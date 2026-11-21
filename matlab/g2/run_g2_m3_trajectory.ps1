# Issue #39: bounded two-step material-specific numerical crack paths (soft / stiff).
# Default is a DRY, read-only preflight that writes nothing. -Run computes at most the two
# policy-capped steps for ONE material, with a token bound to policy SHA + material + cap.
# Other modes: analysis (decomposition + preregistered alternative meshes), faults (restart and
# tamper suite on disposable copies), report (figures from a saved analysis run).
# Guards: >= 5 GiB free physical RAM (cannot be lowered), one MATLAB process, R2023a.
[CmdletBinding()]
param(
  [ValidateSet('trajectory','analysis','faults','report')][string]$Mode = 'trajectory',
  [ValidateSet('soft','stiff','')][string]$Material = '',
  [string]$ChainDir = '',
  [string]$RunDir = '',
  [switch]$Run,
  [string]$MatlabExe = 'C:\Program Files\Polyspace\R2023a\bin\matlab.exe',
  [double]$MinFreeGiB = 5.0
)
$ErrorActionPreference='Stop'
if ($MinFreeGiB -lt 5.0) { throw 'HOLD_RAM_POLICY: the 5 GiB guard cannot be reduced.' }
$policy=Join-Path $PSScriptRoot 'G2_M3_TRAJECTORY_POLICY_v1.json'
if(-not (Test-Path -LiteralPath $policy -PathType Leaf)){throw 'M3 policy missing.'}
if (-not (Test-Path -LiteralPath $MatlabExe -PathType Leaf)) { throw "MATLAB R2023a not found: $MatlabExe" }
$busy=@(Get-Process -Name MATLAB -ErrorAction SilentlyContinue)
if ($busy.Count -gt 0) { throw "HOLD_MATLAB_ALREADY_RUNNING ($($busy.Count))" }
$free=[double](Get-CimInstance -ClassName Win32_OperatingSystem).FreePhysicalMemory/1024/1024
Write-Host ("Free RAM: {0:N2} GiB (guard {1:N2} GiB)" -f $free,$MinFreeGiB)
if($free -lt $MinFreeGiB) { throw 'HOLD_RAM: free physical RAM below guard; no MATLAB launched.' }
$sha=(Get-FileHash -LiteralPath $policy -Algorithm SHA256).Hash
Write-Host "M3 policy SHA-256: $sha"
$g2=$PSScriptRoot.Replace("'","''");$vendor=(Join-Path $PSScriptRoot 'vendor_p010_a14d8872').Replace("'","''")
$pre="restoredefaultpath;addpath('$g2','-begin');addpath('$vendor','-begin');"
switch ($Mode) {
  'trajectory' {
    if ($Material -eq '') { throw 'Specify -Material soft|stiff.' }
    $margs="'Material','$Material'"
    if ($ChainDir -ne '') { $margs+=",'ChainDir','"+$ChainDir.Replace("'","''")+"'" }
    if ($Run) { $tok="G2M3RUN|$sha|$Material|maxState=2"; $margs+=",'Run',true,'AuthToken','$tok'"; Write-Host "RUN authorized for $Material (max 2 steps)" }
    else { Write-Host "DRY preflight (no files written)" }
    $expr=$pre+"R=g2_m3_trajectory_run($margs);disp(R);if ~R.pass,exit(2),end"
  }
  'analysis' { $expr=$pre+"L=run_g2_m3_analysis_batch();" }
  'faults'   { $expr=$pre+"T=run_g2_m3_faults_batch();" }
  'report'   { $rd=(Resolve-Path -LiteralPath $RunDir -ErrorAction Stop).Path.Replace("'","''"); $expr=$pre+"W=run_g2_m3_report_batch('$rd');" }
}
& $MatlabExe -batch $expr
exit $LASTEXITCODE
