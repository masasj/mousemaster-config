@echo off
rem ---------------------------------------------------------------------------
rem  Autostart wrapper. The Startup shortcut points HERE, not at the exe, so
rem  a delay can be reintroduced without touching the Startup folder (that
rem  folder cannot be edited from Cowork).
rem
rem  No wait: the old batch waited 4s for the desktop to come up. That felt
rem  slow, was shortened to 2s, then removed entirely on 2026-08-02 with no
rem  ill effects. If starting too early ever causes trouble, put it back:
rem      timeout /t 2 /nobreak ^>nul
rem ---------------------------------------------------------------------------
echo %DATE% %TIME% task-fired >> "%~dp0autostart-timing.log"
call "%~dp0mousemaster-start.bat"
echo %DATE% %TIME% start-bat-returned >> "%~dp0autostart-timing.log"
