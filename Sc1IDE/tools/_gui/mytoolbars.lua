--by [mathmhb] 01/05/09: to support file type sensitive separate toolbars
--01/14/09: to add customization of disable some toolbars 
--put icon images in the following paths
local img_path=props['SciteDefaultHome']..'\\images'
toolbar_image_path=scite_GetProp('TOOLBAR_IMAGE_PATH',img_path)


--set tool icon size
toolbar_image_size=tonumber(scite_GetProp('TOOLBAR_IMAGE_SIZE','16'))
gui_toolbars=prop2table('MYTOOLBARS',true)

scite_require('_gui\\mytoolbars.lux')

--don't change the codes below!
local tt_list={}

local function make_tt_list ()
	for t,v in pairs(gui_toolbars) do
		local px=tonumber(v[3])
		local py=tonumber(v[4])
		local tb=v[2]
		for __,vv in ipairs(tb) do
			tb[__]=vv:gsub('~~','|')
		end
		tt_list[t]=gui.toolbar(v[1],tb,toolbar_image_size,toolbar_image_path)
		tt_list[t]:position(px,py)
 		tt_list[t]:hide()
	end
end

local function set_visible(tt,typ)
	if not tt then return; end
	if props['MYTOOLBAR_'..typ]=='1' then
		tt:show()
	else
		tt:hide()
	end
end

function MyToolbarAll_ShowHide()
	local prp='MYTOOLBAR_ALL'
	if tonumber(props[prp])==1 then
		props[prp]=0
	else
		props[prp]=1
	end
	set_visible(tt_list['all'],'ALL')
end

function MyToolbar_ShowHide()
	local typ=props['FileType']
	local prp='MYTOOLBAR_'..typ
	if tonumber(props[prp])==1 then
		props[prp]=0
	else
		props[prp]=1
	end
	set_visible(tt_list[typ],typ)
end



local function on_switch ()
	typ=props['FileType']
	tt=tt_list[typ]
	for t,v in pairs(gui_toolbars) do
		tt_list[t]:hide()
-- 		if t~='all' or props['MYTOOLBAR_'..string.upper(t)]=='0' then tt_list[t]:hide();end
	end
	set_visible(tt_list['all'],'ALL')
	set_visible(tt_list[typ],typ)
end



make_tt_list()
scite_OnSwitchFile(on_switch)
scite_OnOpen(on_switch)