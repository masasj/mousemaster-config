@echo off
chcp 437 >nul
title mousemaster cursor rescue
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0restore-cursor.ps1"
echo.
pause
