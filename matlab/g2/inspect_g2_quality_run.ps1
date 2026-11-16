# Read-only retrospective review of an EXISTING G2 MATLAB geometry-only run.
# Windows PowerShell 5.1+: no MATLAB, mesh, physics or files are modified.
# Usage:
# powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\inspect_g2_quality_run.ps1 -RunDir ".\outputs\g2_specimen1_pencil\run_20261116_200724_582"
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$RunDir
)
$ErrorActionPreference = 'Stop'
$folder = (Resolve-Path -LiteralPath $RunDir -ErrorAction Stop).Path
$qfile = Join-Path $folder 'quality_forensics.json'
$sfile = Join-Path $folder 'batch_summary.json'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$gfile = Join-Path $repo 'docs\research\crack-growth-gaps-2026\G2_SPECIMEN1_1990_GEOMETRY.json'
foreach ($f in @($qfile,$sfile,$gfile)) {
    if (-not (Test-Path -LiteralPath $f -PathType Leaf)) { throw "Missing input file: $f" }
}
$q = Get-Content -LiteralPath $qfile -Raw -Encoding UTF8 | ConvertFrom-Json
$summary = Get-Content -LiteralPath $sfile -Raw -Encoding UTF8 | ConvertFrom-Json
$geometry = Get-Content -LiteralPath $gfile -Raw -Encoding UTF8 | ConvertFrom-Json
if ($geometry.schema -ne 'NewMetacomp.G2.IngraffeaGrigoriu1990.Specimen1.nominal.v1') {
    throw 'Unexpected geometry JSON schema.'
}
if (-not $q.native -or -not $q.collapsed) { throw 'Missing native/collapsed quality data.' }
$rawN = @($q.native.overLimitEdgeNodeIDs)
$rawC = @($q.collapsed.overLimitEdgeNodeIDs)
$rawP = @($q.native.overLimitEdgeMidpoints_mm)
$rawOwn = @($q.native.overLimitOwnerElementIDs)
$n = [int]$q.native.ratioOver1p8Count
$nc = [int]$q.collapsed.ratioOver1p8Count
if ($n -le 0 -or $rawN.Count -ne $n -or $rawP.Count -ne $n -or
    $rawOwn.Count -ne $n -or $rawC.Count -ne $nc) {
    throw ("Quality JSON arrays inconsistent: native={0}, collapsed={1}; edges={2}, points={3}, owners={4}, collapsedEdges={5}" -f
        $n,$nc,$rawN.Count,$rawP.Count,$rawOwn.Count,$rawC.Count)
}
$holes = @($geometry.nominal_geometry_mm.holes)
if ($holes.Count -ne 3) { throw 'Expected exactly three specimen-1 holes.' }
$tip = @($geometry.nominal_geometry_mm.initial_crack.tip)
if ($tip.Count -ne 2) { throw 'Invalid crack tip coordinates in geometry JSON.' }
$counts = @(0,0,0)
$byHole = @(0,0,0)
$rows = @()
$sameEdges = ($n -eq $nc)
for ($i=0; $i -lt $n; $i++) {
    $en = @($rawN[$i]); $enC = @($rawC[$i])
    $p = @($rawP[$i]); $owners = @($rawOwn[$i])
    if ($en.Count -ne 2 -or $p.Count -ne 2 -or $owners.Count -ne 2) {
        throw ("Malformed native arrays at violating edge #{0}" -f ($i+1))
    }
    if ($i -lt $nc) {
        if ($enC.Count -ne 2 -or $en[0] -ne $enC[0] -or $en[1] -ne $enC[1]) {
            $sameEdges = $false
        }
    }
    $x=[double]$p[0];$y=[double]$p[1]
    if ([double]::IsNaN($x) -or [double]::IsInfinity($x) -or
        [double]::IsNaN($y) -or [double]::IsInfinity($y)) {
        throw ("Nonfinite midpoint for violating edge #{0}" -f ($i+1))
    }
    $bestDist = [double]::PositiveInfinity
    $bestHole = -1
    $bestR = 0.0
    for ($k=0;$k -lt $holes.Count;$k++) {
        $center=@($holes[$k].center)
        $rad=[double]$holes[$k].radius
        $dist=[Math]::Sqrt([Math]::Pow($x-[double]$center[0],2)+
            [Math]::Pow($y-[double]$center[1],2)) - $rad
        if ([Math]::Abs($dist) -lt [Math]::Abs($bestDist)) {
            $bestDist=$dist;$bestHole=$k;$bestR=$rad
        }
    }
    if ($bestHole -lt 0 -or $bestR -le 0) { throw 'Nearest-hole lookup failed.' }
    $scaled=$bestDist/$bestR
    $band=2
    if ([Math]::Abs($bestDist) -le $bestR) {$band=0}
    elseif ($scaled -le 2) {$band=1}
    $counts[$band]++
    $byHole[$bestHole]++
    $dTip=[Math]::Sqrt([Math]::Pow($x-[double]$tip[0],2)+
       [Math]::Pow($y-[double]$tip[1],2))
    $rows += [pscustomobject]@{
        Row=($i+1)
        Edge=("{0}/{1}" -f $en[0],$en[1])
        Elements=("{0}/{1}" -f $owners[0],$owners[1])
        X_mm=[Math]::Round($x,3)
        Y_mm=[Math]::Round($y,3)
        Hole=($bestHole+1)
        Wall_mm=[Math]::Round($bestDist,3)
        WallOverR=[Math]::Round($scaled,3)
        Tip_mm=[Math]::Round($dTip,3)
    }
}
$native = $q.native
$collapsed = $q.collapsed
Write-Host '===== CORNELL #1 EXISTING-RUN T3 QUALITY FORENSICS (READ ONLY) ====='
Write-Host "Source run: $folder"
Write-Host ("MATLAB stage: {0}; Hmax: {1} mm; pass: {2}" -f
    $summary.stage,$summary.controls.Hmax_mm,$summary.pass)
