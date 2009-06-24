--[mhb] 06/12/09: toggle whether to enable lua events
module('m_events', package.seeall)

local _E={} --all events are saved in this table
local pn='USE_EVENT_HANDLERS'
if tostring(props[pn])=='' then props[pn]='1' end

function _save_events()
  _E={
  OnUserListSelection=OnUserListSelection,
  OnMarginClick=OnMarginClick,
  OnDoubleClick=OnDoubleClick,
  OnSavePointLeft=OnSavePointLeft,
  OnSavePointReached=OnSavePointReached,
  OnChar=OnChar,
  OnSave=OnSave,
  OnBeforeSave=OnBeforeSave,
  OnSwitchFile=OnSwitchFile,
  OnOpen=OnOpen,
  OnUpdateUI=OnUpdateUI,
  OnKey=OnKey,
  OnDwellStart=OnDwellStart,
  OnClose=OnClose,
  }
  -- for _,v in pairs(_E) do print(_,v) end
end

function _clear_events()
  OnUserListSelection=nil
  OnMarginClick=nil
  OnDoubleClick=nil
  OnSavePointLeft=nil
  OnSavePointReached=nil
  OnChar=nil
  OnSave=nil
  OnBeforeSave=nil
  OnSwitchFile=nil
  OnOpen=nil
  OnUpdateUI=nil
  OnKey=nil
  OnDwellStart=nil
  OnClose=nil
end

function _set_events()
  for _,v in pairs(_E) do
    if props[pn]=='1' then 
      _G[_]=_E[_]
    else
      _G[_]=nil
    end
  end
  if props[pn]=='0' then
    _clear_events()
  end
--[[  
  OnUserListSelection=E.OnUserListSelection
  OnMarginClick=E.OnMarginClick
  OnDoubleClick=E.OnDoubleClick
  OnSavePointLeft=E.OnSavePointLeft
  OnSavePointReached=E.OnSavePointReached
  OnChar=E.OnChar
  OnSave=E.OnSave
  OnBeforeSave=E.OnBeforeSave
  OnSwitchFile=E.OnSwitchFile
  OnOpen=E.OnOpen
  OnUpdateUI=E.OnUpdateUI
  OnKey=E.OnKey
  OnDwellStart=E.OnDwellStart
  OnClose=E.OnClose
  for _,v in pairs(E) do print(_,v) end
  ]]
end


function _toggle_events()
  if props[pn]=='1' then 
    props[pn]='0'
  else
    props[pn]='1'
  end
  _set_events()
end


_save_events()

_set_events()
