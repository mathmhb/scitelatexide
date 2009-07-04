--[mhb] modified based on SideBar.lua in SciTE-Ru, by Frank Wunderlich, mozers™, VladVRO, frs, BioInfo

--[mhb] 04/04/09
local s_=scite.GetTranslation
local function GotoLine(line)
	editor:GotoLine(line)
	editor:ScrollCaret()
	editor.FoldExpanded[line]=true
	editor:EnsureVisible(line)
end


-- you can choose to make it a stand-alone window; just uncomment this line:
-- local win = true

local tab_index = 0
local panel_width = tonumber(props['sidebar.width']) or 280 --[mhb] 06/28/09 
local win_height = props['position.height']
if win_height == '' then win_height = 600 end

----------------------------------------------------------
-- Create panels
----------------------------------------------------------
local tab0 = gui.panel(panel_width + 18)

local memo_path = gui.memo()
tab0:add(memo_path, "top", 22)

local list_dir = gui.list()
-- local list_dir_height = win_height/2 - 80
local list_dir_height=200
tab0:add(list_dir, "top", list_dir_height)

local list_favorites = gui.list(true)
tab0:add(list_favorites, "top", 100) --[mhb]
list_favorites:add_column(s_("Favorites"), 300)

-- tab0:client(list_favorites)  --[mhb] commented

--[mhb] added: to support project management
local proj = gui.list(true)
proj:add_column(s_("Project"),300)
tab0:add(proj,"bottom",80)
tab0:client(proj)

tab0:context_menu {
	s_('FileMan: Select Dir')..'|FileMan_SelectDir',
	s_('FileMan: Show All')..'|FileMan_MaskAllFiles',
	s_('FileMan: Only current ext')..'|FileMan_MaskOnlyCurrentExt',
	'', -- separator
	s_('FileMan: Copy to')..'...|FileMan_FileCopy',
	s_('FileMan: Move to')..'...|FileMan_FileMove',
	s_('FileMan: Rename')..'|FileMan_FileRename',
	s_('FileMan: Delete')..'\tDel|FileMan_FileDelete',
	s_('FileMan: Execute')..'|FileMan_FileExec',
	s_('FileMan: Exec with Params')..'|FileMan_FileExecWithParams',
	s_('FileMan: Add to Favorites')..'\tIns|Favorites_AddFile',
	s_('FileMan: Add to Project')..'|prj_AddFile',
	'', -- separator
	s_('Favorites: Add active buffer')..'|Favorites_AddCurrentBuffer',
	s_('Favorites: Delete item')..'\tDel|Favorites_DeleteItem',
	--[mhb] added
	'', -- separator
	s_('Project: Add active buffer')..'|prj_AddCurrentBuffer',
	s_('Project: Open item')..'\tEnter|prj_OpenFile',
	s_('Project: Delete item')..'\tDel|prj_DeleteItem',
	s_('Project: Save current project')..'|prj_SaveList',
	s_('Project: Open existing project')..'|prj_OpenList',
}
-------------------------
local tab1 = gui.panel(panel_width + 18)

--~ local list_func = gui.list(true)
--~ list_func:add_column(s_("Functions/Procedures"), 600)
-- local list_func_height = win_height/2 - 80
--~ tab1:add(list_func, "top", 10)

local list_bookmarks = gui.list(true)
list_bookmarks:add_column("@", 40)
list_bookmarks:add_column(s_("Bookmarks"), 600)
tab1:add(list_bookmarks, "bottom", 100)
-- tab1:client(list_bookmarks)

local fcn = gui.list(true)
fcn:add_column("#",40)
fcn:add_column(s_("Functions/Patterns"), 600)
tab1:add(fcn,"bottom",200)
tab1:client(fcn)

tab1:context_menu {
	s_('Functions: Sort by Order')..'|funcs_SortByOrder',
	s_('Functions: Sort by Name')..'|funcs_SortByName',
}
-------------------------
local tab2 = gui.panel(panel_width + 18)

local list_abbrev = gui.list(true)
list_abbrev:add_column(s_("Abbrev"), 60)
list_abbrev:add_column(s_("Expansion"), 600)
tab2:client(list_abbrev)

--[mhb] added: use open_abbrfile from open_abbrfile.lua
tab2:context_menu {
	s_('Abbrev: Edit abbreviations')..'|open_abbrfile',
}

-------------------------
--[mhb] added:
local width=panel_width

-- local bookmarks = gui.list(true)
-- bookmarks:add_column(s_("Bookmarks"),width)




local tab_4 = gui.panel(panel_width + 18)
local ref = gui.list(true)
local cite= gui.list(true)
local sbf = gui.list(true)
ref:add_column(s_('Labels'),width-18)
cite:add_column(s_('Bibitems'),width-18)
sbf:add_column(s_('SubFiles'),width-18)
tab_4:add(cite,"bottom",80)
tab_4:add(ref,"bottom",80)
tab_4:add(sbf,"bottom",200)
tab_4:client(ref)

tab_4:context_menu {
	s_('LaTeX: Refresh Labels')..'|Fill_LaTeX'
}

local tab_5 = gui.panel(panel_width + 18)
local grk = gui.list(true)
local mth = gui.list(true)
local env = gui.list(true)
grk:add_column(s_("Greek"),width-18)
mth:add_column(s_("Math"),width-18)
env:add_column(s_("Environments"),width-18)
tab_5:add(grk,"bottom",200)
tab_5:add(mth,"bottom",200)
tab_5:add(env,"bottom",200)
tab_5:client(grk)



