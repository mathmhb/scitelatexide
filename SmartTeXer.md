# Introduction #

SmartTeXer.pl included in this project is a perl script for automatic typesetting of .tex files. It is designed for TeX users who do not know or do not wish to know about the typesetting engines. TeX engine and typesetting route are automatically selected by the program, users only need to specify the output format, which must be one of DVI, PDF or HTML.

Typical use cases of the script:

SmartTeXer.pl -pdf -view foo.tex

SmartTeXer.pl -pdf -synctex -view -source=foo.tex