-- scite_Command '输入环境begin|tex_begin|Ctrl+Alt+B'
-- scite_Command '输入分式frac|tex_frac|Ctrl+Alt+F'
-- scite_Command '输入偏导partial|tex_partial|Ctrl+Alt+P'
-- scite_Command '输入矩阵matrix|tex_matrix|Ctrl+Alt+M'
--scite_require menucmds.lua

prevquote="'";
nextquote="`";

function ReplaceQuote()
	editor:DeleteBack();
	add_char(nextquote);add_char(nextquote);
	prevquote, nextquote = nextquote, prevquote;
end;


function CheckBlock()
	local m_end = 0;
	local senv, env, str, line
	if get_chars(0,0)=='%' then return;end
	line = editor:LineFromPosition(editor.CurrentPos);
	str = editor:GetLine(line-1);
	
	-- look for last \begin{foo}
	repeat
		senv = env;
		m_start, m_end, env = string.find(str, '\\begin{(%w-)}%s*$', m_end);
	until m_start == nil;
	
	--[mhb] 01/31/09: to check whether there is a matching \end{foo}
	if not senv then return; end
	str=''
	for i=line,line+10 do
		str=editor:GetLine(i);
		if string.find(str,'\\end{(%w-)}') then break;end
	end
	if string.find(str,'\\end{'..senv..'}') then return;end
	
	-- add \end{foo}
	if(senv) then
        editor:DeleteBack();
		local pos = editor.CurrentPos;
		editor:insert(pos,"%\n\n\\end{"..senv..'}');
        editor:LineDown();
	end;
end;

function CheckBlock2()
  local m_end = 0;
  local senv, env;
        
  line = editor:LineFromPosition(editor.CurrentPos);
  str = editor:GetLine(line);

  -- look for last \begin{foo}
  repeat
    senv = env;
    m_start, m_end, env = string.find(str, '\\begin{(%w-)}}', m_end);
  until m_start == nil;
        
  -- add \end{foo}        
  if(senv) then
    local pos = editor.CurrentPos;
    editor:DeleteBack();
    if (editor.LineCount==line+1) then
      editor:insert(-1, '\n');
    end
    editor:insert(pos,
      "*\n\\end{"..senv..'}\n');
    editor.LineIndentation[line+1] = editor.LineIndentation[line]+2;
    editor.LineIndentation[line+2] = editor.LineIndentation[line];
    editor:GotoPos(pos+editor.LineIndentation[line+1]);
    m_start, m_end = editor:findtext("[*]", SCFIND_REGEXP, pos+1);
    if (m_start~=nil) and (m_end~=nil) then
      editor:SetSel(m_start, m_end);
    end
end;        
end;


function CheckBlock3()
	local m_end = 0;
	local senv, env, str, line
	if get_chars(0,0)=='%' then return;end
	line = editor:LineFromPosition(editor.CurrentPos);
	str = editor:GetLine(line-1);
	
	-- look for last \startfoo
	repeat
		senv = env;
		m_start, m_end, env = string.find(str, '\\start(%w*)%s*', m_end);
	until m_start == nil;
	
	--[mhb] 01/31/09: to check whether there is a matching \stopfoo
	if not senv then return; end
	str=''
	for i=line,line+10 do
		str=editor:GetLine(i);
		if string.find(str,'\\stop(%w*)%s*') then break;end
	end
	if string.find(str,'\\stop'..senv..'') then return;end
	
	-- add \stopfoo
	if(senv) then
        editor:DeleteBack();
		local pos = editor.CurrentPos;
		editor:insert(pos,"%\n\n\\stop"..senv..'');
        editor:LineDown();
	end;
end;

function CheckBlock4()
  local m_end = 0;
  local senv, env;
        
  line = editor:LineFromPosition(editor.CurrentPos);
  str = editor:GetLine(line);

  -- look for last \startfoo
  repeat
    senv = env;
    m_start, m_end, env = string.find(str, '\\stop(%w+)%s*}', m_end);
  until m_start == nil;
        
  -- add \stopfoo
  if(senv) then
    local pos = editor.CurrentPos;
    editor:DeleteBack();
    if (editor.LineCount==line+1) then
      editor:insert(-1, '\n');
    end
    editor:insert(pos,"*\n\\stop"..senv..'\n');
    editor.LineIndentation[line+1] = editor.LineIndentation[line]+2;
    editor.LineIndentation[line+2] = editor.LineIndentation[line];
    editor:GotoPos(pos+editor.LineIndentation[line+1]);
    m_start, m_end = editor:findtext("[*]", SCFIND_REGEXP, pos+1);
    if (m_start~=nil) and (m_end~=nil) then
      editor:SetSel(m_start, m_end);
    end