local greek = {'\\alpha'; '\\beta'; '\\gamma'; '\\delta'; '\\epsilon'; '\\varepsilon'; '\\zeta'; '\\eta';
'\\theta'; '\\vartheta'; '\\iota'; '\\kappa'; '\\lambda'; '\\mu'; '\\nu'; '\\xi'; '\\pi'; '\\varpi';
'\\rho'; '\\varrho'; '\\sigma'; '\\varsigma'; '\\tau'; '\\upsilon'; '\\phi'; '\\varphi'; '\\chi';
'\\psi'; '\\omega'; '\\varkappa'; '\\Gamma'; '\\Delta'; '\\Theta'; '\\Lambda'; '\\Xi'; '\\Pi';
'\\Sigma'; '\\Upsilon'; '\\Phi'; '\\Psi'; '\\Omega'; '\\digamma'}
table.sort(greek)
for _,k in pairs(greek) do
	grk:add_item{k}
end

local math_symb = {'\\frac';'\\sqrt';'\\partial','\\infty';'\\limit';'\\sum';'\\times';'\\otimes';'\\langle';'\\rangle';'\\nabla';'\\pm';'\\subset';'\\in';'\\sin';'\\cos';'\\tan';'\\cot';'\\sec';'\\csc';'\\exp';'\\log';'\\int';'\\label'}
table.sort(math_symb)
for _,k in pairs(math_symb) do
	mth:add_item{k}
end

local envs ={'equation'; 'eqnarray'; 'align'; 'itemize'; 'enumerate'; 'description'; 'theorem';
'displaymath'; 'array'; 'figure'; 'listing'; 'comment'; 'table'; 'tabular'; 'frame'}
table.sort(envs)
for _,k in pairs(envs) do
	env:add_item{k}
end

--[mhb] 05/26/09: add a tab for help docs; require menucmds.lua
local tab_3 = gui.panel(panel_width + 18)
local doc = gui.list(true)
doc:add_column(s_("HelpDocs"),width-18)
tab_3:add(doc,"bottom",200)
tab_3:client(doc)

local function get_helpdocs()
	local t=props['FileType']
	local p='HELPCMDS_'..t
	if props[p]=='' then p='HELPCMDS_*' end
	local res=prop2table(p)
	return res
end

local function docs_FILL()
	local help_list=get_helpdocs()
	doc:clear()
	for _,v in ipairs(help_list) do
			doc:add_item(v)
	end
end

doc:on_double_click(function() local idx=doc:get_selected_item()
	if not (idx == -1) then
		local item = doc:get_item_text(idx)
		if item then
			sel_helpfile(item)
		end
	end
end)

local function fill_list(lst,tbl)
	local w
	lst:clear()
	for i,v in ipairs(tbl) do
		if type(v)=='table' then w=v else w={v} end
		lst:add_item(w,w[1])
	end
end

local function funcs_FILL(sort_alpha)
--~ 	if not patterns then return; end
	local t=props['FileType']
	local pat=prop2table('PATTERNS_'..t)
--~ 	local pat=patterns[t]
	if not pat then return; end
	if #pat==0 then return;end
	
	local found_patterns=findall(pat,false)
	if not found_patterns then return; end
	if not found_patterns.w then return;end
	local found_names=found_patterns.w
	local found_lines=found_patterns.line
	local j,s1,s2,tbl
	tbl={}
	for i,v in ipairs(found_names) do
		j=string.find(v,':',1,true)
		if not j then break;end
		s1=string.sub(v,1,j-1)
		s2=string.sub(v,j+1)
		s2=s2:gsub("\n",""):gsub("\r","")
		table.insert(tbl,{s1,s2})
	end
	if sort_alpha then
		table.sort(tbl,function(a, b) return a[2]<b[2] end)
	end
	fill_list(fcn,tbl)
end

function funcs_SortByOrder()
	funcs_FILL()
end

function funcs_SortByName()
	funcs_FILL('alpha')
end

grk:on_double_click(function() local idx=grk:get_selected_item()
	if not (idx == -1) then
		local item = grk:get_item_text(idx)
		if item then
			local pos = editor.CurrentPos + string.len(item)
			editor:InsertText(-1,item)
			editor:GotoPos(pos)
			editor:GrabFocus()
		end
	end
end)

mth:on_double_click(function() local idx=mth:get_selected_item()
	if not (idx == -1) then
		local item = mth:get_item_text(idx)
		if item then
			local pos = editor.CurrentPos + string.len(item)
			editor:InsertText(-1,item)
			editor:GotoPos(pos)
			editor:GrabFocus()
		end
	end
end)

env:on_double_click(function() local idx=env:get_selected_item()
	if not (idx == -1) then
		local item = env:get_item_text(idx)
		if item then
			local str = '\\begin{'..item..'}\n'
			local str2 = str..'\n'..'\\end{'..item..'}'
			local pos = editor.CurrentPos + string.len(str)
			editor:InsertText(-1,str2)
			editor:GotoPos(pos)
			editor:GrabFocus()
		end
	end
end)

