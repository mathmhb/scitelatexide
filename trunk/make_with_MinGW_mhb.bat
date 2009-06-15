@ECHO OFF
PATH c:\mingw\bin;d:\mingw\bin;c:\msys\bin;d:\msys\bin;%~dp0;%PATH%

CD scintilla\win32
make
CD ..\..
CD scite\win32
make ONEIDE=-DONEIDE
copy ..\bin\SciTE.exe ..\..\Release

upx -o ..\Sc1IDE\Sc1.exe ..\bin\SciTE.exe
cd ..\..\iconlib
call mymake.bat
