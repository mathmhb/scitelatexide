@echo off
setlocal
echo Usage: RUN_TEX [-1] [-2] texcmd folder texfilename texfileext 
PATH %~dp0;%PATH%
call set_env.bat
if #%1==#-1   set ONCE=1
if #%1==#-1   shift
if #%1==#-2   set ONCE=2
if #%1==#-2   shift
if #%4==# goto END

echo TeXing command: %1
echo Working folder: %2
echo Tex file: %3.%4
echo PATH: %PATH%
cd /d %2

set F=%3.%4
set N=%3
set SCMD=%1 %%TEX_OPT%% %F%
if #%1==#pdflatex  set SYNC=-synctex=-1
if #%1==#xelatex  set SYNC=-synctex=-1
if #%1==#pdflatex  set OUT=pdf
if #%1==#pdftex  set OUT=pdf
if #%1==#latex  set OUT=dvi
if #%1==#tex  set OUT=dvi

call clean_tmp.bat *
del %N%.pdf
del %N%.dvi

set TEX_OPT=-src %SYNC%
echo Running[1]: %SCMD%
call %SCMD%
if not errorlevel 0 goto Preview
if #%ONCE%==#1 goto Preview

bibtex %N%
REM fixbbl %N%

makeindex %N%
rem cctmkind %N%

set TEX_OPT=%TEX_OPT% -interaction=batchmode
echo Running[2]: %SCMD%
call %SCMD%
if not errorlevel 0 goto Preview
if #%ONCE%==#2 goto Preview

if exist %N%.out  gbk2uni %N%.out
echo Running[3]: %SCMD%
call %SCMD%
if not errorlevel 0 goto Preview

:Preview
preview.bat %N%  %OUT%

:END
pause
