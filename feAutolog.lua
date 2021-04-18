require("fe_rnEvent")

local P = {}
autolog = P

local filesWritten = 0




local nodeObj = {}

function nodeObj:new(parent, text)
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
	
	return o
end

function nodeObj:pathString()
	path = ""
	
	traceNode = self
	while traceNode.parent do
		if #traceNode.parent.children > 1 then
			for i, child in ipairs(traceNode.parent.children) do
				if child == self then
					path = "," .. i .. path
					break
				end
			end
		end
		traceNode = traceNode.parent
	end
	
	return "root" .. path
end

function nodeObj:isSynced()
	return self.turn == memory.readbyte(addr.TURN) and self.phase == addr.getPhase() and self.RN == rns.rng1.pos
end




local root = nodeObj:new()
local currNode = root
P.GUInode = root




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




-- non-modifying functions

local function nameFromSlot(slot)
	return unitData.hexCodeToName(addr.wordFromSlot(slot, addr.NAME_CODE_OFFSET))
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




local savedNodes = {}

-- up to 16 strings, first use children, then parents
-- string up to 59 chars
local CHAR_PER_LINE = 59
function P.GUIstrings()
	local strs = {}
	
	local nodeToRead = P.GUInode
	
	local function insert(atStart)
		local childCount = 0
		if nodeToRead.children then childCount = #nodeToRead.children end
		
		-- construct GUI prefix
		local str = " "
		
		-- mark savestate
		for i = 1, 10 do
			if nodeToRead == savedNodes[i] then
				str = i % 10
				break
			end
		end
		
		-- mark branching point
		if childCount > 1 then
			str = str .. "+"
		else
			str = str .. " "
		end
		
		-- mark current
		if nodeToRead == currNode then
			str = str .. "c"
		else
			str = str .. " "
		end
		
		-- mark selection
		if nodeToRead.depth == P.GUInode.depth then
			str = str .. ">"
		else
			str = str .. " "
		end
		
		if str == "    " then
			str = string.format("%04d", nodeToRead.depth % 1000)
		end
	
		str = str .. " " .. nodeToRead.text
		
		if childCount > 1 then
			str = str .. string.format(" %d/%d", nodeToRead.children.sel_i, childCount)
		end

		local multilines = {}
		while str:len() > CHAR_PER_LINE do
			table.insert(multilines, str:sub(1, CHAR_PER_LINE))
			str = str:sub(CHAR_PER_LINE + 1)
		end
		if str:len() > 0 then
			table.insert(multilines, str)
		end
		
		if atStart then -- add in reverse order
			local i = #multilines
			while i > 0 and #strs < 16 do
				table.insert(strs, 1, multilines[i])
				i = i - 1
			end
		else
			for _, line in ipairs(multilines) do
				if #strs < 16 then
					table.insert(strs, line)
				end
			end
		end
	end
	
	insert()
	while nodeToRead.children and #strs < 16 do
		nodeToRead = selected(nodeToRead.children)
		insert()
	end
	nodeToRead = P.GUInode
	while nodeToRead.parent and #strs < 16 do
		nodeToRead = nodeToRead.parent
		insert(true) -- insert at start
	end
	
	return strs
end

function P.addLog(text)
	if currNode.children then
		for i, child in ipairs(currNode.children) do
			if child.text == text then
				-- forward-track instead of creating a duplicate node/branch			
				currNode.children.sel_i = i
				currNode = child
				P.GUInode = currNode
				return
			end
		end
	else
		currNode.children = {}
	end
	
	currNode = nodeObj:new(currNode, text)
	P.GUInode = currNode
end

P.addLog("Log start")

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




local prevRN = 0
local currTurn = -1
local currPhase = "player"
local currMoney = addr.getMoney()




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
			print("healer is deployed", nameFromSlot(lastPlayerSlot))
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
			print("healer is deployed", nameFromSlot(lastPlayerSlot))
		end
		
		if addr.byteFromSlot(lastPlayerSlot, addr.X_OFFSET) ~= 255 then
			P.addLog(slotLocString(lastPlayerSlot) .. " joins")
			reloadSlot(lastPlayerSlot)
		end
	end
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
				rns.rng1.pos))
		end
		
		if currTurn == 1 and currPhase == "player" then
			for slot = 1, lastPlayerSlot do
				if addr.byteFromSlot(slot, addr.X_OFFSET) ~= 255 then
					P.addLog(slotLocString(slot) .. " start")
					local firstChangeLogged = false
					
					for i = 1, 5 do
						if slotData[slot].uses[i] == 0 then
							break
						end
						if firstChangeLogged then
							P.addLog(string.format("%s      %d: %s %2d",
								string.rep(" ", nameFromSlot(slot):len() + 2),
								i,
								combat.ITEM_NAMES[slotData[slot].items[i]],
								slotData[slot].uses[i]))
						else
							P.addLog(string.format("%s's item %d: %s %2d",
								nameFromSlot(slot),
								i,
								combat.ITEM_NAMES[slotData[slot].items[i]],
								slotData[slot].uses[i]))
							
							firstChangeLogged = true
						end
					end
				end
			end
			P.addLog("")
		end
	end
	
	
	
	local selSlot = memory.readbyte(addr.SELECTED_SLOT)
		
	local function logAtLoc(str)
		P.addLog(slotLocString(selSlot) .. relativeMoveStr() .. str)
	end
	
	if addr.getPhase() == "player" and selSlot <= lastPlayerSlot then -- check movements
	
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
			
			checkRecruitment()
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

	
	
	if prevRN ~= rns.rng1.pos then
		P.addLog_RNconsumed()
		prevRN = rns.rng1.pos
	end
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
	
	if lastEvent.length ~= rnsUsed then 
		-- reinforcements may consume rns after start of player phase but before game displays "player phase"
		if rnsUsed % 12 == 0 then
			P.addLog(aLoc .. " reinforcements?")
		end
		return 
	end
	
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
			
			-- moving items down in inventory to clear 1st for equipped weapon is not necessarily redundant, 
			-- since we might also swap 2nd or more weapons manually
			
			slotData[a.slot].items[1] = addr.byteFromSlot(a.slot, addr.ITEMS_OFFSET)
			-- item durability not yet updated in RAM, manually update
			slotData[a.slot].uses[1] = lastEvent.mHitSeq.attacker.endUses
			
		elseif lastEvent:levelDetected() then
			P.addLog(aLoc .. relativeMoveStr() .. resultStr)
		end
		
		P.addLog(string.format("RN %5d->%5d (%+d)", rns.rng1.prevPos, rns.rng1.pos, rnsUsed))
	
	-- don't match with last event of player phase
	elseif a.slot > lastPlayerSlot then
		-- possible for AI movement burns to have a false match with length of last event
		P.addLog(aLoc .. aWep)
		P.addLog(dLoc .. dWep .. resultStr)
		P.addLog(string.format("RN %5d->%5d (%+d) AI event?", rns.rng1.prevPos, rns.rng1.pos, rnsUsed))
	end
end

return P