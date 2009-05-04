-- LaTeX abbrivations encoder and decoder
-- original idea by kmc, latex_abbrev_dec() modified by qihs
function latex_abbrev_enc()
        local sel        =        editor:GetSelText()
        if sel == '' then
                return
        end
        sel = string.gsub(sel, '\\', "\\\\")
        sel = string.gsub(sel, '\r\n', "\\n")
        sel = string.gsub(sel, '\t', "\\t")
        editor:ReplaceSel(sel)
end

function latex_abbrev_dec()
        local sel = editor:GetSelText()
        if not sel or sel == '' then
                return
        end
        local m = {t = '\t', n = '\n', ['\\'] = '\\'}
        sel = string.gsub(sel,'\\[tn\\]',
                function(s)
                        return m[string.sub(s,2,2)]
                end)
        editor:ReplaceSel(sel)
end
