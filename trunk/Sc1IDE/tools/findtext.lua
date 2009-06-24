function EditorClearMarks(style_number, start, length)
	local _first_style, _end_style, style
	if style_number == nil then
		_first_style, _end_style = 0, 31
	else
		_first_style, _end_style = style_number, style_number
	end
	if start == nil then
		start, length = 0, editor.Length
	end
	for style = _first_style, _end_style do
		scite.SendEditor(SCI_SETINDICATORCURRENT, style)
		scite.SendEditor(SCI_INDICATORCLEARRANGE, start, length)
	end
end

function ClearAllMarks()
    EditorClearMarks() 
    scite.SendEditor(SCI_SETINDICATORCURRENT, tonumber(props['findtext.first.mark']) or 31) 
    if props['findtext.bookmarks'] == '1' then 
        editor:MarkerDeleteAll(1) 
    end
end

function CheckChange(prop_name)
	if tonumber(props[prop_name]) == 1 then
		props[prop_name] = 0
	else
		props[prop_name] = 1
	end
end


function FindText()
    local firstNum = tonumber(props['findtext.first.mark']) or 31
    if firstNum < 1 or firstNum > 31 then firstNum = 31 end

    local sText = props['CurrentSelection']
    local flag0 = 0
    if (sText == '') then
        sText = props['CurrentWord']
        flag0 = SCFIND_WHOLEWORD
    end
    local flag1 = 0
    if props['findtext.matchcase'] == '1' then flag1 = SCFIND_MATCHCASE end
    local bookmark = props['findtext.bookmarks'] == '1'
    local isOutput = props['findtext.output'] == '1'
    local isTutorial = props['findtext.tutorial'] == '1'

    local current_mark_number = scite.SendEditor(SCI_GETINDICATORCURRENT)
    if current_mark_number < firstNum then current_mark_number = firstNum end
    if string.len(sText) > 0 then
        if bookmark then editor:MarkerDeleteAll(1) end
        local msg
        if isOutput then
            if flag0 == SCFIND_WHOLEWORD then
                msg = '> '..scite.GetTranslation('Search for current word')..': "'
            else
                msg = '> '..scite.GetTranslation('Search for selected text')..': "'
            end
            props['lexer.errorlist.findtitle.begin'] = msg
            scite.SendOutput(SCI_SETPROPERTY, 'lexer.errorlist.findtitle.begin', msg)
            props['lexer.errorlist.findtitle.end'] = '"'
            scite.SendOutput(SCI_SETPROPERTY, 'lexer.errorlist.findtitle.end', '"')
            print(msg..sText..'"')
        end
        local s,e = editor:findtext(sText, flag0 + flag1, 1)
        local count = 0
        if(s~=nil)then
            local m = editor:LineFromPosition(s) - 1
            while s do
                local l = editor:LineFromPosition(s)
                EditorMarkText(s, e-s, current_mark_number)
                count = count + 1
                if l ~= m then
                    if bookmark then editor:MarkerAdd(l,1) end
                    local str = string.gsub(' '..editor:GetLine(l),'%s+',' ')
                    if isOutput then
                        print(props['FileNameExt']..':'..(l + 1)..':\t'..str)
                    end
                    m = l
                end
                s,e = editor:findtext(sText, flag0 + flag1, e+1)
            end
            if isOutput then
                print('> '..string.gsub(scite.GetTranslation('Found: @ results'), '@', count))
                if isTutorial then
                    print('F3 (Shift+F3) - '..scite.GetTranslation('Jump by markers')..
                        '\nF4 (Shift+F4) - '..scite.GetTranslation('Jump by lines')..
                        '\nCtrl+Alt+C - '..scite.GetTranslation('Erase all markers'))
                end
            end
        else
            print('> '..string.gsub(scite.GetTranslation("Can't find [@]!"), '@', sText))
        end
        current_mark_number = current_mark_number + 1
        if current_mark_number > 31 then current_mark_number = firstNum end
        scite.SendEditor(SCI_SETINDICATORCURRENT, current_mark_number)
            if flag0 == SCFIND_WHOLEWORD then
                editor:GotoPos(editor:WordStartPosition(editor.CurrentPos))
            else
                editor:GotoPos(editor.SelectionStart)
            end
            scite.Perform('find:'..sText)
    else
        EditorClearMarks()
        if bookmark then editor:MarkerDeleteAll(1) end
        scite.SendEditor(SCI_SETINDICATORCURRENT, firstNum)
        print('> '..scite.GetTranslation('Select text for search! (search for selection)'))
        print('> '..scite.GetTranslation('Or put cursor on the word for search. (search for word)'))
        print('> '..scite.GetTranslation('You can also select text in console.'))
    end
    --~ editor:CharRight() editor:CharLeft()
end

function find_next(inverse) 
    local pane=editor
    local sText = props['CurrentSelection']
    local flags = 0
    if (sText == '') then
        sText = props['CurrentWord']
        flags = SCFIND_WHOLEWORD
    end
    local len=string.len(sText)
    local s=editor.CurrentPos
    local inv=tostring(inverse) or ''
    if inverse=='inverse' then
        editor:CharLeft()
        pane:SearchAnchor()
        s=pane:SearchPrev(flags, sText)
    else
        editor:GotoPos(s+len)
        pane:SearchAnchor()
        s=pane:SearchNext(flags, sText)
    end
    editor:GotoPos(s)
    editor:SetSel(s,s+len)

end

function find_prev() 
    find_next('inverse')
end

