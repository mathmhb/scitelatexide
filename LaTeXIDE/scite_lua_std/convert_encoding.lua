function To_UTF8()
	editor:GrabFocus()
	local pos = editor.CurrentPos;
	scite.MenuCommand(IDM_SELECTALL)
	scite.MenuCommand(IDM_COPY)
	scite.MenuCommand(IDM_ENCODING_UCOOKIE)
	scite.MenuCommand(IDM_PASTE)
	scite.MenuCommand(IDM_SAVE)
	editor:GotoPos(pos)
	output:append("Document encoding converted to UTF8.")
end

function To_ANSI()
	editor:GrabFocus()
	local pos = editor.CurrentPos;
	scite.MenuCommand(IDM_SELECTALL)
	scite.MenuCommand(IDM_COPY)
	scite.MenuCommand(IDM_ENCODING_DEFAULT)
	scite.MenuCommand(IDM_PASTE)
	scite.MenuCommand(IDM_SAVE)
	editor:GotoPos(pos)
	output:append("Document encoding converted to ANSI.")
end

