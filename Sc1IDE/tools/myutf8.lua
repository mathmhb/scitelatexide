--scite_require 'm_ext.lua'
function toggle_utf8() 
	if editor.CodePage~=SC_CP_UTF8 then 
		editor.CodePage=SC_CP_UTF8
		print('Codepage is switched to UTF8 now!')
	else
		editor.CodePage=tonumber(codepage)
		print('Codepage is changed to '..codepage..' now!')
	end
end


--scite_Command(c_{'Toggle UTF8','ʹ��UTF8����','�ϥ�UTF8�s�X'}..'|toggle_utf8|Ctrl+Alt+U')

-- [mhb] 06/26/11 : decode an UTF8 string to a table of unicode codes
local function DecodeUTF8(s)
    local mod = math.mod
    local function charat(p)
      local v = s:byte(p); if v < 0 then v = v + 256 end; return v
    end
    local codes={}
    local pos=0
    local v, c, n
    while(pos<s:len()) do
      pos=pos+1
      v, c, n = 0, charat(pos), 1
      if c < 128 then v = c
      elseif c < 192 then
        error("Byte values between 0x80 to 0xBF cannot start a multibyte sequence")
      elseif c < 224 then v = mod(c, 32); n = 2
      elseif c < 240 then v = mod(c, 16); n = 3
      elseif c < 248 then v = mod(c,  8); n = 4
      elseif c < 252 then v = mod(c,  4); n = 5
      elseif c < 254 then v = mod(c,  2); n = 6
      else
        error("Byte values between 0xFE and OxFF cannot start a multibyte sequence")
      end
      for i = 2, n do
        pos = pos + 1; c = charat(pos)
        if c < 128 or c > 191 then
          error("Following bytes must have values between 0x80 and 0xBF")
        end
        v = v * 64 + mod(c, 64)
      end
      table.insert(codes,v)
    end
    return codes
end

-- [mhb] 06/26/11 : convert an UTF8 string to RTF string representation
local function RTF_UTF8_string(s)
    local codes=DecodeUTF8(s)
    local u_str=''
    for _,v in ipairs(codes) do 
		if(v==string.byte('\\')) then
			u_str=u_str.."\\'5C"
        elseif(v<256) then 
			u_str=u_str..string.char(v)
		else
			u_str=u_str..'\\u'..v..','
		end
    end
    -- print(u_str)
    return u_str
end




-- return value of UTF-8 character <khman@users.sf.net> 20061017 public domain
-- (see Markus Kuhn's UTF-8 and Unicode FAQ or RFC3629 for more info)
function FromUTF8(pos)
  local mod = math.mod
  local function charat(p)
    local v = editor.CharAt[p]; if v < 0 then v = v + 256 end; return v
  end
  local v, c, n = 0, charat(pos), 1
  if c < 128 then v = c
  elseif c < 192 then
    error("Byte values between 0x80 to 0xBF cannot start a multibyte sequence")
  elseif c < 224 then v = mod(c, 32); n = 2
  elseif c < 240 then v = mod(c, 16); n = 3
  elseif c < 248 then v = mod(c,  8); n = 4
  elseif c < 252 then v = mod(c,  4); n = 5
  elseif c < 254 then v = mod(c,  2); n = 6
  else
    error("Byte values between 0xFE and OxFF cannot start a multibyte sequence")
  end
  for i = 2, n do
    pos = pos + 1; c = charat(pos)
    if c < 128 or c > 191 then
      error("Following bytes must have values between 0x80 and 0xBF")
    end
    v = v * 64 + mod(c, 64)
  end
  return v, pos, n
end

-- return UTF-8 sequence string <khman@users.sf.net> 20061017 public domain
-- (see Markus Kuhn's UTF-8 and Unicode FAQ or RFC3629 for more info)
function ToUTF8(v)
  local math = math
  local n, s, b = 1, "", 0
  -- delete this if your version of SciTE goes beyond UCS-2
  if v > 65535 then error("SciTE does not support codes above U+FFFF") end
  if v >= 55296 and v <= 57343 then
    error("failed to convert UTF-16 surrogate pairs to UTF-8")
  end
  if    v >= 67108864 then n = 6; b = 252
  elseif v >= 2097152 then n = 5; b = 248
  elseif v >=   65536 then n = 4; b = 240
  elseif v >=    2048 then n = 3; b = 224
  elseif v >=     128 then n = 2; b = 192
  end
  for i = 2, n do
    local c = math.mod(v, 64); v = math.floor(v / 64)
    s = string.char(c + 128)..s
  end
  s = string.char(v + b)..s
  return s, n
end

-- write out a UTF-16 table <khman@users.sf.net> 20061017 public domain
function UTF16Table()
  scite.Open("")
  editor.CodePage = SC_CP_UTF8
  editor:AppendText("-*- coding: utf-8 -*-\n")
  editor:AppendText("   Dec ( Hex ) : 0123456789ABCDEF0123456789ABCDEF\n")
  editor:AppendText("-------------------------------------------------\n")
  for p = 0, 65535, 32 do
    ln = string.format("%6d (0x%4X): ", p, p)
    for q = p, p+31 do
      if q < 32 or (q >= 55296 and q <= 57343) then ln = ln.."?"
      else ln = ln..ToUTF8(q)
      end
    end
    ln = ln.."\n"
    editor:AppendText(ln)
  end
end


-- demonstrate use of FromUTF8() function: display the character code
-- value of the current character under the cursor in the output window
function Demo_FromUTF8()
  print("Character code: "..(FromUTF8(editor.CurrentPos)))
end

-- demonstrate use of ToUTF8() function: display two characters based
-- on the given unicode value
function Demo_ToUTF8()
  editor:AppendText(ToUTF8(tonumber("0x4E2D", 16)))
  editor:AppendText(ToUTF8(tonumber("0x6587", 16)))
end

