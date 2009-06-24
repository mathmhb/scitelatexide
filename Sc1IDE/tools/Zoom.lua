--[[-------------------------------------------------
Zoom.lua
Version: 1.2
Authors: mozers 
(magnification, print.magnification, output.magnification)
save_settings.lua
-----------------------------------------------------
  statusbar.text.1=$(font.current.size)px
  dofile (props["SciteDefaultHome"].."\\tools\\Zoom.lua")
--]]-------------------------------------------------

local function ChangeFontSize(zoom)
	if output.Focus then
		props["output.magnification"] = output.Zoom
	else
		props["magnification"] = zoom
		props["print.magnification"] = zoom
		local _, _, font_current_size = props["style.*.32"]:find("size:(%d+)")
		props["font.current.size"] = font_current_size + zoom -- Used in statusbar
		scite.UpdateStatusBar()
	end
end

local old_OnSendEditor = OnSendEditor
function OnSendEditor(id_msg, wp, lp)
	local result
	if old_OnSendEditor then result = old_OnSendEditor(id_msg, wp, lp) end
	if id_msg == SCI_SETZOOM then
		ChangeFontSize(lp)
	end
	return result
end