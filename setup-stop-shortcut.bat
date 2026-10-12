@echo off
rem ---------------------------------------------------------------------------
rem  Branch B (no admin rights): put a "mousemaster stop" entry in the Start
rem  menu that kills the NON-elevated mousemaster directly. No scheduled task,
rem  no UAC, no admin rights. Also adds a "mousemaster" start entry if there is
rem  none yet, so  mou  works in PowerToys Run as well.
rem
rem  If mousemaster runs elevated on this PC (mousemaster-admin task), use
rem  setup-stop-task.bat instead: a non-elevated stop cannot end it.
rem
rem  How to use it afterwards: alt+e (PowerToys Run), type stop, Enter.
rem  Without PowerToys: Windows key, type "mousemaster stop", Enter.
rem  Undo: delete "mousemaster stop.lnk" from the Start menu Programs folder.
rem ---------------------------------------------------------------------------
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-stop-task.ps1" -ShortcutOnly
echo.
pause
