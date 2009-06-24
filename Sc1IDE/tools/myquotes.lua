--This tool can help you to easily add quotes/tags to selected text 
local c_sel='\255'
local s_sel='~~~'

function sel_quote(quote)
	local sel=editor:GetSelText()
	rep=string.gsub(quote,c_sel,sel)
	editor:ReplaceSel(rep)
end
function select_quotes()
	local quotes=prop2table('MY_QUOTES')
	for _,v in ipairs(quotes) do
		quotes[_]=v:gsub('%[\\n%]','\n'):gsub(s_sel,c_sel)
	end
	scite_UserListShow(quotes,1,sel_quote,'\253')
end