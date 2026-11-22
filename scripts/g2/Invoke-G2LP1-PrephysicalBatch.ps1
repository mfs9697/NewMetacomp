#Requires -Version 5.1
<#
.SYNOPSIS
  NewMetacomp G2-LP0/LP1 prephysical MATLAB batch (NO FEM, NO MESH).
.EXAMPLE
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\g2\Invoke-G2LP1-PrephysicalBatch.ps1
.EXAMPLE
  .\scripts\g2\Invoke-G2LP1-PrephysicalBatch.ps1 -MatlabExe 'C:\Program Files\Polyspace\R2023a\bin\matlab.exe'
#>
[CmdletBinding()]
param(
    [string]$RepositoryRoot = '',
    [string]$MatlabExe = ''
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Resolve the script location only after parameter binding. On Windows PowerShell
# 5.1, $PSScriptRoot may be empty while default parameters are evaluated.
if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
    if ([string]::IsNullOrWhiteSpace($PSCommandPath)) {
        throw 'Cannot determine script path. Pass -RepositoryRoot explicitly.'
    }
    # Avoid Split-Path -LiteralPath/-Parent: ambiguous parameter set in Windows PowerShell 5.1.
    $scriptDirectory = [System.IO.Path]::GetDirectoryName($PSCommandPath)
    if ([string]::IsNullOrWhiteSpace($scriptDirectory)) {
        throw 'Cannot resolve script directory. Pass -RepositoryRoot explicitly.'
    }
    $RepositoryRoot = [System.IO.Path]::GetFullPath(
        [System.IO.Path]::Combine($scriptDirectory, '..', '..')
    )
}

