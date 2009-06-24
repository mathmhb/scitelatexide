function get_abbrfile()
    local s=props["AbbrevPath"]
    if s=='' then
        local n=props['FileType'] or props['FileExt']
        s=props['abbreviations.$(file.patterns.'..n..')']
    end
    return s or ''
end

function open_abbrfile()
    local s=get_abbrfile()
    if s=='' then return; end
    for f in string.gmatch(s, "[^;]+") do 
        print('Opening ',f)
        scite.Open(f) 
    end
end
