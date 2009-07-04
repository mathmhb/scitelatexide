-- [mhb] 06/27/09 : to support adding time stamp easily
function add_time_stamp()
    local com=props['comment.block.'..editor.LexerLanguage]
    local sig=com..props['TIME_STAMP_SIG']
    local s=editor:GetLine(0)
    local s2=sig..os.date()
    if s:find(sig,1,true) then
        editor:GotoPos(0)
        editor:DelLineRight()
    else
        s2=s2..'\n'
    end
    editor:InsertText(0,s2)
    print("Added time stamp: ",s2)
end

scite_OnBeforeSave(function()
    if tostring(props['AUTO_ADD_TIME_STAMP'])=='1' then 
        add_time_stamp()
    end
end)
