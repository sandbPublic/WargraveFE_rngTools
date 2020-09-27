require("feAddress")


HARD_MODE = true
WINDOW_WIDTH = 45






-- 0 = player, 0x40 = other, 0x80 = enemy
local PHASE_NAMES = {"player", "other", "enemy"}

function getPhase()
	return PHASE_NAMES[1 + memory.readbyte(addr.PHASE)/0x40]
end

function printStringArray(array)
	print()
	for _, string_ in ipairs(array) do
		print(string_)
	end
end

function selected(tbl_)
	return tbl_[tbl_.sel_i]
end

-- sets selection to 1 if selection doesn't exist
function changeSelection(tbl_, amount, lock)
	tbl_.sel_i = tbl_.sel_i or 1
	
	if #tbl_ < 1 then return end
	
	amount = amount or 0
	
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
