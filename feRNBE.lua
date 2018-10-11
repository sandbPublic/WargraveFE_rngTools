require("feUnitData")
require("feCombat")
require("feGUI")

local P = {}
rnbe = P -- random number block event

local PPrnbes = {} -- Player Phase rnbes
PPrnbes.count = 0
local EPrnbes = {} -- Enemy Phase rnbes
EPrnbes.count = 0
P.playerPhase = true

local perms = {}
perms.count = 0
local permsNeedUpdate = false

local function getLast(list)
	return list[list.count]
end

-- selected phase
function P.SPrnbes()
	if P.playerPhase then return PPrnbes end
	return EPrnbes
end

-- return one or the other phase
function P.TPrnbes(playerPhase)
	if playerPhase then return PPrnbes end
	return EPrnbes
end

local sel_RNBE_i = 1
local function limitSel_RNBE_i()
	if sel_RNBE_i > P.SPrnbes().count then sel_RNBE_i = P.SPrnbes().count end
	if sel_RNBE_i < 1 then sel_RNBE_i = 1 end 
end

function P.togglePhase()
	P.playerPhase = not P.playerPhase
	limitSel_RNBE_i()
	
	if P.playerPhase then
		feGUI.rects[feGUI.RNBE_I].color = "blue"
	else
		feGUI.rects[feGUI.RNBE_I].color = "red"
	end
	
	print("playerPhase = " .. tostring(P.playerPhase))
end

-- go from hue 120 to hue 240 in steps of 20, jagged for contrast
local LEVEL_UP_COLORS = {
0x00FF00FF, -- hue 120
0x00AAFFFF, -- hue 200
0x00FF55FF, -- hue 140
0x0055FFFF, -- hue 220
0x00FFAAFF, -- hue 160
0x0000FFFF, -- hue 240
0x00FFFFFF  -- hue 180
}

-- consists of combat, level-up, and/or dig preceded by burns
-- registered and manipulated (+/-burns and swapping) to seek outcomes
local rnbeObj = {}

-- INDEX FROM 1
function rnbeObj:new(stats, combatO, sel_Unit_i)
	stats = stats or unitData.getSavedStats() -- todo do we get enemy stats on EP?
	combatO = combatO or combat.currBattleParams	
	sel_Unit_i = sel_Unit_i or unitData.sel_Unit_i

	local o = {}
	setmetatable(o, self)
	self.__index = self
	 
	o.ID = P.SPrnbes().count -- order in which rnbes were registered
	o.dependency = {} -- to enforce dependencies: certain rnbes must precede others
	o.isPP = P.playerPhase
	
	o.unit_i = sel_Unit_i	
	o.stats = {}
	for stat_i = 1, unitData.EXP_I do
		o.stats[stat_i] = stats[stat_i]
	end
	o.batParams = combatO:copy()
	o.combat = true -- most RNBEs will be combats without levels or digs
	o.combatWeight = 1
	
	o.lvlUp = false
	o.dig = false
	-- as units ram their caps (or have the potential to), the value of their levels drops
	o.expValueFactor = unitData.expValueFactor(o.unit_i, o.stats)
	
	o.enemyID = 0 -- for units attacking the same enemyID
	o.enemyHP = 0 -- if a previous unit has damaged this enemy. HP at start of this rnbe
	o.enemyHPend = 0 -- HP at end of this rnbe
	-- TODO player HP (from multi combat due to dance, or EP)
	
	o.burns = 0 -- TODO AI burns? post burns for rein?
	o.startRN_i = 0
	o.postBurnsRN_i = 0
	o.hitSq = {} -- not hitSeq, avoid confusion with function
	o.postCombatRN_i = 0
	o.nextRN_i = 0
	o.length = 0
	o.eval = 0
	
	-- cache length and eval
	-- use this for optimized fast updates when searching outcomes
	-- cache indexed by *postBurnsRN_i* rn_i, not startRN_i
	-- 2nd index is enemyHP at start so eHP passing will work
	o:clearCache()
	
	return o
end

function P.diagnostic()
	if P.SPrnbes().count <= 0 then return end
	
	P.get():diagnostic()
end

