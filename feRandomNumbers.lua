local P = {}
rns = P

local function nextrng(r1, r2, r3)
	return AND(XOR(SHIFT(r3, 5), SHIFT(r2, -11), SHIFT(r1, -1), SHIFT(r2, 15)),0xFFFF)
end

local rngbase=0x03000000

P[-3] = memory.readword(rngbase+4)
--P[-3] = 0x1496 --  5270
P[-2] = 0x90EA -- 37098
P[-1] = 0x3671 -- 13937	
P.pos = 0 -- position in the rn stream relative to initial
P.prevPos = 0
P.rnsGenerated = 0

function P.rnsLastConsumed()
	return P.pos - P.prevPos
end

-- generates more if needed
function P.getRN(pos_i)
	while pos_i >= P.rnsGenerated do
		-- generate more rns
		P[P.rnsGenerated] = nextrng(
			P[P.rnsGenerated-3], 
			P[P.rnsGenerated-2], 
			P[P.rnsGenerated-1])
		P.rnsGenerated = P.rnsGenerated + 1
	end
	return P[pos_i]
end

-- returns false if current seeds don't match previous 3 rns
function P.atPos_bool()
	return P.getRN(P.pos-3) == memory.readword(rngbase+4) and
		   P.getRN(P.pos-2) == memory.readword(rngbase+2) and
		   P.getRN(P.pos-1) == memory.readword(rngbase)
end

-- returns true if updated
function P.update()
	if not P.atPos_bool() then
		P.prevPos = P.pos
		P.pos = 0
		while not P.atPos_bool() do
			P.pos = P.pos + 1

			-- sometimes the place in memory that holds the rns
			-- temporarily holds other values
			-- failsafe against this
			if P.pos > 10000 then
				print(string.format("rns.pos %d too high, skipping frame %d, seeds %4X %4X %4X", 
					P.pos, vba.framecount(), memory.readword(rngbase+4),
					memory.readword(rngbase+2), memory.readword(rngbase)))
				P.pos = 0
				
				emu.frameadvance()
			end
		end
		return true
	end
	return false
end

function P.relToAbsPos(relPos_i) -- relative position
	return relPos_i + P.pos
end

function P.RNtoCent(rn)
	return math.floor(100*rn/0xFFFF) 
	-- game itself floors, as I found, 
	-- fractional part made a difference on Tirado's 25% hit at 1647
	-- may round differently in FE6? simply divides by 655?
	-- https://www.gamefaqs.com/boards/468480-fire-emblem/58065405?page=1
	-- can return 100?
end

function P.getRNasCent(index)
	return P.RNtoCent(P.getRN(index))
end

function P.rnToString(index)
	return string.format("%02d", P.getRNasCent(index))
end

 -- string, append space after each rn
function P.rnSeqString(index, length)
	local seq = ""
	for i = 0, length - 1 do
		seq = seq .. P.rnToString(index+i) .. " "
	end
	return seq
end

-- index from 0
-- colorized for gui leaves the numbers blank so they can be drawn colored later
function P.RNstream_strings(colorized, numLines, rnsPerLine)
	local ret = {}
		
	-- put the first line before the current position for context
	local firstLineRnPos = math.floor(P.pos/rnsPerLine-1)*rnsPerLine
	if firstLineRnPos < 0 then firstLineRnPos = 0 end
	
	for line_i = 0, numLines-1 do
		local lineString = string.format("%04d:", firstLineRnPos+line_i*rnsPerLine)
		for rn_i = 0, rnsPerLine-1 do
			local rnPos = firstLineRnPos + rnsPerLine*line_i + rn_i
		
			if rnPos == P.pos then
				lineString = lineString .. ">"
			else
				lineString = lineString .. " "
			end
			
			if colorized then
				lineString = lineString .. "  "
			else
				lineString = lineString .. P.rnToString(rnPos)
			end
		end
		ret[line_i] = lineString
	end
	return ret
end

-- secondary RN seems to be located at 0x03000008 in FE7
-- advanced by desert digs, blinking (suspend menu), 
-- and most usefully by merely opening a unit's item

local rng2base=0x03000008
P.rn2 = {}

function P.updateRN2()
	local currentRN2 = memory.readword(0x03000008)
	if P.rn2 ~= currentRN2 then
		P.rn2 = currentRN2
		print("RN2: " .. tostring(P.rn2))
	end
end

P.rn2[-3] = 0x1496 --  5270
P.rn2[-2] = 0x90EA -- 37098
P.rn2[-1] = 0x3671 -- 13937	
P.rn2.pos = 0 
P.rn2.prevPos = 0
P.rn2.rnsGenerated = 0

return rns