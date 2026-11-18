# Cornell #1, Issue #24 WP3.0-WP3.1: analytic MTS tests, ONE kinked protected mesh (family A),
# the mirrored geometry-only control, independent kink-aware audits and negative controls.
# Geometry and algebra only: NO elasticity, SIF or crack growth here.
# Windows PowerShell 5.1 + MATLAB R2023a with PDE Toolbox. Run from the repository root:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_wp3_first_kink.ps1 -P0RunDir <dir> -StraightMeshRunDir <dir>
# P0RunDir: an outputs/g2_p010_isolated/run_* folder (run_g2_p010_isolated_batch).
# StraightMeshRunDir: the WP2 family-A outputs/g2_protected_mesh/run_* folder (control N9 only).
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$P0RunDir,
    [Parameter(Mandatory=$true)][string]$StraightMeshRunDir,
    [string]$MatlabExe='C:\Program Files\Polyspace\R2023a\bin\matlab.exe',
    [double]$MinFreeGiB=5.0
)
$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$scriptDir=(Resolve-Path $PSScriptRoot).Path
$vendorDir=Join-Path $scriptDir 'vendor_p010_a14d8872'
if (-not (Test-Path -LiteralPath $MatlabExe -PathType Leaf)) {throw "MATLAB R2023a executable not found: $MatlabExe"}
$specimen=Join-Path $repo 'docs\research\crack-growth-gaps-2026\G2_SPECIMEN1_1990_GEOMETRY.json'
$jsonSha=(Get-FileHash -LiteralPath $specimen -Algorithm SHA256).Hash
if ($jsonSha -ne '45A88FA0926472DDBE5E70E4C80A97B88196DD45D8A266FA04273F89790B47BF') {throw "HOLD_SOURCE_CHANGED: $jsonSha"}
$pinned=@(
    @{ Name='build_m1i_trial_tip_annulus_p010.m'; SHA='9440ceda09609b4bcbb4bc7da2874f9fffde62b1' }
    @{ Name='build_m1i_trial_tip_disk_p010.m'; SHA='877aa59c8d6cadc0987c791e1d13204f98125d7e' }
    @{ Name='build_twohole_literal_annulus.m'; SHA='16b2045836f548bbc38eea944663a9eb09a5eec3' }
    @{ Name='cut_twohole_literal_annulus.m'; SHA='bfdd4418193da5792e28e07562fffa46bfab8196' }
    @{ Name='T3toT6_fast.m'; SHA='29bf9d8e233b24d70cdc81e392f8b24e239c1afa' }
    @{ Name='main_m1i_increment_ring_geometry_only.m'; SHA='40fbc6b2e4f35299f773fc14736961d4136a7bf7' }
)
foreach($item in $pinned) {
    $rel="matlab/g2/vendor_p010_a14d8872/$($item.Name)"
    $actual=(& git -C $repo rev-parse "HEAD:$rel" 2>$null)
    if ($LASTEXITCODE -ne 0 -or $actual.Trim() -ne $item.SHA) {throw "HOLD_PINNED_BLOB: $($item.Name)"}
    if (@(& git -C $repo status --porcelain -- $rel).Count -gt 0) {throw "HOLD_VENDOR_DIRTY: $($item.Name)"}
}
function Assert-Memory {
    $free=[double](Get-CimInstance -ClassName Win32_OperatingSystem).FreePhysicalMemory/1024/1024
    Write-Host ("Available physical RAM: {0:N2} GiB (guard {1:N2})" -f $free,$MinFreeGiB)
    if ($free -lt $MinFreeGiB) {throw 'HOLD_MEMORY: insufficient free RAM.'}
}
function Invoke-Matlab([string]$expr) {
    Assert-Memory
    $d=$scriptDir.Replace("'","''");$v=$vendorDir.Replace("'","''")
    $old=$ErrorActionPreference;$ErrorActionPreference='Continue'
    & $MatlabExe -batch "restoredefaultpath;addpath('$d','-begin');addpath('$v','-begin');$expr"
    $rc=$LASTEXITCODE;$ErrorActionPreference=$old
    if ($rc -ne 0) {throw "MATLAB step failed (exit=$rc): $expr"}
}
function Get-NewestRun([string]$sub) {(Get-ChildItem -LiteralPath (Join-Path $repo "outputs\$sub") -Directory | Sort-Object Name | Select-Object -Last 1).FullName}
$opts="'BottomVertices_mm',[25.4 482.6],'TopVertices_mm',254,'TipGuideRadius_mm',15,'TipGuideHface_mm',1.5"
Write-Host 'G2_WP3_STEP=1/6 analytic MTS tests and reference manifest'
Invoke-Matlab 'run_g2_wp3_mts_tests_batch'
$man=Join-Path (Get-NewestRun 'g2_wp3_mts') 'WP3_REFERENCE_MANIFEST.mat'
Write-Host 'G2_WP3_STEP=2/6 kinked protected mesh, family A'
Invoke-Matlab "run_g2_wp3_kinked_mesh_batch('$man','famA',false,$opts)"
$meshA=Get-NewestRun 'g2_wp3_kinked_mesh'
Write-Host 'G2_WP3_STEP=3/6 independent kink-aware audit (separate process)'
Invoke-Matlab "run_g2_wp3_kinked_audit_batch('$meshA','$P0RunDir')"
Write-Host 'G2_WP3_STEP=4/6 negative controls'
Invoke-Matlab "check_g2_kinked_auditor_controls('$meshA','$P0RunDir','$StraightMeshRunDir')"
Write-Host 'G2_WP3_STEP=5/6 mirrored geometry-only control mesh'
Invoke-Matlab "run_g2_wp3_kinked_mesh_batch('$man','famA_mirror',true,$opts)"
$meshM=Get-NewestRun 'g2_wp3_kinked_mesh'
Write-Host 'G2_WP3_STEP=6/6 mirrored control audit'
Invoke-Matlab "run_g2_wp3_kinked_audit_batch('$meshM','$P0RunDir')"
Write-Host "G2_WP3_KINKED_MESH_A=$meshA"
Write-Host "G2_WP3_KINKED_MESH_MIRROR=$meshM"
Write-Host 'G2_WP3_0_1_DONE=1; NO_LEFM=1; NO_CRACK_GROWTH=1'
