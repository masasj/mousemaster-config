@echo off
rem Starts Snipaste (the portable copy in Snipaste-2.11.3-x64 next to this bat) at sign-in,
rem by putting a shortcut into the Startup folder, and starts it now if it is not running.
rem Not elevated on purpose: snipaste-unpin.ahk posts messages to its windows, and an
rem elevated Snipaste would not accept them (UIPI). Run remove-snipaste-startup.bat to undo.
rem Snipaste's own "run on system startup" checkbox does the same through the registry;
rem either one is enough, both at once is harmless (Snipaste runs a single instance).
setlocal
set "EXE=%~dp0Snipaste-2.11.3-x64\Snipaste.exe"
set "LNK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Snipaste.lnk"
if not exist "%EXE%" (
    echo Snipaste.exe was not found at:
    echo   %EXE%
    pause
    exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%LNK%'); $s.TargetPath='%EXE%'; $s.WorkingDirectory='%~dp0Snipaste-2.11.3-x64'; $s.Save()"
if exist "%LNK%" (
    echo Startup shortcut created:
    echo   %LNK%
) else (
    echo Failed to create the startup shortcut.
    pause
    exit /b 1
)
tasklist /FI "IMAGENAME eq Snipaste.exe" 2>nul | find /I "Snipaste.exe" >nul
if errorlevel 1 (
    start "" "%EXE%"
    echo Snipaste started.
) else (
    echo Snipaste is already running.
)
pause