local function fill_items(ref,cite,sbf)

	ref:clear()
	--local tbl = list_after_word('bibitem')
	local lbl = list_labels() --[mhb] 04/23/09: from myrefbib.lua
	for _,v in pairs(lbl) do
		ref:add_item({v},'\\label{'..v..'}')
	end

	cite:clear()
	--[mhb] modified 01/16/09: to support list also bib items in bib files:  list_all_bibitems(tex_file,debug,sort_items,ignore_bibfile) 
	--local tbl = list_after_word('bibitem')
	local tbl = list_all_bibitems(props['FilePath'],false,true,false) 
	for _,v1 in pairs(tbl) do
		cite:add_item{v1}
	end
	

	sbf:clear()
	--local sf = subfile_list()
	local sf = list_subfiles()  --[mhb] 04/23/09: from myrefbib.lua
	for _,v in pairs(sf) do
		sbf:add_item{v}
	end
	
	--[mhb] added 01/16/09: to support list also bib files: 
	local bibs=list_bibfiles(props['FilePath'])
	for _,v in pairs(bibs) do
		sbf:add_item{v}
	end	
	
end

function Fill_LaTeX()
	fill_items(ref,cite,sbf)
end

ref:on_select(function() local idx=ref:get_selected_item()
	if idx==-1 then return; end
	local item = ref:get_item_data(idx)
	output:ClearAll()
	findall(item,true,true,1)
end)

ref:on_double_click(function() local idx=ref:get_selected_item()
	if not (idx == -1) then
		local item = ref:get_item_text(idx)
		if item then
			local str = '(\\ref{'..item..'})'
			local pos = editor.CurrentPos + string.len(str)
			editor:InsertText(-1,'(\\ref{'..item..'})')
			editor:GotoPos(pos)
			editor:GrabFocus()
		end
	end
end)

cite:on_double_click(function() local idx=cite:get_selected_item()
	if not (idx == -1) then
		local item = cite:get_item_text(idx)
		if item then
			local str = '\\cite{'..item..'}'
			local pos = editor.CurrentPos + string.len(str)
			editor:InsertText(-1,'\\cite{'..item..'}')
			editor:GotoPos(pos)
			editor:GrabFocus()
		end
	end
end)

--[mhb] 04/23/09
function find_tex_file(f)
	local f_tmp='__tmp__.out'
	local s_cmd='kpsewhich.exe '..f .. ' > '..f_tmp
	os.execute(s_cmd)
	local res=f_read(f_tmp,true) or {}
	os.remove(f_tmp)
	if table.getn(res)>0 then
		return res[1]
	else
		return nil
	end
end


sbf:on_double_click(function() local idx=sbf:get_selected_item()
	if not (idx == -1) then
		local item = sbf:get_item_text(idx)
		if item then
			--[mhb] modified: to open sub file when it exists
			local f=props['FileDir']..'/'..item
			if f_exist(f) then
				scite.Open(f)
			else
				f=find_tex_file(item) --[mhb] 04/23/09
				print('Found ',item,':',f)
				if f and f_exist(f) then  --[mhb] 04/23/09
					scite.Open(f) --[mhb] 04/23/09
				else 
					local str = item
					local pos = editor.CurrentPos + string.len(str)
					editor:InsertText(-1,item)
					editor:GotoPos(pos)
					editor:GrabFocus()
				end
			end
		end
	end
end)

--[[
proj:on_double_click(function() local idx=proj:get_selected_item()
	if not (idx == -1) then
		local v = proj:get_item_data(idx)
		if v=='[*]' then
			local caption='Please choose or create a SciTE project file:'
			local filter='SciTE Project (.project)|.project'
			new_project=gui.open_dlg(caption,filter)
			if new_project then
				f_project=new_project
				project_name=name_of(f_project)
				project_files=f_read(f_project,true) or {}
			end
		elseif v=='[-]' then
			table.remove(project_files,idx)
			f_write(f_project,project_files)
		elseif v=='[+]' then
			table.insert(project_files,props['FilePath'])
			f_write(f_project,project_files)
		else
			scite.Open(v)
		end
		fill()
	end
end)
]]--

fcn:on_select(function() local idx=fcn:get_selected_item()
	if idx==-1 then return; end
	local item = fcn:get_item_text(idx)
	local s=string.gfind(item,'[a-zA-Z]*%(')
	output:ClearAll()
	findall(item,true,true,0)
end)

fcn:on_double_click(function() local idx=fcn:get_selected_item()
	if not (idx == -1) then
		local s_line = fcn:get_item_data(idx)
		local line=tonumber(s_line)-1
		GotoLine(line)
		gui.pass_focus()
	end
end)




--[[
bookmarks:on_double_click(function() local idx=bookmarks:get_selected_item()
	if not (idx == -1) then
		local pos = bookmarks:get_item_data(idx)
        scite.Open(pos[1])
        editor:GotoLine(pos[2])
    end
end)
]]



-------------------------
local win_parent
if win then
	win_parent = gui.window "Side Bar"
else
	win_parent = gui.panel(panel_width)
end

local tabs = gui.tabbar(win_parent)
tabs:add_tab(s_('File'), tab0)
tabs:add_tab(s_('Outline'), tab1)
tabs:add_tab(s_('Abbrev'), tab2)
tabs:add_tab(s_('Docs'), tab_3)
tabs:add_tab(s_('ltx-Labels'), tab_4)
tabs:add_tab(s_('ltx-Cmds'), tab_5)
win_parent:client(tab_5)
win_parent:client(tab_4)
win_parent:client(tab_3)
win_parent:client(tab2)
win_parent:client(tab1)
win_parent:client(tab0)

