require("feAutolog")
-- emu.frameadvance() does not work from within requires
-- "attempt to yield across metamethod/C-call boundary"

-- Combat
if true then
	combat.paramInRAM()
	combat.currBattleParams:set()
	combat.hitSeq_string()
end

-- Event
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

if true then
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
	
	assert(rnEvent.getByID(2))
	assert(rnEvent.getByID(3) == nil)
	
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

print("---All tests passed---")