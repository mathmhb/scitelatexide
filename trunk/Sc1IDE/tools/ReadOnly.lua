-- VladVRO, mozers
-- version 1.2

--   dofile (props["SciteDefaultHome"].."\\tools\\ReadOnly.lua")
--   statusbar.text.1=Line:$(LineNumber) Col:$(ColumnNumber) [$(scite.readonly)]
--   style.back.readonly=#F2F2F1
------------------------------------------------

function SetReadOnly(ro)
	if ro then
		if props["normal.style.saved"] == "" then
			props["normal.style.saved"] = "1"
			props["caret.period.normal"] = props["caret.period"]
			props["caret.width.normal"] = props["caret.width"]
			props["style.*.33.normal"] = props["style.*.33"]
		end

		props["caret.period"] = 0
		props["caret.width"] = 0
		props["style.*.33"] = props["style.*.33"]..",back:"..props["style.back.readonly"]

		scite.Perform("reloadproperties:")
		props["scite.readonly"] = "VIEW"
	else
		if props["style.back.readonly"]~='' and props["scite.readonly"] == "VIEW" then
			props["caret.period"] = props["caret.period.normal"]
			props["caret.width"] = props["caret.width.normal"]
			props["style.*.33"] = props["style.*.33.normal"]

			scite.Perform("reloadproperties:")
		end
		props["scite.readonly"] = "EDIT"
	end
	scite.UpdateStatusBar()
end


local function on_open(file)
	if SetReadOnly(editor.ReadOnly) then return true end
end

scite_OnSwitchFile(on_open)
scite_OnOpen(on_open)

local old_OnSendEditor = OnSendEditor
function OnSendEditor(id_msg, wp, lp)
	local result
	if old_OnSendEditor then result = old_OnSendEditor(id_msg, wp, lp) end
	if id_msg == SCI_SETREADONLY then
		if SetReadOnly(wp~=0) then return true end
	end
	return result
end
