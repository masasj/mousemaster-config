@echo off
rem Puts mm-companion.ahk into the Startup folder (runs at sign-in) and starts it now,
rem in place of the four separate scripts: their Startup entries are removed here and
rem the running copies are asked to exit by mm-companion itself when it starts.
rem Run remove-mm-companion.bat to undo. Needs AutoHotkey v2.
setlocal
set "SCRIPT=%~dp0mm-companion.ahk"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "LNK=%STARTUP%\mm-companion.lnk"
if not exist "%SCRIPT%" (
    echo mm-companion.ahk was not found next to this bat.
    pause
    exit /b 1
)
for %%n in (claude-to-front snipaste-unpin glance ibeam-watch) do (
    if exist "%STARTUP%\%%n.lnk" (
        del "%STARTUP%\%%n.lnk"
        echo Removed the old startup entry: %%n.lnk
    )
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
echo Script started. One green H icon should sit in the tray (the old four exit by themselves).
echo Check: Alt+Z closes a pin, w shows the calendar, a text selection shows no crane,
echo        a file drag does, a click on a Claude toast brings Claude to the front.
echo Log: mm-companion.log next to this bat.
pause
