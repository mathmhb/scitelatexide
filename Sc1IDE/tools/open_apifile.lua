function get_apifile()
    local s=props["APIPath"]
    if s=='' then
        local n=props['FileType'] or props['FileExt']
        s=props['api.$(file.patterns.'..n..')']
    end
    return s or ''
end

function open_apifile()
    local s=get_apifile()
    if s=='' then return; end
    for f in string.gmatch(s, "[^;]+") do 
        print('Opening ',f)
        scite.Open(f) 
    end
end
