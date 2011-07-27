--[mhb] 01/16/10 : fix a bug in UTF8 encoding by changing '\255' to '\127'
--This tool can help you to easily add quotes/tags to selected text 
local c_sel='\127'
local s_sel='~~~'
local p_sel='{@@@@@}'

function sel_quote(quote)
	local sel=editor:GetSelText()
	sel=string.gsub(sel,'%%',p_sel)
	print(quote,sel)
	rep=string.gsub(quote,c_sel,sel)
	rep=string.gsub(rep,p_sel,'%%')
	print(rep)
	editor:ReplaceSel(rep)
end
function select_quotes()
	local quotes=prop2table('MY_QUOTES')
	for _,v in ipairs(quotes) do
		quotes[_]=v:gsub('%[\\n%]','\n'):gsub(s_sel,c_sel)
	end
	scite_UserListShow(quotes,1,sel_quote,'\253')
end