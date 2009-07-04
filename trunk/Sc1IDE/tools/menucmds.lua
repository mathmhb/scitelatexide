-- by [mathmhb]: to be documented ...
-- require m_ext.lua
menucmds={}
usercmds={}
helpcmds={}
--[mhb] 06/13/09: To support dynamic lexers
lexer_settings={}

--[mhb]added: 01/11/09 To support assigning a main file
local cn_set_mainfile=props['CN_SET_MAINFILE']
local mainfile=''
function set_mainfile()
	local curfile=props['FilePath']
	local s='command.checked.'..tostring(cn_set_mainfile)..'.*'
	if mainfile==curfile then
		print('Unsetting Mainfile: '..mainfile)
		mainfile=''
		props[s]='0'
	else
		mainfile=curfile
		props[s]='1'
		print('Setting Mainfile: '..mainfile)
	end
end
--[mhb] 06/28/09 : to support compiling mainfile via corresponding compile command
function compile_mainfile()
	if mainfile=='' then
		print('Please Set Mainfile first!')
		return
	end
	local curfile=props['FilePath']
	if mainfile~='' and curfile~='' then
		scite.Open(mainfile)
	end
	local typ=props['FileType']
	print('Compiling Mainfile: ',props['FilePath'],typ)
	local cmd=props['COMPILEMAIN_'..typ]
	if cmd=='' then
		scite.MenuCommand(IDM_COMPILE)
	elseif cmd=='@build' then
		scite.MenuCommand(IDM_BUILD)
	elseif cmd=='@go' then
		scite.MenuCommand(IDM_GO)
	else
		shellexec(cmd)
	end
	if mainfile~='' and curfile~='' then
		scite.Open(curfile)
	end
end

local last_shortcut=''

--[mhb] added: 01/18/09 To support dynamic file types determined from file contents
ftype_patterns={
	tex={'\\documentclass','\\documentstyle'},
	cpp={'#define','#include','main%s*%(','/*'},
}
local dyn_files={} --this table records files with dynamic file types
function check_ftype_from_line(line)
	if not line then return nil; end
	for typ,tbl in pairs(ftype_patterns) do
		if type(tbl)=='string' then
			tbl={tbl}
		end
		if type(tbl)=='table' then
			for _,v in ipairs(tbl) do
				if string.find(line,v) then
					return typ
				end
			end
		end
	end
	return nil
end

local max_test_lines=20
function test_filetype()
	if tostring(props['AUTO_TEST_FILETYPE'])~='1' then
		return nil
	end
	if tostring(props['IS_READY'])~='1' then
		return nil
	end
	for i=0,max_test_lines do
		local line=editor:GetLine(i)
		local typ=check_ftype_from_line(line)
		if typ then 
			return typ; 
		end
		if i >= editor.LineCount-2 then 
			return nil; 
		end
	end
	return nil
end

-- [mhb] 06/11/09: 
local f_log=nil
function pv_(p,val)
	props[p]=tostring(val)
	if f_log and val~='' and val~=nil then f_log:write(p..'='..val..'\n') end
end


--[mhb] 06/13/09: to support dynamic lexers
local lexer_properties=prop2table('LEXER_PROPERTIES')
function save_lexer_settings(lex,def_lex)
    local res={}
    for _,v in ipairs(lexer_properties) do
        local s1=v:gsub('.lexer','.'..lex)
        local t=props[s1] or ''
        if (t=='') and (lex~=def_lex) then
            local s2=v:gsub('.lexer','.'..def_lex)
            t=props[s2] or ''
        end
        res[v]=t
    end
    lexer_settings[lex]=res
    return res
end

function set_lexer_settings(lex,res)
	if lex=='' or res==nil or res=={} then return;end
    for _,v in pairs(res) do
        local s=_:gsub('.lexer','.'..lex)
        pv_(s,v)
    end
end

--To allow customized api,abbr and properties paths
local api_path=scite_GetProp('API_PATH','$(SciteDefaultHome)/')
local abbr_path=scite_GetProp('ABBR_PATH','$(SciteDefaultHome)/')

