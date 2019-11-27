-- consists of combat, level-up, and/or dig preceded by burns
-- rnEvents are registered and manipulated (+/-burns and swapping) to seek outcomes

-- Enemy phase behavior no longer supported.
-- Value provided doesn't justify maintaining feature,
-- as enemy phase events can't be permuted and the burns are unpredictable.
-- Instead implement rn advancing to enable fast enemy phase trials.

require("feUnitData")
require("feCombat")
--require("feGUI")

local P = {}
rnEvent = P

local eventList = {}
local deletedEventsStack = {} -- recover deleted rnEvents (except dependencies) in order of deletion

function P.getEventList()
	return eventList
end

local perms = {}
local permsNeedUpdate = false

local sel_rnEvent_i = 1
local function limitSel_rnEvent_i()
	if sel_rnEvent_i > #eventList then sel_rnEvent_i = #eventList end
	if sel_rnEvent_i < 1 then sel_rnEvent_i = 1 end 
end

local LEVEL_UP_COLORS = {
	0xFF8080FF, -- hue   0 pink
	0xFFAA00FF, -- hue  40 orange
	0xFFFF00FF, -- hue  60 yellow
	0x00FF00FF, -- hue 100 green
	0x00FFFFFF, -- hue 180 cyan
	0x0000FFFF, -- hue 240 blue
	0xFF00FFFF  -- hue 300 magenta
}


local rnEventObj = {}

function rnEventObj:setStats(stats)
	stats = stats or unitData.getSavedStats()

	self.stats = {}
	for stat_i = 1, unitData.EXP_I do
		self.stats[stat_i] = stats[stat_i]
	end
end

-- INDEX FROM 1
function rnEventObj:new(stats, batParams, sel_Unit_i)
	batParams = batParams or combat.currBattleParams
	sel_Unit_i = sel_Unit_i or unitData.sel_Unit_i
	
	local o = {}
	setmetatable(o, self)
	self.__index = self
	 
	o.ID = #eventList+1 -- order in which rnEvents were registered
	o.comesAfter = {} -- enforces dependencies: certain rnEvents must precede others
	
	o.unit_i = sel_Unit_i
	o:setStats(stats) -- todo do we get enemy stats on EP?
	o.batParams = batParams:copy()
	
	o.hasCombat = true -- most rnEvents will be combats without levels or digs
	o.lvlUp = false
	o.dig = false
	
	-- as units ram their caps (or have the potential to), the value of their levels drops
	o.expValueFactor = unitData.expValueFactor(o.unit_i, o.stats)
	o.combatWeight = 1
	
	o.enemyID = 0 -- for units attacking the same enemyID
	o.enemyHP = 0 -- if a previous unit has damaged this enemy. HP at start of this rnEvent
	o.enemyHPend = 0 -- HP at end of this rnEvent
	-- TODO player HP (from multi combat due to dance, or EP)
	
	o.burns = 0
	o.startRN_i = 0
	o.postBurnsRN_i = 0
	o.mHitSeq = {} -- avoid confusion between member variable and function in combatObj
	o.postCombatRN_i = 0
	o.nextRN_i = 0
	o.length = 0
	o.eval = 0
	
	-- cache length and eval
	-- use this for optimized fast updates when searching outcomes
	-- cache indexed by *postBurnsRN_i* rn_i, not startRN_i
	-- 2nd index is enemyHP at start so eHP passing will work
	o.cache = nil
	
	return o
end

function P.diagnostic()
	if #eventList > 0 then
		P.get():diagnostic()
	end
end

