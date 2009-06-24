-- [mhb] modified: use winexec instead of shell.exec 
-- Version: 1.2
-- Author: HSolo, mozers 
---------------------------------------------------
-- http://forum.ru-board.com/topic.cgi?forum=5&topic=3215&start=2020#3
---------------------------------------------------

local function FormulaDetect(str)
  local PatternNum = "([\-\+\*\/%b()%s]*%d+[\.\,]*%d*[\)]*)"
  local startPos, endPos, Num, Formula
  startPos = 1
  Formula = ''
  while true do
      startPos, endPos, Num = string.find(str, PatternNum, startPos) 
      if startPos == nil then break end
      startPos = endPos + 1
--~ print(Num)
      Num = string.gsub (Num, '%s+', '')                           
      Num = string.gsub (Num, '^([\(%d]+)', '+%1')                 
      Num = string.gsub (Num, '^([\)]+)([%d]+)', '%1+%2')          
      Formula = Formula..Num                                       
  end
  Formula = string.gsub (Formula, '^[\+]', '')                     
  Formula = string.gsub(Formula,"[\,]+",'.')                       
  Formula = string.gsub(Formula,"([\+])([\+]+)",'%1')              
  Formula = string.gsub(Formula,"([\-])([\+]+)",'%1')              

  Formula = string.gsub(Formula,"([\+\-\*\/])([\*\/]+)",'%1')      
  Formula = string.gsub(Formula,"([\+\-\*\/])([\*\/]+)",'%1')      

  Formula = string.gsub(Formula,"([%d\)]+)([\+\*\/\-])",'%1 %2 ')  

  return Formula
end


function calc_url()

local str = ''
if editor.Focus then
  str = editor:GetSelText()
else
  str = props['CurrentSelection']
end

if (str == '') then
  str = editor:GetCurLine()
end

if (string.len(str) > 2) then
  if string.find(str,'https?://(.*)') then
    local browser = ('explorer "' .. str .. '"')
    winexec(browser)
    --~ os.execute (browser)
  else
    if string.find(str, "(math\.%w+)") then 
      str = string.gsub(str,"[=]",'')
    else
      str = FormulaDetect(str)
    end

    print('->Expr: '..str)
    local res = assert(loadstring('return '..str),str)()
    editor:CharRight()
    editor:LineEnd()
    local sel_start = editor.SelectionStart + 1
    local sel_end = sel_start + string.len(res)
    editor:AddText('\n= '..res)
    editor:SetSel(sel_start, sel_end)
    print('>> Result= '..res)
  end
end


end

-- Тесты типа :)
--~ 1/2 56/4 - 56 (8-6)*4  4,5*(1+2)    66
--~ 3/6 6.4/2 6  (7-6)*4  45/4.1 66


--~ dmfdmk v15*6dmd.ks skm4.37/3d(k)gm/sk+d skdmg(6,7+6)skdmgk

--~ Колбаса = 24.5кг. * 120руб./кг
--~ Бензин(ABC) = (2500км. / (11,5л./100км.)) * 18.4руб./л + Канистра =100руб.
--~ Штукатурка = 22.4 м2 /80руб./100 м2
