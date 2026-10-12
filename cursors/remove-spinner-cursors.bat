@echo off
rem Restores the pointer settings saved by install-spinner-cursors.bat.
setlocal
set "HERE=%~dp0"
if not exist "%HERE%backup-cursors.reg" (
    echo No backup-cursors.reg found. Restoring Windows defaults instead.
    reg delete "HKCU\Control Panel\Cursors" /v Wait /f >nul 2>&1
    reg delete "HKCU\Control Panel\Cursors" /v AppStarting /f >nul 2>&1
) else (
    reg import "%HERE%backup-cursors.reg" >nul 2>&1
    echo Restored pointer settings from backup-cursors.reg
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0apply-cursors.ps1"
echo Done.
pause
