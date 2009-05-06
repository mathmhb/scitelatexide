--[[
  Mitchell's scite.lua
  Copyright (c) 2006-2007 Mitchell Foral. All rights reserved.

  SciTE-tools homepage: http://caladbolg.net/scite.php
  Send email to: mitchell<att>caladbolg<dott>net

  Permission to use, copy, modify, and distribute this file
  is granted, provided credit is given to Mitchell.
]]--

---
-- The scite module.
-- It provides utilities for editing text in SciTE.

PLATFORM ='windows'

module('modules.scite', package.seeall)

require 'scite_lua_std/editing'
require 'scite_lua_std/snippets'
require 'scite_lua_std/functions'
require 'scite_lua_std/mlines'

require 'scite_lua_std/convert_encoding'
require 'scite_lua_std/MarkWord'
require 'scite_lua_std/reformat'

require 'scite_lua_std/abbrev_encdec'
require 'scite_lua_std/tex_lister'
require 'scite_lua_std/compile_block'


require 'gui'
--require 'scite_lua_std/SideBar'
require 'scite_lua_std/GUI-Panel'
require 'scite_lua_std/edit_colour'


require 'scite_lua_std/keys' -- important to load last

-- Opens specified module in SciTE.
-- @param name The name of the module.
function open_module(name)
  scite.Open( props['SciteDefaultHome']'/scite_lua_std/'..name )
end
