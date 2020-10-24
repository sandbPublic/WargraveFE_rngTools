require("fe_rnEvent")

local P = {}
autolog = P

local filesWritten = 0

local root = {}
root.depth = 0
root.frame = -1
root.text = "Start"

local currNode = root
P.GUInode = root

local function equalNodes(a, b)
	return a.depth == b.depth and a.frame == b.frame and a.text == b.text
end




-- up to 16 strings, first use children, then parents
-- string up to 60 chars
function P.GUIstrings()
	local strs = {}
	
	local function strFn(node)
		local childCount = 0
		if node.children then childCount = #node.children end
		
		local str = " "
		if equalNodes(node, currNode) then
			str = "<"
		end
		if childCount > 1 then
			str = str .. "+"
		else
			str = str .. " "
		end
		if node.depth == P.GUInode.depth then
			str = str .. ">"
		else
			str = str .. " "
		end
		if str == "   " then
			str = string.format("%5d ", node.depth % 10000)
		else
			str = str .. string.format("%02d ", node.depth % 100)
		end
	
		if childCount > 1 then
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
	if #currNode.children > 1 then
		print("Added autolog branch")
	end
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




-- combat RAM may not all be updated within one frame
-- attacker slot is updated when unit selects "attack"
-- defender slot is updated when unit selects weapon
-- hit and crit set to 0, then correct value next frame?




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




local currFrame = vba.framecount() - 1
local lastRN = 0
local currTurn = -1
local currPhase = "player"
local currMoney = addr.getMoney()




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
	while addr.wordFromSlot(lastPlayerSlot, addr.NAME_CODE_OFFSET) == 0 and lastPlayerSlot > 1 do
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

-- we don't want to log inventories each frame,
-- since items may be swapped around while trying different combats.
-- log only when a unit's movement status changes.
-- don't log changes in inventory due only to combat since they are redundant clutter.
local function updateInventories()
	for slot = 1, lastPlayerSlot do -- until empty player slots
		if addr.byteFromSlot(slot, addr.X_OFFSET) ~= 255 then
			local firstChangeLogged = false
			
			for i = 1, 5 do
				local offset = 2 * i - 2
				local item = addr.byteFromSlot(slot, addr.ITEMS_OFFSET + offset)
				local uses = addr.byteFromSlot(slot, addr.ITEMS_OFFSET + offset + 1)
				
				if slotData[slot].items[i] ~= item or 
				   slotData[slot].uses[i] ~= uses then
				   
					slotData[slot].items[i] = item
					slotData[slot].uses[i] = uses
					
					if firstChangeLogged then
						P.addLog(string.format("%s      %d: %s %2d",
							string.rep(" ", nameFromSlot(slot):len() + 2),
							i,
							combat.ITEM_NAMES[item],
							uses))
					else
						P.addLog(string.format("%s's item %d: %s %2d",
							nameFromSlot(slot),
							i,
							combat.ITEM_NAMES[item],
							uses))
						
						firstChangeLogged = true
					end
				end
			end
		end
	end
end

updateInventories()
P.addLog("") -- add space after initial inventory list

local function othersExist()
	return false -- todo
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
	if currFrame ~= vba.framecount() - 1 then
		print("autolog jump detected")
		
		currFrame = vba.framecount()
		while currNode.frame > currFrame do
			currNode = currNode.parent
		end
		while currNode.children and selected(currNode.children).frame <= currFrame do
			currNode = selected(currNode.children)
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
		
		skipNextStopLogAt.x = -1
		skipNextStopLogAt.y = -1
		
		lastRN = rns.rng1.pos
	end
	currFrame = vba.framecount()

	
	
	-- note turn 1 may begin with cutscene when units are not deployed if no preps
	if (currTurn ~= memory.readbyte(addr.TURN)) or (currPhase ~= getPhase()) then
		
		currTurn = memory.readbyte(addr.TURN)
		currPhase = getPhase()
		
		if currPhase ~= "other" or othersExist() then
		
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
		end
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

	
	
	if lastRN ~= rns.rng1.pos then
		P.addLog_RNconsumed()
		lastRN = rns.rng1.pos
	end
end

function P.addLog_RNconsumed()
	local rnsUsed = rns.rng1.pos - lastRN
	if rnsUsed < 0 then return end -- don't create a log for the user reverting to savestate
	
	local lastEvent = rnEvent.rnEventObj:new()
	lastEvent.startRN_i = lastRN
	lastEvent.postBurnsRN_i = lastRN
	lastEvent:updateFull()
	
	if lastEvent.length ~= rnsUsed then return end

	
	local a = lastEvent.combatants.attacker
	local d = lastEvent.combatants.defender
	
	-- slot may be erased by now, use combatant data
	local aLoc = string.format("at %2d,%2d %s", a.x, a.y, a.name)
	local dLoc = string.format("at %2d,%2d %s", d.x, d.y, d.name)
	
	local aWep = string.format(" %s %2d", a.weapon, a.weaponUses)
	local dWep = string.format(" %s %2d", d.weapon, d.weaponUses)
	
	local resultStr = ""
	if lastEvent.hasCombat then
		resultStr = resultStr .. " " .. combat.hitSeq_string(lastEvent.mHitSeq)
	end
	if lastEvent:levelDetected() then
		resultStr = resultStr .. " " .. lastEvent.unit:levelUpProcs_string(lastEvent.postCombatRN_i)
	end
	
	if currPhase == "player" then
		skipNextStopLog()
		
		if lastEvent.hasCombat then
			P.addLog(aLoc .. relativeMoveStr() .. aWep .. resultStr)
			
			P.addLog(dLoc .. dWep)
			
			-- moving items down in inventory to clear item#1 for equipped weapon is redundant, 
			-- update here and don't log during next update inventory
			for i = 1, 5 do
				local offset = 2 * i - 2
				slotData[a.slot].items[i] = addr.byteFromSlot(a.slot, addr.ITEMS_OFFSET + offset)
				slotData[a.slot].uses[i] = addr.byteFromSlot(a.slot, addr.ITEMS_OFFSET + offset + 1)
			end
			
			-- item durability not yet updated in RAM, manually update
			slotData[a.slot].uses[1] = lastEvent.mHitSeq.attacker.endUses
			
		elseif lastEvent:levelDetected() then
			P.addLog(aLoc .. relativeMoveStr() .. resultStr)
		end
		
		P.addLog(string.format("RN %5d->%5d (%+d)", rns.rng1.prevPos, rns.rng1.pos, rnsUsed))
	
	-- don't match with last event of player phase
	elseif a.slot > lastPlayerSlot then
		-- possible for AI movement burns to have a false match with length of last event
		P.addLog(aLoc .. aWep .. " AI event?")
		P.addLog(dLoc .. dWep .. resultStr)
		P.addLog(string.format("RN %5d->%5d (%+d)", rns.rng1.prevPos, rns.rng1.pos, rnsUsed))
	end
end

return P