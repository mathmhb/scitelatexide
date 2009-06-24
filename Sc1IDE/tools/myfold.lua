-- folding any documents in SciTE

if fold_settings then 
	print('WARNING!:\t It seems that you are using old fold.lua written by mathmhb. \n\t Please remove fold.lua and use its new version myfold.lua.' )
end
	
myfold_settings={}
myfold_list={}
local myfold_stack={}
local myfold_verbatim=0
local myfold_quote=0
local line_no=0
local myfold_comment=0

local strfind = string.find
local strlen = string.len
local gfind = string.gfind
local d={}

function find_plain(s,pat,start)
  local tmp1,tmp2
  tmp1,tmp2=string.find(s,pat,start,true)
  return tmp1,tmp2
end

function find_word(s,pat,start)
  local i1,i2,s1,s2
  s1=' '..s..' '
  i1,i2=string.find(s1,pat,start)
  if i1==nil then return  nil,nil; end
  if i1>1  then 
    s2=string.sub(s1,i1-1,i1-1)..string.sub(s1,i2+1,i2+1)
    if not string.find(s2,'[_%w]') then 
      i1=i1-1;i2=i2-1;
    else
      i1=nil;i2=nil
    end
  end 
   return i1,i2
end


function find_comment(s,pat,start)
  local i1,i2,l
  i1,i2=string.find(s,pat,start)
  l=string.len(s)
  if type(i1)=='number' then
    if myfold_comment==0 then
     myfold_comment=1
     return l,-1
    elseif myfold_comment==1 then
     return nil,nil
    end
  else
    if myfold_comment==1 then
     myfold_comment=0
     return 1,-1  
    else
     return nil,nil
    end
  end
end
     


-- scite_Command {
--   'Folding--Show Outline|toggle_outline',
--   'Folding--Rescan|myfold_process_file $(FilePath)',
-- }

function myfold_toggle_outline()
  for i = 0,editor.LineCount-1 do
     if editor.FoldLevel[i] < SC_FOLDLEVELHEADERFLAG then
        editor:HideLines(i,i)
     end
  end   
end

--[mhb] 01/15/09
function toggle_outline() 
scite.MenuCommand (IDM_TOGGLE_FOLDALL) 
end



local function set_level(i,lev,fold)
  local foldlevel = lev + SC_FOLDLEVELBASE
  if fold then 
     foldlevel = foldlevel + SC_FOLDLEVELHEADERFLAG
     editor.FoldExpanded[i] = true
  end
  editor.FoldLevel[i] = foldlevel
end

-- we need to know if a line is a fold point;
-- this is ad-hoc code that doesn't work for
-- richer fold info!
local function get_level(i)
  local fold = false
  local level_flags = editor.FoldLevel[i] - SC_FOLDLEVELBASE
  if level_flags - SC_FOLDLEVELHEADERFLAG >= 0 then
    fold = true
    level_flags = level_flags - SC_FOLDLEVELHEADERFLAG 
  end
  return level_flags, fold  
end

local txt_extensions = {}
local txt_ext_prop = nil
local file_ext

local lev=0
local in_text_file
local outline_pat = '^(=+)'
local start_depth
local looking_for_number,explicit_match1,explicit_match2
local txt_files = {}
local parse_myfold_line

scite_require 'myfold.lux'

function get_par_level(i,last_lev)
  local par_lev=last_lev-1
  for j=i-2,0,-1 do
    local lev_j=get_level(j)
    if lev_j<last_lev then par_lev=lev_j end
  end
  return par_lev
end

function myfold_process_line(i)
  local line=editor:GetLine(i)
  local depth = parse_myfold_line(line)
  d[i]=depth
  local tmp,last_i,last_lev,last_fold
  if i==0 then 
    set_level(i,0,depth)
    return
  end
  
  last_lev,last_fold=get_level(i-1)
  if (not depth) then
    if last_fold then
      set_level(i,last_lev+1,false)
    elseif d[i-1]==-2 then
      local par_lev=get_par_level(i,last_lev)
      set_level(i,par_lev,false)
    else
      set_level(i,last_lev,false)
    end
  elseif depth==0 then
    set_level(i,last_lev,false)
  elseif depth>0 then
    set_level(i,depth,true)
  elseif depth==-1 then
    if last_fold then
      set_level(i,last_lev+1,true)
    else
      set_level(i,last_lev,true)
    end
  elseif depth==-2 then
    set_level(i,last_lev,false)
  elseif depth==-3 then
    if last_lev>0 then
      local par_lev=get_par_level(i,last_lev)
      set_level(i,par_lev,true)
    else
      set_level(i,0,true)
    end
  elseif depth==-9 then
    set_level(i,last_lev,false)
  end
  
  --[[
   if not depth then 
        set_level(i,lev)
   elseif depth>0 then
	lev = depth
        set_level(i,depth-1,true)   
   elseif depth==-1 then
	table.insert(myfold_stack,{lev,i})
	set_level(i,lev,true)  
	lev=lev+1
   elseif depth==-2 then
    	tmp=table.remove(myfold_stack)
    	if tmp==nil then return; end
 	set_level(i,lev,false) 
   	lev=tmp[1]
   elseif depth==-3 then
   	tmp=table.getn(myfold_stack) or 0
    	if tmp==0 then return; end
    	lev=myfold_stack[tmp][1]
    	set_level(i,lev,true)
    	lev=lev+1
   else
        	set_level(i,lev)
   end 
   ]]--
