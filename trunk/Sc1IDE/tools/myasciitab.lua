-- ASCII Table for SciTE; khman 20050812; public domain 
-- modified by mathmhb: ASCIITable() -- use new buffer; ASCIITable(true) --use output pane
function ASCIITable(use_output) 
  local Ctrl = false -- set to true if ASCII<32 appear as valid chars
  local f
  if use_output then 
	f=function(s) trace(s);end;
	output:ClearAll();
  else 
    f=function(s) editor:AddText(s);end;
    scite.Open('');
  end

  local hl = "    +----------------+\n"
  f("ASCII Table:\n"..hl.."    |0123456789ABCDEF|\n"..hl)
  local start = Ctrl and 0 or 32
  for x = start, 240, 16 do
    f(string.format(" %02X |", x))
    for y = x, x+15 do f(string.char(y)) end
    f("|\n")
  end
  f(hl)
  if not Ctrl then
    f(
      "\nControl Characters:\n"..
      " 00: NUL SOH STX ETX\n 04: EOT ENQ ACK BEL\n"..
      " 08: BS  HT  LF  VT\n 0C: FF  CR  SO  SI\n"..
      " 10: DLE DC1 DC2 DC3\n 14: DC4 NAK SYN ETB\n"..
      " 18: CAN EM  SUB ESC\n 1C: FS  GS  RS  US\n"
    )
  end
  scite.MenuCommand(450)
end
  
--Ben Fisher, 2006, Public domain
--modified by mathmhb: compact display
function ascii_table()
	local padnum = function (nIn)
		if nIn < 10 then return "00"..nIn
		elseif nIn < 100 then return "0"..nIn
		else return nIn
		end
	end
	local overrides = { [0]="(Null)", [9]="(Tab)",[10]="(\\n Newline)", [13]="(\\r Return)", [32]="(Space)"}
	local c
	for n=0,127 do
		if overrides[n] then c = overrides[n] else c = string.char(n) end
		--print (padnum(n).."  "..c)
		trace (padnum(n).."  "..c)
		if n<32 then trace('  '); else trace('\t'); end
		if n%3==1 then trace('\n');end
	end
end