function rnbeObj:diagnostic()
	print()
	print(string.format("Diagnosis of rnbe %d", self.ID))

	if self.combat then	
		batParamStrings = self.batParams:toStrings()
		print(batParamStrings[0])
		print(batParamStrings[1])
		print(batParamStrings[2])
		
		local str = ""
		for hitSq_i = 1, self.hitSq.numEvents do
			local event = self.hitSq[hitSq_i]
			str = str .. event.action .. string.format(" %2d dmg, ", event.dmg)
		end
		
		print(str)
		print(string.format("expGained=%2d eHP=%2d pHP=%2d", 
			self.hitSq.expGained, self.hitSq.eHP, self.hitSq.pHP))
		
	end
	
	print(string.format("Eval %5.2f", self.eval))
	
	for c_i = self.cache.min_i, self.cache.max_i do
		if self.cache[c_i] and self.cache[c_i][self.enemyHP] then
			--print(string.format("Cache eval %5.2f", self.cache[c_i][self.enemyHP].eval))		
		end
	end
	
	print(self.dependency)
	
	print("stats")
	print(self.stats)
end

function rnbeObj:clearCache()
	self.cache = {}
	self.cache.count = 0
	self.cache.min_i = 9999
	self.cache.max_i = 0
end

-- assumes first index returns a table
function rnbeObj:writeToCache()
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

function rnbeObj:printCache()
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

function rnbeObj:readFromCache()
	self.length = self.burns + self.cache[self.postBurnsRN_i][self.enemyHP].postBurnLength
	self.nextRN_i = self.startRN_i + self.length
	self.eval = self.cache[self.postBurnsRN_i][self.enemyHP].eval
	self.enemyHPend = self.cache[self.postBurnsRN_i][self.enemyHP].enemyHPend
end

function rnbeObj:setStart(RNBE_i)
	if RNBE_i == 1 then 
		if self.isPP or (PPrnbes.count == 0) then
			self.startRN_i = rns.rng1.pos
		else
			self.startRN_i = getLast(PPrnbes).nextRN_i
		end
	else
		self.startRN_i = P.TPrnbes(self.isPP)[RNBE_i-1].nextRN_i
	end
end

function rnbeObj:setEnemyHP(RNBE_i)
	if not self.combat then 
		self.enemyHP = 0 
		return 
	end

	self.enemyHP = self.batParams:data(combat.enum_ENEMY)[combat.HP_I]
		
	-- check eHP from previous combat(s) if applicable
	if self.enemyID ~= 0 then
		for prevCombat_i = RNBE_i-1, 1, -1 do
			local priorRNBE = P.TPrnbes(self.isPP)[prevCombat_i]
		
			if priorRNBE.enemyID == self.enemyID and priorRNBE.combat then
				self.enemyHP = priorRNBE.enemyHPend
				return
			end
		end
		
		if not self.isPP then
			for prevCombat_i = PPrnbes.count, 1, -1 do
				if PPrnbes[prevCombat_i].enemyID == self.enemyID then
					self.enemyHP = PPrnbes[prevCombat_i].enemyHPend
					return
				end
			end
		end
	end
end

-- assumes previous rnbes have updates for optimization
function rnbeObj:updateFull(RNBE_i)	
	if self.combat then
		self.hitSq = self.batParams:hitSeq(self.postBurnsRN_i, self.enemyHP)
		
		self.postCombatRN_i = self.postBurnsRN_i + self.hitSq.totalRNsConsumed
		
		self.enemyHPend = self.hitSq.eHP
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
function rnbeObj:update(RNBE_i, fast)
	if RNBE_i then -- if no ordering given, do not update startRN_i, used for searchFutureOutcomes
		self:setStart(RNBE_i)
	else 
		RNBE_i = 1
	end
	
	self.postBurnsRN_i = self.startRN_i + self.burns
	self:setEnemyHP(RNBE_i)

	if fast then
		if self.cache[self.postBurnsRN_i] then
			if self.cache[self.postBurnsRN_i][self.enemyHP] then
				self:readFromCache()
			else
				self:updateFull(RNBE_i)
				self:writeToCache()
			end
		else
			self:updateFull(RNBE_i)
			self.cache[self.postBurnsRN_i] = {}
			self:writeToCache()
		end
	else
		self:updateFull(RNBE_i)
	end
end

