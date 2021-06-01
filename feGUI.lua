require("feAutolog")

local P = {}
feGUI = P




P.rects = {}
P.RN_EVENT_I 	= 1
P.AUTOLOG_I		= 2
P.RN_STREAM_I	= 3
P.STAT_DATA_I	= 4
P.COMBAT_I 	    = 5
P.COMPACT_BPS_I	= 6
P.COORD_I		= 7
P.rects.sel_i = P.AUTOLOG_I

local RECT_COLORS = {
	"blue",
	"cyan",
	"white",
	"green",
	"red",
	"yellow",
	"white",
}
local RECT_STRINGS = {
	"rnEvents",
	"autolog",
	"rn stream",
	"stat data",
	"battle parameters",
	"compact btl params",
	"cursor coordinates",
}
local LEVEL_UP_COLORS = {
	0xFF8080FF, -- hue   0 pink
	0xFFAA00FF, -- hue  40 orange
	0xFFFF00FF, -- hue  60 yellow
	0x00FF00FF, -- hue 100 green
	0x00FFFFFF, -- hue 180 cyan
	0x0000FFFF, -- hue 240 blue
	0xFF00FFFF  -- hue 300 magenta
}
local CHAR_PIXELS = 4 -- can fit ~60 chars within 240 pixel window
-- for the rnStream rect's colorized rns
local RNS_PER_LINE = 15
local NUM_RN_LINES = 15




-- syncs with fire emblem animation cycle
-- units animate on a 48 == 8 * 6 frame cycle when highlighted
-- 72 == 8 * 9 frame cycle when not
-- cursor has 32 == 8 * 4 frame cycle
local function isPulsePhase(cycle)
	cycle = cycle or 48
	
	return (vba.framecount() % cycle) < (cycle/2)
end

-- alternates between color1 and color2 (or inverse of color1) based on pulse phase
local function pulseColor(color1, color2)
	color1 = color1 or "white"
	if isPulsePhase() then 
		return color1
	else
		if color2 then return color2 end
		
		local r, g, b, a = gui.parsecolor(color1)
		local inverse = {}
		inverse.r = 0xFF - r
		inverse.g = 0xFF - g
		inverse.b = 0xFF - b
		inverse.a = a
		
		return inverse
	end
end






local rectObj = {}

-- non modifying functions

