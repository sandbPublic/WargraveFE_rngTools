--https://gamefaqs.gamespot.com/gba/468480-fire-emblem/faqs/31542

GAME_VERSION = 7
HARD_MODE = true
WINDOW_WIDTH = 45

-- 0,0 is upper left
CURSOR_X_ADDR = {0x0202AA1C, 0x0202BBCC, 0x0202BCC4} -- also at +4
CURSOR_X_ADDR = CURSOR_X_ADDR[GAME_VERSION - 5]
CURSOR_Y_ADDR = CURSOR_X_ADDR + 2

FOG_ADDR = {0x0202AA55, 0x0202BC05, 0x0202BCFD}
FOG_ADDR = FOG_ADDR[GAME_VERSION - 5]
PHASE_ADDR = FOG_ADDR + 2
-- 0 = player, 0x40 = other, 0x80 = enemy
local PHASE_NAMES = {"player", "other", "enemy"}
TURN_ADDR = PHASE_ADDR + 1
function turnString(turn, phase)
	return "Turn " .. turn .. " " .. PHASE_NAMES[1+phase/0x40] .. " phase"
end

function selected(tbl_)
	return tbl_[tbl_.sel_i]
end

function changeSelection(tbl_, amount, lock)
	if #tbl_ < 1 then return end
	
	tbl_.sel_i = tbl_.sel_i + amount
	
	if lock then
		if tbl_.sel_i > #tbl_ then tbl_.sel_i = #tbl_ end
		if tbl_.sel_i < 1 then tbl_.sel_i = 1 end
		return
	end
	
	while tbl_.sel_i > #tbl_ do
		tbl_.sel_i = tbl_.sel_i - #tbl_
	end
	while tbl_.sel_i < 1 do
		tbl_.sel_i = tbl_.sel_i + #tbl_
	end
end
