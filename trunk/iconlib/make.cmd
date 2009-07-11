@echo off
REM copyright [mhb] 15/06/2009: generate toolbar.dll from named icons in [ico] (excluding ICON_*.ico)
REM You just need to put named icon files in [ico]. Remember to make all file names uppercase.
cd /d "%~dp0ico"
set N=0
echo Deleting toolbar.constant and toolbar.rc ...
del toolbar.constant
del toolbar.rc
copy VersionInfo.rc toolbar.rc

echo Regenerating toolbar.constant and toolbar.rc from *.ico automatically ...
for %%A in (*.ico) do call proc_ico.cmd %%A%%

echo Bulding toolbar.dll from toolbar.rc ...
path c:\mingw\bin;d:\mingw\bin;c:\msys\bin;d:\msys\bin;%PATH%
windres -o resfile.o toolbar.rc
gcc -s -shared -nostdlib -o toolbar.dll resfile.o

echo Copying toolbar.constant and toolbar.dll to Release and Sc1IDE folders ...
copy toolbar.constant ..\..\LaTeXIDE
copy toolbar.dll ..\..\LaTeXIDE
copy toolbar.constant ..\..\Sc1IDE\lib
copy toolbar.dll ..\..\Sc1IDE\lib

cd ..
pause