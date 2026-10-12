# Reports the real state of the elevated-autostart setup.
# Uses the ScheduledTasks cmdlets rather than parsing schtasks output: schtasks
# prints localized labels, and grepping English ones silently found nothing on a
# Japanese Windows (which is what made the first version of this script useless).
$ErrorActionPreference = 'Continue'
$programs = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$startup  = Join-Path $programs 'Startup'
$shell = New-Object -ComObject WScript.Shell

function ShowLnk($file) {
    $s = $shell.CreateShortcut($file.FullName)
    Write-Host ("    {0}" -f $file.Name)
    Write-Host ("       -> {0} {1}" -f $s.TargetPath, $s.Arguments)
}

Write-Host ''
Write-Host '=== 1. Scheduled tasks matching *mousemaster* ==='
$tasks = Get-ScheduledTask -TaskName '*mousemaster*' -ErrorAction SilentlyContinue
if (-not $tasks) {
    Write-Host '  none - run setup-admin-autostart.bat'
} else {
    foreach ($t in $tasks) {
        $info = Get-ScheduledTaskInfo -TaskName $t.TaskName -TaskPath $t.TaskPath -ErrorAction SilentlyContinue
        Write-Host ("  name      : {0}{1}" -f $t.TaskPath, $t.TaskName)
        Write-Host ("  state     : {0}" -f $t.State)
        Write-Host ("  run level : {0}   (Highest = elevated)" -f $t.Principal.RunLevel)
        foreach ($a in $t.Actions) {
            Write-Host ("  action    : {0} {1}" -f $a.Execute, $a.Arguments)
            if ($a.WorkingDirectory) { Write-Host ("  workdir   : {0}" -f $a.WorkingDirectory) }
        }
        foreach ($tr in $t.Triggers) { Write-Host ("  trigger   : {0}" -f $tr.CimClass.CimClassName) }
        if ($info) {
            Write-Host ("  last run  : {0}" -f $info.LastRunTime)
            Write-Host ("  last result: 0x{0:X}   (0 = ok)" -f $info.LastTaskResult)
            Write-Host ("  next run  : {0}" -f $info.NextRunTime)
        }
        Write-Host ''
    }
}

Write-Host '=== 2. Start menu entries matching *mousemaster* (what PowerToys Run offers) ==='
$found = Get-ChildItem -Path $programs -Recurse -Filter '*mousemaster*' -ErrorAction SilentlyContinue
if ($found) {
    foreach ($f in $found) {
        # CreateShortcut only accepts .lnk/.url; a .bak beside them threw a COM error.
        if ($f.Extension -eq '.lnk') { ShowLnk $f } else { Write-Host ("    {0}   (not a shortcut)" -f $f.Name) }
    }
} else { Write-Host '    (none)' }

Write-Host ''
Write-Host '=== 3. Startup folder (everything in it) ==='
$su = Get-ChildItem -Path $startup -ErrorAction SilentlyContinue
if ($su) { foreach ($f in $su) { Write-Host ("    " + $f.Name) } } else { Write-Host '    (empty)' }

Write-Host ''
Write-Host '=== 4. Running process ==='
$p = Get-Process mousemaster -ErrorAction SilentlyContinue
if ($p) {
    foreach ($proc in $p) { Write-Host ("  running: pid {0}, started {1}" -f $proc.Id, $proc.StartTime) }
} else {
    Write-Host '  not running'
}

Write-Host ''
Write-Host '=== 5. Can the task be started right now? ==='
Write-Host '  (this actually runs it - mousemaster should appear)'
$r = & schtasks /Run /TN 'mousemaster-admin' 2>&1
Write-Host ("  schtasks exit code: {0}" -f $LASTEXITCODE)
Write-Host ("  " + ($r -join "`n  "))
Start-Sleep -Seconds 3
$p2 = Get-Process mousemaster -ErrorAction SilentlyContinue
if ($p2) {
    Write-Host '  -> mousemaster is now running.'
} else {
    Write-Host '  -> still not running. Check autostart-timing.log next to this script,'
    Write-Host '     and mousemaster.log, for what the batch did.'
}
