-- consists of combat, level-up, and/or FE8 dig preceded by burns
-- rnEvents are registered and manipulated (+/-burns and swapping) to seek outcomes

require("feCombat")

local P = {}
rnEvent = P




P.events = {}
P.events.sel_i = 1
local deletedEventsStack = {} -- recover deleted rnEvents (except dependencies) in order of deletion

local perms = {}
local permsNeedUpdate = false

local DEFAULT_PHP_WEIGHT = 100
local DEFAULT_EHP_WEIGHT = 50




-- non modifying functions

function P.getByID(vID)
	for _, event in ipairs(P.events) do
		if event.ID == vID then
			return event
		end
	end
	print("ID not found: " .. tostring(vID))
	return nil
end

local rnEventObj = {}

-- auto-detected via experience gain, but can be set to true manually
function rnEventObj:levelDetected()
	return self.lvlUp or (self.mHitSeq.lvlUp and self.hasCombat)
end

function rnEventObj:levelScore()
	return self.unit:levelScoreInExp(self.postCombatRN_i)
end

function rnEventObj:digSucceed()
	return rns.rng1:getRN(self.nextRN_i - 1) <= self.unit.stats[7]
	-- luck+1% chance, therefore even 0 luck has 1% chance, confirmed luck 8 succeeds with rn = 8
end

function rnEventObj:resultString()
	local rString = ""
	if self.hasCombat then
		rString = rString .. " " .. self.batParams.attacker.weapon .. " " .. combat.hitSeq_string(self.mHitSeq) 
	end
	if self:levelDetected() then
		rString = rString .. string.format(" %s %3d",
			self.unit:levelUpProcs_string(self.postCombatRN_i),
			self:levelScore())
	end
	if self.dig then
		rString = rString .. string.format(" dig %02s ", self.unit.stats[7])
		if self:digSucceed() then -- luck > rn
			rString = rString .. "success!"
		else 
			rString = rString .. "fail"
		end
	end
	return rString
end

function rnEventObj:headerString(rnEvent_i)
	local hString = "  "
	if rnEvent_i == P.events.sel_i then
		hString = "->" 
	end
	
	local detailString = ""
	
	if self.burns ~= 0 then
		detailString = detailString .. string.format(" burns %d", self.burns)
	end
	
	local hasDependencies = false
	for i = 1, #P.events do
		if self.comesAfter[i] then
			hasDependencies = true
			break
		end
	end
	
	if hasDependencies then
		detailString = detailString .. " deps"
		for i = 1, #P.events do
			if self.comesAfter[i] then
				detailString = detailString .. i
			end
		end
	end
	
	if self.enemyID ~= 0 then
		detailString = detailString .. string.format(" eID %d %dhp", self.enemyID, self.enemyHPstart)
	end

	if self.batParams:isWeaponSpecial("isPlayer") then
		detailString = detailString .. " " .. combat.WEAPON_TYPE_STRINGS[self.batParams.player.weaponType]:upper()
	end
	
	if self.batParams:isWeaponSpecial(false) then
		detailString = detailString .. " " .. combat.WEAPON_TYPE_STRINGS[self.batParams.enemy.weaponType]
	end
	
	if self.batParams.enemy.class ~= classes.LORD then
		detailString = detailString .. " class " .. tostring(self.batParams.enemy.class)
	end
	
	if self.pHPweight ~= DEFAULT_PHP_WEIGHT or self.eHPweight ~= DEFAULT_EHP_WEIGHT then
		detailString = detailString .. string.format(" hpw %d %d", self.pHPweight, self.eHPweight)
	end
	
	return hString .. string.format("%2d %s%s%s",
		self.ID, self.unit.name, self:resultString(), detailString)
end

function rnEventObj:healable()
	if self.hasCombat and self.mHitSeq.pHP < self.maxHP then
		return true
	end
	return self:levelDetected() 
		and self.unit:willLevelStats(self.postCombatRN_i)[1] >= 1
end

-- the most important point of hp is the last;
-- going from 100%->90% is far better than 1%->0 for the player.
-- define a parabola f(x) such that f(0) = 0, f(1) = 1, f'(0) = K*f'(1),
-- where K is the slope at 0 / slope at 100%.
-- then f(x) = x(2K-(K-1)x)/(K+1).
-- (note the slope at 0 never becomes asymptotic with this definition,
-- instead it approaches 2 while the slope at 1 approaches 0.)
-- let K = 4.
-- in this way it evaluates better to lose 5 hp from a 25 hp unit than a 
-- 10 hp remaining unit if both have 25 max hp (a loss of 13/125 in the 
-- first case and 31/125 in the second, rather than 1/5 in both cases)
local function nonlinearhpValue(frac)
	return frac*(8-3*frac)/5