--To support easily setting compile, build, go, help, print commands
function set_compiler_typ(typ)
	local m='.$(file.patterns.'..typ..')'
	if typ=='*' then m='.*' end
	local tbl={'compile','build','go','help','print'}
	for _,v in ipairs(tbl) do
		local p=string.upper(v)..'_'..typ
		local res=prop2table(p) or {}
		if #res==1 and v=='help' and not string.find(res[1],'%$%(') then
			if string.find(res[1],'%.chm') then 
				res[2]=4
				res[1]='$(CurrentWord)!'..res[1]
			elseif string.find(res[1],'%.hlp') then 
				res[2]=5
				res[1]='$(CurrentWord)!'..res[1]
			end
		end
		if #res>0 then pv_('command.'..v..m,res[1]) end
		if #res>1 then pv_('command.'..v..'.subsystem'..m,res[2]) end
		if #res>2 then pv_('command.'..v..'.directory'..m,res[3]) end
	end
end

--To support easy configuration for filepatterns: auto set file.patterns,lexer,api
filetypes={}
function add_filetype(v)
--old interface: function add_filetype(n,exts,des,api,abbr)
	local mask,n,exts,des,api,abbr,hotkey,lex
	n,exts,des,api,abbr,hotkey,lex=unpack(v)
	if not exts then exts=n;end
	if not des then des=string.upper(string.sub(n,1,1))..string.sub(n,2,-1);end
	
	local m='.$(file.patterns.'..n..')'
	if not api then
		api=props['api.'..n..')'] or ''
		if api=='' then api=n..'.api';end
	end
	if not string.find(api,'[/\\]') then
		api=api_path..api;
		api=string.gsub(api,';',';'..api_path)
	end
	if not abbr then
		abbr=props['abbreviations'..m] or ''
		if abbr=='' then abbr=n..'.abbr';end
	end
	if not string.find(abbr,'[/\\]') then
		abbr=abbr_path..abbr;
		abbr=string.gsub(abbr,';',';'..abbr_path)
	end
	
	if string.find(exts,'*',1,true) then --[mhb] 04/24/09
		mask=exts
	else
		mask=string.gsub(exts,'%s*(%w+)%s*','*.%1;')
		mask=string.gsub(mask,';$','')
	end
	
	pv_('file.patterns.'..n,mask)
	pv_('filter.'..n,des..' ('..exts..')|$(file.patterns.'..n..')|')
	pv_('api'..m,api)
	pv_('abbreviations'..m,abbr)
	
	lex=v.lexer or lex
	if lex then
		pv_('LEXER_'..n,lex)
		pv_('lexer'..m,lex)
		local kw=props['KEYWORDS_'..n]
		if kw~=nil and kw~='' then
			pv_('keywords'..m,'$(KEYWORDS_'..n..')')
			for i=2,9 do
				pv_('keywords'..i..m,'$(KEYWORDS'..i..'_'..n..')')
			end
		end
		save_lexer_settings(n,lex) --[mhb] 06/13/09
	end
	
	props['SOURCE_FILES']=props['SOURCE_FILES']..';'..mask --[mhb] 01/09/09
	props['GET_WILD_FILE_TYPES']=props['GET_WILD_FILE_TYPES']..';'..n --[mhb] 06/23/09 
	--[mhb] 06/11/09
	if (des~='') and (des:sub(1,1)~='#') then
		local ext=n
		props['MENU_LANGUAGE']=props['MENU_LANGUAGE']..des..'|'..ext..'|'..(key or '')..'|'
	end
	
	set_compiler_typ(n) --[mhb] 06/14/09: to support easy settings of compile/build/go commands
end


function add_filetypes(tbl)
	lexer_settings={}
	props['MENU_LANGUAGE']='' --[mhb] 06/11/09
	props['SOURCE_FILES']=''  --[mhb] 06/11/09
	props['GET_WILD_FILE_TYPES']=''  --[mhb] 06/23/09 
	local n,exts,des,lexer,api,abbr
	for _,v in ipairs(tbl) do
		if not v[1] then return;end
		add_filetype(v)
	end
	pv_('MENU_LANGUAGE',props['MENU_LANGUAGE'])
	pv_('SOURCE_FILES',props['SOURCE_FILES'])
	pv_('GET_WILD_FILE_TYPES',props['GET_WILD_FILE_TYPES'])
end


function mask_of_exts(exts) --[mhb] 01/18/09
	mask=string.gsub(exts,'%s*(%w+)%s*','*.%1;')
	mask=string.gsub(mask,';$','')
	return mask
