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

local currTurn = 0
local currPhase = "player"

local currMoney = 0

-- non modifying functions

function P.writeLogs()
	local fileName = string.format("fe%dch%d-%d-%d.autolog.txt",
		GAME_VERSION,
		memory.readbyte(addr.CHAPTER),
		os.time(),
		logsWritten)
		
	local f = io.open(fileName, "w")
	
	for i = 1, logCount do
		f:write(logs[i].str, "\n")
	end
	
	f:close()
	logsWritten = logsWritten + 1
	print("wrote " .. fileName)
end




-- modifying functions

function P.passiveUpdate()
	if (lastAttackerID ~= memory.readbyte(addr.ATTACKER_START + addr.SLOT_OFFSET_ID)) or 
       (lastDefenderID ~= memory.readbyte(addr.DEFENDER_START + addr.SLOT_OFFSET_ID)) then
	   
		lastAttackerID = memory.readbyte(addr.ATTACKER_START + addr.SLOT_OFFSET_ID)
		lastDefenderID = memory.readbyte(addr.DEFENDER_START + addr.SLOT_OFFSET_ID)
		lastEventUpdateFrame = vba.framecount() + 1
	end
	
	if lastEventUpdateFrame == vba.framecount() then
		lastEvent = rnEvent.rnEventObj:new()
		lastEvent.startRN_i = rns.rng1.pos
		lastEvent.postBurnsRN_i  = rns.rng1.pos
	end
	
	if currTurn ~= memory.readbyte(addr.TURN) or currPhase ~= getPhase() then
		currTurn = memory.readbyte(addr.TURN)
		currPhase = getPhase()
		
		autolog.addLog_string("\nTurn " .. currTurn .. " " .. currPhase .. " phase")
	end
	
	if currMoney ~= addr.getMoney() then
		local moneyChange = addr.getMoney() - currMoney
		
		autolog.addLog_string(string.format("Money %6d %+7d -> %6d at %2d,%2d by %s", 
			currMoney, 
			moneyChange, 
			addr.getMoney(),
			memory.readbyte(addr.ATTACKER_START + addr.X_OFFSET),
			memory.readbyte(addr.ATTACKER_START + addr.Y_OFFSET),
			unitData.hexCodeToName(memory.readword(addr.ATTACKER_START + addr.NAME_CODE_OFFSET))))
			
		currMoney = addr.getMoney()
	end
end

-- movement, phase change, money, etc
function P.addLog_string(str)
	local newLog = {}
	
	newLog.rnStart = rns.rng1.pos
	newLog.rnEnd = rns.rng1.pos
	newLog.str = str
	
	P.addLog(newLog)
end

function P.addLog_RNconsumed()
	-- do just in time update of fields that only update with rns on enemy phase
	lastEvent.combatants.defender.hit = memory.readbyte(addr.DEFENDER_START + addr.HIT_OFFSET)
	lastEvent.combatants.defender.crit = memory.readbyte(addr.DEFENDER_START + addr.CRIT_OFFSET)
	lastEvent:updateFull()
	
	local newLog = {}
	
	newLog.rnStart = rns.rng1.prevPos
	newLog.rnEnd = rns.rng1.pos
	local rnsUsed = newLog.rnEnd - newLog.rnStart
	
	newLog.str = string.format("RN %5d->%5d (%d)", newLog.rnStart, newLog.rnEnd, rnsUsed)
	
	if lastEvent.length == rnsUsed then
		newLog.str = newLog.str .. "\n"
		if lastEvent.hasCombat then
			newLog.str = newLog.str .. combat.hitSeq_string(lastEvent.mHitSeq) .. " "
		end
		if lastEvent:levelDetected() then
			newLog.str = newLog.str .. lastEvent.unit:levelUpProcs_string(lastEvent.postCombatRN_i)
		end
		
		local function line(combatant)
			return string.format("\n%-9s at %2d,%2d with %2d use %-12s ",
				combatant.name,
				combatant.x,
				combatant.y,
				combatant.weaponUses,
				combatant.weapon)
		end
	
		newLog.str = newLog.str .. line(lastEvent.combatants.attacker)
		newLog.str = newLog.str .. line(lastEvent.combatants.defender)
	end
	
	P.addLog(newLog)
end

function P.addLog(newLog)
	-- saved log overlaps or comes after newLog
	-- erase subsequent logs (jumped back via savestate, or negative rn jump)
	while logs[logCount] and (math.max(logs[logCount].rnStart, logs[logCount].rnEnd) 
	                          > math.min(newLog.rnStart, newLog.rnEnd)) do
		logCount = logCount - 1
	end
	
	logCount = logCount + 1
	logs[logCount] = newLog
end

return P