local function show_autolist(list)
	local list_str='';
	local sep = string.char(editor.AutoCSeparator)
	for _,v in pairs(list) do list_str = list_str..v..sep end
	editor:AutoCShow(0, list_str)
end

local function PrevNonemptyChar(pos)
	local rstr;
	local p = pos;
	rstr = editor:textrange(p-1,p);
	while(rstr ==' ') do
		p = p -1;
		rstr = editor:textrange(p-1,p);
	end
	return rstr;
end

local function NextNonemptyChar(pos)
	local rstr;
	local p = pos;
	rstr = editor:textrange(p,p+1);
	while(rstr ==' ') do
		p = p +1;
		rstr = editor:textrange(p,p+1);
	end
	return rstr;
end

local function InsideCommandRange(pos,command)
	local rstr;
	local p = pos;
	local len = string.len(command);
	rstr = editor:textrange(p-1,p);
	while(p > 0 and rstr ~='{' and rstr ~='}') do
		p = p -1;
		rstr = editor:textrange(p-1,p);
	end
	if(rstr == '{') then
		local str = editor:textrange(p-len-1,p-1);
		if(str == command) then 
			return true
		end
	elseif(rstr == '}') then 
		return nil
	end
	return nil
end

function table_count(tt, item)
  local count
  count = 0
  for ii,xx in pairs(tt) do
    if item == xx then count = count + 1 end
  end
  return count
end

