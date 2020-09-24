-- package dependencies
-- main
-- test
--   autolog
--     gui
--       event
--         combat
--           unit
--             rn
--               class
--                 misc
--                   address

require("feAutolog")

local function printStringArray(array)
	print("")
	for _, string_ in ipairs(array) do
		print(string_)
	end
end

local usingPrimaryFunctions = true

-- TYUIOP
--  HJKL
--  BNM

local windowWidthString = ""
for i = 1, WINDOW_WIDTH do
	windowWidthString = windowWidthString .. (i % 10)
end
print(windowWidthString)
print("Game version " .. GAME_VERSION)

local hotkeys = {}
local f = assert(io.open("QwertyHotkeys.txt", "r"))
local c = f:read("*line")
while c do
	hotkey = {}
	hotkey.key = c
	hotkey.message1 = c .. ": " .. f:read("*line")
	hotkey.message2 = c:lower() .. ": " ..f:read("*line")
	
	table.insert(hotkeys, hotkey)
	c = f:read("*line")
end
f:close()

local function printHelp()
	print("")

	for _, hotkey in ipairs(hotkeys) do
		if usingPrimaryFunctions then
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
	
	ctrl.anythingHeld = false
	for _, hotkey in ipairs(hotkeys) do
		if ctrl.thisFrame[hotkey.key] then
			ctrl.anythingHeld = true
			return
		end
	end
end

local function pressed(key, ctrl)
	ctrl = ctrl or keybCtrl
	
	if type(key) == "number" then
		key = hotkeys[key].key
	end
	
	return ctrl.thisFrame[key] and not ctrl.lastFrame[key]
end

local function held(key, ctrl)
	ctrl = ctrl or keybCtrl
	
	if type(key) == "number" then
		key = hotkeys[key].key
	end
	
	return ctrl.thisFrame[key]
end

local currentRNG = rns.rng1
local rnStepSize = 1 -- distance to move rng position or how many burns to add to an event

local savedFog = 0
local currTurn = 0
local currPhase = 0

