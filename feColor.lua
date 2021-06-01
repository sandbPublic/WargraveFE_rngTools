local P = {}
colorUtil = P




function P.darken(c, factor)
	factor = factor or 4
	
	local d = {}
	d.a = c.a
	d.r = c.r/factor
	d.g = c.g/factor
	d.b = c.b/factor
	
	return d
end

P.white = {r = 255, g = 255, b = 255}
P.grey = {r = 191, g = 191, b = 191}
P.black = {r = 0, g = 0, b = 0}

P.red = {r = 255, g = 0, b = 0}
P.orange = {r = 255, g = 127, b = 0}
P.yellow = {r = 255, g = 255, b = 0}
P.green = {r = 0, g = 255, b = 0}
P.blue = {r = 0, g = 63, b = 255} -- blue is darkest on screen
P.violet = {r = 255, g = 0, b = 255}

P.right = P.red
P.left = P.green
P.down = P.yellow
P.up = P.blue

P.phaseColors = {}
P.phaseColors["player"] = P.blue
P.phaseColors["enemy"] = P.red
P.phaseColors["other"] = P.green

P.blueToRed = {
	{63,128,255},
	{63,255,128},
	{255,255,255},
	{255,255,0},
	{255,0,0}
}

P.redToBlue = {
	{255,0,0},
	{255,255,0},
	{255,255,255},
	{63,255,128},
	{63,128,255}
}

P.chromaticLoop = {
	{255,127,127},
	{255,255,0},
	{127,255,127},
	{0,255,255},
	{127,127,255},
	{255,0,255},
	{255,127,127}
}

function P.interpolate(x, endpointValues)
	if x > 1 then
		x = 1
	end
	if x < 0 then
		x = 0
	end
	x = x * (#endpointValues-1)
	
	local i = math.floor(x) + 1
	local thisColorWeight = i - x
	local nextColorWeight = 1 - thisColorWeight
	
	local thisColor = endpointValues[i]
	local nextColor = endpointValues[i+1] or endpointValues[i]
	
	local c = {}
	c.a = 0xFF
	c.r = thisColor[1] * thisColorWeight + nextColor[1] * nextColorWeight		
	c.g = thisColor[2] * thisColorWeight + nextColor[2] * nextColorWeight		
	c.b = thisColor[3] * thisColorWeight + nextColor[3] * nextColorWeight
	
	return c
end

function P.prandom(i)
	return P.interpolate(((i * 144) % 233) / 232, P.chromaticLoop)
end



return P