@echo off
rem Puts snipaste-unpin.ahk into the Startup folder (runs at sign-in)
rem and starts it now. Run remove-snipaste-unpin.bat to undo.
rem Needs AutoHotkey v2 (the .ahk file association does the rest).
rem Alt+Z in mousemaster's normal-mode closes the oldest Snipaste pin
rem (mousemaster.properties [31b] sends F14; this script catches it).
setlocal
set "SCRIPT=%~dp0snipaste-unpin.ahk"
set "LNK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\snipaste-unpin.lnk"
if not exist "%SCRIPT%" (
    echo snipaste-unpin.ahk was not found next to this bat.
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
echo Test: pin two things with z, then press Alt+Z twice in normal-mode.
echo Log: snipaste-unpin.log next to this bat.
pause
