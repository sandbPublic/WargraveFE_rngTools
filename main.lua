-- use x.count to track array size
-- use ABCD_I to name a constant index
-- use enum_ABCD for enums

-- 07000003 cursor pulse
-- 0202.. 55E0, 55E2, BCC4, BCC8 cursor x pos
-- 0202.. 55E1, 55E3, BCC6, BCCA cursor y pos
-- .. 55C6 = 0

require("feRandomNumbers")
require("feClass")
require("feUnitData")
require("feCombat")
require("fe_rnEvent")
require("feGUI")

local function printStringArray(array, size)
	print("")
	for i = 0, size-1 do
		print(array[i])
	end
end

function rotInc(num, maxVal, inc, minVal)
	minVal = minVal or 1
	inc = inc or 1
	if num + inc > maxVal then
		return minVal
	end
	return num + inc
end

local savedFogRange = 0
local primaryFunctions = true

-- GJLUY
--  HNEIO
-- BKM

local hotkeys = {}
local function loadHotkeys(filename)
	local f = assert(io.open(filename, "r"))
	
	hotkeys.count = 0
	local c = f:read("*line")
	
	while c do
		hotkeys.count = hotkeys.count + 1
		hotkeys[hotkeys.count] = {}
		hotkeys[hotkeys.count].key = c
		hotkeys[hotkeys.count].message1 = c .. ": " .. f:read("*line")
		hotkeys[hotkeys.count].message2 = string.lower(c) .. ": " ..f:read("*line")
		c = f:read("*line")
	end
	
	print("loaded hotkeys " .. filename)
end
loadHotkeys("QwertyHotkeys.txt")

local function printHelp()
	print("")

	for hotkey_i = 1, hotkeys.count do
		if primaryFunctions then
			print(hotkeys[hotkey_i].message1)
		else
			print(hotkeys[hotkey_i].message2)
		end
	end
end

-- START
-- TODO levels in vicinity functionality
-- for level ups/battles on EP?
printHelp()

-- struct style so pressed needs one fewer param in more common keybCtrl case
local keybCtrl = {}
keybCtrl.thisFrame = {}
keybCtrl.lastFrame = {}
local gameCtrl = {}
gameCtrl.thisFrame = {}
gameCtrl.lastFrame = {}

local function updateCtrl(ctrl, currFrame)
	ctrl.lastFrame = ctrl.thisFrame
	ctrl.thisFrame = currFrame
end

local function pressed(key, ctrl)
	ctrl = ctrl or keybCtrl
	
	if type(key) == "number" then
		key = hotkeys[key].key
	end
	
	return ctrl.thisFrame[key] and not ctrl.lastFrame[key]
end

local update2ndary = false
local fogAddr = {}

fogAddr[6] = 0x202AA55
fogAddr[7] = 0x202BC05
fogAddr[8] = 0x202BCFD

