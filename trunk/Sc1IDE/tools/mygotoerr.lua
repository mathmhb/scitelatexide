--[mhb] v1:02/15/09; v2:06/04/11 avoid mis-detecting numbers in file name or path
--to support easy error location by double-clicking the output error message containing a line number
--using functions from findtext.lua
local function GotoLine(line)
	editor:GotoLine(line)
	editor:ScrollCaret()
	editor.FoldExpanded[line]=true
	editor:EnsureVisible(line)
end

function EditorMarkLine()
	local pos=editor.CurrentPos
	local line=editor:GetCurLine()
	local length=string.len(line)
	EditorClearMarks()
	EditorMarkText(pos, length, 31)
end

function my_goto_lineno(s) 
	if not s then s=output:GetSelText();end
	local n=tonumber(s)
	if not n then return; end
	--output.Focus=false
	output:CharLeft()
	editor.Focus=true
	GotoLine(n-1)
	EditorMarkLine()
end	

--[mhb] 03/03/09 21:19:07
function my_check_line(line)
	local i1,i2,s,fn,fn2,f
	
	fn=props['FilePath']
	i1,i2=string.find(line,fn,1,true)
	if not i1 then
		fn=props['FileNameExt']
		i1,i2=string.find(line,fn,1,true)
	end
	
	if i1 then
		line=string.sub(line,i2+1) .. '@@@' .. string.sub(line,1,i1-1)
		s=string.match(line,'([0-9]+)')
		if tostring(props['DEBUG_GOTOERR'])=='1' then
			print(s,fn)
		end
	else
		i1,i2=string.find(line,'[^%w]([0-9]+)[^%w]')
		if not i1 then return; end
		s=string.sub(line,i1+1,i2-1)
		fn=string.sub(line,1,i1-1)
		fn2=string.match(fn,'([/a-zA-Z0-9%.:_\\]+)[^%w%.]*')
		if tostring(props['DEBUG_GOTOERR'])=='1' then
			print(s,fn,fn2)
		end
		fn=fn2
	end
	
	f=io.open(fn,'r')
	if f then 
		f:close()
		scite.Open(fn)
	end
	my_goto_lineno(s)
end


function my_goto_err_line()
	if not output.Focus then return;end
	local line=output:GetCurLine()
	if not line then return;end
	EditorClearMarks()
	if gmatch(line,':([0-9]+):') then return;end
	my_check_line(line)
	return true
end

scite_OnDoubleClick(my_goto_err_line)
