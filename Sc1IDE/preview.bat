@echo off
echo Running: %0 %*
echo Current folder: %CD%
setlocal

set E=%2
set FP=%1.%E%
if #%E%==#htm for %%a in (%1.%E%?) do set FP="%%a"
if not exist %FP%  for %%a in (%1-*.%E%) do set FP="%%a"

if not #%2==# goto Next

set E=pdf
set FP=%1.%E%
for %%a in (%1*.%E%) do set FP="%%a"

if not exist %FP%  set E=dvi
if not exist %FP%  for %%a in (%1-*.%E%) do set FP="%%a"

if not exist %FP%  set E=ps
if not exist %FP%  for %%a in (%1-*.%E%) do set FP="%%a"

if not exist %FP%  set E=eps
if not exist %FP%  for %%a in (%1-*.%E%) do set FP="%%a"

if not exist %FP%  set E=mps
if not exist %FP%  for %%a in (%1-*.%E%) do set FP="%%a"

if not exist %FP%  set E=1
if not exist %FP%  for %%a in (%1-*.%E%) do set FP="%%a"

if not exist %FP%  set E=html
if not exist %FP%  for %%a in (%1-*.%E%) do set FP="%%a"

if not exist %FP%  set E=htm
if not exist %FP%  for %%a in (%1-*.%E%) do set FP="%%a"

if not exist %FP%  set E=rtf
if not exist %FP%  for %%a in (%1-*.%E%) do set FP="%%a"


:Next
if exist  %FP%  goto View
echo Error: Cannot find any file to preview!
pause
goto END

:View
echo Viewing file: %FP%
if #%E%==#pdf goto ViewPDF
if #%E%==#dvi goto ViewDVI
if #%E%==#ps goto ViewPS
if #%E%==#eps goto ViewPS
if #%E%==#mps goto ViewPS
if #%E%==#1 goto ViewPS
if #%E%==#html goto ViewHTM
if #%E%==#htm goto ViewHTM
if #%E%==#rtf goto ViewRTF
goto END

:ViewPDF
start SumatraPDF.exe  -reuse-instance -inverse-search "Sc1.exe -open \"%f\" -goto:%l" %FP%
goto END

:ViewDVI
start yap.exe -1 %FP%
goto END

:ViewPS
start gsview32.exe %FP%
goto END

:ViewHTM
:ViewRTF
start "" %FP%
goto END

:END
