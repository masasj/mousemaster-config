@echo off
rem Removes the Startup entry of mm-companion.ahk and asks the running copy to exit.
rem To go back to the four separate scripts, run their install-*.bat files afterwards.
setlocal
set "LNK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\mm-companion.lnk"
if exist "%LNK%" (
    del "%LNK%"
    echo Removed: %LNK%
) else (
    echo No startup entry found.
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*mm-companion.ahk*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force; 'stopped pid ' + $_.ProcessId }"
pause
