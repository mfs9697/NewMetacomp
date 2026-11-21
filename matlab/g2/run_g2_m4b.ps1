# Issue #47, G2-M4.B: frozen-S2 three-ring factorial (16 logical cases, 15 solves), policy v2.
# Default is DRY (B0 inventory + B1 activation checks; writes nothing). -Run needs a clean committed
# tree and builds the token bound to policy v2 SHA + source-set SHA + S2 mesh SHA + case cap. Modes:
#   campaign  dry preflight, or -Run (new run) / -Run -RunDir <run> (verified resume, no FEM on reuse)
#   analysis  attribution analysis of an accepted run (-RunDir)
#   faults    tamper / restart / replay suite on disposable run roots
#   report    Ukrainian figures and tables from an analysis folder (-RunDir <analysis>) and the run (-CampaignDir)
# Guards: >= 5 GiB free physical RAM (cannot be lowered), one MATLAB process, R2023a.
[CmdletBinding()]
param(
  [ValidateSet('campaign','analysis','faults','report')][string]$Mode = 'campaign',
  [string]$RunDir = '',
  [string]$CampaignDir = '',
  [switch]$Run,
  [string]$MatlabExe = 'C:\Program Files\Polyspace\R2023a\bin\matlab.exe',
  [double]$MinFreeGiB = 5.0
)
$ErrorActionPreference='Stop'
if ($MinFreeGiB -lt 5.0) { throw 'HOLD_RAM_POLICY: the 5 GiB guard cannot be reduced.' }
$policy=Join-Path $PSScriptRoot 'G2_M4B_POLICY_v2.json'
if(-not (Test-Path -LiteralPath $policy -PathType Leaf)){throw 'M4.B policy v2 missing.'}
if (-not (Test-Path -LiteralPath $MatlabExe -PathType Leaf)) { throw "MATLAB R2023a not found: $MatlabExe" }
$busy=@(Get-Process -Name MATLAB -ErrorAction SilentlyContinue)
if ($busy.Count -gt 0) { throw "HOLD_MATLAB_ALREADY_RUNNING ($($busy.Count))" }
$free=[double](Get-CimInstance -ClassName Win32_OperatingSystem).FreePhysicalMemory/1024/1024
Write-Host ("Free RAM: {0:N2} GiB (guard {1:N2} GiB)" -f $free,$MinFreeGiB)
if($free -lt $MinFreeGiB) { throw 'HOLD_MEMORY: free physical RAM below guard; no MATLAB launched.' }
$g2=$PSScriptRoot.Replace("'","''");$vendor=(Join-Path $PSScriptRoot 'vendor_p010_a14d8872').Replace("'","''")
$pre="restoredefaultpath;addpath('$g2','-begin');addpath('$vendor','-begin');"
switch ($Mode) {
  'campaign' {
    $margs="'Run',false"
    if ($Run) {
      # the token is computed by MATLAB from the same files the controller verifies, then passed back in
      $margs="'Run',true,'AuthToken',T"
      if ($RunDir -ne '') { $margs+=",'RunDir','"+((Resolve-Path -LiteralPath $RunDir).Path.Replace("'","''"))+"'" }
      $pol=(Get-FileHash -LiteralPath $policy -Algorithm SHA256).Hash.ToLower()
      $expr=$pre+"P=jsondecode(fileread('$g2\G2_M4B_POLICY_v2.json'));[~,s]=g2_m4b_sources('$g2');T=sprintf('G2M4BRUN|%s|src=%s|mesh=%s|cases=16|solves=15','$pol',s,lower(P.reference.meshSHA256));disp(T);R=g2_m4b_campaign($margs);disp(R.status);if ~R.pass,exit(2),end"
      Write-Host "RUN authorized (policy v2 $pol)"
    } else {
      Write-Host 'DRY preflight (no files written)'
      $expr=$pre+"R=g2_m4b_campaign($margs);disp(R.status);if ~R.pass,exit(2),end"
    }
  }
  'analysis' { $rd=(Resolve-Path -LiteralPath $RunDir -ErrorAction Stop).Path.Replace("'","''"); $expr=$pre+"L=run_g2_m4b_analysis_batch('$rd');if ~strcmp(L.status,'GO'),exit(2),end" }
  'faults'   { $rd=(Resolve-Path -LiteralPath $RunDir -ErrorAction Stop).Path.Replace("'","''"); $expr=$pre+"T=run_g2_m4b_faults_batch('$rd');if ~T.pass,exit(2),end" }
  'report'   { $rd=(Resolve-Path -LiteralPath $RunDir -ErrorAction Stop).Path.Replace("'","''"); $cd=(Resolve-Path -LiteralPath $CampaignDir -ErrorAction Stop).Path.Replace("'","''"); $expr=$pre+"W=run_g2_m4b_report_batch('$rd','$cd');" }
}
& $MatlabExe -batch $expr
exit $LASTEXITCODE
