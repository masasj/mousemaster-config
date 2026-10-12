@echo off
cd /d "%~dp0"
set "LNK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\mousemaster-prewarm.lnk"

echo ============================================================
echo   Repoint the startup shortcut at THIS folder
echo ============================================================
echo.
echo   RUN THIS WHENEVER YOU RENAME THE MOUSEMASTER FOLDER.
echo   The Startup shortcut stores an absolute path, so a rename
echo   silently breaks autostart with no error message.
echo.
echo   Only this one shortcut is modified:
echo      mousemaster-prewarm.lnk
echo   New target:
echo      %~dp0mousemaster-autostart.bat
echo   Nothing else is touched, nothing is deleted.
echo.
echo   Press Ctrl+C to cancel, or
pause
echo.
powershell -NoProfile -Command "$w=New-Object -ComObject WScript.Shell; $p=\"$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\mousemaster-prewarm.lnk\"; $s=$w.CreateShortcut($p); $s.TargetPath='%~dp0mousemaster-autostart.bat'; $s.WorkingDirectory='%~dp0'; $s.WindowStyle=7; $s.Save(); $t=$w.CreateShortcut($p).TargetPath; Write-Host ('     target now: ' + $t); if (Test-Path $t) { Write-Host '     target exists: OK' } else { Write-Host '     WARNING: target does not exist' }"
echo.
echo   Done. Autostart now points at this folder.
echo.
pause
