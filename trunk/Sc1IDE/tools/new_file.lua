--[[
[mhb] modified 07/23/09 : to allow saving file as untitiled?.*
--------------------------------------------------
new_file.lua
mozers™ (при активном участии dB6)
version 2.1
----------------------------------------------
Replaces SciTE command "File|New" (Ctrl+N)
Creates new buffer in the current folder with current file extension
----------------------------------------------
Connection:
In file SciTEStartup.lua add a line:
  dofile (props["SciteDefaultHome"].."\\tools\\new_file.lua")
--]]----------------------------------------------------

props["untitled.file.number"] = 0

local function CreateUntitledFile()
	local file_ext = "."..props["FileExt"]
	if file_ext == "." then file_ext = props["default.file.ext"] end
	repeat
		local file_path = props["FileDir"].."\\"..'Untitled'..props["untitled.file.number"]..file_ext
		props["untitled.file.number"] = tonumber(props["untitled.file.number"]) + 1
		if not f_exist(file_path) then
			local warning_couldnotopenfile_disable = props['warning.couldnotopenfile.disable']
			props['warning.couldnotopenfile.disable'] = 1
			scite.Open(file_path)
			props['warning.couldnotopenfile.disable'] = warning_couldnotopenfile_disable
			return true
		end
	until false
end

--[mhb] 07/23/09 : modify SaveUntitledFile() to allow saving under name Untitled?
local saved_files={} 
local function SaveUntitledFile()
	if string.find(props['FileName'],'Untitled') and not saved_files[props['FilePath']] then
		scite.MenuCommand(IDM_SAVEAS)
		saved_files[props['FilePath']]=true
		return true
	else
		return false
	end
end


-- Add user event handler OnMenuCommand
local old_OnMenuCommand = OnMenuCommand
function OnMenuCommand (msg, source)
	local result
	if old_OnMenuCommand then result = old_OnMenuCommand(msg, source) end
	if msg == IDM_NEW then
		if CreateUntitledFile() then return true end
	elseif msg == IDM_SAVE then
		if SaveUntitledFile() then return true end
	end
	return result
end
