# Tell Windows to reload the pointer set from the registry (SPI_SETCURSORS).
# Used by install-spinner-cursors.bat / remove-spinner-cursors.bat. No parameters.
$sig = @'
[DllImport("user32.dll", SetLastError = true)]
public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
'@
$u = Add-Type -MemberDefinition $sig -Name Spi -Namespace W -PassThru
$ok = $u::SystemParametersInfo(0x57, 0, [IntPtr]::Zero, 3)
$err = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
Write-Host ("SPI_SETCURSORS returned {0} (lastError {1})" -f $ok, $err)
