-- [mhb] 06/27/09: to provide a smart texer with lua, similar to MTeX clatex.btm and MicTeX SmartTeXer.
local function find_pat(s,pat)
    local tbl=pat
    if not pat then return end
    if type(pat)=='string' then tbl={pat} end
    for _,v in ipairs(tbl) do
        if s:find(v) then return true end
    end
    return false
end

function tex_cmd()
    local p=tonumber(props['SMART_TEX_CHECK_LINES']) or 20
    p=math.min(editor.LineCount-2,p)
    local s=''
    for i=0,p do 
        s=s..editor:GetLine(i) 
    end
    local i1,i2,mode=s:find('%&(%w+)')
    if mode then return mode end
    if s:find('\documentstyle') then return 'latex209' end
    local latex_mode=s:find('\documentclass')
    local pat=prop2table('SMART_TEX_PATTERNS')
    local cmd_ltx={'latex','pdflatex','lualtex','xelatex','lambda'}
    local cmd_tex={'tex','pdftex','luatex','xetex','omega','context'}
    if latex_mode then
        for _,v in ipairs(cmd_ltx) do
            if find_pat(s,pat[v]) then return v end
        end
        local def_latex=props['SMART_TEX_DEF_LATEX'] or ''
        if def_latex=='' then def_latex='latex' end
        print('Found latex file. Default latex command: ',def_latex)
        return def_latex
    else
        for _,v in ipairs(cmd_tex) do
            if find_pat(s,pat[v]) then return v end
        end
        return 'tex'
    end
end

function smart_tex()
    local typ=props['FileType']
    if (typ~='tex') and (typ~='latex') then
        print('Warning: Smart TeXing is designed for tex files! It may be harmful to other files!')
--         return
    end
    local cmd=tex_cmd()
    props['TEX_CMD']=cmd
    print('Detected compiling mode: ',cmd)
    local s_cmd=props['SMART_TEX_RUN']
    print('Running: ',s_cmd)
    os.execute(s_cmd)
    print('Done!')
end

function smart_tex_once()
    props['SMART_TEX_OPT']='-1'
    smart_tex()
    props['SMART_TEX_OPT']=''
end

