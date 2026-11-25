# LP2-A2 equivalence campaign, activation attempt A2: operating-system check BEFORE MATLAB starts.
# Requires >= MinFreeGiB available physical memory (operational headroom, default 8.2 GiB), no running
# MATLAB process, and the removable backup drive present. Writes a JSON record and exits 0 (pass) or
# 4 (refuse). It does not start MATLAB, create a GO or run any solve; the >= 7 GiB gate inside MATLAB
# (g2_lp2a2_eq_memgate) and the 5 GiB preflight guard (g2_lp0_preflight) are unchanged and separate.
# usage: powershell -NoProfile -File lp2a2_eq_prestart_check.ps1 -Out <json> [-MinFreeGiB 8.2] [-BackupDrive D]
param([Parameter(Mandatory = $true)][string]$Out, [double]$MinFreeGiB = 8.2, [string]$BackupDrive = 'D')
$os = Get-CimInstance Win32_OperatingSystem
$free = [math]::Round($os.FreePhysicalMemory / 1MB, 3)
$ml = @(Get-Process -Name MATLAB -ErrorAction SilentlyContinue)
$vol = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}:'" -f $BackupDrive) -ErrorAction SilentlyContinue
$backupOk = ($null -ne $vol) -and ($vol.DriveType -eq 2)
$pass = ($free -ge $MinFreeGiB) -and ($ml.Count -eq 0) -and $backupOk
$rec = [ordered]@{
  schema = 'NewMetacomp.G2.LP2A2.EQ.PrestartCheck.v1'; activationLabel = 'A2'
  utc = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
  freePhysicalGiB = $free; minFreeGiB = $MinFreeGiB; matlabProcesses = $ml.Count
  backupDrive = $BackupDrive; backupRemovable = $backupOk; pass = $pass
}
($rec | ConvertTo-Json) | Out-File -FilePath $Out -Encoding ascii
Write-Output ("PRESTART free={0} GiB (min {1}) matlab={2} backup={3}:{4} pass={5}" -f $free, $MinFreeGiB, $ml.Count, $BackupDrive, $backupOk, $pass)
if ($pass) { exit 0 } else { exit 4 }