function P.updateRNBEs(start_i, fast, playerPhase)
	start_i = start_i or sel_RNBE_i
	playerPhase = playerPhase or P.playerPhase
	
	if playerPhase then
		for RNBE_i = start_i, PPrnbes.count do
			PPrnbes[RNBE_i]:update(RNBE_i, fast)
		end
		start_i = 1 -- start from beginning of EPrnbes afterwards
	end
	
	for RNBE_i = start_i, EPrnbes.count do
		EPrnbes[RNBE_i]:update(RNBE_i, fast)
	end
end

-- auto-detected via experience gain, but can be set to true manually
function rnbeObj:levelDetected()
	return self.lvlUp or (self.hitSq.lvlUp and self.combat)
end

function rnbeObj:levelScore()
	return unitData.statProcScore(self.postCombatRN_i, self.unit_i, self.stats)
end
function rnbeObj:digSucceed()
	return rns.rng1:getRNasCent(self.nextRN_i - 1) <= self.stats[unitData.LUCK_I]
	-- luck+1% chance, therefore even 0 luck has 1% chance, confirmed luck 8 succeeds with rn = 8
end

function rnbeObj:resultString()
	local ret = ""
	if self.combat then
		ret = ret .. " " .. combat.hitSeq_string(self.hitSq) 
	end
	if self:levelDetected() then
		ret = ret .. string.format(" %+d %s", self:levelScore(),
			unitData.levelUpProcs_string(self.postCombatRN_i, self.unit_i, self.stats))
	end
	if self.dig then
		if self:digSucceed() then -- luck > rn
			ret = ret .. " dig success!"
		else 
			ret = ret .. " dig fail"
		end
	end
	return ret
end
function rnbeObj:headerString(RNBE_i)
	local ret = "  "
	if RNBE_i == sel_RNBE_i and feGUI.canAlterRNBE() then 
		if feGUI.pulse() then 
			ret = "<>" 
		else
			ret = "--"
		end
	end
	
	local specialStringEvents = ""	
	
	if self.enemyID ~= 0 then
		specialStringEvents = specialStringEvents .. 
			string.format(" eID %d %dhp", self.enemyID, self.enemyHP)
	end
	local weapon = self.batParams:data(combat.enum_PLAYER).weapon
	if weapon ~= combat.enum_NORMAL then
		specialStringEvents = specialStringEvents .. " " 
			.. string.upper(combat.WEAPON_TYPE_STRINGS[weapon])
	end
	
	weapon = self.batParams:data(combat.enum_ENEMY).weapon
	if weapon ~= combat.enum_NORMAL then
		specialStringEvents = specialStringEvents .. " " 
			.. combat.WEAPON_TYPE_STRINGS[weapon]
	end
	
	if self.batParams:data(combat.enum_ENEMY).class ~= classes.F.LORD then
		specialStringEvents = specialStringEvents .. " class " .. tostring(self.batParams:data(combat.enum_ENEMY).class)
	end
	
	return ret .. string.format("%2d %s%s%s",
		self.ID, unitData.names(self.unit_i), self:resultString(), specialStringEvents)
end

-- measure in units of exp
-- perfect combat value == 100 exp
-- can adjust combat weight
-- dig = 50 exp
function rnbeObj:evaluation_fn(printV)
	local score = 0	
	local printStr = string.format("%02d", self.ID)
	
	-- could have empty combat if enemy HP == 0 e.g. another unit killed this enemy this phase
	if self.combat and self.hitSq.numEvents > 0 then 
		if self.hitSq[1].action == "STF-X" then
			score = score + 100
			if printV then printStr = printStr .. " staff hit" end
		else
			-- normalize to 1, out of HP at start of phase.
			-- damaging the same enemy for X damage by 2 units
			-- should be evaled the same as by 1 unit.
			-- A - B + (B - C) == A - C
			
			local dmgToEnemy = (self.enemyHP-self.hitSq.eHP)/
				self.batParams:data(combat.enum_ENEMY)[combat.HP_I]
			local dmgToPlayer = 1-self.hitSq.pHP/
				self.batParams:data(combat.enum_PLAYER)[combat.HP_I]
			
			score = score + 100*dmgToEnemy - 200*dmgToPlayer 
				+ self.hitSq.expGained*self.expValueFactor
			
			printStr = printStr .. string.format(" d2e %.2f  d2p %.2f  exp %dx%.2f", 
					dmgToEnemy, dmgToPlayer, self.hitSq.expGained, self.expValueFactor)
		end
	end
	
	score = score * self.combatWeight
	
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

