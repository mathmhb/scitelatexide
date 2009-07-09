--[[
Ver 9: add chdir();make findall() display compact;
Written by mathmhb, copyright.
1. This file provides easy call of any Win32 API. e.g.:
	DoFunc('MessageBoxA@user32.dll',0,'Hello,World!','Hello',3)
	DoFunc('MessageBeep@user32.dll',0)
	DoFunc('WinExec@kernel32.dll','mspaint.exe',3)
	DoFunc('SetCurrentDirectory@kernel32.dll','c:\\windows\\system32');
	DoFunc('GetEnvironmentVariableA@kernel32.dll','xxx',{},200)
***BE CAUTIONS TO USE CORRECT ARGUMENTS!***
2. DoFunc also provides several convenient functions: 
	DoFunc('winexec',cmd) -- call WinExec(...)
	DoFunc('shellexec',cmd) -- call ShellExecute(...): much faster than os.execute
	DoFunc('msgbox',msg) -- call MessageBox(...)
	DoFunc('#ExecWait','cmd.exe /c dir /p',1)
3. Other useful Win32 related functions: 
	get_choice(prompt_msg,tbl,width) -- show a menu to choose and return the button number to be chosen
	??set_env('PATH','yyyy')
    path=get_env('PATH')
	shell('mspaint.exe')
	shellexec('mspaint.exe')
	winexec('mspaint.exe')
	Execute('dir /p',1,true)
	execwait('cmd.exe /c dir /p',2)
	chdir('c:\\windows\\system32')
4. Other useful lua functions:
	f_read(file)  -- read file as a whole string
	f_read(file,true) -- read file as a string table
	f_write(file,s)	-- write string or string table s to file (overwrite)
	f_write(file,s,'a')	-- write string or string table s to file (append)
    f_exist(file) -- test whether a file exists
    chdir(dir) -- change to directory
5. Other useful variables:
    m_ext_version: version of m_ext.lua
    codepage: current code page
    mtexdir:  mtex folder
    comspec:  command shell program
]]
m_ext_version='11' --01/31/09 --01/18/09 '9'--2009.01.04
local dir=os.getenv('TEMP')
if dir=='' then dir='c:';end
local in_file=dir..'/MExtTemp.in'
local out_file=dir..'/MExtTemp.out'
local fn=package.loadlib(props['SciteDefaultHome']..'/lib/m_ext.dll','DoFunc')
if not fn then
	print('Cannot find m_ext.dll!')
	m_ext_version=nil
end


codepage=props['code.page']
comspec=(os.getenv('COMSPEC') or 'cmd.exe')..' /c'

mtexdir=os.getenv('MTEX')
--codepage=os.getenv('LANG')
if not mtexdir then
  mtexdir=props['SciteDefaultHome']..'\\..\\..'
  --codepage=props['code.page']
end

if props['PLAT_WIN']~='' then slash='\\';else slash='/';end

function f_exist(file)
	local f=io.open(file,'r')
	if not f then return false; end
	f:close()
	return true
end

function f_read(file,return_table)
	local f=io.open(file,'r')
	if not f then return f;end
	local s
	if not return_table then 
		s=f:read('*a')
	else
		s={}
		for v in f:lines() do table.insert(s,v);end
	end
	f:close()
	return s
end

function f_write(file,s,mode)
	if not mode then mode='w';end
	local f=io.open(file,mode)
	if not f then return;end
	if type(s)=='table' then s=table.concat(s,'\n');end
	f:write(s)
	f:close()
	return s
end

function arg_type(v)
	local t=type(v)
	if t=='table' and not t[1] then return '*','';end
	if t=='table' then return 't',tostring(t[1]);end
	return string.sub(t,1,1),tostring(v)
end

function DoFunc(func,...)
	local arg_t,arg_s=func..';','\n'
	local t,s
	for _,v in ipairs(arg) do 
		t,s=arg_type(v)
		arg_t=arg_t..t
		arg_s=arg_s..s..'\n'
	end
	f_write(in_file,arg_t..arg_s)
	fn()
	return unpack(f_read(out_file,true))
end

function spellcheck(w)
	f_write(in_file,'#SpellCheck;s\n'..w..'\n')
	fn()
	return f_read(out_file,true)
end


function showmsg(msg)
	DoFunc('msgbox',msg)
end

