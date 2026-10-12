@echo off
rem ---------------------------------------------------------------------------
rem  Launch mousemaster.
rem
rem  --pre-warm-hints=true is kept for safety but is a NO-OP since v91: the
rem  author made pre-warming the default. On v91 with no flag at all, 23 taps
rem  of f gave +f 23 / -f 23 / mode switch 23, and the first mesh build was
rem  1-2ms instead of ~620ms. See GitHub issue #74 (fixed).
rem
rem  Quit any running mousemaster before running this.
rem  taskkill /F used to leave the hooks installed (issue #75). v92 exits
rem  cleanly, but quitting it normally is still the right habit.
rem
rem  NOTE: batch files here must be ASCII with CRLF line endings. An echo line
rem        must never contain a bare ^> and neither must a rem line - cmd still
rem        performs the redirection and truncates that file.
rem ---------------------------------------------------------------------------
cd /d "%~dp0"
rem 2026-08-23: idempotent guard - never start a second instance
rem (hibernate-resume fires the ONLOGON task while the old instance is alive,
rem  and two instances fight over the hooks and both go insane)
tasklist /FI "IMAGENAME eq mousemaster.exe" | find /I "mousemaster.exe" >nul
if not errorlevel 1 (
    echo mousemaster is already running - nothing to do.
    exit /b
)
rem 2026-09-02: /MIN so the console cannot be clicked into selection mode during
rem the ~1s between process start and the config load that hides it
rem (hide-console=true in mousemaster.properties). A minimised window takes no
rem mouse clicks, and it stays reachable from the taskbar if the config fails.
start "" /MIN "%~dp0mousemaster.exe" --pre-warm-hints=true