function rnEventObj:diagnostic()
	print()
	print(string.format("Diagnosis of rnEvent %d", self.ID))
	
	if self.hasCombat then
		batParamStrings = self.batParams:toStrings()
		print(batParamStrings[0])
		print(batParamStrings[1])
		print(batParamStrings[2])
		
		local str = ""
		for _, hitEvent in ipairs(self.mHitSeq) do
			local event = hitEvent
			str = str .. hitEvent.action .. string.format(" %2d dmg, ", hitEvent.dmg)
		end
		
		print(str)
		print(string.format("expGained=%2d eHP=%2d pHP=%2d", 
			self.mHitSeq.expGained, self.mHitSeq.eHP, self.mHitSeq.pHP))
			
		strA = ""
		strD = ""
		for data_i = 1, 9 do
			strA = strA .. string.format("%2d ",self.batParams.attacker[data_i])
			strD = strD .. string.format("%2d ",self.batParams.defender[data_i])
		end
		print(strA)
		print(strD)
		
	end
	
	print(string.format("Eval %5.2f", self.eval))
	
	if self.cache then
		for c_i = self.cache.min_i, self.cache.max_i do
			if self.cache[c_i] and self.cache[c_i][self.enemyHP] then
				--print(string.format("Cache eval %5.2f", self.cache[c_i][self.enemyHP].eval))
			end
		end
	end
	
	print(self.comesAfter)
	
	print("stats")
	print(self.stats)
end

-- assumes first index returns a table
function rnEventObj:writeToCache()
	self.cache.count = self.cache.count + 1
	if self.cache.min_i > self.postBurnsRN_i then
		self.cache.min_i = self.postBurnsRN_i
	end
	if self.cache.max_i < self.postBurnsRN_i then
		self.cache.max_i = self.postBurnsRN_i
	end
	
	self.cache[self.postBurnsRN_i][self.enemyHP] = {}
	self.cache[self.postBurnsRN_i][self.enemyHP].postBurnLength = self.length - self.burns
	self.cache[self.postBurnsRN_i][self.enemyHP].eval = self.eval
	self.cache[self.postBurnsRN_i][self.enemyHP].enemyHPend = self.enemyHPend
end

function rnEventObj:printCache()
	print()
	print(string.format("%2d cache, size: %d, %4d - %4d", 
		self.ID, self.cache.count, self.cache.min_i, self.cache.max_i))
	
	if self.cache.count == 0 then return end
	
	for c_i = self.cache.min_i, self.cache.max_i do
		if self.cache[c_i] then
			for eHP = 0, 60 do
				if self.cache[c_i][eHP] then
					
					if eHP == 0 then
						print(string.format("%4d-%4d  eHP 0",
							c_i, c_i+self.cache[c_i][eHP].postBurnLength))
					else
						print(string.format("%4d-%4d  eval %3d  eHP %2d  eHPend %2d",
							c_i, c_i+self.cache[c_i][eHP].postBurnLength,
							self.cache[c_i][eHP].eval, eHP,
							self.cache[c_i][eHP].enemyHPend))
					end
				end
			end
		end
	end
end

function rnEventObj:readFromCache()
	self.length = self.burns + self.cache[self.postBurnsRN_i][self.enemyHP].postBurnLength
	self.nextRN_i = self.startRN_i + self.length
	self.eval = self.cache[self.postBurnsRN_i][self.enemyHP].eval
	self.enemyHPend = self.cache[self.postBurnsRN_i][self.enemyHP].enemyHPend
end

function rnEventObj:setStart(rnEvent_i)
	if rnEvent_i == 1 then 
		self.startRN_i = rns.rng1.pos
	else
		self.startRN_i = eventList[rnEvent_i-1].nextRN_i
	end
end

function rnEventObj:setEnemyHP(rnEvent_i)
	if not self.hasCombat then 
		self.enemyHP = 0 
		return 
	end

	self.enemyHP = self.batParams.enemy[combat.HP_I]
		
	-- check eHP from previous combat(s) if applicable
	if self.enemyID ~= 0 then
		for prevCombat_i = rnEvent_i-1, 1, -1 do
			local prior_rnEvent = eventList[prevCombat_i]
		
			if prior_rnEvent.enemyID == self.enemyID and prior_rnEvent.hasCombat then
				self.enemyHP = prior_rnEvent.enemyHPend
				return
			end
		end
	end
end

