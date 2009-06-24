-- Sort a selected text
-- I got the lines function from Lua wiki at http://lua-users.org/wiki/StringRecipes

function lines(str)
  local t = {}
  local i, lstr = 1, #str
  while i <= lstr do
    local x, y = string.find(str, "\r?\n", i)
    if x then t[#t + 1] = string.sub(str, i, x - 1)
    else break
    end
    i = y + 1
  end
  if i <= lstr then t[#t + 1] = string.sub(str, i) end
  return t
end

function sort_text()
  local sel = editor:GetSelText()
  if #sel == 0 then return end
  local eol = string.match(sel, "\n$")
  local buf = lines(sel)
  --table.foreach(buf, print) --used for debugging
  table.sort(buf)
  local out = table.concat(buf, "\n")
  if eol then out = out.."\n" end
  editor:ReplaceSel(out)
end

function sort_text_reverse()
  local sel = editor:GetSelText()
  if #sel == 0 then return end
  local eol = string.match(sel, "\n$")
  local buf = lines(sel)
  --table.foreach(buf, print) --used for debugging
  table.sort(buf, function(a, b) return a > b end)
  local out = table.concat(buf, "\n")
  if eol then out = out.."\n" end
  editor:ReplaceSel(out)
end