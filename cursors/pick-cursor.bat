@echo off
rem Switches the Windows Busy / Working-in-background pointers between the
rem spinners in this folder. backup-cursors.reg (the ORIGINAL Windows settings,
rem saved 2026-09-08) is never touched, so 0 always gets you back.
rem
rem Two slots get set, and they are NOT the same picture:
rem   Wait        - the app is frozen, you cannot click. Ring only, no arrow.
rem   AppStarting - still working, but you CAN click. Arrow + small ring,
rem                 so you can still see what you are pointing at.
setlocal
set "HERE=%~dp0"
echo.
echo   Which spinner?
echo.
echo     1   red arc        (the original, 2026-09-08)
echo     2   arc bloom      teal
echo     3   arc bloom      red
echo     4   gyro           teal
echo     5   gyro           red
echo     6   hand seals     teal   (12 seals, 2.6 s - for fun)
echo     0   Windows default
echo.
set "N="
set /p "N=Pick a number: "
set "ANI="
set "APPS="
if "%N%"=="1" set "ANI=%HERE%spinner-busy-32.ani"          & set "APPS=%HERE%spinner-appstarting-32.ani"
if "%N%"=="2" set "ANI=%HERE%spinner-arcbloom-32.ani"      & set "APPS=%HERE%spinner-arcbloom-app-32.ani"
if "%N%"=="3" set "ANI=%HERE%spinner-arcbloom-red-32.ani"  & set "APPS=%HERE%spinner-arcbloom-red-app-32.ani"
if "%N%"=="4" set "ANI=%HERE%spinner-gyro-32.ani"          & set "APPS=%HERE%spinner-gyro-app-32.ani"
if "%N%"=="5" set "ANI=%HERE%spinner-gyro-red-32.ani"      & set "APPS=%HERE%spinner-gyro-red-app-32.ani"
if "%N%"=="6" set "ANI=%HERE%spinner-seal-zoom-32.ani"     & set "APPS=%HERE%spinner-seal-app-32.ani"
if "%N%"=="0" (
    call "%HERE%remove-spinner-cursors.bat"
    exit /b 0
)
if not defined ANI (echo Nothing picked. & pause & exit /b 1)
if not exist "%ANI%" (echo ERROR: %ANI% not found. & pause & exit /b 1)
if not defined APPS set "APPS=%ANI%"
if not exist "%APPS%" (echo ERROR: %APPS% not found. & pause & exit /b 1)
if not exist "%HERE%backup-cursors.reg" (
    reg export "HKCU\Control Panel\Cursors" "%HERE%backup-cursors.reg" /y >nul
)
reg add "HKCU\Control Panel\Cursors" /v Wait /t REG_EXPAND_SZ /d "%ANI%" /f >nul
reg add "HKCU\Control Panel\Cursors" /v AppStarting /t REG_EXPAND_SZ /d "%APPS%" /f >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%HERE%apply-cursors.ps1"
echo.
echo   Wait        : %ANI%
echo   AppStarting : %APPS%
echo.
echo   Look at it: show-busy-cursor2.bat  (two rows, five backgrounds each)
echo.
pause
