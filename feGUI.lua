local P = {}
feGUI = P

P.rects = {}
P.RNBE_I 			= 1
P.BATTLE_PARAMS_I 	= 2
P.RN_STREAM_I		= 3 
P.STAT_DATA_I		= 4
P.LEVEL_UPS_I		= 5
P.COMPACT_BPS_I		= 6
-- burn notifier, don't want to cycle to this though
P.rects.count 		= 6
local RECT_COLORS = {
	"blue", 
	"green", 
	"red", 
	"yellow", 
	"magenta", 
	"white",
	"red"
}
local RECT_STRINGS = {
	"RNBE", 
	"battle parameters", 
	"rn stream", 
	"stat data", 
	"level ups", 
	"compact btl params",
	"burn notifier"
}

P.selRect_i = P.RNBE_I
function P.advanceDisplay()
	P.selRect_i = rotInc(P.selRect_i, P.rects.count)
	print("selecting display: " .. RECT_STRINGS[P.selRect_i])
end

P.rectShiftMode = false

function P.canAlterRNBE()
	return (not P.rectShiftMode) 
		and (P.selRect_i == P.RNBE_I) 
		and (P.rects[P.RNBE_I].opacity > 0)
end

local CHAR_PIXELS = 4
local rectObj = {}
rectObj.ID = 0
rectObj.Xratio = 0 -- 0 to 1, determine position within the gba window
rectObj.Yratio = 0
rectObj.opacity = 0
rectObj.color = 0
rectObj.strings = {} -- index from 0

function rectObj:numOfStrings()
	local ret = 0
	while self.strings[ret] do
		ret = ret + 1
	end
	return ret
end

-- height of a line
function rectObj:linePixels()
	if self:numOfStrings() > 16 then
		return math.floor(162/self:numOfStrings())
	end
	return 10
end

-- for the rnStream rect's colorized rns
local rnsPerLine = 10
local rnsLines = 5
function rectObj:width()
	local width = 0
	-- set to max line length
	for line_i = 0, self:numOfStrings()-1 do
		local stringLen = string.len(self.strings[line_i])
		
		-- add colorized string length
		-- don't need to do this for rnStream because it's padded with spaces
		if (self.ID == P.RNBE_I) and (line_i % 2 == 1) then
			stringLen = stringLen + rnbe.SPrnbes()[(line_i+1)/2].length * 3
		end
		
		if stringLen > width then
			width = stringLen
		end
	end
	return width*CHAR_PIXELS+6
end

function rectObj:height()
	return self:numOfStrings()*self:linePixels()+2
end

function rectObj:left()
	local ret = self.Xratio * (239 - self:width())
	if ret < 0 then
		ret = 0
	end
	return ret
end

function rectObj:top()
	local ret = self.Yratio * (159 - self:height())
	if ret < 0 then
		ret = 0
	end
	return ret
end

-- change position or opacity
function rectObj:shift(x, y, opac)
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

-- syncs with fire emblem animation cycle
-- units animate on a 48 == 8 * 6 frame cycle when hilighted
-- 72 == 8 * 9 frame cycle when not
-- cursor has 32 == 8 * 4 frame cycle
function P.pulse()
	return (vba.framecount() % 48) < 24
end

function P.flashcolor(color, color2)
	color = color or "white"
	if P.pulse() then 
		return color
	else
		local r, g, b, a = gui.parsecolor(color)
		local inverse = {}
		inverse.r = 0xFF - r
		inverse.g = 0xFF - g
		inverse.b = 0xFF - b
		inverse.a = a
		
		color2 = color2 or inverse
		
		return color2
	end

end

-- drawing functions are opacity agnostic, set gui.opacity before calling
function rectObj:drawBackgroundBox()
	local outlineColor = self.color
	if (self.ID == P.selRect_i) and P.rectShiftMode then 	
		outlineColor = P.flashcolor(outlineColor) -- selected and visible, flash outline
	end
	
	local r, g, b, a = gui.parsecolor(self.color)
	local darkColor = {}
	darkColor.r = r/4
	darkColor.g = g/4
	darkColor.b = b/4
	darkColor.a = a
	
	-- determine placement in window based on rectRatios
	local x1 = self:left()
	local y1 = self:top()
	gui.box(x1, y1, x1+self:width(), y1+self:height(), darkColor, outlineColor)
