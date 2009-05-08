--[[
  Mitchell's mlines.lua
  Copyright (c) 2006 Mitchell Foral. All rights reserved.
  Modifed by haimag@tom.com

  Multiple Lines edit, support insert delete backspace
    and add increment(or decrement) number at successive lines...

  API (see functions for descriptions):
    - MLines_add
    - MLines_add_multiple
    - MLines_clear
    - MLines_update
    - MLines_incr



  command.name.1.*=MLines Add Marker
  command.1.*=dostring MLines_add()
  command.mode.1.*=subsystem:lua,savebefore:no

  command.name.2.*=MLines Add Markers
  command.2.*=dostring MLines_add_multiple()
  command.mode.2.*=subsystem:lua,savebefore:no

  command.name.3.*=MLines Edit Update
  command.3.*=dostring MLines_update()
  command.mode.3.*=subsystem:lua,savebefore:no

  command.name.4.*=MLines Clear Markers
  command.4.*=dostring MLines_clear()
  command.mode.4.*=subsystem:lua,savebefore:no

  command.name.5.*=MLines Insert Number
  command.5.*=*dostring MLines_incr($(1),$(2)) -- $1:start_num,$2:incr_num ."
  command.mode.5.*=subsystem:lua,savebefore:no
]]--

-- options
local MARK_MLINE = 2
local mlines = {}
local mlines_count = 0
local mlines_start_col = 0
local mlines_end_col = 0

local mlines_most_recent
local PLATFORM = PLATFORM or 'linux'
local MARK_MLINE_COLOR
if PLATFORM == 'linux' then
  MARK_MLINE_COLOR = tonumber("0x4D994D")
elseif PLATFORM == 'windows' then
  MARK_MLINE_COLOR = 5085517
end
MARK_MLINE_COLOR = 5085517
-- end options



-- adds mline marker on current line
function MLines_add()
  MLines_clear()

  editor:MarkerSetBack(MARK_MLINE, MARK_MLINE_COLOR)
  local column = editor.Column[editor.CurrentPos]
  local line = editor:LineFromPosition(editor.CurrentPos)
  local new_marker = editor:MarkerAdd(line, MARK_MLINE)
  mlines[line] = { marker = new_marker }
  mlines_most_recent = line
  mlines_count =1
  mlines_start_col = column
  mlines_end_col = editor:LineLength(line)
end

-- adds set of mline markers between most recently added line
-- and current line (using current column on current line)
function MLines_add_multiple()
  if mlines_count > 0 then
    local line = editor:LineFromPosition(editor.CurrentPos)
    local column = editor.Column[editor.CurrentPos]
    local start_line, end_line
    if mlines_most_recent < line then
      start_line, end_line = mlines_most_recent, line
    else
      start_line, end_line = line, mlines_most_recent
    end
    for curr_line = start_line, end_line do
      local new_mark = editor:MarkerAdd(curr_line, MARK_MLINE)
      mlines[curr_line] = { marker = new_mark }
    end
    mlines_count = 1
    mlines_most_recent = line

    mlines_start_col = column
    mlines_end_col = editor:LineLength(line)
  end
end

-- clears all mline markers
function MLines_clear()
  editor:MarkerDeleteAll(MARK_MLINE)
  mlines = {}
  mlines_count = 0
  mlines_most_recent = nil
end

-- applies changes in current line to all lines being edited
function MLines_update()
  editor:BeginUndoAction()

  local curr_line = editor:LineFromPosition(editor.CurrentPos)
  local curr_col  = editor.Column[editor.CurrentPos]
  if mlines[curr_line] then
    local start_pos = editor:FindColumn(curr_line, mlines_start_col)
    local end_pos   = editor:FindColumn(curr_line, curr_col)
    local delta     = curr_col - mlines_start_col

    local line_end_col = editor:LineLength(curr_line)
    local delta2  = (mlines_end_col - line_end_col)

    local txt       = ''
    if delta > 0 then
      txt = editor:textrange(start_pos, end_pos)
    end

    for line_num in mlines do
      if line_num ~= curr_line then
        --taking into account tabs
        start_pos = editor:FindColumn(line_num, mlines_start_col)
        local d = mlines_start_col-editor.Column[start_pos]

        -- add space
        if d>0 then
            editor:insert(start_pos,  string.rep(" ", d ))
            start_pos = start_pos+d
        end

        if delta == 0 then
          if delta2 > 0 then -- do delete
            editor.TargetStart = start_pos
            editor.TargetEnd   = editor:FindColumn(line_num, curr_col + delta2)
            editor:ReplaceTarget('')
          end
        elseif delta < 0 then -- do backspace
          end_pos   = editor:FindColumn(line_num, curr_col)
          editor.TargetStart = end_pos
          editor.TargetEnd   = start_pos
          editor:ReplaceTarget('')
        else
          if editor.Overtype then  -- do overtype
            end_pos   = editor:FindColumn(line_num, curr_col)
            editor.TargetStart = start_pos
            editor.TargetEnd   = end_pos
            editor:ReplaceTarget(txt)
          else
            editor:InsertText(start_pos, txt)
          end
        end
      end
    end
    if delta <= 0 then
      local pos = editor:FindColumn(curr_line, curr_col)
      editor.CurrentPos, editor.Anchor = pos, pos
    end
    mlines_start_col = curr_col
    mlines_end_col   = editor:LineLength(curr_line)
  end

  editor:EndUndoAction()
end

-- add incrment number at succesive lines
function MLines_incr(s_start_num, s_incr_num)
  editor:BeginUndoAction()

  local curr_line = editor:LineFromPosition(editor.CurrentPos)
  local curr_col  = editor.Column[editor.CurrentPos]

  if mlines[curr_line] then

    local start_num = tonumber(s_start_num)
    local incr_num  = tonumber(s_incr_num )

    if start_num ==nil or incr_num==nil then
        trace("please set two integer parameter.")
        return
    end

    local min_line = curr_line
    local max_line = curr_line
    for line_num in mlines do
        if min_line > line_num then min_line = line_num end
        if max_line < line_num then max_line = line_num end
    end

    for line_num= min_line, max_line do
        local start_pos = editor:FindColumn(line_num, mlines_start_col)
        local d = mlines_start_col-editor.Column[start_pos]

        -- add space
        if d>0 then
            editor:insert(start_pos,  string.rep(" ", d ))
            start_pos = start_pos+d
        end

        editor:InsertText(start_pos, tostring(start_num) )
        start_num = start_num +incr_num
    end --end for

    mlines_start_col = curr_col
    mlines_end_col   = editor:LineLength(curr_line)
  end

  editor:EndUndoAction()
end
