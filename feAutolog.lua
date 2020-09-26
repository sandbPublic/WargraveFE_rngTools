require("feGUI")

local P = {}
autolog = P

local logLineObj = {}

local logs = {}
local logCount = 0
local logsWritten = 0



-- non modifying functions

function P.writeLogs()
	local fileName = string.format("autolog%dch%d-%d.txt",
		os.time(),
		memory.readbyte(addr.CHAPTER),
		logsWritten)
	local f = io.open(fileName, "w")
	
	local currTurn = 0
	local currPhase = 0
	for i = 1, logCount do
		if currTurn ~= logs[i].turn or currPhase ~= logs[i].phase then
			currTurn = logs[i].turn
			currPhase = logs[i].phase
			f:write("\n")
			f:write(turnString(currTurn, currPhase), "\n")
		end
		
		local rnsUsed = logs[i].rnEnd-logs[i].rnStart
		f:write(string.format("%4d RN %d-%d (%d)\n", 
			i, logs[i].rnStart, logs[i].rnEnd, rnsUsed))
		
		if logs[i].attacker then
			f:write(logs[i].outcome, "\n")
			f:write(logs[i].attacker, "\n")
			f:write(logs[i].defender, "\n")
		end
	end
	
	f:close()
	logsWritten = logsWritten + 1
	print("wrote " .. fileName)
end




-- modifying functions

function logLineObj:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	
	o.turn = memory.readbyte(addr.TURN)
	o.phase = memory.readbyte(addr.PHASE)
	o.rnStart = rns.rng1.prevPos
	o.rnEnd = rns.rng1.pos
	o.rnsUsed = o.rnEnd - o.rnStart
	
	local function line(combatant)
		return string.format("%-9s with %2d use %-12s  at %2d,%2d",
			combatant.name,
			combatant.weaponUses,
			combatant.weapon,
			combatant.x,
			combatant.y)
	end
	
	local c = combat.combatObj:new()
	local hitSeq = c:hitSeq(o.rnStart)
	if hitSeq.totalRNsConsumed == o.rnsUsed then
		o.outcome = combat.hitSeq_string(hitSeq)
		o.attacker = line(c.attacker)
		o.defender = line(c.defender)
	end
	
	return o
end

function P.addLog()
	local newLog = logLineObj:new()
	
	while logs[logCount] and math.max(logs[logCount].rnStart, logs[logCount].rnEnd) 
	                         > math.min(newLog.rnStart, newLog.rnEnd) do
		
		-- saved log overlaps or comes after newLog
		-- erase subsequent logs (jumped back via savestate, or negative rn jump)
		logCount = logCount - 1
	end
	
	logCount = logCount + 1
	logs[logCount] = newLog
end

return P