@echo off
rem ---------------------------------------------------------------------------
rem  Switch mousemaster's autostart to an ELEVATED scheduled task.
rem
rem  Why: only an elevated mousemaster can duplicate winlogon's token and get
rem  UIAccess, which is what lets hints draw over the taskbar, the notification
rem  flyout and elevated windows (GitHub issue #98, README step 5).
rem
rem  A Startup-folder shortcut cannot start a program elevated. A scheduled
rem  task with "run with highest privileges" can, and does it without a UAC
rem  prompt, so autostart stays silent.
rem
rem  This script needs admin rights itself; it re-launches itself elevated if
rem  you just double-click it (one UAC prompt, only during setup).
rem
rem  Undo with undo-admin-autostart.bat. Nothing is deleted: the Startup
rem  shortcut is renamed to .lnk.disabled and can be restored.
rem ---------------------------------------------------------------------------
cd /d "%~dp0"

net session >nul 2>&1
if errorlevel 1 (
    echo Requesting administrator rights...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-admin-autostart.ps1"
echo.
pause
