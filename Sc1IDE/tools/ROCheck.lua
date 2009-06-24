--     dofile (props["SciteDefaultHome"].."\\tools\\ROCheck.lua")
--Midas, vladvro
-----------------------------------------------
local function ROCheck()
	local FileAttr = props['FileAttr']
	if string.find(FileAttr, "[RHS]") and not editor.ReadOnly then
		scite.MenuCommand(IDM_READONLY)
	end
end

scite_OnOpen(ROCheck)

