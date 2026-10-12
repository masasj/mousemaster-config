# Registers the on-demand elevated task "mousemaster-stop" and a Start-menu
# shortcut "mousemaster stop" that fires it. Same idea as setup-admin-autostart.ps1,
# but built with the ScheduledTasks cmdlets instead of XML (no schema to get wrong).
# Everything printed here also goes to setup-stop-task.log next to this script.
#
# -ShortcutOnly (run by setup-stop-shortcut.bat): no task, no admin rights.
# The shortcut then runs stop-mousemaster-direct.bat, which kills a NON-elevated
# mousemaster directly. For a PC without admin rights (branch B of the plan),
# where mousemaster itself runs non-elevated.
param([switch]$ShortcutOnly)
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
Start-Transcript -Path (Join-Path $here 'setup-stop-task.log') -Append | Out-Null
try {
    $taskName = 'mousemaster-stop'
    $worker = Join-Path $here 'stop-mousemaster-task.ps1'
    if ($ShortcutOnly) { $launcher = Join-Path $here 'stop-mousemaster-direct.bat' }
    else { $launcher = Join-Path $here 'stop-mousemaster-admin.bat' }
    $user = "$env:USERDOMAIN\$env:USERNAME"

    Write-Host ''
    Write-Host '=== 1. Checking prerequisites ==='
    foreach ($f in @($worker, $launcher)) {
        if (-not (Test-Path $f)) { throw "Not found: $f  (run this from the mousemaster folder)" }
    }
    if (-not $ShortcutOnly) {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw 'This script must run elevated. Use setup-stop-task.bat.'
        }
    }
    Write-Host "  worker   : $worker"
    Write-Host "  launcher : $launcher"
    Write-Host "  user     : $user"

    Write-Host ''
    Write-Host '=== 2. Registering the on-demand task ==='
    if ($ShortcutOnly) {
        Write-Host '  skipped (-ShortcutOnly): no task. The shortcut kills a non-elevated mousemaster directly.'
    }
    else {
        # No trigger: it only runs when asked (schtasks /Run). RunLevel Highest is what
        # lets it end the elevated mousemaster without a UAC prompt. The worker runs
        # through powershell.exe with a hidden window so nothing flashes on screen.
        $workerArgs = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $worker + '"'
        $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $workerArgs -WorkingDirectory $here
        $taskPrincipal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew `
            -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
            -ExecutionTimeLimit (New-TimeSpan -Minutes 1) -Priority 5
        Register-ScheduledTask -TaskName $taskName -Action $action -Principal $taskPrincipal -Settings $settings `
            -Description 'Stop the elevated mousemaster on demand (force-kill, then reload the system cursors). Fired by stop-mousemaster-admin.bat and the "mousemaster stop" Start menu entry.' `
            -Force | Out-Null
        Write-Host "  registered: $taskName"
    }

    Write-Host ''
    Write-Host '=== 3. Start menu entry "mousemaster stop" ==='
    # Same folder and style as the existing "mousemaster" entry, so PowerToys Run
    # lists both when you type "mou"; typing "stop" narrows it to this one.
    $programs = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
    $lnk = Join-Path $programs 'mousemaster stop.lnk'
    $shell = New-Object -ComObject WScript.Shell
    $s = $shell.CreateShortcut($lnk)
    $s.TargetPath = $launcher
    $s.WorkingDirectory = $here
    if ($ShortcutOnly) { $s.Description = 'Stop mousemaster (kills the non-elevated process directly, no admin rights)' }
    else { $s.Description = 'Stop mousemaster (mousemaster-stop scheduled task, no UAC prompt)' }
    $s.WindowStyle = 7   # minimised: the launcher is silent on success
    # Red tile + dark wheel = stopped (pair of mm4-start.ico, purple tile + green wheel).
    $ico = Join-Path $here 'mm4-stop.ico'
    if (Test-Path $ico) { $s.IconLocation = "$ico,0" } else { $s.IconLocation = "$env:SystemRoot\System32\main.cpl,0" }
    $s.Save()
    if (-not (Test-Path $lnk)) { throw "Shortcut was not created: $lnk" }
    Write-Host "  created: $lnk"

    # Branch B has no Start menu entry for starting. Give it one, so "mou" works too.
    if ($ShortcutOnly) {
        $startLnk = Join-Path $programs 'mousemaster.lnk'
        $adminLnk = Join-Path $programs 'mousemaster (admin).lnk'
        $starter = Join-Path $here 'mousemaster-start.bat'
        if ((-not (Test-Path $startLnk)) -and (-not (Test-Path $adminLnk)) -and (Test-Path $starter)) {
            $st = $shell.CreateShortcut($startLnk)
            $st.TargetPath = $starter
            $st.WorkingDirectory = $here
            $st.Description = 'Start mousemaster (non-elevated)'
            $st.WindowStyle = 7
            $startIco = Join-Path $here 'mm4-start.ico'
            if (Test-Path $startIco) { $st.IconLocation = "$startIco,0" } else { $st.IconLocation = "$env:SystemRoot\System32\main.cpl,0" }
            $st.Save()
            Write-Host "  created: $startLnk  (start entry, so  mou  works as well)"
        }
    }

    Write-Host ''
    Write-Host '=== 4. Verifying ==='
    if (-not $ShortcutOnly) {
        $t = Get-ScheduledTask -TaskName $taskName
        Write-Host ("  task : {0}  state={1}  runLevel={2}" -f $t.TaskName, $t.State, $t.Principal.RunLevel)
    }
    Write-Host ("  lnk  : {0}" -f $lnk)
    Write-Host ''
    Write-Host 'DONE. From now on:'
    if ($ShortcutOnly) {
        Write-Host '  stop  : alt+e (PowerToys Run), type  stop , Enter   (or run stop-mousemaster-direct.bat)'
        Write-Host '  start : alt+e, type  mou , Enter'
        Write-Host 'No PowerToys? Press the Windows key, type  mousemaster stop , Enter. Same thing.'
    }
    else {
        Write-Host '  stop  : alt+e (PowerToys Run), type  stop , Enter   (or run stop-mousemaster-admin.bat)'
        Write-Host '  start : alt+e, type  mou , Enter                     (as before)'
    }
    Write-Host 'What the stop does: force-kills mousemaster, then reloads the system cursors.'
    Write-Host 'Log of each stop: mm-stop.log next to this script.'
    Write-Host ''
    Write-Host 'PowerToys Run may take a moment to index the new entry. If it never shows up,'
    Write-Host 'quit PowerToys from the tray and start it again.'
} catch {
    Write-Host ''
    Write-Host ("FAILED: " + $_.Exception.Message)
    Write-Host ($_.ScriptStackTrace)
} finally {
    Stop-Transcript | Out-Null
}