-- assumes previous rnEvents have updates for optimization
function rnEventObj:updateFull()
	if self.hasCombat then
		self.mHitSeq = self.batParams:hitSeq(self.postBurnsRN_i, self.enemyHP)
		
		self.postCombatRN_i = self.postBurnsRN_i + self.mHitSeq.totalRNsConsumed
		
		self.enemyHPend = self.mHitSeq.eHP
	else
		self.postCombatRN_i = self.postBurnsRN_i
	end
	self.length = self.postCombatRN_i - self.startRN_i
	
	if self:levelDetected() then
		self.length = self.length + 7 -- IF EMPTY LEVEL REROLLS, MORE THAN 7!!
	end
	
	if self.dig then
		self.length = self.length + 1 -- FE8, 6&7 use secondary rn
	end
	
	self.nextRN_i = self.startRN_i + self.length
	
	self.eval = self:evaluation_fn()
end

-- uses cache if valid
-- skip reconstructing combat, eval, etc
function rnEventObj:update(rnEvent_i, cacheUpdateOnly)
	if rnEvent_i then -- if no ordering given, do not update startRN_i, used for searchFutureOutcomes
		self:setStart(rnEvent_i)
	else 
		rnEvent_i = 1
	end
	
	self.postBurnsRN_i = self.startRN_i + self.burns
	self:setEnemyHP(rnEvent_i)
	
	if cacheUpdateOnly then
		if self.cache[self.postBurnsRN_i] then
			if self.cache[self.postBurnsRN_i][self.enemyHP] then
				self:readFromCache()
			else
				self:updateFull()
				self:writeToCache()
			end
		else
			self:updateFull()
			self.cache[self.postBurnsRN_i] = {}
			self:writeToCache()
		end
	else
		self:updateFull()
	end
end

function P.update_rnEvents(start_i, cacheUpdateOnly)
	start_i = start_i or sel_rnEvent_i
	
	for rnEvent_i = start_i, #eventList do
		eventList[rnEvent_i]:update(rnEvent_i, cacheUpdateOnly)
	end
end

-- auto-detected via experience gain, but can be set to true manually
function rnEventObj:levelDetected()
	return self.lvlUp or (self.mHitSeq.lvlUp and self.hasCombat)
end

function rnEventObj:levelScore()
	return unitData.statProcScore(self.postCombatRN_i, self.unit_i, self.stats)
end
function rnEventObj:digSucceed()
	return rns.rng1:getRNasCent(self.nextRN_i - 1) <= self.stats[unitData.LUCK_I]
	-- luck+1% chance, therefore even 0 luck has 1% chance, confirmed luck 8 succeeds with rn = 8
end

function rnEventObj:resultString()
	local rString = ""
	if self.hasCombat then
		rString = rString .. " " .. combat.hitSeq_string(self.mHitSeq) 
	end
	if self:levelDetected() then
		rString = rString .. string.format(" %s %3d",
			unitData.levelUpProcs_string(self.postCombatRN_i, self.unit_i, self.stats),
			self:levelScore())
	end
	if self.dig then
		if self:digSucceed() then -- luck > rn
			rString = rString .. " dig success!"
		else 
			rString = rString .. " dig fail"
		end
	end
	return rString
