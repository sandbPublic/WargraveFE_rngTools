require("feGUI")

local P = {}
autolog = P

local logLineObj = {}

local logs = {}
local logCount = 0
local filesWritten = 0
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

local slotLoc = {} -- todo for warp/rescue staffing

local function updateLoc(slot)
	slotLoc[slot].x = addr.byteFromSlot(slot, addr.X_OFFSET)
	slotLoc[slot].y = addr.byteFromSlot(slot, addr.Y_OFFSET)
end

local function relativeMoveStr(slot)
	local str = ""
	local xChange = addr.byteFromSlot(slot, addr.X_OFFSET) - slotLoc[slot].x
	local yChange = addr.byteFromSlot(slot, addr.Y_OFFSET) - slotLoc[slot].y
	
	while xChange > 0 do
		str = str .. ">"
		xChange = xChange - 1
	end
	while xChange < 0 do
		str = str .. "<"
		xChange = xChange + 1
	end
	while yChange > 0 do
		str = str .. "v"
		yChange = yChange - 1
	end
	while yChange < 0 do
		str = str .. "^"
		yChange = yChange + 1
	end
	
	return str
end


local slotIsStopped = {}
local slotCarrying = {}
local slotEquipedWith = {}
local slotEquipedUses = {}

local function nameFromSlot(slot)
	return unitData.hexCodeToName(addr.wordFromSlot(slot, addr.NAME_CODE_OFFSET))
end

local lastDeployedSlot = 1
local function updateLastDeployedSlot()
	for slot = 1, 255 do
		if addr.wordFromSlot(slot, addr.NAME_CODE_OFFSET) == 0 then
			return
		end
		if addr.byteFromSlot(slot, addr.X_OFFSET) ~= 255 then
			lastDeployedSlot = slot
		end
	end
end
updateLastDeployedSlot()

for slot = 1, lastDeployedSlot do
	slotCarrying[slot] = 0
	slotEquipedWith[slot] = {0, 0, 0, 0, 0}
	slotEquipedUses[slot] = {0, 0, 0, 0, 0}
	slotLoc[slot] = {}
	slotLoc[slot].x = -1
	slotLoc[slot].y = -1
end

-- helps distinguish enemy rn burns from events,
-- since we don't reverse construct EP events after combats
local newEvent = false 

-- don't add redundant log that a unit stopped after certain logs
-- because a unit may canto (including after combat in FE7 if on a "trapped" tile)
-- need to mark the spot so cantoing units WILL log their stop location after actions 
-- that always stop non-cantoing units
local skipNextStopAt = {}
local function updateNextStopSkip()
	skipNextStopAt.x = addr.byteFromSlot(memory.readbyte(addr.SELECTED_SLOT), addr.X_OFFSET)
	skipNextStopAt.y = addr.byteFromSlot(memory.readbyte(addr.SELECTED_SLOT), addr.Y_OFFSET)
	skipNextStopAt.logNumber = logCount -- save this to append relative move string after stop
end


