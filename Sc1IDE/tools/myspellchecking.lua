--[mhb] new version of my previous mini-spell-checking
-- this version uses m_spell.dll to look up words 
Err=showmsg
local user_dict_file=props['spell.user_dict'] or props['SciteDefaultHome']..'\\m_spell.usr'
local user_dict={}
local word_list={}
local word_chars={
   tex='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
   latex='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
}

local com_delims='\\\t\n\r#$%&~(){}[]<>=+-/*|^.,;:?!@~_ '
local delims={
   tex=com_delims,
   latex=com_delims,
   lua=com_delims,
}

-- local in_file='c:\\temp\\m_spell.in'
-- local out_file='c:\\temp\\m_spell.out'
local env_in='MSPELL_WORD'
local env_out='MSPELL_SUGGESTIONS'
local ini_file=props['SciteDefaultHome']..'\\m_spell.ini'


local mspell_dll=props['SciteDefaultHome']..'/lib/m_spell.dll'
local sp_init=package.loadlib(mspell_dll,'SpellCheckerInit')
local sp_exit=package.loadlib(mspell_dll,'SpellCheckerExit')
local spell_suggestions=package.loadlib(mspell_dll,'SpellCheckerSuggestions')
local sp_load_userdicts=package.loadlib(mspell_dll,'ReadUserDicts')

local speller_inited=false
-- Err(mspell_dll)

local function write_spell_ini()
   local keys={
   -- 'in_file','out_file',
   'debugging','index_level','max_errors','max_error_ratio','max_word_length','max_lookups','max_suggestions','check_uppercase','check_ignore_case','keep_capital_initial','dict_path','dict_file','userdict_file'
   }
   local s=''
   for _,v in ipairs(keys) do
      s=s..v..'='..props['spell.'..v]..'\n'
   end
   for i=1,20 do 
      v='userdict_'..tonumber(i)
      s=s..v..'='..props['spell.'..v]..'\n'
   end
   f_write(ini_file,s)
end

function LoadUserDict(user_dict_file) 
   user_dict=f_read(user_dict_file,true) or {}
   for _,v in ipairs(user_dict) do 
      word_list[v]={}
   end
end

function SaveUserDict(user_dict_file) 
   if speller_inited then
      if tonumber(props['spell.user_dict.autosave']) == 1 then
         f_write(user_dict_file,user_dict)
         sp_load_userdicts()
      end
    end
end

function spell_init()
   if not sp_init then
     Err('Cannot find m_spell.dll!')
     return 0
   end
   -- in_file=props['spell.in_file'];
   -- out_file=props['spell.out_file'];
   word_list={}
   write_spell_ini()
   sp_init()
   print('Spell checker m_spell.dll loaded into memory!')
   
   LoadUserDict(user_dict_file) 
   print('User dict file loaded into memory!')
   
   speller_inited=true
   -- os.remove(ini_file)
end

function spell_exit()
   if not sp_exit then
-- 	print('Cannot find m_spell.dll!')
    return
   end
   sp_exit()
   word_list={}
-- Err('Spell checker m_spell.dll unloaded from memory!')
end


local function ErrorMark(p1,p2)
   editor.IndicatorCurrent = 1
   editor:IndicatorFillRange(p1,p2-p1)
end

local function ClearMark(p1,p2)
   editor.IndicatorCurrent = 1
   editor:IndicatorClearRange(p1,p2-p1)
end

function ClearErrorMarks()
   ClearMark(0,editor.Length)
end

--[mhb] 02/21/2010: spell checking suggestions are allocated to command i0~imax, 60~99 by default 
local i0=tonumber('0'..props['SPELL_CHECKING_NUM_MIN'])
local imax=tonumber('0'..props['SPELL_CHECKING_NUM_MAX'])
if i0==0 then i0=60 end
if imax==0 then imax=99 end


local function AddMenuSug(i,v,w)
   local j=i0+i
   if j>imax then return end
   props['command.'..tostring(j)..'.*']='dostring CorrectCurWord("'..v..'","'..w..'")'
   props['command.mode.'..tostring(j)..'.*']='subsystem:lua,savebefore:no'
