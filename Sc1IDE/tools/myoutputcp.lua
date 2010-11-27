--[mhb] 11/27/10: set output panel code page 

function set_output_codepage(arg)
    local cp
    if not arg then
        cp=""
    elseif arg==0 then
        cp=""
    elseif arg==1 then
        cp=props["code.page"]
    elseif arg==2 then
        cp="65001"
    end
    props["output.code.page"]=cp
    scite.MenuCommand(IDM_TOGGLEOUTPUT)
    scite.MenuCommand(IDM_TOGGLEOUTPUT)
end

set_output_utf8=function() set_output_codepage(2) end
set_output_ansi=function() set_output_codepage(1) end
set_output_none=function() set_output_codepage(0) end
