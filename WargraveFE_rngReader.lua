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
require("feRNBE")
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
	if (num + inc > maxVal) then
		return minVal
	end
	return num + inc
end

local savedFogRange = 0
local primaryFunctions = true

-- GJLUY
-- HNEIO
-- BKM

local function printHelp()
	print("")

	if primaryFunctions then
		print("G: clear last RNBE")
		print("J: register new RNBE")
		print("L: toggle RNBE.combat")
		print("U: cycle enemy class")
		print("Y: toggle bonus exp")
	
		print("H: switch to 2ndary functions")		
		print("N: unit_i to next deployed")
		print("E: quick toggle visibility")
		print("I: next display mode")
		print("O: suggest RNBE permutation")
		
		print("B: toggle enemy promo")
		print("K: save battle params and stats")
		print("M: toggle phase")		
	else 
		print("g: undo RNBE deletion")
		print("j: cycle player weapon type")
		print("l: toggle RNBE lvlUp")
		print("u: toggle RNBE dig")
		print("y: hold, L/R change fog")
	
		print("h: switch to primary functions")		
		print("n: ")
		print("e: toggle window adjustments")
		print("i: ")
		print("o: search future outcomes of RNBE[1]")
		
		print("b: ")
		print("k: ")
		print("m: cycle version")
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

	if type(key) ~= "string" then
		print("Non-string key passed to pressed(): " .. tostring(key))
		print(debug.traceback())
	end
	
	return ctrl.thisFrame[key] and not ctrl.lastFrame[key]
end

while true do
	local reprintRNs = false
	local reprintStats = false
	local reprintLvlUps = false
	
	if rns.rng1:update() then
		rnbe.updateRNBEs(1)
	end

	--rns.rng2:update()
	
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
	
	if feGUI.canAlterRNBE() then -- alter burns, selected, swap, toggle swapping
		-- change burns
		if pressed("left", gameCtrl) then
			rnbe.decBurns()
		end		
		if pressed("right", gameCtrl) then
			rnbe.incBurns()
		end
		
		if pressed("L", gameCtrl) then
			rnbe.changeEnemyID(-1)
		end		
		if pressed("R", gameCtrl) then
			rnbe.changeEnemyID(1)
		end
		
		-- change selection
		if pressed("up", gameCtrl) then
			rnbe.decSel()
		end
		if pressed("down", gameCtrl) then
			rnbe.incSel()
		end
		
		-- swap with next
		if pressed("select", gameCtrl) then			
			rnbe.swap() -- updates self
		end
		
		if pressed("start", gameCtrl) then			
			rnbe.toggleDependency()
		end	
	end
	
	if pressed("H") then -- print help
		primaryFunctions = not primaryFunctions
		printHelp()
	end	
		
	if primaryFunctions then
		if pressed("G") then rnbe.removeLastObj() end	
		if pressed("J") then rnbe.addObj() end
		if pressed("L") then rnbe.toggleCombat() end
		if pressed("U") then combat.currBattleParams:cycleEnemyClass() end	
		if pressed("Y") then combat.currBattleParams:toggleBonusExp() end
	
		if pressed("N") then -- advance to next deployed
			unitData.sel_Unit_i = unitData.nextDeployed()		
			print(string.format("Selected: %-10.10s (next: %s)", unitData.names(), 
				unitData.names(unitData.nextDeployed())))
		end	
		
		if pressed("I") then feGUI.advanceDisplay() end	
		
		if pressed("E") then -- quick toggle visibility
			if feGUI.selRect().opacity == 0 then
				feGUI.selRect().opacity = 0.75
			else
				feGUI.selRect().opacity = 0
			end
		end	

		if pressed("O") then rnbe.suggestedPermutation() end	
		
		if pressed("B") then -- toggle enemy promoted
			combat.currBattleParams:togglePromo()
			printStringArray(combat.currBattleParams:toStrings(), 3)
		end	
		
		if pressed("M") then rnbe.togglePhase() end
		
		if pressed("K") then -- save battle params & stats
			combat.currBattleParams:set()
			printStringArray(combat.currBattleParams:toStrings(), 3)
			
			reprintStats = true
			unitData.saveStats()
		end	
	else
		if pressed("G") then rnbe.undoDelete() end	
		
		if pressed("J") then 
			combat.currBattleParams:cycleWeapon(combat.enum_PLAYER)
		end	
		
		if pressed("L") then rnbe.toggleLevel() end
		
		if pressed("U") then rnbe.toggleDig() end	
				
		if keybCtrl.thisFrame.Y then -- hold down, then press L/R
			local currFogRange = memory.readbyte(0x202BC05)
			if pressed("L", gameCtrl) then
				currFogRange = currFogRange - 1
				memory.writebyte(0x202BC05, currFogRange)
				print("fog set to " .. tostring(currFogRange))
			end		
			if pressed("R", gameCtrl) then
				currFogRange = currFogRange + 1
				memory.writebyte(0x202BC05, currFogRange)
				print("fog set to " .. tostring(currFogRange))
			end
			
			-- memory.writebyte(0x202BCFD, viewRange=3), FE8?	
		end
		
		if pressed("E") then 
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
		
		if pressed("O") then rnbe.searchFutureOutcomes() end	
				
		if pressed("M")  then cycleVersion() end
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