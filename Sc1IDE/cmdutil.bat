@echo off
call %~dp0set_env.bat
echo Running: %*
%*
nircmdc.exe wait 1500