-- height of a line, 10 if <= 16
function rectObj:linePixels()
	if #self.strings > 16 then
		return math.floor(162/#self.strings)
	end
	return 10
end

function rectObj:width()
	local longestStringLength = 0
	-- set to max line length
	for line_i, string_ in ipairs(self.strings) do
		local stringLen = string_:len()
		
		-- add colorized string length
		if (self.ID == P.RN_EVENT_I) and (line_i % 2 == 0) then
			stringLen = stringLen + rnEvent.events[line_i/2].length * 3
		end
		
		if longestStringLength < stringLen then
			longestStringLength = stringLen
		end
	end
	return longestStringLength * CHAR_PIXELS + 6
end

function rectObj:height()
	return #self.strings*self:linePixels()+2
end

function rectObj:left()
	local ret = self.Xratio * (239 - self:width())
	if ret < 0 then
		return 0
	end
	return ret
end

function rectObj:top()
	local ret = self.Yratio * (159 - self:height())
	if ret < 0 then
		return 0
	end
	return ret
end




-- drawing functions
-- opacity agnostic; set gui.opacity before calling

function rectObj:drawBackgroundBox()	
	-- determine placement in window based on rectRatios
	local x1 = self:left()
	local y1 = self:top()
	
	-- if shiftMode and visible, flash outline
	if (self.ID == P.rects.sel_i) and self.shiftMode then
		gui.box(x1, y1, x1+self:width(), y1+self:height(), 
			pulseColor(self.backgroundColor), pulseColor(self.outlineColor))
		return
	end
	
	gui.box(x1, y1, x1+self:width(), y1+self:height(), 
		self.backgroundColor, self.outlineColor)
end

function rectObj:drawString(line_i, char_offset, str, color, borderColor)
	if not color then
		color = "white"
		borderColor = "black"
	elseif not borderColor then
		borderColor = colorUtil.darken(color)
	end
	
	gui.text(self:left() + 3 + char_offset*CHAR_PIXELS, 
			 self:top() + 2 + (line_i - 1)*self:linePixels(), 
			 str, 
			 color, 
			 borderColor)
end

function rectObj:drawBox(line_i, char_offset, length, color)
	x1 = self:left() + char_offset*CHAR_PIXELS
	y1 = self:top()  + (line_i - 1)*self:linePixels()
	x2 = x1 + length*CHAR_PIXELS
	y2 = y1 + self:linePixels()
	
	gui.box(x1, y1, x2, y2, 0, color)
end

-- draw boxes around rns on second line
function rectObj:drawEventBoxes(event, rnEvent_i)
	local line_i = 2*rnEvent_i
	local INIT_CHARS = 6
	
	self:drawBox(line_i, INIT_CHARS, event.burns * 3, "red")
	
	if event.hasCombat then
		hitStart = event.burns
		
		for _, hitEvent in ipairs(event.mHitSeq) do
			self:drawBox(line_i, INIT_CHARS + hitStart * 3, hitEvent.RNsConsumed * 3, "yellow")
			
			hitStart = hitStart + hitEvent.RNsConsumed
		end
	end
	
	if event:levelDetected() then
		local procs = event.unit:willLevelStats(event.postCombatRN_i, event.stats)
		
		for i = 1, 7 do
			local char_start = INIT_CHARS + (event.postCombatRN_i-event.startRN_i + i-1) * 3
			
			if procs[i] == 1 then
				self:drawBox(line_i, char_start, 3, LEVEL_UP_COLORS[i]) 
			elseif procs[i] == 2 then -- Afa's provided stat
				self:drawBox(line_i, char_start, 3, pulseColor(LEVEL_UP_COLORS[i], "white")) 
			elseif procs[i] == -1 then -- capped stat
				self:drawBox(line_i, char_start, 3, pulseColor(0x662222FF, "black"))
			end
		end
	end
end

function rectObj:draw()
	if self.opacity <= 0 then return end
	
	local colorSegmentLists = {}
	
	if self.ID == P.RN_EVENT_I then
	
		self.strings, colorSegmentLists = rnEvent.toStrings()
		
	elseif self.ID == P.AUTOLOG_I then
	
		self.strings, colorSegmentLists = autolog.GUIstrings()
		
	elseif self.ID == P.RN_STREAM_I then
	
		self.strings, colorSegmentLists = rns.rng1:RNstream_strings(NUM_RN_LINES, RNS_PER_LINE)
		
	elseif self.ID == P.STAT_DATA_I then
	
		self.strings, colorSegmentLists = unitData.currUnit():statData_strings(isPulsePhase(480) and (P.rects.sel_i == P.STAT_DATA_I))
		
	elseif self.ID == P.COMBAT_I then
	
		self.strings = combat.combatObj:new():toStrings()
		
	elseif self.ID == P.COMPACT_BPS_I then
	
		self.strings = combat.combatObj:new():toCompactStrings()
		
	elseif self.ID == P.COORD_I then
	
		self.strings = {string.format("%02d,%02d", memory.readbyte(addr.CURSOR_X), memory.readbyte(addr.CURSOR_Y))}
		
	end
	
	gui.opacity(self.opacity)
	self:drawBackgroundBox()
	
	for line_i, line in ipairs(self.strings) do
		
		local charsUsed = 0
		local colorSegments = colorSegmentLists[line_i] or {}
		
		for _, segment in ipairs(colorSegments) do
			if type(segment[1]) ~= "number" then
				print()
				print(debug.traceback())
				print()
				print(self.ID)
				print()
				for j, segment2 in ipairs(colorSegments) do
					print(j, segment2)
				end
				print()
				print(line, line_i)
				print()
				print(segment)
				print()
				print(segment[1])
			end
		
			local nextCharsUsed = charsUsed + segment[1]
			self:drawString(line_i, 
							charsUsed, 
							line:sub(charsUsed + 1, nextCharsUsed), 
							segment[2], 
							segment[3])
			charsUsed = nextCharsUsed
			
		end
		
		self:drawString(line_i, charsUsed, line:sub(charsUsed + 1)) -- if unspecified, draw until end in white
	end
	
	-- color highlighted RN strings, draw boxes
	if self.ID == P.RN_EVENT_I then
		for i, event in ipairs(rnEvent.events) do
			self:drawEventBoxes(event, i)
		end	
	elseif self.ID == P.RN_STREAM_I then
		if rns.rng1.pos >= RNS_PER_LINE then
			self:drawBox(2, 7 + (rns.rng1.pos % RNS_PER_LINE)*3, 3, "white")
		else
			self:drawBox(1, 7 + rns.rng1.pos*3, 3, "white")
		end
	end
	
	gui.opacity(1)
end

function P.drawRects()
	for _, rect in ipairs(P.rects) do
		rect:draw()
	end
end




-- modifying functions

-- change position or opacity
function rectObj:adjust(x, y, opac)
	self.Xratio = self.Xratio + x
	if self.Xratio < 0 then self.Xratio = 0 end
	if self.Xratio > 1 then self.Xratio = 1 end
	self.Yratio = self.Yratio + y
	if self.Yratio < 0 then self.Yratio = 0 end
	if self.Yratio > 1 then self.Yratio = 1 end
	self.opacity = self.opacity + opac
	if self.opacity < 0 then self.opacity = 0 end
	if self.opacity > 1 then self.opacity = 1 end
end

function rectObj:new(ID_p, color_p)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	
	o.ID = ID_p
	o.Xratio = 0 -- 0 to 1, determine position within the gba window
	o.Yratio = 0
	o.opacity = 0
	o.shiftMode = false
	o.name = RECT_STRINGS[ID_p]
	o.strings = {}
	
	o.outlineColor = color_p or RECT_COLORS[ID_p]
	
	local r, g, b, a = gui.parsecolor(o.outlineColor)
	o.backgroundColor = {}
	o.backgroundColor.r = r/4
	o.backgroundColor.g = g/4
	o.backgroundColor.b = b/4
	o.backgroundColor.a = a	
	
	return o
end

for rect_i = 1, #RECT_COLORS do
	table.insert(P.rects, rectObj:new(rect_i))
end

return feGUI