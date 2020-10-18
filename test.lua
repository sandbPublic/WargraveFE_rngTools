require("feGUI")
-- emu.frameadvance() does not work from within requires
-- "attempt to yield across metamethod/C-call boundary"

local testAll = true

if testAll then -- Misc
	print("---Misc...---")
	
	local miscTest = {}
	changeSelection(miscTest, 1)
	miscTest = {"a", "b"}
	changeSelection(miscTest)
	assert(selected(miscTest) == "a")
	changeSelection(miscTest, 1)
	assert(selected(miscTest) == "b")
	changeSelection(miscTest, 3)
	assert(selected(miscTest) == "a")
	changeSelection(miscTest, 2)
	assert(selected(miscTest) == "a")
	changeSelection(miscTest, -10)
	assert(selected(miscTest) == "a")
	changeSelection(miscTest, 2, "lock")
	assert(selected(miscTest) == "b")
	
	print("---Misc passed---")
else
	print("---Misc skipped---")
end

if testAll then -- Class
	print("---Class...---")
	assert(classes.isNoncombat(classes.DANCER))
	assert(classes.isNoncombat(classes.OTHER) == false)
	assert(classes.hasSilencer(classes.ASSASSIN_F))
	assert(classes.hasSilencer(classes.OTHER) == false)
	assert(classes.hasPierce(classes.WYVERN_KNIGHT_F))
	assert(classes.hasPierce(classes.OTHER) == false)
	assert(classes.hasSureStrike(classes.SNIPER_F) == (GAME_VERSION == 8))
	assert(classes.hasSureStrike(classes.OTHER) == false)
	assert(classes.hasGreatShield(classes.GENERAL_F) == (GAME_VERSION == 8))
	assert(classes.hasGreatShield(classes.OTHER) == false)
	print("---Class passed---")
else
	print("---Class skipped---")
end

if testAll then -- Random Numbers
	print("---Random numbers...---")
	
	assert(rns.rng1:name() == "primary")
	assert(rns.rng2:name() == "2ndary")
	
	assert(rns.rng1:generator(1) ~= nil)
	assert(rns.rng1:generator(2) ~= nil)
	assert(rns.rng1:generator(3) ~= nil)
	assert(rns.rng2:generator(1) ~= nil)
	assert(rns.rng2:generator(2) ~= nil)
	
	print("---Random numbers passed---")
else
	print("---Random numbers skipped---")
end

