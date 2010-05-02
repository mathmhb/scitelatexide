@echo off
set W=%3
if #%3==# set W=512
set H=%4
if #%4==# set H=768
if "%@eval[1+1]"=="2"  set W=%@eval[%_xpixels/2]
if "%@eval[1+1]"=="2"  set H=%_ypixels/2
set F=%1
set C=%2
if #%2==# set C=ititle
REM for %%E in (rtf htm html ps dvi pdf %2) if exist "%1.%E%" set F="%1.%E%"
echo Window: %F%      Width=%W%   Height=%H%
nircmdc.exe win setsize class "SciTEWindow" 0 0 %W% %H%
nircmdc.exe win setsize %C% %F% %W% 0 %W% %H%
