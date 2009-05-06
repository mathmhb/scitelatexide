function scite_GetProp(key,default)
   local val = props[key]
   if val and val ~= '' then return val 
   else return default end
end  

block_prefix= [[
\documentclass[CJK]{cctart}
\usepackage{amsmath}
\usepackage{graphicx}
\begin{document}
]]
block_suffix=[[
\end{document}
]]

block_compiler='SmartTeXer -pdf -once -nonstopmode'
block_viewer='start ""'
block_view_ext='.pdf'
block_use_sys_tmp_path = 1
block_del_aux = 1

block_max_line = 100
block_tbl={'compiler','viewer','view_ext','use_sys_tmp_path','del_aux'}

GTK = scite_GetProp('PLAT_GTK')
if GTK then slash = '/' else slash = '\\' end
if GTK then rm_cmd = 'rm -y ' else rm_cmd = 'del /Q ' end
if GTK then cd_cmd = 'cd ' else cd_cmd = 'cd /D ' end
if GTK then temp_dir = '/tmp/' else temp_dir = os.getenv('TEMP')..slash end


function compile_tex_block()
        local sel = editor:GetSelText()
        if sel == '' then
                return 
        end
        local _block_prefix,_block_suffix='',''
        local _,e1 = editor:findtext('^[^%]*\\\\begin\\s*{document}',SCFIND_REGEXP)
        if e1 == nil then
                _block_prefix = block_prefix
        else
                local s2,e2 = editor:findtext('^[^%]*\\\\begin\\s*{CJK\\**}{.+}{.+}',SCFIND_REGEXP,e1)
                if e2 == nil then
                        _block_prefix = editor:textrange(0,e1)
                else
                        _block_prefix = editor:textrange(0,e2)
                        local _,_,_cjk = string.find(editor:textrange(s2,e2),'\\begin%s*{(.-)}')
                        _block_suffix = _block_suffix..'\n'..'\\end{'.._cjk..'}'
                end
        end
        _block_prefix = _block_prefix..'\n'
        _block_suffix = _block_suffix..'\n'..block_suffix

        local l = math.min(block_max_line,editor.LineCount)
        for i=0,l-1 do
            local s = editor:GetLine(i)
			if s ~=nil then
                for i=1,table.getn(block_tbl) do
                        local _,_,v = string.find(s,"^%%!block%s+"..block_tbl[i].."%s+([^\r\n]+)")
                        if v ~= nil and v ~= '' then
                                dostring('block_'..block_tbl[i]..'=\''..v..'\'')
                        end
                end
			end
        end
        
        local block_tmp_path = props['FileDir']..slash
        local block_tmp_file = '__temp__'
        if tonumber(block_use_sys_tmp_path) == 1 then
				block_tmp_path = temp_dir
        end
        local block_tmp_tex = _block_prefix..sel.._block_suffix
        local block_tmp_f = io.open(block_tmp_path..block_tmp_file..'.tex', 'wb')
        if not block_tmp_f then 
                print('Can not open the temporary file')
                return 
        end
        block_tmp_f:write(block_tmp_tex)
        block_tmp_f:close()
        local cmd
		cmd = cd_cmd..block_tmp_path
        cmd = cmd..' && '..block_compiler..' '..block_tmp_file..'.tex'
        if block_viewer ~= '@' then
                cmd = cmd..' && '..block_viewer..' '..block_tmp_file..block_view_ext
        end
        if tonumber(block_del_aux) == 1 then
			cmd = cmd..' && '..rm_cmd..block_tmp_file..'.aux'
        end
        os.execute(cmd)
end

-- --------------------------------------------------------------

compiler='SmartTeXer -pdf -view -nonstopmode -source='

props['master.set'] = 0
props['master.name']=nil
props['master.dir']=nil

props['command.separator.18.$(file.patterns.latex)']=1
props['command.name.18.$(file.patterns.latex)']='Set Master File'
props['command.18.$(file.patterns.latex)']='togglemaster'
props['command.mode.18.$(file.patterns.latex)']='subsystem:lua,savebefore:yes'
props['command.shortcut.18.$(file.patterns.latex)']='Alt+8'

props['command.name.19.$(file.patterns.latex)']='Compile Master File'
props['command.19.$(file.patterns.latex)']='print Currently there is no master file. Needs to set a master file first.'
props['command.mode.19.$(file.patterns.latex)']='subsystem:lua,savebefore:yes'
props['command.shortcut.19.$(file.patterns.latex)']='Alt+9'

function togglemaster()
	if tonumber(props['master.set'])==0 then
		props['master.set'] = 1
		props['master.dir']=props['FileDir']
		props['master.name']=props['FileNameExt']
		props['command.checked.18.$(file.patterns.latex)']=props['master.set']
		props['command.19.$(file.patterns.latex)']='$(ComSpec) /c CD /d $(master.dir) && '..compiler..'$(master.name)'
		props['command.mode.19.$(file.patterns.latex)']='subsystem:console,savebefore:yes'
		output:append(props['master.dir']..slash..props['master.name']..' set as master file.\n')
	else
		props['master.set'] = 0
		props['master.name']=nil
		props['master.dir']=nil
		props['command.checked.18.$(file.patterns.latex)']=props['master.set']
		props['command.19.$(file.patterns.latex)']='print Currently there is no master file. Needs to set a master file first.'
		props['command.mode.19.$(file.patterns.latex)']='subsystem:lua,savebefore:yes'
		output:append('Master file unset successfully.\n')
	end
end

--[[
function compilemaster()
	if tonumber(props['master.set'])==1 then
		output:append('Compiling master file '..props['master.name']..'...please wait\n')
		cmd1=cd_cmd..props['master.dir']
		cmd2=compiler..props['master.name']
		cmd=cmd1..' && '..cmd2
--		scite_execute(cmd)
		os.execute(cmd)
--   		p = spawner.new(cmd)
--   		p:use_shell() 
--			p:set_output 'trace' 
--   		p:run()
		output:append('Compilation finished sucessfully.')
	else
		output:append('Currently there is no master file. Needs to set a master file first.')
	end
end
]]--

