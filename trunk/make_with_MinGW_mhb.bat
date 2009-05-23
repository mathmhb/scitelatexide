@ECHO OFF
PATH c:\mingw\bin;d:\mingw\bin;c:\msys\bin;d:\msys\bin;%~dp0;%PATH%

CD scintilla\win32
make
CD ..\..
CD scite\win32
make ONEIDE=-DONEIDE
upx -o ..\bin\Sc1.exe ..\bin\SciTE.exe
copy ..\bin\Sc1.exe ..\..\Release
cd ..\..\iconlib
make.bat
copy toolbar.dll ..\Release

