-- [mhb] 11/28/09 paste here (without moving cursor location)
function paste_here()
    local pos = editor.CurrentPos
    scite.MenuCommand(IDM_PASTE)
    editor:GotoPos(pos)
end
