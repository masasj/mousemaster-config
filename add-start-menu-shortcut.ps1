# Creates a Start-menu shortcut that launches mousemaster through its elevated
# scheduled task (no UAC prompt), so name-based launchers can find it again.
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$target = Join-Path $here 'start-mousemaster-admin.bat'
if (-not (Test-Path $target)) { throw "Not found: $target" }

$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$lnk = Join-Path $startMenu 'mousemaster (admin).lnk'

$shell = New-Object -ComObject WScript.Shell
$s = $shell.CreateShortcut($lnk)
$s.TargetPath = $target
$s.WorkingDirectory = $here
$s.Description = 'Start mousemaster elevated (via the mousemaster-admin scheduled task, no UAC prompt)'
$s.WindowStyle = 7   # minimised: the batch is silent on success
# The exe carries no icon resource of its own, so borrow the mouse control panel's.
$s.IconLocation = "$env:SystemRoot\System32\main.cpl,0"
$s.Save()

Write-Host ''
Write-Host "Created: $lnk"
Write-Host "  target: $target"
Write-Host ''
Write-Host 'PowerToys Run may take a moment to re-index. Type "mousemaster" or "mou".'
Write-Host 'Launching it starts mousemaster elevated with no UAC prompt.'
Write-Host ''
Write-Host 'Note: if mousemaster is already running, nothing happens by design -'
Write-Host 'a second instance would fight the first one over the keyboard hooks.'
