function S=run_g2_protected_audit_batch(meshRunDir,p0RunDir)
%RUN_G2_PROTECTED_AUDIT_BATCH  WP1 independent audits of a SAVED protected mesh.
% Separate MATLAB process from the mesher. Reads <meshRunDir>/GEOMETRY_ONLY_candidate.mat,
% the pinned Cornell JSON and <p0RunDir>/P010_ISOLATED_REGULAR_ONLY.mat, then runs
%  (a) the synthetic T6 Jacobian self-test and the UNCHANGED 38-gate
%      g2_independent_t6_checker (the checker that passed the unprotected candidate);
%  (b) g2_protected_tip_checker (protected p010 conditions).
% Writes a NEW outputs/g2_protected_audit/run_* folder. No remeshing, no FEM.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
meshMAT=fullfile(char(meshRunDir),'GEOMETRY_ONLY_candidate.mat');
p0MAT=fullfile(char(p0RunDir),'P010_ISOLATED_REGULAR_ONLY.mat');
json=fullfile(repo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json');
assert(isfile(meshMAT)&&isfile(p0MAT)&&isfile(json),'G2Audit:Inputs','Missing audit input.');
outRoot=fullfile(repo,'outputs','g2_protected_audit');
if ~exist(outRoot,'dir'),mkdir(outRoot);end
folder=fullfile(outRoot,['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);
assert(~exist(folder,'dir'),'G2Audit:Collision','Refusing to overwrite %s',folder);
mkdir(folder);diary(fullfile(folder,'audit_console.log'));c=onCleanup(@()diary('off')); %#ok<NASGU>
fprintf('STAGE=G2_WP1_INDEPENDENT_AUDIT\nDATE=%s\nMATLAB_RELEASE=%s\n',datestr(now,31),version('-release'));
fprintf('MESH_MAT=%s\nP0_MAT=%s\nOUTDIR=%s\nNO_REMESH=1; NO_FEM=1\n',meshMAT,p0MAT,folder);
S=struct('pass',false,'stage','HOLD_NOT_RUN','meshMAT',meshMAT,'p0MAT',p0MAT,'outputDirectory',folder, ...
 'MATLABRelease',version('-release'),'approvedForLEFM',false,'independentT6',struct(),'protectedTip',struct(), ...
 'exception','');
try
 assert(check_g2_independent_t6_jacobian(),'G2Audit:JacobianSelfTest','Synthetic T6 Jacobian self-test failed.');
 D=load(meshMAT);
 C38=g2_independent_t6_checker(D,json);
 CP=g2_protected_tip_checker(D,json,p0MAT);
 S.independentT6=C38;S.protectedTip=CP;
 S.pass=C38.pass&&CP.pass;
 if S.pass,S.stage='WP1_PROTECTED_MESH_INDEPENDENT_PASS';else,S.stage='HOLD_WP1_INDEPENDENT_AUDIT';end
 fprintf('G2_AUDIT_38_GATES=%d/%d\nG2_AUDIT_PROTECTED_GATES=%d/%d\n',C38.gatesPassed,C38.gatesTotal,CP.gatesPassed,CP.gatesTotal);
catch ME
 S.stage='HOLD_AUDIT_EXCEPTION';S.exception=getReport(ME,'extended','hyperlinks','off');
 fprintf(2,'G2_AUDIT_EXCEPTION=%s\n',S.exception);
end
f=fopen(fullfile(folder,'protected_audit_summary.json'),'w');
fwrite(f,jsonencode(S,'PrettyPrint',true),'char');fclose(f);
fprintf('G2_AUDIT_SUMMARY=%s\nG2_AUDIT_PASS=%d\nG2_AUDIT_LEFM_APPROVAL=0\n',fullfile(folder,'protected_audit_summary.json'),S.pass);
if ~S.pass,error('G2Audit:HOLD','Independent WP1 audit HOLD: %s',S.stage);end
end
