-- Word counter: revised from http://www.rrreese.com/scite/wc.html
--[mhb] revised: to support Chinese Word Counting

--[mhb] 06/07/09: calculate number of Chinese chars; 06/04/11 : add chinese char count for selection; 07/07/11 : add other counting for selection

--[qhs] 12/27/11: output encoding support
local function _s_(str)
return s_(str):to_utf8(props["editor.code.page"]):from_utf8(props["output.code.page"])
end

function count_chinese_chars(p1,p2)
	local cnt=0
	local p=p1 or 0
	local q=p2 or editor.Length
	while p<q do
		local c1=editor.CharAt[p]
		local c2=editor.CharAt[p+1]
		if c1<0 and c2<0 then 
			cnt=cnt+1
			p=p+2
		else
			p=p+1
		end
	end
	return cnt
end

function count_patterns(s,pattern)
	local itt=0
	for pat in string.gfind(s,pattern) do
		itt=itt+1
	end
	return itt
end

function my_word_count()
	local sel=editor:GetSelText()
	local all=editor:GetText()
	local chars=string.len(all)
	local chars2=string.len(sel)
	local chinesechars=count_chinese_chars(0,editor.Length)
	local chinesechars2=count_chinese_chars(editor.SelectionStart,editor.SelectionEnd)
	local words=count_patterns(all,'%w+')
	local spaces=count_patterns(all,'%s')
	local lines=count_patterns(all,'\n')
	local nlines=count_patterns(all,'\n.*%w.*\n')
	local texcmds=count_patterns(all,'\\%w+')
	local texenvs=count_patterns(all,'\\begin{%w+}')
	local words2=count_patterns(sel,'%w+')
	local spaces2=count_patterns(sel,'%s')
	local lines2=count_patterns(sel,'\n')
	local nlines2=count_patterns(sel,'\r%s*\n')
	local texcmds2=count_patterns(sel,'\\%w+')
	local texenvs2=count_patterns(sel,'\\begin{%w+}')
	local msg=' ('..s_('All')..'/'..s_('Selected')..'):'
	msg=msg:to_utf8(props["editor.code.page"]):from_utf8(props["output.code.page"]) -- [qhs] 12/27/11
	print("-------------------------------------------")
	print(_s_('Chinese Char Count')..msg,chinesechars,chinesechars2)
	print(_s_('Char Count')..msg,chars,chars2)
	print(_s_('Word Count')..msg,words,words2)
	print(_s_('White Space')..msg,spaces,spaces2)
	print(_s_('Line Count')..msg,lines,lines2)
	-- print(_s_('Empty lines')..msg,nlines,nlines2)
	print(_s_('LaTeX Commands')..msg,texcmds,texcmds2)
	print(_s_('LaTeX Environments')..msg,texenvs,texenvs2)
	print(_s_("Current Pos")..':',editor.CurrentPos);
	print(_s_("Current Line")..':', editor:LineFromPosition(editor.CurrentPos) +1);
	
end

function word_count()

local newline = 0;      --number of newlines
local nonEmptyLine = 0; --number of non blank lines
local wordCount = 0;    --total number of words
local whiteSpace = 0;   --number of whitespace chars

--Calculate whitespace control
for m in editor:match("\n") do --count newline
	whiteSpace = whiteSpace + 1;
end
for m in editor:match("\r") do --count carriage return
	whiteSpace = whiteSpace + 1;
end
for m in editor:match("\t") do --count tabs
	whiteSpace = whiteSpace + 1;
end

--Calculate non-empty lines
local itt = 0;
while itt < editor.LineCount do --iterate through each line
	local hasChar, hasNum = 0;
	line = editor:GetLine(itt);
	if line then
		hasAlphaNum = string.find(line,'%w');
	end
        
        if (hasAlphaNum ~= nill) then
            nonEmptyLine = nonEmptyLine + 1;
        end
	itt = itt + 1;
end

--calculate number of words
local itt = 0;
while itt < editor.LineCount do --iterate through each line
	line = editor:GetLine(itt);
	if line then
		for word in string.gfind(line, "%w+") do 
			wordCount = wordCount + 1 
		end
	end
	itt = itt + 1;
end



local sep=':\t'
print("-------------------------------------------");
print(_s_("Selected")..s_("Chinese Char Count")..':',count_chinese_chars(editor.SelectionStart,editor.SelectionEnd));
print(_s_("Selected")..s_("Char Count")..':',editor.SelectionEnd-editor.SelectionStart);
print(_s_("Chinese Char Count")..sep,count_chinese_chars());

print(_s_("Char Count")..sep,editor.Length);
print(_s_("Word Count")..sep,wordCount);
print(_s_("Line Count")..sep,editor.LineCount);
print(_s_("Non empty lines")..sep, nonEmptyLine);
print(_s_("Empty lines")..sep, editor.LineCount - nonEmptyLine);
print(_s_("White Space")..sep, whiteSpace);
print(_s_("Non white space chars")..sep,(editor.Length)-whiteSpace);
print(_s_("Current Pos")..sep,editor.CurrentPos);
print(_s_("Current Line")..sep, editor:LineFromPosition(editor.CurrentPos) +1);

end
--你好adsfsf这是中国人
-- my_word_count()