@echo off
rem ---------------------------------------------------------------------------
rem  Publish this folder to GitHub as masasj/mousemaster-config.
rem
rem  First time only: create an EMPTY repository on github.com first
rem      https://github.com/new
rem      Repository name : mousemaster-config
rem      Visibility      : Public (decided 2026-10-12; nothing private goes in here)
rem      Do NOT add a README, .gitignore or license there (this folder has them).
rem  Then run this file. It initialises git here, commits everything and pushes.
rem  Later runs: commits whatever changed and pushes again.
rem
rem  mousemaster.exe is never pushed (.gitignore). Attach it to a Release instead:
rem      https://github.com/masasj/mousemaster-config/releases/new
rem      Tag: exe-96c7f26  (the nightly commit the exe was built from)
rem      Drag mousemaster.exe into the assets box, paste its sha256 from
rem      SHA256SUMS.txt into the description, then "Publish release".
rem ---------------------------------------------------------------------------
setlocal
cd /d "%~dp0"
set REPO=https://github.com/masasj/mousemaster-config.git

where git >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: git was not found on the PATH.
    echo.
    pause
    exit /b 1
)

if not exist ".git" (
    echo.
    echo === First run: creating the local repository ===
    git init
    git symbolic-ref HEAD refs/heads/main
    if errorlevel 1 goto fail
    git remote add origin %REPO%
    if errorlevel 1 goto fail
)

echo.
echo === Committing changes ===
rem .gitattributes says "* -text": re-add everything so files committed earlier with
rem autocrlf conversion (LF .bat files) are stored byte-for-byte (CRLF) from now on.
git add --renormalize .
git add -A
git commit -m "Update %DATE% %TIME:~0,5%"
echo (nothing to commit is fine: it just pushes what is already committed)

echo.
echo === Pushing to %REPO% ===
git push -u origin main
if errorlevel 1 goto fail

echo.
echo Done. Repository: https://github.com/masasj/mousemaster-config
echo Releases (for mousemaster.exe): https://github.com/masasj/mousemaster-config/releases
echo.
pause
exit /b 0

:fail
echo.
echo FAILED. Common causes:
echo   - the repository does not exist yet: create it at https://github.com/new
echo   - not signed in: git opens a browser window for GitHub sign-in on first push
echo   - a push was rejected: run again, or check the output above
echo.
pause
exit /b 1
