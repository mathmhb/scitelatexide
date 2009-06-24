-- This file provides some functions for text processing (selected text).

function cur_sel_word()
	local s=editor:GetSelText()
	if s=='' then 
		editor:WordLeftExtend();
		editor:WordRightExtend();
		s=editor:GetSelText();
	end
	return s
end	

function toggle_case(c)
	if c>='a' and c<='z' then return string.upper(c); else return string.lower(c);end
end

function text_toggle_case()
	local s=cur_sel_word()
	local t=''
	for i=1,string.len(s) do t=t..toggle_case(string.sub(s,i,i));end
	editor:ReplaceSel(t)
	print(t)
end