while true do
	if currTurn ~= memory.readbyte(addr.TURN) or currPhase ~= memory.readbyte(addr.PHASE) then
		currTurn = memory.readbyte(addr.TURN)
		currPhase = memory.readbyte(addr.PHASE)
		print()
		print(turnString(currTurn, currPhase))
		print()
	end
	
	if currentRNG:update() and currentRNG.isPrimary then
		rnEvent.update_rnEvents(1)
		
		autolog.addLog()
	end

	updateCtrl(keybCtrl, input.get())
	updateCtrl(gameCtrl, joypad.get(0))
	
	if feGUI.rectShiftMode then -- move rects or change opacity
		if gameCtrl.thisFrame.left 	then selected(feGUI.rects):adjust(-0.02, 0, 0) end
		if gameCtrl.thisFrame.right then selected(feGUI.rects):adjust( 0.02, 0, 0) end
		if gameCtrl.thisFrame.up 	then selected(feGUI.rects):adjust(0, -0.02, 0) end
		if gameCtrl.thisFrame.down 	then selected(feGUI.rects):adjust(0,  0.02, 0) end
		if gameCtrl.thisFrame.L 	then selected(feGUI.rects):adjust(0, 0, -0.04) end
		if gameCtrl.thisFrame.R 	then selected(feGUI.rects):adjust(0, 0,  0.04) end
	end
	
	-- alter burns, selected, swap, toggle swapping
	-- disable if using a keyboard hotkey which may combine with game controls 
	if feGUI.canAlter_rnEvent() and not keybCtrl.anythingHeld then
		-- change burns
		if pressed("left", gameCtrl) then
			rnEvent.change("burns", -rnStepSize)
		end
		if pressed("right", gameCtrl) then
			rnEvent.change("burns", rnStepSize)
		end
		
		if pressed("L", gameCtrl) then
			rnEvent.change("enemyID", -1)
		end
		if pressed("R", gameCtrl) then
			rnEvent.change("enemyID", 1)
		end
		
		-- change selection
		if pressed("up", gameCtrl) then
			changeSelection(rnEvent.events, -1)
		end
		if pressed("down", gameCtrl) then
			changeSelection(rnEvent.events, 1)
		end
		
		-- swap with next
		if pressed("select", gameCtrl) then
			rnEvent.swap() -- updates self
		end
		
		-- create/remove dependency
		if pressed("start", gameCtrl) then
			rnEvent.toggleDependency()
		end
	end
	
	if pressed(7) then -- print help, switch functions
		usingPrimaryFunctions = not usingPrimaryFunctions
		printHelp()
	end
	
	if usingPrimaryFunctions then
		if pressed(1) then rnEvent.deleteLastEvent() end
		
		if pressed(2) then
			selected(unitData.deployedUnits):setStats()
			rnEvent.addEvent()
			selected(rnEvent.events).batParams:set()
			rnEvent.update_rnEvents()
			
			printStringArray(selected(rnEvent.events).batParams:toStrings())
		end
		
		if pressed(3) then rnEvent.toggle("hasCombat") end
		
		if pressed(4) then
			rnEvent.toggleBatParam(combat.combatObj.togglePromo)
			
			printStringArray(selected(rnEvent.events).batParams:toStrings())
		end	
		
		if pressed(5) then rnEvent.toggleBatParam(combat.combatObj.toggleBonusExp) end

		if pressed(6) then rnEvent.suggestedPermutation() end
		
		if pressed(8) then
			print(selected(unitData.deployedUnits).name)
		end
		
		if held(8) then -- hold down, press left/right
			if pressed("left", gameCtrl) then
				changeSelection(unitData.deployedUnits, -1)
				print(selected(unitData.deployedUnits).name)
			end
			if pressed("right", gameCtrl) then
				changeSelection(unitData.deployedUnits, 1)
				print(selected(unitData.deployedUnits).name)
			end
		end
		
		if pressed(9) then -- quick toggle visibility
			if selected(feGUI.rects).opacity == 0 then
				selected(feGUI.rects).opacity = 0.75
			else
				selected(feGUI.rects).opacity = 0
			end
		end
		
		if held(10) then -- hold down, then press left/right
			if pressed("left", gameCtrl) then
				changeSelection(feGUI.rects, -1)
				print("selecting display: " .. selected(feGUI.rects).name)
			end
			if pressed("right", gameCtrl) then
				changeSelection(feGUI.rects, 1)
				print("selecting display: " .. selected(feGUI.rects).name)
			end
		end
				
		if pressed(11) then selected(unitData.deployedUnits):toggleAfas() end
		
		if pressed(12) then -- save battle params & stats
			combat.currBattleParams:set()
			printStringArray(combat.currBattleParams:toStrings())
			
			selected(unitData.deployedUnits):setStats()
			rnEvent.updateStats()
			unitData.printRanks()
			
			printStringArray(selected(unitData.deployedUnits):statData_strings())
		end
		
		if held(13) then -- hold down, then press direction
			if pressed("left", gameCtrl) then
				currentRNG:moveRNpos(-rnStepSize)
				rnEvent.update_rnEvents(1)
			end
			if pressed("right", gameCtrl) then
				currentRNG:moveRNpos(rnStepSize)
				rnEvent.update_rnEvents(1)
			end
			if pressed("up", gameCtrl) then
				rnStepSize = rnStepSize * 10
				print("rnStepSize now " .. rnStepSize)
			end
			if pressed("down", gameCtrl) then
				rnStepSize = rnStepSize / 10
				if rnStepSize < 1 then
					rnStepSize = 1
				end
				print("rnStepSize now " .. rnStepSize)
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
		
		if pressed(3) then rnEvent.toggle("lvlUp") end
		
		if pressed(4) then rnEvent.toggle("dig") end
		
		if pressed(5) then -- toggle fog
			if savedFog > 0 then
				memory.writebyte(addr.FOG, savedFog)
				print("fog set to " .. savedFog)
				savedFog = 0
			else
				savedFog = memory.readbyte(addr.FOG)
				memory.writebyte(addr.FOG, 0)
				print("fog set to 0")
			end
		end
	
		if pressed(6) then rnEvent.searchFutureOutcomes() end
	
		if held(8) then -- hold down, then press <^v>
			if pressed("up", gameCtrl) then
				rnEvent.change("pHPweight", 25)
			end
			if pressed("down", gameCtrl) then
				rnEvent.change("pHPweight", -25)
			end
			if pressed("left", gameCtrl) then
				rnEvent.change("eHPweight", -25)
			end
			if pressed("right", gameCtrl) then
				rnEvent.change("eHPweight", 25)
			end
		end
		
		if pressed(9) then 
			feGUI.rectShiftMode = not feGUI.rectShiftMode
			
			if feGUI.rectShiftMode then
				print("display shift mode: ON")
				print("change display opacity with L and R")
				print("change display position with D-pad")
				
				if selected(feGUI.rects).opacity == 0 then
					selected(feGUI.rects).opacity = 0.5
				end
			else
				print("display shift mode: OFF")
			end
		end	
		
		if pressed(10) then 
			-- print(combat.paramInRAM(true)) 
		end
		
		if held(10) then
			-- change combatant stat to print
		end
			
		if pressed(11) then
			if currentRNG.isPrimary then
				currentRNG = rns.rng2
			else
				currentRNG = rns.rng1
			end
			print(string.format("Switching to %s rng", currentRNG:name()))
		end
		
		if pressed(12) then autolog.writeLogs() end
		
		if pressed(13) then rnEvent.toggleBatParam(combat.combatObj.cycleEnemyClass) end
	end
	
	feGUI.drawRects()

	emu.frameadvance()
end