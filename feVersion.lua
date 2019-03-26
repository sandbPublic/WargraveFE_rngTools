version = 7

function cycleVersion()
	version = version + 1
	if version > 8 then
		version = 6
	end
	print("Version " .. tostring(version))
end

return version