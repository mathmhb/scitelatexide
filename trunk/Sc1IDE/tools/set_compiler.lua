function set_compiler()
    local menu={'compile','build','go'}
    local k=get_choice('Please choose a button to configure:',menu,140)
    if k<1 or k>#menu then return; end
    local c=menu[k]
    local p='menu.'..c..'.'..props['FileType']
    print('Found setting:',p..'='..props[p])
    local tbl=prop2table(p)
    if #tbl==0 then
        print('Not found compiler list for current file type! Please define the following property:',p)
        print('Example settings: compilers.cpp=GCC|BCC32|TURBOC')
        return
    end
    local v=props[c..'.'..props['FileType']]
    local s='CMD_'..c
    print('Current compiler ['..v..']:',s..'='..props[s])
    local kk=get_choice('Please choose new default compiler:',tbl,140)
    local cc=tbl[kk]
    local nn=cc..'.'..props['FileType']
    local ss='CMD_'..cc
    props[nn]=cc
    print('New default compiler ['..cc..']:',ss..'='..props[ss])
end
