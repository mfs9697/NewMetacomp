# Cornell #1: MATLAB R2023a headless pencil-channel candidate geometry.
# Requires Windows PowerShell 5.1+ and MATLAB PDE Toolbox.
# USAGE from any folder:
#   powershell -NoProfile -ExecutionPolicy Bypass -File matlab\g2\run_g2_specimen1_pencil.ps1
#   ... -MatlabExe "C:\Program Files\MATLAB\R2023a\bin\matlab.exe"
# No FEM is run; a geometry HOLD results in a nonzero exit code.
[CmdletBinding()]
param(
    [string]$MatlabExe = 'C:\Program Files\MATLAB\R2023a\bin\matlab.exe',
    [double]$MinFreeGiB = 5.0,
    [ValidateRange(5.0,7.0)]
    [double]$Hmax_mm = 7.0
)
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$scriptDir = (Resolve-Path $PSScriptRoot).Path
if (-not (Test-Path -LiteralPath $MatlabExe -PathType Leaf)) {
    $found = Get-Command matlab.exe -ErrorAction SilentlyContinue
    if ($null -ne $found) {
        $MatlabExe = $found.Source
    } else {
        throw "MATLAB executable not found: $MatlabExe"
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $scriptDir 'g2_specimen1_pencil_mesh.m'))) {
    throw "Missing Cornell #1 pencil mesh source."
}
if (-not (Test-Path -LiteralPath (Join-Path $repoRoot 'docs\research\crack-growth-gaps-2026\G2_SPECIMEN1_1990_GEOMETRY.json'))) {
    throw "Missing pinned geometry JSON. Checkout the full stacked research branch."
}
try {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $freeGiB = [double]$os.FreePhysicalMemory / 1024.0 / 1024.0
    Write-Host ("Available physical RAM: {0:N2} GiB" -f $freeGiB)
    if ($freeGiB -lt $MinFreeGiB) {
        throw ("Memory guard HOLD: {0:N2} GiB free < {1:N2} GiB required" -f $freeGiB,$MinFreeGiB)
    }
} catch {
    Write-Error $_
    exit 17
}
$matlabPath = $scriptDir.Replace("'", "''")
# Invariant-culture MATLAB numeric literal regardless of Windows locale.
$hmaxLiteral = $Hmax_mm.ToString('G17', [System.Globalization.CultureInfo]::InvariantCulture)
$expr = "addpath('$matlabPath');run_g2_specimen1_pencil_batch($hmaxLiteral)"
Write-Host "Repository: $repoRoot"
Write-Host "MATLAB: $MatlabExe"
Write-Host ("Hmax_mm control: {0} (sole changed parameter; default 7)" -f $hmaxLiteral)
Write-Host "Command: matlab -batch <g2 geometry-only runner>"
& $MatlabExe -batch $expr
$rc = $LASTEXITCODE
if ($null -eq $rc) { $rc = 1 }
if ($rc -ne 0) {
    Write-Error "MATLAB geometry batch HOLD / failure (exit=$rc). See outputs/g2_specimen1_pencil/run_*/batch_console.log."
    exit $rc
}
Write-Host 'Candidate geometry batch exited 0. This does NOT authorize LEFM or certify p010.'
exit 0
