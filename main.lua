-- 07000003 cursor pulse
-- 0202.. 55E0, 55E2, BCC4, BCC8 cursor x pos
-- 0202.. 55E1, 55E3, BCC6, BCCA cursor y pos
-- .. 55C6 = 0

-- package dependencies
-- main
--     gui
--         event
--             unit
--                 class
--             combat
--                 class
--                 rn

require("feGUI")

local function printStringArray(array)
	print("")
	for _, string_ in ipairs(array) do
		print(string_)
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

local primaryFunctions = true

-- TYUIOP
--   HJKL
--  BNM

local hotkeys = {}
local function loadHotkeys(filename)
	local f = assert(io.open(filename, "r"))
	
	local c = f:read("*line")
	
	while c do
		hotkey = {}
		hotkey.key = c
		hotkey.message1 = c .. ": " .. f:read("*line")
		hotkey.message2 = string.lower(c) .. ": " ..f:read("*line")
		
		table.insert(hotkeys, hotkey)
		
		c = f:read("*line")
	end
	
	print("loaded hotkeys " .. filename)
end
loadHotkeys("QwertyHotkeys.txt")

local function printHelp()
	print("")

	for _, hotkey in ipairs(hotkeys) do
		if primaryFunctions then
			print(hotkey.message1)
		else
			print(hotkey.message2)
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

local currentRNG = rns.rng1
local rnJumpAmount = 1 -- distance to move rng position or how many burns to add to an event
local FOG_ADDR = {}

FOG_ADDR[6] = 0x202AA55
FOG_ADDR[7] = 0x202BC05
FOG_ADDR[8] = 0x202BCFD

while true do
	if currentRNG:update() and currentRNG.isPrimary then
		rnEvent.update_rnEvents(1)
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
			rnEvent.changeBurns(-rnJumpAmount)
		end
		if pressed("right", gameCtrl) then
			rnEvent.changeBurns(rnJumpAmount)
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
			
			printStringArray(rnEvent.get().batParams:toStrings())
		end
		
		if pressed(3) then rnEvent.toggleCombat() end
		
		if pressed(4) then
			rnEvent.toggleBatParam(combat.combatObj.togglePromo)
			
			printStringArray(rnEvent.get().batParams:toStrings())
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
			printStringArray(combat.currBattleParams:toStrings())
			
			unitData.saveStats()
			rnEvent.updateStats()
			
			printStringArray(unitData.statData_strings())
		end
		
		if keybCtrl.thisFrame[hotkeys[13].key] then -- hold down, then press left/right
			if pressed("L", gameCtrl) then
				currentRNG:moveRNpos(-rnJumpAmount)
				rnEvent.update_rnEvents(1)
			end
			if pressed("R", gameCtrl) then
				currentRNG:moveRNpos(rnJumpAmount)
				rnEvent.update_rnEvents(1)
			end
		end
	else
		if pressed(1) then rnEvent.undoDelete() end
		
		if pressed(2) then
			if gameCtrl.thisFrame.B then -- enemy's weapon
				rnEvent.toggleBatParam(combat.combatObj.cycleWeapon, false)
			else
				rnEvent.toggleBatParam(combat.combatObj.cycleWeapon, true)
			end
		end
		
		if pressed(3) then rnEvent.toggleLevel() end
		
		if pressed(4) then rnEvent.toggleDig() end
		
		if keybCtrl.thisFrame[hotkeys[5].key] then -- hold down, then press L/R
			local currFogRange = memory.readbyte(FOG_ADDR[version])
			if pressed("L", gameCtrl) then
				currFogRange = currFogRange - 1
				memory.writebyte(FOG_ADDR[version], currFogRange)
				print("fog set to " .. tostring(currFogRange))
			end
			if pressed("R", gameCtrl) then
				currFogRange = currFogRange + 1
				memory.writebyte(FOG_ADDR[version], currFogRange)
				print("fog set to " .. tostring(currFogRange))
			end
		end	
		
		if keybCtrl.thisFrame[hotkeys[7].key] then -- hold down, then press L/R
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
		
		if pressed(9) then 
			if rnJumpAmount == 1 then
				rnJumpAmount = 12 -- 12 because enemy reinforcements often consume rns in multiples of 12
			else
				rnJumpAmount = 1
			end
			print("rnJumpAmount now " .. rnJumpAmount)
		end
		
		if pressed(10) then rnEvent.searchFutureOutcomes() end
		
		if pressed(11) then
			if currentRNG.isPrimary then
				currentRNG = rns.rng2
				print("Switching to 2ndary rng")
			else
				currentRNG = rns.rng1
				print("Switching to primary rng")
			end
		end
		
		if pressed(12) then rnEvent.diagnostic() end
		
		if pressed(13) then unitData.setAfas() end
	end
	
	feGUI.drawRects()

	emu.frameadvance()
end