--To execute a shell command
Execute=function(cmd,mode,wait) return os.execute(cmd);end
execwait=Execute;shellexec=Execute;winexec=Execute;shellrun=Execute;
if m_ext_version then 
function Execute(cmd,mode,wait) return DoFunc('#ExecWait',comspec..' '..cmd,mode or 1,wait or false);end
function execwait(cmd,mode)	return	DoFunc('#ExecWait',cmd,mode or 1);end
function shellexec(cmd,mode) return	DoFunc('#ShellExec',cmd,mode or 1);end
function winexec(cmd,mode)	return DoFunc('#WinExec',cmd,mode or 1);end
function shellrun(cmd,mode,wait) DoFunc('#ShellRun',cmd,mode or 1,wait or false);end
function chdir(dir) DoFunc('SetCurrentDirectoryA@kernel32.dll',dir);end
end


function get_choice(prompt_msg,tbl,width)
	if not width then width=80;end
	local s=table.concat(tbl,'/')
	local ret=DoFunc('#DlgChoice',string.gsub(prompt_msg,'\n','\255'),s,tostring(width))
	return tonumber(ret)
end

--To get/set environment variables
function set_env(var,s)
	local ret=DoFunc('SetEnvironmentVariableA@kernel32.dll',var,s)
	return ret
end
function get_env(var)
	local ret,res=DoFunc('GetEnvironmentVariableA@kernel32.dll',var,{},1000)
	return res
end

--To get/set file attributes
function get_fileattr(FN)
	local ret=DoFunc('GetFileAttributesA@kernel32.dll',FN)
	return tonumber(ret)
end

function set_fileattr(FN,attr)
	local ret=DoFunc('SetFileAttributesA@kernel32.dll',FN,attr)
	return ret
end

--[mhb] 01/19/09 To provide easy to use iif()
function iif (expresion, onTrue, onFalse)
	if (expresion) then return onTrue; else return onFalse; end
end

--[mhb] 01/19/09 To convert between attributes string and number
function file_attr_string(a)
	if a<0 then return '';end
	return iif((a%2)>0,'R','')..iif((a%4)>=2,'H','')..iif((a%16)>=8,'S','')..iif((a%64)>=32,'A','')..iif((a%32)>=16,'D','')
end

function file_attr_number(s) 
	return iif(string.find(s,'A'),32,0) + iif(string.find(s,'R'),1,0) + iif(string.find(s,'H'),2,0) + iif(string.find(s,'S'),4,0)
end


--To strip end-of-line of a line
function strip_eol(line)
	return string.gsub(string.gsub(line or '','\n',''),'\r','')
end
--To trip leading and tailing spaces of a string 
function trim(s)
	local r=string.gsub(s,'^[%s\t]*','')
	r=string.gsub(r,'[%s\t]*$','')
	return r
end
function gmatch(s,pattern)
	for v in string.gmatch(s,pattern) do return v;end
end

--To format a path in unix/windows style 
function path_slash(path,slash)
	if not slash then slash='/';end
	return string.gsub(path,'[/\\]',slash)
end
--To get current line, word, selection, etc.
function get_info(pane)
	if not pane then pane=editor;end
	local r={}
	r.pos=pane.CurrentPos
	r.no=pane:LineFromPosition(r.pos)
	r.line=strip_eol(pane:GetLine(r.no))
	r.sel=pane:GetSelText()
	r.p2=pane:WordEndPosition(r.pos,true)
	r.p1=pane:WordStartPosition(r.pos,true)
	r.word=editor:textrange(r.p1,r.p2)
	return r
end
--[mhb] 05/31/09: To get current selection or current word (if not selected)
function get_curword(pane)
	if not pane then pane=editor;end
	local p=pane.CurrentPos
	local p2=pane:WordEndPosition(p,true)
	local p1=pane:WordStartPosition(p,true)
	return editor:textrange(p1,p2)
end
function get_cursel(pane)
	sel=pane:GetSelText()
	if sel=='' then sel=get_curword(pane) end
	return sel
end

--To get lists of indexs and values
function get_list(tbl)
	local idx,val={},{}
	for _,v in pairs(tbl) do table.insert(idx,_);table.insert(val,v);end
	return idx,val
end

--To get chars relative to current caret position
function charat(p)
    local v = editor.CharAt[p]; 
	if v < 0 then v = v + 256 end; 
	return v
end
function get_chars(pos_from,pos_to)
	local res,ch=''
	local pos = editor.CurrentPos
	for i=pos_from,pos_to do 
		ch=charat(pos+i)
		--if ch<0 then break;end
		res=res..string.char(ch)
	end
	return res
end

