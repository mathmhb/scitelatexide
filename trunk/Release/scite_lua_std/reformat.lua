-----------------------------------------------------------------------
-- Reformat Line (PFE-style) for SciTE (self-contained)
-- Kein-Hong Man <khman@users.sf.net> 20040727
-- This program is hereby placed into PUBLIC DOMAIN
-----------------------------------------------------------------------
-- Best installed as a shortcut key, e.g. Ctrl-1 with the following in
-- your user properties file, usually SciTEUser.properties:
--     command.name.1.*=Reformat line
--     command.subsystem.1.*=3
--     command.1.*=ReformatLine
--     command.save.before.1.*=2
-- This Lua function itself should be in SciTEStartup.lua, assuming it
-- is properly set up. Consult SciTEDoc.html if you are unsure of what
-- to do. You can also keep it in a separate file and load it using:
--     require(props["SciteUserHome"].."/SciTE_Reformat.lua")
-- Tested on SciTE 1.61+ (CVS 20040718) on Win98SE. Be careful when
-- tweaking it, you *may* be able to crash SciTE. You have been warned!
-----------------------------------------------------------------------
-- This is an enhanced line reformatting function based on "Reformat"
-- found in a classic Win32 editor, PFE. It can be summarized as:
-- (a) if line contains whitespace only, the whitespace is deleted
-- (b) there is always a single space between words, except at the end
--     of sentences, which can be set to 1 or 2 spaces
-- (c) if a word cannot fit within the right margin, a hard break
--     (newline) is added and the sentence continues on the next line
-- (d) trailing whitespace are changed to a single space
-- (e) if a word is longer than the display width, then the formatter
--     tries to split the word around punctuation
-- (f) the first line can have a different indentation setting, and
--     there are some other customizable settings as well
-- (g) formatting can be configured using the following properties
--     (which by default closely follows PFE behaviour) to be placed
--     in your appropriate properties file:
--      ext.lua.reformatline.leftmargin=1
--      ext.lua.reformatline.rightmargin=72
--      ext.lua.reformatline.firstindent=1
--      ext.lua.reformatline.sentencespc=1
--      ext.lua.reformatline.textonly=0
--      ext.lua.reformatline.nextline=0
-- (PFE 1.01 crashes often if you undo reformat lines, this doesn't.)
-----------------------------------------------------------------------
ReformatLine = function()
  -- default settings, margins are column positions
  local LEFTMARGIN  = 1     -- leftmost column available for printing
  local RIGHTMARGIN = 72    -- rightmost column available for printing
  local FIRSTINDENT = 1     -- indentation column for first line
  local SENTENCESPC = 1     -- spaces after a sentence
  local TEXTONLY = 0        -- ignore line if no alphanumeric (flag)
  local NEXTLINE = 0        -- advance to next line (flag)

  -- load properties
  local GetProp = function(p)
    return tonumber(props["ext.lua.reformatline."..p])
  end
  local leftmargin = GetProp("leftmargin") or LEFTMARGIN
  local rightmargin = GetProp("rightmargin") or RIGHTMARGIN
  local firstindent = GetProp("firstindent") or FIRSTINDENT
  local sentencespc = GetProp("sentencespc") or SENTENCESPC
  local textonly = GetProp("textonly") or TEXTONLY
  local nextline = GetProp("nextline") or NEXTLINE
  -- validate properties
  if rightmargin - leftmargin < 1 or leftmargin < 1
     or rightmargin < 1 or firstindent < leftmargin
     or rightmargin - firstindent < 1 or sentencespc < 1
     or sentencespc > 2 then
    _ALERT("ReformatLine: bad settings") return
  end

  -- EOL char to avoid indentation if NewLine
  local EOLLookup = function()
    local eol = editor.EOLMode
    if eol == SC_EOL_CR then return "\r"
    elseif eol == SC_EOL_CRLF then return "\r\n"
    else return "\n" --SC_EOL_LF
    end
  end

  -- grabs a line without EOLs
  local GetLine = function(ln)
    return editor:textrange(editor:PositionFromLine(ln),
                            editor.LineEndPosition[ln])
  end
  -- sets a line without involving cursor
  local SetLine = function(ln, txt)
    editor.TargetStart = editor:PositionFromLine(ln)
    editor.TargetEnd = editor.LineEndPosition[ln]
    editor:ReplaceTarget(txt)
  end
  -- common ending behaviour
  local EndingStuff = function()
    local ln = editor:LineFromPosition(editor.CurrentPos)
    editor:GotoPos(editor.LineEndPosition[ln])
    if nextline ~= 0 then editor:CharRight() end
  end
  -- checks if end of sentence
  local EndOfSentence = function(txt)
    local z = string.sub(txt, -1)
    local y = string.sub(txt, -2, -2)
    if (z == "." and y ~= ".") or z == "!" or z == "?" 
       or (y == "." and (z == ")" or z == "\"")) then return true end
    return false
  end

  local text, tlen
  local word, wlen
  local line = editor:LineFromPosition(editor.CurrentPos)
  local trailingspaces = false
  local t = {}

  -- grab line data for processing
  text = GetLine(line)
  editor:GotoPos(editor:PositionFromLine(line))
  -- check for trailing spaces
  if string.find(text, "%s+$") then trailingspaces = true end
  -- break up line
  for i in string.gfind(text, "(%S+)%s*") do table.insert(t, i) end
  -- remove a line of all-whitespaces
  if table.getn(t) == 0 and trailingspaces then
    SetLine(line, "") EndingStuff() return
  end
  -- ignore non-textual lines
  if not string.find(text, "%w") and textonly ~= 0 then
    EndingStuff() return
  end

  -- single-line reformatter
  local firstline, firstword = true, true
  editor:BeginUndoAction()
  for i,v in ipairs(t) do
    while v ~= "" do -- until consumed (may be piecemeal)
      if firstword then -- initialize line
        if firstline then tlen = firstindent-1 else tlen = leftmargin-1 end
        text = string.rep(" ", tlen)
        word = v
      else
        -- check end of sentence
        if EndOfSentence(t[i-1]) then
          word = string.rep(" ", sentencespc)
        else
          word = " "
        end
        word = word..v
      end
      wlen = string.len(word)
      if tlen + wlen > rightmargin then -- cannot fit right margin
        if firstword then -- split a very long word
          wlen = rightmargin - tlen -- hard split
          word = string.sub(v, 1, wlen)
          local punc = string.find(word, "%p%w+$")
          if punc then -- split around punctuation?
            if tlen + punc <= rightmargin then wlen = punc end
          end
          text = text..string.sub(v, 1, wlen)
          v = string.sub(v, wlen + 1)
        end
        -- write formatted text and insert new line
        SetLine(line, text..EOLLookup())
        line = line + 1
        editor:GotoPos(editor:PositionFromLine(line))
        firstline = false
        firstword = true
      else -- fit in a word, consume it
        text = text..word
        tlen = tlen + wlen
        v = ""
        firstword = false
      end
    end--while(each word fragment)
  end--for(each word)
  -- handle trailing whitespace
  if trailingspaces and tlen < rightmargin then text = text.." " end
  -- complete line
  SetLine(line, text)
  editor:EndUndoAction()
  EndingStuff()
end

-----------------------------------------------------------------------
-- Reformat Paragraph (PFE-style) for SciTE (self-contained)
-- Kein-Hong Man <khman@users.sf.net> 20040727
-- This program is hereby placed into PUBLIC DOMAIN
-----------------------------------------------------------------------
-- Best installed as a shortcut key, e.g. Ctrl-1 with the following in
-- your user properties file, usually SciTEUser.properties:
--     command.name.1.*=Reformat paragraph
--     command.subsystem.1.*=3
--     command.1.*=ReformatPara
--     command.save.before.1.*=2
-- This Lua function itself should be in SciTEStartup.lua, assuming it
-- is properly set up. Consult SciTEDoc.html if you are unsure of what
-- to do. You can also keep it in a separate file and load it using:
--     require(props["SciteUserHome"].."/SciTE_Reformat.lua")
-- Tested on SciTE 1.61+ (CVS 20040718) on Win98SE. Be careful when
-- tweaking it, you *may* be able to crash SciTE. You have been warned!
-----------------------------------------------------------------------
-- This is an enhanced line reformatting function based on "Reformat
-- Paragraph" found in a classic Win32 editor, PFE. It can be summarized
-- as:
-- (a) reformats block of non-empty lines under the cursor, or the
--     nearest following block of non-empty lines
-- (b) breaking conventions are the same as ReformatLine() (see above)
-- (c) the reformatted paragraph may take up more lines or less lines,
--     depending on how the text was written
-- (d) formatting can be configured using the following properties
--     (which by default closely follows PFE behaviour) to be placed
--     in your appropriate properties file:
--      ext.lua.reformatpara.leftmargin=1
--      ext.lua.reformatpara.rightmargin=72
--      ext.lua.reformatpara.firstindent=1
--      ext.lua.reformatpara.sentencespc=1
--      ext.lua.reformatpara.textonly=0
--      ext.lua.reformatpara.nextline=0
-- (PFE 1.01 often undoes reformat paragraphs badly, this doesn't.)
-- (Comment block-awareness can be added without too much trouble.)
-----------------------------------------------------------------------
ReformatPara = function()
  -- default settings, margins are column positions
  local LEFTMARGIN  = 1     -- leftmost column available for printing
  local RIGHTMARGIN = 72    -- rightmost column available for printing
  local FIRSTINDENT = 1     -- indentation column for first line
  local SENTENCESPC = 1     -- spaces after a sentence
  local TEXTONLY = 0        -- ignore line if no alphanumeric (flag)
  local NEXTLINE = 0        -- advance to next line (flag)

  -- load properties
  local GetProp = function(p)
    return tonumber(props["ext.lua.reformatpara."..p])
  end
  local leftmargin = GetProp("leftmargin") or LEFTMARGIN
  local rightmargin = GetProp("rightmargin") or RIGHTMARGIN
  local firstindent = GetProp("firstindent") or FIRSTINDENT
  local sentencespc = GetProp("sentencespc") or SENTENCESPC
  local textonly = GetProp("textonly") or TEXTONLY
  local nextline = GetProp("nextline") or NEXTLINE
  -- validate properties
  if rightmargin - leftmargin < 1 or leftmargin < 1
     or rightmargin < 1 or firstindent < leftmargin
     or rightmargin - firstindent < 1 or sentencespc < 1
     or sentencespc > 2 then
    _ALERT("ReformatPara: bad settings") return
  end

  -- EOL char to avoid indentation if NewLine
  local EOLLookup = function()
    local eol = editor.EOLMode
    if eol == SC_EOL_CR then return "\r"
    elseif eol == SC_EOL_CRLF then return "\r\n"
    else return "\n" --SC_EOL_LF
    end
  end

  -- grabs a line without EOLs
  local GetLine = function(ln)
    return editor:textrange(editor:PositionFromLine(ln),
                            editor.LineEndPosition[ln])
  end
  -- sets a line without involving cursor
  local SetLine = function(ln, txt)
    editor.TargetStart = editor:PositionFromLine(ln)
    editor.TargetEnd = editor.LineEndPosition[ln]
    editor:ReplaceTarget(txt)
  end
  -- common ending behaviour
  local EndingStuff = function()
    local ln = editor:LineFromPosition(editor.CurrentPos)
    editor:GotoPos(editor.LineEndPosition[ln])
    if nextline ~= 0 then editor:CharRight() end
  end
  -- checks if end of sentence
  local EndOfSentence = function(txt)
    local z = string.sub(txt, -1)
    local y = string.sub(txt, -2, -2)
    if (z == "." and y ~= ".") or z == "!" or z == "?" 
       or (y == "." and (z == ")" or z == "\"")) then return true end
    return false
  end
  -- is line whitespace-only?
  local IsSpaceOnly = function(ln)
    local txt = editor:GetLine(ln) or ""
    if string.find(txt, "%S") then 
      -- ignore non-textual lines
      if not string.find(txt, "%w") and textonly ~= 0 then return true end
    else return true end
    return false 
  end

  local text, tlen
  local word, wlen
  local line = editor:LineFromPosition(editor.CurrentPos)
  local trailingspaces = false
  local t = {}

  -- find start of paragraph
  if not IsSpaceOnly(line) then -- backwards
    while line >= 0 and not IsSpaceOnly(line-1) do line = line - 1 end
    if line < 0 then EndingStuff() return end
  else -- forwards
    while line < editor.LineCount and IsSpaceOnly(line) do line = line + 1 end
    if line == editor.LineCount then EndingStuff() return end
  end

  -- common processing for each line
  local ProcessLine = function(ln)
    local txt = GetLine(ln)
    -- check for trailing spaces
    if string.find(txt, "%s+$") then trailingspaces = true end
    -- break up line
    for i in string.gfind(txt, "(%S+)%s*") do table.insert(t, i) end  
  end

  -- initialize for processing
  editor:BeginUndoAction()
  editor:GotoPos(editor:PositionFromLine(line))
  ProcessLine(line)

  -- process lines incrementally
  local firstline, firstword = true, true
  local i = 1
  while i <= table.getn(t) do
    local v = t[i]
    while v ~= "" do -- until consumed (may be piecemeal)
      if firstword then -- initialize line
        if firstline then tlen = firstindent-1 else tlen = leftmargin-1 end
        text = string.rep(" ", tlen)
        word = v
      else
        -- check end of sentence
        if EndOfSentence(t[i-1]) then
          word = string.rep(" ", sentencespc)
        else
          word = " "
        end
        word = word..v
      end
      wlen = string.len(word)
      if tlen + wlen > rightmargin then -- cannot fit right margin
        if firstword then -- split a very long word
          wlen = rightmargin - tlen -- hard split
          word = string.sub(v, 1, wlen)
          local punc = string.find(word, "%p%w+$")
          if punc then -- split around punctuation?
            if tlen + punc <= rightmargin then wlen = punc end
          end
          text = text..string.sub(v, 1, wlen)
          v = string.sub(v, wlen + 1)
        end
        line = line + 1
        firstline = false
        firstword = true
        if IsSpaceOnly(line) then
          -- write formatted text and insert new line
          SetLine(line - 1, text..EOLLookup())
          editor:GotoPos(editor:PositionFromLine(line))
        else
          -- write and move on to process next line
          SetLine(line - 1, text)
          editor:GotoPos(editor:PositionFromLine(line))
          ProcessLine(line)
        end
      else -- fit in a word, consume it
        text = text..word
        tlen = tlen + wlen
        v = ""
        firstword = false
      end
    end--while(each word fragment)
    i = i + 1
    -- line too short, suck next line
    if i > table.getn(t) and not IsSpaceOnly(line + 1) then
      ProcessLine(line + 1)
      editor.TargetStart = editor:PositionFromLine(line + 1)
      editor.TargetEnd = editor:PositionFromLine(line + 2)
      editor:ReplaceTarget("")
    end
  end--while(each word)
  -- handle trailing whitespace
  if trailingspaces and tlen < rightmargin then text = text.." " end
  -- complete line
  SetLine(line, text)
  EndingStuff()
  editor:EndUndoAction()
end
-- end of script

