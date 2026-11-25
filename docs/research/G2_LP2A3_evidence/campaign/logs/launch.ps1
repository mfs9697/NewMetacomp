# One MATLAB launch, gated by the STRUCTURED result of the pinned pre-start check (exit code and JSON
# field 'pass'; no log-text matching, no loop, no retry). Usage: launch.ps1 -Tag <name> -Script <m> -Prestart <json>
param([Parameter(Mandatory = $true)][string]$Tag, [Parameter(Mandatory = $true)][string]$Script, [Parameter(Mandatory = $true)][string]$Prestart)
$ps = '<repo>\scripts\g2\lp2a2\lp2a2_eq_prestart_check.ps1'
$runml = '<scratch>'
& powershell -NoProfile -ExecutionPolicy Bypass -File $ps -Out $Prestart | Out-Null
$code = $LASTEXITCODE
$rec = Get-Content $Prestart -Raw | ConvertFrom-Json
Write-Output ("PRESTART exit={0} pass={1} free={2} matlab={3} backup={4}" -f $code, $rec.pass, $rec.freePhysicalGiB, $rec.matlabProcesses, $rec.backupRemovable)
if (($code -ne 0) -or (-not $rec.pass)) { Write-Output 'LAUNCH_NOT_STARTED'; exit 4 }
& $runml -Tag $Tag -Script $Script -Cwd '<repo>' | Out-Null
Write-Output ("MATLAB_EXIT={0}" -f $LASTEXITCODE)
