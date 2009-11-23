--[[--------------------------------------------------
 Save SciTE Settings
 Version: 1.7
 Author: mozers�, Dmitry Maslov
---------------------------------------------------
 Save current settings on SciTE close.
 ��������� ������� ��������� ��� �������� SciTE (� ����� SciTE.session)
---------------------------------------------------
Connection:
In file SciTEStartup.lua add a line:
  dofile (props["SciteDefaultHome"].."\\tools\\save_settings.lua")
Set in a file .properties:
  save.settings=1
  import home\SciTE.session
--]]----------------------------------------------------

local text = ''

-- ���������� � text ������� �������� �������� key
local function SaveKey(key)
	local value = props[key]
	-- [mhb] 11/23/09 commented: if tonumber(value) then 
		local regex = '([^%w.]'..key..'=)%-?%d+'
		if text:find(regex) == nil then
			text = text..'\n'..key..'='..value
			return
		end
		text = text:gsub(regex, "%1"..value)
	-- [mhb] 11/23/09 commented:  end
	return
end

local function SaveSettings()
	local file = props["scite.userhome"]..'\\SciTE.session'
	io.input(file)
	text = io.read('*a')
	SaveKey('toolbar.visible')
	SaveKey('tabbar.visible')
	SaveKey('statusbar.visible')
	SaveKey('view.whitespace')
	SaveKey('view.eol')
	SaveKey('view.indentation.guides')
	SaveKey('line.margin.visible')
	SaveKey('split.vertical')
	SaveKey('wrap')
	SaveKey('output.wrap')
	SaveKey('magnification') -- �������� ���������� � Zoom.lua
	SaveKey('output.magnification') -- �������� ���������� � Zoom.lua
	SaveKey('print.magnification') -- �������� ���������� � Zoom.lua
	SaveKey('sidebar.show') -- �������� ���������� � SideBar.lua
	SaveKey('sidebar.width')
	
	--[mhb] 10/24/09 added: to allow users to specify extra properties to save when finalise
	local tbl=prop2table('save.properties')
	for _,v in ipairs(tbl) do
		if type(v)=='string' then SaveKey(v) end
	end
	
	io.output(file)
	io.write(text)
	io.close()
end

local function ToggleProp(prop_name)
	local prop_value = tonumber(props[prop_name])
	if prop_value==0 then
		props[prop_name] = '1'
	elseif prop_value==1 then
		props[prop_name] = '0'
	end
end

-- ��������� ���� ���������� ������� OnMenuCommand
-- ��� ��������� ���������� ����� ����, �������� � ��������������� �������� props[]
local old_OnMenuCommand = OnMenuCommand
function OnMenuCommand(cmd, source)
	local result
	if old_OnMenuCommand then result = old_OnMenuCommand(cmd, source) end
	if cmd == IDM_VIEWTOOLBAR then
		ToggleProp('toolbar.visible')
	elseif cmd == IDM_VIEWTABBAR then
		ToggleProp('tabbar.visible')
	elseif cmd == IDM_VIEWSTATUSBAR then
		ToggleProp('statusbar.visible')
	elseif cmd == IDM_VIEWSPACE then
		ToggleProp('view.whitespace')
	elseif cmd == IDM_VIEWEOL then
		ToggleProp('view.eol')
	elseif cmd == IDM_VIEWGUIDES then
		ToggleProp('view.indentation.guides')
	elseif cmd == IDM_LINENUMBERMARGIN then
		ToggleProp('line.margin.visible')
	elseif cmd == IDM_SPLITVERTICAL then
		ToggleProp('split.vertical')
	elseif cmd == IDM_WRAP then
		ToggleProp('wrap')
	elseif cmd == IDM_WRAPOUTPUT then
		ToggleProp('output.wrap')
	end
	return result
end

-- ��������� ���� ���������� ������� OnFinalise
-- ���������� �������� ��� �������� SciTE
local old_OnFinalise = OnFinalise
function OnFinalise()
	local result
	if old_OnFinalise then result = old_OnFinalise() end
	if tonumber(props['save.settings']) == 1 then
		SaveSettings()
	end
	return result
end
