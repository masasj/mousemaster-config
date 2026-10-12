$ErrorActionPreference = 'SilentlyContinue'
Start-Transcript -Path (Join-Path $PSScriptRoot 'cursor-check.txt') -Force | Out-Null

Write-Host ""
Write-Host "=== 1. Is mousemaster still alive? ==="
$mm = Get-Process mousemaster
if ($mm) {
  foreach ($p in $mm) {
    Write-Host ("  ALIVE   pid={0}  started={1}" -f $p.Id, $p.StartTime)
    Write-Host ("          description={0}" -f $p.Description)
  }
  Write-Host ""
  Write-Host "  -> The process SURVIVED. This is issue #75, still broken for this case."
  Write-Host "     End 'mousemaster.exe' from Task Manager > Details to stop it."
} else {
  Write-Host "  not running"
  Write-Host ""
  Write-Host "  -> The process is gone but the cursor did not come back."
  Write-Host "     That is issue #72: SetSystemCursor was never undone."
}

Write-Host ""
Write-Host "=== 2. Console/terminal processes right now ==="
Get-Process | Where-Object { $_.ProcessName -match 'WindowsTerminal|OpenConsole|conhost|cmd|powershell|pwsh' } |
  ForEach-Object { Write-Host ("  {0,-20} pid={1}" -f $_.ProcessName, $_.Id) }

Write-Host ""
Write-Host "=== 3. Restore the default system cursors ==="
Write-Host "  This reloads the cursor scheme you already have configured in Windows."
Write-Host "  It changes nothing else and needs no reboot."
Write-Host ""
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Cur {
  [DllImport("user32.dll", SetLastError=true)]
  public static extern bool SystemParametersInfo(uint a, uint b, IntPtr c, uint d);
}
"@
$ok = [Cur]::SystemParametersInfo(0x0057, 0, [IntPtr]::Zero, 0)   # SPI_SETCURSORS
if ($ok) { Write-Host "  SPI_SETCURSORS: OK - cursors reloaded." }
else { Write-Host "  SPI_SETCURSORS failed. Signing out and back in also restores them." }

Write-Host ""
Write-Host "  Move the mouse and look at the pointer now."
Write-Host ""
Stop-Transcript | Out-Null
