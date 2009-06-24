local line_comment={'%%.+$'}
local block_comment_begin='^\\iffalse[%s\n\r]-$'
local block_comment_end='^%s*\\fi[%s\n\r]-$'
function strip_comments()
	local n=editor.LineCount
	local s=''
	local t=''
	local lev=0
	local F=props['FileNameExt']
	for i=1,n-1 do 
		s=editor:GetLine(i-1)
		for _,v in ipairs(line_comment) do 
			s=string.gsub(s,v,'')
		end
		if string.find(s,block_comment_begin) then 
			lev=lev+1
			print(F..':'..i..':',s,lev)
		elseif string.find(s,block_comment_end) then 
			lev=lev-1
			print(F..':'..i..':',s,lev)
			s=''
		end
		if lev==0 then t=t..s;end
	end
	scite.Open('')
	editor:append(t)
end
--scite_Command('Strip TeX comments|strip_comments')