--To get relative path of current file: $FilePath start with root dir
function get_relative_path(root_dir,use_win)
	local p=string.gsub(props['FilePath'],'\\','/')
	local r=string.gsub(root_dir,'\\','/')
	local res=string.gsub(p,r,'')
	res=string.gsub(res,'^/','')
	if use_win then res=string.gsub(res,'/','\\');end
	return res
end
--To get the contents of a file as a string
function get_file_text(file)
  local f = io.open(file)
  local txt = f:read('*a')
  if txt then
    f:close()
    return txt
  else
    return ""
  end
end

--To support multiple language easily
function c_(tbl,cps)
	if type(cps)=='nil' then cps={'437','936','950'};end
	for i=2,table.getn(cps) do
		if cps[i]==codepage then return tbl[i];end
	end
	return tbl[1]
end

s_=scite.GetTranslation --[mhb] added 04/26/09: using feature of SciTE-Ru / instanton

--To determine whether current file matches a given extensions list
function curfile_match(exts,ignore_case)
	if not exts then return nil;end
	local ext,name=props['FileExt'],props['FileName']
	if ignore_case then 
		exts=string.lower(exts);ext=string.lower(ext);name=string.lower(name)
	end
	return string.find(' '..exts..' ',' '..ext..' ') or string.find(exts..';','%*%.'..ext..';') or string.find(';'..exts,';'..name..'%.%*')
end

--To find all lines containing certain pattern
function findall(pat,debug,plain,n_lines)
  local res={line={},w={},w1={},w2={},w3={}}
  local s,pats,pat_exists,n,s2
  pats=pat
  if type(pats)=='string' then pats={pat};end
  
  --[mhb] 04/04/09
  n=n_lines or 0
  
  for i=0,editor.LineCount-2 do
	s=editor:GetLine(i)

	--[mhb] 04/04/09
	s2=''
	if n>0 then
		for k=1,n do
			s2=s2..(editor:GetLine(i+k) or '')
		end
	end
	
	for _,v in pairs(pats) do
		pat_exists=0
		if plain then --2008.10.30
			w1=v
			w2=''
			w3=''
			if string.find(s,v,1,true) then
				if debug then 
					--trace(':'..(i+1)..': '..w1..'\n'..'\t'..s)
					trace(':'..(i+1)..': '..trim(s)..'\n'..s2) --[mhb] modified: 04/04/09
				end
				table.insert(res.line,i)
				table.insert(res.w,tostring(i+1)..': '..w1)
				table.insert(res.w1,w1)
				table.insert(res.w2,w2)
				table.insert(res.w3,w3)
				pat_exists=1
				break 
			end
		else
			for w1,w2,w3 in string.gmatch(s,v) do
				
				if debug then 
-- 					print(w1,w2,w3)
-- 					trace(':'..(i+1)..': '..w1)
-- 					if not string.find(w1,'\n') then trace('\n');end
-- 					trace('\t'..s)
					trace(':'..(i+1)..': '..trim(s)..'\n'..s2) --[mhb] modified: 04/04/09
				end
				table.insert(res.line,i)
				table.insert(res.w,tostring(i+1)..': '..w1)
				table.insert(res.w1,w1)
				table.insert(res.w2,w2)
				table.insert(res.w3,w3)
				pat_exists=1
				break --2008.08.15
			end
			if pat_exists==1 then break;end
		end
	end
  end
  return res
end

--[mhb] added 01/16/09: find pattern in a file 
function f_findall(file,pat,debug,plain)
  local res={line={},w={},w1={},w2={},w3={}}
  local f=io.open(file,'r')
  if not f then return res;end
   
  local i,s,pats,pat_exists
  pats=pat
  i=0
  if type(pats)=='string' then pats={pat};end
  for s in f:lines() do
	for _,v in pairs(pats) do
		pat_exists=0
		if plain then --2008.10.30
			w1=v
			w2=''
			w3=''
			if string.find(s,v,1,true) then
				if debug then 
					--trace(':'..(i+1)..': '..w1..'\n'..'\t'..s)
					trace(file..':'..(i+1)..': '..trim(s)..'\n')
				end
				table.insert(res.line,i)
				table.insert(res.w,tostring(i+1)..': '..w1)
				table.insert(res.w1,w1)
				table.insert(res.w2,w2)
				table.insert(res.w3,w3)
				pat_exists=1
				break 
			end
		else
			for w1,w2,w3 in string.gmatch(s,v) do
				
				if debug then 
