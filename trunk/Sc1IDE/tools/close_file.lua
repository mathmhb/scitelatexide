function close_all()
    scite.MenuCommand(IDM_CLOSEALL)
end

function close_all_but_current()
    local file_cur=props["FilePath"] 
    scite.MenuCommand(IDM_NEXTFILE) 
    while props["FilePath"]~=file_cur do 
        scite.MenuCommand(IDM_CLOSE) 
    end 
    scite.MenuCommand(IDM_PREVFILE) 
    while props["FilePath"]~=file_cur do 
        scite.MenuCommand(IDM_CLOSE) 
        scite.MenuCommand(IDM_PREVFILE) 
    end
end