end;        
end;

function add_tags(a, b)
	if(editor:GetSelText() ~= '') then
		editor:ReplaceSel(a .. editor:GetSelText() .. b);
	else
		editor:insert(editor.CurrentPos, a..b);
		editor:GotoPos(editor.CurrentPos + string.len(a));
	end;
end

function add_char(a)
	if(editor:GetSelText() ~= '') then
		editor:ReplaceSel(a .. editor:GetSelText());
	else
		editor:insert(editor.CurrentPos, a);
		editor:GotoPos(editor.CurrentPos + string.len(a));
	end;
end


-- TeX commands --------
function tex_frac()
	add_tags('\\frac{', '}{}');
end;

function tex_sqrt()
	add_tags('\\sqrt{', '}');
end;

function tex_partial()
	add_tags('\\partial{', '}');
end;

function tex_begin()
	add_tags('\\begin{', '}');
end;

function tex_chapter()
	add_tags('\\chapter{', '}');
end;

function tex_section()
	add_tags('\\section{', '}');
end;

function tex_subsection()
	add_tags('\\subsection{', '}');
end;

function tex_braces()
	add_tags('{', '}');
end;
function tex_matrix()
    add_tags('\\left[\\matrix{ ',' & \\cr   & \\cr}\\right]')
end;

function tex_makearray()
	if(editor:GetSelText() == '') then
		return;
	end;
	
	local mytext = editor:GetSelText();
	mytext = string.gsub(mytext, "\t", "\t& ");
	mytext = string.gsub(mytext, "\n", "\\\\\n");
	editor:ReplaceSel(mytext);
end;

function tex_documentclass()
	add_tags('\\documentclass{','}');
end;

function tex_usepackage()
	add_tags('\\usepackage{','}');
end;

function tex_titlepage()
	add_char('titlepage');
end;

function tex_article()
	add_char('article');
end;



-- Greek Letter input
------------------------
function tex_alpha()
	add_char('\\alpha');
end;

function tex_beta()
	add_char('\\beta');
end;

function tex_chi()
	add_char('\\chi');
end;

function tex_gamma()
	add_char('\\gamma');
end;

function tex_Gamma()
	add_char('\\Gamma');
end;

function tex_delta()
	add_char('\\delta');
end;

function tex_Delta()
	add_char('\\Delta');
end;

function tex_epsilon()
	add_char('\\epsilon');
end;

function tex_lambda()
	add_char('\\lambda');
end;

function tex_Lambda()
	add_char('\\Lambda');
end;

function tex_kappa()
	add_char('\\kappa');
end;

function tex_omega()
	add_char('\\omega');
end;

function tex_mu()
	add_char('\\mu');
end;

function tex_nu()
	add_char('\\nu');
end;

function tex_phi()
	add_char('\\phi');
end;

function tex_Phi()
	add_char('\\Phi');
end;

function tex_psi()
	add_char('\\psi');
end;

function tex_Psi()
	add_char('\\Psi');
end;

function tex_Omega()
	add_char('\\Omega');
end;

function tex_omega()
	add_char('\\varphi');
end;

function tex_sigma()
	add_char('\\sigma');
end;

function tex_Sigma()
	add_char('\\Sigma');
end;

function tex_tau()
	add_char('\\tau');
end;

function tex_theta()
	add_char('\\theta');
end;

function tex_Theta()
	add_char('\\Theta');
end;

function tex_eta()
	add_char('\\eta');
end;

function tex_zeta()
	add_char('\\zeta');
end;

function tex_ipsilon()
	add_char('\\ipsilon');
end;

function tex_pi()
	add_char('\\pi');
end;

function tex_Pi()
	add_char('\\Pi');
end;

function tex_rho()
	add_char('\\rho');
end;

function tex_upsilon()
	add_char('\\upsilon');
end;

function tex_Upsilon()
	add_char('\\Upsilon');
end;

function tex_omega()
	add_char('\\omega');
end;

function tex_xi()
	add_char('\\xi');
end;

function tex_Xi()
	add_char('\\Xi');
end;
-- TeX Key words
function tex_eqnarray()
	add_char('eqnarray');
