-- Open_Selected_Filename.lua
-- mozers™, vladvro
-- version 1.2

---------------------------------------
-- dofile (props["SciteDefaultHome"].."\\scite_lua\\Open_Selected_Filename.lua")
--------------------------------------------------------------

function Open_Selected_Filename()
	local filename
	if editor.Focus then
		filename = editor:GetSelText()
	else
		filename = output:GetSelText()
	end 
	local foropen = nil

	-- Example: $(SciteDefaultHome)\c.abbr
	local pattern_sci = '^$[(](.-)[)]'
	local _, _, scite_var = string.find(filename,pattern_sci)
	if scite_var ~= nil then
		foropen = string.gsub(filename, pattern_sci, props[scite_var])
	else

		-- Example: %APPDATA%\Opera\Opera\profile\opera6.ini
		local pattern_env = '^[%%](.-)[%%]'
		local _, _, os_env = string.find(filename, pattern_env)
		if os_env ~= nil then
			foropen = string.gsub(filename, pattern_env, os.getenv(os_env))
		else

			-- Example: props["SciteDefaultHome"].."\\tools\\Zoom.lua"
			local pattern_props = '^props%[%p(.-)%p%]%.%.%p(.*)%p'
			local _, _, scite_prop1, scite_prop2 = string.find(filename,pattern_props)
			if scite_prop1 ~= nil then
				foropen = props[scite_prop1]..scite_prop2
			end
		end
	end

	if foropen ~= nil then
		foropen = string.gsub(foropen, '\\\\', '\\')
		scite.Open (foropen)
		return true
	end
end

-- Add user event handler OnMenuCommand
local old_OnMenuCommand = OnMenuCommand
function OnMenuCommand (msg, source)
	local result
	if old_OnMenuCommand then result = old_OnMenuCommand(msg, source) end
	if msg == IDM_OPENSELECTED then
		if Open_Selected_Filename() then return true end
	end
	return result
end