if testAll then -- Unit Data
	print("---Unit data...---")
	
	rns.rng1[0] = 89
	rns.rng1[1] = 89
	rns.rng1[2] = 89
	rns.rng1[3] = 89
	rns.rng1[4] = 89
	rns.rng1[5] = 89
	rns.rng1[6] = 89
	
	local u = unitData.currUnit()
	
	u.index = 0
	u.name = "Test name"
	u.growths = {90, 50, 0, 0, 0, 0, 90}
	u.freeStats = {0, 0, 1, 0, 0, 0, 0}
	u.growthWeights = {20, 45, 15, 60, 30, 10, 10}
	u.bases = {20, 0, 0, 0, 0, 0, 0, 1}

	u.promotion = classes.OTHER_PROMOTED
	u.willPromoteAt = 11 -- gain 10 levels before promotion
	u.willEndAt = 20
	
	u:loadRAMvalues({20, 1, 2, 3, 4, 5, 6, 11, 0})
	u.class = classes.OTHER
	u.canPromote = true
	assert(u.avgLevelValue == 6450) -- 20*90 + 45*50 + 15*100 + 10*90
	u.hasAfas = false
	
	local willLevelStats = {1, 0, 0, 0, 0, 0, 1}
	for i = 1, 7 do
		assert(u.growthWeights[i] == u.dynamicWeights[i], "assertion failed! " .. i)
		assert(u:willLevelStats(0)[i] == willLevelStats[i], "assertion failed! " .. i)
		assert(u:statsGained(i) == u.stats[i] - u.bases[i], "assertion failed! " .. i)
		u:statAverage(i)
		u:statDeviation(i)
		u:statStdDev(i)
		assert(u:effectiveGrowthRate(i) == u:statsGained(i)*10, "assertion failed! " .. i)
	end
	assert(u:statsGained(8) == u.stats[8] - u.bases[8])
	assert(u:levelUpProcs_string(0) == "+.....+")
	-- 20*100 + 15*100 + 10*100 = 4500
	assert(math.abs(u:levelScoreInExp(0) - 100*(4500/u.avgLevelValue-1)) < 0.00000001, 
		u:levelScoreInExp(0) .. " " ..  100*(4500/u.avgLevelValue-1))
	u:expValueFactor()
	
	
	
	
	-- level strength
	rns.rng1[1] = 49
	assert(u:willLevelStats(0)[2] == 1, u:willLevelStats(0)[2])
	assert(u:levelUpProcs_string(0) == "++....+", u:levelUpProcs_string(0))
	-- (20 + 45 + 15 + 10)*100 = 9000
	assert(math.abs(u:levelScoreInExp(0) - 100*(9000/u.avgLevelValue-1)) < 0.00000001, 
		u:levelScoreInExp(0) .. " " ..  100*(9000/u.avgLevelValue-1))
	
	
	
	
	-- test afas
	rns.rng1[1] = 54
	assert(u:willLevelStats(0)[2] == -2, u:willLevelStats(0)[2])
	if unitData.CAN_ADD_AFAS then
		assert(u:levelUpProcs_string(0) == "+?....+", u:levelUpProcs_string(0))
	else
		assert(u:levelUpProcs_string(0) == "+.....+", u:levelUpProcs_string(0))
	end
	assert(math.abs(u:levelScoreInExp(0) - 100*(4500/u.avgLevelValue-1)) < 0.00000001, 
		u:levelScoreInExp(0) .. " " ..  100*(4500/u.avgLevelValue-1))
	
	u:toggleAfas()
	assert(u:willLevelStats(0)[2] == 2, u:willLevelStats(0)[2])
	assert(u:levelUpProcs_string(0) == "+!....+")
	assert(math.abs(u:levelScoreInExp(0) - 100*(9000/u.avgLevelValue-1)) < 0.00000001, 
		u:levelScoreInExp(0) .. " " ..  100*(9000/u.avgLevelValue-1))
	u:toggleAfas()
	rns.rng1[1] = 89
	
	
		
	-- promote
	u.class = classes.OTHER_PROMOTED
	u.canPromote = true
	u.bases[8] = 1 + u.bases[8] - u.willPromoteAt
	
	for i = 1, 7 do
		assert(u.growthWeights[i] == u.dynamicWeights[i], "assertion failed! " .. i)
		assert(u:willLevelStats(0)[i] == willLevelStats[i], "assertion failed! " .. i)
		assert(u:statsGained(i) == u.stats[i] - u.bases[i], "assertion failed! " .. i)
		u:statAverage(i)
		u:statDeviation(i)
		u:statStdDev(i)
		assert(u:effectiveGrowthRate(i) == u:statsGained(i)*5, "assertion failed! " .. i)
	end
	assert(u:statsGained(8) == u.stats[8] - u.bases[8])
	
	for _,v in ipairs(u:statData_strings()) do
		print(v)
	end
	
	
	
	
	unitData.printRanks()
	unitData.printSupports()
	
	print("---Unit data passed...---")
else
	print("---Unit data skipped---")
end

