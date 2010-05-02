set base=%1
if #%1==# set base=*
for %%a in (aux log tmp bbl toc idx out ind tui tuo top tmp thm ilg blg vpe xref htm? dvi dlg lot lof snm nav bak fls tab cut cpy 4ct 4tc idv lg synctex) do del %base%.%%a

del %base%-mpgraph.*
