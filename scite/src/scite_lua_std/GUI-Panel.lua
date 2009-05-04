-- Tabbed side panel for SciTE
-- Based on original work of Steve D
-- Extended substentially by instanton 

local append = table.insert
local current_path = props['FileDir']
local ext = props['FileExt']

local width = 160;

local FilesPanel = gui.panel(width)
local file_list = gui.list(false)
local dir_list = gui.list(false)

	file_list:set_list_colour("#DDDDDD","#000000") 
	dir_list:set_list_colour("#DDDDDD","#000000")

text_path = gui.memo()
FilesPanel:add(text_path, "top", 26)

	text_path:set_memo_colour("#DDDDDD","#000000") 

local function show_path()
	local file_mask = '*.*'
	local rtf = '{\\rtf{\\fonttbl{\\f0 MS Shell Dlg;}}{\\colortbl ;\\red128\\green128\\blue255;  \\red255\\green0\\blue0;}\\f0\\fs16'
	local path = '\\cf1'..string.gsub(current_path, '\\', '\\\\')..'\\\\'
	local mask = '\\cf2'..file_mask..'}'
	text_path:set_text(rtf..path..mask)
end


FilesPanel:add(dir_list,"top",200)
FilesPanel:client(file_list)

function all_files() -- note not local function!
	current_ext = '*'
	fill()
end

function same_ext_only() -- note not local function!
	current_ext = props['FileExt']
	fill()
end


FilesPanel:context_menu {
	scite.GetTranslation('Show all files')..'|all_files',
	scite.GetTranslation('Only current ext')..'|same_ext_only',
}

local PalettesPanel = gui.panel(width)
local GreekLetters = gui.list(true)
local mathematics = gui.list(true)
local environments = gui.list(true)

local MathName="Math"
MathName=scite.GetTranslation(MathName)
local GreekName="Greek"
GreekName=scite.GetTranslation(GreekName)
local EnvName="Environments"
EnvName=scite.GetTranslation(EnvName)

mathematics:add_column(MathName,width-18)
GreekLetters:add_column(GreekName,width-18)
environments:add_column(EnvName,width-18)

	GreekLetters:set_list_colour("#FF55FF","#000000") 
	mathematics:set_list_colour("#5555FF","#000000") 
	environments:set_list_colour("#55FF55","#000000") 

PalettesPanel:add(GreekLetters,"top",150)
PalettesPanel:add(mathematics,"top",140)
PalettesPanel:client(environments)

local greek = {'\\alpha'; '\\beta'; '\\gamma'; '\\delta'; '\\epsilon'; '\\varepsilon'; 
'\\zeta'; '\\eta'; '\\theta'; '\\vartheta'; '\\iota'; '\\kappa'; '\\lambda'; '\\mu'; 
'\\nu'; '\\xi'; '\\pi'; '\\varpi'; '\\rho'; '\\varrho'; '\\sigma'; '\\varsigma'; '\\tau'; 
'\\upsilon'; '\\phi'; '\\varphi'; '\\chi'; '\\psi'; '\\omega'; '\\varkappa'; '\\Gamma'; 
'\\Delta'; '\\Theta'; '\\Lambda'; '\\Xi'; '\\Pi'; '\\Sigma'; '\\Upsilon'; '\\Phi'; 
'\\Psi'; '\\Omega'; '\\digamma'}
table.sort(greek)
for _,k in pairs(greek) do
	GreekLetters:add_item{k}
end

local math_symb = {'\\frac';'\\sqrt';'\\partial','\\infty';'\\limit';'\\sum';'\\times';
'\\otimes';'\\langle';'\\rangle';'\\left';'\\right';'\\nabla';'\\pm';'\\subset';'\\in';'\\sin';'\\cos';
'\\tan';'\\cot';'\\sec';'\\csc';'\\exp';'\\log';'\\int';'\\label'}
table.sort(math_symb)
for _,k in pairs(math_symb) do
	mathematics:add_item{k}
end

local environmentss ={'equation'; 'eqnarray'; 'align'; 'itemize'; 'enumerate'; 'description'; 
'theorem'; 'displaymath'; 'array'; 'figure'; 'listing'; 'comment'; 'table'; 'tabular'; 
'frame'; 'thebibliography';'align*';'eqnarray*'}
table.sort(environmentss)
for _,k in pairs(environmentss) do
	environments:add_item{k}
end


local ListPanel = gui.panel(width)
local ref = gui.list(true)
local cite= gui.list(true)
local subfile = gui.list(true)

	ref:set_list_colour("#999999","#000000") 
	cite:set_list_colour("#999999","#000000") 
	subfile:set_list_colour("#999999","#000000") 

local LabelName='Labels'
LabelName=scite.GetTranslation(LabelName)
local BibitemName='Bibitems'
BibitemName=scite.GetTranslation(BibitemName)
local SubFileName='SubFiles'
SubFileName=scite.GetTranslation(SubFileName)

ref:add_column(LabelName,width-18)
cite:add_column(BibitemName,width-18)
subfile:add_column(SubFileName,width-18)

ListPanel:add(cite,"top",150)
ListPanel:add(ref,"top",140)
ListPanel:client(subfile)


local panel = gui.panel(width)
local tabs = gui.tabbar(panel)

