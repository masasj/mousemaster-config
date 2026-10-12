@echo off
rem ---------------------------------------------------------------------------
rem  Put a "mousemaster (admin)" entry in the Start menu, so PowerToys Run
rem  (and the Start menu itself) can launch mousemaster elevated by name.
rem
rem  Why this is needed: setup-admin-autostart.bat disabled the Startup-folder
rem  shortcut, and that shortcut was what PowerToys Run used to find when you
rem  typed "mou". This puts a searchable entry back - one that starts the
rem  elevated scheduled task, so there is no UAC prompt.
rem
rem  No admin rights needed: it only writes into your own Start menu folder.
rem ---------------------------------------------------------------------------
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0add-start-menu-shortcut.ps1"
echo.
pause
