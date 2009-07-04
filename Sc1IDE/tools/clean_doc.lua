-- http://lua-users.org/wiki/SciteCleanDocWhitespace
function stripTrailingSpaces(reportNoMatch)
    local count = 0
    local fs,fe = editor:findtext("[ \\t]+$", SCFIND_REGEXP)
    if fe then
        repeat
            count = count + 1
            editor:remove(fs,fe)
            fs,fe = editor:findtext("[ \\t]+$", SCFIND_REGEXP, fs)
        until not fe
        print("Removed trailing spaces from " .. count .. " line(s).")
    elseif reportNoMatch then
        print("Document was clean already; nothing to do.")
    end
    return count
end

function fixIndentation(reportNoMatch)
    local tabWidth = editor.TabWidth
    local count = 0
    if editor.UseTabs then
        -- for each piece of indentation that includes at least one space
        for m in editor:match("^[\\t ]* [\\t ]*", SCFIND_REGEXP) do
            -- figure out the indentation size
            local indentSize = editor.LineIndentation[editor:LineFromPosition(m.pos)]
            local spaceCount = math.mod(indentSize, tabWidth)
            local tabCount = (indentSize - spaceCount) / tabWidth
            local fixedIndentation = string.rep('\t', tabCount) .. string.rep(' ', spaceCount)

            if fixedIndentation ~= m.text then
                m:replace(fixedIndentation)
                count = count + 1
            end
        end
    else
        -- for each piece of indentation that includes at least one tab
        for m in editor:match("^[\\t ]*\t[\\t ]*", SCFIND_REGEXP) do
            -- just change all of the indentation to spaces
            m:replace(string.rep(' ', editor.LineIndentation[editor:LineFromPosition(m.pos)]))
            count = count + 1
        end
    end
    if count > 0 then
        print("Fixed indentation for " .. count .. " line(s).")
    elseif reportNoMatch then
        print("Document was clean already; nothing to do.")
    end
    return count
end

function cleanDocWhitespace()
    local trailingSpacesCount = stripTrailingSpaces(false)
    local fixedIndentationCount = fixIndentation(false)

    if (fixedIndentationCount == 0) and (trailingSpacesCount == 0) then
        print("Document was clean already; nothing to do.")
    end
end

