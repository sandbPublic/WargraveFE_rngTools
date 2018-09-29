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
	
	if pressed(6) then -- print help
		primaryFunctions = not primaryFunctions
		printHelp()
	end	
		
	if primaryFunctions then
		if pressed(1) then rnbe.removeLastObj() end	
		
		if pressed(2) then 
			rnbe.addObj()
			rnbe.get().batParams:set()
			rnbe.updateRNBEs()
		end
		
		if pressed(3) then rnbe.toggleCombat() end
		
		if pressed(4) then
			rnbe.toggleBatParam(combat.combatObj.togglePromo)
		end	
		
		if pressed(5) then
			rnbe.toggleBatParam(combat.combatObj.toggleBonusExp)
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
			rnbe.suggestedPermutation("fast")
		end
		
		if pressed(11) then
			rnbe.toggleBatParam(combat.combatObj.cycleEnemyClass)
		end
		
		if pressed(12) then -- save battle params & stats
			combat.currBattleParams:set()
			printStringArray(combat.currBattleParams:toStrings(), 3)
			
			reprintStats = true
			unitData.saveStats()
		end
		
		if pressed(13) then rnbe.togglePhase() end
	else
		if pressed(1) then rnbe.undoDelete() end		
		if pressed(2) then
			rnbe.toggleBatParam(combat.combatObj.cycleWeapon, combat.enum_PLAYER)
		end
		if pressed(3) then rnbe.toggleLevel() end		
		if pressed(4) then rnbe.toggleDig() end
				
		if keybCtrl.thisFrame[hotkeys[5].key] then -- hold down, then press L/R
			local currFogRange = memory.readbyte(0x202BCFD)
			if pressed("L", gameCtrl) then
				currFogRange = currFogRange - 1
				memory.writebyte(0x202BCFD, currFogRange)
				print("fog set to " .. tostring(currFogRange))
			end		
			if pressed("R", gameCtrl) then
				currFogRange = currFogRange + 1
				memory.writebyte(0x202BCFD, currFogRange)
				print("fog set to " .. tostring(currFogRange))
			end
			
			--0x202BC05 FE7
			--0x202BCFD FE8
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
		
		if pressed(9) then rnbe.toggleBurnAmount() end		
		if pressed(10) then rnbe.searchFutureOutcomes() end	
		
		if pressed(11) then
			if rnbe.SPrnbes().count > 0 then
				rnbe.get():printCache()
			else
				print("no rnbes")
			end
		end
		
		if pressed(12) then
			rnbe.diagnostic()
		end
		
		if pressed(13) then cycleVersion() end
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