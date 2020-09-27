require("feGUI")

local P = {}
autolog = P

local logLineObj = {}

local logs = {}
local logCount = 0
local logsWritten = 0
local lastEvent = rnEvent.rnEventObj:new()

-- combat RAM may not all be updated within one frame
-- slots and most fields seem to be updated first
-- enemy rn burns happen after slots etc are updated
-- wait a frame to do first update
-- hit and crit afterward, and exp and event rn consumed at same frame during enemy phase
-- do partial update of just hit and crit
local lastAttackerID = 0
local lastDefenderID = 0
local lastEventUpdateFrame = 0




-- non modifying functions

function P.writeLogs()
	local fileName = string.format("fe%dch%d-%d-%d.autolog.txt",
		GAME_VERSION,
		memory.readbyte(addr.CHAPTER),
		os.time(),
		logsWritten)
	local f = io.open(fileName, "w")
	
	local currTurn = 0
	local currPhase = "player"
	for i = 1, logCount do
		if currTurn ~= logs[i].turn or currPhase ~= logs[i].phase then
			currTurn = logs[i].turn
			currPhase = logs[i].phase
			f:write("\n")
			f:write("Turn " .. currTurn .. " " .. currPhase .. " phase\n")
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

function P.updateLastEvent()
	if (lastAttackerID ~= memory.readbyte(addr.UNIT_SLOT_ID)) or 
       (lastDefenderID ~= memory.readbyte(addr.UNIT_SLOT_ID + addr.DEFENDER_OFFSET)) then
	   
		lastAttackerID = memory.readbyte(addr.UNIT_SLOT_ID)
		lastDefenderID = memory.readbyte(addr.UNIT_SLOT_ID + addr.DEFENDER_OFFSET)
		lastEventUpdateFrame = vba.framecount() + 1
	end
	
	if lastEventUpdateFrame == vba.framecount() then
		lastEvent = rnEvent.rnEventObj:new()
		lastEvent.startRN_i = rns.rng1.pos
		lastEvent.postBurnsRN_i  = rns.rng1.pos
	end
end

function logLineObj:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	
	o.turn = memory.readbyte(addr.TURN)
	o.phase = getPhase()
	
	o.rnStart = rns.rng1.prevPos
	o.rnEnd = rns.rng1.pos
	o.rnsUsed = o.rnEnd - o.rnStart
	
	local function line(combatant)
		return string.format("%-9s at %2d,%2d with %2d use %-12s ",
			combatant.name,
			combatant.x,
			combatant.y,
			combatant.weaponUses,
			combatant.weapon)
	end
	
	if lastEvent.length == o.rnsUsed then
		o.outcome = ""
		if lastEvent.hasCombat then
			o.outcome = " " .. combat.hitSeq_string(lastEvent.mHitSeq)
		end
		if lastEvent:levelDetected() then
			o.outcome = o.outcome .. " " .. lastEvent.unit:levelUpProcs_string(lastEvent.postCombatRN_i)
		end
		o.attacker = line(lastEvent.combatants.attacker)
		o.defender = line(lastEvent.combatants.defender)
	end
	
	return o
end

function P.addLog()
	-- do just in time update of fields that only update with rns on enemy phase
	lastEvent.combatants.defender.hit = memory.readbyte(addr.UNIT_HIT + addr.DEFENDER_OFFSET)
	lastEvent.combatants.defender.crit = memory.readbyte(addr.UNIT_CRIT + addr.DEFENDER_OFFSET)
	lastEvent:updateFull()
	
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