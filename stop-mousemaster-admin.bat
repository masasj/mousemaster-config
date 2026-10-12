@echo off
rem ---------------------------------------------------------------------------
rem  Stop mousemaster right now, with no UAC prompt.
rem
rem  Asks the "mousemaster-stop" scheduled task to run; the task carries the
rem  elevated token, so no consent dialog appears. Requires setup-stop-task.bat
rem  to have been run once. This is what the "mousemaster stop" Start menu
rem  entry runs (alt+e in PowerToys Run, type stop, Enter).
rem
rem  Silent on success, like start-mousemaster-admin.bat. What happens is
rem  logged to mm-stop.log by the worker (stop-mousemaster-task.ps1).
rem ---------------------------------------------------------------------------
schtasks /Run /TN "mousemaster-stop" >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: could not start the task "mousemaster-stop".
    echo Has setup-stop-task.bat been run?
    echo.
    pause
)
