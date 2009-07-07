@echo off
setlocal
set USE_MTEX=1
if #%MTEX%==# set MTEX=d:\MTeX
if not exist "%MTEX%\bin\4nt.exe" set MTEX=%~dp0..\..
start sc1.exe %*
