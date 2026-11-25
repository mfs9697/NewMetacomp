# Compatible with Windows PowerShell 5.1 and PowerShell 7.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$build = Join-Path $root 'build'
$null = New-Item -ItemType Directory -Path $build -Force
$xe = (Get-Command xelatex -CommandType Application -ErrorAction Stop).Source
$pdf = Join-Path $build 'main.pdf'
$log = Join-Path $build 'main.log'
$generated = @('pdf','aux','toc','out','log','bcf','bbl','blg','run.xml','lof','lot','fls','fdb_latexmk','xdv')
function Invoke-XePass([int]$pass) {
    Write-Host "XeLaTeX pass $pass (batchmode)"
    & $xe '-interaction=batchmode' '-halt-on-error' '-file-line-error' '-no-shell-escape' "-output-directory=$build" 'main.tex'
    if ($LASTEXITCODE -ne 0) { throw "XeLaTeX pass $pass failed. See $log" }
}
Push-Location $root
try {
    foreach ($ext in $generated) {
        $p = Join-Path $build ("main." + $ext)
        if (Test-Path -LiteralPath $p -PathType Leaf) { Remove-Item -LiteralPath $p -Force }
    }
    Invoke-XePass 1
    if (Test-Path -LiteralPath (Join-Path $build 'main.bcf')) {
        $biber = (Get-Command biber -CommandType Application -ErrorAction Stop).Source
        & $biber "--input-directory=$build" "--output-directory=$build" 'main'
        if ($LASTEXITCODE -ne 0) { throw 'Biber failed. See build/main.blg.' }
    }
    Invoke-XePass 2
    Invoke-XePass 3
    if (-not (Test-Path -LiteralPath $pdf -PathType Leaf)) { throw 'No PDF generated.' }
    if ((Get-Item -LiteralPath $pdf).Length -eq 0) { throw 'Empty PDF.' }
    $warnings = Select-String -LiteralPath $log -Pattern 'There were undefined (references|citations)|Citation .* undefined|Reference .* undefined|Label\(s\) may have changed|Please \(re\)run Biber|Rerun to get cross-references right'
    if ($warnings) { throw 'Unresolved references or rerun request in final log.' }
    Write-Host "SUCCESS: $pdf"
} catch {
    if (Test-Path -LiteralPath $pdf -PathType Leaf) { Remove-Item -LiteralPath $pdf -Force }
    throw
} finally {
    Pop-Location
}
