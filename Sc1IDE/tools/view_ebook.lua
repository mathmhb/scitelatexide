local view_mode=0
function view_ebook()
    show_hide()
    scite.MenuCommand(IDM_TOGGLEOUTPUT)
    view_mode=1-view_mode
    SetReadOnly(view_mode>0)
    props['ebook.view']=view_mode
--     props['statusbar.visible']=tostring(1-view_mode)
--     scite.UpdateStatusBar()
--     scite.MenuCommand(IDM_FULLSCREEN)
end
