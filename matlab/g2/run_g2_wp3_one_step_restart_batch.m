function W=run_g2_wp3_one_step_restart_batch(p0RunDir,manifestMAT,acceptedMeshDirA)
%RUN_G2_WP3_ONE_STEP_RESTART_BATCH  WP3.3 tests R1-R5 (WP3_PREREGISTRATION s.7). ONE step only.
% Builds state 0 (WP2 accepted straight crack, preregistered K), runs the one-step
% transaction twice (replay), restarts from the accepted state 1, and runs the
% integrity and no-second-step controls. Also compares the transaction mesh with the
% WP3.1 audited family-A mesh (acceptedMeshDirA). Writes a NEW outputs/g2_wp3_state/run_*.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
vendor=fullfile(here,'vendor_p010_a14d8872');addpath(vendor,'-begin');
p0MAT=fullfile(char(p0RunDir),'P010_ISOLATED_REGULAR_ONLY.mat');
outRoot=fullfile(repo,'outputs','g2_wp3_state');if ~exist(outRoot,'dir'),mkdir(outRoot);end
folder=fullfile(outRoot,['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);assert(~exist(folder,'dir'));mkdir(folder);
diary(fullfile(folder,'one_step_restart_console.log'));c=onCleanup(@()diary('off')); %#ok<NASGU>
fprintf('STAGE=G2_WP3_3_ONE_STEP_RESTART\nDATE=%s\nMATLAB_RELEASE=%s\nOUTDIR=%s\n',datestr(now,31),version('-release'),folder);
[~,head]=system(sprintf('git -C "%s" rev-parse HEAD',repo));fprintf('GIT_HEAD=%s\n',strtrim(head));
W=struct('pass',false,'tests',struct(),'exception','');tok={'Authorize','ONE_IDEALIZED_DEMO_STEP'};
try
 % ---- state 0
 Mf=load(manifestMAT,'Mf');Mf=Mf.Mf;
 ev=jsondecode(fileread(fullfile(here,'evidence','wp2_20261118','cornell_run_20261118_170047_650','cornell_sif_summary.json')));
 kf=[ev.result_per_kN.familyA_KI_MPa_sqrt_m,ev.result_per_kN.familyA_KII_MPa_sqrt_m];
 assert(all(abs(round(kf*1e6)/1e6-[.166436 .018827])<1e-12),'G2W3:State0K','WP2 evidence K does not round to the preregistered values.');
 S0=struct('schema','NewMetacomp.G2.WP3.CrackState.v1','stateIndex',0,'parentStateSHA256','', ...
  'crackPolyline_mm',[101.6 0;101.6 25.4],'tip_mm',[101.6 25.4],'t',[0 1],'n',[-1 0],'DeltaA_mm',4, ...
  'KI_MPa_sqrt_m_per_kN',.166436,'KII_MPa_sqrt_m_per_kN',.018827,'KI_fullPrecisionWP2',kf(1),'KII_fullPrecisionWP2',kf(2), ...
  'Ksource','PR #23 513044cc, SIF_WP2_RESULTS.md family A plane stress; six-digit values are the preregistered forecast inputs', ...
  'bvp',struct('E_MPa',3268.115,'nu',.35,'plane','stress','P_N',1,'thickness_mm',12.7,'pin_mm',[25.4 0],'roller_mm',[482.6 0],'load_mm',[254 203.2]), ...
  'idealized_propagation_demo',true,'physical_onset',false,'created',datestr(now,31));
 h0=g2_wp3_state_io('save',fullfile(folder,'state0'),S0);fprintf('STATE0_SHA256=%s\n',h0);
 % ---- transaction (accepted) and replay
 T1=g2_wp3_one_step(fullfile(folder,'state0'),fullfile(folder,'step1_a'),p0MAT,tok{:});
 fprintf('STEP1_A=%s audit %s\n',T1.status,T1.detail.auditGates);
 assert(strcmp(T1.status,'ACCEPTED_ONE_IDEALIZED_DEMO_STEP'),'G2W3:Step','Transaction HOLD: %s',T1.status);
 T2=g2_wp3_one_step(fullfile(folder,'state0'),fullfile(folder,'step1_b'),p0MAT,tok{:});
 fprintf('STEP1_B=%s\n',T2.status);
 A=load(fullfile(folder,'step1_a','KINKED_GEOMETRY_ONLY_candidate.mat'));B=load(fullfile(folder,'step1_b','KINKED_GEOMETRY_ONLY_candidate.mat'));
 Wa=load(fullfile(char(acceptedMeshDirA),'KINKED_GEOMETRY_ONLY_candidate.mat'),'X3','T3','upperBankT6','lowerBankT6');
 [Sa,~,~]=g2_wp3_state_io('load',fullfile(folder,'step1_a','state'));[Sb,~,~]=g2_wp3_state_io('load',fullfile(folder,'step1_b','state'));
 kd=max(abs([Sa.KI_raw-Sb.KI_raw,Sa.KII_raw-Sb.KII_raw]))/hypot(Sa.KI_raw,Sa.KII_raw);
 sameAB=isequal(A.X3,B.X3)&&isequal(A.T3,B.T3)&&isequal(A.upperBankT6,B.upperBankT6)&&isequal(A.lowerBankT6,B.lowerBankT6);
 sameWP31=isequal(A.X3,Wa.X3)&&isequal(A.T3,Wa.T3)&&isequal(A.upperBankT6,Wa.upperBankT6)&&isequal(A.lowerBankT6,Wa.lowerBankT6);
 W.tests.R1=struct('status',T2.status,'meshArraysAndBanksIdentical',sameAB,'K_relDiff',kd,'identicalToWP31AuditedMesh',sameWP31, ...
  'pass',strcmp(T2.status,'ACCEPTED_ONE_IDEALIZED_DEMO_STEP')&&sameAB&&kd<=1e-12);
 fprintf('R1 replay: arrays identical %d, K diff %.3e, identical to WP3.1 mesh %d -> %d\n',sameAB,kd,sameWP31,W.tests.R1.pass);
 % ---- R2 restart
 Rs=g2_wp3_restart(fullfile(folder,'step1_a'));
 W.tests.R2=struct('status',Rs.status,'KI_relDiff',Rs.KI_relDiff,'KII_relDiff',Rs.KII_relDiff,'nextForecast',Rs.nextForecast, ...
  'pass',strcmp(Rs.status,'RESTART_VERIFIED')&&~Rs.nextForecast.executed);
 fprintf('R2 restart: %s, dK %.3e/%.3e, next forecast %.6f deg (NOT executed)\n',Rs.status,Rs.KI_relDiff,Rs.KII_relDiff,Rs.nextForecast.theta_deg);
 % ---- R3 integrity controls (copies only)
 bad=fullfile(folder,'R3_corrupt_copy');copyfile(fullfile(folder,'step1_a'),bad);
 fn=fullfile(bad,'state','state.mat');fid=fopen(fn,'r+');fseek(fid,-200,'eof');by=fread(fid,1,'*uint8');fseek(fid,-200,'eof');fwrite(fid,bitxor(by,uint8(1)));fclose(fid);
 Rb=g2_wp3_restart(bad);
 bad2=fullfile(folder,'R3_wrong_hash_copy');copyfile(fullfile(folder,'step1_a'),bad2);
 fid=fopen(fullfile(bad2,'state','state.sha256'),'w');fprintf(fid,'%s *state.mat\n',repmat('0',1,64));fclose(fid);
 Rc=g2_wp3_restart(bad2);
 Tc=g2_wp3_one_step(fullfile(bad2,'state'),fullfile(folder,'R3_should_not_exist'),p0MAT,tok{:});
 W.tests.R3=struct('byteFlipRestart',Rb.status,'wrongHashRestart',Rc.status,'wrongHashTransaction',Tc.status, ...
  'pass',strcmp(Rb.status,'HOLD_STATE_INTEGRITY')&&strcmp(Rc.status,'HOLD_STATE_INTEGRITY')&&strcmp(Tc.status,'HOLD_STATE_INTEGRITY')&& ...
  ~exist(fullfile(folder,'R3_should_not_exist'),'dir'));
 fprintf('R3 integrity: byte flip %s, wrong hash %s, transaction %s -> %d\n',Rb.status,Rc.status,Tc.status,W.tests.R3.pass);
 % ---- R4 frame consistency
 t1=Mf.trial.t(:).';
 W.tests.R4=struct('tError',norm(Sa.t-t1),'tipError',norm(Sa.tip_mm-Mf.trial.tip_mm(:).'),'KI',Sa.KI_MPa_sqrt_m_per_kN, ...
  'pass',norm(Sa.t-t1)<=1e-12&&Sa.KI_MPa_sqrt_m_per_kN>0);
 fprintf('R4 frame: |t-t1| %.3e, |tip-tip1| %.3e, KI %.6f -> %d\n',W.tests.R4.tError,W.tests.R4.tipError,Sa.KI_MPa_sqrt_m_per_kN,W.tests.R4.pass);
 % ---- R5 no second step
 T5=g2_wp3_one_step(fullfile(folder,'step1_a','state'),fullfile(folder,'R5_should_not_exist'),p0MAT,tok{:});
 T6n=g2_wp3_one_step(fullfile(folder,'state0'),fullfile(folder,'R5_no_token'),p0MAT);
 W.tests.R5=struct('secondStep',T5.status,'noToken',T6n.status,'pass',strcmp(T5.status,'HOLD_SECOND_STEP_NOT_AUTHORIZED')&& ...
  strcmp(T6n.status,'HOLD_NOT_AUTHORIZED')&&~exist(fullfile(folder,'R5_should_not_exist'),'dir')&&~exist(fullfile(folder,'R5_no_token'),'dir'));
 fprintf('R5: second step %s, no token %s -> %d\n',T5.status,T6n.status,W.tests.R5.pass);
 W.accepted=struct('state1SHA256',T1.childHash,'state0SHA256',h0,'meshSHA256',T1.detail.meshSHA256, ...
  'KI_MPa_sqrt_m_per_kN',Sa.KI_MPa_sqrt_m_per_kN,'KII_MPa_sqrt_m_per_kN',Sa.KII_MPa_sqrt_m_per_kN, ...
  'KI_COD',Sa.KI_COD_MPa_sqrt_m_per_kN,'KII_COD',Sa.KII_COD_MPa_sqrt_m_per_kN,'tip_mm',Sa.tip_mm,'t',Sa.t, ...
  'idealized_propagation_demo',Sa.idealized_propagation_demo,'physical_onset',Sa.physical_onset);
 W.pass=W.tests.R1.pass&&W.tests.R2.pass&&W.tests.R3.pass&&W.tests.R4.pass&&W.tests.R5.pass;
catch ME
 W.exception=getReport(ME,'extended','hyperlinks','off');fprintf(2,'G2_WP3_STATE_EXCEPTION=%s\n',W.exception);
end
f=fopen(fullfile(folder,'one_step_restart_summary.json'),'w');fwrite(f,jsonencode(W,'PrettyPrint',true),'char');fclose(f);
fprintf('G2_WP3_3_ONE_STEP_RESTART_PASS=%d\nNO_SECOND_STEP=1; PHYSICAL_ONSET=0\n',W.pass);
if ~W.pass,error('G2W3:HOLD','WP3.3 HOLD (see %s).',folder);end
end
