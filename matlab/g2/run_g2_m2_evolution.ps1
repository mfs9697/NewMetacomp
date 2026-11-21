# Issue #36: bonded-band shielding/steering at frozen Cornell States S0, S1, S2 (+ S2alt).
# Reads the accepted meshes/records only; writes a NEW outputs/g2_material_evolution_v1/run_<time>/.
# Guards: >= 5 GiB free physical RAM (cannot be lowered), one MATLAB process, R2023a,
# pinned Cornell JSON SHA-256; MATLAB re-checks a clean committed tree and every source hash.
# Illustrative moduli only: no crack growth, no State 3, no onset or toughness claim.
[CmdletBinding()]
param(
  [string]$MatlabExe = 'C:\Program Files\Polyspace\R2023a\bin\matlab.exe',
  [double]$MinFreeGiB = 5.0,
  [string]$Batch = 'run_g2_m2_evolution_batch',
  [string]$RunDir = ''   # report batch only: a saved outputs/g2_material_evolution_v1/run_<time>
)
$ErrorActionPreference='Stop'
if ($MinFreeGiB -lt 5.0) { throw 'HOLD_RAM_POLICY: the 5 GiB guard cannot be reduced.' }
if ($Batch -notin @('run_g2_m2_evolution_batch','run_g2_m2_report_batch')) { throw "Unknown batch $Batch" }
$root=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$json=Join-Path $root 'docs\research\crack-growth-gaps-2026\G2_SPECIMEN1_1990_GEOMETRY.json'
$policy=Join-Path $PSScriptRoot 'G2_M2_POLICY_v1.json'
foreach($f in @($json,$policy)){ if(-not (Test-Path -LiteralPath $f -PathType Leaf)){throw "Required source is absent: $f"} }
if((Get-FileHash -LiteralPath $json -Algorithm SHA256).Hash -ne '45A88FA0926472DDBE5E70E4C80A97B88196DD45D8A266FA04273F89790B47BF'){
  throw 'HOLD_SOURCE_JSON: nominal geometry SHA-256 changed.'
}
if (-not (Test-Path -LiteralPath $MatlabExe -PathType Leaf)) { throw "MATLAB R2023a not found: $MatlabExe" }
$busy=@(Get-Process -Name MATLAB -ErrorAction SilentlyContinue)
if ($busy.Count -gt 0) { throw "HOLD_MATLAB_ALREADY_RUNNING ($($busy.Count))" }
$free=[double](Get-CimInstance -ClassName Win32_OperatingSystem).FreePhysicalMemory/1024/1024
Write-Host ("Free RAM: {0:N2} GiB (guard {1:N2} GiB)" -f $free,$MinFreeGiB)
if($free -lt $MinFreeGiB) { throw 'HOLD_RAM: free physical RAM below guard; no MATLAB launched.' }
Write-Host ("M2 policy SHA-256: {0}" -f (Get-FileHash -LiteralPath $policy -Algorithm SHA256).Hash)
$g2=$PSScriptRoot.Replace("'","''");$vendor=(Join-Path $PSScriptRoot 'vendor_p010_a14d8872').Replace("'","''")
$arg=''
if ($Batch -eq 'run_g2_m2_report_batch') { $arg=(Resolve-Path -LiteralPath $RunDir -ErrorAction Stop).Path.Replace("'","''") }
$expr="restoredefaultpath;addpath('$g2','-begin');addpath('$vendor','-begin');L=$Batch('$arg');"
& $MatlabExe -batch $expr
exit $LASTEXITCODE
