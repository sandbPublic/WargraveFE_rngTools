require("fe_rnEvent")

local P = {}
autolog = P

local filesWritten = 0


local root = {}
root.depth = 0
root.frame = -1
root.text = "Root"

local currNode = root
P.GUInode = root

local function equalNodes(a, b)
	return a.depth == b.depth and a.frame == b.frame and a.text == b.text
end


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
local lastEvent
local lastAttackerID = -1 -- slot 0 may be snag/wall
local lastDefenderID = -1
local nextUpdateFrame = -1
-- helps distinguish enemy rn burns from events,
-- since we don't reverse construct EP events after combats
local newEvent = false 
local function updateLastEvent()
	lastEvent = rnEvent.rnEventObj:new()
	lastEvent.startRN_i = rns.rng1.pos
	lastEvent.postBurnsRN_i = rns.rng1.pos
	lastEvent:updateFull()	
	newEvent = true
end
updateLastEvent()




-- don't add redundant log that a unit stopped after certain logs (combat, carry/drop, change money)
-- because a unit may canto (including after combat in FE7 if on a "trapped" tile)
-- mark the spot: if they stop on that spot, skip the stop log
-- if they canto off, also log where they stop as normal
-- either way, then clear skipNextStopLogAt
local skipNextStopLogAt = {}
local function skipNextStopLog()
	skipNextStopLogAt.x = addr.byteFromSlot(memory.readbyte(addr.SELECTED_SLOT), addr.X_OFFSET)
	skipNextStopLogAt.y = addr.byteFromSlot(memory.readbyte(addr.SELECTED_SLOT), addr.Y_OFFSET)
end




local currTurn = -1
local currPhase = "player"
local currMoney = 0




local function nameFromSlot(slot)
	return unitData.hexCodeToName(addr.wordFromSlot(slot, addr.NAME_CODE_OFFSET))
end

local slotData = {}
for slot = 0, 255 do
	slotData[slot] = {}
	slotData[slot].x = -1
	slotData[slot].y = -1
	slotData[slot].isStopped = false
	slotData[slot].carrying = 0
	slotData[slot].items = {0, 0, 0, 0, 0}
	slotData[slot].uses = {0, 0, 0, 0, 0}
end

-- player slots begin with deployed units, then undeployed, then recruited this chapter
local lastPlayerSlot = 1
local function updateLastPlayerSlot()
	while addr.wordFromSlot(lastPlayerSlot + 1, addr.NAME_CODE_OFFSET) ~= 0 do
		lastPlayerSlot = lastPlayerSlot + 1
	end
	while addr.wordFromSlot(lastPlayerSlot, addr.NAME_CODE_OFFSET) == 0 do
		lastPlayerSlot = lastPlayerSlot - 1
	end
end
updateLastPlayerSlot()

local function updateLoc(slot)
	slotData[slot].x = addr.byteFromSlot(slot, addr.X_OFFSET)
	slotData[slot].y = addr.byteFromSlot(slot, addr.Y_OFFSET)
end

local function relativeMoveStr(slot)
	slot = slot or memory.readbyte(addr.SELECTED_SLOT)

	local xChange = addr.byteFromSlot(slot, addr.X_OFFSET) - slotData[slot].x
	local yChange = addr.byteFromSlot(slot, addr.Y_OFFSET) - slotData[slot].y
	
	local function changeStr(change, A, B)
		if change < 0 then 
			A = B
			change = -change
		end
		if change > 3 then
			return A .. change
		end
		return string.rep(A, change)
	end
	
	if xChange == 0 and yChange == 0 then
		return "" -- don't return what will be an extra space
	else
		return " " .. changeStr(xChange, ">", "<") .. changeStr(yChange, "v", "^")
	end
end

local function slotLocString(slot)
	return string.format("at %2d,%2d %s",
		addr.byteFromSlot(slot, addr.X_OFFSET),
		addr.byteFromSlot(slot, addr.Y_OFFSET),
		nameFromSlot(slot))
end




