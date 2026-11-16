# Independent read-only T6 geometry audit of one EXISTING successful G2 batch.
# Original MATLAB candidate run is never modified; no mesh generation/FEM.
#
# Example from repository root:
# powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_independent_t6.ps1 -RunDir ".\outputs\g2_specimen1_pencil\run_20261116_214346_310"
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$RunDir,
    [string]$MatlabExe = 'C:\Program Files\MATLAB\R2023a\bin\matlab.exe',
    [double]$MinFreeGiB = 5.0
)
$ErrorActionPreference='Stop'
$repoRoot=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$source=(Resolve-Path -LiteralPath $RunDir -ErrorAction Stop).Path
$mat=Join-Path $source 'GEOMETRY_ONLY_candidate.mat'
if (-not (Test-Path -LiteralPath $mat -PathType Leaf)) {
    throw "Geometry-only candidate MAT is missing: $mat"
}
$geom=Join-Path $repoRoot 'docs\research\crack-growth-gaps-2026\G2_SPECIMEN1_1990_GEOMETRY.json'
if (-not (Test-Path -LiteralPath $geom -PathType Leaf)) {throw "Missing specimen source JSON: $geom"}
if (-not (Test-Path -LiteralPath $MatlabExe -PathType Leaf)) {
    $located=Get-Command matlab.exe -ErrorAction SilentlyContinue
    if ($null -eq $located) {throw "MATLAB executable not found: $MatlabExe"}
    $MatlabExe=$located.Source
}
$os=Get-CimInstance -ClassName Win32_OperatingSystem
$free=[double]$os.FreePhysicalMemory/1024/1024
Write-Host ("Free RAM: {0:N2} GiB (minimum {1:N2} GiB)" -f $free,$MinFreeGiB)
if ($free -lt $MinFreeGiB) {
    Write-Error ("HOLD_MEMORY: {0:N2} GiB < {1:N2} GiB" -f $free,$MinFreeGiB)
    exit 17
}
Write-Host "Source candidate MAT: $mat"
Write-Host ("Source candidate SHA256: {0}" -f (Get-FileHash -LiteralPath $mat -Algorithm SHA256).Hash)
Write-Host ("Pinned specimen JSON SHA256: {0}" -f (Get-FileHash -LiteralPath $geom -Algorithm SHA256).Hash)
Write-Host 'NO_REMESH=1; NO_PHYSICAL_FEM=1'
$srcEsc=$source.Replace("'","''")
$pathEsc=$PSScriptRoot.Replace("'","''")
$expr="addpath('$pathEsc');run_g2_independent_t6_batch('$srcEsc')"
& $MatlabExe -batch $expr
$exit=$LASTEXITCODE
if ($null -eq $exit) {$exit=1}
if ($exit -ne 0) {
    Write-Error "Independent T6 geometry HOLD (MATLAB exit $exit). Inspect outputs/g2_independent_t6/run_*/independent_t6_summary.json."
    exit $exit
}
Write-Host 'Independent T6 geometric audit exited 0. Protected tip p010 and physical LEFM remain NOT authorized.'
exit 0