end
function rnEventObj:headerString(rnEvent_i)
	local hString = "  "
	if rnEvent_i == sel_rnEvent_i and feGUI.canAlter_rnEvent() then 
		if feGUI.pulse() then 
			hString = "<>" 
		else
			hString = "--"
		end
	end
	
	local specialStringEvents = ""	
	
	if self.burns ~= 0 then
		specialStringEvents = specialStringEvents .. 
			string.format(" burns %d", self.burns)
	end
	
	if self.enemyID ~= 0 then
		specialStringEvents = specialStringEvents .. 
			string.format(" eID %d %dhp", self.enemyID, self.enemyHP)
	end

	if self.batParams.player.weapon ~= combat.enum_NORMAL then
		specialStringEvents = specialStringEvents .. " " 
			.. string.upper(combat.WEAPON_TYPE_STRINGS[self.batParams.player.weapon])
	end
	
	if self.batParams.enemy.weapon ~= combat.enum_NORMAL then
		specialStringEvents = specialStringEvents .. " " 
			.. combat.WEAPON_TYPE_STRINGS[self.batParams.enemy.weapon]
	end
	
	if self.batParams.enemy.class ~= classes.LORD then
		specialStringEvents = specialStringEvents .. " class " .. tostring(self.batParams.enemy.class)
	end
	
	if self.combatWeight ~= 1 then
		specialStringEvents = specialStringEvents .. " cmb x" .. tostring(self.combatWeight)
	end
	
	return hString .. string.format("%2d %s%s%s",
		self.ID, unitData.names(self.unit_i), self:resultString(), specialStringEvents)
end

function rnEventObj:healable()
	if self.hasCombat and self.mHitSeq.pHP < self.stats[1] then
		return true
	end
	return self:levelDetected() 
		and unitData.willLevelStat(self.postCombatRN_i, self.unit_i, self.stats)[1] >= 1
end

-- measure in units of exp
-- perfect combat value == 100 exp
-- can adjust combat weight
-- dig = 50 exp
-- if healing is relevant, +11xp if player hp is less than max
function rnEventObj:evaluation_fn(printV)
	local score = 0	
	local printStr = string.format("%02d", self.ID)
	
	-- could have empty combat if enemy HP == 0 e.g. another unit killed this enemy this phase
	if self.hasCombat and self.mHitSeq[1] then 
		if self.mHitSeq[1].action == "STF-X" then
			score = score + 100
			if printV then printStr = printStr .. " staff hit" end
		else
			-- normalize to 1, out of HP at start of phase.
			-- damaging the same enemy for X damage by 2 units
			-- should be evaled the same as by 1 unit.
			-- A - B + (B - C) == A - C
			
			local dmgToEnemy = (self.enemyHP-self.mHitSeq.eHP)/
				self.batParams:data(combat.enum_ENEMY)[combat.HP_I]
			local dmgToPlayer = 1-self.mHitSeq.pHP/
				self.batParams:data(combat.enum_PLAYER)[combat.HP_I]
			
			score = score + 100*dmgToEnemy - 200*dmgToPlayer 
				+ self.mHitSeq.expGained*self.expValueFactor
			
			printStr = printStr .. string.format(" d2e %.2f  d2p %.2f  exp %dx%.2f", 
					dmgToEnemy, dmgToPlayer, self.mHitSeq.expGained, self.expValueFactor)
		end
		
		score = score * self.combatWeight
	end
	
	if self:healable() then
		score = score + 6
		printStr = printStr .. " healable"
	end
	
	if self:levelDetected() then
		score = score + self:levelScore()*self.expValueFactor
		
		printStr = printStr .. string.format(" level %3d", self:levelScore())
	end
	if self.dig and self:digSucceed() then
		score = score + 50
		
		printStr = printStr .. " dig 50"
	end
	
	if printV then print(printStr) end
	return score
end

-- quickly find how many burns needed to improve result of selected rnEvent
-- for rn burning gameplay
function P.searchFutureOutcomes(event_i)
	if #eventList < 1 then return end
	
	event_i = event_i or sel_rnEvent_i
	-- swap to first location
	eventList[event_i], eventList[1] = eventList[1], eventList[event_i]
	event = eventList[1]
	event.burns = 0
	
	print()
	print("Searching for event ID " .. event.ID)
	print("Position Score Outcome")
	
	local record = -9999
	for improveAttempts = 0, 1000 do		
		event:update()
		
		if improveAttempts % 50 == 0 then
			emu.frameadvance()
		end
		
		if record < event:evaluation_fn() then
			record = event:evaluation_fn()
			print(string.format("%8d %5d%s", 
				rns.rng1.pos + event.burns, 
				record, 
				event:resultString()))
			improveAttempts = 0
		end
		
		event.burns = event.burns + 1
	end
	
	event.burns = 0
	P.update_rnEvents(1)
