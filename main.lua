-- package dependencies
-- main
--   ctrl
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
require("feControl")



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

local function printHelp()
	print("")

	for _, hotkey in ipairs(ctrl.hotkeys) do
		if usingPrimaryFunctions then
			print(hotkey.message1)
		else
			print(hotkey.message2)
		end
	end
end

printHelp()



local currentRNG = rns.rng1
local rnStepSize = 1 -- distance to move rng position or how many burns to add to an event

local moneyStepSize = 10000

local currTurn = 0
local currPhase = "player"

local RAMoffset = 0

-- disable if using a keyboard hotkey which may combine with game controls or modify displays
local function canModifyWindow(window)
	return feGUI.rects.sel_i == window and selected(feGUI.rects).opacity > 0 and not ctrl.keyboard.anythingHeld
end

local REPEAT_RATE = 10

while true do
	if currTurn ~= memory.readbyte(addr.TURN) or currPhase ~= addr.getPhase() then
		currTurn = memory.readbyte(addr.TURN)
		currPhase = addr.getPhase()

		print()
		print("Turn " .. currTurn .. " " .. currPhase .. " phase")
	end
	
	if currentRNG:update() and currentRNG.isPrimary then
		rnEvent.update_rnEvents(1)
	end

	ctrl.keyboard:update(input.get())
	
	for i = 1, 10 do
		if ctrl.keyboard:pressed("F" .. i) then
			if ctrl.keyboard:held("shift") then
				autolog.saveNode(i)
			else
				autolog.loadNode(i)
			end
		end
	end
	
	autolog.passiveUpdate()	
	
	-- Returns a table of all buttons. Does not read movie input. 
	-- Key values are 1 for pressed, nil for not pressed. Keys for joypad table: 
	-- (A, B, select, start, right, left, up, down, R, L). Keys are case-sensitive. 
	-- When passed 0, the default joypad is read
	ctrl.gamepad:update(joypad.get(0))
	
	-- alter burns, select, delete/undo, swap, toggle swapping
	if canModifyWindow(feGUI.RN_EVENT_I) then
		-- change burns
		if ctrl.gamepad:held("left", REPEAT_RATE) then
			rnEvent.change("burns", -rnStepSize)
		end
		if ctrl.gamepad:held("right", REPEAT_RATE) then
			rnEvent.change("burns", rnStepSize)
		end
		
		-- change selection
		if ctrl.gamepad:held("up", REPEAT_RATE) then
			changeSelection(rnEvent.events, -1)
		end
		if ctrl.gamepad:held("down", REPEAT_RATE) then
			changeSelection(rnEvent.events, 1)
		end
		
		-- delete/undo
		if ctrl.gamepad:pressed("L") then
			rnEvent.deleteLastEvent()
		end
		if ctrl.gamepad:pressed("R") then
			rnEvent.undoDelete()
		end
		
		-- swap with next
		if ctrl.gamepad:pressed("select") then
			rnEvent.swap() -- updates self
		end
		
		-- create/remove dependency
		if ctrl.gamepad:pressed("start") then
			rnEvent.toggleDependency()
		end
	end
	
	-- move within autolog display
	if canModifyWindow(feGUI.AUTOLOG_I) then
		-- change depth
		if ctrl.gamepad:held("up", REPEAT_RATE) then
			if autolog.GUInode.parent then
				autolog.GUInode = autolog.GUInode.parent
			end
		end
		if ctrl.gamepad:held("down", REPEAT_RATE) then
			if autolog.GUInode.children then
				autolog.GUInode = selected(autolog.GUInode.children)
			end
		end
		if ctrl.gamepad:held("L") then
			if autolog.GUInode.parent then
				autolog.GUInode = autolog.GUInode.parent
			end
		end
		if ctrl.gamepad:held("R") then
			if autolog.GUInode.children then
				autolog.GUInode = selected(autolog.GUInode.children)
			end
		end
		
		-- change branch
		if ctrl.gamepad:pressed("left") then
			if autolog.GUInode.children then
				changeSelection(autolog.GUInode.children, -1)
			end
		end
		if ctrl.gamepad:pressed("right") then
			if autolog.GUInode.children then
				changeSelection(autolog.GUInode.children, 1)
			end
		end
		
		if ctrl.gamepad:pressed("select") then
			autolog.attemptSync(autolog.GUInode)
		end
	end
	
	
	if ctrl.keyboard:pressed("H") then -- print help, switch functions
		usingPrimaryFunctions = not usingPrimaryFunctions
		printHelp()
	end
	
	if usingPrimaryFunctions then
		if ctrl.keyboard:pressed("Y") then -- add event
			rnEvent.addEvent()
			rnEvent.update_rnEvents()
			
			printStringArray(selected(rnEvent.events).combatants:toStrings())
		end
		
		if ctrl.keyboard:pressed("U") then rnEvent.toggle("hasCombat") end
		
		if ctrl.keyboard:pressed("I") then rnEvent.toggle("lvlUp") end	
		
		if ctrl.keyboard:pressed("O") then 
			if #rnEvent.events > 0 then
				selected(rnEvent.events).combatants:toggleBonusExp() 
			end
		end
		
		if ctrl.keyboard:pressed("J") then print("selecting display: " .. selected(feGUI.rects).name) end
		if ctrl.keyboard:held("J") then -- hold down, then press left/right
			if ctrl.gamepad:pressed("left", 10) then
				changeSelection(feGUI.rects, -1)
				print("selecting display: " .. selected(feGUI.rects).name)
			end
			if ctrl.gamepad:pressed("right", 10) then
				changeSelection(feGUI.rects, 1)
				print("selecting display: " .. selected(feGUI.rects).name)
			end
		end
		if ctrl.keyboard:released("J") then
			if selected(feGUI.rects).opacity == 0 then
				selected(feGUI.rects).opacity = 0.75
			else
				selected(feGUI.rects).opacity = 0
			end
		end
		
		if ctrl.keyboard:pressed("K") then rnEvent.suggestPermutation() end
		
		if ctrl.keyboard:pressed("L") then autolog.writeLogs() end
				
		if ctrl.keyboard:pressed("B") then
			if #rnEvent.events > 0 then
				selected(rnEvent.events).unit:toggleAfas()
			end
		end
		
		if ctrl.keyboard:pressed("N") then
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
		
		if ctrl.keyboard:pressed("M") then print("moving rn position...") end
		if ctrl.keyboard:held("M") then -- move rn position
			if ctrl.gamepad:held("left", REPEAT_RATE) then
				currentRNG:moveRNpos(-rnStepSize)
				rnEvent.update_rnEvents(1)
			end
			if ctrl.gamepad:held("right", REPEAT_RATE) then
				currentRNG:moveRNpos(rnStepSize)
				rnEvent.update_rnEvents(1)
			end
			if ctrl.gamepad:held("up", REPEAT_RATE) then
				rnStepSize = rnStepSize * 10
				print("rnStepSize now " .. rnStepSize)
			end
			if ctrl.gamepad:held("down", REPEAT_RATE) then
				rnStepSize = rnStepSize / 10
				if rnStepSize < 1 then
					rnStepSize = 1
				end
				print("rnStepSize now " .. rnStepSize)
			end
		end
	else -- 2ndary functions
		if ctrl.keyboard:pressed("Y") then rnEvent.printDiagnostic() end
		
		if ctrl.keyboard:pressed("U") then print("change hp weights: ^v player, <> enemy") end
		if ctrl.keyboard:held("U") then -- hold down, then press <^v> change weights
			if ctrl.gamepad:pressed("up", REPEAT_RATE) then
				rnEvent.change("pHPweight", 25)
			end
			if ctrl.gamepad:pressed("down", REPEAT_RATE) then
				rnEvent.change("pHPweight", -25)
			end
			if ctrl.gamepad:pressed("left", REPEAT_RATE) then
				rnEvent.change("eHPweight", -25)
			end
			if ctrl.gamepad:pressed("right", REPEAT_RATE) then
				rnEvent.change("eHPweight", 25)
			end
		end	
		
		if ctrl.keyboard:pressed("I") then rnEvent.toggle("dig") end
	
		if ctrl.keyboard:pressed("O") then print("changing fog...") end
		if ctrl.keyboard:held("O") then
			local fog = memory.readbyte(addr.FOG)
			
			if ctrl.gamepad:pressed("left", REPEAT_RATE) then
				fog = (fog - 1) % 256
				memory.writebyte(addr.FOG, fog)
				print("fog set to " .. fog)
			end
			
			if ctrl.gamepad:pressed("right", REPEAT_RATE) then
				fog = (fog + 1) % 256
				memory.writebyte(addr.FOG, fog)
				print("fog set to " .. fog)
			end
		end
	
		if ctrl.keyboard:pressed("J") then
			selected(feGUI.rects).shiftMode = true
			print("display shift mode: ON")
			print("change display opacity with L and R")
			print("change display position with D-pad")
			
			if selected(feGUI.rects).opacity <= 0.1 then
				selected(feGUI.rects).opacity = 0.5
			end
		end
		if ctrl.keyboard:held("J") then -- move rects or change opacity
			if ctrl.gamepad:held("left")  then selected(feGUI.rects):adjust(-0.02, 0, 0) end
			if ctrl.gamepad:held("right") then selected(feGUI.rects):adjust( 0.02, 0, 0) end
			if ctrl.gamepad:held("up")    then selected(feGUI.rects):adjust(0, -0.02, 0) end
			if ctrl.gamepad:held("down")  then selected(feGUI.rects):adjust(0,  0.02, 0) end
			if ctrl.gamepad:held("L")     then selected(feGUI.rects):adjust(0, 0, -0.04) end
			if ctrl.gamepad:held("R")     then selected(feGUI.rects):adjust(0, 0,  0.04) end
		end
		if ctrl.keyboard:released("J") then
			selected(feGUI.rects).shiftMode = false
			print("display shift mode: OFF")
		end
		
		if ctrl.keyboard:pressed("K") then rnEvent.searchFutureOutcomes() end
		
		if ctrl.keyboard:pressed("L") then end
			
		if ctrl.keyboard:pressed("B") then
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
			
			stat = RAMoffset - addr.MAX_HP_OFFSET -- both max and current hp
			if stat == 0 then
				print("Max HP")
			elseif stat == 1 then
				print("Current HP")
			elseif stat == 2 then
				print("Strength")
			elseif stat == 3 then
				print("Skill")
			elseif stat == 4 then
				print("Speed")
			elseif stat == 5 then
				print("Defense")
			elseif stat == 6 then
				print("Resistance")
			elseif stat == 7 then
				print("Luck")
			end
			
			if RAMoffset == addr.CARRYING_SLOT_OFFSET then
				print(unitData.hexCodeToName(addr.wordFromSlot(memory.readbyte(address), addr.NAME_CODE_OFFSET)))
			end
			
			itemSlot = (RAMoffset - addr.ITEMS_OFFSET) / 2
			for i = 0, 4 do
				if itemSlot == i then
					print(combat.ITEM_NAMES[memory.readbyte(address)])
				end
			end
			
			rank = RAMoffset - addr.RANKS_OFFSET
			for i = 0, 7 do
				if rank == i then
					print(unitData.RANK_NAMES[i + 1])
				end
			end
		end
		
		if ctrl.keyboard:pressed("N") then
			printRAMhelp()
			print("<> to change value, ^v change offset")
		end
		if ctrl.keyboard:held("N") then
			-- change offset
			if ctrl.gamepad:pressed("up", REPEAT_RATE) then
				RAMoffset = RAMoffset - 1
				if RAMoffset < 0 then
					RAMoffset = 0
					print()
					print("can't move offset outside slot")
				else
					printRAMhelp()
				end
			end
			if ctrl.gamepad:pressed("down", REPEAT_RATE) then
				RAMoffset = RAMoffset + 1
				if RAMoffset > 71 then
					RAMoffset = 71
					print()
					print("can't move offset outside slot")
				else
					printRAMhelp()
				end
			end
			
			-- modify value
			if ctrl.gamepad:pressed("left", REPEAT_RATE) then
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
			if ctrl.gamepad:pressed("right", REPEAT_RATE) then
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
		
		if ctrl.keyboard:pressed("M") then print("changing money by " .. moneyStepSize .. "...") end
		if ctrl.keyboard:held("M") then
			local currMoney = addr.getMoney()
		
			if ctrl.gamepad:pressed("left", REPEAT_RATE) then
				addr.setMoney(math.max(currMoney - moneyStepSize, 0))
				print("money now " .. math.max(currMoney - moneyStepSize, 0))
			end
			if ctrl.gamepad:pressed("right", REPEAT_RATE) then
				addr.setMoney(math.min(currMoney + moneyStepSize, 0x7FFFFFFF))
				print("money now " .. math.min(currMoney + moneyStepSize, 0x7FFFFFFF))
			end
			if ctrl.gamepad:pressed("up", REPEAT_RATE) then
				moneyStepSize = moneyStepSize * 10
				print("moneyStepSize now " .. moneyStepSize)
			end
			if ctrl.gamepad:pressed("down", REPEAT_RATE) then
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