function Require([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}
function MatlabQuote([string]$Value) { return $Value.Replace("'", "''") }
function GitText([string[]]$GitArguments) {
    $lines = & git @GitArguments 2>&1
    Require ($LASTEXITCODE -eq 0) ('Git command failed: ' + ($GitArguments -join ' '))
    return (($lines | Out-String).Trim())
}

$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
# VG1 (Issue #58): the reviewed implementation branch and the VG1 hardening branch
# stacked on it are accepted; the exact commit is recorded in the manifest.
$allowedBranches = @('research/g2-lp0-lp1-implementation-20261122','research/g2-lp1-vg1-guard-negatives-20261122')
$top = GitText -GitArguments @('-C',$root,'rev-parse','--show-toplevel')
Require ([IO.Path]::GetFullPath($top).TrimEnd('\') -ieq $root.TrimEnd('\')) 'Use the NewMetacomp repository.'
$current = GitText -GitArguments @('-C',$root,'branch','--show-current')
Require ($allowedBranches -ccontains $current) ('Wrong branch: ' + $current)
$dirty = GitText -GitArguments @('-C',$root,'status','--porcelain','--untracked-files=all')
Require ([string]::IsNullOrWhiteSpace($dirty)) ('Working tree is not clean: ' + $dirty)
$head = GitText -GitArguments @('-C',$root,'rev-parse','HEAD')
$goFile = Join-Path $root 'matlab\g2\G2_LP1_SCIENTIFIC_GO_v1.json'
Require (-not (Test-Path -LiteralPath $goFile)) 'Scientific GO exists. This script is PRE-AUTHORIZATION only.'
Require (Test-Path -LiteralPath (Join-Path $root 'matlab\g2\g2_lp1_scientific_gate.m')) 'Missing scientific gate.'
if (-not $MatlabExe) {
    foreach ($candidate in @(
        (Join-Path $env:ProgramFiles 'MATLAB\R2023a\bin\matlab.exe'),
        (Join-Path $env:ProgramFiles 'Polyspace\R2023a\bin\matlab.exe')
    )) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { $MatlabExe = $candidate; break }
    }
}
Require ($MatlabExe -and (Test-Path -LiteralPath $MatlabExe -PathType Leaf)) 'Supply -MatlabExe with full path to MATLAB R2023a bin\matlab.exe.'
$MatlabExe = (Resolve-Path -LiteralPath $MatlabExe).Path

$stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMdd_HHmmss_fff')
$out = Join-Path $root ('outputs\g2_lp1_prephysical_batch\run_' + $stamp)
New-Item -ItemType Directory -Path $out | Out-Null
$runner = Join-Path $out 'run_prephysical_tests.m'
$resultFile = Join-Path $out 'PREPHYSICAL_RESULT.json'
$contractFile = Join-Path $out 'CONTRACT_TESTS.json'
$log = Join-Path $out 'matlab_console.log'
$manifestFile = Join-Path $out 'BATCH_MANIFEST.json'
$probe = 'run_prephysical_guard_' + $stamp

# This MATLAB script lives under Git-ignored outputs, never in the source lock.
$matlabSource = @'
try
    repo = '%%REPO%%';
    resultFile = '%%RESULT%%';
    contractFile = '%%CONTRACT%%';
    probe = '%%PROBE%%';
    cd(repo);
    addpath(fullfile(repo,'matlab','g2'),'-begin');
    ram = struct('stage',{},'utc',{},'freeGiB',{});
    assert(~isfile(fullfile(repo,'matlab','g2','G2_LP1_SCIENTIFIC_GO_v1.json')), ...
        'G2Batch:UnexpectedGO','Scientific GO must be absent.');
    ram = observe(ram,'start');
    p = g2_lp0_preflight();
    assert(p.pass && strcmp(p.status,'PREFLIGHT_READY_NOT_LP0_QUALIFIED') && ...
        p.physicalSolves==0 && p.meshBuilds==0, ...
        'G2Batch:Preflight','LP0 preflight failed: %s',p.cause);
    fprintf('LP0_PREFLIGHT_PASS %s RAM_GiB=%.3f\n',p.sourceCommit,p.freePhysicalRAM_GiB);
    g = check_g2_lp0_clearance();
    assert(g.pass && g.passed==23 && g.total==23,'G2Batch:Clearance','Expected 23/23 geometry tests.');
    ids = {'H','stiff13','soft2','soft1'};
    tokens = cell(1,numel(ids));
    for i=1:numel(ids)
        ram = observe(ram,['dry_' ids{i}]);
        d = g2_lp1_run('Case',ids{i},'Run',false,'MaxStateIndex',2);
        assert(strcmp(d.status,'DRY_READY_NO_FEM') && d.computed==0 && d.lastState==-1, ...
            'G2Batch:Dry','Dry controller failed for %s',ids{i});
        tokens{i} = d.token;
        fprintf('LP1_DRY %s PASS\n',ids{i});
    end
    assert(all(strcmp(tokens,tokens{1})),'G2Batch:Dry','Dry tokens differ between cases.');
    fprintf('LP1_CURRENT_TOKEN %s\n',tokens{1});
    ram = observe(ram,'contract');
    t = check_g2_lp1_contract();
    assert(t.pass && t.passed==t.total && t.total>=20 && ...
        t.negativeTestsPassed && t.recordIntegrityPassed && ...
        isfield(t,'goFixturesPassed') && t.goFixturesPassed && t.admissionPassed && ...
        t.interfacePassed && t.exactIdentifierNegatives && ...
        t.physicalSolves==0 && t.meshBuilds==0,'G2Batch:Contract','LP1 contract failed.');
    fid=fopen(contractFile,'w');assert(fid>=0,'G2Batch:File','Cannot open contract report.');
    fwrite(fid,jsonencode(t,'PrettyPrint',true),'char');fclose(fid);
    % Two refusal probes: an invalid token and the CORRECT current token. Both must be
    % refused by the absent GO (exact identifier and message) before any folder exists.
    runRoot=fullfile(repo,'outputs','g2_lp1_matrix_paths_v1');
    before=listing(runRoot);
    probes={'INVALID_NOT_AUTHORIZED',tokens{1}};probeIds=cell(1,2);
    for j=1:2
        pf=fullfile(runRoot,[probe '_' num2str(j)]);
        assert(~isfolder(pf),'G2Batch:Probe','Guard probe path exists.');
        ram = observe(ram,sprintf('probe_%d',j));
        refused=false;probeIds{j}='<no error>';
        try
            g2_lp1_run('Case','H','Run',true,'MaxStateIndex',0, ...
                'AuthToken',probes{j},'RunName',[probe '_' num2str(j)]);
        catch ME
            probeIds{j}=ME.identifier;
            refused=strcmp(ME.identifier,'G2LP1:HOLD_UNAUTHORIZED_STATE') && ...
                contains(ME.message,'no separate GO record');
        end
        fprintf('SCIENTIFIC_GO_REFUSAL probe=%d token=%s id=%s\n',j, ...
            ternary(j==1,'invalid','current'),probeIds{j});
        assert(refused && ~isfolder(pf),'G2Batch:Guard','No-GO refusal failed for probe %d.',j);
    end
    assert(isequal(before,listing(runRoot)),'G2Batch:Guard','Run root changed during refusal probes.');
    ram = observe(ram,'end');
    r=struct('schema','NewMetacomp.G2.LP1.PrephysicalBatch.v2', ...
        'status','TESTS_PASS_SCIENTIFIC_HOLD','sourceCommit',p.sourceCommit, ...
        'release',p.release,'policySHA256',p.policySHA256, ...
        'freePhysicalRAM_GiB',p.freePhysicalRAM_GiB,'ramObservations',ram, ...
        'clearanceTestsPassed',g.passed,'clearanceTestsTotal',g.total, ...
        'contractTestsPassed',t.passed,'contractTestsTotal',t.total, ...
        'negativeTestsPassed',t.negativeTestsPassed, ...
        'recordIntegrityPassed',t.recordIntegrityPassed, ...
        'goFixturesPassed',t.goFixturesPassed,'admissionPassed',t.admissionPassed, ...
        'interfacePassed',t.interfacePassed,'exactIdentifierNegatives',t.exactIdentifierNegatives, ...
        'currentToken',tokens{1},'refusalProbeIdentifiers',{probeIds}, ...
        'goRefusedBeforeWrites',true,'dryCases',{ids}, ...
        'scientificGO',false,'physicalSolves',0,'meshBuilds',0, ...
        'evidenceRole','UNREVIEWED_CANDIDATE_NOT_AUTHORIZATION');
    fid=fopen(resultFile,'w');
    assert(fid>=0,'G2Batch:File','Cannot open report.');
    fwrite(fid,jsonencode(r,'PrettyPrint',true),'char');fclose(fid);
    fprintf('G2_LP1_PREFLIGHT_PASS NO_MESH=1 NO_FEM=1 SCIENTIFIC_HOLD=1\n');
catch ME
    fprintf(2,'G2_LP1_PREFLIGHT_FAIL %s %s\n',ME.identifier,ME.message);
    fprintf(2,'%s\n',getReport(ME,'extended','hyperlinks','off'));
    if exist('resultFile','var')
        if ~exist('ram','var'),ram=struct('stage',{},'utc',{},'freeGiB',{});end
        try,ram=observe(ram,'failure');catch,end
        r=struct('schema','NewMetacomp.G2.LP1.PrephysicalBatch.v2', ...
            'status','FAILED','errorIdentifier',ME.identifier,'message',ME.message, ...
            'ramObservations',ram,'scientificGO',false,'evidenceRole','UNREVIEWED_FAILURE');
        fid=fopen(resultFile,'w');
        if fid>=0,fwrite(fid,jsonencode(r,'PrettyPrint',true),'char');fclose(fid);end
    end
    exit(1);
end
exit(0);

function ram=observe(ram,stage)
[~,s]=memory;
ram(end+1)=struct('stage',stage,'utc',char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss.SSS''Z''')), ...
    'freeGiB',s.PhysicalMemory.Available/2^30);
fprintf('RAM_OBSERVATION %s %.6f GiB\n',stage,ram(end).freeGiB);
end
function L=listing(folder)
if ~isfolder(folder),L={};return,end
d=dir(fullfile(folder,'**','*'));L=sort(strcat({d.folder},filesep,{d.name}));
end
function y=ternary(c,a,b)
if c,y=a;else,y=b;end
end
'@
$matlabSource = $matlabSource.Replace('%%REPO%%',(MatlabQuote $root))
$matlabSource = $matlabSource.Replace('%%RESULT%%',(MatlabQuote $resultFile))
$matlabSource = $matlabSource.Replace('%%CONTRACT%%',(MatlabQuote $contractFile))
$matlabSource = $matlabSource.Replace('%%PROBE%%',(MatlabQuote $probe))
[IO.File]::WriteAllText($runner,$matlabSource,(New-Object Text.UTF8Encoding($false)))

Write-Host "Branch:   $current"
Write-Host "Commit:   $head"
Write-Host "MATLAB:   $MatlabExe"
Write-Host "Output:   $out"
Write-Host 'NO FEM / NO MESH / NO SCIENTIFIC GO'
$oldErrorActionPreference = $ErrorActionPreference
$exitCode = -1
try {
    $ErrorActionPreference = 'Continue'
    & $MatlabExe '-batch' ("run('" + (MatlabQuote $runner) + "')") 2>&1 | Tee-Object -FilePath $log
    $exitCode = $LASTEXITCODE
} finally {
    $ErrorActionPreference = $oldErrorActionPreference
}

$files=@()
foreach ($file in @($runner,$resultFile,$contractFile,$log)) {
    if (Test-Path -LiteralPath $file -PathType Leaf) {
        $files += [pscustomobject]@{
            name = (Split-Path -Path $file -Leaf)
            sha256 = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
            bytes = (Get-Item -LiteralPath $file).Length
        }
    }
}
$manifest=[ordered]@{
    schema='NewMetacomp.G2.LP1.PrephysicalBatchManifest.v2'
    sourceCommit=$head
    branch=$current
    matlabExecutable=$MatlabExe
    generatedUTC=(Get-Date).ToUniversalTime().ToString('o')
    exitCode=$exitCode
    scientificGO=$false
    files=$files
}
[IO.File]::WriteAllText($manifestFile,($manifest | ConvertTo-Json -Depth 8),(New-Object Text.UTF8Encoding($false)))
Require ($exitCode -eq 0) "MATLAB exit code $exitCode. Read $log and $resultFile. No automatic retry."
Require (Test-Path -LiteralPath $resultFile -PathType Leaf) 'MATLAB exited without JSON evidence.'
$report=Get-Content -LiteralPath $resultFile -Raw | ConvertFrom-Json
Require ($report.status -ceq 'TESTS_PASS_SCIENTIFIC_HOLD' -and
    -not $report.scientificGO -and
    $report.goRefusedBeforeWrites -and
    $report.physicalSolves -eq 0 -and
    $report.meshBuilds -eq 0) 'Unsafe or incomplete MATLAB evidence.'
Write-Host 'PASS: LP0 clearance 23/23, LP1 contract, four dry cases, GO refused.'
Write-Host 'SCIENTIFIC HOLD REMAINS. No mesh or physical solve was run.'
Write-Host "Result:   $resultFile"
Write-Host "Log:      $log"
Write-Host "Manifest: $manifestFile"