if tonumber(props['sidebar.show'])==1 then
	if win then
		win_parent:size(panel_width + 24, 600)
		win_parent:show()
	else
		gui.set_panel(win_parent,props['sidebar.position'] or 'left')
	end
end

----------------------------------------------------------
-- tab0:memo_path   Path and Mask
----------------------------------------------------------
local current_path = ''
local file_mask = '*.*'

local function FileMan_ShowPath()
	local rtf = '{\\rtf\\ansi\\ansicpg1251{\\fonttbl{\\f0\\fcharset204 Helv;}}{\\colortbl ;\\red0\\green0\\blue255;  \\red255\\green0\\blue0;}\\f0\\fs16'
	local path = '\\cf1'..current_path:gsub('\\', '\\\\')
	local mask = '\\cf2'..file_mask..'}'
	memo_path:set_text(rtf..path..mask)
end

----------------------------------------------------------
-- tab0:list_dir   File Manager
----------------------------------------------------------
local function FileMan_ListFILL()
	if current_path == '' then return end
	list_dir:clear()
	local folders = gui.files(current_path..'*', true)
	list_dir:add_item ('[..]', {'..','d'})
	for i, d in ipairs(folders) do
		list_dir:add_item('['..d..']', {d,'d'})
	end
	local files = gui.files(current_path..file_mask)
	if files then
		for i, filename in ipairs(files) do
			list_dir:add_item(filename, {filename})
		end
	end
	list_dir:set_selected_item(0)
	FileMan_ShowPath()
end

local function FileMan_GetSelectedItem()
	local idx = list_dir:get_selected_item()
	if idx == -1 then return '' end
	local data = list_dir:get_item_data(idx)
	local dir_or_file = data[1]
	local attr = data[2]
	return dir_or_file, attr
end

function FileMan_SelectDir()
	local newPath = gui.select_dir_dlg('Select new directory') or ''
	if newPath ~= '' then
		if newPath:match('[\\/]$') then
			current_path = newPath
		else
			current_path = newPath..'\\'
		end
		FileMan_ListFILL()
	end
end

function FileMan_MaskAllFiles()
	file_mask = '*.*'
	FileMan_ListFILL()
end

function FileMan_MaskOnlyCurrentExt()
	local filename, attr = FileMan_GetSelectedItem()
	if filename == '' then return end
	if attr == 'd' then return end
	file_mask = '*.'..filename:gsub('.+%.','')
	FileMan_ListFILL()
end

function FileMan_FileCopy()
	local filename = FileMan_GetSelectedItem()
	if filename == '' or filename == '..' then return end
	local path_destantion = gui.select_dir_dlg("Copy to...")
	if path_destantion == nil then return end
	os_copy(current_path..filename, path_destantion..'\\'..filename)
	FileMan_ListFILL()
end

function FileMan_FileMove()
	local filename = FileMan_GetSelectedItem()
	if filename == '' or filename == '..' then return end
	local path_destantion = gui.select_dir_dlg("Move to...")
	if path_destantion == nil then return end
	os.rename(current_path..filename, path_destantion..'\\'..filename)
	FileMan_ListFILL()
end

function FileMan_FileRename()
	local filename = FileMan_GetSelectedItem()
	if filename == '' or filename == '..' then return end
	local filename_new = shell.inputbox(s_("Rename"), s_("Enter new file name:"), filename, function(name) return not name:match('[\\/:|*?"<>]') end)
	if filename_new == nil then return end
	if filename_new.len ~= 0 and filename_new ~= filename then
		os.rename(current_path..filename, current_path..filename_new)
		FileMan_ListFILL()
	end
end

function FileMan_FileDelete()
	local filename, attr = FileMan_GetSelectedItem()
	if filename == '' then return end
	if attr == 'd' then return end
	if shell.msgbox(s_("Are you sure you want to DELETE this file?").."\n"..filename, s_("DELETE"), 4+256) == 6 then
	-- if gui.message("Are you sure you want to DELETE this file?\n"..filename, "query") then
		os.remove(current_path..filename)
		FileMan_ListFILL()
	end
end

local function FileMan_FileExecWithSciTE(cmd, mode)
	local p0 = props["command.0.*"]
	local p1 = props["command.mode.0.*"]
	props["command.name.0.*"] = 'tmp'
	props["command.0.*"] = cmd
	if mode == nil then mode = 'console' end
	props["command.mode.0.*"] = 'subsystem:'..mode..',savebefore:no'
	scite.MenuCommand(9000)
	props["command.0.*"] = p0
	props["command.mode.0.*"] = p1
end

function FileMan_FileExec(params)
	if params == nil then params = '' end
	local filename = FileMan_GetSelectedItem()
	if filename == '' then return end
	local file_ext = filename:match("[^.]+$")
	if file_ext == nil then return end
	file_ext = '%*%.'..string.lower(file_ext)
	local cmd = ''
	local function command_build(lng)
		local cmd = props['command.build.$(file.patterns.'..lng..')']
		cmd = cmd:gsub(props["FilePath"], current_path..filename)
		return cmd
	end
	-- Lua
	if string.match(props['file.patterns.lua'], file_ext) ~= nil then
		dostring(params)
		dofile(current_path..filename)
	-- Batch
	elseif string.match(props['file.patterns.batch'], file_ext) ~= nil then
		FileMan_FileExecWithSciTE(command_build('batch'))
		return
	-- WSH
	elseif string.match(props['file.patterns.wscript']..props['file.patterns.wsh'], file_ext) ~= nil then
		FileMan_FileExecWithSciTE(command_build('wscript'))
	-- Other
	else
		local ret, descr = shell.exec(current_path..filename..params)
		if not ret then
			print (">Exec: "..filename)
			print ("Error: "..descr)
		end
	end
