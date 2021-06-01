require("fe_rnEvent")

local P = {}
autolog = P




local nodeObj = {}

local uniqueID = 0
function nodeObj:new(parent, text, colorSegments)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	
	if parent then
		o.turn = memory.readbyte(addr.TURN)
		o.phase = addr.getPhase()
		o.RN = rns.rng1.pos
		
		o.text = text
		
		o.parent = parent
		o.depth = parent.depth + 1
		
		table.insert(parent.children, o)
		parent.children.sel_i = #parent.children
		
		if #parent.children > 1 then
			print("Added autolog branch " .. o:pathString())
		end
	else
		o.turn = 0
		o.phase = "prep"
		o.RN = 0
		
		o.text = "Root"

		o.depth = 0
	end
	
	o.colorSegments = colorSegments or {}
	o.children = {}
	o.uniqueID = uniqueID
	uniqueID = uniqueID + 1
	return o
end

local root = nodeObj:new()
local currNode = root
P.GUInode = root

function nodeObj:pathString()
	local path = ""
	
	local traceNode = self
	while traceNode.parent do
		if #traceNode.parent.children > 1 then
			for i, child in ipairs(traceNode.parent.children) do
				if child == traceNode then
					path = "," .. i .. path
					break
				end
			end
		end
		traceNode = traceNode.parent
	end
	
	return "root" .. path
end

function nodeObj:setAsPath()
	local traceNode = self
	while traceNode.parent do
		if #traceNode.parent.children > 1 then
			for i, child in ipairs(traceNode.parent.children) do
				if child == traceNode then
					traceNode.parent.children.sel_i = i
					break
				end
			end
		end
		traceNode = traceNode.parent
	end
end

function nodeObj:isSynced()
	return self.turn == memory.readbyte(addr.TURN) and self.phase == addr.getPhase() and self.RN == rns.rng1.pos
end

-- Combine children into common table which both parents point to.
-- Each child points to original parent, which can cause depth mismatches among step-siblings.
function nodeObj:marry(spouse)
	if self == spouse then
		print("Cannot marry self.")
		return
	end

	for _, stepchild in ipairs(spouse.children) do
		local stepchildIsDuplicate = false
	
		for _, child in ipairs(self.children) do
			if stepchild.text == child.text then
				stepchildIsDuplicate = true
				child:marry(stepchild) -- join subtrees recursively
				break
			end
		end
		
		if not stepchildIsDuplicate then
			table.insert(self.children, stepchild)
		end
	end
	
	print("Married " .. self.text .. " to " .. spouse.text)
	spouse.children = self.children
end