end

-- measure in units of perfect levels (= 100)
-- perfect combat value == 50
-- can adjust combat weight
-- dig = 25
-- if healing exp is relevant, +5 if player hp is less than max
function rnEventObj:evaluation_fn(printV)
	local score = 0
	local printStr = string.format(" %2d:", self.ID)
	
	-- could have empty combat if enemy HP == 0 e.g. another unit killed this enemy this phase
	if self.hasCombat and self.mHitSeq[1] then 
		if self.mHitSeq[1].action == "STF-X" then
			local hitValue = self.eHPweight + 15*self.mExpValueFactor -- exp depends on staff
			score = score + hitValue
			self.mHitSeq.expGained = 0
			if printV then printStr = printStr .. string.format(" staff hit %02d", hitValue) end
		else			
			local eHPstartFrac = self.enemyHPstart/self.batParams.enemy.maxHP
			local eHPendFrac = self.mHitSeq.eHP/self.batParams.enemy.maxHP
			local eLostValue = nonlinearhpValue(eHPstartFrac) - nonlinearhpValue(eHPendFrac)
			
			local pHPstartFrac = self.batParams.player.currHP/self.maxHP
			local pHPendFrac = self.mHitSeq.pHP/self.maxHP
			local pLostValue = nonlinearhpValue(pHPstartFrac) - nonlinearhpValue(pHPendFrac)
			
			score = score + self.eHPweight * eLostValue 
			              - self.pHPweight * pLostValue
			              + self.mHitSeq.expGained * self.mExpValueFactor
			
			printStr = printStr .. string.format(
				" eHP %d%%->%d%% nl %d%%, pHP %d%%->%d%% nl %d%%, exp %dx%.2f", 
				eHPstartFrac * 100, 
				eHPendFrac * 100,
				-eLostValue * 100,
				pHPstartFrac * 100, 
				pHPendFrac * 100,
				-pLostValue * 100,
				self.mHitSeq.expGained, 
				self.mExpValueFactor)
		end
	end
		
	if self:levelDetected() then
		score = score + self:levelScore()*self.mExpValueFactor
		printStr = printStr .. string.format(", level %dx%.2f", self:levelScore(), self.mExpValueFactor)
	end

	if unitData.HEALER_DEPLOYED and self:healable() then
		score = score + 5
		printStr = printStr .. ", healable 5"
	end
	
	if self.dig and self:digSucceed() then
		score = score + 25
		printStr = printStr .. ", dig 25"
	end
	
	if printV then print(printStr) end
	return score
end

function P.totalEvaluation()
	local score = 0	
	for _, event in ipairs(P.events) do
		score = score + event.eval
	end
	return score
end