while true do
	local reprintRNs = false
	local reprintStats = false
	local reprintLvlUps = false
	
	if rns.rng1:update() then
		rnEvent.update_rnEvents(1)
	end
	
	if update2ndary then
		rns.rng2:update()
	end
	
	updateCtrl(keybCtrl, input.get())
	updateCtrl(gameCtrl, joypad.get(0))
	
	if feGUI.rectShiftMode then -- move rects or change opacity
		if gameCtrl.thisFrame.left 	then feGUI.selRect():shift(-0.02, 0, 0) end
		if gameCtrl.thisFrame.right then feGUI.selRect():shift( 0.02, 0, 0) end
		if gameCtrl.thisFrame.up 	then feGUI.selRect():shift(0, -0.02, 0) end
		if gameCtrl.thisFrame.down 	then feGUI.selRect():shift(0,  0.02, 0) end
		if gameCtrl.thisFrame.L 	then feGUI.selRect():shift(0, 0, -0.04) end
		if gameCtrl.thisFrame.R 	then feGUI.selRect():shift(0, 0,  0.04) end
	end
	
	if feGUI.canAlter_rnEvent() then -- alter burns, selected, swap, toggle swapping
		-- change burns
		if pressed("left", gameCtrl) then
			rnEvent.decBurns()
		end		
		if pressed("right", gameCtrl) then
			rnEvent.incBurns()
		end
		
		if pressed("L", gameCtrl) then
			rnEvent.changeEnemyID(-1)
		end		
		if pressed("R", gameCtrl) then
			rnEvent.changeEnemyID(1)
		end
		
		-- change selection
		if pressed("up", gameCtrl) then
			rnEvent.decSel()
		end
		if pressed("down", gameCtrl) then
			rnEvent.incSel()
		end
		
		-- swap with next
		if pressed("select", gameCtrl) then
			rnEvent.swap() -- updates self
		end
		
		if pressed("start", gameCtrl) then
			rnEvent.toggleDependency()
		end
	end
	
	if pressed(6) then -- print help
		primaryFunctions = not primaryFunctions
		printHelp()
	end
	
	if primaryFunctions then
		if pressed(1) then rnEvent.deleteLastEvent() end	
		
		if pressed(2) then
			unitData.saveStats()
			rnEvent.addEvent()
			rnEvent.get().batParams:set()
			rnEvent.update_rnEvents()
			
			printStringArray(rnEvent.get().batParams:toStrings(), 3)
		end
		
		if pressed(3) then rnEvent.toggleCombat() end
		
		if pressed(4) then
			rnEvent.toggleBatParam(combat.combatObj.togglePromo)
			
			printStringArray(rnEvent.get().batParams:toStrings(), 3)
		end	
		
		if pressed(5) then
			rnEvent.toggleBatParam(combat.combatObj.toggleBonusExp)
		end
		
		if pressed(7) then -- advance to next deployed
			unitData.sel_Unit_i = unitData.nextDeployed()
			print(string.format("Selected %-10.10s (next %s)", unitData.names(), 
				unitData.names(unitData.nextDeployed())))
		end
		
		if pressed(8) then -- quick toggle visibility
			if feGUI.selRect().opacity == 0 then
				feGUI.selRect().opacity = 0.75
			else
				feGUI.selRect().opacity = 0
			end
		end
		
		if pressed(9) then feGUI.advanceDisplay() end
		
		if pressed(10) then 
			rnEvent.suggestedPermutation()
		end
		
		if pressed(11) then
			rnEvent.toggleBatParam(combat.combatObj.cycleEnemyClass)
		end
		
		if pressed(12) then -- save battle params & stats
			combat.currBattleParams:set()
			printStringArray(combat.currBattleParams:toStrings(), 3)
			
			reprintStats = true
			unitData.saveStats()
			rnEvent.updateStats()
		end
		
		if pressed(13) then unitData.setAfas() end
	else
		if pressed(1) then rnEvent.undoDelete() end
		if pressed(2) then
			if gameCtrl.thisFrame.B then
				rnEvent.toggleBatParam(combat.combatObj.cycleWeapon, combat.enum_ENEMY)
			else
				rnEvent.toggleBatParam(combat.combatObj.cycleWeapon, combat.enum_PLAYER)
			end
		end
		if pressed(3) then rnEvent.toggleLevel() end
		if pressed(4) then rnEvent.toggleDig() end
		
		if keybCtrl.thisFrame[hotkeys[5].key] then -- hold down, then press L/R
			local currFogRange = memory.readbyte(fogAddr[version])
			if pressed("L", gameCtrl) then
				currFogRange = currFogRange - 1
				memory.writebyte(fogAddr[version], currFogRange)
				print("fog set to " .. tostring(currFogRange))
			end
			if pressed("R", gameCtrl) then
				currFogRange = currFogRange + 1
				memory.writebyte(fogAddr[version], currFogRange)
				print("fog set to " .. tostring(currFogRange))
			end
		end	
		
		if keybCtrl.thisFrame[hotkeys[7].key] then
			if pressed("L", gameCtrl) then
				rnEvent.adjustCombatWeight(-0.5)
			end		
			if pressed("R", gameCtrl) then
				rnEvent.adjustCombatWeight(0.5)
			end
		end
		
		if pressed(8) then 
			feGUI.rectShiftMode = not feGUI.rectShiftMode
			
			if feGUI.rectShiftMode then
				print("display shift mode: ON")
				print("change display opacity with L and R")
				print("change display position with D-pad")
				
				if feGUI.selRect().opacity == 0 then
					feGUI.selRect().opacity = 0.5
				end
			else
				print("display shift mode: OFF")
			end
		end	
		
		if pressed(9) then rnEvent.toggleBurnAmount() end
		if pressed(10) then rnEvent.searchFutureOutcomes() end
		
		if pressed(11) then
			update2ndary = not update2ndary
			print("update2ndary = " .. tostring(update2ndary))
		end
		
		if pressed(12) then rnEvent.diagnostic() end
		
		if pressed(13) then rnEvent.togglePhase() end
	end
	
	if reprintRNs then
		printStringArray(rns.rng1:RNstream_strings(false, 5, 10), 5)
	end

	if reprintStats then
		printStringArray(unitData.statData_strings(), 2) -- up to 9 lines
		--print(string.format("percentile: %.1f", 100*unitData.percentile())) 
	end
	
	if reprintLvlUps then
		unitData.setLevelUpStrings()
		printStringArray(unitData.levelUp_strings, unitData.levelUp_stringsSize)
	end
	
	feGUI.drawRects()

	emu.frameadvance()
end