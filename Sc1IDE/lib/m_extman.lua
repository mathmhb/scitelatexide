-- [Comments from Extman]]:: 
-- Extman is a Lua script manager for SciTE. It enables multiple scripts to capture standard events
-- without interfering with each other. For instance, scite_OnDoubleClick() will register handlers
-- for scripts that need to know when a double-click event has happened. (To know whether it
-- was in the output or editor pane, just test editor.Focus).  It provides a useful function scite_Command
-- which allows you to define new commands without messing around with property files (see the
-- examples in the scite_lua directory.)
-- extman defines three new convenience handlers as well:
--scite_OnWord (called when user has entered a word)
--scite_OnEditorLine (called when a line is entered into the editor)
--scite_OnOutputLine (called when a line is entered into the output pane)

-- this is an opportunity for you to make regular Lua packages available to SciTE
--~ package.path = package.path..';C:\\lang\\lua\\lua\\?.lua'
--~ package.cpath = package.cpath..';c:\\lang\\lua\\?.dll'


--[Variables and Initializations from Extman]:: 

local GTK = tostring(props['PLAT_GTK'])=='1'

local _MarginClick,_DoubleClick,_SavePointLeft = {},{},{}
local _SavePointReached,_Open,_SwitchFile = {},{},{}
local _BeforeSave,_Save,_Char = {},{},{}
local _Word,_LineEd,_LineOut = {},{},{}
local _OpenSwitch = {}
local _UpdateUI = {}
local _UserListSelection
-- new with 1.74!
local _Key = {}
local _DwellStart = {}
local _Close = {}
-- new
local _remove = {}
local append = table.insert
local find = string.find
local size = table.getn
local sub = string.sub
local gsub = string.gsub

local path_pattern
local tempfile
local dirsep

-- this version of scite-gdb uses the new spawner extension library.
local fn,err,spawner_path
if package then loadlib = package.loadlib end



if GTK then
    tempfile = '/tmp/.scite-temp-files'
    path_pattern = '(.*)/[^%./]+%.%w+$'
    dirsep = '/'
else
    tempfile = props['SciteUserHome']..'\\scite_temp1' --[mhb]:'\\scite_temp1'
    path_pattern = '(.*)[\\/][^%.\\/]+%.%w+$'
    dirsep = '\\'
end


function path_of(s)
    local _,_,res = string.find(s,path_pattern)
    if _ then return res else return s end
end


local extman_path = path_of(props['ext.lua.startup.script'])
local lua_path = props['ext.lua.directory'] or ''
if lua_path=='' then lua_path=extman_path..dirsep..'scite_lua' end


--[My Variables]:: 
--[mhb] 06/13/09: to support recording current script
local current_script='m_extman.lua'
local funcs_table={}
local h_name={}
h_name[_Save]='_Save'
h_name[_Open]='_Open'
h_name[_SwitchFile]='_SwitchFile'
h_name[_Close]='_Close'
h_name[_OpenSwitch]='_OpenSwitch'
h_name[_DoubleClick]='_DoubleClick'
h_name[_Word]='_Word'
h_name[_Char]='_Char'
h_name[_UpdateUI]='_UpdateUI'

--[mhb] 06/05/09: added property FILES_IN_SESSION to provide functions like Find in Session...
local files_cache={}

--[Extman Functions]:: 
-- useful function for getting a property, or a default if not present.
function scite_GetProp(key,default)
   local val = props[key]
   if val and val ~= '' then return val 
   else return default end
end

function scite_GetPropBool(key,default)
	local res = scite_GetProp(key,default)
	if not res or res == '0' or res == 'false' then return false
	else return true
	end
end

function scite_WordAtPos(pos)
    if not pos then pos = editor.CurrentPos end
    local p2 = editor:WordEndPosition(pos,true)
    local p1 = editor:WordStartPosition(pos,true)
    if p2 > p1 then
        return editor:textrange(p1,p2)
    end
end

function scite_GetSelOrWord()
    local s = editor:GetSelText()
    if s == '' then
        return scite_WordAtPos()
    else
        return s
    end
end