end;

function tex_equation()
	add_char('equation');
end;

function tex_displaymath()
	add_char('displaymath');
end;

function tex_figure()
	add_char('figure');
end;

function tex_array()
	add_char('array');
end;

function tex_itemize()
	add_char('itemize');
end;

-- var greek letters ---------
function tex_varphi()
	add_char('\\varphi');
end;

function tex_varsigma()
	add_char('\\varsigma');
end;

function tex_varepsilon()
	add_char('\\varepsilon');
end;

function tex_vartheta()
	add_char('\\vartheta');
end;

function tex_varrho()
	add_char('\\varrho');
end;

-- LaTeX abbrivations encoder and decoder
-- original idea by kmc, latex_abbrev_dec() modified by qihs

function latex_abbrev_enc()
        local sel        =        editor:GetSelText()
        if sel == '' then
                return
        end
        sel = string.gsub(sel, '\\', "\\\\")
        sel = string.gsub(sel, '\r\n', "\\n")
        sel = string.gsub(sel, '\t', "\\t")
        editor:ReplaceSel(sel)
end

--[[
function latex_abbrev_dec()
        local sel        =        editor:GetSelText()
        if sel == '' then
                return
        end
        sel = string.gsub(sel, '(\\t)(%W)', '\t%2')
        sel = string.gsub(sel, '(\\n)(%W)', '\r\n%2')
        sel = string.gsub(sel, '\\\\', '\\')
        editor:ReplaceSel(sel)
end
]]--

function latex_abbrev_dec()
        local sel = editor:GetSelText()
        if not sel or sel == '' then
                return
        end
        local m = {t = '\t', n = '\n', ['\\'] = '\\'}
        sel = string.gsub(sel,'\\[tn\\]',
                function(s)
                        return m[string.sub(s,2,2)]
                end)
        editor:ReplaceSel(sel)
end



scite_OnChar(function(char)
  local ext=props['FileExt']
  local res
  if not editor.Focus then return false;end
  local sel=editor:GetSelText()
  
  local brace_auto=props['AUTO_COMPLETE_BRACE']
  if brace_auto~='0' then
    if(char=="(") then 
        add_tags("",")");
    elseif(char=="[") then 
        add_tags("","]");  
    elseif(char=="{") then 
        add_tags("","}");
    elseif(char=="<" and editor.Lexer==SCLEX_HTML) then 
        add_tags("",">");
    end;
  end

  local quote_auto=props['AUTO_COMPLETE_QUOTE']
  if quote_auto~='0' and editor.Lexer~=SCLEX_LATEX and editor.Lexer~=SCLEX_TEX  then
    if(char=="'") then 
        add_tags("","'");
    elseif(char=='"') then 
        add_tags("",'"');  
    end;
  end

  if editor.Lexer==SCLEX_LATEX or editor.Lexer==SCLEX_TEX then 
	if(char=="`" and quote_auto~='0') then 
        add_tags("","'");
	elseif(char=='"' and quote_auto~='0') then
		ReplaceQuote();
	elseif(char=="\n") then
		if props['TEX_COMPLETE_ENVIRONMENT']~='0' then
			CheckBlock();
		end
		if props['CONTEXT_COMPLETE_COMMAND']~='0' then
			CheckBlock3();
		end
	elseif(char=="}") then
		if props['TEX_COMPLETE_ENVIRONMENT']~='0' then
			CheckBlock2();
		end
		if props['CONTEXT_COMPLETE_COMMAND']~='0' then
			CheckBlock4();
		end
	elseif(char=="^" and props['TEX_SUPERSCRIPT']~='0') then
		tex_braces();
	elseif(char=="_" and props['TEX_SUBSCRIPT']~='0') then
		tex_braces();
	elseif(char=='$' and props['TEX_DOUBLE_DOLLAR']~='0') then
		add_tags('','$');
	end;
	
	--[mhb] added 04/23/09: to provide easy \cite{} and \ref{}, require myrefbib.lua
	if Check_RefBib then
		Check_RefBib();
	end
  end;
end
);


local old_OnClick=OnClick
function OnClick(shift, ctrl, alt)
   local result
   if old_OnClick then result = old_OnClick(shift, ctrl, alt) end
   if (editor.Lexer==SCLEX_LATEX or editor.Lexer==SCLEX_TEX) and Check_RefBib then 
		Check_RefBib()
   end
   return result
end
