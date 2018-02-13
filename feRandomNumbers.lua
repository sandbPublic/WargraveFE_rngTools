local P = {}
rns = P

local function nextrng(r1, r2, r3)
	return AND(XOR(SHIFT(r3, 5), SHIFT(r2, -11), SHIFT(r1, -1), SHIFT(r2, 15)),0xFFFF)
end

local function byteToPercent(rn)
	return math.floor(100*rn/0xFFFF) 
	-- game itself floors, as I found, 
	-- fractional part made a difference on Tirado's 25% hit at 1647
	-- may round differently in FE6? simply divides by 655?
	-- https://www.gamefaqs.com/boards/468480-fire-emblem/58065405?page=1
	-- can return 100?
end

-- since there is a secondary rn for desert digs in FE6/7, 
-- make the functionality here an object
-- will require much refactoring
local rnStreamObj = {}

function rnStreamObj:new(rngMemoryOffset, name)
	local o = {} -- use numerical indexes as numbers in the stream
	setmetatable(o, self)
	self.__index = self
	
	o.rngAddr = rngMemoryOffset
	o.name = name
	
	o[-3] = o:generator(3) --0x1496  5270
	o[-2] = o:generator(2) --0x90EA 37098
	o[-1] = o:generator(1) --0x3671 13937
	
	o.pos = 0 -- position in the rn stream relative to power on
	o.prevPos = 0
	o.rnsGenerated = 0
	
	return o
end

-- gets rns that construct the next rn, initially the seed
function rnStreamObj:generator(num)
	return memory.readword(self.rngAddr+2*(num-1))
end

P.rng1 = rnStreamObj:new(0x03000000, "rng1")
-- secondary RN seems to be located at 0x03000008 in FE7
-- advanced by desert digs, blinking (suspend menu), 
-- and most usefully by merely opening a unit's item
P.rng2 = rnStreamObj:new(0x03000008, "rng2")

function rnStreamObj:rnsLastConsumed()
	return self.pos - self.prevPos
end

-- generates more if needed
function rnStreamObj:getRN(pos_i)
	while pos_i >= self.rnsGenerated do
		-- generate more rns
		self[self.rnsGenerated] = nextrng(
			self[self.rnsGenerated-3], 
			self[self.rnsGenerated-2], 
			self[self.rnsGenerated-1])
		self.rnsGenerated = self.rnsGenerated + 1
	end
	return self[pos_i]
end

function rnStreamObj:getRNasCent(index)
	return byteToPercent(self:getRN(index))
end

function rnStreamObj:getRNasString(index)
	return string.format("%02d", self:getRNasCent(index))
end

-- returns false if current generators don't match previous 3 rns
function rnStreamObj:atPos_bool()
	return self:getRN(self.pos-3) == self:generator(3) and
		   self:getRN(self.pos-2) == self:generator(2) and
		   self:getRN(self.pos-1) == self:generator(1)
end

-- returns true if updated
function rnStreamObj:update()
	if not self:atPos_bool() then
		self.prevPos = self.pos
		self.pos = 0
		while not self:atPos_bool() do
			self.pos = self.pos + 1

			-- sometimes the place in memory that holds the rns
			-- temporarily holds other values
			-- failsafe against this
			if self.pos > 10000 then
				print(string.format(
					"%s pos %d too high. Skipping frame %d. Generators %4X %4X %4X", 
					self.name, self.pos, vba.framecount(), 
					self:generator(3), self:generator(2), self:generator(1)))
				self.pos = 0
				
				emu.frameadvance()
			end
		end
		
		local rnPosDelta = self:rnsLastConsumed()
		print(string.format("rngPos %d -> %d, %d", self.prevPos, self.pos, rnPosDelta))
		
		-- print what was consumed if not a large jump
		if (rnPosDelta > 0 and rnPosDelta <= 24)then
			print(self:rnSeqString(self.pos-rnPosDelta, rnPosDelta))
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
		seq = seq .. self.getRNasString(index+i) .. " "
	end
	return seq
end

-- index from 0
-- colorized for gui leaves the numbers blank so they can be drawn colored later
function rnStreamObj:RNstream_strings(colorized, numLines, rnsPerLine)
	local ret = {}
		
	-- put the first line before the current position for context
	local firstLineRnPos = math.floor(self.pos/rnsPerLine-1)*rnsPerLine
	if firstLineRnPos < 0 then firstLineRnPos = 0 end
	
	for line_i = 0, numLines-1 do
		local lineString = string.format("%04d:", firstLineRnPos+line_i*rnsPerLine)
		for rn_i = 0, rnsPerLine-1 do
			local rnPos = firstLineRnPos + rnsPerLine*line_i + rn_i
		
			if rnPos == self.pos then
				lineString = lineString .. ">"
			else
				lineString = lineString .. " "
			end
			
			if colorized then
				lineString = lineString .. "  "
			else
				lineString = lineString .. self.getRNasString(rnPos)
			end
		end
		ret[line_i] = lineString
	end
	return ret
end

return rns