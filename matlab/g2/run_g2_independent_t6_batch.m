function C = run_g2_independent_t6_batch(sourceRunDir)
%RUN_G2_INDEPENDENT_T6_BATCH Read-only verification of saved Cornell T6 mesh.
%
% MATLAB R2023a:
%  run_g2_independent_t6_batch('C:\...\run_20261116_214346_310')
%
% Reads the original author's GEOMETRY_ONLY_candidate.mat and pinned JSON.
% Does NOT re-mesh, write in the original output directory, solve, calculate
% SIF, EDI, COD, J, or advance cracks. Writes NEW independent audit evidence.
if nargin~=1 || ~(ischar(sourceRunDir)||isstring(sourceRunDir))
 error('G2Independent:Usage','Pass the exact existing G2 run directory.');
end
sourceRunDir=char(sourceRunDir);
assert(isfolder(sourceRunDir),'G2Independent:MissingRun', ...
 'Original G2 run directory not found: %s',sourceRunDir);
matFile=fullfile(sourceRunDir,'GEOMETRY_ONLY_candidate.mat');
assert(isfile(matFile),'G2Independent:MissingCandidate', ...
 'The original run is not a successful candidate; missing MAT: %s',matFile);
here=fileparts(mfilename('fullpath'));
repoRoot=fileparts(fileparts(here));
geometryFile=fullfile(repoRoot,'docs','research', ...
    'crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json');
assert(isfile(geometryFile),'G2Independent:MissingSource', ...
 'Pinned Cornell geometry JSON is required.');
outRoot=fullfile(repoRoot,'outputs','g2_independent_t6');
if ~exist(outRoot,'dir'),mkdir(outRoot);end
folder=fullfile(outRoot,['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);
assert(~exist(folder,'dir'),'G2Independent:ExistingOutput', ...
 'Cannot overwrite independent audit directory.');
mkdir(folder);
diaryFile=fullfile(folder,'independent_t6_console.log');
diary(diaryFile);
cleanup=onCleanup(@()diary('off')); %#ok<NASGU>
fprintf('G2_INDEPENDENT_AUDIT_STAGE=START\n');
fprintf('G2_INDEPENDENT_SOURCE_RUN=%s\n',sourceRunDir);
fprintf('G2_INDEPENDENT_SOURCE_MAT=%s\n',matFile);
fprintf('G2_INDEPENDENT_SOURCE_JSON=%s\n',geometryFile);
fprintf('G2_INDEPENDENT_OUTDIR=%s\n',folder);
fprintf('G2_INDEPENDENT_MATLAB_RELEASE=%s\n',version('-release'));
fprintf('G2_INDEPENDENT_NO_REMESH=1\n');
fprintf('G2_INDEPENDENT_NO_FEM=1\n');
summary=struct('pass',false,'stage','HOLD_NOT_RUN', ...
    'sourceRunDir',sourceRunDir,'sourceMAT',matFile, ...
    'sourceJSON',geometryFile,'outputDir',folder, ...
    'checkedOn',datestr(now,31),'MATLABRelease',version('-release'), ...
    'approvedForLEFM',false, 'independentT6',struct(), ...
    'error','');
C=struct('pass',false,'stage','NOT_RUN');
try
    selfCheck=check_g2_independent_t6_jacobian();
    assert(selfCheck,'G2Independent:JacobianSelfCheck', ...
        'Synthetic independent T6 Jacobian preflight failed.');
    summary.syntheticT6JacobianPreflightPassed=true;
    S=load(matFile);
    C=g2_independent_t6_checker(S,geometryFile);
    summary.pass=C.pass;
    summary.stage=C.stage;
    summary.independentT6=C;
    if C.pass
        fprintf('G2_INDEPENDENT_T6_GEOMETRY_ACCEPTED=1\n');
    else
        fprintf(2,'G2_INDEPENDENT_T6_GEOMETRY_ACCEPTED=0\n');
        fprintf(2,'G2_INDEPENDENT_T6_FAILED_GATES=%s\n', ...
            strjoin(C.failedGates,','));
    end
catch ME
    summary.stage='HOLD_INDEPENDENT_T6_EXCEPTION';
    summary.pass=false;
    summary.error=getReport(ME,'extended','hyperlinks','off');
    fprintf(2,'G2_INDEPENDENT_EXCEPTION=%s\n',summary.error);
end
reportFile=fullfile(folder,'independent_t6_summary.json');
fid=fopen(reportFile,'w');
assert(fid>=0,'G2Independent:CannotWrite', ...
 'Cannot create independent T6 report: %s',reportFile);
fwrite(fid,jsonencode(summary,'PrettyPrint',true),'char');
fclose(fid);
fprintf('G2_INDEPENDENT_REPORT_JSON=%s\n',reportFile);
if ~summary.pass
 error('G2Independent:GeometryHOLD', ...
     'Independent T6 geometry checker failed. Review %s',reportFile);
end
fprintf('G2_INDEPENDENT_T6_DONE=1; P010_PROTECTED_CORE_PENDING=1; NO_LEFM=1\n');
end
