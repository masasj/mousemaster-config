@echo off
rem Removes the Startup shortcut for Snipaste. The running Snipaste keeps going
rem until you exit it from its tray icon.
setlocal
set "LNK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Snipaste.lnk"
if exist "%LNK%" (
    del "%LNK%"
    echo Removed: %LNK%
) else (
    echo No startup entry found. Nothing to do.
)
pause
