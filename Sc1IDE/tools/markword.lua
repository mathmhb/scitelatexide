--mark all occurrences of a word in the document
function clearOccurrences()
    scite.SendEditor(SCI_INDICATORCLEARRANGE, 0, editor.Length)
end

function markOccurrences()
    clearOccurrences()
    scite.SendEditor(SCI_INDICSETSTYLE, 0, INDIC_CONTAINER)
    scite.SendEditor(SCI_INDICSETFORE, 0, 0x0000FF)
    local txt = GetCurrentWord()
	if(txt == nil) then return; end;
    local flags = SCFIND_WHOLEWORD
    local s,e = editor:findtext(txt,flags,0)
    while s do
        scite.SendEditor(SCI_INDICATORFILLRANGE, s, e - s)
        s,e = editor:findtext(txt,flags,e+1)
    end
end

function isWordChar(char)
    local strChar = string.char(char)
    local beginIndex = string.find(strChar, '%w')
    if beginIndex ~= nil then
        return true
    end
    if strChar == '_' or strChar == '$' then
        return true
    end
    
    return false
end

function GetCurrentWord()
    local beginPos = editor.CurrentPos
    local endPos = beginPos
    if editor.SelectionStart ~= editor.SelectionEnd then
        return editor:GetSelText()
    else
		while isWordChar(editor.CharAt[beginPos-1]) do
			beginPos = beginPos - 1
		end
		while isWordChar(editor.CharAt[endPos]) do
			endPos = endPos + 1
		end
		if(beginPos ~= endPos) then
			return editor:textrange(beginPos,endPos)
		else
			return nil
		end
	end
end
