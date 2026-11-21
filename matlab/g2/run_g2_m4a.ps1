# Issue #44, G2-M4.A: alternative-mesh-family full-path robustness (homogeneous, soft, stiff).
# Default is DRY (writes nothing). -Run needs a clean committed tree and builds a token bound to
# the M4 policy SHA (+ material, family, cap). Modes:
#   s0         alternative State 0 mesh (dry, or -Run to write S0ALT once)
#   trajectory two-step path for ONE material (dry, or -Run)
#   analysis   original-vs-alternative comparison (both families, both uncertainty rules)
#   faults     tamper / restart / replay suite on disposable copies
#   report     Ukrainian figures and tables from a saved analysis run (-RunDir)
# Guards: >= 5 GiB free physical RAM (cannot be lowered), one MATLAB process, R2023a.
[CmdletBinding()]
param(
  [ValidateSet('s0','trajectory','analysis','faults','report')][string]$Mode = 'trajectory',
  [ValidateSet('homogeneous','soft','stiff','')][string]$Material = '',
  [string]$ChainDir = '',
  [string]$RunDir = '',
  [switch]$Run,
  [string]$MatlabExe = 'C:\Program Files\Polyspace\R2023a\bin\matlab.exe',
  [double]$MinFreeGiB = 5.0
)
$ErrorActionPreference='Stop'
if ($MinFreeGiB -lt 5.0) { throw 'HOLD_RAM_POLICY: the 5 GiB guard cannot be reduced.' }
$policy=Join-Path $PSScriptRoot 'G2_M4_POLICY_v1.json'
if(-not (Test-Path -LiteralPath $policy -PathType Leaf)){throw 'M4 policy missing.'}
if (-not (Test-Path -LiteralPath $MatlabExe -PathType Leaf)) { throw "MATLAB R2023a not found: $MatlabExe" }
$busy=@(Get-Process -Name MATLAB -ErrorAction SilentlyContinue)
if ($busy.Count -gt 0) { throw "HOLD_MATLAB_ALREADY_RUNNING ($($busy.Count))" }
$free=[double](Get-CimInstance -ClassName Win32_OperatingSystem).FreePhysicalMemory/1024/1024
Write-Host ("Free RAM: {0:N2} GiB (guard {1:N2} GiB)" -f $free,$MinFreeGiB)
if($free -lt $MinFreeGiB) { throw 'HOLD_MEMORY: free physical RAM below guard; no MATLAB launched.' }
$sha=(Get-FileHash -LiteralPath $policy -Algorithm SHA256).Hash
Write-Host "M4 policy SHA-256: $sha"
$fam='famB_m4alt'
$g2=$PSScriptRoot.Replace("'","''");$vendor=(Join-Path $PSScriptRoot 'vendor_p010_a14d8872').Replace("'","''")
$pre="restoredefaultpath;addpath('$g2','-begin');addpath('$vendor','-begin');"
switch ($Mode) {
  's0' {
    $margs="'Mode','build'"
    if ($Run) { $margs+=",'Run',true,'AuthToken','G2M4AS0|$sha|family=$fam'"; Write-Host 'RUN: writes S0ALT once' } else { Write-Host 'DRY (no files written)' }
    $expr=$pre+"R=g2_m4a_s0alt($margs);disp(R);if ~R.pass,exit(2),end"
  }
  'trajectory' {
    if ($Material -eq '') { throw 'Specify -Material homogeneous|soft|stiff.' }
    $margs="'Material','$Material'"
    if ($ChainDir -ne '') { $margs+=",'ChainDir','"+$ChainDir.Replace("'","''")+"'" }
    if ($Run) { $margs+=",'Run',true,'AuthToken','G2M4ARUN|$sha|$Material|family=$fam|maxState=2'"; Write-Host "RUN authorized for $Material (max 2 steps)" }
    else { Write-Host 'DRY preflight (no files written)' }
    $expr=$pre+"R=g2_m4a_trajectory_run($margs);disp(R);if ~R.pass,exit(2),end"
  }
  'analysis' { $expr=$pre+"L=run_g2_m4a_analysis_batch();if ~strcmp(L.status,'GO'),exit(2),end" }
  'faults'   { $expr=$pre+"T=run_g2_m4a_faults_batch();if ~T.pass,exit(2),end" }
  'report'   { $rd=(Resolve-Path -LiteralPath $RunDir -ErrorAction Stop).Path.Replace("'","''"); $expr=$pre+"W=run_g2_m4a_report_batch('$rd');" }
}
& $MatlabExe -batch $expr
exit $LASTEXITCODE
