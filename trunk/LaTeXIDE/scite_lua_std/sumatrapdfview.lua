require 'luadde'

DdeService,DdeTopic,ServiceApp = 'SUMATRA','control','SUMATRA'

function sumatrapdfview(fn)
	local dir,name,line,scitehome = props['FileDir'], props['FileName'], props['SelectionStartLine'],props['SciteDefaultHome']
	local pdfname = dir..'\\'..name..'.pdf'
	local srcname = dir..'\\'..name..'.tex'
	cmd ='start "" \"'..scitehome..'\\SumatraPDF.exe\" -reuse-instance  -inverse-search \"SciTE.exe -open \\\"\%f\\\" -goto:\%l\"'
	os.execute(cmd)
                win.sleep(1000)
		local d = luadde.create()
		d:open(DdeService, DdeTopic, ServiceApp)
		d:execute('[ForwardSearch("'..pdfname..'","'..srcname..'",'..line..',0,0,1)]')
		d:close()

end
