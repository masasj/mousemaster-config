@echo off
rem ---------------------------------------------------------------------------
rem  Stop a NON-elevated mousemaster right now. No admin rights, no UAC.
rem
rem  For a PC where mousemaster runs without elevation (branch B of the
rem  setup guide: Startup shortcut autostart). Where mousemaster runs
rem  elevated (mousemaster-admin task) this cannot end it - use
rem  stop-mousemaster-admin.bat there (needs setup-stop-task.bat once).
rem
rem  Runs the same worker as the stop task, hidden: force-kill, then reload
rem  the system cursors. Logged to mm-stop.log. This is what the Start menu
rem  entry "mousemaster stop" runs after setup-stop-shortcut.bat.
rem ---------------------------------------------------------------------------
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0stop-mousemaster-task.ps1"