-- quickly find how many burns necessary for improving the result of the first RNBE
-- for artless rn burning gameplay
function P.searchFutureOutcomes()
	if PPrnbes.count < 1 then return end
	
	PPrnbes[1].burns = 0
	local record
	
	local function newRecord()
		record = PPrnbes[1]:evaluation_fn()
		print(string.format("%4d %3d %3d %s", rns.rng1.pos + PPrnbes[1].burns, PPrnbes[1].burns, record, PPrnbes[1]:resultString()))
	end
	
	print("Searching for " .. PPrnbes[1]:headerString())
	newRecord()
	
	local improveAttempts = 0
	while improveAttempts < 1000 do
		PPrnbes[1].burns = PPrnbes[1].burns + 1
		PPrnbes[1]:update()
		if record < PPrnbes[1]:evaluation_fn() then
			newRecord()
			improveAttempts = 0
		else 
			improveAttempts = improveAttempts + 1
		end
	end
	
	PPrnbes[1].burns = 0
	PPrnbes[1]:update()
end

function rnbeObj:drawMyBoxes(rect, RNBE_i)
	local line_i = 2*RNBE_i-1
	local INIT_CHARS = 5
	
	rect:drawBox(line_i, INIT_CHARS, self.burns * 3, "red")
		
	if self.combat then
		local hitStart = {}

		for ev_i = 1, self.hitSq.numEvents do
			if ev_i == 1 then
				hitStart[1] = self.burns
			else
				hitStart[ev_i] = hitStart[ev_i-1] + self.hitSq[ev_i-1].RNsConsumed
			end

			rect:drawBox(line_i, INIT_CHARS + hitStart[ev_i] * 3, 
				self.hitSq[ev_i].RNsConsumed * 3, "yellow")
		end
	end	
	if self:levelDetected() then
		local procs = unitData.willLevelStat(
				self.postCombatRN_i, self.unit_i, self.stats)
	
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

function P.addObj()
	P.SPrnbes().count = P.SPrnbes().count+1

	P.SPrnbes()[P.SPrnbes().count] = rnbeObj:new()
	sel_RNBE_i = P.SPrnbes().count
	permsNeedUpdate = true
	P.updateRNBEs()
end

-- decrements length of selected phase 
-- and adjusts IDs, including dependencies
function P.removeLastObj()
	if P.SPrnbes().count > 0 then
		local IDremoved = getLast(P.SPrnbes()).ID		
		for RNBE_i = 1, P.SPrnbes().count do
			if P.SPrnbes()[RNBE_i].ID > IDremoved then
				P.SPrnbes()[RNBE_i].ID = P.SPrnbes()[RNBE_i].ID - 1 -- dec own ID
				for RNBE_j = IDremoved, P.SPrnbes().count do -- dec dependency table after IDremoved
					P.SPrnbes()[RNBE_i].dependency[RNBE_j] = P.SPrnbes()[RNBE_i].dependency[RNBE_j+1]
				end
			end
		end
		
		P.SPrnbes().count = P.SPrnbes().count - 1
		permsNeedUpdate = true
		limitSel_RNBE_i()
	end
end

-- simply increments length of selected phase
-- and sets ID to new highest value
-- doesn't restore dependencies
function P.undoDelete()	
	if P.SPrnbes()[P.SPrnbes().count + 1] then
		P.SPrnbes().count = P.SPrnbes().count + 1	
		getLast(P.SPrnbes()).ID = P.SPrnbes().count
		permsNeedUpdate = true
	else
		print("No deletion to undo.")
	end
end

 -- index from 0, rns blank to be colorized
function P.toStrings()
	local ret = {}
	
	if P.SPrnbes().count <= 0 then
		ret[0] = "RNBEs empty"	
		return ret
	end
	
	for RNBE_i = 1, P.SPrnbes().count do
		ret[2*RNBE_i-2] = P.SPrnbes()[RNBE_i]:headerString(RNBE_i)
		ret[2*RNBE_i-1] = string.format("%4d ", P.SPrnbes()[RNBE_i].startRN_i)
	end
	return ret
