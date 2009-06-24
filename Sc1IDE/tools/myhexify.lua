-- Convert a string to a string of hex escapes
function Hexify(s) 
  local hexits = ""
  for i = 1, string.len(s) do
    hexits = hexits .. string.format("\\x%2x", string.byte(s, i))
  end
  return hexits
end

-- Convert the selection to hex escaped form
-- command.name.1.*=Hexify Selection
-- command.mode.1.*=subsystem:lua,savebefore:no
-- command.1.*=HexifySelection
function HexifySelection()
  editor:ReplaceSel(Hexify(editor:GetSelText()))
end