local savedNodes = {}
function nodeObj:GUIstring()
	-- construct GUI prefix
	local str = " "
	
	-- mark savestate
	for i = 1, 10 do
		if self == savedNodes[i] then
			str = i % 10
			break
		end
	end
	
	-- mark branching point
	if #self.children > 1 then
		str = str .. "+"
	else
		str = str .. " "
	end
	
	-- mark current
	if self == currNode then
		str = str .. "c"
	else
		str = str .. " "
	end
	
	-- mark selection
	if self.depth == P.GUInode.depth then
		str = str .. ">"
	else
		str = str .. " "
	end
	
	local colorSegs = {{5}}
	if str == "    " then
		str = string.format("%04d", self.depth % 1000)
		colorSegs = {{5, colorUtil.grey, colorUtil.darkGrey}}
	end

	
	for _, seg in ipairs(self.colorSegments) do
		table.insert(colorSegs, seg)
	end

	str = str .. " " .. self.text
	
	if #self.children > 1 then
		str = str .. string.format(" %d/%d", self.children.sel_i, #self.children)
	end
	
	return str, colorSegs
end




function P.addLog(text, colorSegments)
	for i, child in ipairs(currNode.children) do
		if child.text == text then
			-- forward-track instead of creating a duplicate node/branch			
			currNode.children.sel_i = i
			currNode = child
			P.GUInode = currNode
			return
		end
	end
	
	currNode = nodeObj:new(currNode, text, colorSegments)
	P.GUInode = currNode
end

local function addLogItem(name, i, itemID, uses, includeName)
	local namePrefix = string.rep(" ", name:len() + 7) -- blank for subsequent lines
	if includeName then
		namePrefix = name .. "'s item"
	end

	P.addLog(string.format("%s %d: %s %2d",
						   namePrefix,
						   i,
						   combat.ITEM_NAMES[itemID],
						   uses),
			 {unitData.units[name].colorSegment, 
			  {8, colorUtil.grey, colorUtil.darkGrey},
			  {3, colorUtil.interpolate((i - 1)/4, colorUtil.blueToRed)},
			  combat.ITEM_COLOR_SEGS[itemID],
			  {3, colorUtil.interpolate(uses/45, colorUtil.redToBlue)}})
end

P.addLog("Log start", {{9, colorUtil.yellow}})




-- combat RAM may not all be updated within one frame
-- attacker slot is updated when unit selects "attack"
-- defender slot is updated when unit selects weapon
-- hit and crit set to 0, then correct value next frame?

local function nameFromSlot(slot)
	return unitData.hexCodeToName(addr.wordFromSlot(slot, addr.NAME_CODE_OFFSET))
end

local function locAndNameFromSlot(slot)
	local name = nameFromSlot(slot)
	local unit = unitData.units[name] or unitData.units[0]

	return string.format("at %2d,%2d %s",
						 addr.byteFromSlot(slot, addr.X_OFFSET),
						 addr.byteFromSlot(slot, addr.Y_OFFSET),
						 name), 
		   {{9, colorUtil.grey}, 
			unit.colorSegment}
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

local function relativeMoveStr(slot)
	slot = slot or memory.readbyte(addr.SELECTED_SLOT)

	local xChange = addr.byteFromSlot(slot, addr.X_OFFSET) - slotData[slot].x
	local yChange = addr.byteFromSlot(slot, addr.Y_OFFSET) - slotData[slot].y
	
	if xChange == 0 and yChange == 0 then
		return "", {} -- don't return what will be an extra space
	end

	local function changeStr(change, arrow, reverse)
		if change < 0 then 
			arrow = reverse
			change = -change
		end
		if change > 3 then
			return arrow .. change
		end
		return string.rep(arrow, change)
	end

	local function changeColorSegs(change, colorA, colorB)
		if change < 0 then 
			colorA = colorB
			change = -change
		end
		if change > 3 then
			return {2, colorA, colorUtil.darken(colorA)}
		end
		return {change, colorA, colorUtil.darken(colorA)}
	end

	return " " .. changeStr(xChange, ">", "<") .. changeStr(yChange, "v", "^"), 
		   {{1}, changeColorSegs(xChange, colorUtil.right, colorUtil.left), changeColorSegs(yChange, colorUtil.down, colorUtil.up)}
end

local function updateLoc(slot)
	slotData[slot].x = addr.byteFromSlot(slot, addr.X_OFFSET)
	slotData[slot].y = addr.byteFromSlot(slot, addr.Y_OFFSET)
end

local function reloadSlot(slot)
	updateLoc(slot)
	slotData[slot].isStopped = addr.unitIsStopped(slot)
	slotData[slot].carrying = addr.byteFromSlot(slot, addr.CARRYING_SLOT_OFFSET)
	
	for i = 1, 5 do
		local offset = 2 * i - 2
		slotData[slot].items[i] = addr.byteFromSlot(slot, addr.ITEMS_OFFSET + offset)
		slotData[slot].uses[i] = addr.byteFromSlot(slot, addr.ITEMS_OFFSET + offset + 1)
	end
end

-- player slots begin with deployed units, then undeployed, then recruited this chapter
local lastPlayerSlot = 1
local function updateLastPlayerSlot()
	while addr.wordFromSlot(lastPlayerSlot + 1, addr.NAME_CODE_OFFSET) ~= 0 do
		lastPlayerSlot = lastPlayerSlot + 1
		
		if addr.byteFromSlot(lastPlayerSlot, addr.RANKS_OFFSET + 4) > 0 then
			rnEvent.IS_HEALER_DEPLOYED = true
			print("healer is deployed", nameFromSlot(lastPlayerSlot)) -- todo bugged
		end
	end
	
	while addr.wordFromSlot(lastPlayerSlot, addr.NAME_CODE_OFFSET) == 0 and lastPlayerSlot > 1 do
		lastPlayerSlot = lastPlayerSlot - 1
	end
end
updateLastPlayerSlot()

local function checkRecruitment()
	while addr.wordFromSlot(lastPlayerSlot + 1, addr.NAME_CODE_OFFSET) ~= 0 do
		lastPlayerSlot = lastPlayerSlot + 1
		
		if addr.byteFromSlot(lastPlayerSlot, addr.RANKS_OFFSET + 4) > 0 then
			rnEvent.IS_HEALER_DEPLOYED = true
			print("healer is deployed", nameFromSlot(lastPlayerSlot)) -- todo bugged
		end
		
		if addr.byteFromSlot(lastPlayerSlot, addr.X_OFFSET) ~= 255 then
			local str, colorSegs = locAndNameFromSlot(lastPlayerSlot)
			
			table.insert(colorSegs, {6, {r = 127, g = 127, b = 255}})
			
			P.addLog(str .. " joins", colorSegs)
			reloadSlot(lastPlayerSlot)
		end
	end
end

-- We don't want to log inventories each frame,
-- since items may be swapped around while trying different combats.
-- Log only when a unit's movement status changes.
-- Don't log changes in inventory due only to combat since they are redundant clutter.
local function updateAllInventories()
	for slot = 1, lastPlayerSlot do -- until empty player slots
		if addr.byteFromSlot(slot, addr.X_OFFSET) ~= 255 then

			local includeName = true
			for i = 1, 5 do

				local itemID = addr.byteFromSlot(slot, addr.ITEMS_OFFSET + 2 * i - 2)
				local uses = addr.byteFromSlot(slot, addr.ITEMS_OFFSET + 2 * i - 1)
				
				if slotData[slot].items[i] ~= itemID or slotData[slot].uses[i] ~= uses then
				   
					slotData[slot].items[i] = itemID
					slotData[slot].uses[i] = uses
					addLogItem(nameFromSlot(slot), i, itemID, uses, includeName)
					includeName = false

				end
			end
		end
	end
end

local function othersExist() -- todo
	-- enemies begin at slot 129, note that enemy boss is sometimes at 63??
	--for slot = 65, 128 do
		--if addr.wordFromSlot(slot, addr.NAME_CODE_OFFSET) ~= 0 and 
			--addr.byteFromSlot(slot, addr.X_OFFSET) ~= 255 then
			--print("other at slot", slot, nameFromSlot(slot))
			--return true
		--end
	--end
	return false
end

local prevRN = 0
local currTurn = -1
local currPhase = "player"
local currMoney = addr.getMoney()

local skipNextStopLogAt = {}
-- Don't add redundant log that a unit stopped after certain logs (combat, carry/drop, change money),
-- because a unit may canto (including after combat in FE7 if on a "trapped" tile).
-- Mark the spot: if they stop there, skip the stop log.
-- If they canto off, also log where they stop as normal.
-- Either way, then clear skipNextStopLogAt.
local function skipNextStopLog()
	skipNextStopLogAt.x = addr.byteFromSlot(memory.readbyte(addr.SELECTED_SLOT), addr.X_OFFSET)
	skipNextStopLogAt.y = addr.byteFromSlot(memory.readbyte(addr.SELECTED_SLOT), addr.Y_OFFSET)
end

-- updateLastPlayerSlot(), prevRN, currTurn, currPhase, currMoney, reloadSlot(), skipNextStopLogAt
local function reloadAll()
	updateLastPlayerSlot()

	prevRN = rns.rng1.pos
	currTurn = memory.readbyte(addr.TURN)
	currPhase = addr.getPhase()
	currMoney = addr.getMoney()
	
	for slot = 1, lastPlayerSlot do
		reloadSlot(slot)
	end
	
	skipNextStopLogAt.x = -1
	skipNextStopLogAt.y = -1
end

-- select merlinus before ending chapter if possible to capture his level up
function P.addLog_RNconsumed()
	local rnsUsed = rns.rng1.pos - prevRN
	if rnsUsed < 0 then return end -- don't create a log for the user reverting to savestate
	
	local lastEvent = rnEvent.rnEventObj:new()
	lastEvent.startRN_i = prevRN
	lastEvent.postBurnsRN_i = prevRN
	lastEvent:updateFull()
	
	local a = lastEvent.combatants.attacker
	local d = lastEvent.combatants.defender
	
	-- slot may be erased by now, use combatant data
	local aLoc = string.format("at %2d,%2d %s", a.x, a.y, a.name)
	local dLoc = string.format("at %2d,%2d %s", d.x, d.y, d.name)

	local aSegs = {{9, colorUtil.grey}, unitData.units[a.name].colorSegment}
	
	if lastEvent.length ~= rnsUsed then 
		-- reinforcements may consume rns after start of player phase but before game displays "player phase"
		if rnsUsed % 12 == 0 then
			P.addLog(aLoc .. " reinforcements? " .. rnsUsed, aSegs)
		end
		
		if currPhase == "player" then
			P.addLog(aLoc .. " burn? " .. rnsUsed, aSegs)
		end
		return
	end
	
	local aWep = string.format(" %s %2d", a.weapon, a.weaponUses)
	local dWep = string.format(" %s %2d", d.weapon, d.weaponUses)

	local dSegs = {{9, colorUtil.grey}, 
				   {d.name:len(), colorUtil.red, colorUtil.black}, 
				   {1},
				   combat.ITEM_COLOR_SEGS[d.weaponCode], 
				   {3, colorUtil.interpolate(d.weaponUses/45, colorUtil.redToBlue)}}
	
	local resultStr = ""
	if lastEvent.hasCombat then
		resultStr = resultStr .. " " .. combat.hitSeq_string(lastEvent.mHitSeq)
	end
	if lastEvent:levelDetected() then
		resultStr = resultStr .. " " .. lastEvent.unit:levelUpProcs_string(lastEvent.postCombatRN_i)
	end
	
	if currPhase == "player" then
		skipNextStopLog()
		
		local rmStr, rmSegs = relativeMoveStr()
		insertAll(aSegs, rmSegs)

		if lastEvent.hasCombat then
			table.insert(aSegs, {1})
			table.insert(aSegs, combat.ITEM_COLOR_SEGS[a.weaponCode])
			table.insert(aSegs, {3, colorUtil.interpolate(a.weaponUses/45, colorUtil.redToBlue)})

			P.addLog(aLoc .. rmStr .. aWep .. resultStr, aSegs)
			
			P.addLog(dLoc .. dWep, dSegs)
			
			-- moving items down in inventory to clear 1st for equipped weapon is not necessarily redundant, 
			-- since we might also swap 2nd or more weapons manually
			
			slotData[a.slot].items[1] = addr.byteFromSlot(a.slot, addr.ITEMS_OFFSET)
			-- item durability not yet updated in RAM, manually update
			slotData[a.slot].uses[1] = lastEvent.mHitSeq.attacker.endUses
			
		elseif lastEvent:levelDetected() then
			P.addLog(aLoc .. rmStr .. resultStr, aSegs)
		end
		
		P.addLog(string.format("RN %5d->%5d (%+d)", rns.rng1.prevPos, rns.rng1.pos, rnsUsed))
	
	-- don't match with last event of player phase
	elseif a.slot > lastPlayerSlot then
		table.insert(aSegs, combat.ITEM_COLOR_SEGS[a.weaponCode])
		table.insert(aSegs, {3, colorUtil.interpolate(a.weaponUses/45, colorUtil.redToBlue)})

		-- possible for AI movement burns to have a false match with length of last event
		P.addLog(aLoc .. aWep)
		P.addLog(dLoc .. dWep .. resultStr)
		P.addLog(string.format("RN %5d->%5d (%+d) AI event?", rns.rng1.prevPos, rns.rng1.pos, rnsUsed))
	end
end




-- public tree functions

local logIsSynced = true
local resyncFailedThisFrame = false
local prevFrame = emu.framecount() - 1

function P.attemptSync(node)
	if node:isSynced() then
		if not logIsSynced then
			logIsSynced = true
			print("Now resynced! Logging resumed.")
		end
		reloadAll()
	else
		resyncFailedThisFrame = true
		print("Sync failed")
	end
	currNode = node
	P.GUInode = currNode
	currNode:setAsPath()
end

function P.attemptMarriage(node)
	if currNode:isSynced() and node:isSynced() then
		currNode:marry(node)
	else
		print("Marriage attempt failed, need both nodes synced.")
	end
end

function P.saveNode(i)
	if currNode:isSynced() then
		savedNodes[i] = currNode
		print("Log saved state " .. i)
	else
		print("Log can't save state " .. i .. ", not synced")
	end
end

function P.loadNode(i)
	if savedNodes[i] then
		P.attemptSync(savedNodes[i])
	else
		print("Log can't load state " .. i .. ", attempting save...")
		P.saveNode(i)
	end
end




-- Run every frame.
function P.passiveUpdate()
	if prevFrame ~= emu.framecount() - 1 or resyncFailedThisFrame then
		if not currNode:isSynced() then
			print()
			print("WARNING! Log desync.")
			print("Current node on path " .. currNode:pathString() .. " expects:")
			print("Turn " .. currNode.turn .. " " .. currNode.phase .. " phase, RN " .. currNode.RN)
			print("Select node and press select to try resync.")
			logIsSynced = false
		end
	end
	
	prevFrame = emu.framecount()
	resyncFailedThisFrame = false
	
	if not logIsSynced then return end
	
	-- note turn 1 may begin with cutscene when units are not deployed if no preps
	if (currTurn ~= memory.readbyte(addr.TURN)) or (currPhase ~= addr.getPhase()) then
		
		-- don't want to log each "refresh" at the start of turn, 
		-- or items since these should be known from last player phase
		reloadAll()
		
		if currPhase ~= "other" or othersExist() then -- othersExist may not update in time if an other is deploying?
			P.addLog("")
			P.addLog(string.format("Turn %d %s phase, RN %d",
								   currTurn,
								   currPhase,
								   rns.rng1.pos),
					 {{7 + math.floor(math.log(currTurn, 10)), colorUtil.yellow},
					  {currPhase:len() + 6, colorUtil.phaseColors[currPhase]}})
		end
		
		if currTurn == 1 and currPhase == "player" then
			for slot = 1, lastPlayerSlot do
				if addr.byteFromSlot(slot, addr.X_OFFSET) ~= 255 then
				
					local str, colorSegs = locAndNameFromSlot(slot)
					table.insert(colorSegs, {6, colorUtil.white, colorUtil.darken(colorUtil.green)})
					P.addLog(str .. " start", colorSegs)
				
					local includeName = true
					for i = 1, 5 do

						if slotData[slot].uses[i] == 0 then
							break
						end
						addLogItem(nameFromSlot(slot), i, slotData[slot].items[i], slotData[slot].uses[i], includeName)
						includeName = false

					end
				end
			end
			P.addLog("")
		end
	end
	
	
	
	local selSlot = memory.readbyte(addr.SELECTED_SLOT)
		
	local function logAtLoc(inputStr, colorSegments, slot)
		slot = slot or selSlot

		local buildingStr = ""
		local buildingSegments = {}

		local tempStr, nextSegs = locAndNameFromSlot(slot)
		buildingStr = buildingStr .. tempStr
		insertAll(buildingSegments, nextSegs)

		tempStr, nextSegs = relativeMoveStr(slot)
		buildingStr = buildingStr .. tempStr
		insertAll(buildingSegments, nextSegs)

		buildingStr = buildingStr .. inputStr
		insertAll(buildingSegments, colorSegments)

		P.addLog(buildingStr, buildingSegments)
	end
	
	if addr.getPhase() == "player" and selSlot <= lastPlayerSlot then -- check movements
	
		-- only selected unit should check for stopping
		-- after stopping, check for refresh, inventory
		-- check for carried unit
		-- if was 0 and now is not, log carry
		-- if was not 0 and now is, log drop
		
		local newCarry = addr.byteFromSlot(selSlot, addr.CARRYING_SLOT_OFFSET)
		if slotData[selSlot].carrying ~= newCarry then
			updateAllInventories()
			
			local logStr = " carry " .. nameFromSlot(newCarry)
			local colorSegments = {{7, colorUtil.orange}}
			
			if newCarry == 0 then
				local xDiff = addr.byteFromSlot(slotData[selSlot].carrying, addr.X_OFFSET) - 
					addr.byteFromSlot(selSlot, addr.X_OFFSET)
				
				if xDiff > 0 then
					logStr = " drop >"
					colorSegments = {{7, colorUtil.right}}
				elseif xDiff < 0 then
					logStr = " drop <"
					colorSegments = {{7, colorUtil.left}}
				else
					local yDiff = addr.byteFromSlot(slotData[selSlot].carrying, addr.Y_OFFSET) - 
						addr.byteFromSlot(selSlot, addr.Y_OFFSET)
				
					if yDiff > 0 then
						logStr = " drop v"
						colorSegments = {{7, colorUtil.down}}
					elseif yDiff < 0 then
						logStr = " drop ^"
						colorSegments = {{7, colorUtil.up}}
					end
				end
				updateLoc(slotData[selSlot].carrying)
			else
				table.insert(colorSegments, unitData.units[nameFromSlot(newCarry)].colorSegment)
			end
			
			logAtLoc(logStr, colorSegments)
			updateLoc(selSlot)
			skipNextStopLog()
			
			slotData[selSlot].carrying = newCarry
		end
		
		
		
		if slotData[selSlot].isStopped ~= addr.unitIsStopped(selSlot) then
			slotData[selSlot].isStopped = addr.unitIsStopped(selSlot)
			
			checkRecruitment()
			updateAllInventories()
			
			if slotData[selSlot].isStopped then
				if skipNextStopLogAt.x == addr.byteFromSlot(selSlot, addr.X_OFFSET) and
				   skipNextStopLogAt.y == addr.byteFromSlot(selSlot, addr.Y_OFFSET) then
				   
					-- if unit is moved from this spot, may not want to skip stop log at this tile next time
					skipNextStopLogAt.x = -1
					skipNextStopLogAt.y = -1
				else
					logAtLoc(" stop", {{5, colorUtil.red, colorUtil.black}})
				end
			end
			
			updateLoc(selSlot)
			
			for slot = 1, lastPlayerSlot do
				if addr.byteFromSlot(slot, addr.X_OFFSET) ~= 255 then
					if slotData[slot].isStopped ~= addr.unitIsStopped(slot) then
						slotData[slot].isStopped = addr.unitIsStopped(slot)
						
						if not slotData[slot].isStopped then
							logAtLoc(" refresh", {{8, colorUtil.white, colorUtil.darken(colorUtil.green)}}, slot)
						end
					end
					
					if (slotData[slot].x ~= addr.byteFromSlot(slot, addr.X_OFFSET) or
						slotData[slot].y ~= addr.byteFromSlot(slot, addr.Y_OFFSET)) and
					   not addr.unitIsRescued(slot) then
						
						logAtLoc(" warp", {{5, colorUtil.white, colorUtil.darken(colorUtil.violet)}}, slot)
					end
					
					updateLoc(slot)
				end
			end
		end
	end
	
	
	
	if currMoney ~= addr.getMoney() then
		updateAllInventories()
		
		logAtLoc(string.format(" shop %6d %+6d", currMoney, addr.getMoney() - currMoney),
				 {19, colorUtil.yellow})
		updateLoc(selSlot)
		skipNextStopLog()
		
		currMoney = addr.getMoney()
	end

	
	
	if prevRN ~= rns.rng1.pos then
		P.addLog_RNconsumed()
		prevRN = rns.rng1.pos
	end
end

-- Up to 16 strings, first use children, then parents.
-- Window fits up to 59 chars.
function P.GUIstrings()
	local nodeToRead = P.GUInode
	
	local str, colorSeg = nodeToRead:GUIstring()
	
	local strs = {str}
	local colorSegmentsList = {colorSeg}
	
	while #nodeToRead.children > 0 and #strs < 16 do
		nodeToRead = selected(nodeToRead.children)
		str, colorSeg = nodeToRead:GUIstring()
		
		table.insert(strs, str)
		table.insert(colorSegmentsList, colorSeg)
	end
	
	nodeToRead = P.GUInode
	while nodeToRead.parent and #strs < 16 do
		nodeToRead = nodeToRead.parent
		str, colorSeg = nodeToRead:GUIstring()
		
		table.insert(strs, 1, str)
		table.insert(colorSegmentsList, 1, colorSeg)
	end
	
	return strs, colorSegmentsList
end

local filesWritten = 0
-- Note this saves under vba movie directory when running movie.
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