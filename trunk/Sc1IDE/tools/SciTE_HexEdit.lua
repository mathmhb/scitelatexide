------------------------------------------------------------------------
-- SciTE_HexEdit: A Self-Contained Primitive Hex Editor for SciTE
------------------------------------------------------------------------
-- Version 0.9, 20050811
-- Copyright 2005 by Kein-Hong Man <khman@users.sf.net>
-- See SciTE_HexEdit.txt for usage instructions.
------------------------------------------------------------------------
-- Permission to use, copy, modify, and distribute this software and
-- its documentation for any purpose and without fee is hereby granted,
-- provided that the above copyright notice appear in all copies and
-- that both that copyright notice and this permission notice appear
-- in supporting documentation.
--
-- KEIN-HONG MAN DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
-- INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN
-- NO EVENT SHALL KEIN-HONG MAN BE LIABLE FOR ANY SPECIAL, INDIRECT OR
-- CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
-- OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
-- NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION
-- WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
------------------------------------------------------------------------

function HexEdit()
  ----------------------------------------------------------------
  -- script settings and constants
  ----------------------------------------------------------------
  -- OPTION: jump to equivalent of binary file's caret position
  local JUMPTO = true
  -- OPTION: more compact view, a few more usable lines
  local COMPACT = false
  -- CONFIG: size of edit window; should be multiple of WIDTH
  local BlockSize = 512
  -- CONFIG: width of hex edit window view
  local WIDTH = 16
  ----------------------------------------------------------------
  local PROMPT = ">HexEdit: "           -- prompt for output window
  local OLDEXT = ".$$$"                 -- extension for old file
  local SIG = "SciTE_HexEdit"           -- used for buffer table
  local TitleLine = ". Braindead SciTE Hex Editor . khman . ver 0.9 (20050811) .\n"
  local ButtonBar = "| UpdateView | Open/Revert | Move: First|Prev|Next|Last | Save | Command |\n"
  ----------------------------------------------------------------
  -- configuration validation
  ----------------------------------------------------------------
  local n = WIDTH while n >= 2 do n = n / 2 end
  if n ~= 1 then
    Error("WIDTH must be a 2^n value in the script") return
  end
  if math.mod(BlockSize, WIDTH) > 0 then
    Error("BlockSize must be a multiple of WIDTH in the script") return
  end
  ----------------------------------------------------------------
  local SEPARATOR = WIDTH / 2
  local REGEX_ASCII = "|("..string.rep(".", WIDTH)..")|%s*$"
  local ButtonLine = "+"..string.rep("-", string.len(ButtonBar)-3).."+\n"
  local HexLine = string.rep("-", 12+WIDTH*4).."\n"
  local HexHeading = "|Offset|  "
  for i = 0, WIDTH-1 do HexHeading = HexHeading..string.format("%02X ", i) end
  HexHeading = HexHeading.."| ASCII view "..string.rep(" ", WIDTH-12).."|\n"
  ----------------------------------------------------------------
  -- helper functions
  ----------------------------------------------------------------
  local function Error(msg) _ALERT(PROMPT..msg) end
  local function HexPos(pos) return string.format("%08X", pos) end
  ----------------------------------------------------------------
  local function CharAt(pos)
    local c = editor.CharAt[pos]
    if c < 0 then c = c + 256 end
    return string.char(c)
  end
  ----------------------------------------------------------------
  local function FixHex(n)
    if type(n) == "string" and string.find(n, "^0[xX]%w") then
      return tonumber(n, 16)
    end
    return tonumber(n)
  end
  ----------------------------------------------------------------
  local function AlignWidth(n)
    while math.mod(n, WIDTH) > 0 do n = n - 1 end
    return n
  end
  ----------------------------------------------------------------
  -- retrieve source file path from header
  ----------------------------------------------------------------
  local function SourceFile(sln)
    if not sln then return end
    local f, _, fl = string.find(sln, [[SourceFile:%s+%"([^%"]+)%"]])
    if f then return fl end
  end
  ----------------------------------------------------------------
  -- retrieve block start position and block size from header
  ----------------------------------------------------------------
  local function BlockInfo(bln)
    if not bln then return end
    local f, _, bp = string.find(bln, "BlockOffset:%s+(%w+)")
    local g, _, bs = string.find(bln, "BlockSize:%s+(%w+)")
    if f and g then return FixHex(bp), FixHex(bs) end
  end
  ----------------------------------------------------------------
  -- retrieve command string if it exists
  ----------------------------------------------------------------
  local function CmdString(bln)
    if not bln then return "" end
    local f, _, cs = string.find(bln, "Command:%s*(.-)%s*$")
    return f and cs or ""
  end
  ----------------------------------------------------------------
  -- parse editor line buffer for hex values
  ----------------------------------------------------------------
  local function ParseForHex(buf)
    local dat = ""
    for v in string.gfind(buf, "[0-9a-fA-F][0-9a-fA-F]") do
      dat = dat..string.char(tonumber(v, 16))
    end
    return dat
  end
  ----------------------------------------------------------------
  -- adjust position of edit window one block up
  ----------------------------------------------------------------
  local function PrevBlock(idx, siz)
    idx = AlignWidth(idx) - siz
    if idx < 0 then idx = 0 end
    return idx
  end
  ----------------------------------------------------------------
  -- adjust position of edit window one block down
  ----------------------------------------------------------------
  local function NextBlock(idx, siz, max)
    idx = AlignWidth(idx)
    local idxnew = idx + siz
    if idxnew > max then return idx end
    return idxnew
  end
  ----------------------------------------------------------------
  -- move to last block in a brain-damaged manner
  ----------------------------------------------------------------
  local function LastBlock(siz, max)
    local idx = 0
    while true do
      local idxnew = NextBlock(idx, siz, max)
      if idxnew == idx then return idx end
      idx = idxnew
    end
  end
  ----------------------------------------------------------------
  -- simple validator for position and size values
  ----------------------------------------------------------------
  local function Validate(max, idx, siz)
    idx, siz = AlignWidth(idx), AlignWidth(siz)
    if idx < 0 then idx = 0 end
    if idx >= max then idx = LastBlock(siz, max) end
    if siz <= 0 then siz = BlockSize end
    return idx, siz
  end
  ----------------------------------------------------------------
  -- basic data loader
  ----------------------------------------------------------------
  local function Load(filepath)
    local INF = io.open(filepath, "rb")
    if not INF then Error("Cannot open \""..filepath.."\" for reading") return end
    local src = INF:read("*a")
    if not src then Error("Failed to read from \""..filepath.."\"") end
    io.close(INF)
    return src
  end
  ----------------------------------------------------------------
  -- data loader with size test
  ----------------------------------------------------------------
  local function LoadData(filepath)
    local data = Load(filepath)
    if not data then return end
    local size = string.len(data)
    if size == 0 then
      Error("Cannot process a zero-length data file") return
    end
    return data, size
  end
  ----------------------------------------------------------------
  -- basic data saver
  ----------------------------------------------------------------
  local function Save(filepath, filedata)
    local ONF = io.open(filepath, "wb")
    if not ONF then Error("Cannot open \""..filepath.."\" for writing") return end
    local okay = ONF:write(filedata)
    if not okay then Error("Failed to write to \""..filepath.."\"") return end
    io.close(ONF)
    return true
  end
  ----------------------------------------------------------------
  -- extended rename function
  ----------------------------------------------------------------
  local function Rename(filename, ext)
    local destname = filename..ext
    local okay = os.rename(filename, destname)
    if not okay then
      for n = 1, 99 do
        destname = filename.."("..n..")"..ext
        if os.rename(filename, destname) then return true end
      end
      return false
    end
    return true
  end
  ----------------------------------------------------------------
  -- hex edit header block
  ----------------------------------------------------------------
  local function HexHeader(origFile, origSize, blkPos, blkSize, cmdString)
    cmdString = cmdString or ""
    editor:AddText(
      TitleLine..                       -- heading block
      ButtonLine..ButtonBar..ButtonLine..
      "SourceFile: \""..origFile.."\"  (FileLength: "..origSize..")\n"..
      "BlockOffset: "..blkPos.."  BlockSize: "..blkSize..
      "  Command: "..cmdString.."\n"
    )
  end
  ----------------------------------------------------------------
  -- hex edit body
  ----------------------------------------------------------------
  local function HexBody(data, origSize, blkPos, blkSize)
    if COMPACT then                                     -- header
      editor:AddText(HexLine)
    else
      editor:AddText("\n"..HexLine..HexHeading..HexLine)
    end
    local startPos = editor.CurrentPos
    blkSize = math.min(blkSize, origSize - blkPos)
    local pos, len = blkPos + 1, blkSize                -- body
    while len > 0 do
      local ln, ascii = HexPos(pos - 1).."  ", "|"
      local n = WIDTH
      while n > 0 do                                    -- per line
        n = n - 1
        if len > 0 then
          local ch = string.sub(data, pos, pos)         -- per byte
          local c = string.byte(ch) or 0
          if c < 32 then ch = " " end
          ln = ln..string.format("%02x", c)
          if n == SEPARATOR then ln = ln.."-" else ln = ln.." " end
          ascii = ascii..ch
          pos, len = pos + 1, len - 1
        else
          ln = ln.."   "
          ascii = ascii.." "
        end--if len
      end--while n
      editor:AddText(ln..ascii.."|\n")
    end--while len
    editor:AddText(HexLine)                             -- footer
    return startPos
  end
  ----------------------------------------------------------------
  -- not a hex edit window; this will open a new hex edit window
  ----------------------------------------------------------------
  local thisWindow = props["FileNameExt"]
  if thisWindow ~= "" then
    local origFile = props["FilePath"]  -- info of source data
    local data, origSize = LoadData(origFile)
    if not data then return end
    local blkPos, blkSize = 0, BlockSize
    local jmpPos
    if JUMPTO then                      -- jumps to location (optional)
      jmpPos = editor.CurrentPos
      while jmpPos > blkSize do
        jmpPos, blkPos = jmpPos - blkSize, blkPos + blkSize
      end
      jmpPos = math.floor(jmpPos / WIDTH)
    end
    scite.Open("")                      -- create an "Untitled" file
    HexHeader(origFile, origSize, blkPos, blkSize)
    local startPos = HexBody(data, origSize, blkPos, blkSize)
    if JUMPTO then
      jmpPos = editor:PositionFromLine(jmpPos + editor:LineFromPosition(startPos))
      editor:GotoPos(jmpPos)            -- start at original pos
    else
      editor:GotoPos(startPos)          -- start at convenient pos
    end
    buffer[SIG] = data                  -- for view synchronization
  ----------------------------------------------------------------
  -- a hex edit window; an operation may be performed
  ----------------------------------------------------------------
  else
    local line1 = editor:GetLine(0) or ""       -- signature check
    if not string.find(line1, TitleLine, 1, 1) then
      return    -- not a hex edit window; ignore
    end
    local pos = editor.CurrentPos
    local ln = editor:LineFromPosition(pos)
    local bln = editor:GetLine(ln) or ""
    local command = "none"
    if string.find(bln, ButtonBar, 1, 1) then   -- find command
      local selBeg, selEnd = pos, pos
      while string.find(CharAt(selBeg-1), "%w") do selBeg = selBeg-1 end
      while string.find(CharAt(selEnd), "%w") do selEnd = selEnd+1 end
      command = editor:textrange(selBeg, selEnd)
    elseif string.find(bln, "^%w%w%w%w%w%w%w%w%s") then
      command = "UpdateView"    -- implied updateview
    else
      return                    -- do nothing
    end
    --------------------------------------------------------
    local origFile = SourceFile(editor:GetLine(4))
    local blkPos, blkSize = BlockInfo(editor:GetLine(5))
    local cmdString = CmdString(editor:GetLine(5))
    if not origFile or not blkPos or not blkSize then
      Error("Failed to parse data parameters in header") return
    end
    local startPos = editor.CurrentPos
    local data = buffer[SIG]
    if not data then
      Error("Please set ext.lua.reset=0 for view updating to work properly") return
    end
    local origSize = string.len(buffer[SIG])
    --------------------------------------------------------
    if command == "Command" then
      local _, _, cmd = string.find(cmdString, "^(%a+)")
      -- CMD_EXTENSIONS: put extended commands here
      if not cmd then
        Error("Command word not found, please read script documentation") return
      --[[elseif cmd == "find" then]]
        --TODO find function
      else
        Error("Unknown command word '"..cmd.."'") return
      end
    end
    --------------------------------------------------------
    if string.find("Open|Revert|First|Prev|Next|Last", command, 1, 1) then
      -- open/revert explicitly reloads the data, block moves don't
      if string.find("Open|Revert", command, 1, 1) then
        data, origSize = LoadData(origFile)
        if not data then Error("Failed to open/reload file") return end
      end
      blkPos, blkSize = Validate(origSize, blkPos, blkSize)
      if command == "First" then
        blkPos = 0
      elseif command == "Prev" then
        blkPos = PrevBlock(blkPos, blkSize)
      elseif command == "Next" then
        blkPos = NextBlock(blkPos, blkSize, origSize)
      elseif command == "Last" then
        blkPos = LastBlock(blkSize, origSize)
      end
      editor:ClearAll()
      HexHeader(origFile, origSize, blkPos, blkSize, cmdString)
      HexBody(data, origSize, blkPos, blkSize)
      editor:GotoPos(startPos)
      buffer[SIG] = data
    --------------------------------------------------------
    elseif string.find("UpdateView|Save", command, 1, 1) then
      local ln = 0                              -- find start of hex data
      while ln < editor.LineCount do
        local dln = editor:GetLine(ln) or ""
        if string.find(dln, "^"..HexPos(blkPos).."%s") then break end
        ln = ln + 1
      end
      --TODO Update currently cannot handle a change of BlockOffset
      if ln == editor.LineCount then return end
      local pos, siz = blkPos, math.min(blkSize, origSize - blkPos)
      local newSize = blkSize
      local hData, aData = "", ""
      while ln < editor.LineCount and siz > 0 do
        -- locate hex offset address
        local dln = editor:GetLine(ln) or ""
        local x, y = string.find(dln, "^"..HexPos(pos).."%s")
        if not x then
          -- user may have changed the BlockSize, not an error condition
          blkSize = string.len(hData) break
        end
        -- locate ascii data portion
        dln = string.sub(dln, y)
        local x, y, ascii = string.find(dln, REGEX_ASCII)
        if not x then
          Error("Failed to read ascii data in edit window") return
        end
        if siz < WIDTH then ascii = string.sub(ascii, 1, siz) end
        aData = aData..ascii
        -- locate hex data portion
        hData = hData..ParseForHex(string.sub(dln, 1, x))
        ln, pos, siz = ln + 1, pos + WIDTH, siz - WIDTH
      end
      local hLen, aLen = string.len(hData), string.len(aData)
      if hLen ~= aLen then
        Error("Data sizes of views do not match, read failed") return
      end
      -- check datasets and update hData for view
      sData = string.sub(data, blkPos+1, blkPos+blkSize)
      if hLen ~= string.len(sData) then
        Error("View data size and original data size don't match") return
      end
      local getbyte = string.byte
      if command == "UpdateView" then   -- synchronize views
        for i = 1, hLen do
          local a, h, s = getbyte(aData, i), getbyte(hData, i), getbyte(sData, i)
          local c
          if h ~= s then c = h elseif a > 32 and a ~= s then c = a end
          if c then
            sData = string.sub(sData, 1, i-1)..string.char(c)..string.sub(sData, i+1)
          end
        end
        data = string.sub(data, 1, blkPos)..sData..string.sub(data, blkPos+blkSize+1)
        editor:ClearAll()
        blkSize = newSize               -- restore new size if it was updated
        HexHeader(origFile, origSize, blkPos, blkSize, cmdString)
        HexBody(data, origSize, blkPos, blkSize)
        editor:GotoPos(startPos)
        buffer[SIG] = data
      else-- command == "Save"          -- trap unsynchronized view
        for i = 1, hLen do
          local a, h, s = getbyte(aData, i), getbyte(hData, i), getbyte(sData, i)
          if a > 32 and a ~= h then
            Error("Hex and ascii views not synchronized, please Update first") return
          end
        end
        -- latest changes are in hData, not sData
        data = string.sub(data, 1, blkPos)..hData..string.sub(data, blkPos+blkSize+1)
        buffer[SIG] = data
      end
    end--if command
    --------------------------------------------------------
    if command == "Save" then    -- auto-updates view too...
      oData, fileSize = LoadData(origFile)
      if not data then
        -- new file, always allow save
      else-- data exists
        if data == oData then           -- don't save if no change
          Error("No changes to save") return
        elseif origSize ~= fileSize then
          Error("File size different, rename SourceFile to new file and try again") return
        end
        -- rename old file as a safety measure; not really foolproof
        local okay = Rename(origFile, OLDEXT)
        if not okay then
          Error("Failed to rename original file for backup; save failed") return
        end
      end
      local okay = Save(origFile, data)         -- attempt to save
      if not okay then
        Error("Problem writing to file; save failed") return
      end
      local changed, getbyte = 0, string.byte
      for i = 1, origSize do                    -- count change bytes
        local c, d = getbyte(data, i), getbyte(oData, i)
        if c ~= d then changed = changed + 1 end
      end
      _ALERT(PROMPT.."Saved changes to \""..origFile.."\"\n"
           ..PROMPT..changed.." bytes changed.")
    --------------------------------------------------------
    end
  end--if thisWindow
end
-- end of script
