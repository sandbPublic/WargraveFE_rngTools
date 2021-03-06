require("feClass")
require("feColor")

local P = {}
rns = P



local MAX_RNS = 99999

local function nextrng(r1, r2, r3)
	return AND(XOR(SHIFT(r3, 5), SHIFT(r2, -11), SHIFT(r1, -1), SHIFT(r2, 15)),0xFFFF)
end

-- 2ndary rn use 1 4-byte number and generator 
-- rather than 1 2-byte number and 3 2-byte generators
-- http://bbs.fireemblem.net/read.php?tid=184603&fpage=2
-- digging/anna blinking consumes 1, looking at items/attack consumes 2, trade 4,
local function nextrng2(generator)
	-- Lua _VERSION 5.1 does not include bitwise operators eg &
	local lowerWord = AND(generator, 0x0000FFFF)
	local upperWord = AND(generator, 0xFFFF0000)/0x10000

	local lowerPart = 4*lowerWord*lowerWord+5*lowerWord+1
	local upperPart = upperWord*(5+8*lowerWord)*0x10000
	
	return AND(lowerPart+upperPart,0x3FFFFFFF)
end

local function bytesToPercent(rn)
	if (GAME_VERSION == 6) then
		-- rounds differently in FE6, simply divides by 655
		-- https://www.gamefaqs.com/boards/468480-fire-emblem/58065405?page=1
		-- compare rn at 693 in FE6: raw is 0xB333, ~69.9996948242
		-- but doesn't proc Bartre's 70 hp growth
		-- 0xB333/655 ~70.0381679389
		-- can produce 100s, if >= 0xFFDC (which is exactly 100*655)
		-- there are 2 fairly close together, at 670 and 688
		return math.floor(rn/655)
	else
		return math.floor(100*rn/0x10000)
	end
end





local rnStreamObj = {}

-- non modifying functions

function rnStreamObj:name()
	if self.isPrimary then return "primary" end
	return "2ndary"
end

-- gets rns that construct the next rn, initially the seed
function rnStreamObj:generator(relativePriorIndex)
	return memory.readword(self.rngAddr + 2*(relativePriorIndex - 1))
end

-- generates more if needed
function rnStreamObj:getRN(pos_i, isRaw)
	while pos_i >= self.rnsGenerated do
		if self.isPrimary then
			local rawDoubleByte = nextrng(
				self.rawBytes[self.rnsGenerated-3], 
				self.rawBytes[self.rnsGenerated-2], 
				self.rawBytes[self.rnsGenerated-1])
		
			self.rawBytes[self.rnsGenerated] = rawDoubleByte
			local cent = bytesToPercent(rawDoubleByte)
			self[self.rnsGenerated] = cent
			if cent < 100 then
				self.strings[self.rnsGenerated] = string.format("%02d", cent)
			else
				self.strings[self.rnsGenerated] = "A0" -- only possible in FE6
			end
		else
			local rawQuadByte = nextrng2(self.rawBytes[self.rnsGenerated-1])
		
			self.rawBytes[self.rnsGenerated] = rawQuadByte			
			self[self.rnsGenerated] = (rawQuadByte%11 == 0)
		end
		self.rnsGenerated = self.rnsGenerated + 1
	end
	
	if isRaw then
		return self.rawBytes[pos_i]
	end	
	return self[pos_i]
end

-- returns false if current generators don't match previous 3 rns
function rnStreamObj:isAtCurrentPosition()
	local gen = self:getRN(self.pos-1, "isRaw")

	return (self.isPrimary and 
			(self.rawBytes[self.pos-3] == self:generator(3) and -- earlier raw bytes are already generated
		     self.rawBytes[self.pos-2] == self:generator(2) and
		     gen == self:generator(1)))
			or
			((not self.isPrimary) and
			 gen == self:generator(1)+self:generator(2)*0x10000)
end

 -- space before each rn
function rnStreamObj:rnSeqString(start, length)
	self:getRN(start + length - 1)

	local rString = ""
	for rnPos = start, start + length - 1 do
		rString = rString .. " " .. self.strings[rnPos]
	end
	return rString
end

-- color code rns
-- 00 = blue
-- 25 = teal
-- 50 = white
-- 75 = yellow
-- 100 = red

local rnColors = {}
local rnBorderColors = {}

for rnCent = 0, 100 do
	rnColors[rnCent] = colorUtil.interpolate(rnCent/100, colorUtil.blueToRed)
	rnBorderColors[rnCent] = colorUtil.darken(rnColors[rnCent])
end

function rnStreamObj:rnSeqColorSegments(start, length, colorSegs)
	self:getRN(start + length - 1)
	
	colorSegs = colorSegs or {}
	for rnPos = start, start + length - 1 do
		table.insert(colorSegs, {3, rnColors[self[rnPos]], rnBorderColors[self[rnPos]]})
	end
	return colorSegs
