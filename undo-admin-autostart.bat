@echo off
rem ---------------------------------------------------------------------------
rem  Undo setup-admin-autostart.bat: remove the elevated task, remove the Start
rem  menu entry, and put the ordinary Startup shortcut back. mousemaster then
rem  starts non-elevated again, as it did before.
rem ---------------------------------------------------------------------------
cd /d "%~dp0"

net session >nul 2>&1
if errorlevel 1 (
    echo Requesting administrator rights...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo Removing the scheduled task...
schtasks /Delete /TN "mousemaster-admin" /F

echo Removing the Start menu entry...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\mousemaster (admin).lnk'; if (Test-Path $p) { Remove-Item $p -Force; Write-Host '  removed' } else { Write-Host '  not present' }"

echo Re-enabling mousemaster-fast-autostart and restoring the resume task...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$u=\"$env:USERDOMAIN\$env:USERNAME\"; if (Get-ScheduledTask -TaskName 'mousemaster-fast-autostart' -ErrorAction SilentlyContinue) { Enable-ScheduledTask -TaskName 'mousemaster-fast-autostart' | Out-Null; Write-Host '  fast-autostart re-enabled' }; if (Get-ScheduledTask -TaskName 'mousemaster-resume-start' -ErrorAction SilentlyContinue) { $pr=New-ScheduledTaskPrincipal -UserId $u -LogonType Interactive -RunLevel Limited; Set-ScheduledTask -TaskName 'mousemaster-resume-start' -Principal $pr | Out-Null; Write-Host '  resume-start back to Limited' }"

echo Restoring the Start menu shortcut from backup...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\mousemaster.lnk'; if (Test-Path ($p + '.bak')) { Copy-Item ($p + '.bak') $p -Force; Write-Host '  mousemaster.lnk restored from .bak' } else { Write-Host '  no .bak found' }"

echo Restoring the Startup shortcut...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup\mousemaster-prewarm.lnk'; if (Test-Path ($p + '.disabled')) { if (Test-Path $p) { Remove-Item $p -Force }; Rename-Item -Path ($p + '.disabled') -NewName (Split-Path $p -Leaf); Write-Host '  restored' } else { Write-Host '  no .disabled shortcut found - nothing to restore' }"

echo.
echo Done. The next logon starts mousemaster without admin rights again.
echo.
pause
