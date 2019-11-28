local P = {}
rns = P

local MAX_RNS = 999999

local function nextrng(r1, r2, r3)
	return AND(XOR(SHIFT(r3, 5), SHIFT(r2, -11), SHIFT(r1, -1), SHIFT(r2, 15)),0xFFFF)
end

-- 2ndary rn use 1 4-byte number and generator 
-- rather than 1 2-byte number and 3 2-byte generators
-- http://bbs.fireemblem.net/read.php?tid=184603&fpage=2
-- digging/anna blinking consumes 1, looking at items/attack consumes 2, trade 4,
local function nextrng2(generator)
	local lowerWord = AND(generator, 0x0000FFFF)
	local upperWord = AND(generator, 0xFFFF0000)/0x10000

	local lowerPart = 4*lowerWord*lowerWord+5*lowerWord+1
	local upperPart = upperWord*(5+8*lowerWord)*0x10000
	
	return AND(lowerPart+upperPart,0x3FFFFFFF)
end

local function byteToPercent(rn)
	return math.floor(100*rn/0x10000)
	-- may round differently in FE6? simply divides by 655?
	-- https://www.gamefaqs.com/boards/468480-fire-emblem/58065405?page=1
end

local rnStreamObj = {}

function rnStreamObj:new(rngMemoryOffset, primary)
	local o = {} -- use numerical indexes as numbers in the stream
	setmetatable(o, self)
	self.__index = self
	
	o.rawBytes = {} -- save these in memory to find exact position/move position
	o.rngAddr = rngMemoryOffset
	o.isPrimary = primary
	
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

function rnStreamObj:name()
	if self.isPrimary then return "primary" end
	return "2ndary"
end

-- gets rns that construct the next rn, initially the seed
function rnStreamObj:generator(relative_prior_index)
	return memory.readword(self.rngAddr + 2*(relative_prior_index - 1))
end

P.rng1 = rnStreamObj:new(0x03000000, true)
-- secondary RN located at 0x03000008 in FE7
-- advanced by desert digs, blinking (suspend menu), 
-- and most usefully by merely opening a unit's item
P.rng2 = rnStreamObj:new(0x03000008, false)

-- generates more if needed
function rnStreamObj:getRN(pos_i, isRaw)
	while pos_i >= self.rnsGenerated do
		if self.isPrimary then
			local rawDoubleByte = nextrng(
				self.rawBytes[self.rnsGenerated-3], 
				self.rawBytes[self.rnsGenerated-2], 
				self.rawBytes[self.rnsGenerated-1])
		
			self.rawBytes[self.rnsGenerated] = rawDoubleByte
			self[self.rnsGenerated] = byteToPercent(rawDoubleByte)
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

function rnStreamObj:moveRNpos(delta)
	local destination = self.pos + delta
	if destination < 0 then destination = 0 end
	
	gen = self:getRN(destination-1, "isRaw")
	
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

-- returns false if current generators don't match previous 3 rns
function rnStreamObj:isAtCurrentPosition()
	local gen = self:getRN(self.pos-1, "isRaw")

	return (self.isPrimary and 
			(self.rawBytes[self.pos-3] == self:generator(3) and  -- other bytes are generated
		     self.rawBytes[self.pos-2] == self:generator(2) and
		     gen == self:generator(1)))
			or
			((not self.isPrimary) and
			 gen == self:generator(1)+self:generator(2)*0x10000)
end

local lastFrameUpdated = 0
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
		
		-- prevent 2ndary from printing a lot during crits
		if (not self.isPrimary) and (vba.framecount() - lastFrameUpdated) <= 4 then
			lastFrameUpdated = vba.framecount()
			return
		end
		lastFrameUpdated = vba.framecount()
		
		local rnPosDelta = self.pos - self.prevPos
		
		local str = string.format("rng pos %4d -> %4d, %d", self.prevPos, self.pos, rnPosDelta)
		if not self.isPrimary then
			str = "2ndary " .. str
		end
		
		-- print what was consumed if not a large jump
		if rnPosDelta == 1 and self.isPrimary then -- print single rns on same line
			print(str .. ": " .. self:getRN(self.pos - 1))
		elseif rnPosDelta > 0 and rnPosDelta <= 24 then
			print(str)
		
			if self.isPrimary then
				print(self:rnSeqString(self.pos-rnPosDelta, rnPosDelta))
			else
				str = "Next: "
				for rn2_i = self.pos, self.pos + 30 do -- show next 30
					if self:getRN(rn2_i) then
						str = str .. "!"
					else
						str = str .. "."
					end
				end
				print(str)
			end
		else
			print(str)
		end
		
		return true
	end
	return false -- no update performed or needed
end

 -- string, append space after each rn
function rnStreamObj:rnSeqString(index, length)
	local seq = ""
	for offset = 0, length - 1 do
		seq = seq .. string.format("%02d ", self:getRN(index+offset))
	end
	return seq
end

-- isColored for gui leaves the numbers blank so they can be drawn colored later
function rnStreamObj:RNstream_strings(isColored, numLines, rnsPerLine)
	local rStrings = {}
	
	-- put the prior line before the current position for context
	local currLineRnPos = math.floor(self.pos/rnsPerLine-1)*rnsPerLine
	if currLineRnPos < 0 then currLineRnPos = 0 end
	
	for line_i = 1, numLines do
		local lineString = string.format("%05d:", (currLineRnPos)%100000)
		
		if not isColored then
			for rnPos = currLineRnPos, currLineRnPos + rnsPerLine - 1 do
				if rnPos == self.pos then
					lineString = lineString .. string.format("%>02d", self:getRN(rnPos))
				else
					lineString = lineString .. string.format("% 02d", self:getRN(rnPos))
				end
			end
		end
		
		currLineRnPos = currLineRnPos + rnsPerLine
		table.insert(rStrings, lineString)
	end
	return rStrings
end

return rns