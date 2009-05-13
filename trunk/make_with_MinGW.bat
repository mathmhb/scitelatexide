@ECHO OFF
SET PATH=C:\MinGW\bin;%PATH%;

CD scintilla\win32
make
CD ..\..
CD scite\win32
make
copy ..\bin\SciTE.exe ..\..\Release
cd ..\..\iconlib
make.bat
copy toolbar.dll ..\Release