end
function current_filetype()
	local n,exts,des,api,abbr
	for _,v in ipairs(filetypes) do
		n,exts,des,api,abbr=unpack(v)
		if not n then return nil;end
		if not exts then exts=n;end
		if not api then api=n..'.api';end
		if not des then des=string.upper(string.sub(n,1,1))..string.sub(n,2,-1);end
		if curfile_match(exts,true) then return n,exts,des,api;end
	end
	
	--[mhb] added: to support auto detection of file types from file contents
	local fnam=props['FileNameExt']
	local typ=dyn_files[fnam]
	if typ then 
		return typ
	else
		typ=test_filetype() or 'text'
		dyn_files[fnam]=typ
		return typ
	end
	return nil
end


--[mhb] 01/19/09: To support using dynamic file type 
function use_dyn_ftype()
	if tostring(props['AUTO_TEST_FILETYPE'])~='1' then
		return nil
	end
	if props['IGNORE_DYN_FTYPE']=='1' then return; end
	local fnam=props['FileNameExt']
	if fnam=='' then return;end
	local ftyp=dyn_files[fnam]
	if not ftyp then return; end
	if ftyp=='text' then return; end
	local msg=s_('Do you want to use the lexer detected from file contents?')
	local k=get_choice(msg..' ['..fnam..'==>'..ftyp..']',{s_('YES'),s_('NO')},250)
	if (k~=1) then return; end
	
	local old_filepat=props['file.patterns.'..ftyp] or ''
	if string.find(old_filepat,fnam) then return; end
	props['file.patterns.'..ftyp]=fnam..';'..old_filepat
	print('Set file ['..fnam..'] to type ['..ftyp..'] via its contents!')
	local pos=editor.CurrentPos
	local fn=props['FilePath']
	props['IGNORE_DYN_FTYPE']='1'
 	scite.MenuCommand(IDM_SAVE)
 	scite.Open(fn)
	props['IGNORE_DYN_FTYPE']=''
 	editor:GotoPos(pos)
	SetLanguage(ftyp) --[mhb] 03/17/09 14:37:55
end

-- To support add menus easily
function inc_str(s,d)
	if not s or string.len(tostring(s))<4 then return s end
	return string.sub(s,1,-2)..string.char(string.byte(s,-1)+d)
end

submenu_idx=100
function add_menu(ftype,idx,menu,parent)
	local mode,which,name,cmd,shortcut,execmode,savebefore,directory,toolbar_no,is_usermenu
	mode='.'..ftype
	if not (ftype=='*') then mode='.$(file.patterns.'..ftype..')';end
	which = '.'..tostring(idx)..mode
	name=menu[1]
    if type(name)=='nil' then return;end
	if name=='' then return end
	cmd=menu[2]
	if type(cmd)=='nil' then return;end
	if cmd=='' then return end
	
	--to support submenu for scite [instanton]: 2008-08-14
	if type(cmd)=='table' then
		subidx=tonumber(menu[3])
		if type(subidx)=='nil' then
			subidx=submenu_idx
		end
		pv_('command.submenu.name'..which,tostring(name))
		for i,submenu in ipairs(cmd) do
			add_menu(ftype,i+subidx-1,submenu,idx)
			submenu_idx=submenu_idx+1
		end
		return
	end

	if string.sub(cmd,1,1)==' ' then cmd=comspec..cmd;end
	
	pv_('command.name'..which,name)
	pv_('command'..which,cmd)

	if menu[3] then
		shortcut=tostring(menu[3])
		if shortcut=='1' then
			shortcut=inc_str(last_shortcut,1)
		end
		if string.len(shortcut)>1 then
			last_shortcut=shortcut
			pv_('command.shortcut'..which,shortcut)
		end
	end
	
	if menu[4] then
		execmode=tostring(menu[4])
		pv_('command.subsystem'..which,execmode)
	end
	
	if menu[5] then
		savebefore=tostring(menu[5])
		pv_('command.save.before'..which,savebefore)
	end
	
