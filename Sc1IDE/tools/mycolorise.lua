-----------------------------------------------------------------------
-- demo to provide custom colours and styles to a specific buffer
-- <khman@users.sf.net> public domain 20060906
-----------------------------------------------------------------------

local function SetColours(lexer, scheme)
  local function dec(s) return tonumber(s, 16) end
  if lexer then editor.Lexer = lexer end
  for i, style in pairs(scheme) do
    for prop, value  in pairs(style) do
      if (prop == "StyleFore" or prop == "StyleBack")
         and type(value) == "string" then -- convert from string
        local hex, hex, r, g, b =
          string.find(value, "^(%x%x)(%x%x)(%x%x)$")
        value = hex and (dec(r) + dec(g)*256 + dec(b)*65536) or 0
      end
      editor[prop][i] = value
    end--each property
  end--each style
end

--scite_Command('ColourTest|ColourTest|Ctrl+8')

local ColourScheme = { -- a sample colour scheme
  [1] = {StyleFore = "800000", StyleBold = true,},
  [2] = {StyleFore = "008000", StyleBack = "E0E0E0", StyleItalic = true,},
}

function ColourTest()
  local SIG = "ColourTest"
  -- colouriser function, used when buffer created or switched
  local function Colourise(n)
    local segment = n * 2
    editor:StartStyling(0, 31)
    for i = 1, 10 do
      editor:SetStyling(segment, 1)
      editor:SetStyling(segment, 2)
    end
  end
  -- recolour text again upon switching buffers
  scite_OnSwitchFile(function()
    if not buffer[SIG] then return end
    SetColours(SCLEX_CONTAINER, ColourScheme)
    Colourise(editor.Length / 100)
    return true
  end)
  -- create buffer, identify it, add some text, colourise
  scite.Open("")
  buffer[SIG] = true;
  SetColours(SCLEX_CONTAINER, ColourScheme)
  for i = 1, 100 do
    editor:AddText("The quick brown fox jumped over the lazy dog.\n")
  end
  Colourise(editor.Length / 100)
  -- since this colouring method breaks upon many operations, it
  -- cannot be used as a language syntax highlighter
  editor.ReadOnly = true
end
