-- doing word substitutions on the fly!
local words


local function word_substitute(word)
  return words and words[word] or word
end

local word_start,in_word,current_word
local find = string.find

local function on_char(s)
 --[mhb] 06/18/09: use properties rather than lux files 
 words=prop2table('MY_WORDSUBS_'..props['FileType'])
 if words=={} or words==nil then return end
 
 if not in_word then
    if find(s,'%w') then 
      -- we have hit a word!
      word_start = editor.CurrentPos
      in_word = true
      current_word = s
    end
 else -- we're in a word
   -- and it's another word character, so collect
   if find(s,'%w') then   
      current_word = current_word..s
   else
    -- leaving a word; see if we have a substitution
      local word_end = editor.CurrentPos
      local subst = word_substitute(current_word)
      if subst ~= current_word then
         editor:SetSel(word_start-1,word_end-1)
         -- this is somewhat ad-hoc logic, but
         -- SciTE is handling space differently.
         local was_whitespace = find(s,'%s')
         if was_whitespace then
            subst = subst..s
         end
	 editor:ReplaceSel(subst)
         word_end = editor.CurrentPos
         if not was_whitespace then
            editor:GotoPos(word_end + 1)
         end
      end
      in_word = false
   end   
  end 
  -- don't interfere with usual processing!
  return false
end  

function set_event_wordsubs(toggle)
   local p=tostring(props['AUTO_WORDSUBS'])
   if toggle==1 then
      if p=='0' then p='1' else p='0' end
      props['AUTO_WORDSUBS']=p
   end
   if p=='1' then 
      scite_OnChar(on_char)
   else
      scite_OnChar(on_char,'remove')
   end
end

function toggle_wordsubs()
   set_event_wordsubs(1)
end

set_event_wordsubs()