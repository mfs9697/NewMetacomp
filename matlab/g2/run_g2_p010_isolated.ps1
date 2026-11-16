# Cornell #1: isolate pinned regular p010 disk-annulus + 0.3 mm collar.
# NO global remeshing, no elasticity, no physical crack growth or LEFM.
# Can run from repository root on Windows PowerShell 5.1 + MATLAB R2023a.
[CmdletBinding()]
param(
    [string]$MatlabExe='C:\Program Files\Polyspace\R2023a\bin\matlab.exe',
    [double]$MinFreeGiB=5.0
)
$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$scriptDir=(Resolve-Path $PSScriptRoot).Path
$vendor=Join-Path $scriptDir 'vendor_p010_a14d8872'
if (-not (Test-Path -LiteralPath $MatlabExe -PathType Leaf)) {
    $found=Get-Command matlab.exe -ErrorAction SilentlyContinue
    if ($null -eq $found) {throw "MATLAB R2023a executable not found: $MatlabExe"}
    $MatlabExe=$found.Source
}
$specimen=Join-Path $repo 'docs\research\crack-growth-gaps-2026\G2_SPECIMEN1_1990_GEOMETRY.json'
if (-not (Test-Path -LiteralPath $specimen -PathType Leaf)) {
    throw "Cornell nominal source JSON missing: $specimen"
}
$jsonSha=(Get-FileHash -LiteralPath $specimen -Algorithm SHA256).Hash
if ($jsonSha -ne '45A88FA0926472DDBE5E70E4C80A97B88196DD45D8A266FA04273F89790B47BF') {
    throw "HOLD_SOURCE_CHANGED: Original Cornell nominal geometry SHA-256 differs: $jsonSha"
}
# Verify pinned upstream copies by Git blob identity *and* a clean local
# working tree. Git handles Windows checkout EOL filters itself.
$pinned=@(
    @{ Name='build_m1i_trial_tip_annulus_p010.m'; SHA='9440ceda09609b4bcbb4bc7da2874f9fffde62b1' }
    @{ Name='build_m1i_trial_tip_disk_p010.m'; SHA='877aa59c8d6cadc0987c791e1d13204f98125d7e' }
    @{ Name='build_twohole_literal_annulus.m'; SHA='16b2045836f548bbc38eea944663a9eb09a5eec3' }
    @{ Name='cut_twohole_literal_annulus.m'; SHA='bfdd4418193da5792e28e07562fffa46bfab8196' }
    @{ Name='T3toT6_fast.m'; SHA='29bf9d8e233b24d70cdc81e392f8b24e239c1afa' }
    @{ Name='main_m1i_increment_ring_geometry_only.m'; SHA='40fbc6b2e4f35299f773fc14736961d4136a7bf7' }
)
$verified=0
foreach($item in $pinned) {
    $name=$item.Name;$expected=$item.SHA
    $file=Join-Path $vendor $name
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw "Pinned p010 MATLAB source missing: $file"
    }
    $rel="matlab/g2/vendor_p010_a14d8872/$name"
    $actual=(& git -C $repo rev-parse "HEAD:$rel" 2>$null)
    if ($LASTEXITCODE -ne 0 -or $actual.Trim() -ne $expected) {
        throw "HOLD_PINNED_BLOB: $name HEAD blob $actual (expected $expected)"
    }
    $dirty=@(& git -C $repo status --porcelain -- $rel)
    if ($LASTEXITCODE -ne 0 -or $dirty.Count -gt 0) {
        throw "HOLD_VENDOR_DIRTY: $name working tree differs from pinned commit"
    }
    $verified++
}
$os=Get-CimInstance -ClassName Win32_OperatingSystem
$freeGiB=[double]$os.FreePhysicalMemory/1024/1024
Write-Host ("Available physical RAM: {0:N2} GiB (guard {1:N2})" -f $freeGiB,$MinFreeGiB)
if ($freeGiB -lt $MinFreeGiB) {throw 'HOLD_MEMORY: insufficient free RAM.'}
$matlabDir=$scriptDir.Replace("'","''")
Write-Host "Repository: $repo"
Write-Host "MATLAB: $MatlabExe"
Write-Host "Original specimen JSON SHA256: $jsonSha"
Write-Host "G2_P010_UPSTREAM_SOURCES_PINNED=$verified/6"
Write-Host 'G2_P010_PDE_REMESH=0'
Write-Host 'G2_P010_PHYSICAL_SOLVE=0'
Write-Host 'G2_P010_ONLY_REGULAR_CORE_AND_COLLAR=1'
$expr="addpath('$matlabDir','-begin');run_g2_p010_isolated_batch"
& $MatlabExe -batch $expr
$rc=$LASTEXITCODE
if ($null -eq $rc) {$rc=1}
if ($rc -ne 0) {
    Write-Error "G2 isolated regular p010 HOLD (exit=$rc). See outputs/g2_p010_isolated/run_*/p010_isolated_summary.json."
    exit $rc
}
Write-Host 'Isolated regular p010 block passed. Conforming Cornell exterior join and LEFM remain NOT authorized.'
exit 0
