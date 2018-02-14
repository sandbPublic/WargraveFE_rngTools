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

local inputLastLoop = {} -- to determine presses, not helds
local joypadLastLoop = {} -- to determine presses, not helds
local fogOfWar = true
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
		print("y: ")
	
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

local burnNotifyFramesLeft = 0
local burnNotifyStr = ""
while true do
	local reprintRNs = false
	local reprintStats = false
	local reprintLvlUps = false
	
	if rns.rng1:update() then
		rnbe.updateRNBEs(1)
	end

	--rns.rng2:update()
	
	local inputThisLoop = input.get()	
	local joypadThisLoop = joypad.get(0)
	
	if feGUI.rectShiftMode then -- move rects or change opacity
		if joypadThisLoop.left 	then feGUI.selRect():shift(-0.02, 0, 0) end
		if joypadThisLoop.right then feGUI.selRect():shift( 0.02, 0, 0) end
		if joypadThisLoop.up 	then feGUI.selRect():shift(0, -0.02, 0) end
		if joypadThisLoop.down 	then feGUI.selRect():shift(0,  0.02, 0) end
		if joypadThisLoop.L 	then feGUI.selRect():shift(0, 0, -0.04) end
		if joypadThisLoop.R 	then feGUI.selRect():shift(0, 0,  0.04) end
	end
	
	if feGUI.canAlterRNBE() then -- alter burns, selected, swap, toggle swapping
		-- change burns
		if joypadThisLoop.left and not joypadLastLoop.left then
			rnbe.decBurns()
		end		
		if joypadThisLoop.right and not joypadLastLoop.right then
			rnbe.incBurns()
		end
		
		if joypadThisLoop.L and not joypadLastLoop.L then
			rnbe.changeEnemyID(-1)
		end		
		if joypadThisLoop.R and not joypadLastLoop.R then
			rnbe.changeEnemyID(1)
		end
		
		-- change selection
		if joypadThisLoop.up and not joypadLastLoop.up then
			rnbe.decSel()
		end
		if joypadThisLoop.down and not joypadLastLoop.down then
			rnbe.incSel()
		end
		
		-- swap with next
		if joypadThisLoop.select and not joypadLastLoop.select then			
			rnbe.swap() -- updates self
		end
		
		if joypadThisLoop.start and not joypadLastLoop.start then			
			rnbe.toggleDependency()
		end	
	end
	
	if inputThisLoop.H and not inputLastLoop.H then -- print help
		primaryFunctions = not primaryFunctions
		printHelp()
	end	
	
	-- fog of war off? TODO
	-- memory.writebyte(0x202BCFD, viewRange=3), FE8?
	if not fogOfWar then
		memory.writebyte(0x202BC05, 0)
	end	
	
	if primaryFunctions then
		if inputThisLoop.G and not inputLastLoop.G then 
			rnbe.removeLastObj()
		end	
		
		if inputThisLoop.J and not inputLastLoop.J then 
			rnbe.addObj()
		end
		
		if inputThisLoop.L and not inputLastLoop.L then 
			rnbe.toggleCombat()
		end
		
		if inputThisLoop.U and not inputLastLoop.U then 
			combat.currBattleParams:cycleEnemyClass()
		end	
		
		if inputThisLoop.Y and not inputLastLoop.Y then
			combat.currBattleParams:toggleBonusExp()
		end
	
		if inputThisLoop.N and not inputLastLoop.N then -- advance to next deployed
			unitData.sel_Unit_i = unitData.nextDeployed()		
			print(string.format("Selected: %-10.10s   (next: %s)", unitData.names(), 
				unitData.names(unitData.nextDeployed())))
		end	
		
		if inputThisLoop.I and not inputLastLoop.I then -- advance displayMode
			feGUI.advanceDisplay()
		end	
		
		if inputThisLoop.E and not inputLastLoop.E then -- quick toggle visibility
			if feGUI.selRect().opacity == 0 then
				feGUI.selRect().opacity = 0.75
			else
				feGUI.selRect().opacity = 0
			end
		end	

		if inputThisLoop.O and not inputLastLoop.O then			
			rnbe.suggestedPermutation()
		end	
		
		if inputThisLoop.B and not inputLastLoop.B then -- toggle enemy promoted
			combat.currBattleParams:togglePromo()
			printStringArray(combat.currBattleParams:toStrings(), 3)
		end	
		
		if inputThisLoop.M and not inputLastLoop.M  then
			rnbe.togglePhase()
		end
		
		if inputThisLoop.K and not inputLastLoop.K then -- save battle params & stats
			combat.currBattleParams:set()
			printStringArray(combat.currBattleParams:toStrings(), 3)
			
			reprintStats = true
			unitData.saveStats()
		end	
	else
		if inputThisLoop.G and not inputLastLoop.G then 
			rnbe.undoDelete()
		end	
		
		if inputThisLoop.J and not inputLastLoop.J then 
			combat.currBattleParams:cycleWeapon(combat.enum_PLAYER)
		end	
		
		if inputThisLoop.U and not inputLastLoop.U then 
			rnbe.toggleDig()
		end	
		
		if inputThisLoop.E and not inputLastLoop.E then 
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
		
		if inputThisLoop.O and not inputLastLoop.O then			
			rnbe.searchFutureOutcomes()
		end	
		
		if inputThisLoop.L and not inputLastLoop.L then
			rnbe.toggleLevel()
		end
		
		if inputThisLoop.M and not inputLastLoop.M  then
			cycleVersion()
		end
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
	
	joypadLastLoop = joypadThisLoop
	inputLastLoop = inputThisLoop	
end