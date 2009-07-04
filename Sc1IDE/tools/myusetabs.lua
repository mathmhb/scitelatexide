--[mhb] 06/24/09 : to enable the users toggle whether to use tabs at any time

function toggle_use_tabs()
    local cn=props['CN_USE_TABS']
    local p='command.checked.'..cn..'.*'
    local use_tabs=props[p]
    if editor.UseTabs then
        props[p]='0'
        editor.UseTabs=false
    else
        props[p]='1'
        editor.UseTabs=true
    end
--     props['use.tabs']=props[p]
--     props['use.tabs.'..props['FileNameExt']]=props[p]
end
