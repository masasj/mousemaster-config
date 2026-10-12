@echo off
rem ---------------------------------------------------------------------------
rem  Report the actual state of the elevated-autostart setup, so we stop
rem  guessing: the scheduled task, both shortcuts, and the running process.
rem  No admin rights needed; nothing is modified.
rem ---------------------------------------------------------------------------
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0check-admin-setup.ps1"
echo.
pause
