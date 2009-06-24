-- Word counter: revised from http://www.rrreese.com/scite/wc.html
--[mhb] revised: to support Chinese Word Counting

--[mhb] 06/07/09: calculate number of Chinese chars

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

print("----------------------------");
local sep=':\t'
print(s_("Chinese Char Count")..sep,count_chinese_chars());


print(s_("Char Count")..sep,editor.Length);
print(s_("Word Count")..sep,wordCount);
print(s_("Line Count")..sep,editor.LineCount);
print(s_("Non empty lines")..sep, nonEmptyLine);
print(s_("Empty lines")..sep, editor.LineCount - nonEmptyLine);
print(s_("White Space")..sep, whiteSpace);
print(s_("Non white space chars")..sep,(editor.Length)-whiteSpace);
print(s_("Current Pos")..sep,editor.CurrentPos);
print(s_("Current Line")..sep, editor:LineFromPosition(editor.CurrentPos) +1);

end
--你好adsfsf这是中国人
--~ word_count()