-- quickly find how many burns needed to improve result of selected rnEvent
-- for rn burning gameplay
function P.searchFutureOutcomes(event_i)
	if #P.events < 1 then 
		print("no events to search")
		return 
	end
	
	event_i = event_i or P.events.sel_i
	-- swap to first location
	P.events[event_i], P.events[1] = P.events[1], P.events[event_i]
	event = P.events[1]
	event.burns = 0
	
	print()
	print("Searching for event ID " .. event.ID)
	print("RNG-pos Score Outcome")
	
	local record = -9999
	for improveAttempts = 0, 1000 do
		event:update()
		if improveAttempts % 50 == 0 then
			emu.frameadvance()
		end
		if record < event:evaluation_fn() then
			record = event:evaluation_fn()
			print(string.format("%7d %5d%s", 
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

function rnEventObj:printCache()
	print()
	if not self.cache then 
		print("no cache")
		return
	end

	print(string.format("%2d cache, size: %d, %4d - %4d", 
		self.ID, self.cache.count, self.cache.min_i, self.cache.max_i))
	
	if self.cache.count == 0 then return end
	
	for c_i = self.cache.min_i, self.cache.max_i do
		if self.cache[c_i] then
			for eHP = 0, 60 do
				if self.cache[c_i][eHP] then
					
					if eHP == 0 then
						print(string.format("%4d-%4d  eval %3d  eHP 0",
							c_i, 
							c_i+self.cache[c_i][eHP].postBurnLength,
							self.cache[c_i][eHP].eval))
					else
						print(string.format("%4d-%4d  eval %3d  eHP %2d  eHPend %2d",
							c_i, 
							c_i+self.cache[c_i][eHP].postBurnLength,
							self.cache[c_i][eHP].eval, 
							eHP,
							self.cache[c_i][eHP].enemyHPend))
					end
				end
			end
		end
	end
end

function rnEventObj:printDiagnostic()
	print()
	print(string.format("Diagnosis of rnEvent %d", self.ID))
	
	if self.hasCombat then
		for _, str_ in ipairs(self.batParams:toStrings()) do print(str_) end
		
		local str = ""
		for _, hitEvent in ipairs(self.mHitSeq) do
			local event = hitEvent
			str = str .. hitEvent.action .. string.format(" %2d dmg, ", hitEvent.dmg)
		end
		
		print(str)
		print(string.format("expGained=%2d pHP=%2d eHP=%2d", 
			self.mHitSeq.expGained, self.mHitSeq.pHP, self.mHitSeq.eHP))
		
		print(self.batParams.attacker)
		print(self.batParams.defender)
	end
	
	print(string.format("Eval %5.2f", self.eval))
	
	if self.cache then
		for c_i = self.cache.min_i, self.cache.max_i do
			if self.cache[c_i] and self.cache[c_i][self.enemyHPstart] then
				--print(string.format("Cache eval %5.2f", self.cache[c_i][self.enemyHPstart].eval))
			end
		end
	end
	
	print("dependencies, stats")
	print(self.comesAfter)
	print(self.unit.stats)
	
	--self:printCache()
end

function P.printDiagnostic()
	if #P.events <= 0 then return end
	selected(P.events):printDiagnostic()
end

-- rns blank to be colorized
function P.toStrings(isColored)
	local rStrings = {}
	
	if #P.events <= 0 then
		rStrings[1] = "rnEvents empty"
		return rStrings
	end
	
	for rnEvent_i, event in ipairs(P.events) do
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




-- modifying functions

-- functions that may require updating the list of valid permutations
function P.addEvent(event)
	event = event or rnEventObj:new()
	
	table.insert(P.events, event)
	P.events.sel_i = #P.events
	permsNeedUpdate = true
	P.update_rnEvents()
end

-- adjusts IDs, including dependencies
function P.deleteLastEvent()
	if #P.events <= 0 then return end
	
	local IDremoved = P.events[#P.events].ID
	for _, event in ipairs(P.events) do
		if event.ID > IDremoved then
			event.ID = event.ID - 1 -- decrement own ID
			for rnEvent_j = IDremoved, #P.events do -- decrement dependency table after IDremoved
				event.comesAfter[rnEvent_j] = event.comesAfter[rnEvent_j+1]
			end
		end
	end
	
	table.insert(deletedEventsStack, table.remove(P.events))
	if P.events.sel_i > #P.events then P.events.sel_i = #P.events end
	
	permsNeedUpdate = true
end

-- sets a new ID at end of table, clears dependencies because ids may have changed
function P.undoDelete()
	if #deletedEventsStack > 0 then
		P.addEvent(table.remove(deletedEventsStack))
		P.events[#P.events].ID = #P.events
		P.events[#P.events].comesAfter = {}
	else
		print("No deletion to undo.")
	end
end

function P.toggleDependency()
	if P.events.sel_i >= #P.events then return end
	
	local nextEvent = P.events[P.events.sel_i+1]
	local selectedID = selected(P.events).ID
	
	nextEvent.comesAfter[selectedID] = not nextEvent.comesAfter[selectedID]
	
	if nextEvent.comesAfter[selectedID]	then
		print(string.format("%d now depends on %d", nextEvent.ID, selectedID))
	else
		print(string.format("%d no longer depends on %d", nextEvent.ID, selectedID))
	end
	permsNeedUpdate = true
end





function P.swap()
	if P.events.sel_i >= #P.events then return end

	local nextEvent_i = P.events.sel_i+1
	
	if P.events[nextEvent_i].comesAfter[selected(P.events).ID] then
		print(string.format("Can't swap: %d depends on %d; toggle with Start", 
			P.events[nextEvent_i].ID, selected(P.events).ID))
	else
		P.events[P.events.sel_i], P.events[nextEvent_i] = P.events[nextEvent_i], P.events[P.events.sel_i]
		P.update_rnEvents()
	end
end

function rnEventObj:setStats()
	self.unit:setStats()
	self.maxHP = self.unit.stats[1]
	self.mExpValueFactor = self.unit:expValueFactor()
end

function rnEventObj:setEnemyHP(rnEvent_i)
	if not self.hasCombat then 
		self.enemyHPstart = 0
		return
	end

	self.enemyHPstart = self.batParams.enemy.currHP
	
	if self.enemyID == 0 then return end
	
	-- copy eHP from end of earliest previous combat that shares an enemy id if one exists
	for prevCombat_i = rnEvent_i-1, 1, -1 do
		local prev_rnEvent = P.events[prevCombat_i]
	
		if prev_rnEvent.enemyID == self.enemyID and prev_rnEvent.hasCombat then
			self.enemyHPstart = prev_rnEvent.enemyHPend
			return
		end
	end
end

-- assumes previous rnEvents have updates for optimization
-- does not do anything with cached values
function rnEventObj:updateFull()
	if self.hasCombat then
		self.mHitSeq = self.batParams:hitSeq(self.postBurnsRN_i, self.enemyHPstart)
		
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




-- cache saves length, score, and possibly enemy HP post combat,
-- saved by start rn position and possibly enemy HP pre combat.
-- also saves number of entries and earliest/latest entry position.
-- used to speed up evaluation when shuffling permutations to skip reconstructing combat and score

function rnEventObj:clearCache()
	self.cache = {}
	self.cache.count = 0
	self.cache.min_i = 999999
	self.cache.max_i = 0
end

function rnEventObj:writeToCache()
	self.cache.count = self.cache.count + 1
	if self.cache.min_i > self.postBurnsRN_i then
		self.cache.min_i = self.postBurnsRN_i
	end
	if self.cache.max_i < self.postBurnsRN_i then
		self.cache.max_i = self.postBurnsRN_i
	end
	
	self.cache[self.postBurnsRN_i][self.enemyHPstart] = {}
	self.cache[self.postBurnsRN_i][self.enemyHPstart].postBurnLength = self.length - self.burns
	self.cache[self.postBurnsRN_i][self.enemyHPstart].eval = self.eval
	self.cache[self.postBurnsRN_i][self.enemyHPstart].enemyHPend = self.enemyHPend
end

function rnEventObj:readFromCache()
	self.length = self.burns + self.cache[self.postBurnsRN_i][self.enemyHPstart].postBurnLength
	self.nextRN_i = self.startRN_i + self.length
	self.eval = self.cache[self.postBurnsRN_i][self.enemyHPstart].eval
	self.enemyHPend = self.cache[self.postBurnsRN_i][self.enemyHPstart].enemyHPend
end

-- uses cache if valid, when called from setToPerm()
function rnEventObj:update(rnEvent_i, cacheUpdateOnly)
	if rnEvent_i then -- if no ordering given, do not update startRN_i, used for searchFutureOutcomes
		if rnEvent_i == 1 then 
			self.startRN_i = rns.rng1.pos
		else
			self.startRN_i = P.events[rnEvent_i-1].nextRN_i
		end
	else 
		rnEvent_i = 1
	end
	
	self.postBurnsRN_i = self.startRN_i + self.burns
	self:setEnemyHP(rnEvent_i)
	
	if cacheUpdateOnly then
		if self.cache[self.postBurnsRN_i] then
			if self.cache[self.postBurnsRN_i][self.enemyHPstart] then
				-- neither update nor write is needed
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
	start_i = start_i or P.events.sel_i
	
	for rnEvent_i = start_i, #P.events do
		P.events[rnEvent_i]:update(rnEvent_i, cacheUpdateOnly)
	end
end




-- functions that invalidate cache
local function invalidateCache()
	selected(P.events):clearCache()
	P.update_rnEvents()
end

function P.updateStats()
	if #P.events <= 0 then return end
	
	selected(P.events):setStats()
	invalidateCache()
end

-- hasCombat, lvlUp, and dig
function P.toggle(k)
	if #P.events <= 0 then return end
	
	selected(P.events)[k] = not selected(P.events)[k]
	invalidateCache()
end

-- burns, enemyID, pHPweight, eHPweight
-- technically burns do not require a cache invalidation,
-- and the other fields would be valid as negative, 
-- but this allows function consolidation
function P.change(k, amount)
	if #P.events <= 0 then return end
	
	selected(P.events)[k] = selected(P.events)[k] + amount
	if selected(P.events)[k] < 0 then selected(P.events)[k] = 0 end
	invalidateCache()
end

function P.toggleBatParam(func, var)
	if #P.events <= 0 then return end
	
	func(selected(P.events).batParams, var) -- :func() syntactic for func(self)
	invalidateCache()
end




function rnEventObj:new(batParams, sel_Unit_i)
	batParams = batParams or combat.currBattleParams
	sel_Unit_i = sel_Unit_i or unitData.sel_Unit_i
	
	local o = {}
	setmetatable(o, self)
	self.__index = self
	 
	o.ID = #P.events+1 -- order in which rnEvents were registered
	o.comesAfter = {} -- enforces dependencies: certain rnEvents must precede others
	
	o.unit = selected(unitData.deployedUnits)
	o:setStats() -- todo do we get enemy stats on EP?
	o.batParams = batParams:copy()
	
	o.hasCombat = true -- most rnEvents will be combats without levels or digs
	o.lvlUp = false
	
	if classes.isNoncombat(o.unit.class) then
		o.hasCombat = false
		o.lvlUp = true
	end
	
	o.dig = false
	
	-- as units ram their caps (or have the potential to), the value of their levels drops
	o.mExpValueFactor = o.unit:expValueFactor()
	o.pHPweight = DEFAULT_PHP_WEIGHT
	o.eHPweight = DEFAULT_EHP_WEIGHT
	
	o.enemyID = 0 -- for units attacking the same enemyID
	o.enemyHPstart = 0 -- if a previous unit has damaged this enemy. HP at start of this rnEvent
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
	o:clearCache()
	
	return o
end




-- permutation functions

local MEM_LIMIT = 500000

-- include logic to enforce dependencies
local function recursivePerm(usedNums, currPerm, currSize)
	if #perms >= MEM_LIMIT then return end

	local count = #P.events
	
	-- base case
	if currSize == count then
		table.insert(perms, currPerm)
		
		if #perms >= MEM_LIMIT then
			print()
			print(string.format("MEMORY LIMIT %d REACHED, ABORTING", MEM_LIMIT))
			print("Delete P.events or add dependencies to reduce memory use.")
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
	for i = 1, #P.events do
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

function P.setToPerm(perm)
	local count = #P.events
	
	local lowestSwap = count+1 -- don't need to update from 1 to lSwap-1
	-- saves a lot of time because usually only the higher rnEvent are swapped
	
	for swapInto_i = 1, count do
		local perm_ID = perm[swapInto_i]
				
		-- find rnEvent with ID, previous should be in position
		-- if current (swapInto_i) is in position, doing nothing is OK
		for swapOutOf_j = swapInto_i+1, count do
			if P.events[swapOutOf_j].ID == perm_ID then
				-- swap into place
				P.events[swapOutOf_j], P.events[swapInto_i] = P.events[swapInto_i], P.events[swapOutOf_j]
				
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
local TOP_N = 3
function P.suggestedPermutation()
	local timeStarted = os.clock()

	if permsNeedUpdate then
		P.permutations()
		print(string.format("Time taken: %.2f seconds", os.clock() - timeStarted))
		timeStarted = os.clock()
		
		if permsNeedUpdate then return end -- memory limit
	end
	
	local topScores = {}
	local topPerms = {}
	for top_i = 1, TOP_N do
		topScores[top_i] = -999
		topPerms[top_i] = {}
	end
		
	for perm_i, perm in ipairs(perms) do
		if perm_i % 5000 == 0 then
			print(string.format("%7d/%d", perm_i, #perms))
			emu.frameadvance() -- prevent unresponsiveness
		end
	
		-- swap each rnEvent into position based on ID and perm, and update
		P.setToPerm(perm)
		
		local score = P.totalEvaluation()
		
		-- update top results
		for top_i = 1, TOP_N do
			if score > topScores[top_i] then
				for shift_k = TOP_N, top_i + 1, -1 do
					topScores[shift_k] = topScores[shift_k-1]
					topPerms[shift_k] = topPerms[shift_k-1]
				end
				topScores[top_i] = score
				topPerms[top_i] = perm
				break
			end
		end
	end
	
	P.setToPerm(topPerms[1])
	P.update_rnEvents(1)
	
	print()
	for _, event in ipairs(P.events) do
		event:evaluation_fn(true)
	end
	
	print()
	for top_i = 1, TOP_N do
		print(topPerms[top_i])
		print(string.format("%.2f", topScores[top_i]))
	end
	
	print(string.format("Time taken: %.2f seconds", os.clock() - timeStarted))
end

return rnEvent