local FilesPanelName="File"
FilesPanelName=scite.GetTranslation(FilesPanelName)
local PalettesPanelName="Palette"
PalettesPanelName=scite.GetTranslation(PalettesPanelName)
local ListPanelName="List"
ListPanelName=scite.GetTranslation(ListPanelName)

tabs:add_tab(FilesPanelName,FilesPanel)
tabs:add_tab(PalettesPanelName,PalettesPanel)
tabs:add_tab(ListPanelName,ListPanel)

panel:client(PalettesPanel)
panel:client(ListPanel)
panel:client(FilesPanel)
gui.set_panel(panel,"left")


GreekLetters:on_double_click(function(idx)
	if not (idx == -1) then
		local item = GreekLetters:get_item_text(idx)..' '
		if item then 
			local pos = editor.CurrentPos + string.len(item)
			local sel = editor:GetSelText()
			if (sel=="") then
				editor:InsertText(-1,item) 
			else 
				editor:ReplaceSel(item)
			end
			editor:GotoPos(pos)
			editor:GrabFocus()
		end
	end
end)

mathematics:on_double_click(function(idx)
	if not (idx == -1) then
		local item = mathematics:get_item_text(idx)..' '
		if item then 
			local pos = editor.CurrentPos + string.len(item)
			local sel = editor:GetSelText()
			if (sel=="") then
				editor:InsertText(-1,item) 
			else 
				editor:ReplaceSel(item)
			end
			editor:GotoPos(pos)
			editor:GrabFocus()
		end
	end
end)

environments:on_double_click(function(idx)
	if not (idx == -1) then
		local item = environments:get_item_text(idx)
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

local function fill_items(ref,cite,subfile)
	ref:clear()
	local lbl = list_after_word('label')
	for _,v in pairs(lbl) do
		ref:add_item{v}
	end

	cite:clear()
	local tbl = list_after_word('bibitem')
	for _,v1 in pairs(tbl) do
		cite:add_item{v1}
	end

	subfile:clear()
	local sf = subfile_list()
	for _,v in pairs(sf) do
		subfile:add_item{v,v}
	end
	show_path()
end

ref:on_double_click(function(idx)
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

cite:on_double_click(function(idx)
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




function name_of (f)
    return f:match('([^\\]+)%.%w+$')
end

local dirsep = '\\'

local function makepath (f)
    return current_path..dirsep..f
end

subfile:on_double_click(function(idx)
	if not (idx == -1) then
		local file = subfile:get_item_text(idx)
		scite.Open(makepath(file))
	end
end)

-- ---------------------------------------------

function fill ()
    local mask_base = makepath('*.')
	local mask = mask_base..current_ext
	local files = gui.files(mask)
--    local same_ext = true
	file_list:clear()
    -- note that gui.files will not return a table if there were no contents!
    if not files then
        files = gui.files(mask_base..'*')
        same_ext = false
    end
	if files then
		for i,f in ipairs(files) do
            local name = f
--            if same_ext then name = name_of(name) end
			file_list:add_item(name,f)
		end
	end
	local dirlist = gui.files(makepath('*'),true)
	dir_list:clear()
	dir_list:add_item ('[..]','..')
	for i,d in ipairs(dirlist) do
		dir_list:add_item('['..d..']',d)
	end
	show_path()
end

file_list:on_double_click(function(idx)
	if not (idx == -1) then
		local file = file_list:get_item_data(idx)
		scite.Open(makepath(file))
	end
end)

dir_list:on_double_click(function(idx)
	if not (idx == -1) then
		local dir = dir_list:get_item_data(idx)
		gui.chdir(dir)
		if dir == '..' then
			current_path = string.gsub(current_path,"(.*)\\.*$", "%1")
		else
			current_path = current_path..'\\'..dir
		end
		fill()
	end
end)

--[[
function OnCommand (id)
    if id == IDM_BOOKMARK_TOGGLE then
        local line = editor:GetCurLine()
        -- is this line already in the list?
        local inserting = true
        for i = 0,bookmarks:count() - 1 do
            if bookmarks:get_item_text(i) == line then
                bookmarks:delete_item(i)
                inserting = false
                break
            end
        end
        if inserting then
            local lno = editor:LineFromPosition(editor.CurrentPos)
            bookmarks:add_item(line,{props['FilePath'],lno})
        end
    end
end

bookmarks:on_double_click(function(idx)
	if not (idx == -1) then
		local pos = bookmarks:get_item_data(idx)
        scite.Open(pos[1])
        editor:GotoLine(pos[2])
    end
end)
--]]

local function on_switch ()
	local path = props['FileDir']
	local ext = props['FileExt']
    if path == '' then return end
	if path ~= current_path or ext ~= current_ext then
		current_path = path
		current_ext = ext
		fill()
	end
	
	fill_items(ref,cite,subfile)
end

local oldOnSwitchFile = OnSwitchFile
local oldOnOpen = OnOpen

function OnSwitchFile(file)
	on_switch()
	if oldOnSwitchFile then oldOnSwitchFile(file) end
end

function OnOpen(file)
	on_switch()
	if oldOnOpen then oldOnOpen(file) end
end

-- ----------------------------------------------


props['sidebar.show'] = 1
function show_hide()
	if tonumber(props['sidebar.show'])==1 then
		panel:size(0, 0)
		props['sidebar.show'] = 0
	else
		panel:size(width, 0)
		props['sidebar.show'] = 1
	end
end