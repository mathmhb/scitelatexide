-- [mhb] modified: to use m_ext.lua
-- ROWrite
-- Version: 1.1
-- Midas, VladVRO
-----------------------------------------------
--     dofile (props["SciteDefaultHome"].."\\tools\\ROWrite.lua")
-----------------------------------------------

local function BSave(FN)
	local FileAttr = file_attr_string(get_fileattr(FN))
	props['FileAttrNumber'] = 0
	if string.find(FileAttr, '[RHS]') then 
		local msg=c_{"Do you really want to save file with attributes ["..FileAttr..']?','该文件具有属性['..FileAttr..']，确认要保存？','赣ゅンㄣΤ妮┦['..FileAttr..']谔粄璶玂'}
		local choice=get_choice(msg,{"Yes","No"},200)
		if choice==1 then
			local FileAttrNumber= get_fileattr(FN)
			if (FileAttrNumber < 0) then
				props['FileAttrNumber'] = 32 + iif(string.find(FileAttr,'R'),1,0) + iif(string.find(FileAttr,'H'),2,0) + iif(string.find(FileAttr,'S'),4,0)
			else
				props['FileAttrNumber'] = FileAttrNumber
			end
			set_fileattr(FN, 2080)
		end
	end
end

local function AfterSave(FN)
	local FileAttrNumber = tonumber(props['FileAttrNumber'])
	if FileAttrNumber ~= nil and FileAttrNumber > 0 then
		set_fileattr(FN, FileAttrNumber)
	end
end


scite_OnBeforeSave(BSave)
scite_OnSave(AfterSave)

