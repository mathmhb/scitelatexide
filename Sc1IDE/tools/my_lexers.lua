local function pv_(p,val)
	props[p]=tostring(val)
	print(p..'='..val)
end

function set_lexer_typ(typ)
	local m='.$(file.patterns.'..typ..')'
	local z,x='$(','_'..typ..')'
	local lex=props['LEXER_'..typ] or typ
	pv_('lexer'..m,lex)
	pv_('keywords'..m,z..'KEYWORDS'..x)
	for i=2,9 do
		pv_('keywords'..i..m,z..'KEYWORDS'..x)
	end
end

function update_lexers()
	local types=prop2table('FILE_TYPES')
	for _,v in ipairs(filetypes) do
		local typ=v[1]
		set_lexer_typ(typ)
	end
end

update_lexers()

--[[
mylexers={}
scite_require('mylexers.lux')


function add_mylexer(n,v,flag)
	if type(v)=='string' then v={keywords=v};end
	if type(v)~='table' then return;end
	local mode,m,lex,c,s,s0
	m='.'..n
	mode='.$(file.patterns.'..n..')'
	if flag==1 then --first pass process: setting properties related to file patterns
		if not v.keywords then --[mhb] added 04/26/09: to let user define keywords in properties 
			v.keywords='$(KEYWORDS_'..string.upper(n)..')'
		end
		p_('keywordclass'..m,v.keywords)
		p_('keywords'..mode,'$(keywordclass'..m..')')
		for i=2,9 do 
			p_('keywords'..i..mode,v['keywords'..i])
		end
		if type(v.wordchar)=='string' then p_('word.characters'..mode,v.wordchar);end
		if type(v.whitespace)=='string' then p_('whitespace.characters'..mode,v.whitespace);end
		if type(v.lexer)=='string' then p_('lexer'..mode,v.lexer);end
		if props['lexer'..mode]=='' then p_('lexer'..mode,n);end
	elseif flag==2 then --second pass process: setting properties related to lexers
		lex=props['lexer'..mode]
		-- print('Lexer:',lex)
		if lex=='' then return;end
		if lex~=n and not mylexers[lex] then 
			-- print(n..'->'..lex)
			mylexers[lex]={
				lexer=lex,
				comment={props['comment.block.'..lex],props['comment.stream.start.'..lex],props['comment.stream.end.'..lex],props['comment.box.middle.'..lex],props['comment.box.start.'..lex],props['comment.box.end.'..lex]},
				style={}
			}
			for i0=0,37 do 
				s0=props['style.'..lex..'.'..i0]
				if s0~='' then mylexers[lex]['style'][i0]=s0;end
			end
		end
		c=v.comment
		if type(c)=='table' then 
			p_('comment.block.'..lex,c[1])
			p_('comment.stream.start.'..lex,c[2])
			p_('comment.stream.end.'..lex,c[3])		
			p_('comment.box.start.'..lex,c[5] or c[2])
			p_('comment.box.end.'..lex,c[6] or c[3])
			p_('comment.box.middle.'..lex,c[4])
		end
		s=v.style
		if type(s)=='table' then 
			for i0,s0 in pairs(s) do 
				p_('style.'..lex..'.'..i0,s0)
			end
		end
		
	end
end	

function add_mylexers(tbl)
	for n,v in pairs(tbl) do add_mylexer(n,v,1) end
end
function update_mylexers()
	local ftype=props['FileType'] --current_filetype() from menucmds.lua
	--editor:SetLexerLanguage(ftype)
	local mylexer_setting=mylexers[ftype]
	--print(props['FileNameExt'],ftype)
	if not mylexer_setting then return;end
	print('Using lexer ['..ftype..'] defined in mylexer.lux for file ['..props['FilePath']..']!')
	add_mylexer(ftype,mylexer_setting,2)
end
add_mylexers(mylexers)
scite_OnSwitchFile(update_mylexers)
scite_OnOpen(update_mylexers)
scite_OnSave(update_mylexers)

]]

