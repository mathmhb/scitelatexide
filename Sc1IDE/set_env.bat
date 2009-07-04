rem Set your own environment vars and searching PATH in this file
set SC1=%~dp0
set MTEX=d:\MTeX
set MIKTEXBIN="D:\miktex\miktex\bin"
set MYUTILS=%MTEX%\utils\gsview;%MTEX%\utils\gsview;%MTEX%\utils\sumatrapdf;%MTEX%\utils\gnuplot;%MTEX%\utils\tpx;%MTEX%\utils\asy;
REM set TEXINPUTS=%MTEX%\texinput//;%MTEX%\texlocal//
PATH %MIKTEXBIN%;%MYUTILS%;"%SC1%";%PATH%
