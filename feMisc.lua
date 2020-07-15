GAME_VERSION = 8
HARD_MODE = true
WINDOW_WIDTH = 45

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