--~ 	pv_('command.directory'..which,directory or '$(Filedir)')
--~ 	pv_('command.quiet'..which,'yes')

	--to record number of this menu (set to property CN_id)
	if menu['id'] then --[mhb] 01/30/09
		id=string.upper(tostring(menu['id']))
		local s_idx=string.upper(tostring(idx))
		if idx<10 then
			s_idx='00'..s_idx
		elseif idx<100 then
			s_idx='0'..s_idx
		end
		pv_('CN_'..id,s_idx) --[mhb] 06/15/09
		menu['id']=nil --[mhb] 06/15/09
	end
	
	--to support toolbars for scite [instanton]: 2008-08-14, revised 06/15/09
	if menu['toolbar'] then
		props['TOOLBAR.'..ftype]=props['TOOLBAR.'..ftype]..tostring(name)..'|'..tostring(9000+idx)..'|'..menu['toolbar']..'|'
		menu['toolbar']=nil
	end

	--to support user context menu, revised 06/15/09
	if menu['usermenu'] then
		props['USERMENU.'..ftype]=props['USERMENU.'..ftype]..tostring(name)..'|'..tostring(9000+idx)..'|'
		menu['usermenu']=nil
	end

	--to support extra properties (e.g. separator) for scite [instanton]: 2008-08-14
	for _,v in pairs(menu) do
		if type(_)=='string' then
			pv_('command.'.._..which,v)
		end
	end

	--to support submenu for scite [instanton]: 2008-08-14
	if type(parent)=='number' then
		pv_('command.parent'..which,tostring(parent))
		--print('command.parent'..which,tostring(parent),name,cmd)
	end
end

function add_menus(ftype,menus,i0)
  props['TOOLBAR.'..ftype]=''
  props['USERMENU.'..ftype]='' --[mhb]
  for i,menu in ipairs(menus) do
	add_menu(ftype,i+i0-1,menu)
  end
  pv_('TOOLBAR.'..ftype,props['TOOLBAR.'..ftype])
  pv_('USERMENU.'..ftype,props['USERMENU.'..ftype])
end

function update_menus()
	local menu_all=prop2table('MENU_*',true)
	local i0=tonumber(props['MENU_NUM_*'])
	if (not i0) or (i0==0) then i0=40 end
	
	if #menu_all>0 then
		add_menus('*',menu_all,i0)
	end
	for _,v in ipairs(filetypes) do
		local typ=v[1]
		local menu=prop2table('MENU_'..typ,true)
		local i0=tonumber(props['MENU_NUM_'..typ])
		if not i0 then i0=0 end
		if #menu>0 then
			if tostring(props['DEBUG_MENUCMDS'])=='1' then
				print(typ)
				print_r(menu)
			end
			add_menus(typ,menu,i0)
		end
	end
end


--To support changing directory to folder of current file
function m_chdir(dir)
  if DoFunc then
  DoFunc('SetCurrentDirectory@kernel32.dll',dir);
  end
end

--To support user cmdline easily: $4 $1 $2 $3
local ext=''
webroot='' -- set it to your web root directory
function set_parameters(file)
  -- 01/19/09 add new properties on file attributes
  local attr=get_fileattr(props['FilePath'])
  props['FileAttrNumber']=attr
  props['FileAttrString']=file_attr_string(attr) 
  
  m_chdir(props['FileDir']) -- force to change directory to current file directory
  if mainfile=='' then 
    props['MainFile']=props['FilePath']
  else
    props['MainFile']=mainfile
  end
  
  --local typ=current_filetype() 
  local typ=props['FileType']

  --props['FileType']=typ -- provides a new property for use in statusbar or other lua files
  local lex=props['lexer.$(file.pattern.'..typ..')']
  lex=props['LEXER_'..typ]
  local res=lexer_settings[typ]
  set_lexer_settings(lex,res) --[mhb] 06/13/09: to support dynamic lexers
  
  props['Lexer']=editor.Lexer or ''-- provides a new property for use in statusbar or other lua files
  props['FileWebPath']=get_relative_path(webroot)
  
  
  props['2']=' '..props['FileNameExt']..' ' --props['FilePath']
  if props['FileExt']~=ext then
	usercmds[ext]=props['1']
	ext=props['FileExt']
	props['1']=usercmds[ext] or props['COMPILE_'..ext] or '' --[mhb] 04/23/09
	if props['1']=='' then props['1']=' start ';end
  end
end
function run_usercmd(...)
	local cmd
	cmd=props['1']..props['2']..props['3']..props['4']
	if not string.find(props['1'],'start ',1,true) then
		cmd=cmd..' && pause'
	end
	print('Running: '..cmd)
	os.execute(cmd)
	print('Done.')
