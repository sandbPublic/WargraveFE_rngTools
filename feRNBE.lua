require("feUnitData")
require("feCombat")
require("feGUI")

local P = {}
rnbe = P -- random number block event

local PP = {} -- Player Phase rnbes
PP.length = 0
local EP = {} -- Enemy Phase rnbes
EP.length = 0
P.playerPhase = true

local function getLast(list)
	return list[list.length]
end

-- selected phase
function P.SP()
	if P.playerPhase then return PP end
	return EP
end

function P.togglePhase()
	P.playerPhase = not P.playerPhase
	if sel_RNBE_i > P.SP().length  then
		sel_RNBE_i = P.SP().length
	end
end

local sel_RNBE_i = 1
local function limitSel_RNBE_i()
	if sel_RNBE_i > P.SP().length then sel_RNBE_i = P.SP().length end
	if sel_RNBE_i < 1 then sel_RNBE_i = 1 end -- TODO why is this needed?
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
	stats = stats or unitData.getSavedStats()
	combatO = combatO or combat.currBattleParams	
	sel_Unit_i = sel_Unit_i or unitData.sel_Unit_i

	local o = {}
	setmetatable(o, self)
	self.__index = self
	 
	o.ID = P.SP().length -- order in which rnbes were registered
	o.dependency = {} -- to enforce dependencies: certain rnbes must precede others
	
	o.unit_i = sel_Unit_i	
	o.stats = {}
	for stat_i = 1, unitData.i_EXP do
		o.stats[stat_i] = stats[stat_i]
	end
	o.batParams = combatO:copy()
	o.combat = true -- most RNBEs will be combats without levels or digs
	o.lvlUp = false
	o.dig = false
	-- as units ram their caps (or have the potential to), the value of their levels drops
	o.expValueFactor = unitData.expValueFactor(o.unit_i, o.stats)
	
	o.enemyID = 0 -- for units attacking the same enemyID
	o.enemyHP = 0 -- if a previous unit has damaged this enemy. HP at start of this rnbe
	-- TODO player HP (from multi combat due to dance, or EP)
	
	o.burns = 0 -- TODO AI burns?
	o.startRN_i = 0
	o.postBurnsRN_i = 0
	o.hitSq = {} -- not hitSeq, avoid confusion with function
	o.postCombatRN_i = 0
	o.nextRN_i = 0
	o.length = 0
	o.eval = 0
		
	return o
end

-- assumes previous rnbes have updates for optimization
function rnbeObj:update(RNBE_i)	
	if RNBE_i == 1 then 
		if P.playerPhase then
			self.startRN_i = rns.pos
		else
			self.startRN_i = getLast(PP).nextRN_i
		end
	else
		self.startRN_i = P.SP()[RNBE_i-1].nextRN_i
	end

	self.postBurnsRN_i = self.startRN_i + self.burns
	
	if self.combat then	
		self.enemyHP = self.batParams:data(combat.enum_ENEMY)[combat.i_HP]
		-- check eHP from previous combat(s) if applicable
		if self.enemyID ~= 0 then
			for prevCombat_i = 1, RNBE_i-1 do
				if P.SP()[prevCombat_i].enemyID == self.enemyID then
					self.enemyHP = P.SP()[prevCombat_i].hitSq.eHP
				end
			end
		end
		
		self.hitSq = self.batParams:hitSeq(self.postBurnsRN_i, self.enemyHP)
		
		self.postCombatRN_i = self.postBurnsRN_i + self.hitSq.totalRNsConsumed
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

