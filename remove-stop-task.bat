@echo off
rem ---------------------------------------------------------------------------
rem  Undo setup-stop-task.bat: delete the "mousemaster-stop" task and the
rem  "mousemaster stop" Start menu entry. Needs admin once (task deletion).
rem ---------------------------------------------------------------------------
cd /d "%~dp0"

net session >nul 2>&1
if errorlevel 1 (
    echo Requesting administrator rights...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

schtasks /Delete /TN "mousemaster-stop" /F
powershell -NoProfile -Command "$p = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\mousemaster stop.lnk'; if (Test-Path $p) { Remove-Item -LiteralPath $p -Force; Write-Host 'Start menu entry removed.' } else { Write-Host 'Start menu entry was not there.' }"
echo.
pause