end

--scite_OnOpenSwitch(set_parameters)
--scite_OnSave(set_parameters)
--scite_OnOpen(use_dyn_ftype) -- [mhb] 01/19/09: updates current dynamic file type


--To support properties selecting easily (such as FilePath,Date,...)
properties={}
function sel_prop(prop)
	props['CurrentDate']=os.date('%x')
	props['CurrentTime']=os.date('%X')
	props['CurrentDateTime']=os.date('%c')
	local s=props[prop]
	editor:insert(editor.CurrentPos, s);
	editor:GotoPos(editor.CurrentPos + string.len(s));
end
function select_properties()
	scite_UserListShow(properties,1,sel_prop)
end

--To support search selection or locate patterns (e.g. functions, labels, ...) easily
function find_selection()
	output:ClearAll()
	local res=findall(editor:GetSelText(),true,true)
end

patterns={}
function sel_pattern(w)
	local j,line
	j=string.find(w,':',1,true)
	if not j then return;end
	line=tonumber(string.sub(w,1,j-1))-1
	--print(editor:GetLine(line))
	editor:GotoLine(line)
	if not editor.FoldExpanded[line] then
		editor:ToggleFold(line)
	end
	if not editor.FoldExpanded[line+1] then
		editor:ToggleFold(line+1)
	end
end
function select_patterns()
	sel_text=editor:GetSelText();-- if text is selcted, then find_selection; otherwise, search and choose patterns
	if string.len(sel_text)>0 then
		find_selection()
		return
	end
	local pat=patterns[props['FileType']]
	if not pat then
		print('Please add an entry for filetype ['..props['FileType']..'] in settings [patterns=...] of menucmds.lux as the example. ')
		return;
	end
	local found_patterns=findall(pat,true)
	if not found_patterns then
		print('I cannot find any line containing the following pattern: \n',unpack(pat))
		return
	end
	if not found_patterns.w then return;end
	if table.getn(found_patterns.w)==0 then
		print('I cannot find any line containing the following pattern: \n',unpack(pat))
		return;
	end
	scite_UserListShow(found_patterns.w,1,sel_pattern)
end

--To support selecting config files easily (such as menucmds.lux,...)
configfiles={'menucmds.lux'}
function sel_cfgfile(f)
	d=props['ext.lua.directory'] or ''
	if d=='' then
		d=props['SciteDefaultHome']..slash..'scite_lua'
	end
	d=d:gsub('/',slash)
	if not string.find(f,':') then
		f=d..slash..f
	end
	scite.Open(f)
	print('You are editing config file ['..f..'].\n Please restart the editor to make your changes in effect!')
end
function select_configfiles()
	scite_UserListShow(configfiles,1,sel_cfgfile)
end
--[mhb] 05/27/09: edit menucmds.lux
function edit_menucmds()
	print('This function is outdated! Now you can directly edit settings in menucmds.properties and tools-*.properties!')
end


--To support selecting related files easily (e.g. switching between c/c++ programs with header files)
relatedfiles={}
relatedexts={'c cpp cxx h hpp'}
function get_relatedfiles()
  local files={}
  local name,ext,mask,vv,debug_info
  ext=props['FileExt']
  name=props['FileName']
  debug_info='relatedexts={'
  for _,v in ipairs(relatedexts) do
    vv=' '..v..' '
	debug_info=debug_info.."\n\t'"..v.."',"
	mask=string.gsub(vv,' ','  ')
	mask=string.gsub(mask,' (%w+) ',' "'..name..'.%1"') --[mhb] 02/01/09
	if string.find(string.lower(vv),' '..string.lower(ext)..' ') then
	  files=scite_Files2(mask)
	  break
	end
  end
  debug_info=debug_info..'\n}'
  if table.getn(files)==0 then return files,debug_info;end
  local rfiles=files
  for _,v in ipairs(files) do
    if v==name..'.'..ext then table.remove(rfiles,_);end
  end
  return rfiles,debug_info
end
function sel_relfile(f)
	scite.Open(f)
end
function select_relatedfiles()
	local debug_info
	relatedfiles,debug_info=get_relatedfiles()
	if table.getn(relatedfiles)==0 then
		print('I cannot find related files! Related files are defined by [relatedexts=...] in "menucmds.lux".\n Current settings of relatedexts:')
		print(debug_info)
	elseif table.getn(relatedfiles)==1 then
		scite.Open(relatedfiles[1])
	else
		scite_UserListShow(relatedfiles,1,sel_relfile)
	end
