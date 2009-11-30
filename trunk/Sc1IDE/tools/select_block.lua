-- [mhb] modified: require bit.lua
-- this experimental script makes it easy to select blocks with a single click.
-- The usual behaviour is to select the whole line, and if that line happens to be a fold line
-- then select the rest of that block.

function select_block(line_,s1_,s2_)
	local line,s1,s2=line_,s1_,s2_
	if not s2 then
		s1 = editor.SelectionStart
		s2 = editor.SelectionEnd
		line = editor:LineFromPosition(s1)
	end
	props['Message']=''
	local lev = editor.FoldLevel[line]
	if bit.band(lev,SC_FOLDLEVELHEADERFLAG) then -- a fold line
		local lastl = editor:GetLastChild(line,-1)
		s2 = editor:PositionFromLine(lastl+1)
		-- hack: a fold line beginning with a '{' is not where we want to start...
		if string.find(editor:GetLine(line),'^%s*{') then
			s1 = editor:PositionFromLine(line-1)
		end
		local n1,n2
		n1=editor:LineFromPosition(s1)
		n2=editor:LineFromPosition(s2)
		if n2<=n1+1 then
			return
		end
		
		----[mhb] 11/28/09 : 'select_block'==>scite.GetTranslation('block:')
		props['Message']=scite.GetTranslation('block:')..(n1+1)..'-'..(n2) 
		
		editor.Anchor = s2
		editor.CurrentPos = s1
	end
end

local function line_selected()
--	if not scite_GetProp('fold') then return end
	local s1 = editor.SelectionStart
	local s2 = editor.SelectionEnd

	if s2 > s1 then -- non-trivial selection
		local line = editor:LineFromPosition(s1)
		if editor:PositionFromLine(line) > s1 then
			return -- because selection didn't start at begining of line
		end 

		if s2 == editor:PositionFromLine(line+1) then -- whole line selected!
			select_block(line,s1,s2)
		end
	end
end

if props['USING_SELECT_BLOCK']=='1' then --[mhb] 03/17/09 14:03:37
	scite_OnUpdateUI(line_selected)
end 