function P.updateRNBEs(start_i)
	start_i = start_i or sel_RNBE_i
	
	if P.playerPhase then
		for RNBE_i = start_i, PP.length do
			PP[RNBE_i]:update(RNBE_i)
		end
		start_i = 1 -- start from beginning of EP afterwards
	end
	
	for RNBE_i = start_i, EP.length do
		EP[RNBE_i]:update(RNBE_i)
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
	return rns.getRNasCent(self.nextRN_i - 1) < self.stats[unitData.i_LUCK]
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
	if RNBE_i == sel_RNBE_i and feGUI.pulse() and
		feGUI.canAlterRNBE() then 
		ret = "->" 
	end
	
	local specialStringEvents = ""	
	
	if self.enemyID ~= 0 then
		specialStringEvents = specialStringEvents .. 
			string.format(" eID %d %dhp", self.enemyID, self.enemyHP)
	end
	local weapon = self.batParams:data(combat.enum_PLAYER).weapon
	if weapon ~= combat.enum_NORMAL then
		specialStringEvents = specialStringEvents .. " " .. combat.WEAPON_TYPE_STRINGS[weapon]
	end
	if self.batParams:data(combat.enum_ENEMY).class ~= classes.F.LORD then
		specialStringEvents = specialStringEvents .. " spec class"
	end
	
	return ret .. string.format("%2d %s%s%s",
		self.ID, unitData.names(self.unit_i), self:resultString(), specialStringEvents)
end
function rnbeObj:RNPrefixString()
	return string.format("%04d+%02d:", self.startRN_i, self.burns)
end

-- measure in units of exp
-- perfect combat value == 100 exp
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
				self.batParams:data(combat.enum_ENEMY)[combat.i_HP]
			local dmgToPlayer = 1-self.hitSq.pHP/
				self.batParams:data(combat.enum_PLAYER)[combat.i_HP]
			
			score = score + 100*dmgToEnemy - 200*dmgToPlayer 
				+ self.hitSq.expGained*self.expValueFactor
		
			printStr = printStr .. string.format(" d2e %.2f  d2p %.2f  exp %dx%.2f", 
					dmgToEnemy, dmgToPlayer, self.hitSq.expGained, self.expValueFactor)
		end
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

function rnbeObj:drawMyBoxes(rect, RNBE_i)
	local line_i = 2*RNBE_i-1
	
	rect:drawBox(line_i, 9, self.burns * 3, "red")
		
	if self.combat then
		local hitStart = {}

		for ev_i = 1, self.hitSq.numEvents do
			if ev_i == 1 then
				hitStart[1] = self.burns
			else
				hitStart[ev_i] = hitStart[ev_i-1] + self.hitSq[ev_i-1].RNsConsumed
			end

			rect:drawBox(line_i, 9 + hitStart[ev_i] * 3, 
				self.hitSq[ev_i].RNsConsumed * 3, "yellow")
		end
	end	
	if self:levelDetected() then
		for stat_i = 1, 7 do
			local proc = unitData.willLevelStat(
				stat_i, self.postCombatRN_i, self.unit_i, self.stats)
		
			if proc == 1 then
				rect:drawBox(line_i, 
					9 + (self.postCombatRN_i-self.startRN_i + stat_i-1) * 3,
					3, LEVEL_UP_COLORS[stat_i]) 
			elseif proc == -1 then -- capped stat
				rect:drawBox(line_i, 
					9 + (self.postCombatRN_i-self.startRN_i + stat_i-1) * 3,
					3, feGUI.flashcolor(0x662222FF, "black"))
			end
		end
	end
end

function P.addObj()
	P.SP().length = P.SP().length+1

	P.SP()[P.SP().length] = rnbeObj:new()
	sel_RNBE_i = P.SP().length
	P.updateRNBEs()
end

-- decrements length of selected phase 
-- and adjusts IDs, including dependencies
function P.removeLastObj()
	if P.SP().length > 0 then
		local IDremoved = getLast(P.SP()).ID		
		for RNBE_i = 1, P.SP().length do
			if P.SP()[RNBE_i].ID > IDremoved then
				P.SP()[RNBE_i].ID = P.SP()[RNBE_i].ID - 1 -- dec own ID
				for RNBE_j = IDremoved, P.SP().length do -- dec dependency table after IDremoved
					P.SP()[RNBE_i].dependency[RNBE_j] = P.SP()[RNBE_i].dependency[RNBE_j+1]
				end
			end
		end
		
		P.SP().length = P.SP().length - 1
		limitSel_RNBE_i()
	end
end

-- simply increments length of selected phase
-- and sets ID to new highest value
-- doesn't restore dependencies
function P.undoDelete()	
	if P.SP()[P.SP().length + 1] then
		P.SP().length = P.SP().length + 1	
		getLast(P.SP()).ID = P.SP().length
	else
		print("No deletion to undo.")
	end
