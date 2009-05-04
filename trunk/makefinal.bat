cd .\scintilla\win32
del *.o
make
cd ..\..\scite\win32
del *.o
make
copy ..\bin\sc1.exe ..\src\SciTE.exe
