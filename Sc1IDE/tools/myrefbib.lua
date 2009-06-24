--[mhb] added 04/23/09: to provide easy \cite{} and \ref{}
local pattern_label={'\\label{(%a.-)}','\\eq%[(%a.-)%]'}
local pattern_index={'\\index{(%a.-)}'}
local pattern_bibitem={'\\bibitem%s*%{([^}]+)%}'}
local pattern_bibentry={'@.+%{(.+),'}
local pattern_subfile={'\\input{(%a.-)}','\\input%s+(%a.-)','\\include{(%a.-)}','\\include%s+(%a.-)}'}
local pattern_package={'\\usepackage.*%{(.*)%}'}
local pattern_figure={'\\includegraphics.*%{(.*)%}'}
local pattern_table={'\\begin%s*{tabular}'}
local pattern_header={'\\part','\\chapter', '\\section', '\\subsection', '\\subsubsection', '\\paragraph', '\\appendix', '\\bibliography', '\\title', '\\documentclass', '\\usepackage'}
local pattern_font={'\\set.*font%{(.*)%}'}


tex_packages=nil
function list_packages(debug)
	local tbl=findall(pattern_package,debug)
	tex_packages=tbl --[mhb] 04/23/09: saved in global table so that other files can use it
	return tbl.w1
end

tex_figures=nil
function list_figures(debug)
	local tbl=findall(pattern_figure,debug)
	tex_figures=tbl --[mhb] 04/23/09: saved in global table so that other files can use it
	return tbl.w1
end

tex_tables=nil
function list_tables(debug)
	local tbl=findall(pattern_table,debug)
	tex_tables=tbl --[mhb] 04/23/09: saved in global table so that other files can use it
	return tbl.w1
end

tex_labels=nil
function list_labels(debug)
	local tbl=findall(pattern_label,debug)
	tex_labels=tbl --[mhb] 04/23/09: saved in global table so that other files can use it
	return tbl.w1
end

tex_indexs=nil
function list_indexs(debug)
	local tbl=findall(pattern_index,debug)
	tex_indexs=tbl --[mhb] 04/23/09: saved in global table so that other files can use it
	return tbl.w1
end

tex_fonts=nil
function list_fonts(debug)
	local tbl=findall(pattern_font,debug)
	tex_fonts=tbl --[mhb] 04/23/09: saved in global table so that other files can use it
	return tbl.w1
end

tex_headers=nil
function list_headers(debug)
	local tbl=findall(pattern_header,debug)
	tex_headers=tbl --[mhb] 04/23/09: saved in global table so that other files can use it
	return tbl.w1
end


tex_subfiles=nil
function list_subfiles(debug)
	local tbl=findall(pattern_subfile,debug)
	tex_subfiles=tbl --[mhb] 04/23/09: saved in global table so that other files can use it
	local res=tbl.w1
	for _,v in ipairs(res) do
		if not string.find(v,'.',1,true) then
			res[_]=v..'.tex'
		end
	end
	return res
end

function list_bibentries(bib_file,debug)
	local tbl=f_findall(bib_file,pattern_bibentry,debug)
	return tbl.w1
end

function list_bibitems(tex_file,debug)
	local tbl=f_findall(tex_file,pattern_bibitem,debug)
	return tbl.w1
end

function list_bibfiles(tex_file)
	local tbl=f_findall(tex_file,'\\bibliography%{([^}]+)%}')
	local res={}
    local vvv
	if tbl then
		for _,v in ipairs(tbl.w1) do
			local files=split(v,',') or {}
			for __,vv in ipairs(files) do
				if not string.find(vv,'%.%w+$') then
                    vvv=vv..'.bib'
				else
                    vvv=vv
				end
                table.insert(res,vvv)
			end
		end
	end
    return res
end

tex_bibitems=nil --[mhb] 04/23/09

function list_all_bibitems(tex_file,debug,sort_items,ignore_bibfile) 
    if not tex_file then
        tex_file=props['FilePath']
    end
    local res=list_bibitems(tex_file,debug)
	if not ignore_bibfile then
		local tbl=list_bibfiles(tex_file,debug)
		for _,bib_file in ipairs(tbl) do 
			if not string.find(bib_file,'[/\\]') then
				bib_file=props['FileDir']..'/'..bib_file
			end
		
			local bibs=list_bibentries(bib_file,debug)
			for _,v in ipairs(bibs) do 
				table.insert(res,v)
			end
		end 
	end
    if sort_items then table.sort(res) end
	tex_bibitems=res --[mhb] 04/23/09: saved in global table so that other files can use it
    return res
end

function show_all_bibitems()
	list_all_bibitems(props['FilePath'],true,false,true)
end


function sel_refbib(s) 
	editor:insert(editor.CurrentPos, s);
	editor:GotoPos(editor.CurrentPos + string.len(s));
end


function Check_RefBib()
	local res={}
    if get_chars(-5,0)=='\\ref{}' then
		output:ClearAll()
		res=list_labels(true)
	elseif get_chars(-6,0)=='\\cite{}' then
		output:ClearAll()
		if not tex_bibitems then
			res=findall(pattern_bibitem,true)
			res=res.w1
		else
			res=tex_bibitems
			for _,v in ipairs(res) do 
				print(v)
			end
		end
	end
	if table.getn(res)>0 then
		scite_UserListShow(res,1,sel_refbib)
	end
end
