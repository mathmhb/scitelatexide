-- [mhb] 11/28/09 paste here (without moving cursor location)
-- 07/08/11 fix two bugs of cursor position reported by LuoChaodong when some text is selected
function paste_here()
    local pos = editor.CurrentPos
    if editor.SelectionEnd>editor.SelectionStart then
        pos=editor.SelectionStart
    end
    scite.MenuCommand(IDM_PASTE)
    editor:GotoPos(pos)
    editor:CharLeft()
    editor:CharRight()
end
