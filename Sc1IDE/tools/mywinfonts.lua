-- To add and register a windows font
function add_winfont(f)
	DoFunc('AddFontResourceA@gdi32.dll',f)
	local HWND_BROADCAST, WM_FONTCHANGE=65535,29
	DoFunc('SendMessageA@user32.dll',HWND_BROADCAST, WM_FONTCHANGE, 0, 0)
end

function load_winfonts()
    if not DoFunc then return false end
    local font_path=props['MY_WINFONTS_PATH']
    if font_path=='' then return false end
    if font_path~='' then
        font_path=font_path..'\\'
    end
    local pp='MY_WINFONTS_LIST'
    local font_list
    if props[pp]=='' then
        local mask=font_path..'*.?tf'
        font_list=scite_Files2(mask,true)
    else
        font_list=prop2table(pp)
    end
    for _,v in ipairs(font_list) do
        local f=v
        if not string.find(f,':') then 
            f=font_path..v
        end
        f=f:gsub('/','\\')
        print('Loading winfont:',f)
        add_winfont(f)
    end
end

if props['PLAT_WIN']=="1" then
    load_winfonts()
end
