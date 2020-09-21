require("feGUI")

local P = {}
autolog = P

local logLineObj = {}

local logs = {}
local logCount = 0




-- non modifying functions

function P.writeLogs()
	local fileName = "autolog" .. os.time() .. ".txt"
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
		f:write(string.format("%d RN %d-%d(%d) at %02d,%02d\n", 
			i, logs[i].rnStart, logs[i].rnEnd, logs[i].rnEnd-logs[i].rnStart, logs[i].X, logs[i].Y))
		f:write(logs[i].combat1, "\n")
		f:write(logs[i].combat2, "\n\n")
	end
	
	f:close()
	print("wrote " .. fileName)
end




-- modifying functions

function logLineObj:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	
	o.turn = memory.readbyte(TURN_ADDR)
	o.phase = memory.readbyte(PHASE_ADDR)
	o.rnStart = rns.rng1.prevPos
	o.rnEnd = rns.rng1.pos
	o.X = memory.readbyte(CURSOR_X_ADDR)
	o.Y = memory.readbyte(CURSOR_Y_ADDR)
	combat.currBattleParams:set()
	o.combat1 = combat.currBattleParams:autoLogLine("isAttacker")
	o.combat2 = combat.currBattleParams:autoLogLine()
	
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