end

 -- index from 0, rns blank to be colorized
function P.toStrings()
	local ret = {}
	
	if P.SP().length <= 0 then
		ret[0] = "RNBEs empty"	
		return ret
	end
	
	for RNBE_i = 1, P.SP().length do
		ret[2*RNBE_i-2] = P.SP()[RNBE_i]:headerString(RNBE_i)
		ret[2*RNBE_i-1] = P.SP()[RNBE_i]:RNPrefixString()
	end
	return ret
end

function P.get(index)
	index = index or sel_RNBE_i
	return P.SP()[index]
end
function P.getByID(vID)
	for i = 1, P.SP().length do
		if P.SP()[i].ID == vID then
			return P.SP()[i]
		end
	end
	print("ID not found: " .. vID)
end

function P.incBurns(amount)
	amount = amount or 1
	if sel_RNBE_i <= P.SP().length then -- check that length isn't zero while sel == 1
		P.get().burns = P.get().burns + amount
		P.updateRNBEs()
	end
end
function P.decBurns(amount)
	amount = amount or 1
	if sel_RNBE_i <= P.SP().length then
		P.get().burns = P.get().burns - amount
		if P.get().burns < 0 then
			P.get().burns = 0
		end
		P.updateRNBEs()
	end
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
	if sel_RNBE_i < P.SP().length then
		if P.SP()[sel_RNBE_i+1].dependency[P.get().ID] then
			print(string.format("CAN'T SWAP, %d DEPENDS ON %d, TOGGLE WITH START", 
				P.SP()[sel_RNBE_i+1].ID, P.get().ID))
		else
			P.SP()[sel_RNBE_i], P.SP()[sel_RNBE_i+1] = P.SP()[sel_RNBE_i+1], P.SP()[sel_RNBE_i]
			P.updateRNBEs()
		end
	end
end
function P.toggleDependency()
	if sel_RNBE_i < P.SP().length then
		P.SP()[sel_RNBE_i+1].dependency[P.get().ID] = 
			not P.SP()[sel_RNBE_i+1].dependency[P.get().ID]
		
		if P.SP()[sel_RNBE_i+1].dependency[P.get().ID]	then
			print(string.format("%d NOW DEPENDS ON %d", 
				P.SP()[sel_RNBE_i+1].ID, P.get().ID))
		else
			print(string.format("%d NOW DOES NOT DEPEND ON %d", 
				P.SP()[sel_RNBE_i+1].ID, P.get().ID))
		end
	end
end
function P.changeEnemyID(amount)
	if sel_RNBE_i <= P.SP().length then -- check for sel = 1, length = 0
		P.get().enemyID = P.get().enemyID + amount
		P.updateRNBEs()
	end
end

function P.toggleCombat()
	if sel_RNBE_i <= P.SP().length then
		P.SP()[sel_RNBE_i].combat = not P.SP()[sel_RNBE_i].combat
		P.updateRNBEs()
	end
end
function P.toggleLevel()
	if sel_RNBE_i <= P.SP().length then
		P.SP()[sel_RNBE_i].lvlUp = not P.SP()[sel_RNBE_i].lvlUp 
		P.updateRNBEs()
	end
end
function P.toggleDig()
	if sel_RNBE_i <= P.SP().length then
		P.SP()[sel_RNBE_i].dig = not P.SP()[sel_RNBE_i].dig 
		P.updateRNBEs()
	end
end

function P.totalEvaluation()
	local score = 0	
	for RNBE_i = 1, P.PP.length do
		score = score + P.PP[RNBE_i].eval
	end
	for RNBE_i = 1, P.EP.length do
		score = score + P.EP[RNBE_i].eval
	end
	return score
end

local perms = {}
local permsSize = 0