-- a general popen function that uses the spawner library if found; otherwise falls back
-- on os.execute
function scite_Popen(cmd)
    if spawner then        
        return spawner.popen(cmd)
    else
        cmd = cmd..' > '..tempfile
        if  GTK then -- io.popen is dodgy; don't use it!            
            os.execute(cmd)
        else            
            if Execute then -- scite_other was found!
                Execute(cmd)
            else
                os.execute(cmd)
            end
       end
       return io.open(tempfile)
    end	
end

function dirmask(mask,isdir)    
    local attrib = '' 
    if isdir then
        if not GTK then
            attrib = ' /A:D '
        else
            attrib = ' -F '
        end
    end
    if not GTK then
        mask = gsub(mask,'/','\\')
        return 'dir /b '..attrib..quote_if_needed(mask)
    else
        return 'ls -1 '..attrib..quote_if_needed(mask)
    end
end

-- grab all files matching @mask, which is assumed to be a path with a wildcard.
--[[
function scite_Files(mask)
    local f,path,cmd,_
    if not GTK then
        cmd = dirmask(mask)
        path = mask:match('(.*\\)')  or '.\\'	
    else
        cmd = 'ls -1 '..mask
        path = ''
    end
    f = scite_Popen(cmd)
    local files = {}
    if not f then return files end
    for line in f:lines() do
   --     print(path..line)
        append(files,path..line)
    end
    f:close()
    return files
end
]]--

function scite_Files2(mask,single_mask)
  local f,path,cmd
  if  GTK then
	os.execute('ls -1 '..mask..' > '..tmpfile)
	f = io.open(tempfile)
    path = ''
  else
    mask = gsub(mask,'/','\\')
    _,_,path = find(mask,'(.*\\)')
	path=path or ''
	--[mhb] modified to support multiple mask
	if single_mask then 
		cmd = 'dir /b "'..mask..'" > "'..tempfile..'"'
	else 
		cmd = 'dir /b '..mask..' > "'..tempfile..'"' 
	end
--   if Execute then -- scite_other was found!
    if m_ext_version then -- [mhb] modified to use m_ext.dll: speed up and avoid black dos window
		cmd=(os.getenv('COMSPEC') or 'cmd.exe')..' /c '..cmd
		execwait(cmd,2)  -- SW_SHOWMINIMIZE=2; wait:true
    else
      os.execute(cmd)
    end
    f = io.open(tempfile)
  end
  local files = {}
  if not f then return files end
  for line in f:lines() do
     append(files,path..line)
  end
  f:close()
  return files
end


function scite_Files(mask)
  if not gui then
	return scite_Files2(mask,true)
  else -- using gui.files() may be faster 
	mask = gsub(mask,'/','\\')
    _,_,path = find(mask,'(.*\\)')
	path=path or ''
	local t=gui.files(mask) or {}
	local res={}
	table.sort(t)
	for _,v in ipairs(t) do
	  table.insert(res,path..v)
	end
	return res
  end
end


-- grab all directories in @path, excluding anything that matches @exclude_path
-- As a special exception, will also any directory called 'examples' ;)
function scite_Directories(path,exclude_pat)
    local cmd
    --print(path)
    if not GTK then
        cmd = dirmask(path..'\\*.',true)
    else
        cmd = dirmask(path,true)
    end
    path = path..dirsep    
    local f = scite_Popen(cmd)
    local files = {}
    if not f then return files end
    for line in f:lines() do
--        print(line)
        if GTK then
            if line:sub(-1,-1) == dirsep then
                line = line:sub(1,-2)
            else
                line = nil
            end
        end
        if line and not line:find(exclude_pat) and line ~= 'examples' then
            append(files,path..line)
        end
    end
    f:close()
    return files	
end

function scite_FileExists(f)
  local f = io.open(f)
  if not f then return false
  else
    f:close()
    return true
  end
end

function scite_CurrentFile()
    return props['FilePath']
end

function scite_DirectoryExists(path)
    if GTK then 
        return os.execute('test -d "'..path..'"') == 0
    else
        return true -- on windowns just skip test
    end
