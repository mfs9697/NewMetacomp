# Cornell #1, Issue #20 WP1: full protected mesh (frozen p010 + collar + new exterior)
# followed by independent audits. Geometry only: NO elasticity, SIF or crack growth.
# Windows PowerShell 5.1 + MATLAB R2023a with PDE Toolbox. Run from the repository root:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_protected_mesh.ps1
[CmdletBinding()]
param(
    [string]$MatlabExe='C:\Program Files\Polyspace\R2023a\bin\matlab.exe',
    [double]$MinFreeGiB=5.0
)
$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$scriptDir=(Resolve-Path $PSScriptRoot).Path
if (-not (Test-Path -LiteralPath $MatlabExe -PathType Leaf)) {throw "MATLAB R2023a executable not found: $MatlabExe"}
$specimen=Join-Path $repo 'docs\research\crack-growth-gaps-2026\G2_SPECIMEN1_1990_GEOMETRY.json'
$jsonSha=(Get-FileHash -LiteralPath $specimen -Algorithm SHA256).Hash
if ($jsonSha -ne '45A88FA0926472DDBE5E70E4C80A97B88196DD45D8A266FA04273F89790B47BF') {
    throw "HOLD_SOURCE_CHANGED: Cornell nominal geometry SHA-256 differs: $jsonSha"
}
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
    $dirty=@(& git -C $repo status --porcelain -- $rel)
    if ($dirty.Count -gt 0) {throw "HOLD_VENDOR_DIRTY: $($item.Name)"}
}
function Assert-Memory {
    $os=Get-CimInstance -ClassName Win32_OperatingSystem
    $free=[double]$os.FreePhysicalMemory/1024/1024
    Write-Host ("Available physical RAM: {0:N2} GiB (guard {1:N2})" -f $free,$MinFreeGiB)
    if ($free -lt $MinFreeGiB) {throw 'HOLD_MEMORY: insufficient free RAM.'}
}
function Invoke-Matlab([string]$expr) {
    Assert-Memory
    $d=$scriptDir.Replace("'","''")
    & $MatlabExe -batch "restoredefaultpath;addpath('$d','-begin');$expr"
    if ($LASTEXITCODE -ne 0) {throw "MATLAB step failed (exit=$LASTEXITCODE): $expr"}
}
function Get-NewestRun([string]$sub) {
    (Get-ChildItem -LiteralPath (Join-Path $repo "outputs\$sub") -Directory | Sort-Object Name | Select-Object -Last 1).FullName
}
Write-Host "Repository: $repo"
Write-Host "Original specimen JSON SHA256: $jsonSha"
Write-Host 'G2_WP1_UPSTREAM_SOURCES_PINNED=6/6'
Write-Host 'G2_WP1_STEP=1/3 isolated p010 P0'
Invoke-Matlab 'run_g2_p010_isolated_batch'
$p0=Get-NewestRun 'g2_p010_isolated'
Write-Host "G2_WP1_P0_RUN=$p0"
Write-Host 'G2_WP1_STEP=2/3 full protected mesh'
Invoke-Matlab 'run_g2_protected_mesh_batch'
$mesh=Get-NewestRun 'g2_protected_mesh'
Write-Host "G2_WP1_MESH_RUN=$mesh"
Write-Host 'G2_WP1_STEP=3/3 independent audits (separate MATLAB process)'
$m=$mesh.Replace("'","''");$p=$p0.Replace("'","''")
Invoke-Matlab "run_g2_protected_audit_batch('$m','$p')"
Write-Host "G2_WP1_AUDIT_RUN=$(Get-NewestRun 'g2_protected_audit')"
Write-Host 'WP1 full protected mesh and independent audits passed. Elasticity/SIF (WP2) is a separate gated stage.'
exit 0
