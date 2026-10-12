# Registers an elevated logon task for mousemaster and disables the Startup
# shortcut, so exactly one instance starts and it starts with admin rights.
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$taskName = 'mousemaster-admin'
$target = Join-Path $here 'mousemaster-autostart.bat'
$user = "$env:USERDOMAIN\$env:USERNAME"

Write-Host ''
Write-Host '=== 1. Checking prerequisites ==='
if (-not (Test-Path $target)) {
    throw "Not found: $target  (run this from the mousemaster folder)"
}
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'This script must run elevated. Use setup-admin-autostart.bat.'
}
Write-Host "  target : $target"
Write-Host "  user   : $user"

Write-Host ''
Write-Host '=== 2. Registering the scheduled task ==='
# Written as XML rather than schtasks flags: only XML can set the working
# directory, and IgnoreNew is what stops a resume from starting a second copy.
$xml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>Start mousemaster elevated at logon, so its overlay gets UIAccess (hints over the taskbar, the notification flyout and elevated windows).</Description>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
      <UserId>$user</UserId>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$user</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>5</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>$target</Command>
      <WorkingDirectory>$here</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
"@
$xmlPath = Join-Path $env:TEMP 'mousemaster-admin-task.xml'
# schtasks reads the XML as UTF-16.
Set-Content -Path $xmlPath -Value $xml -Encoding Unicode
$out = & schtasks /Create /TN $taskName /XML $xmlPath /F 2>&1
Write-Host ("  " + ($out -join "`n  "))
if ($LASTEXITCODE -ne 0) { throw "schtasks /Create failed with exit code $LASTEXITCODE" }
Remove-Item $xmlPath -Force

Write-Host ''
Write-Host '=== 3. Disabling the old Startup shortcut ==='
# Two instances fight over the keyboard hook, so the non-elevated launcher has
# to go. Renamed, not deleted: undo-admin-autostart.bat puts it back.
$lnk = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup\mousemaster-prewarm.lnk'
if (Test-Path $lnk) {
    $disabled = "$lnk.disabled"
    if (Test-Path $disabled) { Remove-Item $disabled -Force }
    Rename-Item -Path $lnk -NewName (Split-Path $disabled -Leaf)
    Write-Host "  renamed to mousemaster-prewarm.lnk.disabled"
} else {
    Write-Host '  already absent - nothing to do'
}

Write-Host ''
Write-Host '=== 4. Verifying ==='
$q = & schtasks /Query /TN $taskName /FO LIST 2>&1
Write-Host ("  " + (($q | Select-String 'TaskName|Status|Next Run') -join "`n  "))
Write-Host ''
Write-Host 'DONE. From the next logon, mousemaster starts elevated with no UAC prompt.'
Write-Host ''
Write-Host 'To start it elevated right now:'
Write-Host '  1. quit the mousemaster that is running (tray icon or its console window)'
Write-Host '  2. run start-mousemaster-admin.bat'
Write-Host ''
Write-Host 'To check it worked: the console must NOT show'
Write-Host '  "Failed OpenProcess winlogon 5"'
Write-Host 'and UI hints should now appear over the taskbar and the notification flyout.'