end

local debug=0
  
function my_parse_line(line)
  local pattern,dep,tmp,vrb,i1,i2,j1,j2,l,s_find,line2
  for i=1,table.getn(myfold_list) do
    pattern=myfold_list[i][1]
    s_find=find_plain
    if type(pattern)=='table' then
      s_find=pattern[2] or string.find
      pattern=pattern[1]
    end
    i1,i2=s_find(line,pattern,1)
    i1,i2=i1 or 0, i2 or 0
    tmp=table.getn(myfold_list[i])
    dep=myfold_list[i][2]
    vrb=myfold_list[i][3]
    j1=nil

    if (dep==-9) then
      line2=editor:GetLine(line_no+1)
      if line2 then j1=s_find(line2,pattern,1);end
      j1=j1 or 0
      if (i1>0) and (j1>0) and (myfold_comment==0) then 
         myfold_comment=1
         return -1
      elseif (i1>0) and (j1==0) and (myfold_comment==1) then
         myfold_comment=0
         return -2
      elseif (i1>0)  then
         return
      end
    end
    
    j1=nil
    if (i1>0) and (i2>0) and (dep==-1) and (myfold_list[i+1][2]==-2) then
       pattern2=myfold_list[i+1][1]
       if type(pattern2)=='table' then
          pattern2=pattern2[1]
       end
       j1,j2=s_find(line,pattern2,1)
    elseif (i1>0) and (i2>0) and (dep==0) then 
       j1,j2=s_find(line,pattern,i2+1)
    end
    j1,j2=j1 or 0, j2 or 0
    if debug==1 then print("[i1,i2,pattern]=",i1,i2,pattern,"[j1,j2,pattern2]=",j1,j2,pattern2);end    
    if (j1>0) then return;end
    if (i1>0) and (j1==0) then 
       if dep==0 then
          myfold_quote=1-myfold_quote
	  return myfold_quote-2
       elseif (vrb==nil) and (myfold_verbatim==0) then 
          return dep
       elseif (vrb==0) then 
          myfold_verbatim=1-myfold_verbatim
          return dep
       end
    end
  end
  return  
end

local function prefix_match(line)
     local _,_,prefix = strfind(line,outline_pat)
     if prefix then
         return strlen(prefix) - start_depth
     end 
end

local function prev_depth(i,depth)
  for j=i-1,1,-1 do
    local d=my_parse_line(line)
  end
end

function myfold_process()
  myfold_stack={}
  myfold_verbatim=0
  myfold_quote=0
  myfold_verbatim=0
  myfold_quote=0
  myfold_comment=0
  start_depth=0
  file_ext = props['FileExt']
  myfold_list = nil 
  if file_ext=='txt' then
    parse_myfold_line=prefix_match
  else
	parse_myfold_line=my_parse_line
	filetype=props['FileType'] --a property provided by menucmds.lua
	if filetype=='' then return;end
	myfold_list=myfold_settings[filetype]
    if not myfold_list then return; end
  end
  
  local curpos=editor.CurrentPos
  local line=editor:LineFromPosition(curpos)-1
  local n = editor.LineCount
  local n_from=math.max(0,line-20)
  local n_to=math.min(line+20,n-2)
  lev = 0
  for i = n_from,n_to do  -- n-2??
      line_no=i
      myfold_process_line(i)
  end
end


process=myfold_process

-- yes, this can all be done w/out extman! 
-- But OnEditorLine() is not a builtin SciTE event,
-- so check the extman source for the implementation.

--~ scite_OnSwitchFile(myfold_process)
--~ scite_OnOpen(myfold_process)
--~ scite_OnBeforeSave(myfold_process)
--~ scite_OnEditorLine(myfold_process)
scite_OnUpdateUI(myfold_process)

--[[
scite_OnEditorLine(function(line)
  if myfold_list then
    -- No. of line we have just entered
    local l = editor:LineFromPosition(editor.CurrentPos) - 1
    if l < 0 then return end
    local nlev,fold
    if l < 0 then
      nlev,fold = 0,false
    else
      nlev,fold = get_level(l-1)      
    end
    if not fold then lev = nlev 
                else lev = nlev + 1
                end
    set_level(l+1,lev)
    myfold_process_line(l,line)
  end
end)
]]--

-- [mhb]: for debugging--
--[[
if scite_GetProp('DEBUG_FOLD','0')=='1' then
scite_OnDoubleClick(function()
  --print(editor.CurrentPos)
  editor:GotoPos(editor.CurrentPos)-- get rid of the selection!
  local l = editor:LineFromPosition(editor.CurrentPos)
  local line=editor:GetLine(l)
  print('line:'..l,'level:'..get_level(l),'lexer:'..editor.Lexer,'depth:',my_parse_line(line),line)
  debug=1;my_parse_line(line);debug=0;
end)
end
]]--

