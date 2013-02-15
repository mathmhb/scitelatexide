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

function capital_word(w)
	return string.upper(string.sub(w,1,1))..string.lower(string.sub(w,2))
end

function capitalise_word_initial()
	local s=cur_sel_word()
	local t=string.gsub(s,'%a%l+',capital_word)
	editor:ReplaceSel(t)
	print(t)
end

local quanjiao_puncts={
['.']='¡£',
[',']='£¬',
[';']='£»',
[':']='£º',
}

function use_quanjiao_punct()
	local s=cur_sel_word()
	local t=string.gsub(s,'[,.;:]',quanjiao_puncts)
	editor:ReplaceSel(t)
	print(t)
end

local banjiao_puncts={
['¡£']='.',
['£¬']=',',
['£»']=';',
['£º']=':',
}

function use_banjiao_punct()
	local s=cur_sel_word()
	local t=s
	for _,v in pairs(banjiao_puncts) do
		t=string.gsub(t,_,v)
	end
	editor:ReplaceSel(t)
	print(t)
end

