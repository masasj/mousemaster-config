@echo off
rem ---------------------------------------------------------------------------
rem  Start mousemaster elevated right now, with no UAC prompt.
rem
rem  It asks the scheduled task to run, and the task carries the elevated token,
rem  so no consent dialog appears. Requires setup-admin-autostart.bat to have
rem  been run once.
rem
rem  Nothing happens if mousemaster is already running: mousemaster-start.bat
rem  refuses to start a second instance (two of them fight over the hooks).
rem  Quit the running one first if you meant to restart it.
rem
rem  Silent on success - this is also what the "mousemaster (admin)" Start menu
rem  shortcut runs, and a leftover console window on every launch is noise.
rem ---------------------------------------------------------------------------
schtasks /Run /TN "mousemaster-admin" >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: could not start the task "mousemaster-admin".
    echo Has setup-admin-autostart.bat been run?
    echo.
    pause
)