end

function FileMan_FileExecWithParams()
	if scite.ShowParametersDialog('Exec "'..FileMan_GetSelectedItem()..'". Please set params:') then
		local params = ''
		for p = 1, 4 do
			local ps = props[tostring(p)]
			if ps ~= '' then
				params = params..' '..ps
			end
		end
		FileMan_FileExec(params)
	end
end

local function OpenFile(filename)
	if filename:match(".session$") ~= nil then
		filename = filename:gsub('\\','\\\\')
		scite.Perform ("loadsession:"..filename)
	else
		scite.Open(filename)
	end
	gui.pass_focus()
end

local function FileMan_OpenItem()
	local dir_or_file, attr = FileMan_GetSelectedItem()
	if dir_or_file == '' then return end
	if attr == 'd' then
		gui.chdir(dir_or_file)
		if dir_or_file == '..' then
			local new_path = current_path:gsub('(.*\\).*\\$', '%1')
			if not gui.files(new_path..'*',true) then return end
			current_path = new_path
		else
			current_path = current_path..dir_or_file..'\\'
		end
		FileMan_ListFILL()
	else
		OpenFile(current_path..dir_or_file)
	end
end

list_dir:on_double_click(function()
	FileMan_OpenItem()
end)

list_dir:on_key(function(key)
	if key == 13 then -- Enter
		FileMan_OpenItem()
	elseif key == 8 then -- BackSpace
		list_dir:set_selected_item(0)
		FileMan_OpenItem()
	elseif key == 46 then -- Delele
		FileMan_FileDelete()
	elseif key == 45 then -- Insert
		Favorites_AddFile()
	end
end)

----------------------------------------------------------
-- tab0:list_favorites   Favorites
----------------------------------------------------------
local favorites_filename = props['SciteUserHome']..'\\favorites.lst'
local list_fav_table = {}

local function Favorites_ListFILL()
	local favorites_file = io.open(favorites_filename)
	if favorites_file then
		list_favorites:clear() --[mhb] added: to clear items automatically
		for line in favorites_file:lines() do
			if line.len ~= 0 then
				local caption = line:gsub('.+\\','')
				list_favorites:add_item(caption, line)
				table.insert(list_fav_table, line)
			end
		end
		favorites_file:close()
	end
end
Favorites_ListFILL()

local function Favorites_SaveList()
	io.output(favorites_filename)
	local list_string = table.concat(list_fav_table,'\n')
	io.write(list_string)
	io.close()
end

--[mhb] added: to check whether 
local function is_in_table(tbl,s)
	for _,v in ipairs(tbl) do
		if v==s then return true; end
	end
	return false
end

function Favorites_AddFile()
	local filename, attr = FileMan_GetSelectedItem()
	if filename == '' then return end
	if attr == 'd' then return end
	--[mhb] modified: to avoid repetation
	local s=current_path..filename
	if is_in_table(list_fav_table,s) then return;end
	list_favorites:add_item(filename, s)
	table.insert(list_fav_table, s)
end

function Favorites_AddCurrentBuffer()
	local s=props['FilePath']
	if is_in_table(list_fav_table,s) then return;end	--[mhb] added
	list_favorites:add_item(props['FileNameExt'], props['FilePath'])
	table.insert(list_fav_table, props['FilePath'])
end

function Favorites_DeleteItem()
	local idx = list_favorites:get_selected_item()
	if idx == -1 then return end
	list_favorites:delete_item(idx)
	table.remove (list_fav_table, idx+1)
end

local function Favorites_OpenFile()
	local idx = list_favorites:get_selected_item()
	if idx == -1 then return end
	local filename = list_favorites:get_item_data(idx)
	OpenFile(filename)
end

list_favorites:on_double_click(function()
	Favorites_OpenFile()
end)

list_favorites:on_key(function(key)
	if key == 13 then -- Enter
		Favorites_OpenFile()
	elseif key == 46 then -- Delele
		Favorites_DeleteItem()
	end
end)


----------------------------------------------------------
-- tab0:prj   Project
----------------------------------------------------------
local prj_filename = props['SciteUserHome']..'\\default.prj'
local list_prj_table = {}

local function prj_ListFILL()
	local prj_file = io.open(prj_filename)
	if prj_file then
		proj:clear()
		for line in prj_file:lines() do
			if line.len ~= 0 then
				local caption = line:gsub('.+\\','')
				proj:add_item(caption, line)
				table.insert(list_prj_table, line)
			end
		end
		prj_file:close()
	end
end
prj_ListFILL()

local prj_filters="Project (.prj)|.prj|All (.)|."
function prj_SaveTo(fn)
	io.output(fn)
	local list_string = table.concat(list_prj_table,'\n')
	io.write(list_string)
	io.close()
end
function prj_SaveList()
	local fn=gui.open_dlg('Save Project File',prj_filters)
	if not fn then return;end
	prj_filename=fn
	prj_SaveTo(prj_filename)
