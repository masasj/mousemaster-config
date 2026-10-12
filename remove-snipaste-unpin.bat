@echo off
rem Removes the Startup entry for snipaste-unpin.ahk.
rem The running script keeps going until you exit it from its tray icon
rem (right-click the green H icon, Exit) or sign out.
setlocal
set "LNK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\snipaste-unpin.lnk"
if exist "%LNK%" (
    del "%LNK%"
    echo Removed: %LNK%
) else (
    echo No startup entry found. Nothing to do.
)
pause
