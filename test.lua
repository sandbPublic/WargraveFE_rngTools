require("feAutolog")
-- emu.frameadvance() does not work from within requires
-- "attempt to yield across metamethod/C-call boundary"

-- Misc
if true then
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

-- Class
if true then
	print("---Class...---")
	
	
	print("---Class passed---")
end

-- Random Numbers
if true then
	print("---Random numbers...---")
	
	assert(rns.rng1:name() == "primary")
	assert(rns.rng2:name() == "2ndary")
	
	assert(rns.rng1:generator(1) ~= nil)
	assert(rns.rng1:generator(2) ~= nil)
	assert(rns.rng1:generator(3) ~= nil)
	assert(rns.rng2:generator(1) ~= nil)
	assert(rns.rng2:generator(2) ~= nil)
	
	rns.rng1:printRawBytes(0, 10)
	rns.rng2:printRawBytes(0, 10)
	
	print("---Random numbers passed---")
end

-- Unit Data
if true then
	print("---Unit data...---")
	unitData.printRanks()
	unitData.printSupports()
	-- todo unitObj tests
	
	print("---Unit data passed...---")
end

-- Combat
if true then
	print("---Combat...---")
	
	--combat.paramInRAM()
	c = combat.combatObj:new()
	assert(combat.hitSeq_string({}) == "")
	-- todo combatObj tests
	
	print("---Combat passed---")
end

-- Event
if true then
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

-- GUI
if true then
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

-- Autolog
if true then
	print("---Autolog...---")
	
	autolog.addLog()
	autolog.addLog()
	autolog.writeLogs()
	
	print("---Autolog passed---")
end

print("---All tests passed---")