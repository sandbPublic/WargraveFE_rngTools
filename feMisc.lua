require("feAddress")


HARD_MODE = true
WINDOW_WIDTH = 45




function recursivePrintTable(tbl_, prefix)
	prefix = prefix or ""
	for k, v in pairs(tbl_) do
		if type(v) == "table" then
			local vIsSimpleArray = true
			for k2, v2 in pairs(v) do
				if type(k2) ~= "number" or type(v2) ~= "number" then
					vIsSimpleArray = false
					recursivePrintTable(v, " " .. prefix .. "." .. k)
					break
				end
			end
		
			if vIsSimpleArray then
				print(prefix .. "." .. k .. "=", v)
			end
		else
			print(prefix .. "." .. k .. "=" .. tostring(v))
		end
	end
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