end

function P.get(index)
	index = index or sel_RNBE_i
	return P.SPrnbes()[index]
end
function P.getByID(vID)
	for i = 1, P.SPrnbes().count do
		if P.SPrnbes()[i].ID == vID then
			return P.SPrnbes()[i]
		end
	end
	print("ID not found: " .. tostring(vID))
end

P.burnAmount = 1 -- toggle to 12 for reinforcements, longer burns, etc
function P.toggleBurnAmount()
	if P.burnAmount == 1 then
		P.burnAmount = 12
	else
		P.burnAmount = 1
	end
	print("Burn amount now " .. P.burnAmount)
end
function P.incBurns(amount)
	if P.SPrnbes().count <= 0 then return end

	amount = amount or P.burnAmount
	P.get().burns = P.get().burns + amount
	P.updateRNBEs()
end
function P.decBurns(amount)
	if P.SPrnbes().count <= 0 then return end
	
	amount = amount or P.burnAmount
	P.get().burns = P.get().burns - amount
	if P.get().burns < 0 then
		P.get().burns = 0
	end
	P.updateRNBEs()
end
function P.incSel()
	sel_RNBE_i = sel_RNBE_i + 1
	limitSel_RNBE_i()
end
function P.decSel()
	sel_RNBE_i = sel_RNBE_i - 1
	limitSel_RNBE_i()
end
function P.swap()
	if sel_RNBE_i < P.SPrnbes().count then
		if P.SPrnbes()[sel_RNBE_i+1].dependency[P.get().ID] then
			print(string.format("CAN'T SWAP, %d DEPENDS ON %d, TOGGLE WITH START", 
				P.SPrnbes()[sel_RNBE_i+1].ID, P.get().ID))
		else
			-- don't use get()?
			P.SPrnbes()[sel_RNBE_i], P.SPrnbes()[sel_RNBE_i+1] = P.SPrnbes()[sel_RNBE_i+1], P.SPrnbes()[sel_RNBE_i]
			P.updateRNBEs()
		end
	end
end
function P.toggleDependency()
	if sel_RNBE_i < P.SPrnbes().count then
		P.SPrnbes()[sel_RNBE_i+1].dependency[P.get().ID] = 
			not P.SPrnbes()[sel_RNBE_i+1].dependency[P.get().ID]
		
		if P.SPrnbes()[sel_RNBE_i+1].dependency[P.get().ID]	then
			print(string.format("%d NOW DEPENDS ON %d", 
				P.SPrnbes()[sel_RNBE_i+1].ID, P.get().ID))
		else
			print(string.format("%d NOW DOES NOT DEPEND ON %d", 
				P.SPrnbes()[sel_RNBE_i+1].ID, P.get().ID))
		end
		permsNeedUpdate = true
	end
end
function P.adjustCombatWeight(amount)
	if P.SPrnbes().count <= 0 then return end

	P.get().combatWeight = P.get().combatWeight + amount
	print("combatWeight: x" .. P.get().combatWeight)
end

-- functions that invalidate cache
function P.toggleBatParam(func, var)
	if rnbe.SPrnbes().count > 0 then
		func(P.get().batParams, var) -- :func() syntatic for func(self)
		P.get():clearCache()
		P.updateRNBEs()
	end
end

function P.changeEnemyID(amount)
	if P.SPrnbes().count <= 0 then return end

	P.get().enemyID = P.get().enemyID + amount
	P.get():clearCache()
	P.updateRNBEs()
end
function P.toggleCombat()
	if P.SPrnbes().count <= 0 then return end
	
	P.get().combat = not P.get().combat
	P.get():clearCache()
	P.get().enemyID = 0 -- don't want to cause enemyHP to carry
	P.updateRNBEs()
end
function P.toggleLevel()
	if P.SPrnbes().count <= 0 then return end
	
	P.get().lvlUp = not P.get().lvlUp
	P.get():clearCache()
	P.updateRNBEs()
end
function P.toggleDig()
	if P.SPrnbes().count <= 0 then return end
	
	P.get().dig = not P.get().dig
	P.get():clearCache()
	P.updateRNBEs()
end

