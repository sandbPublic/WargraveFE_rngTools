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

local moneyStepSize = 10000

local currTurn = 0
local currPhase = "player"

local RAMoffset = 0

while true do
	if currTurn ~= memory.readbyte(addr.TURN) or currPhase ~= getPhase() then
		currTurn = memory.readbyte(addr.TURN)
		currPhase = getPhase()

		print()
		print("Turn " .. currTurn .. " " .. currPhase .. " phase")
	end
	
	autolog.passiveUpdate()
	
	if currentRNG:update() and currentRNG.isPrimary then
		rnEvent.update_rnEvents(1)
		
		autolog.addLog_RNconsumed()
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
		
		-- change enemyID -- todo get from RAM
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
		
		if pressed(2) then -- add event
			rnEvent.addEvent()
			rnEvent.update_rnEvents()
			
			printStringArray(selected(rnEvent.events).combatants:toStrings())
		end
		
		if pressed(3) then rnEvent.toggle("hasCombat") end
		
		if pressed(4) then rnEvent.toggle("lvlUp") end	
		
		if pressed(5) then selected(rnEvent.events).combatants:toggleBonusExp() end

		if pressed(6) then rnEvent.suggestedPermutation() end
		
		if pressed(8) then print("selecting display: " .. selected(feGUI.rects).name) end
		if held(8) then -- hold down, then press left/right
			if pressed("left", gameCtrl) then
				changeSelection(feGUI.rects, -1)
				print("selecting display: " .. selected(feGUI.rects).name)
			end
			if pressed("right", gameCtrl) then
				changeSelection(feGUI.rects, 1)
				print("selecting display: " .. selected(feGUI.rects).name)
			end
		end
		
		if pressed(9) then -- quick toggle visibility
			if selected(feGUI.rects).opacity == 0 then
				selected(feGUI.rects).opacity = 0.75
			else
				selected(feGUI.rects).opacity = 0
			end
		end
		
		if pressed(10) then autolog.writeLogs() end
				
		if pressed(11) then unitData.currUnit():toggleAfas() end
		
		if pressed(12) then
			printStringArray(combat.combatObj:new():toStrings())
			
			printStringArray(unitData.currUnit():statData_strings())
			rnEvent.updateStats()
			
			unitData.printRanks()
			unitData.printSupports()
		end
		
		if pressed(13) then print("moving rn position...") end
		if held(13) then -- move rn position
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
		
		if pressed(2) then rnEvent.printDiagnostic() end
		
		if pressed(3) then print("changing fog...") end
		if held(3) then
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
		
		if pressed(4) then print("changing money by " .. moneyStepSize .. "...") end
		if held(4) then -- move rn position
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
		
		if pressed(5) then rnEvent.toggle("dig") end
	
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
			-- todo reimplement
			-- print(combat.paramInRAM(true)) 
			-- print all stats rather than selecting?
		end
			
		if pressed(11) then
			if currentRNG.isPrimary then
				currentRNG = rns.rng2
			else
				currentRNG = rns.rng1
			end
			print(string.format("Switching to %s rng", currentRNG:name()))
		end
		
		-- todo modify RAM values for slots
		
		local function printRAMhelp()
			print()
			local nameCode = memory.readword(addr.ATTACKER_START + addr.NAME_CODE_OFFSET)
			local slotID = memory.readbyte(addr.ATTACKER_START + addr.SLOT_ID_OFFSET)
			local address = addr.SLOT_1_START + (slotID-1)*72 + RAMoffset
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
		
		if pressed(12) then
			printRAMhelp()
			print("<> to change value, ^v change offset")
		end
		if held(12) then 
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
				local address = addr.SLOT_1_START + (slotID-1)*72 + RAMoffset
				local data = memory.readbyte(address)
				data = data - 1
				if data < 0 then
					print()
					print("Can't shift data below 0")
				else
					memory.writebyte(addr.SLOT_1_START + RAMoffset, data)
					printRAMhelp()
				end
			end
			if pressed("right", gameCtrl) then
				local slotID = memory.readbyte(addr.ATTACKER_START + addr.SLOT_ID_OFFSET)
				local address = addr.SLOT_1_START + (slotID-1)*72 + RAMoffset
				local data = memory.readbyte(address)
				data = data + 1
				if data > 255 then
					print()
					print("Can't shift data above 255")
				else
					memory.writebyte(addr.SLOT_1_START + RAMoffset, data)
					printRAMhelp()
				end
			end
		end
		
		if pressed(13) then
			print()
			local nameCode = memory.readword(addr.ATTACKER_START + addr.NAME_CODE_OFFSET)
			print(string.format("unit %s 0x%04X", unitData.hexCodeToName(nameCode), nameCode))
			local classCode = memory.readword(addr.ATTACKER_START + addr.CLASS_CODE_OFFSET)
			local class = classes.HEX_CODES[classCode] or classes.OTHER
			print(string.format("class %d 0x%04X", class, classCode))
		end
	end
	
	feGUI.drawRects()

	emu.frameadvance()
end