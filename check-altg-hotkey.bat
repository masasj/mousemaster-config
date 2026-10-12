@echo off
chcp 437 >nul
title alt+g global hotkey check
rem Finds out whether some other program holds alt+g as a global hotkey
rem (mousemaster is not involved: alt+g fails even with it stopped).
rem Nothing is changed on the PC. Result is also saved to altg-check.txt.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0check-altg-hotkey.ps1"
echo.
echo Result saved to altg-check.txt next to this file.
pause
