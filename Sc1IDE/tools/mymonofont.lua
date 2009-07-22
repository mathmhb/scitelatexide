--[mhb] 07/22/09 : monofont support via new property "MonoFont" existed in Sc1IDE r93+
function UseMonoFont()
	if props['MonoFont']=='' then
		scite.MenuCommand(IDM_MONOFONT)
	end
end

--[[
if tostring(props['start.in.monospaced.mode'])=='1' then
	scite.MenuCommand(IDM_MONOFONT)
	
end
]]