end

local function is_non_word(p,delim) 
   if editor.CharAt[p]<0 then return true end
   local c=string.char(editor.CharAt[p])
   local res=true
   if string.find(delim,c,1,true) then 
      res=true
   elseif string.find(c,'[a-zA-Z]') then
      res=false
   end
   return res
end

function FindWordStart(pos,delim) 
   p=pos
	while p > -1 and not is_non_word(p,delim) do
		p = p - 1
	end
   p=p+1
   return p
end

function FindWordEnd(pos,delim) 
   p=pos
	while p<editor.Length-1 and not is_non_word(p,delim) do
		p = p + 1
	end
   return p
end



function GetCurWordRange() 
	local r={}
    local pane=editor
    r.sel=pane:GetSelText()
	r.pos=pane.CurrentPos
	r.no=pane:LineFromPosition(r.pos)
    r.p0=r.pos-1
   for i=1,10 do
      r.c=charat(r.pos-i)
      s=string.char(r.c)
      if string.find(s,'[%w\n\r]') then
         r.p0=r.pos-i
         break
      end
   end
   local del=delims[props['FileType']]
   if del then
      r.p1=FindWordStart(r.p0,del)
      r.p2=FindWordEnd(r.p1,del)
   elseif (r.sel~='') and (string.len(r.sel)<30) then
      r.p1=pane.SelectionStart
      r.p2=pane.SelectionEnd
   else
      r.p1=pane:WordStartPosition(r.p0,true)
      r.p2=pane:WordEndPosition(r.p0,true)
   end
   r.word=''
   if r.p2<=r.p1 then return;end
   if editor.Lexer==SCLEX_TEX or editor.Lexer==SCLEX_LATEX then
      if string.char(editor.CharAt[r.p1-1])=='\\' then
--          r.p1=r.p1-1
      end
   end
   
   r.word=editor:textrange(r.p1,r.p2)
   
--     r.line=pane:GetCurLine()
--    print(r.no,r.pos,r.line)
--    print(r.p0,r.p1,r.p2,r.word)
    return r
end


function GetSuggestions(w)
   local tbl=nil
   if not speller_inited then 
      spell_init()
      if not speller_inited then
         Err('Cannot initialize the spell checker library!')
         return
      end
   end
	set_env(env_in,w) -- [mhb] 08/07/12 -- f_write(in_file,w)
	spell_suggestions()
    local s=get_env(env_out)
    print(s)
	tbl=split_s(s,';') -- [mhb] 08/07/12 -- tbl=f_read(out_file,true)
    -- os.remove(in_file)
    -- os.remove(out_file)
    return tbl
end

function CheckCurWord(no_spelling_menu,show_words)
   local r=GetCurWordRange()
   if not r then return nil; end
   if not r.word then return nil; end
   local w=(r.word)
   local tbl=word_list[w]
   if not tbl then 
      tbl=GetSuggestions(w)
      word_list[w]=tbl
   end
      
   props['SPELL_CHECKING_MENUS']=''
   if not tbl then 
      ClearMark(r.p1,r.p2)
      return nil; 
   end
   if table.getn(tbl)<1 then return; end
--    print(r.p1,r.p2)
   ErrorMark(r.p1,r.p2)
   if show_words then
      output:Clear()
      local msg=table.concat(tbl,'\t')
      print('Please right-click the incorrect word to choose a suggestion!')
      print('Suggestions:',msg)
   end
   if no_spelling_menu then return tbl; end
   
   props['WORD_INCORRECT']=w
   local menu_sug=''
   for i,v in ipairs(tbl) do
      if i0+i<imax then --[mhb] 02/21/2010: only show limited suggestions 
         --menu_sug=menu_sug..tostring(i)..':'..v..'|'..tostring(9000+i0+i)..'|'
         menu_sug=menu_sug..v..'|'..tostring(9000+i0+i)..'|'
         AddMenuSug(i,v,w)
      end
   end
