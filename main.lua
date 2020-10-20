-- package dependencies
-- main
-- test
--   gui
--     autolog
--       event
--         combat
--           unit
--             rn
--               class
--                 misc
--                   address

require("feGUI")



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

local function released(key, ctrl)
	ctrl = ctrl or keybCtrl
	
	if type(key) == "number" then
		key = hotkeys[key].key
	end
	
	return not ctrl.thisFrame[key] and ctrl.lastFrame[key]
end

local currentRNG = rns.rng1
local rnStepSize = 1 -- distance to move rng position or how many burns to add to an event

local moneyStepSize = 10000

local currTurn = 0
local currPhase = "player"

local RAMoffset = 0

	-- disable if using a keyboard hotkey which may combine with game controls or modify displays
local function canModifyWindow(window)
	return feGUI.rects.sel_i == window and selected(feGUI.rects).opacity > 0 and not keybCtrl.anythingHeld
end

while true do
	if currTurn ~= memory.readbyte(addr.TURN) or currPhase ~= getPhase() then
		currTurn = memory.readbyte(addr.TURN)
		currPhase = getPhase()

		print()
		print("Turn " .. currTurn .. " " .. currPhase .. " phase")
	end
	
	if currentRNG:update() and currentRNG.isPrimary then
		rnEvent.update_rnEvents(1)
	end

	autolog.passiveUpdate()
	
	updateCtrl(keybCtrl, input.get())
	updateCtrl(gameCtrl, joypad.get(0))
	
	-- alter burns, select, delete/undo, swap, toggle swapping

	if canModifyWindow(feGUI.RN_EVENT_I) then
		-- change burns
		if pressed("left", gameCtrl) then
			rnEvent.change("burns", -rnStepSize)
		end
		if pressed("right", gameCtrl) then
			rnEvent.change("burns", rnStepSize)
		end
		
		-- change selection
		if pressed("up", gameCtrl) then
			changeSelection(rnEvent.events, -1)
		end
		if pressed("down", gameCtrl) then
			changeSelection(rnEvent.events, 1)
		end
		
		-- delete/undo
		if pressed("L", gameCtrl) then
			rnEvent.deleteLastEvent()
		end
		if pressed("R", gameCtrl) then
			rnEvent.undoDelete()
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
	
	-- move within autolog display
	if canModifyWindow(feGUI.AUTOLOG_I) then
		-- change selection
		if pressed("up", gameCtrl) then
			if autolog.GUInode.parent then
				autolog.GUInode = autolog.GUInode.parent
			end
		end
		if pressed("down", gameCtrl) then
			if autolog.GUInode.children then
				autolog.GUInode = selected(autolog.GUInode.children)
			end
		end
		if pressed("left", gameCtrl) then
			if autolog.GUInode.children then
				changeSelection(autolog.GUInode.children, -1)
			end
		end
		if pressed("right", gameCtrl) then
			if autolog.GUInode.children then
				changeSelection(autolog.GUInode.children, 1)
			end
		end
	end
	
	
	if pressed("H") then -- print help, switch functions
		usingPrimaryFunctions = not usingPrimaryFunctions
		printHelp()
	end
	
	if usingPrimaryFunctions then
		if pressed("Y") then -- add event
			rnEvent.addEvent()
			rnEvent.update_rnEvents()
			
			printStringArray(selected(rnEvent.events).combatants:toStrings())
		end
		
		if pressed("U") then rnEvent.toggle("hasCombat") end
		
		if pressed("I") then rnEvent.toggle("lvlUp") end	
		
		if pressed("O") then 
			if #rnEvent.events > 0 then
				selected(rnEvent.events).combatants:toggleBonusExp() 
			end
		end
		
		if pressed("J") then print("selecting display: " .. selected(feGUI.rects).name) end
		if held("J") then -- hold down, then press left/right
			if pressed("left", gameCtrl) then
				changeSelection(feGUI.rects, -1)
				print("selecting display: " .. selected(feGUI.rects).name)
			end
			if pressed("right", gameCtrl) then
				changeSelection(feGUI.rects, 1)
				print("selecting display: " .. selected(feGUI.rects).name)
			end
		end
		if released("J") then
			if selected(feGUI.rects).opacity == 0 then
				selected(feGUI.rects).opacity = 0.75
			else
				selected(feGUI.rects).opacity = 0
			end
		end
		
		if pressed("K") then rnEvent.suggestPermutation() end
		
		if pressed("L") then autolog.writeLogs() end
				
		if pressed("B") then
			if #rnEvent.events > 0 then
				selected(rnEvent.events).unit:toggleAfas()
			end
		end
		
		if pressed("N") then
			printStringArray(combat.combatObj:new():toStrings())
			
			printStringArray(unitData.currUnit():statData_strings())
			
			unitData.printRanks()
			unitData.printSupports()
			
			print()
			local nameCode = memory.readword(addr.ATTACKER_START + addr.NAME_CODE_OFFSET)
			print(string.format("unit %s 0x%04X", unitData.hexCodeToName(nameCode), nameCode))
			local classCode = memory.readword(addr.ATTACKER_START + addr.CLASS_CODE_OFFSET)
			local class = classes.HEX_CODES[classCode] or classes.OTHER
			print(string.format("class %d 0x%04X", class, classCode))
			print(string.format("slot %d", memory.readbyte(addr.ATTACKER_START + addr.SLOT_ID_OFFSET)))
		end
		
		if pressed("M") then print("moving rn position...") end
		if held("M") then -- move rn position
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
		if pressed("Y") then rnEvent.printDiagnostic() end
		
		if pressed("U") then print("change hp weights: ^v player, <> enemy") end
		if held("U") then -- hold down, then press <^v> change weights
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
		
		if pressed("I") then rnEvent.toggle("dig") end
	
		if pressed("O") then print("changing fog...") end
		if held("O") then
			local fog = memory.readbyte(addr.FOG)
			
			if pressed("left", gameCtrl) then
				fog = (fog - 1) % 256
				memory.writebyte(addr.FOG, fog)
				print("fog set to " .. fog)
			end
			
			if pressed("right", gameCtrl) then
				fog = (fog + 1) % 256
				memory.writebyte(addr.FOG, fog)
				print("fog set to " .. fog)
			end
		end
	
		if pressed("J") then
			selected(feGUI.rects).shiftMode = true
			print("display shift mode: ON")
			print("change display opacity with L and R")
			print("change display position with D-pad")
			
			if selected(feGUI.rects).opacity <= 0.1 then
				selected(feGUI.rects).opacity = 0.5
			end
		end
		if held("J") then -- move rects or change opacity
			if gameCtrl.thisFrame.left 	then selected(feGUI.rects):adjust(-0.02, 0, 0) end
			if gameCtrl.thisFrame.right then selected(feGUI.rects):adjust( 0.02, 0, 0) end
			if gameCtrl.thisFrame.up 	then selected(feGUI.rects):adjust(0, -0.02, 0) end
			if gameCtrl.thisFrame.down 	then selected(feGUI.rects):adjust(0,  0.02, 0) end
			if gameCtrl.thisFrame.L 	then selected(feGUI.rects):adjust(0, 0, -0.04) end
			if gameCtrl.thisFrame.R 	then selected(feGUI.rects):adjust(0, 0,  0.04) end
		end
		if released("J") then
			selected(feGUI.rects).shiftMode = false
			print("display shift mode: OFF")
		end
		
		if pressed("K") then rnEvent.searchFutureOutcomes() end
		
		if pressed("L") then
			
		end
			
		if pressed("B") then
			if currentRNG.isPrimary then
				currentRNG = rns.rng2
			else
				currentRNG = rns.rng1
			end
			print(string.format("Switching to %s rng", currentRNG:name()))
		end
		
		local function printRAMhelp()
			print()
			local nameCode = memory.readword(addr.ATTACKER_START + addr.NAME_CODE_OFFSET)
			local slotID = memory.readbyte(addr.ATTACKER_START + addr.SLOT_ID_OFFSET)
			local address = addr.addrFromSlot(slotID, RAMoffset)
			print(string.format("modifying for %s slot %2d, offset %2d (%5X) = %3d", 
				unitData.hexCodeToName(nameCode),
				slotID,
				RAMoffset,
				AND(address, 0xFFFFF),
				memory.readbyte(address)))
			for k, v in pairs(addr) do
				if v == RAMoffset then
					print(k)
				end
			end
		end
		
		if pressed("N") then
			printRAMhelp()
			print("<> to change value, ^v change offset")
		end
		if held("N") then 
			if pressed("up", gameCtrl) then
				RAMoffset = RAMoffset - 1
				if RAMoffset < 0 then
					RAMoffset = 0
					print()
					print("can't move offset outside slot")
				else
					printRAMhelp()
				end
			end
			if pressed("down", gameCtrl) then
				RAMoffset = RAMoffset + 1
				if RAMoffset > 71 then
					RAMoffset = 71
					print()
					print("can't move offset outside slot")
				else
					printRAMhelp()
				end
			end
			if pressed("left", gameCtrl) then
				local slotID = memory.readbyte(addr.ATTACKER_START + addr.SLOT_ID_OFFSET)
				local data = addr.byteFromSlot(slotID, RAMoffset)
				data = data - 1
				if data < 0 then
					print()
					print("Can't shift data below 0")
				else
					memory.writebyte(addr.addrFromSlot(slotID, RAMoffset), data)
					printRAMhelp()
				end
			end
			if pressed("right", gameCtrl) then
				local slotID = memory.readbyte(addr.ATTACKER_START + addr.SLOT_ID_OFFSET)
				local data = addr.byteFromSlot(slotID, RAMoffset)
				data = data + 1
				if data > 255 then
					print()
					print("Can't shift data above 255")
				else
					memory.writebyte(addr.addrFromSlot(slotID, RAMoffset), data)
					printRAMhelp()
				end
			end
		end
		
		if pressed("M") then print("changing money by " .. moneyStepSize .. "...") end
		if held("M") then
			local currMoney = addr.getMoney()
		
			if pressed("left", gameCtrl) then
				addr.setMoney(math.max(currMoney - moneyStepSize, 0))
				print("money now " .. math.max(currMoney - moneyStepSize, 0))
			end
			if pressed("right", gameCtrl) then
				addr.setMoney(math.min(currMoney + moneyStepSize, 0x7FFFFFFF))
				print("money now " .. math.min(currMoney + moneyStepSize, 0x7FFFFFFF))
			end
			if pressed("up", gameCtrl) then
				moneyStepSize = moneyStepSize * 10
				print("moneyStepSize now " .. moneyStepSize)
			end
			if pressed("down", gameCtrl) then
				moneyStepSize = moneyStepSize / 10
				if moneyStepSize < 1 then
					moneyStepSize = 1
				end
				print("moneyStepSize now " .. moneyStepSize)
			end
		end
	end
	
	feGUI.drawRects()

	emu.frameadvance()
end