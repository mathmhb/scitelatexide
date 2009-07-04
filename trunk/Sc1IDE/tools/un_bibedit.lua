-- [mhb] 06/29/09
-- BibEdit cannot support Chinese chars correctly; this tool can restore Chinese chars for bib files edited with BibEdit

local conv_table={
{"\S ","?g"},
{"\`A","?g"},
{"\'A","?g"},
{"\^A","?g"},
{"\~A","?g"},
{'\"A',"?g"},
{"\AA ","?g"},
{"\AE","?g"},
{"\c{C}","?g"},
{"\`E","?g"},
{"\'E","?g"},
{"\^E","?g"},
{'\"E',"?g"},
{"\`I","?g"},
{"\'I","?g"},
{"\^I","?g"},
{'\"I',"?g"},
{"\~N","?g"},
{"\`O","?g"},
{"\'O","?g"},
{"\^O","?g"},
{"\~O","?g"},
{'\"O',"?g"},
{"\O ","?g"},
{"\`U","?g"},
{"\'U","?g"},
{"\^U","?g"},
{'\"U',"?g"},
{"\`Y","?g"},
{"\ss","?g"},
{"\`a","?g"},
{"\'a","?g"},
{"\^a","?g"},
{"\~a","?g"},
{'\"a',"?g"},
{"\aa","?g"},
{"\ae","?g"},
{"\c{c}","?g"},
{"\`e","?g"},
{"\'e","?g"},
{"\^e","?g"},
{'\"e',"?g"},
{"\`i","?g"},
{"\'i","?g"},
{"\^i","?g"},
{'\"i',"?g"},
{"\~n","?g"},
{"\`o","?g"},
{"\'o","?g"},
{"\^o","?g"},
{"\~o","?g"},
{'\"o',"?g"},
{"\o ","?g"},
{"\`u","?g"},
{"\'u","?g"},
{"\^u","?g"},
{'\"u',"?g"},
{"\`y","?g"}
}

local function restore_chinese(s)
    local res=s
    for i,v in ipairs(conv_table) do
        local s1,s2=unpack(v)
        res=res:gsub(s1,s2)
    end
    return res
end

function un_bibedit()
    local s=editor:GetText()
    local s2=restore_chinese(s)
    print(s2)
    -- editor:SetText(s2)
end
