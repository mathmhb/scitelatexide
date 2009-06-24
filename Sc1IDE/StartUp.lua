--[mhb] 05/21/09: clean lua global environment 
local _S='|string|xpcall|package|tostring|print|os|unpack|require|getfenv|setmetatable|next|assert|tonumber|io|rawequal|collectgarbage|arg|getmetatable|module|rawset|gcinfo|math|debug|pcall|table|newproxy|type|coroutine|_G|select|lua4nt|pairs|rawget|loadstring|ipairs|_VERSION|dostring|dofile|setfenv|load|error|loadfile|editor|output|scite|props|trace|'

for _,v in pairs(_G) do
  local q=string.find(_S,'|'.._..'|') or string.find(_,'On')
  if not q then _G[_]=nil; end
end

if tostring(props['PLAT_GTK'])=='1' then
  props['USING_GUI']=''
  props['USING_SHELL']=''
end

--GUI support via gui.dll
if props['USING_GUI']=='1' then
  require('gui')
end

--Win32 Shell support via shell.dll
if props['USING_SHELL']=='1' then
  require('shell')
end


--Misc common functions and Win32 Support via m_ext.dll: required by most [mathmhb]'s lua scripts 
require('m_ext')


-- by default, the spawner lib sits next to extman.lua
local spawner_path = props['spawner.extension.path'] or props['SciteDefaultHome']
local fn
if GTK then
    fn,err = package.loadlib(spawner_path..'/unix-spawner-ex.so','luaopen_spawner')
else
    fn,err = package.loadlib(spawner_path..'\\spawner-ex.dll','luaopen_spawner')
end
if fn then
    fn() -- register spawner
else
    print('cannot load spawner '..err)
end

--My new extman functions (without loading scripts automatically): required by most [mathmhb]'s lua scripts 
dofile(props['SciteDefaultHome']..'/'..'m_extman.lua')

local extman_path = path_of(props['ext.lua.startup.script'])
local dirsep='\\'
local lua_path = scite_GetProp('ext.lua.directory',extman_path..dirsep..'scite_lua')

if props['AUTO_PRELOAD_LUA_FILES']=='1' then
  -- Load all scripts in the lua_path, including within any subdirectories
  -- that aren't 'examples' or begin with a '_'
  local script_list = scite_Files(lua_path..dirsep..'*.lua')
  table.sort(script_list) --[mhb] added: to fix the loading order
  load_script_list(script_list,lua_path)
  local dirs = scite_Directories(lua_path,'^_')
  for i,dir in ipairs(dirs) do
      load_script_list(scite_Files(dir..dirsep..'*.lua'),dir)
  end
else
  local lua_files=props['PRELOAD_LUA_FILES'] or ''
  if lua_files=='' then
    print('Please edit settings PRELOAD_LUA_FILES to manually assign preloaded lua files list!')
  else
    local script_list=split(lua_files,'|')
    load_script_list(script_list,lua_path)
  end
end


--[mhb] 06/12/09: allow to enable/disable lua events via property USE_EVENT_HANDLERS
-- dofile(props['SciteDefaultHome']..'/'..'m_events.lua')

