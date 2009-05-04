rem copy ..\"LaTeX IDE"\buttons.bmp .\scite\win32
cd .\scite\win32
rem del *.o
del Sc1Res.o
make
cd ..\..\..\"LaTeX IDE"
copy ..\SciTE-Ru\scite\bin\sc1.exe .\SciTE.exe
