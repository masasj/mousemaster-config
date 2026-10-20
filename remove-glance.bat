@echo off
rem Removes the Startup shortcut created by install-glance.bat and stops the script.
setlocal
set "LNK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\glance.lnk"
if exist "%LNK%" (
    del "%LNK%"
    echo Startup shortcut removed.
) else (
    echo No startup shortcut found.
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*glance.ahk*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }"
echo Script stopped (if it was running). glance-events.txt is kept.
pause