local function table_unique(tt)
  local newtable
  newtable = {}
  for ii,xx in ipairs(tt) do
    if(table_count(newtable, xx) == 0) then
      newtable[#newtable+1] = xx
    end
  end
  return newtable
end

local function NextCharPos(pos,char)
	local rstr;
	local p = pos;
	rstr = editor:textrange(p,p+1);
	while(rstr ~=char and p < editor.TextLength) do
		p = p + 1;
		rstr = editor:textrange(p,p+1);
	end
	if(rstr ==char) then 
		return p;
	else
		return nil
	end
end

local function PrevCharPos(pos,char)
	local rstr;
	local p = pos;
	rstr = editor:textrange(p-1,p);
	while(rstr ~=char) do
		if(p == 0) then return nil; end
		p = p - 1;
		rstr = editor:textrange(p-1,p);
	end
	return p;
end

local function NotInComment(pos)
	local line_begin;
	if(PrevCharPos(pos,'\n') ==nil) then 
		line_begin = 0;
	else
		line_begin = PrevCharPos(pos,'\n')+1;
	end
	local last_cpos = PrevCharPos(pos,'\%');
	if last_cpos  == nil then
		return true;
	elseif last_cpos < line_begin then 
		return true; 
	else
		return nil
	end
end

local function IsTeXCommand(pos)
	local char = editor:textrange(pos-1,pos);
	if(char == '\\') then
		return true;
	else
		return nil
	end
end

function list_after_word(word)
	local list = {};
	local label, findstring;
	if(word == nil) then return; end
	findstring = word..'{.*}';
	for label in editor:match(findstring,SCFIND_REGEXP,0) do
		local _, _, env = string.find(label.text, '{(.-)}');
		table.insert(list, env)
	end
	table.sort(list)
	return list
end

local function show_list_after(word)
	local list = list_after_word(word);
	show_autolist(list);
end


function ArgumentList(command)
	local list = {};
	local str;
--    local flags = SCFIND_WHOLEWORD
    local flags = SCFIND_REGEXP
	
    local s,e = editor:findtext(command,flags,0)
    while s and IsTeXCommand(s) and (NextNonemptyChar(e) =='{' or NextNonemptyChar(e) =='[') do
		if NotInComment(s) then
			local char = editor:textrange(e,e+1);
			if(char == '[') then e = NextCharPos(e+1,']'); end
			local s1 = NextCharPos(e,'{');
			local e1 = NextCharPos(e+1,'}');
			if(s1 and e1 and s1 < e1-1) then
				comma_pos = NextCharPos(s1,',');
				local s2 = s1;
				while (comma_pos and comma_pos < e1) do
					str = editor:textrange(s2+1,comma_pos);
					if(str ~= nil) then
						table.insert(list, str);
					end
					s2 = comma_pos;
					comma_pos = NextCharPos(s2+1,',');
				end
				if (s2 < e1-1 ) then
					str = editor:textrange(s2+1,e1);
					if(str ~= nil) then
						table.insert(list, str);
					end
				end
			end
		end
        s,e = editor:findtext(command,flags,e+1)
    end
	
	list = table_unique(list);
	table.sort(list)
	return list
end

function package_list()
	local list = ArgumentList("usepackage");
	show_autolist(list);
end

function CheckRefList()	
	local pos = editor.CurrentPos;
	local cstr = PrevNonemptyChar(pos);
	local list;

	if(InsideCommandRange(pos,'ref') and cstr == '{') then
		show_list_after('label')
	elseif(InsideCommandRange(pos,'cite') and (cstr ==',' or cstr =='{')) then
		show_list_after('bibitem')
	end
end

function subfile_list()
	local list1 = ArgumentList("input");
	local list2 = ArgumentList("include");
	local list ={};
	
	for _,v in pairs(list1) do
		v = string.gsub(v,'/','\\');
		table.insert(list, v);
	end
	for _,v in pairs(list2) do
		v = string.gsub(v,'/','\\');
		table.insert(list, v..'.tex');
	end
	table.sort(list)
	return list
end

function show_subfile_list()
	local list = subfile_list()
	show_autolist(list)
end

function Open_subfiles()
	local list = subfile_list();
	for _,file in pairs(list) do 
		scite.Open(file)
	end
end

function show_tex_argumentlist()
	local list = list_after_word("begin");     -- can use ArgumentList, but this one is faster.
	list = table_unique(list);
	show_autolist(list)
end

function bibfile_list()
	local list1 = ArgumentList("bibliography")
	local list = {}
	for _,v in pairs(list1) do
		v = v..'.bib';
		table.insert(list, v);
	end
	return list
end

function show_bibfile_list()
	local list = bibfile_list()
	show_autolist(list)
end

function index_list()
	local list = ArgumentList("index")
	show_autolist(list)
end

function graphicsfile_list()
	local list1 = ArgumentList("includegraphics")
	local list = {}
	for _,v in pairs(list1) do
		local _,_,str = string.find(v, '\.')
		if (not str) then
			table.insert(list, v.."(eps/pdf)")
		end
	end
	show_autolist(list)
end	

function xetex_fontlist()
	local command = 'set'..'.*'..'font';
	local list= ArgumentList(command)
	show_autolist(list)
end

function tex_greekletters()
	local greek = {'alpha'; 'beta'; 'gamma'; 'delta'; 'epsilon'; 'varepsilon'; 'zeta'; 'eta';
	'theta'; 'vartheta'; 'iota'; 'kappa'; 'lambda'; 'mu'; 'nu'; 'xi'; 'pi'; 'varpi'; 
	'rho'; 'varrho'; 'sigma'; 'varsigma'; 'tau'; 'upsilon'; 'phi'; 'varphi'; 'chi'; 
	'psi'; 'omega'; 'varkappa'; 'Gamma'; 'Delta'; 'Theta'; 'Lambda'; 'Xi'; 'Pi'; 
	'Sigma'; 'Upsilon'; 'Phi'; 'Psi'; 'Omega'; 'digamma'}
	table.sort(greek)
	show_autolist(greek)
end

function tex_environments()
	local env ={'equation'; 'eqnarray'; 'align'; 'itemize'; 'enumerate'; 'description'; 'theorem'; 
	'displaymath'; 'array'; 'figure'; 'listing'; 'comment'; 'table'; 'tabular'; 'frame'}
	table.sort(env)
	show_autolist(env)
end

function tex_math()
	local math_symb = {'\\frac';'\\sqrt';'\\partial','\\infty';'\\limit';'\\sum';'\\times'}
	show_autolist(math_symb)
end

function tex_headercmds()
	local headers ={'\\part','\\chapter'; '\\section'; '\\subsection'; '\\subsubsection'; '\\paragraph';
	'\\appendix'; '\\bibliography'; '\\title'; '\\documentclass'; '\\usepackage'}
	table.sort(headers)
	show_autolist(headers)
end

function show_codepage()
	print(editor.CodePage);
end



