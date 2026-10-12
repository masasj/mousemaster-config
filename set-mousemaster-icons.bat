@echo off
rem ---------------------------------------------------------------------------
rem  Re-apply the icon pair to the Start menu entries:
rem    mousemaster.lnk or mousemaster (admin).lnk : mm4-start.ico  (white mouse on purple tile, green wheel)
rem    mousemaster stop.lnk                       : mm4-stop.ico   (white mouse on red tile, wheel off)
rem  Use after re-creating either shortcut, or on another PC. No admin rights.
rem  Needs the two .ico files next to this script.
rem ---------------------------------------------------------------------------
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0set-mousemaster-icons.ps1"
echo.
pause