end

-- draw boxes around rns on second line
function rnEventObj:drawMyBoxes(rect, rnEvent_i)
	local line_i = 2*rnEvent_i
	local INIT_CHARS = 6
	
	rect:drawBox(line_i, INIT_CHARS, self.burns * 3, "red")
	
	if self.hasCombat then
		hitStart = self.burns
		
		for _, hitEvent in ipairs(self.mHitSeq) do
			rect:drawBox(line_i, INIT_CHARS + hitStart * 3, hitEvent.RNsConsumed * 3, "yellow")
			
			hitStart = hitStart + hitEvent.RNsConsumed
		end
	end
	
	if self:levelDetected() then
		local procs = unitData.willLevelStat(self.postCombatRN_i, self.unit_i, self.stats)
		
		for stat_i = 1, 7 do
			local char_start = INIT_CHARS + (self.postCombatRN_i-self.startRN_i + stat_i-1) * 3
			
			if procs[stat_i] == 1 then
				rect:drawBox(line_i, char_start, 3, LEVEL_UP_COLORS[stat_i]) 
			elseif procs[stat_i] == 2 then -- Afa's provided stat
				rect:drawBox(line_i, char_start, 3, feGUI.flashcolor(LEVEL_UP_COLORS[stat_i], "white")) 
			elseif procs[stat_i] == -1 then -- capped stat
				rect:drawBox(line_i, char_start, 3, feGUI.flashcolor(0x662222FF, "black"))
			end
		end
	end
end

function P.addEvent(event)
	event = event or rnEventObj:new()
	
	table.insert(eventList, event)
	sel_rnEvent_i = #eventList
	permsNeedUpdate = true
	P.update_rnEvents()
end

