require("feAutolog")
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
end

if testAll then -- Unit Data
	print("---Unit data...---")
	
	local u = unitData.currUnit()
	
	u:willLevelStats(0)
	print(u:levelUpProcs_string(0))
	u:levelScoreInExp(0)
	u:expValueFactor()
	
	for stat_i = 1, 7 do
		u:statsGained(stat_i)
		u:statAverage(stat_i)
		u:statDeviation(stat_i)
		u:statStdDev(stat_i)
		u:effectiveGrowthRate(stat_i)
	end
	
	print(u:statData_strings())
	u:toggleAfas()
	u:setDynamicWeights()
	u:setStats()
	
	unitData.printRanks()
	unitData.printSupports()
	
	print("---Unit data passed...---")
end

if testAll then -- Combat
	print("---Combat...---")
	
	--combat.paramInRAM()
	assert(combat.hitSeq_string({}) == "")
	
	local c = combat.combatObj:new()
	
	c:combatant()
	c:isUsingStaff()
	assert(c:willLevel(0) == false)
	assert(c:willLevel(100))
	c:expFrom()
	c:hitEvent(0)
	
	c.attacker.name         = "a"
	c.attacker.class        = classes.LORD
	c.attacker.level        = 1
	c.attacker.exp          = 0
	c.attacker.x            = 0
	c.attacker.y            = 0
	c.attacker.maxHP        = 20
	c.attacker.luck         = 0
	c.attacker.weapon       = 1
	c.attacker.weaponType   = "normal"
	c.attacker.weaponUses   = 20
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
	c.defender.x            = 0
	c.defender.y            = 0
	c.defender.maxHP        = 20
	c.defender.luck         = 0
	c.defender.weapon       = 1
	c.defender.weaponType   = "normal"
	c.defender.weaponUses   = 20
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
	
	assert(#hitSeq == 2)
	assert(combat.hitSeq_string(hitSeq) == "X x 10xp")
	assert(hitSeq.atkHP == 15)
	assert(hitSeq.defHP == 15)
	
	
	c.attacker.atk = 14
	c.attacker.AS = 10
	c.defender.level = 10
	reset()
	
	assert(#hitSeq == 3)
	assert(combat.hitSeq_string(hitSeq) == "X x X 13xp")
	assert(hitSeq.atkHP == 15)
	assert(hitSeq.defHP == 2)
	
	
	c.attacker.weaponType = "brave"
	c.attacker.exp = 50
	c.defender.hit = 0
	reset()
	
	assert(#c:hitSeq(0) == 4)
	assert(combat.hitSeq_string(hitSeq) == "X X o X 60xp Lvl")
	assert(hitSeq.atkHP == 20)
	assert(hitSeq.defHP == 0)
	
	
	c.attacker.atk = 6
	c.defender.weaponType = "drain"
	c.defender.hit = 100
	c.defender.crit = 100
	reset()
	
	assert(#c:hitSeq(0) == 5)
	assert(combat.hitSeq_string(hitSeq) == "X X c X X 13xp")
	assert(hitSeq.atkHP == 5)
	assert(hitSeq.defHP == 18)
	
	c:staffHitEvent(0)
	c:hitSeq(0)
	c:toggleBonusExp()
	
	-- todo test rn and game version dependent factors
	
	print("---Combat passed---")
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
		rnEvent.suggestedPermutation()
		
		rnEvent.printDiagnostic()
		rnEvent.toStrings()
	end

	print("---Event...---")
	-- test behavior when no events exist
	rnEvent.undoDelete()
	eventTest()
	
	changeFields = {"burns", "enemyID", "pHPweight", "eHPweight"}
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
end

if testAll then -- GUI
	print("---GUI...---")
	feGUI.lookingAt(0)
	feGUI.canAlter_rnEvent()
	feGUI.drawRects()	
	
	selected(feGUI.rects):adjust(0.02, 0, 0)
	selected(feGUI.rects):adjust(-0.02, 0, 0)
	selected(feGUI.rects):adjust(0, .02, 0)
	selected(feGUI.rects):adjust(0, -.02, 0)
	selected(feGUI.rects):adjust(0, 0, 0.04)
	selected(feGUI.rects):adjust(0, 0, -0.04)
	
	changeSelection(feGUI.rects, -1)
	changeSelection(feGUI.rects, 1)
	
	print("---GUI passed---")
end

if testAll then -- Autolog
	print("---Autolog...---")
	
	autolog.passiveUpdate()
	autolog.addLog_string("test")
	autolog.addLog_RNconsumed()
	autolog.addLog_RNconsumed()
	autolog.writeLogs()
	
	print("---Autolog passed---")
end

print("---All tests passed---")