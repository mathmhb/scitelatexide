--[[--------------------------------------------------
 [mhb] 
--]]--------------------------------------------------

--[[
function myrename() 

local filename = props["FileNameExt"]
local filename_new = props["FileNameExt"]
local title = scite.GetTranslation("File Rename")
local msg1 = scite.GetTranslation("Please enter new file name:")
local msg2 = scite.GetTranslation("The file with such name already exists!\nPlease enter different file name.")
repeat
	--filename_new = shell.inputbox(title, msg1, filename_new, function(name) return not name:match('[\\/:|*?"<>]') end)
	filename_new = gui.prompt_value(msg1,filename)
	if not filename_new:match('[\\/:|*?"<>]') then return;end
	
	if filename_new == nil then return end
	if #filename_new == 0 then return end
	if filename_new == filename then return end
	if not f_exist(filename_new) then break end
-- 	shell.msgbox(msg2, title)
	gui.message(msg2)
until false

local file_dir = props["FileDir"]
filename_new = file_dir:gsub('\\','\\\\')..'\\\\'..filename_new
scite.Perform("saveas:"..filename_new)
os.remove(file_dir..'\\'..filename)

end
]]--

function myrename() 
local filepath = props["FilePath"]
scite.MenuCommand(IDM_SAVEAS)
if filepath~=props['FilePath'] then
	print('Removing '..filepath..' ...')
	os.remove(filepath)
end
end