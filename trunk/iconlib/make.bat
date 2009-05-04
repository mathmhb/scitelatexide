@ECHO OFF

::-----------------------------------------
:: ���� � MinGW
SET MINGW=C:\MinGW\bin
:: ���� � upx (���� ����������� �� ������)
SET UPX3=C:\MinGW\upx303w
::-----------------------------------------

ECHO Start building toolbar.dll ...
ECHO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

CD /D "%~dp0"

IF NOT EXIST "%MINGW%" IF NOT EXIST "C:\Program Files\CodeBlocks\bin" (
	ECHO Please install MinGW + UPX!
	ECHO For more information visit: http://code.google.com/p/scite-ru/
	GOTO error
)

SET PATH=%MINGW%;C:\Program Files\CodeBlocks\bin;%PATH%

windres -o resfile.o toolbar.rc
IF ERRORLEVEL 1 GOTO error
gcc -s -shared -nostdlib -o toolbar.dll resfile.o
IF ERRORLEVEL 1 GOTO error

IF EXIST "%UPX3%\upx.exe" (
rem "%UPX3%\upx.exe" --best toolbar.dll
) ELSE (
	ECHO  Warning: UPX not found! File toolbar.dll not packed.
)

DEL resfile.o

ECHO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ECHO Building toolbar.dll successfully completed!
GOTO :EOF

:error
ECHO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ECHO Compile errors were found!
