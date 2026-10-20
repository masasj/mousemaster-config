@echo off
rem Puts glance.ahk into the Startup folder (runs at sign-in) and starts it now.
rem Run remove-glance.bat to undo. Needs AutoHotkey v2 (the .ahk association does the rest).
rem w in mousemaster's normal-mode shows / hides Google Calendar as an app window next
rem to the mouse (mousemaster.properties [34] sends F16; this script catches it).
setlocal
set "SCRIPT=%~dp0glance.ahk"
set "LNK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\glance.lnk"
if not exist "%SCRIPT%" (
    echo glance.ahk was not found next to this bat.
    pause
    exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%LNK%'); $s.TargetPath='%SCRIPT%'; $s.WorkingDirectory='%~dp0'; $s.Save()"
if exist "%LNK%" (
    echo Startup shortcut created:
    echo   %LNK%
) else (
    echo Failed to create the startup shortcut.
    pause
    exit /b 1
)
start "" "%SCRIPT%"
echo Script started. A green H icon should now sit in the tray.
echo Test: press w in normal-mode. Google Calendar opens next to the mouse; w again hides it.
echo Log: glance.log next to this bat.
pause
