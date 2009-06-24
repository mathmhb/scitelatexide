proj_file=props['SciteUserHome']..'/scite_user.prj'
project={
	name='DEFAULT',
	dir=props['SciteDefaultHome']..'/scite_lua',
	files={'menucmds.lux','myfold.lux','mylexer.lux','myspellcheck.lux','zz_keys.lux'},
	positions={},	
}


local ident='>>>>Project Manager<<<<' 
local cmds={'--Add Current File--','--Save Project--'}
function get_par(line)
	local p=string.gsub(line,'%-%-.+=[\t%s]*','')
	return p
end
function hintmsg(msg)
	print('\n**'..msg)
end
function help()
	print('\n')
	hintmsg('Tips:')
	hintmsg('1. Edit file list and press ENTER to add/remove/modify file list.')
	hintmsg('2. Edit project file, project name, directory and press ENTER to change them.')
	hintmsg('3. Double-clik file name to open corresponding file.')
	hintmsg('4. Double-click --ProjectFile-- to re-read project file.')
	hintmsg('5. Double-click --Directory-- to list files in that directory.')
	hintmsg('6. Double-click --Add Current File-- to add current file to project.')
	hintmsg('7. Double-click --Save Project-- to save changes to project file.')
end 
function proj_show()
	output:ClearAll()
	local F=project.files
	
	print(ident)
	print('--ProjectFile=',proj_file)
	print('--ProjectName=',project.name)
	print('--Directory=',project.dir)
	for _,v in ipairs(cmds) do print(v);end
	for _,v in ipairs(F) do	print(v);end
	help()
end

function proj_active()
	if not output.Focus then return false;end
	local s=output:GetLine(0) or ''
	return string.find(s,ident,1,true)
end

function proj_newdir(s,dir_files)
	local d=string.gsub(s,'--Directory=[%s\t]*','')
	d=string.gsub(d,'/%s*$','')
	if project.dir~=d then
		project.dir=d
		if dir_files then project.files=scite_Files(d..'/*.*');end
	end
end
function proj_update()
	local n=output.LineCount-2
	project.files={}
	for i=1,n do
		line=strip_eol(output:GetLine(i))
		line=trim(line)
		if string.find(line,'^%*%*') then break;end
		line=path_slash(line,'/')
		if string.find(line,'^%a.+') then  
			table.insert(project.files,line)
		elseif string.find(line,'%-%-Directory=') then 
			proj_newdir(line,false)
		elseif string.find(line,'%-%-ProjectFile=') then 
			proj_file=get_par(line)
		elseif string.find(line,'%-%-ProjectName=') then 
			project.name=get_par(line)
		end
	end
	proj_show()
end
function proj_close()
	hintmsg('Sorry, not implemented...')
end
function proj_save()
	local s=''
	s='ProjectName='..project.name..'\n';
	s=s..'Directory='..project.dir..'\n'
	s=s..'Files='..'\n'
	s=s..table.concat(project.files,'\n')
	f_write(proj_file,s)
end
function proj_read()
	local s=f_read(proj_file)
	if not s then
		return
	end
	local files=string.gsub(s,'.*\nFiles=\n','')
	project.files=split(files,'\n')
	local name,dir
	for w in string.gmatch(s,'ProjectName=(.-)\n') do name=w;end
	for w in string.gmatch(s,'Directory=(.-)\n') do dir=w;end
	project.name=name
	project.dir=dir	
end

function proj_do_cmd(s)
	local d
	if string.find(s,'%-%-ProjectFile=') then 
		proj_file=get_par(s)
		proj_read()
		proj_show()
		hintmsg('Project info has been read from file: '..proj_file)
	elseif string.find(s,'%-%-Directory=') then 
		proj_newdir(s,true)
		proj_show()
	elseif string.find(s,'%-%-Add Current File') then
		d=get_relative_path(project.dir)
		if not get_index(project.files,d) then
			table.insert(project.files,d)
		end
		proj_show()
	elseif string.find(s,'%-%-Close Project') then
		proj_close()
	elseif string.find(s,'%-%-Save Project') then
		proj_save()
		hintmsg('Current project has been saved to file: '..proj_file)
	end
end 
function proj_dbl_click()
	if not proj_active() then 
		scite_OnDoubleClick(proj_dbl_click,'remove')
		scite_OnOutputLine(proj_update,'remove')
		return false
	end
	local r=get_info(output)
	local s=r.line
	if string.find(s,'^%-%-') then proj_do_cmd(s);return true;end;
	if string.find(s,'^%*%*') then return;end
	local f=s
	if not string.find(s,'^/') and not string.find(s,'^%a:') then
		f=project.dir..'/'..s
	end
	if r.no>0 then
		scite.Open(f)
	end
	return true
end

function proj_man()
	proj_show()
	scite_OnDoubleClick(proj_dbl_click)
	scite_OnOutputLine(proj_update)
end

--scite_Command(c_{'Project Manager','工程管理','祘恨瞶'}..'|proj_man|F10')
proj_read()