end
function list_relatedfiles()
	local files={}
	local  name=props['FileName']
	files=scite_Files2(name..'.*')
	for _,v in ipairs(files) do
		print(v..':1:')
	end
end

--To support help files easily
--[mhb] modified 04/05/09: to allow each file type has a corresponding help files
function sel_helpfile(file)
	local cmd=file
	set_parameters()
	props['CurSel']=get_cursel(editor)
--~ 	for _,v in pairs(help_list) do
--~ 		if string.find(v,file) then cmd=v;break;end
--~ 	end
	local get_prop=function(s) return props[s];end
	cmd=string.gsub(cmd,'%$%((%w+)%)',get_prop)
	print('Opening ',cmd)
	shellexec(cmd)
end
function get_helpdocs()
	local t=props['FileType']
	local p='HELPCMDS_'..t
	if props[p]=='' then p='HELPCMDS_*' end
	local res=prop2table(p)
	return res
end
function select_helpfiles()
	local help_list=get_helpdocs()
	scite_UserListShow(help_list,1,sel_helpfile)
end

--To support search engines or favorite websites
default_browser='' -- using system default browser associated with http protocol
websites={google='http://www.google.com/search?q=%s',baidu='http://www.baidu.com/s?wd=%s'}
function sel_web(w)
	local cmd,sel=websites[w],editor:GetSelText()
	local get_prop=function(s) return props[s];end
	cmd=string.gsub(cmd,'%$%((%w+)%)',get_prop)
	if sel=='' then sel=props['CurrentWord'];end
	--sel=string.gsub(sel,' ','%32')
	cmd=string.gsub(cmd,'%%s',sel)
	if default_browser~='' then cmd=default_browser..' '..cmd;end
	shellexec(cmd)
end
function select_websites()
	local webnames=get_list(websites)
	table.sort(webnames)
	scite_UserListShow(webnames,1,sel_web)
end

--To support easily invoke various lua functions/scripts
lua_tools={}
function sel_lua_tool(m)
	local s=lua_tools[m]
	if type(s)=='string' then
		dostring(s)
	elseif type(s)=='table' then
		local n,t=get_list(s)
		local i=get_choice('',n,120)
		if type(t[i])=='string' then dostring(t[i]);end
	end
end
function select_lua_tools()
	local menus,scripts=get_list(lua_tools)
	table.sort(menus)
	if table.maxn(menus)>0 then
		--scite_UserListShow(menus,1,sel_lua_tool)
		local msg=''
		local m=get_choice(msg,menus,120)
		if menus[m] then sel_lua_tool(menus[m]);end
	else
		print('Please set [lua_tools=...] in menucmds.lux!')
	end
end



--To support scripting with Lua easily
function run_me()
	dofile(props['FilePath'])
end
function run_selection()
	dostring(props['CurrentSelection'])
end
function eval_selection()
	dostring('print('..props['CurrentSelection']..')')
end
function eval_sel_property()
	print(props[editor:GetSelText()])
end

function reload_menucmds()
	props['CACHE_TABLES']='0'
	clear_prop_tables()
	local lua_dir=(props['ext.lua.directory'] or props['SciteDefaultHome']..'\\tools')..'/'

	local log_file=props['SciteDefaultHome']..'/menucmds.cache.properties'
	f_log=nil
	if tostring(props['GEN_MENU_CACHE'])=='1' or (not f_exist(log_file)) then
		f_log=io.open(log_file,'w')
		print('Generating file '..log_file..' for you to use it if you disable menucmds.lua :-)')
	end
	
	filetypes=prop2table('FILE_TYPES')
	properties=prop2table('SCITE_PROPERTIES')
	relatedexts=prop2table('RELATED_EXTS')
	websites=prop2table('WEB_SITES')
	patterns=prop2table('FUNC_PATTERNS')

-- 	if f_log then
	add_filetypes(filetypes)
	update_menus()
-- 	end

	if f_log then 
		f_log:close() 
		f_log=nil 
	end
	props['CACHE_TABLES']='1'
end

props['GEN_MENU_CACHE']='0'
reload_menucmds()
props['GEN_MENU_CACHE']='1'