end

function prj_OpenList()
	local fn=gui.open_dlg('Open Project File',prj_filters)
	if not fn then return;end	
	prj_filename=fn
	prj_ListFILL()
	local ans=gui.message('Do you want to close all buffers and automatically open files in the project?',"query")
	if ans then
		scite.MenuCommand(IDM_CLOSEALL)
		for _,v in ipairs(list_prj_table) do
			scite.Open(v)
		end
	end
end

function prj_AddFile()
	local filename, attr = FileMan_GetSelectedItem()
	if filename == '' then return end
	if attr == 'd' then return end
	local s=current_path..filename
	if is_in_table(list_prj_table,s) then return;end
	proj:add_item(filename, s)
	table.insert(list_prj_table, s)
end

function prj_AddCurrentBuffer()
	local s=props['FilePath']
	if is_in_table(list_prj_table,s) then return;end
	proj:add_item(props['FileNameExt'], props['FilePath'])
	table.insert(list_prj_table, props['FilePath'])
end

function prj_DeleteItem()
	local idx = proj:get_selected_item()
	if idx == -1 then return end
	proj:delete_item(idx)
	table.remove (list_prj_table, idx+1)
end

function prj_OpenFile()
	local idx = proj:get_selected_item()
	if idx == -1 then return end
	local filename = proj:get_item_data(idx)
	scite.Open(filename)
end

proj:on_double_click(function()
	prj_OpenFile()
end)

proj:on_key(function(key)
	if key == 13 then -- Enter
		prj_OpenFile()
	elseif key == 46 then -- Delele
		prj_DeleteItem()
	end
end)

