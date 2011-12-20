@ECHO OFF
PATH c:\mingw\bin;d:\mingw\bin;c:\msys\bin;d:\msys\bin;%~dp0;%PATH%

CD scintilla\win32
del ..\bin\*.dll
REM **please remove arguments to use all lexers; or you can simply specify lexers wanted in scintilla\win32\makefile
REM make LESS_LEXERS=-DLESS_LEXERS
make

CD ..\..
CD scite\win32
make ONEIDE=-DONEIDE

copy ..\bin\SciTE.exe ..\..\LaTeXIDE

del Sc1Res.o
make ONEIDE=-DONEIDE ZERO_EMBED=-DZERO_EMBED

cd ..\..
del Sc1IDE\Sc1.exe
upx -o Sc1IDE\Sc1.exe scite\bin\SciTE.exe

cd iconlib
cmd.exe /c call make.cmd
cd ..

