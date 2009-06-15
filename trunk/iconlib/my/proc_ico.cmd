@echo off
set F=%1
set F=%F:.ico=%
set X=%F:~0,5%
if "%X%"=="ICON_" goto end

echo ICO_%F%=0%N%>> toolbar.constant
set /A N=%N%+1
echo %N%  ICON "%1" >>toolbar.rc

:end