end

function rnStreamObj:RNstream_strings(numLines, rnsPerLine)
	local rStrings = {}
	local colorSegmentLists = {} -- arrays of {length, color, borderColor}
	
	-- put the prior line before the current position for context
	local currLineRnPos = math.floor(self.pos/rnsPerLine-1)*rnsPerLine
	if currLineRnPos < 0 then currLineRnPos = 0 end
	
	for line_i = 1, numLines do
		table.insert(rStrings, string.format("%05d:%s", (currLineRnPos)%100000, self:rnSeqString(currLineRnPos, rnsPerLine)))
		table.insert(colorSegmentLists, self:rnSeqColorSegments(currLineRnPos, rnsPerLine, {{6}}))
		currLineRnPos = currLineRnPos + rnsPerLine
	end
	
	return rStrings, colorSegmentLists
end




-- modifying functions

-- returns true if updated
function rnStreamObj:update()
	if not self:isAtCurrentPosition() then
		self.prevPos = self.pos
		self.pos = 0
		while not self:isAtCurrentPosition() do
			self.pos = self.pos + 1

			-- sometimes the place in memory that holds the rns
			-- temporarily holds other values
			-- failsafe against this
			
			if self.pos % 10000 == 0 then
				emu.frameadvance()
			end
			
			if self.pos > MAX_RNS then
				print(string.format(
					"%s generators not found in rnStream within %d rns." 
					.. " Skipping frame %d. Generators %04X %04X %04X", 
					self:name(), MAX_RNS, vba.framecount(), 
					self:generator(3), self:generator(2), self:generator(1)))
				
				self.pos = 0
				emu.frameadvance()
			end
		end
				
		local rnPosDelta = self.pos - self.prevPos
		
		local str = string.format("RNG position %4d -> %4d, %+d", self.prevPos, self.pos, rnPosDelta)
		if not self.isPrimary then
			print("2ndary " .. str)
			local str2 = "Next"
			self:getRN(self.pos + WINDOW_WIDTH - 4)
			for rn2_i = self.pos, self.pos + WINDOW_WIDTH - 4 do
				if self[rn2_i] then
					str2 = str2 .. "!"
				else
					str2 = str2 .. "."
				end
			end
			print(str2)
			return true
		end
		
		-- print what was consumed if not a large jump
		if rnPosDelta == 1 then -- print single rns on same line
			print(self.strings[self.pos - 1] .. " " .. str)
		elseif 0 < rnPosDelta and rnPosDelta <= 2*WINDOW_WIDTH/3 then -- print on up to 2 lines, need 3 chars per rn
			print(self:rnSeqString(self.pos-rnPosDelta, rnPosDelta))
			print("   " .. str)
		else
			print("   " .. str)
		end
		
		return true
	end
	return false -- no update performed or needed
end

function rnStreamObj:moveRNpos(delta)
	local destination = self.pos + delta
	if destination < 0 then destination = 0 end
	
	local gen = self:getRN(destination-1, "isRaw")
	
	if self.isPrimary then
		memory.writeword(self.rngAddr, gen)
		memory.writeword(self.rngAddr+2, self.rawBytes[destination-2])
		memory.writeword(self.rngAddr+4, self.rawBytes[destination-3])
	else
		memory.writeword(self.rngAddr, AND(gen, 0x0000FFFF))
		memory.writeword(self.rngAddr+2, AND(gen, 0xFFFF0000)/0x10000)
	end
	
	self:update()
end

function rnStreamObj:new(rngMemoryOffset, primary)
	local o = {} -- use numerical indexes as numbers in the stream
	setmetatable(o, self)
	self.__index = self
	
	o.rawBytes = {} -- save these in memory to find or move to correct position
	o.strings = {} -- only for primary
	o.rngAddr = rngMemoryOffset
	o.isPrimary = primary or true
	
	if o.isPrimary then
		o.rawBytes[-3] = 0x1496
		o.rawBytes[-2] = 0x90EA
		o.rawBytes[-1] = 0x3671
	else
		o.rawBytes[-1] = 0x3C7CA4D2
	end
	
	o.pos = 0 -- position in the rn stream relative to gba power on
	o.prevPos = 0
	o.rnsGenerated = 0
	-- # length operator is logarithmic, and indexing from -3 is more natural	
	return o
end

P.rng1 = rnStreamObj:new(0x03000000, true)
-- secondary RN located at 0x03000008 in FE6/7
-- advanced by desert digs, blinking (suspend menu), 
-- and most usefully by merely opening a unit's items
P.rng2 = rnStreamObj:new(0x03000008, false)

return rns