if testAll then -- Combat
	print("---Combat...---")
	
	--combat.paramInRAM()
	assert(combat.hitSeq_string({}) == "")
	
	local c = combat.combatObj:new()
	
	c:isUsingStaff()
	c:willLevel(0)
	c:willLevel(100) -- don't assert, loaded attacker could be level 20
	c:expFrom()
	c:hitEvent(0, "attacker")
	
	c.attacker.name         = "a"
	c.attacker.class        = classes.LORD
	c.attacker.level        = 1
	c.attacker.exp          = 0
	c.attacker.maxHP        = 20
	c.attacker.luck         = 0
	c.attacker.weapon       = ""
	c.attacker.weaponType   = "normal"
	c.attacker.weaponUses   = 20
	c.attacker.usesMagic    = false
	c.attacker.atk          = 10
	c.attacker.def          = 5
	c.attacker.AS           = 5
	c.attacker.hit          = 100
	c.attacker.crit         = 0
	c.attacker.currHP       = 20
	
	c.defender.name         = "b"
	c.defender.class        = classes.OTHER
	c.defender.level        = 1
	c.defender.exp          = 0
	c.defender.maxHP        = 20
	c.defender.luck         = 0
	c.defender.weapon       = ""
	c.defender.weaponType   = "normal"
	c.defender.weaponUses   = 20
	c.attacker.usesMagic    = false
	c.defender.atk          = 10
	c.defender.def          = 5
	c.defender.AS           = 5
	c.defender.hit          = 100
	c.defender.crit         = 0
	c.defender.currHP       = 20
	
	local hitSeq
	
	local function reset()
		c:setNonRAM()
		c:setExpGain()
		hitSeq = c:hitSeq(0)
	end
	
	reset()
	
	assert(#hitSeq == 2, 
		"#hitSeq = " .. #hitSeq .. ", expected 2")
	assert(combat.hitSeq_string(hitSeq) == "X x 10xp", 
		"combat.hitSeq_string(hitSeq) = " .. combat.hitSeq_string(hitSeq) .. ", expected X x 10xp")
	assert(hitSeq.attacker.endHP == 15,
		"hitSeq.attacker.endHP = " .. hitSeq.attacker.endHP .. ", expected 15")
	assert(hitSeq.defender.endHP == 15,
		"hitSeq.defender.endHP = " .. hitSeq.defender.endHP .. ", expected 15")
	
	
	c.attacker.atk = 14
	c.attacker.AS = 10
	c.defender.level = 10
	reset()
	
	assert(#hitSeq == 3, 
		"#hitSeq = " .. #hitSeq .. ", expected 3")
	assert(combat.hitSeq_string(hitSeq) == "X x X 13xp", 
		"combat.hitSeq_string(hitSeq) = " .. combat.hitSeq_string(hitSeq) .. ", expected X x X 13xp")
	assert(hitSeq.attacker.endHP == 15,
		"hitSeq.attacker.endHP = " .. hitSeq.attacker.endHP .. ", expected 15")
	assert(hitSeq.defender.endHP == 2,
		"hitSeq.defender.endHP = " .. hitSeq.defender.endHP .. ", expected 2")
	
	
	c.attacker.weaponType = "brave"
	c.attacker.exp = 50
	c.defender.hit = 0
	reset()
	
	for k, v in pairs(hitSeq) do
		print(k, v)
		print()
	end
	assert(#hitSeq == 4, 
		"#hitSeq = " .. #hitSeq .. ", expected 4")
	assert(combat.hitSeq_string(hitSeq) == "X X o X 60xp Lvl", 
		"combat.hitSeq_string(hitSeq) = " .. combat.hitSeq_string(hitSeq) .. ", expected X X o X 60xp Lvl")
	assert(hitSeq.attacker.endHP == 20,
		"hitSeq.attacker.endHP = " .. hitSeq.attacker.endHP .. ", expected 20")
	assert(hitSeq.defender.endHP == 0,
		"hitSeq.defender.endHP = " .. hitSeq.defender.endHP .. ", expected 0")
	
	
	c.attacker.atk = 6
	c.defender.weaponType = "drain"
	c.defender.hit = 100
	c.defender.crit = 100
	reset()
	
	assert(#hitSeq == 5, 
		"#hitSeq = " .. #hitSeq .. ", expected 5")
	assert(combat.hitSeq_string(hitSeq) == "X X c X X 13xp", 
		"combat.hitSeq_string(hitSeq) = " .. combat.hitSeq_string(hitSeq) .. ", expected X X c X X 13xp")
	assert(hitSeq.attacker.endHP == 5,
		"hitSeq.attacker.endHP = " .. hitSeq.attacker.endHP .. ", expected 5")
	assert(hitSeq.defender.endHP == 18,
		"hitSeq.defender.endHP = " .. hitSeq.defender.endHP .. ", expected 18")
	
	c:staffHitEvent(0)
	c:toggleBonusExp()
	
	-- todo test rn and game version dependent factors
	
	print("---Combat passed---")
else
	print("---Combat skipped---")
end

if testAll then -- Event
	function eventTest()
		changeSelection(rnEvent.events, 1)
		changeSelection(rnEvent.events, -1)
		changeSelection(rnEvent.events, 10)
		changeSelection(rnEvent.events, -10)
		changeSelection(rnEvent.events, -1000)
		rnEvent.updateStats()
		
		rnEvent.toggle("hasCombat")
		rnEvent.toggle("lvlUp")
		rnEvent.toggle("dig")
		
		rnEvent.update_rnEvents()
		changeSelection(rnEvent.events, 1)
		rnEvent.toggleDependency()
		changeSelection(rnEvent.events, -1)
		rnEvent.toggleDependency()
		rnEvent.swap()
		
		rnEvent.totalEvaluation()
		rnEvent.searchFutureOutcomes()
		rnEvent.suggestPermutation()
		
		rnEvent.printDiagnostic()
		rnEvent.toStrings()
	end

	print("---Event...---")
	-- test behavior when no events exist
	rnEvent.undoDelete()
	eventTest()
	
	changeFields = {"burns", "pHPweight", "eHPweight"}
	changeAmounts = {1, -1, 10, -10, -1000}
	
	for i, field in ipairs(changeFields) do
		for j, amount in ipairs(changeAmounts) do
			rnEvent.change(field, amount)
		end
	end
	
	rnEvent.addEvent()
	rnEvent.addEvent()
	rnEvent.addEvent()
	
	assert(rnEvent.getByID(3))
	assert(rnEvent.getByID(4) == nil)
	
	eventTest()
	
	for i, field in ipairs(changeFields) do
		for j, amount in ipairs(changeAmounts) do
			rnEvent.change(field, amount)
		end
		assert(selected(rnEvent.events)[field] == 0)
	end
	
	rnEvent.deleteLastEvent()
	rnEvent.deleteLastEvent()
	rnEvent.deleteLastEvent()
	rnEvent.undoDelete()
	rnEvent.deleteLastEvent()
	rnEvent.deleteLastEvent()
	
	print("---Event passed---")
else
	print("---Event skipped---")
end

if testAll then -- GUI
	print("---GUI...---")
	
	for i = 1, 7 do
		selected(feGUI.rects):adjust(0.02*i, 0, 0)
		selected(feGUI.rects):adjust(0, .02*i, 0)
		selected(feGUI.rects):adjust(0, 0, 0.04*i)
		changeSelection(feGUI.rects, 1)
	end
	feGUI.drawRects()
	for i = 1, 8 do
		selected(feGUI.rects):adjust(-0.02*i, 0, 0)
		selected(feGUI.rects):adjust(0, -.02*i, 0)
		selected(feGUI.rects):adjust(0, 0, -0.04*i)
		changeSelection(feGUI.rects, -1)
	end
	
	print("---GUI passed---")
else
	print("---GUI skipped---")
end

if testAll then -- Autolog
	print("---Autolog...---")
	
	autolog.addLog("TEST")
	autolog.passiveUpdate()
	autolog.addLog_RNconsumed()
	autolog.addLog_RNconsumed()
	autolog.writeLogs()
	
	print("---Autolog passed---")
else
	print("---Autolog skipped---")
end

if testAll then
	print("---All tests passed---")
end