local templates={}
local template_paths={props['SciteDefaultHome']..'/templates'}
function find_file(f,paths)
	local p
	if string.find(f,'[/\\]') then return f;end
	for _,v in ipairs(paths) do
		p=v..'/'..f
		p=path_slash(p,slash)
		if scite_FileExists(p) then return p;end
	end
	
	return nil
end

function sel_template(n)
	local f=templates[n]
	if not f then print('I cannot find template : '..n);return;end
	local p=find_file(f,template_paths)
	if not p then print('I cannot find template file: '..f);return;end
	local s=f_read(p)
	scite.Open('')
	editor:append(s)
	local p1,p2=editor:findtext('^!')
	if not p1 then p1,p2=editor:findtext('^^');end
	if p1 then 
		editor.SelectionStart=p1
		editor.SelectionEnd=p2
		editor:ReplaceSel(' ')
		editor:GotoPos(p1)
	end
end

function select_templates()
	local n,t=get_list(templates)
	scite_UserListShow(n,1,sel_template)
end


local clipfiles={LaTeX='latex.ctl',Html='html.ctl'}
local clipfile_paths={props['SciteDefaultHome']..'/../editplus'}
local cliptext={}
local clipkeys={}
local clip_settings={}
local ident='>>>>ClipText<<<<'
local clipname=''

function get_match(s,pattern)
	for _1,_2,_3,_4,_5,_6,_7,_8,_9 in string.gmatch(s,pattern) do return _1,_2,_3,_4,_5,_6,_7,_8,_9;end
end

function read_ctl(file,debug)
	local f=io.open(file,'r')
	local k,t,s,old_t
	cliptext={}
	clipkeys={}
	s=''
	old_t=''
	for v in f:lines() do 
		if string.find(v,'^#(%a+)=(.+)') then
			--print(s)
			old_t=t
			k,t=get_match(v,'#(%a+)=(.+)')
			--print('===',k,t)
			if k=='T' then 
				cliptext[old_t]=s
				table.insert(clipkeys,old_t)
				if debug then print(old_t);end
			else
				clip_settings[k]=t
			end
			s=''
		else
			s=s..'\n'..v
		end
	end
	f:close()
end


function clip_active() 
	if not output.Focus then return false;end
	local s=output:GetLine(0) or ''
	return string.find(s,ident,1,true)
end
function clip_dbl_click()
	if not clip_active() then 
		scite_OnDoubleClick(clip_dbl_click,'remove')
		output:ClearAll()
		return false
	end
	local r=get_info(output)
	local s=trim(r.line)
	if r.no<1 then return;end
	local t=cliptext[s]
	local pos=editor.CurrentPos
	--print(s,t)
	if t then 
		local i1=string.find(t,'^!',1,true)
		if not i1 then i1=string.find(t,'^^',1,true);end
		if not i1 then i1=string.len(t);end
		t=string.gsub(t,'%^!','  ')
		t=string.gsub(t,'%^%^','  ')
		editor:insert(pos,t)
		editor:GotoPos(pos+i1)
		output:GotoPos(r.pos)
		scite.MenuCommand(IDM_SWITCHPANE)
		scite.MenuCommand(IDM_ACTIVATE)
		editor:GrabFocus()
	end
	return true
end
function sel_clip(n) 
	clipname=n
	local f=clipfiles[n]
	local file=find_file(f,clipfile_paths)
	local vert=props['split.vertical']
	props['split.vertical']='1'
	scite.MenuCommand (IDM_SPLITVERTICAL)
	output:ClearAll()
	print(ident,'['..n..']')
	read_ctl(file,true)
	scite_OnDoubleClick(clip_dbl_click)
end
function select_clipfiles()
	local n,t=get_list(clipfiles)
	scite_UserListShow(n,1,sel_clip)
end
function update_cliptext()
	local s=output:GetLine(0) or ''
	if string.find(s,ident,1,true) then
		sel_clip(clipname)
		--output:ClearAll()
		--print(clipname)
	end
end
--scite_OnSwitchFile(update_cliptext)
--scite_OnOpen(update_cliptext)
scite_require('mytemplates.lux')

