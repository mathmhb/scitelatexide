--modified by [mathmhb] to get correct line text
-- this opens any URL found inside a file on double-click.
-- note the gotcha: the _current linenumber_ after the double click
-- is just past the double-clicked line.
-- (Requires extman)

scite_OnDoubleClick(function()
    local line = editor:GetCurLine()
    local url = line:match('(http://[%w_%-%#%/%&%=%?%.]+)')
    if not url then
        url = line:match('(file://[%w_%-%#%/%&%=%?%.:]+)')
    end
    if url then
        shellexec(url,1)
    end
end)
