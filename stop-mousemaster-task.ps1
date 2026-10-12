# Worker for the "mousemaster-stop" scheduled task (runs elevated, no window),
# and for stop-mousemaster-direct.bat (runs as the user, for a non-elevated
# mousemaster). Not meant to be run by hand: use stop-mousemaster-admin.bat
# (no UAC prompt), stop-mousemaster-direct.bat (no admin at all) or
# stop-mousemaster.bat (asks for UAC).
$ErrorActionPreference = 'SilentlyContinue'
$log = Join-Path $PSScriptRoot 'mm-stop.log'
function Log($msg) { ("{0:yyyy-MM-dd HH:mm:ss} {1}" -f (Get-Date), $msg) | Add-Content -Path $log }

Log 'stop task fired'
$p = Get-Process mousemaster
if ($p) {
    # Stop-Process -Force is taskkill /F. Without force a console app ignores
    # WM_CLOSE (measured 2026-08-14), and only an elevated caller can do this.
    $ids = ($p | ForEach-Object { $_.Id }) -join ','
    $p | Stop-Process -Force
    Start-Sleep -Milliseconds 300
    if (Get-Process mousemaster) { Log "still running after kill (pid $ids)" } else { Log "killed pid $ids" }
} else {
    Log 'not running - nothing to kill'
}

# A killed mousemaster cannot put the system cursors back (render-as-cursor
# replaced them with SetSystemCursor). SPI_SETCURSORS reloads the user's cursor
# scheme. The next start would repair them as well (issue 83, 2261b7b), but a
# game may be next, so do it now.
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MmCur {
  [DllImport("user32.dll", SetLastError=true)]
  public static extern bool SystemParametersInfo(uint a, uint b, IntPtr c, uint d);
}
"@
$ok = [MmCur]::SystemParametersInfo(0x0057, 0, [IntPtr]::Zero, 0)
Log "SPI_SETCURSORS ok=$ok"
