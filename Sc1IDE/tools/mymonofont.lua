local use_monofont=0

local old_OnMenuCommand = OnMenuCommand
function OnMenuCommand(cmd, source)
	local result
	if old_OnMenuCommand then result = old_OnMenuCommand(cmd, source) end
	if cmd == IDM_MONOFONT then
		use_monofont=1-use_monofont
		props['use.monofont']=use_monofont
-- 		print('mono',props['use.monofont'])
		scite.UpdateStatusBar()
	end
	return result
end

function UseMonoFont()
	if use_monofont==0 then
		scite.MenuCommand(IDM_MONOFONT)
	end
end

--[[
if tostring(props['start.in.monospaced.mode'])=='1' then
	scite.MenuCommand(IDM_MONOFONT)
	
end
]]