require("feGUI")

local P = {}
autolog = P

local logLineObj = {}

local logs = {}
local logCount = 0
local logsWritten = 0
local lastEvent = rnEvent.rnEventObj:new()

-- combat RAM may not all be updated within one frame
-- upon selecing the weapon for the combat, slots and most fields seem to be updated first
-- hit and crit set to 0, then correct value next frame
-- enemy rn burns happen after slots etc are updated
-- but defender data may be loaded same frame as rns are used?
-- data to construct event may only be known after rns used...
-- defender data MAY be the same or partially updated by AI calculations
-- data AFTER rn is used will have post event exp/lvl?
-- for now only update and log on player phase
-- todo figure out how to do ep
local lastAttackerID = 0
local lastDefenderID = 0
local nextUpdateFrame = -1

local currTurn = -1
local currPhase = "player"

local currMoney = 0

local slotStopped = {}
local slotRescued = {}
local SLOTS_TO_CHECK = 48

-- helps distinguish enemy rn burns from events,
-- since we don't reverse construct EP events after combats
local newEvent = false 




-- non modifying functions

local function nameFromSlot(slot)
	return unitData.hexCodeToName(addr.wordFromSlot(slot, addr.NAME_CODE_OFFSET))
end




-- modifying functions

function P.passiveUpdate()
	if (lastAttackerID ~= memory.readbyte(addr.ATTACKER_START + addr.SLOT_ID_OFFSET)) or 
       (lastDefenderID ~= memory.readbyte(addr.DEFENDER_START + addr.SLOT_ID_OFFSET)) then
	   
		lastAttackerID = memory.readbyte(addr.ATTACKER_START + addr.SLOT_ID_OFFSET)
		lastDefenderID = memory.readbyte(addr.DEFENDER_START + addr.SLOT_ID_OFFSET)
		nextUpdateFrame = vba.framecount() + 1
		-- hit and crit may not be updated yet
	end
	
	if nextUpdateFrame == vba.framecount() then
		lastEvent = rnEvent.rnEventObj:new()
		lastEvent.startRN_i = rns.rng1.pos
		lastEvent.postBurnsRN_i = rns.rng1.pos
		lastEvent:updateFull()
		
		newEvent = true
	end
	
	if currTurn ~= memory.readbyte(addr.TURN) or currPhase ~= getPhase() then
		currTurn = memory.readbyte(addr.TURN)
		currPhase = getPhase()
		
		autolog.addLog_string("\nTurn " .. currTurn .. " " .. currPhase .. " phase")
		
		for slot = 1, SLOTS_TO_CHECK do
			slotStopped[slot] = addr.unitIsStopped(slot)
			slotRescued[slot] = addr.unitIsRescued(slot)
		end
	end
	
	if getPhase() == "player" then -- check movements
		for slot = 1, SLOTS_TO_CHECK do -- check all slots for rescues, drops and refreshes
			if slotStopped[slot] ~= addr.unitIsStopped(slot) then
				slotStopped[slot] = addr.unitIsStopped(slot)
				
				local action = "stop"
				if not slotStopped[slot] then action = "refresh" end
				
				P.addLog_string(string.format("at %2d,%2d %s %s",
					addr.byteFromSlot(slot, addr.X_OFFSET),
					addr.byteFromSlot(slot, addr.Y_OFFSET),
					nameFromSlot(slot),
					action))
			end
			
			if slotRescued[slot] ~= addr.unitIsRescued(slot) then
				slotRescued[slot] = addr.unitIsRescued(slot)
				
				local action = "rescue"
				if not slotRescued[slot] then action = "drop" end
				
				P.addLog_string(string.format("at %2d,%2d %s %s",
					addr.byteFromSlot(slot, addr.X_OFFSET),
					addr.byteFromSlot(slot, addr.Y_OFFSET),
					nameFromSlot(slot),
					action))
			end
		end
	end
	
	if currMoney ~= addr.getMoney() then
		autolog.addLog_string(string.format("at %2d,%2d Money %6d %+7d -> %6d by %s", 
			memory.readbyte(addr.ATTACKER_START + addr.X_OFFSET),
			memory.readbyte(addr.ATTACKER_START + addr.Y_OFFSET),
			currMoney, 
			addr.getMoney() - currMoney, 
			addr.getMoney(),
			nameFromSlot(addr.SELECTED_SLOT)))
			
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

-- don't add redundant log that a unit stopped after event logged
-- prevents the next log after an event is logged
local skipNextLog = false

function P.addLog_RNconsumed()	
	local newLog = {}
	
	newLog.rnStart = rns.rng1.prevPos
	newLog.rnEnd = rns.rng1.pos
	local rnsUsed = newLog.rnEnd - newLog.rnStart
	
	newLog.str = string.format("RN %5d->%5d (%d)", newLog.rnStart, newLog.rnEnd, rnsUsed)
	
	local function line(combatant)
		return string.format("at %2d,%2d %s with %d use %s\n",
			combatant.x,
			combatant.y,
			combatant.name,
			combatant.weaponUses,
			combatant.weapon)
	end
	
	if currPhase == "player" then
		if lastEvent.length == rnsUsed then
			local eventStr = line(lastEvent.combatants.attacker) .. line(lastEvent.combatants.defender)
		
			if lastEvent.hasCombat then
				eventStr = eventStr .. combat.hitSeq_string(lastEvent.mHitSeq)
			end
			if lastEvent:levelDetected() then
				eventStr = eventStr .. " " .. lastEvent.unit:levelUpProcs_string(lastEvent.postCombatRN_i)
			end
			
			newLog.str = eventStr .. "\n" .. newLog.str
			
			P.addLog(newLog)
			skipNextLog = true
			return
		else
			newLog.str = "Event does not match rns\n" .. newLog.str
			print()
			print("Event does not match rns", lastEvent.length, rnsUsed, lastEvent:headerString())
		end
	elseif rnsUsed > 1 and newEvent then -- neglects enemy staff, but slots update even for some burns
		newLog.str = "Enemy event?\n" .. line(lastEvent.combatants.attacker) .. 
			line(lastEvent.combatants.defender) .. newLog.str
		newEvent = false
	end
	P.addLog(newLog)
end

function P.addLog(newLog)
	if skipNextLog then
		skipNextLog = false
	else
		-- saved log overlaps or comes after newLog
		-- erase subsequent logs (jumped back via savestate, or negative rn jump)
		while logs[logCount] and (math.max(logs[logCount].rnStart, logs[logCount].rnEnd) 
								  > math.min(newLog.rnStart, newLog.rnEnd)) do
			logCount = logCount - 1
		end
		
		logCount = logCount + 1
		logs[logCount] = newLog
	end
end

-- note this saves under vba movie directory when running movie
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

return P