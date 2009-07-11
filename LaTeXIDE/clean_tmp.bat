@echo off
for %%a in (aux log tmp bbl toc idx out ind tui tuo top tmp thm ilg blg vpe xref htm? dvi dlg lot lof snm nav bak fls tab cut cpy 4ct 4tc idv lg ent 4od) do if exist %1.%%a del %1.%%a
if exist %1-mpgraph.* del %1-mpgraph.*
if exist %1.synctex* del %1.synctex*
if exist %1.tex.new del %1.tex.new