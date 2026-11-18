function S=run_g2_wp3_kinked_audit_batch(meshRunDir,p0RunDir)
%RUN_G2_WP3_KINKED_AUDIT_BATCH  WP3.1 independent kink-aware audit of a SAVED kinked mesh (separate process).
% Reads <meshRunDir>/KINKED_GEOMETRY_ONLY_candidate.mat, the pinned JSON and
% <p0RunDir>/P010_ISOLATED_REGULAR_ONLY.mat. Runs the synthetic T6 Jacobian self-test
% and g2_kinked_mesh_auditor (the verdict). For INFORMATION ONLY it also runs the
% unchanged straight-crack 38-gate and 24-gate checkers; their failures on a kinked
% mesh are expected and are not a verdict. Writes a NEW outputs/g2_wp3_kinked_audit/run_*.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
meshMAT=fullfile(char(meshRunDir),'KINKED_GEOMETRY_ONLY_candidate.mat');
p0MAT=fullfile(char(p0RunDir),'P010_ISOLATED_REGULAR_ONLY.mat');
json=fullfile(repo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json');
assert(isfile(meshMAT)&&isfile(p0MAT)&&isfile(json),'G2KAud:Inputs','Missing audit input.');
outRoot=fullfile(repo,'outputs','g2_wp3_kinked_audit');if ~exist(outRoot,'dir'),mkdir(outRoot);end
folder=fullfile(outRoot,['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);assert(~exist(folder,'dir'));mkdir(folder);
diary(fullfile(folder,'kinked_audit_console.log'));c=onCleanup(@()diary('off')); %#ok<NASGU>
fprintf('STAGE=G2_WP3_1_INDEPENDENT_KINKED_AUDIT\nDATE=%s\nMATLAB_RELEASE=%s\nMESH_MAT=%s\nP0_MAT=%s\nOUTDIR=%s\nNO_REMESH=1; NO_FEM=1\n', ...
 datestr(now,31),version('-release'),meshMAT,p0MAT,folder);
S=struct('pass',false,'stage','HOLD_NOT_RUN','meshMAT',meshMAT,'meshSHA256','','p0MAT',p0MAT,'p0SHA256','', ...
 'jsonSHA256','','kinked',struct(),'informationOnlyStraight38',struct(),'informationOnlyStraight24',struct(),'exception','');
try
 S.meshSHA256=g2_sha256_file(meshMAT);S.p0SHA256=g2_sha256_file(p0MAT);S.jsonSHA256=g2_sha256_file(json);
 assert(check_g2_independent_t6_jacobian(),'G2KAud:JacobianSelfTest','Synthetic T6 Jacobian self-test failed.');
 D=load(meshMAT);
 C=g2_kinked_mesh_auditor(D,json,p0MAT);S.kinked=C;
 S.pass=C.pass;
 if S.pass,S.stage='WP3_1_KINKED_MESH_INDEPENDENT_PASS';else,S.stage='HOLD_WP3_1_KINKED_AUDIT';end
 fprintf('--- INFORMATION ONLY: unchanged straight-crack checkers (not a verdict) ---\n');
 try,C38=g2_independent_t6_checker(D,json);S.informationOnlyStraight38=struct('gatesPassed',C38.gatesPassed,'gatesTotal',C38.gatesTotal,'failedGates',{C38.failedGates});
 catch E1,S.informationOnlyStraight38=struct('exception',E1.message);end
 try,C24=g2_protected_tip_checker(D,json,p0MAT);S.informationOnlyStraight24=struct('gatesPassed',C24.gatesPassed,'gatesTotal',C24.gatesTotal,'failedGates',{C24.failedGates});
 catch E2,S.informationOnlyStraight24=struct('exception',E2.message);end
catch ME
 S.stage='HOLD_KINKED_AUDIT_EXCEPTION';S.exception=getReport(ME,'extended','hyperlinks','off');fprintf(2,'G2_KINKED_AUDIT_EXCEPTION=%s\n',S.exception);
end
f=fopen(fullfile(folder,'kinked_audit_summary.json'),'w');fwrite(f,jsonencode(S,'PrettyPrint',true),'char');fclose(f);
fprintf('G2_WP3_KINKED_AUDIT_STAGE=%s\nG2_WP3_KINKED_AUDIT_PASS=%d\nG2_AUDIT_LEFM_APPROVAL=0\n',S.stage,S.pass);
if ~S.pass,error('G2KAud:HOLD','Kinked audit HOLD: %s',S.stage);end
end
