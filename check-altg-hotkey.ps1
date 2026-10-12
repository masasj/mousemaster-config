# Who owns alt+g?
# mousemaster was cleared on 2026-10-07: alt+g fails in OneCommander even with
# mousemaster stopped, while alt+f / alt+s work. So either another program holds
# alt+g as a GLOBAL hotkey (it swallows the key before any window sees it), or
# OneCommander itself changed. RegisterHotKey fails with error 1409 when another
# program already owns the combination. Nothing stays registered afterwards.
# Output is also saved to altg-check.txt next to this script.
$ErrorActionPreference = 'Continue'
Start-Transcript -Path (Join-Path $PSScriptRoot 'altg-check.txt') -Force | Out-Null
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MmHotkeyProbe {
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool UnregisterHotKey(IntPtr hWnd, int id);
}
"@
$MOD_ALT = 1; $MOD_CONTROL = 2; $MOD_SHIFT = 4; $MOD_WIN = 8
$script:nextId = 100
function Probe([string]$name, [uint32]$mods, [uint32]$vk) {
    $id = $script:nextId; $script:nextId++
    $ok = [MmHotkeyProbe]::RegisterHotKey([IntPtr]::Zero, $id, $mods, $vk)
    $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    if ($ok) {
        [void][MmHotkeyProbe]::UnregisterHotKey([IntPtr]::Zero, $id)
        Write-Host ("  {0,-12} free    (no program holds it as a global hotkey)" -f $name)
    } elseif ($err -eq 1409) {
        Write-Host ("  {0,-12} TAKEN   (another program registered it as a global hotkey)" -f $name)
    } else {
        Write-Host ("  {0,-12} ?       (RegisterHotKey failed, error {1})" -f $name, $err)
    }
}

Write-Host ''
Write-Host ("=== alt+g check  {0:yyyy-MM-dd HH:mm:ss} ===" -f (Get-Date))
Write-Host ''
Write-Host '=== 0. Self-check (register alt+g twice: the second must fail with 1409) ==='
$a = [MmHotkeyProbe]::RegisterHotKey([IntPtr]::Zero, 1, $MOD_ALT, 0x47)
$b = [MmHotkeyProbe]::RegisterHotKey([IntPtr]::Zero, 2, $MOD_ALT, 0x47)
$e = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
[void][MmHotkeyProbe]::UnregisterHotKey([IntPtr]::Zero, 1)
[void][MmHotkeyProbe]::UnregisterHotKey([IntPtr]::Zero, 2)
if ($a -and -not $b -and $e -eq 1409) { Write-Host '  ok - the probe detects a taken hotkey' }
elseif (-not $a) { Write-Host '  first registration already failed - see section 1' }
else { Write-Host ("  unexpected: first={0} second={1} error={2}" -f $a, $b, $e) }

Write-Host ''
Write-Host '=== 1. Global hotkey probe (RegisterHotKey) ==='
Probe 'alt+g' $MOD_ALT 0x47
Probe 'alt+z' $MOD_ALT 0x5A
Probe 'alt+f' $MOD_ALT 0x46
Probe 'alt+s' $MOD_ALT 0x53
Probe 'alt+c' $MOD_ALT 0x43
Probe 'alt+m' $MOD_ALT 0x4D
Probe 'alt+d' $MOD_ALT 0x44
Probe 'alt+e' $MOD_ALT 0x45
Probe 'ctrl+g' $MOD_CONTROL 0x47
Probe 'win+g' $MOD_WIN 0x47

Write-Host ''
Write-Host '=== 2. OneCommander ==='
$procs = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like '*OneCommander*' }
if ($procs) {
    foreach ($p in $procs) {
        $path = $null; $ver = $null
        try { $path = $p.Path } catch {}
        try { $ver = $p.MainModule.FileVersionInfo.ProductVersion } catch {}
        Write-Host ("  running: {0}  pid {1}  version {2}" -f $p.ProcessName, $p.Id, $ver)
        if ($path) {
            Write-Host ("    exe: {0}" -f $path)
            $fi = Get-Item $path -ErrorAction SilentlyContinue
            if ($fi) { Write-Host ("    exe date: {0:yyyy-MM-dd HH:mm}" -f $fi.LastWriteTime) }
        } else {
            Write-Host '    exe path not readable from here (elevated process?)'
        }
    }
} else { Write-Host '  not running' }
$pkgs = Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '*OneCommander*' }
foreach ($k in $pkgs) {
    Write-Host ("  store package: {0}  v{1}" -f $k.Name, $k.Version)
    $d = Get-Item $k.InstallLocation -ErrorAction SilentlyContinue
    if ($d) { Write-Host ("    installed/updated: {0:yyyy-MM-dd HH:mm}  {1}" -f $d.LastWriteTime, $k.InstallLocation) }
}

Write-Host ''
Write-Host '=== 3. Programs installed or updated in the last 30 days ==='
$cut = (Get-Date).AddDays(-30)
$rows = @()
$roots = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
         'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
         'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
foreach ($r in $roots) {
    Get-ChildItem $r -ErrorAction SilentlyContinue | ForEach-Object {
        $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
        if ($p.DisplayName -and ($p.InstallDate -match '^\d{8}$')) {
            $d = $null
            try { $d = [datetime]::ParseExact($p.InstallDate, 'yyyyMMdd', $null) } catch {}
            if ($d -and $d -ge $cut) {
                $rows += [pscustomobject]@{ Date = $d; Name = $p.DisplayName; Version = $p.DisplayVersion }
            }
        }
    }
}
Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object { -not $_.IsFramework } | ForEach-Object {
    $d = Get-Item $_.InstallLocation -ErrorAction SilentlyContinue
    if ($d -and $d.LastWriteTime -ge $cut) {
        $rows += [pscustomobject]@{ Date = $d.LastWriteTime; Name = ('(store) ' + $_.Name); Version = $_.Version }
    }
}
if ($rows) {
    $rows | Sort-Object Date -Descending | Select-Object -First 40 | ForEach-Object {
        Write-Host ("  {0:yyyy-MM-dd}  {1}  {2}" -f $_.Date, $_.Name, $_.Version)
    }
} else { Write-Host '  (none found)' }

Write-Host ''
Write-Host '=== 4. Running programs that are known to grab global shortcuts ==='
$suspects = 'AutoHotkey*','nvcontainer','NVIDIA*','RadeonSoftware','Discord','steam','obs64','ShareX','Greenshot',
            'Lightshot','Snagit*','lghub*','Razer*','iCUE','XMouseButtonControl','Flow.Launcher','Wox','Keypirinha',
            'Listary','Ditto','CopyQ','Everything','Clipchamp','GameBar*','EpicGamesLauncher','GalaxyClient','Dropbox',
            'TeamViewer*','AnyDesk','Parsec*','WindowsApp*','msrdc','mstsc','Bandicam*','Xbox*','QuickLook','PowerToys*'
$running = Get-Process -ErrorAction SilentlyContinue
$hits = @()
foreach ($s in $suspects) { $hits += $running | Where-Object { $_.ProcessName -like $s } }
$hits | Sort-Object ProcessName -Unique | ForEach-Object { Write-Host ("  {0}  (pid {1})" -f $_.ProcessName, $_.Id) }
if (-not $hits) { Write-Host '  (none of the usual suspects)' }

Write-Host ''
Write-Host 'Done. The same text is in altg-check.txt.'
Stop-Transcript | Out-Null