Write-Host ("Native: minAngle={0:N6} deg; maxRatio={1:N8}; overLimit={2}/{3}" -f
    [double]$native.minimumT3Angle_deg,[double]$native.maxNeighborRatio,
    $n,[int]$native.interiorEdges)
Write-Host ("Collapsed: minAngle={0:N6} deg; maxRatio={1:N8}; overLimit={2}/{3}" -f
    [double]$collapsed.minimumT3Angle_deg,[double]$collapsed.maxNeighborRatio,
    $nc,[int]$collapsed.interiorEdges)
Write-Host ("Exact same violating edge node pairs before/after collapse: {0}" -f $sameEdges)
Write-Host ("Nearest-hole counts: lower H1={0}; middle H2={1}; upper H3={2}" -f
    $byHole[0],$byHole[1],$byHole[2])
Write-Host ("Distance bands: within 1R={0}; 1R..2R={1}; beyond 2R={2}" -f
    $counts[0],$counts[1],$counts[2])
Write-Host 'Each line below is one violating NATIVE T3 shared edge:'
$rows | Format-Table Row,Edge,Elements,X_mm,Y_mm,Hole,Wall_mm,WallOverR,Tip_mm -AutoSize | Out-Host
Write-Host 'Top ranked size ratios (from saved 12 worst pairs):'
foreach ($t in @($native.topPairs)) {
    $idx=[int]$t.rank
    Write-Host ("#{0,2}: ratio={1:N7}, midpoint=({2:N4},{3:N4}) mm; elements=[{4},{5}]; hole={6}, wallDist={7:N4} mm" -f
        $idx,[double]$t.ratio,[double]$t.edgeMidpoint_mm[0],
        [double]$t.edgeMidpoint_mm[1],[int]$t.elementIDs[0],
        [int]$t.elementIDs[1],[int]$t.nearestHoleIndex,
        [double]$t.nearestHoleWallDistance_mm)
}
Write-Host 'No code, parameter, mesh, original results or run artifacts were changed.'