end



local loaded = {}
local current_filepath

-- this will quietly fail....
local function silent_dofile(f)
f = string.gsub(f,'\\','/') --[mhb] uncommented to make filenames unique
    if scite_FileExists(f) then
        if not loaded[f] then
            current_script=f --[mhb] 06/13/09
            dofile(f)
            loaded[f] = true
        end
        return true
    end
    return false
end

function scite_dofile(f)
    f = extman_path..'/'..f
    silent_dofile(f)
end

function scite_require(f)
    local path = lua_path..dirsep..f
    if not silent_dofile(path) then
        silent_dofile(current_filepath..dirsep..f)
    end
end





--[My Functions]:: 
-- [mhb] 06/05/09:  set property FILES_IN_SESSION to list of opened files
function set_files_in_session()
    local s=''
    for _,v in pairs(files_cache) do
        s=s..' "'..v..'"'
    end
    props['FILES_IN_SESSION']=s
end

-- [mhb] 06/13/09: to detect a function's name, useful for debugging
function get_func_name(func)
    if type(func)~='function' then return nil end
    for _,v in pairs(_G) do
        if v==func then
            return _
        end
    end
    return nil
end


-- [mhb] functions about filenames
function File_Ext(f)
  local i1,i2=string.find(f,'%..*$')
  if not i1 then return '';end
  return string.sub(f,i1+1,i2)
end

function File_NameExt(f)
  local i1,i2=string.find(f,slash..'[_%w]*%.[_%w]*$')
  if not i1 then return f;end
  return string.sub(f,i1+1,i2)
end

function File_Name(f)
  local x=File_NameExt(f)
  local i1,i2=string.find(x,'.',1,true)
  if not i1 then return x;end
  return string.sub(x,1,i2-1)
end


function load_script_list(script_list,path)
    if not script_list then 
      print('Error: no files found in '..path)
    else
      current_filepath = path
      for i,file in pairs(script_list) do
        if not scite_FileExists(file) then --[mhb] 05/28/09
            file=lua_path..dirsep..file
        end
        local msg='Loading '..file
	    if props['DEBUG_EXTMAN']=='1' then 
            print(msg,os.date());
        elseif (props['DEBUG_EXTMAN']=='2') and DoFunc then --[mhb] 04/24/09
            DoFunc('msgbox',msg) --show a messagebox before running
        end
        silent_dofile(file)
      end
    end	
end


function reload_extman()
   print('Reloading extman.lua ... ')
   loaded=nil
   silent_dofile(props['SciteDefaultHome']..'/extman.lua')
end


function reload_script()
   current_file = scite_CurrentFile()
   print('Reloading... '..current_file)
   loaded[current_file] = false
   silent_dofile(current_file)
   --[mhb] 05/21/09: to load .lua file for .lux file
   local f=current_file:gsub('%.lux','%.lua')
   if f==current_file then return; end
   print('Reloading... '..f)
   loaded[f] = false
   silent_dofile(f)
end



--To support splitting string via regular string delimeter
function split_s(s,re) --[mhb] revised 05/31/09: split-->split_s
	local i1 = 1
	local sz = #s
	local ls = {}
	while true do
		local i2,i3 = s:find(re,i1)
		if not i2 then
			append(ls,s:sub(i1))
			return ls
		end
		append(ls,s:sub(i1,i2-1))
		i1 = i3+1
		if i1 >= sz then return ls end
	end
end

--[mhb] added 05/30/09: to support generating lua tables from properties
local sep1=props['TABLE_SEP1']
local sep2=props['TABLE_SEP2']
if sep1=='' then sep1=';;' end
if sep2=='' then sep2='|' end

--[mhb] 05/31/09: adding cache of tables generated from properties
local _prop_tables={} 
function clear_prop_tables()
	_prop_tables={}