--    print(menu_sug)
   props['WORD_SUGGESTIONS']=menu_sug
   local s=scite.GetTranslation('Mini Spell Checking')
   props['SPELL_CHECKING_MENUS']='[$(WORD_INCORRECT)]|POPUPBEGIN|$(WORD_SUGGESTIONS)'..s..'[$(WORD_INCORRECT)]|POPUPEND|'
   return tbl
end 

function CheckSelection()
   local p1,p2,p
   local s=editor:GetSelText()
   if (s=='') then editor:SelectAll();end
   p1=editor.SelectionStart
   p2=editor.SelectionEnd
   editor:GotoPos(p1)
   p=p1
   repeat
      CheckCurWord(true)
      editor:WordRight()
      editor:CharRight()
      p=editor.CurrentPos
--       print(p)
   until p>=p2
end

function CorrectCurWord(v,w)
   local r=GetCurWordRange()
--    print(r.word,v,w)
   if w then
   if string.lower(r.word)~=string.lower(w) then
      CheckCurWord()
--       scite.SendEditor(314)
      return
   end
   end
   ClearMark(r.p1,r.p2)
   editor:SetSel(r.p1,r.p2)
   local i=string.find(v,',')
   if i then
      v=string.sub(v,1,i-1)
   end
   editor:ReplaceSel(v)
end 

local s_checking='my.spell.checking'
if tonumber(props[s_checking])==1 then
   spell_init()
else
   props[s_checking] = 0
end

function ToggleSpellChecking()
   if tonumber(props[s_checking])==1 then
      props[s_checking]=0
      spell_exit()
   else
      props[s_checking]=1
      spell_init()
   end
end

function SpellCheckerSel()
   local s=editor:GetSelText()
   if (s=='') then 
      Err('Please select some text for spell checking!')
      return
   end
   local p1,p2
   p1=editor.SelectionStart
   p2=editor.SelectionEnd
   
   local tmp_file='_spell_.tmp'
   f_write(tmp_file,s)
   local cmd='4nt.exe /c spell.btm '..tmp_file
   print('Running:',cmd)
   os.execute(cmd)
   s=f_read(tmp_file)
   os.remove(tmp_file)
   editor:SetSel(p1,p2)
   editor:ReplaceSel(s)
end 

local function on_char(s)
   if tonumber(props[s_checking])==0 or (not editor.Focus) or string.find(s,'%w') then
      return
   end
   CheckCurWord()
end



function AddCurWord(ignore)
   local r=GetCurWordRange()
   local s=r.word or ''
   if ignore then
      ClearMark(r.p1,r.p2)
      return
   end
   s=gui.prompt_value('Please confirm the word to add into user dictionary:',s)
   if not s then return; end
   ClearMark(r.p1,r.p2)
   for _,v in ipairs(user_dict) do
      if v==s then return; end
   end
   table.insert(user_dict,s)
   table.sort(user_dict)
   word_list[s]={}
   SaveUserDict(user_dict_file) 
end

local s_ignore='--Ignore--'
local s_add='--Add--'
local suggestions={}
local function sel_suggestions(v)
   if v==s_ignore then
      AddCurWord('ignore')
   elseif v==s_add then
      AddCurWord()
   else
      CorrectCurWord(v)
   end
end

local function on_click_word()
   if tonumber(props[s_checking])==0 or (not editor.Focus) then
      return
   end
   suggestions=CheckCurWord()
   if not suggestions then return; end
   if table.getn(suggestions)==0 then return;end
   if suggestions[1]~=s_ignore then
      table.insert(suggestions,1,s_ignore)
      table.insert(suggestions,2,s_add)
   end
   scite_UserListShow(suggestions,1,sel_suggestions)
end
scite_OnChar(on_char)
-- scite_OnDoubleClick(on_click_word)

local old_OnClick=OnClick
function OnClick(shift, ctrl, alt)
   local result
   if old_OnClick then result = old_OnClick(shift, ctrl, alt) end
   on_click_word()
   return result
end

local old_OnFinalise = OnFinalise
function OnFinalise()
	local result
	if old_OnFinalise then result = old_OnFinalise() end
   SaveUserDict(user_dict_file)
	return result
end