-- adjusts IDs, including dependencies
function P.deleteLastEvent()
	if #eventList > 0 then
		local IDremoved = eventList[#eventList].ID
		for _, event in ipairs(eventList) do
			if event.ID > IDremoved then
				event.ID = event.ID - 1 -- dec own ID
				for rnEvent_j = IDremoved, #eventList do -- dec dependency table after IDremoved
					event.comesAfter[rnEvent_j] = event.comesAfter[rnEvent_j+1]
				end
			end
		end
		
		table.insert(deletedEventsStack, table.remove(eventList))
		permsNeedUpdate = true
		limitSel_rnEvent_i()
	end
end

-- sets a new ID at end of table, doesn't restore dependencies
function P.undoDelete()
	if #deletedEventsStack > 0 then
		P.addEvent(table.remove(deletedEventsStack))
		eventList[#eventList].ID = #eventList
	else
		print("No deletion to undo.")
	end
end

-- rns blank to be colorized
function P.toStrings(isColored)
	local rStrings = {}
	
	if #eventList <= 0 then
		rStrings[1] = "rnEvents empty"
		return rStrings
	end
	
	for rnEvent_i, event in ipairs(eventList) do
		table.insert(rStrings, event:headerString(rnEvent_i))
		local prefix = string.format("%5d ", event.startRN_i % 100000)
		if isColored then
			table.insert(rStrings, prefix)
		else
			table.insert(rStrings, prefix .. rns.rng1:rnSeqString(event.startRN_i, event.length))
		end
	end
	return rStrings
end

function P.get(index)
	index = index or sel_rnEvent_i
	return eventList[index]
end
function P.getByID(vID)
	for _, event in ipairs(eventList) do
		if event.ID == vID then
			return event
		end
	end
	print("ID not found: " .. tostring(vID))
end

function P.changeBurns(amount)
	if #eventList > 0 then
		amount = amount or P.burnAmount
		P.get().burns = P.get().burns + amount
		if P.get().burns < 0 then
			P.get().burns = 0
		end
		P.update_rnEvents()
	end
end

function P.incSel()
	sel_rnEvent_i = sel_rnEvent_i + 1
	limitSel_rnEvent_i()
end
function P.decSel()
	sel_rnEvent_i = sel_rnEvent_i - 1
	limitSel_rnEvent_i()
end
function P.swap()
	if sel_rnEvent_i < #eventList then
		if eventList[sel_rnEvent_i+1].comesAfter[P.get().ID] then
			print(string.format("CAN'T SWAP, %d DEPENDS ON %d, TOGGLE WITH START", 
				eventList[sel_rnEvent_i+1].ID, P.get().ID))
		else
			-- don't use get()?
			eventList[sel_rnEvent_i], eventList[sel_rnEvent_i+1] = eventList[sel_rnEvent_i+1], eventList[sel_rnEvent_i]
			P.update_rnEvents()
		end
	end
end
function P.toggleDependency()
	if sel_rnEvent_i < #eventList then
		eventList[sel_rnEvent_i+1].comesAfter[P.get().ID] = 
			not eventList[sel_rnEvent_i+1].comesAfter[P.get().ID]
		
		if eventList[sel_rnEvent_i+1].comesAfter[P.get().ID]	then
			print(string.format("%d NOW DEPENDS ON %d", 
				eventList[sel_rnEvent_i+1].ID, P.get().ID))
		else
			print(string.format("%d NOW DOES NOT DEPEND ON %d", 
				eventList[sel_rnEvent_i+1].ID, P.get().ID))
		end
		permsNeedUpdate = true
	end
end
function P.adjustCombatWeight(amount)
	if #eventList > 0 then
		P.get().combatWeight = P.get().combatWeight + amount
		print("combatWeight: x" .. P.get().combatWeight)
	end
end

-- functions that invalidate cache
function P.toggleBatParam(func, var)
	if #eventList > 0 then
		func(P.get().batParams, var) -- :func() syntactic for func(self)
		P.get().cache = nil
		P.update_rnEvents()
	end
end
function P.updateStats()
	if #eventList > 0 then
		P.get():setStats()
		P.get().cache = nil
	end
end

function P.changeEnemyID(amount)
	if #eventList > 0 then
		P.get().enemyID = P.get().enemyID + amount
		P.get().cache = nil
		P.update_rnEvents()
	end
end
function P.toggleCombat()
	if #eventList > 0 then	
		P.get().hasCombat = not P.get().hasCombat
		P.get().cache = nil
		P.get().enemyID = 0 -- don't want to cause enemyHP to carry
		P.update_rnEvents()
	end
end
function P.toggleLevel()
	if #eventList > 0 then	
		P.get().lvlUp = not P.get().lvlUp
		P.get().cache = nil
		P.update_rnEvents()
	end
end
function P.toggleDig()
	if #eventList > 0 then	
		P.get().dig = not P.get().dig
		P.get().cache = nil
		P.update_rnEvents()
	end
end

function P.totalEvaluation()
	local score = 0	
	for _, event in ipairs(eventList) do
		score = score + event.eval
	end
	return score
end

local MEM_LIMIT = 500000

-- include logic to enforce dependencies
local function recursivePerm(usedNums, currPerm, currSize)
	if #perms >= MEM_LIMIT then return end

	local count = #eventList
	
	-- base case
	if currSize == count then
		table.insert(perms, currPerm)
		
		if #perms >= MEM_LIMIT then
			print()
			print(string.format("MEMORY LIMIT %d REACHED, ABORTING", MEM_LIMIT))
			print()
		end
		return
	end
	
	for next_i = 1, count do
		if not usedNums[next_i] then
			-- if depends on unused rnEvent, don't use yet
			local afterAllDependencies = true
			for check_j = 1, count do
				if P.getByID(next_i).comesAfter[check_j] and not usedNums[check_j] then
					afterAllDependencies = false
				end
			end
			
			if afterAllDependencies then
				local newUsedNums = {}
				local newCurrPerm = {}
				for copy_j = 1, count do
					newUsedNums[copy_j] = usedNums[copy_j]
					newCurrPerm[copy_j] = currPerm[copy_j]
				end
				newUsedNums[next_i] = true
				newCurrPerm[currSize+1] = next_i
								
				recursivePerm(newUsedNums, newCurrPerm, currSize+1)
			end
		end
		if currSize == 0 then
			print(string.format("%d/%d %7d permutations", next_i, count, #perms))
			emu.frameadvance() -- prevent unresponsiveness
		end
	end
end

function P.permutations()
	--if not permsNeedUpdate then return end

	perms = {}
	
	-- using nil as false doesn't fill table properly, explicitly fill
	local usedNums = {}
	local currPerm = {}
	for i = 1, #eventList do
		usedNums[i] = false
		currPerm[i] = 0
	end
	
	recursivePerm(usedNums, currPerm, 0)
	permsNeedUpdate = false
	
	if #perms >= MEM_LIMIT then
		perms = {}
		permsNeedUpdate = true
	end
end

function P.setToPerm(p_index)
	local currPerm = perms[p_index]
	local count = #eventList
	
	local lowestSwap = count+1 -- don't need to update from 1 to lSwap-1
	-- saves a lot of time because usually only the higher rnEvent are swapped
	
	for swapInto_i = 1, count do
		local perm_ID = currPerm[swapInto_i]
				
		-- find rnEvent with ID, previous should be in position
		-- if current (swapInto_i) is in position, doing nothing is OK
		for swapOutOf_j = swapInto_i+1, count do
			if eventList[swapOutOf_j].ID == perm_ID then
				-- swap into place
				eventList[swapOutOf_j], eventList[swapInto_i] = eventList[swapInto_i], eventList[swapOutOf_j]
				
				if lowestSwap > swapInto_i then
					lowestSwap = swapInto_i
				end
			end
		end
	end
	
	P.update_rnEvents(lowestSwap, "cacheUpdateOnly")
end

-- attempt every valid arrangement and score it
-- return top three options, first is auto-set
function P.suggestedPermutation()
	local timeStarted = os.clock()

	if permsNeedUpdate then
		P.permutations()
		print(string.format("Time taken: %.2f seconds", os.clock() - timeStarted))
		timeStarted = os.clock()
		
		if permsNeedUpdate then -- memory abort
			return
		end
	end
	
	local topN = 3
	local topIndicies = {}
	local topScores = {}
	for top_i = 1, topN do
		topIndicies[top_i] = 0
		topScores[top_i] = -999
	end
	
	for _, event in ipairs(eventList) do
		if not event.cache then
			event.cache = {}
			event.cache.count = 0
			event.cache.min_i = 999999
			event.cache.max_i = 0
		end
	end
	
	for perm_i = 1, #perms do
		if perm_i % 5000 == 0 then
			print(string.format("%7d/%d", perm_i, #perms))
			emu.frameadvance() -- prevent unresponsiveness
		end
	
		-- swap each rnEvent into position based on ID and perm, and update
		P.setToPerm(perm_i)
		
		local score = P.totalEvaluation()
		
		-- update top results
		local replaced = false
		for top_i = 1, topN do
			if score > topScores[top_i] and not replaced then
				for shift_k = topN, top_i + 1, -1 do
					topScores[shift_k] = topScores[shift_k-1]
					topIndicies[shift_k] = topIndicies[shift_k-1]
				end
				topScores[top_i] = score
				topIndicies[top_i] = perm_i
				replaced = true
			end
		end
	end
	
	P.setToPerm(topIndicies[1])
	P.update_rnEvents(1)
	
	print()
	for _, event in ipairs(eventList) do
		event:evaluation_fn(true)
	end
	
	print()
	for top_i = 1, topN do
		if not topScores[top_i] then
			topScores[top_i] = -999
		end
		print(perms[topIndicies[top_i]])
		print(string.format("%.2f", topScores[top_i]))
	end
	
	print(string.format("Time taken: %.2f seconds", os.clock() - timeStarted))
end

return rnEvent