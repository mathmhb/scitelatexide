function stripWhiteLines(reportNoMatch)
    local count = 0
    local fs,fe = editor:findtext("^$", SCFIND_REGEXP)
    if fe then
        repeat
            count = count + 1
            editor:remove(fs,fe)
            fs,fe = editor:findtext("^$", SCFIND_REGEXP, fs)
        until not fe
        print("Removed " .. count .. " line(s).")
    elseif reportNoMatch then
        print("Document was clean already; nothing to do.")
    end
    return count
end