end

function rectObj:drawString(line_i, char_i, str, color, borderColor)
	color = color or "white"
	borderColor = borderColor or "black"

	gui.text(self:left()+3+char_i*CHAR_PIXELS, 
			 self:top() +2+line_i*self:linePixels(), 
		str, color, borderColor)
end

function rectObj:drawColorizedRNString(line_i, char_i, RN_start, length)
	for rn_i = 0, length-1 do
		local rn = rns.rng1:getRN(RN_start+rn_i)/0x100
		
		local rnColor = {}
		if rn < 0x80 then 
			rnColor.r = rn*2 -- less red if low number
			rnColor.g = 0xFF
		else
			rnColor.r = 0xFF
			rnColor.g = 0x1FF - rn*2 -- less green if high number
		end
		rnColor.b = math.min(rnColor.r, rnColor.g)
		rnColor.a = 0xFF
		
		self:drawString(line_i, char_i+3*rn_i, 
			rns.rng1:getRNasString(RN_start+rn_i), rnColor)
	end
end

function rectObj:drawBox(line_i, char_i, length, color)
	x1 = self:left() + char_i*CHAR_PIXELS
	y1 = self:top()  + line_i*self:linePixels()
	x2 = x1 + CHAR_PIXELS * length
	y2 = y1 + self:linePixels()
	
	gui.box(x1, y1, x2, y2, 0, color)
end

function rectObj:draw()
	if self.opacity <= 0 then return end
	
	gui.opacity(self.opacity)
	self:drawBackgroundBox()

	for line_i = 0, self:numOfStrings()-1 do
		self:drawString(line_i, 0, self.strings[line_i])
	end
	
	-- color highlighted RN strings, draw boxes
	if self.ID == P.RNBE_I then
		for RNBE_i = 1, rnbe.SPrnbes().count do
			self:drawColorizedRNString(2*RNBE_i-1, 9, -- 4 digits, +, 2 digits, :, space
				rnbe.SPrnbes()[RNBE_i].startRN_i, rnbe.SPrnbes()[RNBE_i].length)
			rnbe.SPrnbes()[RNBE_i]:drawMyBoxes(self, RNBE_i)
		end
		
	elseif self.ID == P.RN_STREAM_I then
		local firstLineRnPos = math.floor(rns.rng1.pos/rnsPerLine-1)*rnsPerLine
		if firstLineRnPos < 0 then firstLineRnPos = 0 end
	
		for line_i = 0, rnsLines-1 do
			self:drawColorizedRNString(line_i, 6, -- 4 digits, :, space
				firstLineRnPos+line_i*rnsPerLine, rnsPerLine)
		end
	end
	
	gui.opacity(1)
end

function rectObj:new(ID_p, color_p)
	color_p = color_p or RECT_COLORS[ID_p]

	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.ID = ID_p
	o.color = color_p
	return o
end

for rect_i = 1, P.rects.count do
	P.rects[rect_i] = rectObj:new(rect_i)
end
function P.selRect()
	return P.rects[P.selRect_i]
end

function P.drawRects()
	P.rects[P.RN_STREAM_I].strings = rns.rng1:RNstream_strings(true, rnsLines, rnsPerLine)
	P.rects[P.STAT_DATA_I].strings = unitData.statData_strings()
	P.rects[P.LEVEL_UPS_I].strings = unitData.levelUp_strings
	P.rects[P.BATTLE_PARAMS_I].strings = combat.currBattleParams:toStrings()
	-- don't want to overwrite currBattleParams generally	
	if (P.selRect_i == P.COMPACT_BPS_I) and (P.rects[P.COMPACT_BPS_I].opacity > 0) then
		combat.currBattleParams:set()
		P.rects[P.COMPACT_BPS_I].strings = combat.currBattleParams:toCompactStrings()
	end	
	P.rects[P.RNBE_I].strings = rnbe.toStrings()

	for rect_i = 1, P.rects.count do
		P.rects[rect_i]:draw()
	end
	P.burnNoteRect:draw()
end

-- put burn notifier at bottom left
P.burnNoteRect = rectObj:new(7, "red")
P.burnNoteRect.Yratio = 1
function P.setRN_BurnNoteString(str, opac)
	P.burnNoteRect.opacity = opac
	P.burnNoteRect.strings[0] = str
end

return feGUI