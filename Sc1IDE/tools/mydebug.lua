scite_require('_debug/class.lua')
scite_require('_debug/extlib.lua')
scite_require('_debug/debugger.lua')
--~ if dbg then
	scite_require('_debug/gdb.lua')
	scite_require('_debug/clidebugger.lua')
 	scite_require('_debug/jdb.lua')
	scite_require('_debug/mdb.lua')
	scite_require('_debug/pydb.lua')
 	scite_require('_debug/luagdb.lua')
 	scite_require('_debug/remdebug.lua')
--~ end
