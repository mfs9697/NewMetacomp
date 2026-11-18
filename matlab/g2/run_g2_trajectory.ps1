# Cornell specimen #1: Policy-v1 numerical trajectory continuation, with dry default.
# Inputs are the author's real verified WP3 step-1 folder and isolated P0 source.
# Executing WITHOUT -Run is a READ-ONLY preflight (no meshing/FEM/files).
# With -Run: one NEW numerical state 2 max, after SHA-bound authorization.
# No physical fracture onset or unrestricted growth claims.
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$SeedStepDir,
  [Parameter(Mandatory=$true)][string]$P0RunDir,
  [string]$ChainDir = '.\outputs\g2_trajectory_chain_v1',
  [string]$MatlabExe = 'C:\Program Files\Polyspace\R2023a\bin\matlab.exe',
  [double]$MinFreeGiB = 5.0,
  [switch]$Run,
  [switch]$ForbidNewComputation
)
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$source=(Resolve-Path -LiteralPath $SeedStepDir -ErrorAction Stop).Path
$p0=(Resolve-Path -LiteralPath $P0RunDir -ErrorAction Stop).Path
$p0mat=Join-Path $p0 'P010_ISOLATED_REGULAR_ONLY.mat'
$state=Join-Path $source 'state\state.mat'
$mesh=Join-Path $source 'KINKED_GEOMETRY_ONLY_candidate.mat'
$policy=Join-Path $PSScriptRoot 'G2_TRAJECTORY_POLICY_v1.json'
$json=Join-Path $root 'docs\research\crack-growth-gaps-2026\G2_SPECIMEN1_1990_GEOMETRY.json'
foreach($f in @($p0mat,$state,$mesh,$policy,$json)){
  if(-not (Test-Path -LiteralPath $f -PathType Leaf)){throw "Required immutable source is absent: $f"}
}
if (-not (Test-Path -LiteralPath $MatlabExe -PathType Leaf)) {
  $found=Get-Command matlab.exe -ErrorAction SilentlyContinue
  if ($null -eq $found) {throw "MATLAB R2023a not found: $MatlabExe"}
  $MatlabExe=$found.Source
}
# Six unchanged p010 vendor files must still be the actual pinned upstream
# Git objects and must be clean in the local working tree.
$pinned=@(
 @{Name='build_m1i_trial_tip_annulus_p010.m';Sha='9440ceda09609b4bcbb4bc7da2874f9fffde62b1'}
 @{Name='build_m1i_trial_tip_disk_p010.m';Sha='877aa59c8d6cadc0987c791e1d13204f98125d7e'}
 @{Name='build_twohole_literal_annulus.m';Sha='16b2045836f548bbc38eea944663a9eb09a5eec3'}
 @{Name='cut_twohole_literal_annulus.m';Sha='bfdd4418193da5792e28e07562fffa46bfab8196'}
 @{Name='T3toT6_fast.m';Sha='29bf9d8e233b24d70cdc81e392f8b24e239c1afa'}
 @{Name='main_m1i_increment_ring_geometry_only.m';Sha='40fbc6b2e4f35299f773fc14736961d4136a7bf7'}
)
foreach($it in $pinned){
  $rel="matlab/g2/vendor_p010_a14d8872/$($it.Name)"
  $sha=(& git -C $root rev-parse "HEAD:$rel" 2>$null)
  if($LASTEXITCODE -ne 0 -or $sha.Trim() -ne $it.Sha){
    throw "HOLD_PINNED_VENDOR: $rel HEAD SHA mismatch"
  }
  $dirty=@(& git -C $root status --porcelain -- $rel)
  if($LASTEXITCODE -ne 0 -or $dirty.Count -gt 0){
    throw "HOLD_VENDOR_DIRTY: $rel has uncommitted changes"
  }
}
$free=[double](Get-CimInstance -ClassName Win32_OperatingSystem).FreePhysicalMemory/1024/1024
Write-Host ("Free RAM: {0:N2} GiB (guard {1:N2} GiB)" -f $free,$MinFreeGiB)
if($free -lt $MinFreeGiB) { throw "HOLD_RAM: free physical RAM below guard; no MATLAB launched." }
$shaPolicy=(Get-FileHash -LiteralPath $policy -Algorithm SHA256).Hash
$shaGeometry=(Get-FileHash -LiteralPath $json -Algorithm SHA256).Hash
$shaSource=(Get-FileHash -LiteralPath $state -Algorithm SHA256).Hash
$shaP0=(Get-FileHash -LiteralPath $p0mat -Algorithm SHA256).Hash
if($shaGeometry -ne '45A88FA0926472DDBE5E70E4C80A97B88196DD45D8A266FA04273F89790B47BF'){
  throw "HOLD_SOURCE_JSON: nominal geometry SHA-256 changed: $shaGeometry"
}
$chainPath=$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ChainDir)
$matlabPath=$PSScriptRoot.Replace("'","''")
$vendor=(Join-Path $PSScriptRoot 'vendor_p010_a14d8872').Replace("'","''")
$sourceLiteral=$source.Replace("'","''")
$p0Literal=$p0mat.Replace("'","''")
$chainLiteral=$chainPath.Replace("'","''")
$runLiteral=if($Run.IsPresent){'true'}else{'false'}
$noCompute=if($ForbidNewComputation.IsPresent){'true'}else{'false'}
if($Run.IsPresent) {
  $authorization="struct('token','CORNELL_G2_BOUNDED_NUMERICAL_V1','policySHA256','$shaPolicy','maxStateIndex',2)"
}else{
  $authorization="struct()"
}
Write-Host "Source WP3 state: $state"
Write-Host "Source SHA256: $shaSource"
Write-Host "P0 source SHA256: $shaP0"
Write-Host "Frozen policy SHA256: $shaPolicy"
Write-Host "Original Cornell JSON SHA256: $shaGeometry"
Write-Host "Chain folder: $chainPath"
Write-Host "Run requested: $($Run.IsPresent); max new state=2; physical onset=false"
$expr="restoredefaultpath;addpath('$matlabPath','-begin');addpath('$vendor','-begin');R=g2_trajectory_run('SeedStepDir','$sourceLiteral','P0Mat','$p0Literal','ChainDir','$chainLiteral','Run',$runLiteral,'ForbidNewComputation',$noCompute,'AuthorizeNumericalMarch',$authorization);disp(R);assert(R.pass,'G2Trajectory:HOLD','Numerical trajectory HOLD: %s',R.stage);"
& $MatlabExe -batch $expr
$exit=$LASTEXITCODE
if($null -eq $exit){$exit=1}
if($exit -ne 0){
  Write-Error "G2 bounded trajectory HOLD (MATLAB exit=$exit). Check its diagnostic and the immutable chain folder; do not retry by overwriting a partial step."
  exit $exit
}
Write-Host "Trajectory controller exited 0. This is NUMERICAL direction only, NOT physical fracture propagation."
exit 0
