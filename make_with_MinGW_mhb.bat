@ECHO OFF
PATH c:\mingw\bin;d:\mingw\bin;c:\msys\bin;d:\msys\bin;%~dp0;%PATH%

CD scintilla\win32
make
CD ..\..
CD scite\win32
make ONEIDE=-DONEIDE
copy ..\bin\SciTE.exe ..\..\Release
cd ..\..
del Sc1IDE\Sc1.exe
upx -o Sc1IDE\Sc1.exe scite\bin\SciTE.exe
cd iconlib
cmd.exe /c mymake.cmd
cd ..
