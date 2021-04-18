local P = {}
ctrl = P

P.hotkeys = {}
local f = assert(io.open("QwertyHotkeys.txt", "r"))
local c = f:read("*line")
while c do
	hotkey = {}
	hotkey.key = c
	hotkey.message1 = c .. ": " .. f:read("*line")
	hotkey.message2 = c:lower() .. ": " ..f:read("*line")
	
	table.insert(P.hotkeys, hotkey)
	c = f:read("*line")
end
f:close()




-- non-modifying functions

local ctrlObj = {}

function ctrlObj:pressed(key)
	return self.inputs[key].framesHeldFor == 0
end

function ctrlObj:held(key, repeatRate)
	repeatRate = repeatRate or 1

	return (self.inputs[key].framesHeldFor % repeatRate) == 0 and self.inputs[key].framesHeldFor >= 0
end

function ctrlObj:released(key)
	return self.inputs[key].framesNotHeldFor == 0
end




-- modifying functions

function ctrlObj:update(currFrame)
	self.anythingHeld = false
	for key, _ in pairs(self.inputs) do
		if currFrame[key] then
			self.inputs[key].framesHeldFor = self.inputs[key].framesHeldFor + 1
			self.inputs[key].framesNotHeldFor = -1
			self.anythingHeld = true
		else
			self.inputs[key].framesNotHeldFor = self.inputs[key].framesNotHeldFor + 1
			self.inputs[key].framesHeldFor = -1
		end
	end
end

function ctrlObj:register(key)
	self.inputs[key] = {}
	self.inputs[key].framesHeldFor = -1
	self.inputs[key].framesNotHeldFor = 1
end

function ctrlObj:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	
	o.inputs = {}
	
	return o
end




P.keyboard = ctrlObj:new()
for i, hotkey in ipairs(P.hotkeys) do
	P.keyboard:register(hotkey.key)
end
-- savestates
for i = 1, 10 do
	P.keyboard:register("F" .. i)
end
P.keyboard:register("shift")

P.gamepad = ctrlObj:new()
local gbaButtons = {"A", "B", "select", "start", "right", "left", "up", "down", "R", "L"}
for i, key in ipairs(gbaButtons) do
	P.gamepad:register(key)
end

return P