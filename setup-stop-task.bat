@echo off
rem ---------------------------------------------------------------------------
rem  One-time setup: register the "mousemaster-stop" scheduled task and put a
rem  "mousemaster stop" entry in the Start menu.
rem
rem  Why a task: mousemaster runs elevated (mousemaster-admin), and only an
rem  elevated taskkill can end it. A task with "run with highest privileges"
rem  carries that token, so "mousemaster stop" works without a UAC prompt.
rem
rem  How to use it afterwards: alt+e (PowerToys Run), type stop, Enter.
rem  Start again with "mou", Enter, as before.
rem
rem  This script needs admin rights once; it re-launches itself elevated.
rem  Undo with remove-stop-task.bat.
rem ---------------------------------------------------------------------------
cd /d "%~dp0"

net session >nul 2>&1
if errorlevel 1 (
    echo Requesting administrator rights...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-stop-task.ps1"
echo.
pause
