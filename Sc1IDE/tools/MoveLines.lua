-- ����������� ���������� ����� (��� 1 ������) �����, ����, ������, �����
-- ����������� ����������� ������� �� ������ ������ � �����
-- codewarlock1101
-- http://forum.ru-board.com/topic.cgi?forum=5&topic=3215&start=1140#6

local function move_lines(horizontal,vertical)
--[[*********************************************************************************************** 
*  PIE_MOVE_TYPE
*     0 �� ���������
*     1 ��� ���������� ����������� �� �������� �������
*     2 ��� ���������� ����������� �� ����� ������
*     3 ���������� �����������
*************************************************************************************************]]
    local PIE_MOVE_TYPE=2
    local sel_start_line = editor:LineFromPosition(editor.SelectionStart)
    local sel_end_line = editor:LineFromPosition(editor.SelectionEnd)
    local slend=editor:GetLineSelEndPosition(sel_end_line)
    local slend2=editor:GetLineSelEndPosition(sel_end_line-1)
    local sel_txt=editor:GetSelText()
    local nap=0

print(horizontal,vertical)
    
    if slend==slend2 then
      nap=1
    end
    local anti_nap=math.abs(nap-1)
  if horizontal==1 then
        if PIE_MOVE_TYPE==0 or (sel_start_line~=sel_end_line or sel_txt=="" or (editor:PositionFromLine(sel_start_line)==editor.SelectionStart and editor.LineEndPosition[sel_end_line]==editor.SelectionEnd)) then
      for i = sel_start_line, sel_end_line-nap do
        if string.gsub(editor:textrange(editor:PositionFromLine(i),editor.LineEndPosition[i]),' ','')~='' then
            editor.LineIndentation [i]=editor.LineIndentation [i]+vertical*(-1)
        end
      end
        else
        if editor.SelectionStart~=0 or vertical==-1 then
            editor:ReplaceSel('')
            if editor.SelectionStart==editor:PositionFromLine(sel_start_line) and vertical==1 then
              if PIE_MOVE_TYPE==1 then editor:CharLeft() end
              if PIE_MOVE_TYPE==1 or PIE_MOVE_TYPE==3 then editor.SelectionStart=editor.SelectionStart+vertical end
              if PIE_MOVE_TYPE==2 then editor.SelectionStart=editor.LineEndPosition[sel_end_line]+vertical end
            end
            if editor.SelectionStart==editor.LineEndPosition[sel_start_line] and vertical==-1 then
              if PIE_MOVE_TYPE==1 then editor:CharRight() end
              if PIE_MOVE_TYPE==1 or PIE_MOVE_TYPE==3 then editor.SelectionStart=editor.SelectionStart+vertical end
              if PIE_MOVE_TYPE==2 then editor.SelectionStart=editor:PositionFromLine(sel_start_line)+vertical end
            end
            editor.SelectionStart=editor.SelectionStart+(-1)*vertical
            local strt=editor.SelectionStart
            editor:InsertText(editor.SelectionStart, sel_txt)
            if vertical==1 then
              editor.SelectionEnd=editor.SelectionStart-1
              editor.SelectionStart=editor.SelectionStart-string.len(sel_txt)
            else
              editor.SelectionStart=strt

              editor.SelectionEnd=editor.SelectionStart+string.len(sel_txt)
            end 
        end
        end
  else
      if (sel_txt == "") or (sel_start_line==sel_end_line) then
          local xsel_s=editor.SelectionStart-editor:PositionFromLine(sel_start_line)
          local xsel_e=editor.SelectionEnd-editor:PositionFromLine(sel_end_line)
      if vertical==1 then
       if sel_end_line-nap<editor.LineCount-1 then
         editor:LineDown() 
         editor:LineTranspose()
       else 
         vertical=0
       end
      else
        editor:LineTranspose() 
        editor:LineUp()
      end
      if (sel_txt ~= "")  then
        xsel_s = editor:PositionFromLine(sel_start_line+vertical)+xsel_s
        xsel_e = xsel_s + string.len(sel_txt)
        editor:SetSel(xsel_s,xsel_e)
      end
    else

      if (sel_start_line>0 and vertical==-1) or (sel_end_line-nap<editor.LineCount-1 and vertical==1) then
        editor:BeginUndoAction()
        if vertical==1 then
        -- Down
            editor:GotoLine(sel_end_line+anti_nap)
            for i = sel_end_line-nap+anti_nap, sel_start_line+anti_nap, -1 do
              editor:LineTranspose()
              editor:LineUp()
            end
        else
        -- Up
            editor:GotoLine(sel_start_line)
            for i = sel_start_line, sel_end_line-nap do
              editor:LineTranspose()
              editor:LineDown()
            end
        end
        local sel_start = editor:PositionFromLine(sel_start_line+vertical)
        local sel_end = editor:PositionFromLine(sel_end_line+vertical+anti_nap)
        editor:SetSel(sel_start,sel_end)
        editor:EndUndoAction()
      end
    end
  end

end


function move_up() move_lines(0,-1) end
function move_down() move_lines(0,1) end
function move_left() move_lines(1,1) end
function move_right() move_lines(1,-1) end