-- include logic to enforce dependencies
local function recursivePerm(usedNums, currPerm, currSize)
	-- base case
	if currSize == P.SP().length then
		permsSize = permsSize + 1
		perms[permsSize] = currPerm
		return
	end
	
	for next_i = 1, P.SP().length do
		if not usedNums[next_i] then
			-- if depends on unused RNBE, don't use yet
			
			local dependencyUnused = false
			for check_j = 1, P.SP().length do
				if P.getByID(next_i).dependency[check_j] and not usedNums[check_j] then
					dependencyUnused = true
				end
			end
			
			if not dependencyUnused then			
				local newUsedNums = {}
				local newCurrPerm = {}
				for copy_j = 1, P.SP().length do
					newUsedNums[copy_j] = usedNums[copy_j]
					newCurrPerm[copy_j] = currPerm[copy_j]
				end
				newUsedNums[next_i] = true
				newCurrPerm[currSize+1] = next_i
								
				recursivePerm(newUsedNums, newCurrPerm, currSize+1)
			end
		end
		if currSize == 0 then
			print(string.format("%d/%d permutation main branches", next_i, P.SP().length))
			emu.frameadvance() -- prevent unresponsiveness
		end
	end
end

function P.permutations()
	perms = {}
	permsSize = 0
	
	-- using nil as false doesn't fill table properly, explicitly fill
	local usedNums = {}
	local currPerm = {}
	for i = 1, P.SP().length do
		usedNums[i] = false
		currPerm[i] = 0
	end
	
	recursivePerm(usedNums, currPerm, 0)
end

function P.setToPerm(p_index)
	local currPerm = perms[p_index]
	local lowestSwap = P.SP().length+1 -- don't need to update from 1 to lSwap-1
	-- saves a lot of time because usually only the higher RNBE are swapped
	
	for swapInto_i = 1, P.SP().length do
		local perm_ID = currPerm[swapInto_i]
		
		-- find RNBE with ID, previous should be in position
		-- if current (swapInto_i) is in position, doing nothing is OK
		for swapOutOf_j = swapInto_i+1, P.SP().length do
			if P.SP()[swapOutOf_j].ID == perm_ID then
				-- swap into place
				P.SP()[swapOutOf_j], P.SP()[swapInto_i] = P.SP()[swapInto_i], P.SP()[swapOutOf_j]
				
				if lowestSwap > swapInto_i then
					lowestSwap = swapInto_i
				end
			end
		end
	end
	
	P.updateRNBEs(lowestSwap)
end

--TODO seperate enemy phase RNBE set, do not permute but account for score

-- attempt every valid arrangement and score it
-- return top three options, first is auto-set
function P.suggestedPermutation()
	local timeStarted = os.clock()

	-- generate array of valid permutations
	-- for each perm
	--		swap RNBE into position
	--		score each RNBE:
	--      if swap order violated, return -999
	--		combat, can be marked as critical
	--		lvl ups, just use that score
	--		dig, + some constant
	--		add score/permutation pair to array
	-- sort array by score, print top results?
	P.permutations()
	local scores = {}
	local topN = 3
	local topIndicies = {0, 0, 0}
	local topScores = {-999, -999, -999}
	
	for perm_i = 1, permsSize do
		if perm_i % 1000 == 0 then
			print(string.format("%d/%d", perm_i, permsSize))
			emu.frameadvance() -- prevent unresponsiveness
		end
	
		-- swap each RNBE into position based on ID and perm, and update
		P.setToPerm(perm_i)
		scores[perm_i] = P.totalEvaluation()
		
		-- update top results
		local replaced = false
		for top_j = 1, topN do
			if scores[perm_i] > topScores[top_j] and not replaced then
				for shift_k = topN, top_j + 1, -1 do
					topScores[shift_k] = topScores[shift_k-1]
					topIndicies[shift_k] = topIndicies[shift_k-1]
				end
				topScores[top_j] = scores[perm_i]
				topIndicies[top_j] = perm_i
				replaced = true
			end
		end
	end
	
	P.setToPerm(topIndicies[1])
	P.updateRNBEs(1)
	
	for RNBE_i = 1, P.SP().length do
		P.SP()[RNBE_i]:evaluation_fn(true)
	end
	for top_j = 1, topN do
		if not scores[topIndicies[top_j]] then
			scores[topIndicies[top_j]] = -999
		end
		print(perms[topIndicies[top_j]])
		print(string.format("%.2f", scores[topIndicies[top_j]]))
	end
	
	print(string.format("Time taken: %.2f seconds", os.clock() - timeStarted))
end

return rnbe