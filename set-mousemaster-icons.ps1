# Points the two Start-menu shortcuts at the icon pair next to this script.
# Only the icon changes; target, working directory and window style are kept.
# The start entry is "mousemaster.lnk" on the home PC and "mousemaster (admin).lnk"
# where add-start-menu-shortcut.bat made it: both names are tried.
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$programs = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$shell = New-Object -ComObject WScript.Shell
$pairs = @(
    @{ lnk = 'mousemaster.lnk';         ico = 'mm4-start.ico' },
    @{ lnk = 'mousemaster (admin).lnk'; ico = 'mm4-start.ico' },
    @{ lnk = 'mousemaster stop.lnk';    ico = 'mm4-stop.ico' }
)
$done = 0
foreach ($p in $pairs) {
    $lnkPath = Join-Path $programs $p.lnk
    $icoPath = Join-Path $here $p.ico
    if (-not (Test-Path $lnkPath)) { continue }
    if (-not (Test-Path $icoPath)) { Write-Host ("  missing icon: {0}" -f $icoPath); continue }
    $s = $shell.CreateShortcut($lnkPath)
    $s.IconLocation = "$icoPath,0"
    $s.Save()
    Write-Host ("  {0}  ->  {1}" -f $p.lnk, $p.ico)
    $done++
}
if ($done -eq 0) { Write-Host '  no mousemaster shortcut found in the Start menu Programs folder - nothing changed.' }
Write-Host ''
Write-Host 'Done. If PowerToys Run still shows the old icons, quit PowerToys from the tray and start it again.'
