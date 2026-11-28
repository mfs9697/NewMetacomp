# Removable backup drive stability log: one sample every 5 s for 15 minutes (180 samples). Attempt 2
# (attempt 1 failed: Bash quoting turned the WMI filter into DeviceID=D: -> 'Invalid query' on every sample).
param([Parameter(Mandatory = $true)][string]$Out)
"utc,present,driveType,freeBytes,testPath" | Out-File -Encoding ascii $Out
$miss = 0; $bad = 0
for ($i = 0; $i -lt 180; $i++) {
  $t = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  $d = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='D:'" -ErrorAction SilentlyContinue
  $tp = Test-Path 'D:\'
  if ($d) {
    if ($d.DriveType -ne 2) { $bad++ }
    "$t,1,$($d.DriveType),$($d.FreeSpace),$tp" | Out-File -Append -Encoding ascii $Out
  } else {
    $miss++; "$t,0,,,$tp" | Out-File -Append -Encoding ascii $Out
  }
  Start-Sleep -Seconds 5
}
"SAMPLES=180 MISSING=$miss NOT_REMOVABLE=$bad"