function P.passiveUpdate()
	-- erase subsequent logs if jumped back via savestate
	-- script should be started at or before first savestate,
	-- so that first turn logs are not overwritten when jumping back
	-- todo reset log memory eg locations, inventory, without logging
	while logs[logCount] and logs[logCount].frame > vba.framecount() do
		logCount = logCount - 1
	end

	if vba.framecount() % 30 == 0 then -- check twice per second for deployed/new units
		updateLastDeployedSlot()
	end

	
	
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


	
	-- we don't want to log inventories each frame,
	-- since items may be swapped around while trying different combats.
	-- log only when a turn, phase, or unit's movement status changes
	local function updateInventories()
		for slot = 1, lastDeployedSlot do -- until empty player slots
			if addr.byteFromSlot(slot, addr.X_OFFSET) ~= 255 then
				for item_i = 1, 5 do
					local offset = 2 * item_i - 2
					local item = addr.byteFromSlot(slot, addr.ITEMS_OFFSET + offset)
					local uses = addr.byteFromSlot(slot, addr.ITEMS_OFFSET + offset + 1)
					
					if slotEquipedWith[slot][item_i] ~= item or 
					   slotEquipedUses[slot][item_i] ~= uses then
					   
						slotEquipedWith[slot][item_i] = item
						slotEquipedUses[slot][item_i] = uses
						
						autolog.addLog(string.format("%s's item %d: %2d use %s",
							nameFromSlot(slot),
							item_i,
							uses,
							combat.ITEM_NAMES[item]))
					end
				end
			end
		end
	end
	
	
	
	if (currTurn ~= memory.readbyte(addr.TURN)) or (currPhase ~= getPhase()) then
		
		currTurn = memory.readbyte(addr.TURN)
		currPhase = getPhase()
		updateLastDeployedSlot()
		
		autolog.addLog("\n\nTurn " .. currTurn .. " " .. currPhase .. " phase")
		
		-- don't want to log each "refresh" at the start of turn
		for slot = 1, lastDeployedSlot do -- until empty player slots
			slotIsStopped[slot] = addr.unitIsStopped(slot)
			slotCarrying[slot] = addr.byteFromSlot(slot, addr.CARRYING_SLOT_OFFSET)
			updateLoc(slot)
		end
		
		updateInventories()
		
		autolog.addLog("") -- add space after initial inventory list
	end
	
	
	
	local selSlot = memory.readbyte(addr.SELECTED_SLOT)
	
	local function slotLocString(slot)
		return string.format("at %2d,%2d %s",
			addr.byteFromSlot(slot, addr.X_OFFSET),
			addr.byteFromSlot(slot, addr.Y_OFFSET),
			nameFromSlot(slot))
	end
	
	local function logAtLoc(str)
		P.addLog(slotLocString(selSlot) .. str)
	end
	
	
	
	if getPhase() == "player" then -- check movements
	
		-- only selected unit should check for stopping
		-- after stopping, check for refresh, inventory
		-- check for carried unit
		-- if was 0 and is now not, log carry
		-- if wasn't 0 and now is, log drop
		
		local partnerSlot = addr.byteFromSlot(selSlot, addr.CARRYING_SLOT_OFFSET)
		if slotCarrying[selSlot] ~= partnerSlot then
			updateInventories()
			
			if partnerSlot ~= 0 then
				logAtLoc(" carries " .. nameFromSlot(partnerSlot) .. " " .. relativeMoveStr(selSlot))

				updateNextStopSkip()
			else
				local direction = "? "
				
				local xDiff = addr.byteFromSlot(slotCarrying[selSlot], addr.X_OFFSET) - 
					addr.byteFromSlot(selSlot, addr.X_OFFSET)
				
				if xDiff > 0 then
					direction = "> "
				elseif xDiff < 0 then
					direction = "< "
				else
					local yDiff = addr.byteFromSlot(slotCarrying[selSlot], addr.Y_OFFSET) - 
						addr.byteFromSlot(selSlot, addr.Y_OFFSET)
				
					if yDiff > 0 then
						direction = "v "
					elseif yDiff < 0 then
						direction = "^ "
					end
				end
			
				logAtLoc(" drops " .. direction .. slotLocString(slotCarrying[selSlot]))
					
				updateNextStopSkip()
			end
			
			updateLoc(selSlot)
			slotCarrying[selSlot] = partnerSlot
		end
		
		
		
		if slotIsStopped[selSlot] ~= addr.unitIsStopped(selSlot) then
			slotIsStopped[selSlot] = addr.unitIsStopped(selSlot)
			
			updateInventories()
			
			if slotIsStopped[selSlot] then
				if skipNextStopAt.x == addr.byteFromSlot(selSlot, addr.X_OFFSET) and
				   skipNextStopAt.y == addr.byteFromSlot(selSlot, addr.Y_OFFSET) then
				   
					-- if unit is moved from this spot, may not want to skip stop log at this tile next time
					skipNextStopAt.x = -1
					skipNextStopAt.y = -1
				   
					print("skipped stop")
					logs[skipNextStopAt.logNumber].str = logs[skipNextStopAt.logNumber].str .. 
						" " .. relativeMoveStr(selSlot)
				else
					logAtLoc(" stops " .. relativeMoveStr(selSlot))
				end
			end
			
			updateLoc(selSlot)
			
			for slot = 1, lastDeployedSlot do
				if addr.byteFromSlot(slot, addr.X_OFFSET) ~= 255 then
					if slotIsStopped[slot] ~= addr.unitIsStopped(slot) then
						slotIsStopped[slot] = addr.unitIsStopped(slot)
						
						if not slotIsStopped[slot] then
							P.addLog(slotLocString(slot) .. " refreshes")
						end
					end
					
					if (slotLoc[slot].x ~= addr.byteFromSlot(slot, addr.X_OFFSET) or
						slotLoc[slot].y ~= addr.byteFromSlot(slot, addr.Y_OFFSET)) and
					   not addr.unitIsRescued(slot) then
						
						P.addLog(slotLocString(slot) .. " was warped")
					end
					
					updateLoc(slot)
				end
			end
		end
	end
	
	
	
	if currMoney ~= addr.getMoney() then
		updateInventories()
		
		logAtLoc(string.format(" changes money: %6d %+7d -> %6d",
			currMoney, 
			addr.getMoney() - currMoney, 
			addr.getMoney()))
			
		currMoney = addr.getMoney()
	end