function P.passiveUpdate()
	updateLastPlayerSlot()
	
	-- erase subsequent logs if jumped back via savestate
	-- script should be started at or before first savestate,
	-- so that first turn logs are not overwritten when jumping back
	-- this may desync volatiles like inventory and skipNextStopLogAt
	-- since they are deferred and don't create logs
	-- if between state A and B, inventory changed but is not logged, 
	-- jumping back to A and continuing will produce different logs than 
	-- jumping back to B (from B may be incomplete record of inventory)
	-- similarly skipNextStopLogAt must be lost (or potentially invalid from 
	-- deleted future)
	if currNode.frame > vba.framecount() then
		while currNode.frame > vba.framecount() do
			currNode = currNode.parent
		end
		P.GUInode = currNode
		
		currTurn = memory.readbyte(addr.TURN)
		currPhase = getPhase()
		currMoney = addr.getMoney()
		
		for slot = 1, lastPlayerSlot do
			updateLoc(slot)
			slotData[slot].isStopped = addr.unitIsStopped(slot)
			slotData[slot].carrying = addr.byteFromSlot(slot, addr.CARRYING_SLOT_OFFSET)
			
			for i = 1, 5 do
				local offset = 2 * i - 2
				slotData[slot].items[i] = addr.byteFromSlot(slot, addr.ITEMS_OFFSET + offset)
				slotData[slot].uses[i] = addr.byteFromSlot(slot, addr.ITEMS_OFFSET + offset + 1)
			end
		end
		
		lastAttackerID = -1
		lastDefenderID = -1
		
		skipNextStopLogAt.x = -1
		skipNextStopLogAt.y = -1
	end
	

	
	-- attacker slot is updated when unit selects "attack"
	-- defender slot is updated when unit selects weapon
	-- problem when attacking a snag/wall if initially defender slot == 0,
	-- since snags/walls have slot == 0, so the hp will not update from initial 0
	-- when the player selects a weapon since the slot didn't change
	-- in that case currHP == 0, update as well
    if (lastAttackerID ~= memory.readbyte(addr.ATTACKER_START + addr.SLOT_ID_OFFSET)) or 
	   (lastDefenderID ~= memory.readbyte(addr.DEFENDER_START + addr.SLOT_ID_OFFSET)) or 
	   (lastDefenderID == 0 and memory.readbyte(addr.DEFENDER_START + addr.CURR_HP_OFFSET) == 0) then
	   
		lastAttackerID = memory.readbyte(addr.ATTACKER_START + addr.SLOT_ID_OFFSET)
		lastDefenderID = memory.readbyte(addr.DEFENDER_START + addr.SLOT_ID_OFFSET)
		
		nextUpdateFrame = vba.framecount() + 1
		-- hit and crit may not be updated yet
	end
	
	if nextUpdateFrame == vba.framecount() then
		updateLastEvent()
	end


	
	-- we don't want to log inventories each frame,
	-- since items may be swapped around while trying different combats.
	-- log only when a turn, phase, or unit's movement status changes
	local function updateInventories()
		for slot = 1, lastPlayerSlot do -- until empty player slots
			if addr.byteFromSlot(slot, addr.X_OFFSET) ~= 255 then
				for i = 1, 5 do
					local offset = 2 * i - 2
					local item = addr.byteFromSlot(slot, addr.ITEMS_OFFSET + offset)
					local uses = addr.byteFromSlot(slot, addr.ITEMS_OFFSET + offset + 1)
					
					if slotData[slot].items[i] ~= item or 
					   slotData[slot].uses[i] ~= uses then
					   
						slotData[slot].items[i] = item
						slotData[slot].uses[i] = uses
						
						P.addLog(string.format("%s's item %d: %2d use %s",
							nameFromSlot(slot),
							i,
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
		
		P.addLog("")
		P.addLog("")
		P.addLog(string.format("Turn %d %s phase, RN %d",
			currTurn,
			currPhase,
			rns.rng1.pos))
				
		-- don't want to log each "refresh" at the start of turn
		for slot = 1, lastPlayerSlot do -- until empty player slots
			updateLoc(slot)
			slotData[slot].isStopped = addr.unitIsStopped(slot)
			slotData[slot].carrying = addr.byteFromSlot(slot, addr.CARRYING_SLOT_OFFSET)
		end
		
		updateInventories()
		
		P.addLog("") -- add space after initial inventory list
	end
	
	
	
	local selSlot = memory.readbyte(addr.SELECTED_SLOT)
		
	local function logAtLoc(str)
		P.addLog(slotLocString(selSlot) .. relativeMoveStr() .. str)
	end
	
	if getPhase() == "player" and selSlot <= lastPlayerSlot then -- check movements
	
		-- only selected unit should check for stopping
		-- after stopping, check for refresh, inventory
		-- check for carried unit
		-- if was 0 and is now not, log carry
		-- if wasn't 0 and now is, log drop
		
		local newCarry = addr.byteFromSlot(selSlot, addr.CARRYING_SLOT_OFFSET)
		if slotData[selSlot].carrying ~= newCarry then
			updateInventories()
			
			local logStr = " carry " .. nameFromSlot(newCarry)
			
			if newCarry == 0 then
				local xDiff = addr.byteFromSlot(slotData[selSlot].carrying, addr.X_OFFSET) - 
					addr.byteFromSlot(selSlot, addr.X_OFFSET)
				
				if xDiff > 0 then
					logStr = " drop >"
				elseif xDiff < 0 then
					logStr = " drop <"
				else
					local yDiff = addr.byteFromSlot(slotData[selSlot].carrying, addr.Y_OFFSET) - 
						addr.byteFromSlot(selSlot, addr.Y_OFFSET)
				
					if yDiff > 0 then
						logStr = " drop v"
					elseif yDiff < 0 then
						logStr = " drop ^"
					end
				end
				updateLoc(slotData[selSlot].carrying)
			end
			
			logAtLoc(logStr)
			updateLoc(selSlot)
			skipNextStopLog()
			
			slotData[selSlot].carrying = newCarry
		end
		
		
		
		if slotData[selSlot].isStopped ~= addr.unitIsStopped(selSlot) then
			slotData[selSlot].isStopped = addr.unitIsStopped(selSlot)
			
			updateInventories()
			
			if slotData[selSlot].isStopped then
				if skipNextStopLogAt.x == addr.byteFromSlot(selSlot, addr.X_OFFSET) and
				   skipNextStopLogAt.y == addr.byteFromSlot(selSlot, addr.Y_OFFSET) then
				   
					-- if unit is moved from this spot, may not want to skip stop log at this tile next time
					skipNextStopLogAt.x = -1
					skipNextStopLogAt.y = -1
				else
					logAtLoc(" stop")
				end
			end
			
			updateLoc(selSlot)
			
			for slot = 1, lastPlayerSlot do
				if addr.byteFromSlot(slot, addr.X_OFFSET) ~= 255 then
					if slotData[slot].isStopped ~= addr.unitIsStopped(slot) then
						slotData[slot].isStopped = addr.unitIsStopped(slot)
						
						if not slotData[slot].isStopped then
							P.addLog(slotLocString(slot) .. " refresh")
						end
					end
					
					if (slotData[slot].x ~= addr.byteFromSlot(slot, addr.X_OFFSET) or
						slotData[slot].y ~= addr.byteFromSlot(slot, addr.Y_OFFSET)) and
					   not addr.unitIsRescued(slot) then
						
						P.addLog(slotLocString(slot) .. " warp")
					end
					
					updateLoc(slot)
				end
			end
		end
	end
	
	
	
	if currMoney ~= addr.getMoney() then
		updateInventories()
		
		logAtLoc(string.format(" shop %6d %+6d", currMoney, addr.getMoney() - currMoney))
		updateLoc(selSlot)
		skipNextStopLog()
		
		currMoney = addr.getMoney()
	end
end



-- up to 16 strings, first use children, then parents
-- string up to 60 chars
function P.GUIstrings()
	local strs = {}
	
	local function strFn(node)
		local childCount = 0
		if node.children then childCount = #node.children end
		
		local str = string.format("%4d ", node.depth % 10000)
		if node.depth == P.GUInode.depth then
			str = string.format("->%2d ", node.depth % 100)
		elseif equalNodes(node, currNode) then
			str = string.format("-<%2d ", node.depth % 100)
		end
	
		if childCount > 1 then
			-- indicate branchs with +
			str = string.format("+%3d ", node.depth % 1000)
			if node.depth == P.GUInode.depth then
				str = string.format("+>%2d ", node.depth % 100)
			elseif equalNodes(node, currNode) then
				str = string.format("+<%2d ", node.depth % 100)
			end
			
			return str .. node.text .. string.format(" %d/%d", node.children.sel_i, childCount)
		end

		return str .. node.text
	end
	
	local nodeToRead = P.GUInode
	table.insert(strs, strFn(nodeToRead))
	
	while nodeToRead.children and #strs < 16 do
		nodeToRead = selected(nodeToRead.children)
		table.insert(strs, strFn(nodeToRead))
	end
	nodeToRead = P.GUInode
	while nodeToRead.parent and #strs < 16 do
		nodeToRead = nodeToRead.parent
		table.insert(strs, 1, strFn(nodeToRead)) -- insert at start
	end
	
	return strs
end

function P.addLog_RNconsumed()	
	local rnsUsed = rns.rng1.pos - rns.rng1.prevPos
	
	if rnsUsed < 0 then return end -- don't create a log for the user reverting to savestate
	
	local a = lastEvent.combatants.attacker
	local d = lastEvent.combatants.defender
	
	-- slot may be erased by now, use combatant data
	local aLoc = string.format("at %2d,%2d %s", a.x, a.y, a.name)
	local dLoc = string.format("at %2d,%2d %s", d.x, d.y, d.name)
	
	local aWep = string.format(" %s %d", a.weapon, a.weaponUses)
	local dWep = string.format(" %s %d", d.weapon, d.weaponUses)
	
	if currPhase == "player" then
		if lastEvent.length == rnsUsed then
			skipNextStopLog()
			
			if lastEvent.hasCombat then
				P.addLog(aLoc .. relativeMoveStr() .. aWep)
				
				P.addLog(dLoc .. dWep)
				
				-- item durability not yet updated in RAM, manually update
				slotData[a.slot].uses[1] = lastEvent.mHitSeq.attacker.endUses
				
				if lastEvent:levelDetected() then
					P.addLog(combat.hitSeq_string(lastEvent.mHitSeq) .. " " .. 
						lastEvent.unit:levelUpProcs_string(lastEvent.postCombatRN_i))
				else
					P.addLog(combat.hitSeq_string(lastEvent.mHitSeq))
				end
				
			elseif lastEvent:levelDetected() then
			
				P.addLog(aLoc .. relativeMoveStr() .. " " .. 
					lastEvent.unit:levelUpProcs_string(lastEvent.postCombatRN_i))
				
			end
		else
			P.addLog("Event does not match rns")
			print()
			print("Event does not match rns", lastEvent.length, rnsUsed, lastEvent:headerString())
		end
		
		P.addLog(string.format("RN %5d->%5d (%+d)", rns.rng1.prevPos, rns.rng1.pos, rnsUsed))
	elseif rnsUsed > 1 and newEvent then -- neglects enemy staff, but slots update even for some burns
		P.addLog("Enemy event?")
		P.addLog(aLoc .. aWep)
		P.addLog(dLoc .. dWep)
		newEvent = false
		P.addLog(string.format("RN %5d->%5d (%+d)", rns.rng1.prevPos, rns.rng1.pos, rnsUsed))
	end
end

function P.addLog(str)
	if currNode.children then
		for i, child in ipairs(currNode.children) do
			if child.text == str then
				-- forward-track instead of creating a redundant node/branch
			
				currNode.children.sel_i = i
				currNode = child
				P.GUInode = currNode
				
				-- move frames back if needed, for example
				-- node A at frame 1000, before savestate 1 at frame 1001
				-- node B at frame 2000
				-- jump to savestate 1, then complete B by frame 1500, then savestate 2 at 1501
				-- then jumping back to savestate 2 would unwind past B even though the state is later
				-- unless the frame for B is updated during the faster completion/forward-track
				if currNode.frame > emu.framecount() then
					currNode.frame = emu.framecount()
				end
				return
			end
		end
	else
		currNode.children = {}
	end
	
	local child = {}
	child.frame = emu.framecount()
	child.text = str
	child.parent = currNode
	child.depth = currNode.depth + 1
	table.insert(currNode.children, child)
	currNode.children.sel_i = #currNode.children
	currNode = child
	P.GUInode = currNode
end

-- note this saves under vba movie directory when running movie
function P.writeLogs()
	local fileName = string.format("fe%dmap%d-%d-%d.autolog.txt",
		GAME_VERSION,
		memory.readbyte(addr.MAP),
		os.time(),
		filesWritten)
		
	local f = io.open(fileName, "w")
	
	local nodeToWrite = root
	while nodeToWrite.children do
		nodeToWrite = selected(nodeToWrite.children)
		f:write(string.format("%4d  %s\n", nodeToWrite.depth, nodeToWrite.text))
	end
	
	f:close()
	filesWritten = filesWritten + 1
	print("wrote " .. fileName)
end

return P