local P = {}
rns = P

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
	
	o.rngAddr = rngMemoryOffset
	o.isPrimary = primary
	
	if o.isPrimary then
		o[-3] = 0x1496
		o[-2] = 0x90EA
		o[-1] = 0x3671
	else
		o[-1] = 0x3C7CA4D2
	end
	
	o.pos = 0 -- position in the rn stream relative to gba power on
	o.prevPos = 0
	o.rnsGenerated = 0 -- more descriptive than count
	o.lastFrameUpdated = 0 -- prevent 2ndary from printing a lot during crits
	
	return o
end

function rnStreamObj:name()
	if self.isPrimary then return "primary" end
	return "2ndary"
end

-- gets rns that construct the next rn, initially the seed
function rnStreamObj:generator(num)
	return memory.readword(self.rngAddr+2*(num-1))
end

P.rng1 = rnStreamObj:new(0x03000000, true)
-- secondary RN located at 0x03000008 in FE7
-- advanced by desert digs, blinking (suspend menu), 
-- and most usefully by merely opening a unit's item
P.rng2 = rnStreamObj:new(0x03000008, false)

function rnStreamObj:rnsLastConsumed()
	return self.pos - self.prevPos
end

-- generates more if needed
function rnStreamObj:getRN(pos_i)
	while pos_i >= self.rnsGenerated do
		-- generate more rns
		if self.isPrimary then
			self[self.rnsGenerated] = nextrng(
				self[self.rnsGenerated-3], 
				self[self.rnsGenerated-2], 
				self[self.rnsGenerated-1])
			else
			self[self.rnsGenerated] = nextrng2(self[self.rnsGenerated-1])
		end
		self.rnsGenerated = self.rnsGenerated + 1
	end
	return self[pos_i]
end

function rnStreamObj:getRNasCent(index)
	return byteToPercent(self:getRN(index))
end

-- returns false if current generators don't match previous 3 rns
function rnStreamObj:isAtCurrentPosition()
	return (self.isPrimary and 
			(self:getRN(self.pos-3) == self:generator(3) and
		     self:getRN(self.pos-2) == self:generator(2) and
		     self:getRN(self.pos-1) == self:generator(1)))
			or
			((not self.isPrimary) and
			 self:getRN(self.pos-1) == self:generator(1)+self:generator(2)*0x10000)
end

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
			if self.pos >= 999999 then
				print(string.format(
					"%s generators not found in rnStream within %d rns." 
					.. " Skipping frame %d. Generators %04X %04X %04X", 
					self:name(), self.pos, vba.framecount(), 
					self:generator(3), self:generator(2), self:generator(1)))
				
				self.pos = 0
				emu.frameadvance()
			end
		end
		
		-- prevent 2ndary from printing a lot during crits
		if (not self.isPrimary) and (vba.framecount() - self.lastFrameUpdated) <= 4 then
			self.lastFrameUpdated = vba.framecount()
			return
		end
		self.lastFrameUpdated = vba.framecount()
		
		local rnPosDelta = self:rnsLastConsumed()
		
		local str = string.format("rng pos %4d -> %4d, %d", self.prevPos, self.pos, rnPosDelta)
		if not self.isPrimary then
			str = "2ndary " .. str
		end
		
		-- print what was consumed if not a large jump
		if rnPosDelta == 1 and self.isPrimary then -- print single rns on same line
			print(str .. ": " .. self:getRNasCent(self.pos-1))
		elseif (rnPosDelta > 0 and rnPosDelta <= 24) then
			print(str)
		
			if self.isPrimary then
				print(self:rnSeqString(self.pos-rnPosDelta, rnPosDelta))
			else
				str = "Next: "
				for rn2_i = self.pos, self.pos+30 do -- show next 30
				--	print(string.format("%08X %%B %X", self:getRN(rn2_i), self:getRN(rn2_i)%11))
					if self:getRN(rn2_i)%11 == 0 then
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

function rnStreamObj:relToAbsPos(relPos_i) -- relative position
	return relPos_i + self.pos
end

 -- string, append space after each rn
function rnStreamObj:rnSeqString(index, length)
	local seq = ""
	for i = 0, length - 1 do
		seq = seq .. string.format("%02d ", self:getRNasCent(index+i))
	end
	return seq
end

-- index from 0
-- isColorized for gui leaves the numbers blank so they can be drawn colored later
function rnStreamObj:RNstream_strings(isColorized, numLines, rnsPerLine)
	local ret = {}
	
	-- put the first line before the current position for context
	local firstLineRnPos = math.floor(self.pos/rnsPerLine-1)*rnsPerLine
	if firstLineRnPos < 0 then firstLineRnPos = 0 end
	
	for line_i = 0, numLines-1 do
		local lineString = string.format("%05d:", (firstLineRnPos+line_i*rnsPerLine)%100000)
		for rn_i = 0, rnsPerLine-1 do
			local rnPos = firstLineRnPos + rnsPerLine*line_i + rn_i
		
			if rnPos == self.pos then
				lineString = lineString .. ">"
			else
				lineString = lineString .. " "
			end
			
			if isColorized then
				lineString = lineString .. "  "
			else
				lineString = lineString .. string.format("%02d", self:getRNasCent(rnPos))
			end
		end
		ret[line_i] = lineString
	end
	return ret
end

return rns