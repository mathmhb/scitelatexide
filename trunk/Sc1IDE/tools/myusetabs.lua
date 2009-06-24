--[mhb] 06/24/09 : to enable the users toggle whether to use tabs at any time ??

function toggle_use_tabs()
    local cn=props['CN_USE_TABS']
    local p='command.checked.'..cn..'.*'
    local use_tabs=props[p]
    if tostring(use_tabs)=='1' then
        props[p]='0'
    else
        props[p]='1'
    end
    props['use.tabs']=props[p]
    props['use.tabs.'..props['FileNameExt']]=props[p]
end