-- [mhb] uncommented: no need to use these functions from SciTE-Ru
--[[ 

----------------------------------------------------------
-- tab1:list_func   Functions/Procedures
----------------------------------------------------------
local table_functions = {}
-- 1 - function names
-- 2 - line number
local _sort = 'order'

-- Note:
	- only upper char
	- ()function name()
	Правила создания регсепов:
	- использовать только заглавные буквы
	- имя функции должно быть выделено с обеих сторон парами скобок "()function name()" . Не путать с %b()!
	- если для языка задано несколько регсепов, то функция должна находится только одним из них


local Lang2RegEx = {
	['Assembler']={"\n%s*()%w+()%s+[FP][R][AO][MC][E%s]"},
-- 	['C++']={"()[^.,<>=\n%s]+()%([^.<>=)']-%)[%s\/}]-{",
	['C++']={"[^.,<>=\n]-[ :]()[^.,<>=\n%s]+()%b()[%s\/\n}]-{",
			"()[%u_]+::[%w~]+()%s*%b()[^};]-{"},
	['JScript']={"[\n;]%s*()FUNCTION +[^ ]-()%b()%s-%b{}"},
	['VisualBasic']={"[\n:][%s%u]*()SUB +[%w_]-()%b()",
					"[\n:][%s%u]*()FUNCTION +[%w_]-()%b()",
					"[\n:][%s%u]*()PROPERTY +[LGS]ET +[%w_]-()%b()"},
	['CSS']={"()[%w.#-_]+()%s-%b{}"},
	['Pascal']={"\n%s*()PROCEDURE +[%w_.]+()[ (;]",
				"\n%s*()FUNCTION +[%w_.]+() *%b(): *%a+;"},
	['Python']={"\n%s*()DEF +[%w_]-()%b():",
				"\n%s*()CLASS +[%w_]-()%b():"},
	['Lua']={"\n[%s%u]*FUNCTION +()[%w_]-()%b()"},
	['*']={"\n%s*()[SF][U][BN][^ .]* [^ (]*()%b()"},
}
local Lexer2Lang = {
	['asm']='Assembler',
	['cpp']='C++',
	['js']='JScript',
	['vb']='VisualBasic',
	['vbscript']='VisualBasic',
	['css']='CSS',
	['pascal']='Pascal',
	['python']='Python',
	['lua']='Lua',
}
local Ext2Lang = {}
local function Fill_Ext2Lang()
	local patterns = {
		[props['file.patterns.asm'] ]='Assembler',
		[props['file.patterns.cpp'] ]='C++',
		[props['file.patterns.wsh'] ]='JScript',
		[props['file.patterns.vb'] ]='VisualBasic',
		[props['file.patterns.wscript'] ]='VisualBasic',
		['*.css']='CSS',
		[props['file.patterns.pascal'] ]='Pascal',
		[props['file.patterns.py'] ]='Python',
		[props['file.patterns.lua'] ]='Lua',
	}
	for i,v in pairs(patterns) do
		for ext in (i..';'):gfind("%*%.([^;]+);") do
			Ext2Lang[ext] = v
		end
	end
end
Fill_Ext2Lang()

local function Functions_GetNames()
	table_functions = {}
	local tablePattern = Lang2RegEx[Ext2Lang[props["FileExt"] ] ]
	if not tablePattern then
		tablePattern = Lang2RegEx[Lexer2Lang[editor.LexerLanguage] ]
		if not tablePattern then
			tablePattern = Lang2RegEx['*']
		end
	end
	local textAll = editor:GetText()
-- output:ClearAll()
	for _, findPattern in ipairs(tablePattern) do
		for _start, _end in string.gmatch(textAll:upper(), findPattern) do
			local line_number = editor:LineFromPosition(_start)
			local findString = textAll:sub(_start, _end-1)
-- print(props['FileNameExt']..':'..(line_number+1)..':\t'..findString)
			findString = findString:gsub("%s+", " ")
			findString = findString:gsub("[Ss][Uu][Bb] ", "[s] ") -- VB
			findString = findString:gsub("[Ff][Uu][Nn][Cc][Tt][Ii][Oo][Nn] ", "[f] ") -- JS, VB,...
			findString = findString:gsub("[Pp][Rr][Oo][Cc][Ee][Dd][Uu][Rr][Ee] ", "[p] ") -- Pascal
			findString = findString:gsub("[Pp][Rr][Oo][Сс] ", "[p] ") -- C
			findString = findString:gsub("[Pp][Rr][Oo][Pp][Ee][Rr][Tt][Yy] [Ll][Ee][Tt] ", "[pl] ") -- VB
			findString = findString:gsub("[Pp][Rr][Oo][Pp][Ee][Rr][Tt][Yy] [Gg][Ee][Tt] ", "[pg] ") -- VB
			findString = findString:gsub("[Pp][Rr][Oo][Pp][Ee][Rr][Tt][Yy] [Ss][Ee][Tt] ", "[ps] ") -- VB
			findString = findString:gsub("[Cc][Ll][Aa][Ss][Ss] ", "[c] ") -- Phyton
			findString = findString:gsub("[Dd][Ee][Ff] ", "[d] ") -- Phyton
			table.insert (table_functions, {findString, line_number})
		end
	end
end

local function Functions_ListFILL()
	if tonumber(props['sidebar.show'])~=1 or tab_index~=1 then return end
	if _sort == 'order' then
		table.sort(table_functions, function(a, b) return a[2]<b[2] end)
	else
		table.sort(table_functions, function(a, b) return a[1]<b[1] end)
	end
	list_func:clear()
	for _, a in ipairs(table_functions) do
		list_func:add_item(a[1], a[2])
	end
end

function Functions_SortByOrder()
	_sort = 'order'
	Functions_ListFILL()
end

function Functions_SortByName()
	_sort = 'name'
	Functions_ListFILL()
end

local function Functions_GotoLine()
	local sel_item = list_func:get_selected_item()
	if sel_item == -1 then return end
	local pos = list_func:get_item_data(sel_item)
	if pos then
		editor:GotoLine(pos)
		gui.pass_focus()
	end
end

list_func:on_double_click(function()
	Functions_GotoLine()
end)

list_func:on_key(function(key)
	if key == 13 then -- Enter
		Functions_GotoLine()
	end
end)
]]--
----------------------------------------------------------
-- tab1:list_bookmarks   Bookmarks
----------------------------------------------------------
local table_bookmarks = {}
-- 1 - file path
-- 2 - buffer number
-- 3 - line number
-- 4 - line text

local function GetBufferNumber()
	local buf = props['BufferNumber']
	if buf == '' then buf = 1 else buf = tonumber(buf) end
	return buf
end

local function Bookmark_Add(line_number)
	local line_text = editor:GetLine(line_number)
	if line_text == nil then line_text = '' end
	line_text = line_text:gsub('^%s+', ''):gsub('%s+', ' ')
	if #line_text == 0 then
		line_text = ' - empty line - ('..(line_number+1)..')'
	end
	local buffer_number = GetBufferNumber()
	table.insert (table_bookmarks, {props['FilePath'], buffer_number, line_number, line_text})
end

local function Bookmark_Delete(line_number)
	for i = #table_bookmarks, 1, -1 do
		local a = table_bookmarks[i]
		if a[1] == props['FilePath'] then
			if line_number == nil then
				table.remove(table_bookmarks, i)
			elseif a[3] == line_number then
				table.remove(table_bookmarks, i)
				break
			end
		end
	end
end

local function Bookmarks_ListFILL()
	if tonumber(props['sidebar.show'])~=1 or tab_index~=1 then return end
	table.sort(table_bookmarks, function(a, b) return a[2]<b[2] or a[2]==b[2] and a[3]<b[3] end)
	list_bookmarks:clear()
	for _, a in ipairs(table_bookmarks) do
		list_bookmarks:add_item({a[2], a[4]}, {a[1], a[3]})
	end
end

local function Bookmarks_RefreshTable()
	Bookmark_Delete()
	for i = 0, editor.LineCount do
		if editor:MarkerGet(i) == 2 then
			Bookmark_Add(i)
		end
	end
	Bookmarks_ListFILL()
end

local function ShowCompactedLine(line_num)
	local function GetFoldLine(ln)
		while editor.FoldExpanded[ln] do ln = ln-1 end
		return ln
	end
	while not editor.LineVisible[line_num] do
		local x = GetFoldLine(line_num)
		editor:ToggleFold(x)
		line_num = x - 1
	end
end

local function Bookmarks_GotoLine()
	local sel_item = list_bookmarks:get_selected_item()
	if sel_item == -1 then return end
	local pos = list_bookmarks:get_item_data(sel_item)
	if pos then
		scite.Open(pos[1])
		ShowCompactedLine(pos[2])
		editor:GotoLine(pos[2])
		gui.pass_focus()
	end
end

list_bookmarks:on_double_click(function()
	Bookmarks_GotoLine()
end)

list_bookmarks:on_key(function(key)
	if key == 13 then -- Enter
		Bookmarks_GotoLine()
	end
end)

----------------------------------------------------------
-- tab2:list_abbrev   Abbreviations
----------------------------------------------------------
local function Abbreviations_ListFILL()
	local function ReadAbbrev(file)
		local abbrev_file = io.open(file)
		if abbrev_file then
			for line in abbrev_file:lines() do
				if string.len(line) ~= 0 then
					local _abr, _exp = string.match(line, '(.-)=(.+)')
					if _abr ~= nil then
						list_abbrev:add_item({_abr, _exp}, _exp)
					else
						local import_file = string.match(line, '^import%s+(.+)')
						if import_file ~= nil then
							ReadAbbrev(string.match(file, '.+\\')..import_file)
						end
					end
				end
			end
			abbrev_file:close()
		end
	end

	list_abbrev:clear()
	local abbrev_filename = get_abbrfile() --[mhb] 06/01/09: <== props['AbbrevPath'] 
	ReadAbbrev(abbrev_filename)
end

local function Abbreviations_InsertExpansion()
	local sel_item = list_abbrev:get_selected_item()
	if sel_item == -1 then return end
	local expansion = list_abbrev:get_item_data(sel_item)
	expansion = expansion:gsub('\\r','\r'):gsub('\\n','\n'):gsub('\\t','\t')
	
	--[mhb] added 06/01/09: support property expansion, e.g. $[CurrentDate]
	local get_prop=function(s) return props[s];end
	expansion=string.gsub(expansion,'%$%[(%w+)%]',get_prop)
	
	scite.InsertAbbreviation(expansion)
	gui.pass_focus()
	editor:CallTipCancel()
end

local function Abbreviations_ShowExpansion()
	local sel_item = list_abbrev:get_selected_item()
	if sel_item == -1 then return end
	local expansion = list_abbrev:get_item_data(sel_item)
	expansion = expansion:gsub('\\r','\r'):gsub('\\n','\n'):gsub('\\t','\t')
	editor:CallTipCancel()
	editor:CallTipShow(editor.CurrentPos, expansion)
end

list_abbrev:on_double_click(function()
	Abbreviations_InsertExpansion()
end)

list_abbrev:on_select(function()
	Abbreviations_ShowExpansion()
end)

list_abbrev:on_key(function(key)
	if key == 13 then -- Enter
		Abbreviations_InsertExpansion()
	end
end)

----------------------------------------------------------
-- Events
----------------------------------------------------------
local function OnSwitch()
	if tonumber(props['sidebar.show'])~=1 then return end
	if tab_index == 0 then
		local path = props['FileDir']
		if path == '' then return end
		path = path:gsub('\\$','')..'\\'
		if path ~= current_path then
			current_path = path
			FileMan_ListFILL()
		end
	elseif tab_index == 1 then
--~ 		Functions_GetNames() Functions_ListFILL() --[mhb] uncommented
		Bookmarks_ListFILL()

		--[mhb] added: to support panel of functions/procedures list
		funcs_FILL()
		
	elseif tab_index == 2 then
		Abbreviations_ListFILL()
	elseif tab_index == 3 then
		doc:clear()
		docs_FILL()
	elseif tab_index == 4 then
		--[mhb] modified 01/16/09: to fill ref,cite,sbf for tex files
		local typ=props['FileType']
		if typ=='tex' or typ=='latex' then
			fill_items(ref,cite,sbf)
		else
			ref:clear()
			cite:clear()
			sbf:clear()
		end
	end
end

tabs:on_select(function(ind)
	tab_index=ind
	OnSwitch()
end)


function SideBar_ShowHide()
	if tonumber(props['sidebar.show'])==1 then
		if win then
			win_parent:hide()
		else
			gui.set_panel()
		end
		props['sidebar.show']=0
	else
		if win then
			win_parent:show()
		else
			gui.set_panel(win_parent,props['sidebar.position'] or 'left')
		end
		props['sidebar.show']=1
		OnSwitch()
	end
end

show_hide=SideBar_ShowHide
props['sidebar.show']=1
scite_OnOpen(OnSwitch)
scite_OnSwitchFile(OnSwitch)

--[[
-- Add user event handler OnUpdateUI
local line_count = 0
local function on_updateUI()
	local line_count_new = editor.LineCount
	if line_count_new ~= line_count then
		OnSwitch()
		line_count = line_count_new
	end
	return nil
end

scite_OnUpdateUI(on_updateUI)

]]--

-- Add user event handler OnSendEditor
local old_OnSendEditor = OnSendEditor
function OnSendEditor(id_msg, wp, lp)
	local result
	if old_OnSendEditor then result = old_OnSendEditor(id_msg, wp, lp) end
	if id_msg == SCI_MARKERADD then
		if lp == 1 then Bookmark_Add(wp) Bookmarks_ListFILL() end
	elseif id_msg == SCI_MARKERDELETE then
		if lp == 1 then Bookmark_Delete(wp) Bookmarks_ListFILL() end
	elseif id_msg == SCI_MARKERDELETEALL then
		if wp == 1 then Bookmark_Delete() Bookmarks_ListFILL() end
	end
	return result
end

-- Add user event handler OnFinalise
local old_OnFinalise = OnFinalise
function OnFinalise()
	local result
	if old_OnFinalise then result = old_OnFinalise() end
	Favorites_SaveList()
	if table.getn(list_prj_table)>0 then 
		prj_SaveTo(prj_filename)
	end
	return result
end