end
function prop2table(prop_name,recursive)
	local p=trim(prop_name)
	local res=_prop_tables[prop_name]
	if res then
		if props['CACHE_TABLES']~='0' then
			return res
		end
	end
    local s=props[p]
	s=string.gsub(s,'${([%w%._]+)}','$(%1)')
    local tbl=split_s(s,sep1)
	if tbl[#tbl]=='' then tbl[#tbl]=nil end
    for _,v in ipairs(tbl) do
		if v:match('^#~.*') then
			tbl[_]=nil
		else
			local k,s=string.match(v,'^([%w_]*)==>(.+)')
			if k and s then
				tbl[_]=nil
				tbl[k]=s
				_=k
				v=s
			end
			if v:find(sep2) then
				v=split_s(v..sep2,sep2) --[mhb] 06/06/09: v ?
				for __,vv in ipairs(v) do
					local kk,ss=string.match(vv,'^([%w_]*)==>(.+)')
					if kk and ss then
						v[__]=nil
						v[kk]=ss
					end
				end
				-- if v[#v]=='' then v[#v]=nil end
				if recursive then
					for __,vv in ipairs(v) do 
						local k=string.match(vv,'^@@([%w%._]*)$')
						if k then
							v[__]=prop2table(k,recursive)
						end
					end
				end
				tbl[_]=v
			else
				if recursive then
					local k=string.match(v,'^@@([%w%._]*)$')
					if k then
						tbl[_]=prop2table(k,recursive)
					end
				end
			end
		end
    end
	if #tbl>0 then 
		_prop_tables[prop_name]=tbl --[mhb] caching
	end
    return tbl
end

function set_cache_tables(on_off)
	props['CACHE_TABLES']=tostring(on_off)
end



--[Extman Util Functions]:: 
-- file must be quoted if it contains spaces!
function quote_if_needed(target)
    local quote = '"'
    if find(target,'%s') and sub(target,1,1) ~= quote then
        target = quote..target..quote
    end
    return target
end

function OnUserListSelection(tp,str)
  if _UserListSelection then 
     local callback = _UserListSelection 
     _UserListSelection = nil
     return callback(str)
  else return false end
end


local next_user_id = 13 -- arbitrary

-- the handler is always reset!
function scite_UserListShow(list,start,fn,sep)
--   local separators = {' ', ';', '@', '?', '~', ':','\255'} --[mhb]
  local separator
  separator =sep or '\255'
  s = table.concat(list, separator, start)
  if string.find(s,'?') then s=string.gsub(s,'?','\254') end --[mhb] 06/16/09 
  _UserListSelection = fn
  local pane = editor
  if not pane.Focus then pane = output end
  pane.AutoCSeparator = string.byte(separator)
  pane:UserListShow(next_user_id,s)
  pane.AutoCSeparator = string.byte(' ')
  return true
end


local function DispatchOne(handlers,arg)
  if #handlers==0 then return false; end
  if props['IS_READY']..props['DISABLE_EVENTS_UNTIL_READY']=='01' then return false; end --[mhb] 05/25/09
    
  local n=h_name[handlers]
  local q=n and #handlers>0 and props['DEBUG_EVENTS']=='1'
  if q then trace('\nEvent '..n..':\t'..(arg or 'nil')..'\n'); end

  for i,handler in pairs(handlers) do
    local fn = handler
    if _remove[fn] then
        handlers[i] = nil
       _remove[fn] = nil
    end
    if q then print('\t['..i..']',fn,funcs_table[fn]); end
    local ret = fn(arg)
    if ret then return ret end
  end
  return false
end

local function Dispatch4(handlers,arg1,arg2,arg3,arg4)
    for i,handler in pairs(handlers) do
        local fn = handler
        if _remove[fn] then
            handlers[i] = nil
            _remove[fn] = nil
        end
        local ret = fn(arg1,arg2,arg3,arg4)
        if ret then return ret end
    end
    return false
end

-- may optionally ask that this handler be immediately
-- removed after it's called
local function append_unique(tbl,fn,rem)
  local once_only
  if not fn then return nil;end --[mhb] 05/29/09
  
  --[mhb] 06/13/09: to cache functions 
  if type(fn)=='function' then
    funcs_table[fn]=current_script
  end
  
  if type(fn) == 'string' then
     once_only = fn == 'once'
     fn = rem
     rem = nil
     if once_only then 
        _remove[fn] = fn
    end  
  else
    _remove[fn] = nil
  end
  local idx 
  for i,handler in pairs(tbl) do
     if handler == fn then idx = i; break end
  end
  if idx then
    if rem then
      table.remove(tbl,idx)
    end
  else
    if not rem then
      append(tbl,fn)
    end
  end        
end

--[Lua Events]::

-- these are the standard SciTE Lua callbacks  - we use them to call installed extman handlers!
function OnMarginClick()
  return DispatchOne(_MarginClick)
end

function OnDoubleClick()
  return DispatchOne(_DoubleClick)
end

function OnSavePointLeft()
  return DispatchOne(_SavePointLeft)
end

function OnSavePointReached()
  return DispatchOne(_SavePointReached)
end

function OnChar(ch)
  return DispatchOne(_Char,ch)
end

function OnSave(file)
  return DispatchOne(_Save,file)
end

function OnBeforeSave(file)
  return DispatchOne(_BeforeSave,file)
end

function OnSwitchFile(file)
  return DispatchOne(_SwitchFile,file)
end


function OnOpen(file)
  if file~='' and not files_cache[file] then
    files_cache[file]=file
    set_files_in_session()
  end
  return DispatchOne(_Open,file)
end

-- new with 1.74
function OnKey(key,shift,ctrl,alt)
    return Dispatch4(_Key,key,shift,ctrl,alt)
end

function OnDwellStart(pos,s)
    return Dispatch4(_DwellStart,pos,s)
end

function OnClose()
  if files_cache[file] then
    files_cache[file]=nil
    set_files_in_session()
  end
  return DispatchOne(_Close)
end



props['IS_READY']='0' --[mhb] 05/25/09
function OnUpdateUI()
  if props['IS_READY']=='0' then
    props['IS_READY']='1' --[mhb] 05/25/09
    DispatchOne(_Open,props['FilePath']) --[mhb] 06/05/09
  end
  if editor.Focus then
    return DispatchOne(_UpdateUI)
  else
    return false
  end
end

--[Scite Events]:: 

-- this is how you register your own handlers with extman
function scite_OnMarginClick(fn,rem)
  append_unique(_MarginClick,fn,rem)
end

function scite_OnDoubleClick(fn,rem)
  append_unique(_DoubleClick,fn,rem)
end

function scite_OnSavePointLeft(fn,rem)
  append_unique(_SavePointLeft,fn,rem)
end

function scite_OnSavePointReached(fn,rem)
  append_unique(_SavePointReached,fn,rem)
end

function scite_OnOpen(fn,rem)
  append_unique(_Open,fn,rem)
end

function scite_OnSwitchFile(fn,rem)
  append_unique(_SwitchFile,fn,rem)
end

function scite_OnBeforeSave(fn,rem)
  append_unique(_BeforeSave,fn,rem)
end

function scite_OnSave(fn,rem)
  append_unique(_Save,fn,rem)
end

function scite_OnUpdateUI(fn,rem)
  append_unique(_UpdateUI,fn,rem)
end

function scite_OnChar(fn,rem)
  append_unique(_Char,fn,rem)  
end

function scite_OnOpenSwitch(fn,rem)
  append_unique(_OpenSwitch,fn,rem)
end

--new 1.74
function scite_OnKey(fn,rem)
    append_unique(_Key,fn,rem)
end

function scite_OnDwellStart(fn,rem)
    append_unique(_DwellStart,fn,rem)
end

function scite_OnClose(fn,rem)
    append_unique(_Close,fn,rem)
end

function buffer_switch(f)
--- OnOpen() is also called if we move to a new folder
   if not find(f,'[\\/]$') then
      DispatchOne(_OpenSwitch,f)
   end
end


--[Extman String Functions]:: 

 local word_start,in_word,current_word
-- (Nicolas) this is in Ascii as SciTE always passes chars in this "encoding" to OnChar
local wordchars = '[A-Za-z?Ýà-ÿ]'  -- wuz %w

 local function on_word_char(s)
     if not in_word then
        if find(s,wordchars) then  
      -- we have hit a word!
         word_start = editor.CurrentPos
         in_word = true
         current_word = s
      end
    else -- we're in a word
   -- and it's another word character, so collect
     if find(s,wordchars) then   
       current_word = current_word..s
     else
       -- leaving a word; call the handler
       local word_end = editor.CurrentPos
       DispatchOne(_Word, {word=current_word,
               startp=word_start,endp=editor.CurrentPos,
               ch = s
            })     
       in_word = false
     end   
    end 
  -- don't interfere with usual processing!
    return false
  end  

function scite_OnWord(fn,rem)
  append_unique(_Word,fn,rem)   
  if not rem then
     scite_OnChar(on_word_char)
  else
     scite_OnChar(on_word_char,'remove')
  end
end

local last_pos = 0

function get_line(pane,lineno)
    if not pane then pane = editor end
    if not lineno then
        local line_pos = pane.CurrentPos
        lineno = pane:LineFromPosition(line_pos)-1
    end
    -- strip linefeeds (Windows is a special case as usual!)
    local endl = 2
    if pane.EOLMode == 0 then endl = 3 end
    local line = pane:GetLine(lineno)
    if not line then return nil end
    return string.sub(line,1,-endl)
end

-- export this useful function...
scite_Line = get_line

local function on_line_char(ch,was_output)
    if ch == '\n' then
        local in_editor = editor.Focus
        if in_editor and not was_output then
            DispatchOne(_LineEd,get_line(editor))
            return false -- DO NOT interfere with any editor processing!
        elseif not in_editor and was_output then
            DispatchOne(_LineOut,get_line(output))
            return true -- prevent SciTE from trying to evaluate the line
        end
    end
    return false
end

local function on_line_editor_char(ch)
  return on_line_char(ch,false)
end

local function on_line_output_char(ch)
  return on_line_char(ch,true)
end

local function set_line_handler(fn,rem,handler,on_char)
  append_unique(handler,fn,rem)   
  if not rem then
     scite_OnChar(on_char)
  else
     scite_OnChar(on_char,'remove')
  end
end

function scite_OnEditorLine(fn,rem)
--   set_line_handler(fn,rem,_LineEd,on_line_editor_char)  
end
 
function scite_OnOutputLine(fn,rem)
  set_line_handler(fn,rem,_LineOut,on_line_output_char)
end



function extman_Path()
    return extman_path
end

function split(s,delim)
    res = {}
    if not s then return {} end --[mhb] 05/31/09
    if not delim then print(s) return nil end
    while true do
        p = find(s,delim)
        if not p then
            append(res,s)
            return res 
        end
        append(res,sub(s,1,p-1))
        s = sub(s,p+1)
    end
end

function splitv(s,delim)
    return unpack(split(s,delim))
end

local idx = 10
local shortcuts_used = {}
local alt_letter_map = {}
local alt_letter_map_init = false
local name_id_map = {}

--[Menu Commands]:: 

local function set_command(name,cmd,mode)
     local _,_,pattern,md = find(mode,'(.+){(.+)}')
     if not _ then
        pattern = mode
        md = 'savebefore:no'
     end
     local which = '.'..idx..pattern
     props['command.name'..which] = name
     props['command'..which] = cmd     
     props['command.subsystem'..which] = '3'
     props['command.mode'..which] = md
     name_id_map[name] = 1100+idx
     return which
end

local function check_gtk_alt_shortcut(shortcut,name)
   -- Alt+<letter> shortcuts don't work for GTK, so handle them directly...
   local _,_,letter = shortcut:find('^Alt%+([A-Z])$')
   if _ then
        alt_letter_map[letter:lower()] = name		    
        if not alt_letter_map_init then
            alt_letter_map_init = true
            scite_OnKey(function(key,shift,ctrl,alt)
                if alt and key < 255 then
                    local ch = string.char(key)
                    if alt_letter_map[ch] then
                        scite_MenuCommand(alt_letter_map[ch])
                    end
                end
            end)
        end
    end
end

local function set_shortcut(shortcut,name,which)
    if shortcut == 'Context' then
        local usr = 'user.context.menu'
        if props[usr] == '' then -- force a separator
            props[usr] = '|'
        end
        props[usr] = props[usr]..'|'..name..'|'..(1100+idx)..'|'
    else
       local cmd = shortcuts_used[shortcut]
       if cmd then
            print('Error: shortcut already used in "'..cmd..'"')
       else
           shortcuts_used[shortcut] = name
           if GTK then check_gtk_alt_shortcut(shortcut,name) end
           props['command.shortcut'..which] = shortcut
       end
     end
end

-- allows you to bind given Lua functions to shortcut keys
-- without messing around in the properties files!
-- Either a string or a table of strings; the string format is either
--      menu text|Lua command|shortcut
-- or
--      menu text|Lua command|mode|shortcut
-- where 'mode' is the file extension which this command applies to,
-- e.g. 'lua' or 'c', optionally followed by {mode specifier}, where 'mode specifier'
-- is the same as documented under 'command.mode'
-- 'shortcut' can be a usual SciTE key specifier, like 'Alt+R' or 'Ctrl+Shift+F1',
-- _or_ it can be 'Context', meaning that the menu item should also be added
-- to the right-hand click context menu.
function scite_Command(tbl)
  if type(tbl) == 'string' then
     tbl = {tbl}
  end
  for i,v in pairs(tbl) do
     local name,cmd,mode,shortcut = splitv(v,'|')
     if not shortcut then
        shortcut = mode
        mode = '.*'
     else
        mode = '.'..mode
     end
     -- has this command been defined before?
     local old_idx = 0
     for ii = 10,idx do
        if props['command.name.'..ii..mode] == name then old_idx = ii end
     end
     if old_idx == 0 then	 
        local which = set_command(name,cmd,mode)
         if shortcut then
            set_shortcut(shortcut,name,which)
        end
        idx = idx + 1
    end
  end
end

-- use this to launch Lua Tool menu commands directly by name
-- (commands are not guaranteed to work properly if you just call the Lua function)
function scite_MenuCommand(cmd)
    if type(cmd) == 'string' then
        cmd = name_id_map[cmd]
        if not cmd then return end
    end
    scite.MenuCommand(cmd)
end

--[Disable/Enable Lua Events]
local events={
'OnUserListSelection','OnMarginClick','OnDoubleClick','OnSavePointLeft','OnSavePointReached',
'OnChar','OnSave','OnBeforeSave','OnSwitchFile','OnOpen','OnKey','OnDwellStart','OnClose','OnUpdateUI'
}
function show_events()
  local s=''
  for i,v in ipairs(events) do s=s..v..'='..tostring(_G[v])..';' end
  print(s)
  DoFunc('msgbox',s)
end
local _E={}
function save_events()
    for _,v in ipairs(events) do _E[v]=_G[v] end
end
function set_events(E)
  if not E then E=_E end
  OnUserListSelection=E.OnUserListSelection
  OnMarginClick=E.OnMarginClick
  OnDoubleClick=E.OnDoubleClick
  OnSavePointLeft=E.OnSavePointLeft
  OnSavePointReached=E.OnSavePointReached
  OnChar=E.OnChar
  OnSave=E.OnSave
  OnBeforeSave=E.OnBeforeSave
  OnSwitchFile=E.OnSwitchFile
  OnOpen=E.OnOpen
  OnKey=E.OnKey
  OnDwellStart=E.OnDwellStart
  OnClose=E.OnClose
  for _,v in ipairs(events) do _G[v]=E[v] end
end

local E_pn='USE_EVENT_HANDLERS'
if tostring(props[E_pn])=='' then props[E_pn]='1' end
function toggle_events()
  if props[E_pn]=='1' then 
    props[E_pn]='0'
    set_events({})
  else
    props[E_pn]='1'
    set_events(_E)
  end
  show_events()
end

--[Register SciTE Events]:: 
scite_OnOpen(buffer_switch)
scite_OnSwitchFile(buffer_switch)

if not scite_DirectoryExists(lua_path) then
    print('Error: directory '..lua_path..' not found')
end