end



function P.addLog_RNconsumed()	
	local rnsUsed = rns.rng1.pos - rns.rng1.prevPos
	
	local function line(combatant)
		return string.format("at %2d,%2d %s with %d use %s",
			combatant.x,
			combatant.y,
			combatant.name,
			combatant.weaponUses,
			combatant.weapon)
	end
	
	if currPhase == "player" then
		if lastEvent.length == rnsUsed then
			P.addLog(line(lastEvent.combatants.attacker))
			updateNextStopSkip()
			P.addLog(line(lastEvent.combatants.defender))
			
			local resultStr = ""
			if lastEvent.hasCombat then
				resultStr = resultStr .. combat.hitSeq_string(lastEvent.mHitSeq)
			end
			if lastEvent:levelDetected() then
				resultStr = resultStr .. " " .. lastEvent.unit:levelUpProcs_string(lastEvent.postCombatRN_i)
			end
			
			P.addLog(resultStr)
			
			-- don't want to log durability reduction from combat
			-- todo restructure combat hitSeq to output hp and weapon durability, and input prior hitSeq
			-- local selSlot = memory.readbyte(addr.SELECTED_SLOT)
			-- slotEquipedUses[selSlot][1] = addr.byteFromSlot(selSlot, addr.ITEMS_OFFSET + 1)
			-- RAM does not update fast enough?
		else
			P.addLog("Event does not match rns")
			print()
			print("Event does not match rns", lastEvent.length, rnsUsed, lastEvent:headerString())
		end
	elseif rnsUsed > 1 and newEvent then -- neglects enemy staff, but slots update even for some burns
		P.addLog("Enemy event?")
		P.addLog(line(lastEvent.combatants.attacker))
		P.addLog(line(lastEvent.combatants.defender))
		newEvent = false
	end
	
	P.addLog(string.format("RN %5d->%5d (%d)", rns.rng1.prevPos, rns.rng1.pos, rnsUsed))
end

function P.addLog(str)
	local newLog = {}
	newLog.frame = emu.framecount()
	newLog.str = str

	logCount = logCount + 1
	logs[logCount] = newLog
end

-- note this saves under vba movie directory when running movie
function P.writeLogs()
	local fileName = string.format("fe%dch%d-%d-%d.autolog.txt",
		GAME_VERSION,
		memory.readbyte(addr.CHAPTER),
		os.time(),
		filesWritten)
		
	local f = io.open(fileName, "w")
	
	for i = 1, logCount do
		f:write(logs[i].str, "\n")
	end
	
	f:close()
	filesWritten = filesWritten + 1
	print("wrote " .. fileName)
end

return P