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
	return self.thisFrame[key] and not self.lastFrame[key]
end

function ctrlObj:held(key)
	return self.thisFrame[key]
end

function ctrlObj:released(key)
	return not self.thisFrame[key] and self.lastFrame[key]
end




-- modifying functions

function ctrlObj:update(currFrame)
	self.lastFrame = self.thisFrame
	self.thisFrame = currFrame
	
	self.anythingHeld = false
	for _, hotkey in ipairs(P.hotkeys) do
		if self.thisFrame[hotkey.key] then
			self.anythingHeld = true
			return
		end
	end
end

function ctrlObj:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	
	o.thisFrame = {}
	o.lastFrame = {}
	o.anythingHeld = false
	
	return o
end

P.keyboard = ctrlObj:new()
P.gamepad = ctrlObj:new()

return P