function text_to_newbuf()
props['clear.before.execute']=0 
local text=props['CurrentSelection'] 
if editor.Focus then text=editor:GetSelText() end 
if string.len(text)==0 then text=output:GetText() end 
scite.Open("") 
editor:AddText(text)
end
