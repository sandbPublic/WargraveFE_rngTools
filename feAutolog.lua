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
		if currTurn < logs[i].turn or currPhase ~= logs[i].phase then
			currTurn = logs[i].turn
			currPhase = logs[i].phase
			f:write("\n")
			f:write(turnString(currTurn, currPhase), "\n")
		end
		f:write(string.format("%d RN %d-%d (%d)\n", 
			i, logs[i].rnStart, logs[i].rnEnd, logs[i].rnEnd-logs[i].rnStart))
		f:write(logs[i].combat1, "\n")
		f:write(logs[i].combat2, "\n\n")
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
	
	combat.currBattleParams:set()
	
	local function line(combatant)
		return string.format("%-12s with %2d use %-12s  at %2d,%2d",
			combatant.name,
			combatant.weaponUses,
			combatant.weapon,
			combatant.x,
			combatant.y)
	end
	
	o.combat1 = line(combat.currBattleParams.attacker)
	o.combat2 = line(combat.currBattleParams.defender)
	
	return o
end

function P.addLog()
	local newLog = logLineObj:new()
	
	for i = 1, logCount do
		if logs[i].rnStart >= newLog.rnStart then
			-- erase subsequent logs (jumped back via savestate, or negative rn jump)
			logCount = i - 1
			break
		end
	end
	
	logCount = logCount + 1
	logs[logCount] = newLog
end

return P