-- 					print(w1,w2,w3)
-- 					trace(':'..(i+1)..': '..w1)
-- 					if not string.find(w1,'\n') then trace('\n');end
-- 					trace('\t'..s)
					trace(file..':'..(i+1)..': '..trim(s)..'\n')
				end
				table.insert(res.line,i)
				table.insert(res.w,tostring(i+1)..': '..w1)
				table.insert(res.w1,w1)
				table.insert(res.w2,w2)
				table.insert(res.w3,w3)
				pat_exists=1
				break --2008.08.15
			end
			if pat_exists==1 then break;end
		end
	end
    i=i+1
  end
  
  f:close()

  return res
end

--[mhb] added 05/28/09: borrowed from highlighting_paired_tags.lua by Mozer
function EditorMarkText(start, length, style_number)
	scite.SendEditor(SCI_SETINDICATORCURRENT, style_number)
	scite.SendEditor(SCI_INDICATORFILLRANGE, start, length)
end
function EditorClearMarks(style_number, start, length)
	local _first_style, _end_style, style
	if style_number == nil then
		_first_style, _end_style = 0, 31
	else
		_first_style, _end_style = style_number, style_number
	end
	if start == nil then
		start, length = 0, editor.Length
	end
	for style = _first_style, _end_style do
		scite.SendEditor(SCI_SETINDICATORCURRENT, style)
		scite.SendEditor(SCI_INDICATORCLEARRANGE, start, length)
	end
end

--[mhb] 05/28/09: Monospace functions
function GetMonoFont()
 -- retrieve monospace font information
  local StyleMono = {}
  local monoprop = props["font.monospace"]
  for style, value in string.gfind(monoprop, "([^,:]+):([^,]+)") do
    StyleMono[style] = value
  end
  -- grab styles, assuming they are defined
  MonoFont = StyleMono.font
  MonoSize = tonumber(StyleMono.size)
  return MonoFont,MonoSize
end

function ToggleMono()
	scite.MenuCommand(IDM_MONOFONT)
end

function MakeMonospace(SIG)
  local MonoFont, MonoSize = GetMonoFont()
--   local SIG = "MakeMonospace"
  local function AllMono()
    for i = 0, 127 do
      editor.StyleFont[i] = MonoFont
      editor.StyleSize[i] = MonoSize
    end
    editor:Colourise(0, -1)
  end
  scite_OnSwitchFile(function() if buffer[SIG] then AllMono() return true end end)
  buffer[SIG] = true
  AllMono()
end

--[mhb] added 05/30/09: to support pretty printing of a table; borrowed from http://lua-users.org/wiki/TableSerialization
function print_r (t, indent) -- alt version, abuse to http://richard.warburton.it
  local indent=indent or ''
  for key,value in pairs(t) do
    trace(indent..'['..tostring(key)..']') 
    if type(value)=="table" then trace('\n') print_r(value,indent..'\t')
    else trace(' = '..tostring(value)..'\n') end
  end
end


--[mhb] added 02/27/09: change lexer language
function SetLanguage(lng_name)
	local i = 0
	for _,name,_ in string.gfind(props["menu.language"],"([^|]*)|([^|]*)|([^|]*)|") do
		if name == lng_name then
			scite.MenuCommand(IDM_LANGUAGE + i)
			return
		end
		i = i + 1
	end
end
 

lexercodes={
ada=20, apdl=61, asm=34, asn1=63, au3=60, automatic=1000, ave=19, baan=31, bash=62, batch=12, blitzbasic=66, bullant=27, caml=65, clw=45, clwnocase=46, cmake=80, conf=17, container=0, cpp=3, cppnocase=35, csound=74, css=38, d=79, diff=16, eiffel=23, eiffelkw=24, erlang=53, errorlist=10, escript=41, f77=37, flagship=73, forth=52, fortran=36, freebasic=75, gap=81, gui4cli=58, haskell=68, html=4, innosetup=76, kix=57, latex=14, lisp=21, lot=47, lout=40, lua=15, makefile=11, matlab=32, metapost=50, mmixal=44, mssql=55, nncrontab=26, nsis=43, null=1, octave=54, opal=77, pascal=18, perl=6, phpscript=69, plm=82, pov=39, powerbasic=51, progress=83, properties=9, ps=42, purebasic=67, python=2, rebol=71, ruby=22, scriptol=33, smalltalk=72, specman=59, spice=78, sql=7, tads3=70, tcl=25, tex=49, vb=8, vbscript=28, verilog=56, vhdl=64, xcode=13, xml=5, yaml=48 
}

