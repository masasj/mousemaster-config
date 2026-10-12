@echo off
rem ---------------------------------------------------------------------------
rem  Stop the running mousemaster, even when it runs elevated and its console
rem  window is hidden (hide-console=true), so there is no X to click.
rem
rem  An elevated process can only be killed by an elevated taskkill, so this
rem  asks for the UAC consent once. /F is required: without it taskkill only
rem  posts WM_CLOSE, which a console application ignores (measured 2026-08-14).
rem  The next start repairs the system cursor by itself (issue 83, 2261b7b).
rem ---------------------------------------------------------------------------
tasklist /FI "IMAGENAME eq mousemaster.exe" 2>nul | find /I "mousemaster.exe" >nul
if errorlevel 1 (
    echo mousemaster is not running.
    goto :end
)
powershell -NoProfile -Command "Start-Process taskkill -ArgumentList '/F','/IM','mousemaster.exe' -Verb RunAs -Wait"
timeout /t 1 /nobreak >nul
tasklist /FI "IMAGENAME eq mousemaster.exe" 2>nul | find /I "mousemaster.exe" >nul
if errorlevel 1 (
    echo mousemaster stopped.
) else (
    echo mousemaster is still running - was the UAC prompt declined?
)
:end
echo.
pause