function P.totalEvaluation()
	local score = 0	
	for RNBE_i = 1, PPrnbes.count do
		score = score + PPrnbes[RNBE_i].eval
	end
	for RNBE_i = 1, EPrnbes.count do
		score = score + EPrnbes[RNBE_i].eval
	end
	return score
end

local MEM_LIMIT = 500000

-- include logic to enforce dependencies
local function recursivePerm(usedNums, currPerm, currSize)
	if perms.count >= MEM_LIMIT then return end

	-- base case
	if currSize == P.SPrnbes().count then
		perms.count = perms.count + 1
		perms[perms.count] = currPerm
		
		if perms.count >= MEM_LIMIT then
			print()
			print(string.format("MEMORY LIMIT %d REACHED, ABORTING", MEM_LIMIT))
			print()
		end
		return
	end
	
	for next_i = 1, P.SPrnbes().count do
		if not usedNums[next_i] then
			-- if depends on unused RNBE, don't use yet
			
			local dependencyUnused = false
			for check_j = 1, P.SPrnbes().count do
				if P.getByID(next_i).dependency[check_j] and not usedNums[check_j] then
					dependencyUnused = true
				end
			end
			
			if not dependencyUnused then			
				local newUsedNums = {}
				local newCurrPerm = {}
				for copy_j = 1, P.SPrnbes().count do
					newUsedNums[copy_j] = usedNums[copy_j]
					newCurrPerm[copy_j] = currPerm[copy_j]
				end
				newUsedNums[next_i] = true
				newCurrPerm[currSize+1] = next_i
								
				recursivePerm(newUsedNums, newCurrPerm, currSize+1)
			end
		end
		if currSize == 0 then
			print(string.format("%d/%d %7d permutations", next_i, P.SPrnbes().count, perms.count))
			emu.frameadvance() -- prevent unresponsiveness
		end
	end
end

function P.permutations()
	--if not permsNeedUpdate then return end

	perms = {}
	perms.count = 0
	
	-- using nil as false doesn't fill table properly, explicitly fill
	local usedNums = {}
	local currPerm = {}
	for i = 1, P.SPrnbes().count do
		usedNums[i] = false
		currPerm[i] = 0
	end
	
	recursivePerm(usedNums, currPerm, 0)
	permsNeedUpdate = false
	
	if perms.count >= MEM_LIMIT then
		perms = {}
		perms.count = 0
		permsNeedUpdate = true
	end
end

function P.setToPerm(p_index, fast)
	local currPerm = perms[p_index]
	local lowestSwap = P.SPrnbes().count+1 -- don't need to update from 1 to lSwap-1
	-- saves a lot of time because usually only the higher RNBE are swapped
	
	for swapInto_i = 1, P.SPrnbes().count do
		local perm_ID = currPerm[swapInto_i]
				
		-- find RNBE with ID, previous should be in position
		-- if current (swapInto_i) is in position, doing nothing is OK
		for swapOutOf_j = swapInto_i+1, P.SPrnbes().count do
			if P.SPrnbes()[swapOutOf_j].ID == perm_ID then
				-- swap into place
				P.SPrnbes()[swapOutOf_j], P.SPrnbes()[swapInto_i] = P.SPrnbes()[swapInto_i], P.SPrnbes()[swapOutOf_j]
				
				if lowestSwap > swapInto_i then
					lowestSwap = swapInto_i
				end
			end
		end
	end
	
	P.updateRNBEs(lowestSwap, fast)
end

-- attempt every valid arrangement and score it
-- return top three options, first is auto-set
function P.suggestedPermutation(fast)
	if not P.playerPhase then
		print("enemy phase cannot be permuted")
		return
	end
	
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
	
	for perm_i = 1, perms.count do
		if ((perm_i % 1000 == 0 and (not fast)) or (perm_i % 5000 == 0)) then
			print(string.format("%7d/%d", perm_i, perms.count))
			emu.frameadvance() -- prevent unresponsiveness
		end
	
		-- swap each RNBE into position based on ID and perm, and update
		P.setToPerm(perm_i, fast)
		
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
	P.updateRNBEs(1)
	
	print()
	for RNBE_i = 1, PPrnbes.count do		
		PPrnbes[RNBE_i]:evaluation_fn(true)
	end
	print()
	for RNBE_i = 1, EPrnbes.count do		
		EPrnbes[RNBE_i]:evaluation_fn(true)
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

return rnbe