function T=g2_lp2b1s10_tests(varargin)
%G2_LP2B1S10_TESTS  Focused zero-FEM readiness qualification of the prospective LP2-B1-S10 controller (no physical solve).
% Real archived records are READ only; every write goes to a fresh folder under tempdir; no GO is created in the
% repository; g2_m4b_sif_partial is never called (driver tests inject non-solving operations; the default solve of the
% test contexts is a sentinel that fails the test).
%  A  context, pins, token, no GO, roots absent, real-preflight correct-token refusal, preflight bypass, invariants
%  B  target qualification (real) and mutations of parent / failed-mesh / terminal / tip / guide-gap pins
%  D  canonical digest of the qualification and repeat arrays
%  G  driver with injected operations: GO, receipt, one attempt, ledger ADMIT, historical root, memory, target failure,
%     test-injection refusal; REAL geometry with a mismatching digest (HOLD before FEM); REAL geometry + fabricated
%     non-solving K (synthetic accepted closure, STATE, TERMINAL, verifier); failed gates, negative KI, S11 forecast
%     failure, pre-solve memory HOLD (cached real geometry, injected)
%  H  GO validator (pure)      I  real git through system() on inert fixtures      M  memory gate
%  J  read-only verifier: positive control, extra / missing / tampered records, ledger defects, unchanged files
%  Z  sentinel never called, repository roots still absent
ip=inputParser;addParameter(ip,'RealGeometry',true,@islogical);addParameter(ip,'RealGit',true,@islogical);addParameter(ip,'OutFile','',@ischar);parse(ip,varargin{:});o=ip.Results;
if ~isempty(o.OutFile),assert(~isfile(o.OutFile),'B1S10T:Overwrite','Test output exists; tests are never overwritten.');end
T0=tic;R={};
C=g2_lp2b1s10_context('Preflight',false);pol=C.policy;au=pol.authorization;
% ---------------------------------------------------------------- A (A0 first: fresh MATLAB for the real preflight)
R{end+1}=t('A0_no_GO_correct_token_refused_real_preflight',refuses(@()g2_lp2b1s10_run('Run',true,'Token',C.token),'G2LP2B1S10:HOLD_UNAUTHORIZED')&&rootsAbsent(C));
R{end+1}=t('A1_token_status_no_GO',startsWith(C.token,'G2LP2B1S10|policy=')&&contains(C.token,'|case=soft1|state=S10|admissions=1|seed=0.40|')&& ...
 strcmp(pol.status,'PROPOSED_NOT_AUTHORIZED')&&~isfile(C.goFile)&&isequal(au.goPresent,false));
R{end+1}=t('A2_run_receipt_summary_absent',rootsAbsent(C));
tg=pol.target;
R{end+1}=t('A3_single_target_one_attempt_seed040',strcmp(tg.caseId,'soft1')&&tg.stateIndex==10&&isequal(reshape(tg.mask,1,3),[1 0 0])&&tg.ratio==0.5&&tg.arc_mm==65.4&& ...
 tg.admissions==1&&tg.physicalSolves==1&&tg.attempts==1&&~tg.retry&&~tg.resumption&&~tg.fallback&&pol.meshFamily.seedSpacing_mm==0.40);
R{end+1}=t('A4_preflight_bypass_refused',refuses(@()g2_lp2b1s10_run('Run',true,'Preflight',false,'Token',C.token),'G2LP2B1S10:HOLD_PREFLIGHT_REQUIRED'));
hr=cellstr(pol.historicalRoots);
R{end+1}=t('A5_historical_roots_include_EQ_exclude_new',any(strcmp(hr,'outputs/g2_lp2b1_eq_v1'))&&any(strcmp(hr,'outputs/g2_lp2b1_eq_receipts'))&&any(strcmp(hr,'outputs/g2_lp2a3_paths_v1'))&& ...
 any(strcmp(hr,'outputs/g2_lp2a3_campaign_ledger'))&&~any(contains(hr,'g2_lp2b1_s10'))&&~any(contains(hr,'g2_lp2b1s10')));
ex=pol.meshFamily.expected;
R{end+1}=t('A6_expected_quality_and_limits_unchanged',ex.T3==30357&&ex.minAngle_deg==23.179107436795395&&ex.maxNeighborRatio==1.6015350873084404&&ex.limits.minAngle_deg==20&& ...
 ex.limits.maxNeighborRatio==1.8&&ex.limits.maxT3==40000&&isequal(reshape(ex.chordsPerCircle,1,3),[76 76 76])&&ex.qActiveT6Parents==2443&&pol.ringProximityGuard.minGap_mm==1&& ...
 strcmp(pol.qualification.canonicalSHA256,'54293d2a527f9bec33605ffea10c8f56af46a56291157f0d911cf68301b85bd2')&&strcmp(pol.qualification.arrays.sha256,'086b6671a733bafad3874dee8d50c84bc52e6bfaa6ba0174caae09995c2f2a88'));
eo=pol.b1eqEvidence.outputs;if ~iscell(eo),eo=num2cell(eo);end
R{end+1}=t('A7_EQ_campaign_evidence_23_outputs_archive',numel(eo)==23&&strcmp(pol.b1eqEvidence.archiveSHA256,'1d739f80fe77597e3749de7e939abf8f572bc48f27bb703c28d02f94634d6e8a')&& ...
 strcmp(pol.policyPins.lp2b1eq.sha256,'b113a7c6d7b2e8fe9950d817ccca3c851c05f1e347c73f66c604b9c41e54eecb')&&strcmp(pol.sourcePins.lp2b1eqSourceSHA256,'74a0edd827daca5714a1347705abc1429a7a573116ad3c438f9e5a1c12dfbf1f'));
R{end+1}=t('A8_parent_pins_issue',strcmp(pol.parent.STATE.record.sha256,'79ebecbc21b4d9425e3a2b82a9bc17270373a85f2a7c26d11cfe1e7c9b45aec6')&& ...
 strcmp(pol.parent.MESH.sha256,'5afd6e8199ca797ced1a73ba7584c29334abdad7d2413d1bc39a2e0385d1eae0')&&strcmp(pol.parent.PHASE.record.sha256,'fe0ad27f471d052153edbebe6ecf39e525021f5051c4572b97e3f89907f0c83e')&& ...
 strcmp(pol.parent.SOLUTION.record.sha256,'ae981011e8092115037b0ae910cd92d2e7e352b2fcb88677425dfd564abcc54b')&&strcmp(pol.failedA3S10.TERMINAL.record.sha256,'8f0289fdd4f9c665fb1666d50aa0a1a3126210cc5f05b70e048d9616328761e7')&& ...
 strcmp(pol.failedA3S10.FAILED_MESH.sha256,'ab54ecaf0ff41bb7cd16cff0eb62c29cb9104d56490201337367bca6b54b8e12')&&strcmp(pol.failedA3S10.HOLD.record.sha256,'dc4043f300dd459fceb4280022f8f1d2e1130c859ee8bb3b0d0a480e9d909ba0'));
R{end+1}=t('A9_forbidden_names_include_A3_and_EQ',any(strcmp(cellstr(au.forbiddenRunNames),'run_lp2a3_s9_s11_v1'))&&any(strcmp(cellstr(au.forbiddenRunNames),'run_lp2b1_eq_v1'))&& ...
 any(strcmp(cellstr(au.forbiddenCampaignIds),'G2-LP2A3-001'))&&any(strcmp(cellstr(au.forbiddenCampaignIds),'G2-LP2B1-EQ-001')));
% ---------------------------------------------------------------- B target qualification
Tq=g2_lp2b1s10_target(C);
R{end+1}=t('B1_target_qualification_all_checks',Tq.pass&&numel(fieldnames(Tq.checks))==10);
R{end+1}=t('B2_tip_bitwise_S10_arc_65p4',isequal(Tq.forecast.polyline_mm(end,:),[114.29544883822506 63.18559491151613])&&Tq.forecast.stateIndex==10&&abs(Tq.forecast.arc_mm-65.4)<=1e-9);
R{end+1}=t('B3_guide_gap_matlab_bitwise_issue_within_1e12',isequal(Tq.info.nominal.guideRingGap_mm(1),4.6329563816383335)&&abs(Tq.info.nominal.gapMinusIssueValue_mm)<=1e-12);
R{end+1}=t('B4_independent_MTS_and_recurrence',abs(Tq.info.mts.diff_rad)<=4*eps(abs(Tq.info.mts.theta_deg*pi/180))&&Tq.info.forecast.independentTipDiff_mm<=1e-12);
R{end+1}=t('B5_shifted_EQ_predictor_not_used',Tq.checks.notShiftedEq);
R{end+1}=t('B6_failed_mesh_is_baseline_same_polyline',isequal(Tq.failedMesh.crackPolyline,Tq.forecast.polyline_mm)&&size(Tq.failedMesh.T3,1)==30387);
Cb=C;Cb.policy.parent.STATE.record.sha256=repmat('0',1,64);X=g2_lp2b1s10_target(Cb);R{end+1}=t('B7_wrong_parent_pin_fails',~X.pass&&~X.checks.parentRecords);
Cb=C;Cb.policy.failedA3S10.FAILED_MESH.sha256=repmat('0',1,64);X=g2_lp2b1s10_target(Cb);R{end+1}=t('B8_wrong_failed_mesh_pin_fails',~X.pass&&~X.checks.failedMesh&&X.checks.parentRecords);
Cb=C;Cb.policy.target.expectedTip_mm=[114.2954484554881 63.1855950991163];X=g2_lp2b1s10_target(Cb);R{end+1}=t('B9_shifted_EQ_tip_as_target_fails',~X.pass&&~X.checks.forecast);
Cb=C;Cb.policy.failedA3S10.TERMINAL.record.sha256=repmat('0',1,64);X=g2_lp2b1s10_target(Cb);R{end+1}=t('B10_wrong_terminal_pin_fails',~X.pass&&~X.checks.terminal);
Cb=C;Cb.policy.target.ring1GuideGap_mm.issueValue=4.632956381638341+2e-12;X=g2_lp2b1s10_target(Cb);R{end+1}=t('B11_guide_gap_issue_value_beyond_1e12_fails',~X.pass&&~X.checks.nominalClearance);
Cb=C;Cb.policy.parent.grandparentS8.sha256=repmat('0',1,64);X=g2_lp2b1s10_target(Cb);R{end+1}=t('B12_wrong_grandparent_link_fails',~X.pass&&~X.checks.parentIdentity);
% ---------------------------------------------------------------- D canonical digest
Qa=load(fullfile(C.repo,strrep(pol.qualification.arrays.path,'/',filesep)));Qr=load(fullfile(C.repo,strrep(pol.qualification.repeatArrays.path,'/',filesep)));
R{end+1}=t('D1_qualification_canonical_equals_pin',strcmp(g2_lp2b1eq_canon(Qa),pol.qualification.canonicalSHA256)&&size(Qa.T3,1)==30357);
R{end+1}=t('D2_repeat_arrays_canonical_equal',strcmp(g2_lp2b1eq_canon(Qr),pol.qualification.canonicalSHA256));
[~,mq]=g2_lp2b1eq_canon(Qa);[~,mr]=g2_lp2b1eq_canon(Qr);R{end+1}=t('D3_metadata_digest_repeat_equal',strcmp(mq,mr));
% ---------------------------------------------------------------- M memory gate
mg=@(v)g2_lp2a2_eq_memgate(7,v);
R{end+1}=t('M1_exactly_7_passes',mg(@()7).pass);R{end+1}=t('M2_below_refuses',~mg(@()6.999).pass);R{end+1}=t('M3_nan_refuses',~mg(@()NaN).pass);
% ---------------------------------------------------------------- G driver with injected operations
root=fullfile(tempdir,sprintf('lp2b1s10_t_%s',datestr(now,'yyyymmddHHMMSSFFF')));mkdir(root);
cnt=containers.Map({'solve','mem','sentinel','geom'},{0,0,0,0});
okGate=@(C,tok)struct('pass',true,'approvedHead',repmat('a',1,40),'goFileSHA256',repmat('b',1,64));
memOK=@(m)bumpMem(cnt,m,true);memNo=@(m)bumpMem(cnt,m,false);sentinel=@(varargin)sentinelSolve(cnt);tgtC=@(C)Tq;
G=struct('notRun',true);
R{end+1}=t('G1_no_GO_refused_real_gate',refuses(@()g2_lp2b1s10_run('Run',true,'Token',C.token,'Test',tt(mk('g1',false),struct())),'G2LP2B1S10:HOLD_UNAUTHORIZED')&&~isfolder(fullfile(root,'g1','run')));
Cg=mk('g2',false);wf(Cg.goFile,jsonencode(struct('decision','GO_LP2B1_S10','fixture','INERT_NOT_AN_AUTHORIZATION','approvedHead',repmat('a',1,40))));
R{end+1}=t('G2_inert_GO_file_without_binding_refused',refuses(@()g2_lp2b1s10_run('Run',true,'Token',C.token,'Test',tt(Cg,struct())),'G2LP2B1S10:HOLD_UNAUTHORIZED')&&~isfolder(Cg.runRoot));
R{end+1}=t('G3_no_receipt_refused',refuses(@()g2_lp2b1s10_run('Run',true,'Token',C.token,'Test',tt(mk('g3',false),struct('gate',okGate))),'G2LP2B1S10:HOLD_NO_RECEIPT'));
Cw=mk('g4',false);g2_lp1_campaign_ledger('write',Cw.receiptRoot,'RECEIPT','RECEIPT.mat',struct('campaignId',pol.campaignId,'token','WRONG'));
R{end+1}=t('G4_receipt_other_token_refused',refuses(@()g2_lp2b1s10_run('Run',true,'Token',C.token,'Test',tt(Cw,struct('gate',okGate))),'G2LP2B1S10:HOLD_NO_RECEIPT'));
Ca=mk('g5',true);g2_lp1_campaign_ledger('write',Ca.receiptRoot,'ADMIT','ADMIT_soft1_S10.mat',struct('campaignId',pol.campaignId,'stateKey','soft1_S10','caseId','soft1','stateIndex',10));
R{end+1}=t('G5_existing_ledger_ADMIT_refused_one_attempt',refuses(@()g2_lp2b1s10_run('Run',true,'Token',C.token,'Test',tt(Ca,struct('gate',okGate,'memgate',memOK))),'G2LP2B1S10:HOLD_ONE_ATTEMPT')&&~isfolder(Ca.runRoot));
Cf=mk('g6',true);mkdir(fullfile(Cf.runRoot,'soft1'));
R{end+1}=t('G6_existing_case_folder_refused_one_attempt',refuses(@()g2_lp2b1s10_run('Run',true,'Token',C.token,'Test',tt(Cf,struct('gate',okGate,'memgate',memOK))),'G2LP2B1S10:HOLD_ONE_ATTEMPT'));
Ch=mk('g7',true);Ch.historicalRoots{end+1}=fileparts(Ch.runRoot);
R{end+1}=t('G7_historical_root_refused',refuses(@()g2_lp2b1s10_run('Run',true,'Token',C.token,'Test',tt(Ch,struct('gate',okGate))),'G2LP2B1S10:HOLD_HISTORICAL_ROOT')&&~isfolder(Ch.runRoot));
Cm=mk('g8',true);
R{end+1}=t('G8_memory_refusal_before_folder_and_admission',refuses(@()g2_lp2b1s10_run('Run',true,'Token',C.token,'Test',tt(Cm,struct('gate',okGate,'memgate',memNo,'target',tgtC))),'G2LP2B1S10:HOLD_MEMORY')&& ...
 ~isfolder(fullfile(Cm.runRoot,'soft1'))&&isempty(g2_lp1_campaign_ledger('snapshot',Cm.receiptRoot).admits));
Ct=mk('g9',true);badT=Tq;badT.pass=false;badT.failed={'forecast'};
R{end+1}=t('G9_target_failure_HOLD_before_folder',refuses(@()g2_lp2b1s10_run('Run',true,'Token',C.token,'Test',tt(Ct,struct('gate',okGate,'memgate',memOK,'target',@(C)badT))),'G2LP2B1S10:HOLD_TARGET')&&~isfolder(Ct.runRoot));
R{end+1}=t('G10_injection_outside_tempdir_refused',refuses(@()g2_lp2b1s10_run('Test',struct('root',C.repo,'context',mk('g10',false))),'G2LP2B1S10:HOLD_TEST_INJECTION'));
Cx=mk('g11',false);Cx.runRoot=fullfile(C.repo,'outputs','g2_lp2b1_s10_v1','x');
R{end+1}=t('G11_test_roots_outside_test_root_refused',refuses(@()g2_lp2b1s10_run('Test',tt(Cx,struct())),'G2LP2B1S10:HOLD_TEST_INJECTION'));
Cr=mk('g12',false);R{end+1}=t('G12_replay_root_inside_run_root_refused',refuses(@()g2_lp2b1s10_run('Mesh',true,'ReplayRoot',fullfile(Cr.runRoot,'r'),'Test',tt(Cr,struct('target',tgtC))),'G2LP2B1S10:HOLD_INPUT'));
Jr=struct('notRun',true);
if o.RealGeometry
 Cd=mk('g13',true);Cd.policy.qualification.canonicalSHA256=repmat('0',1,64);s0=cnt('solve');sd=fullfile(Cd.runRoot,'soft1','S10');
 R{end+1}=t('G13_real_geometry_digest_mismatch_HOLD_before_FEM',refuses(@()g2_lp2b1s10_run('Run',true,'Token',C.token,'Test',tt(Cd,struct('gate',okGate,'memgate',memOK,'target',tgtC))),'G2LP2B1S10:HOLD_MESH_QUALIFICATION')&& ...
  cnt('solve')==s0&&cnt('sentinel')==0&&isfile(fullfile(sd,'HOLD.json'))&&~isfile(fullfile(sd,'MESH.mat'))&&isfile(fullfile(sd,'GEOMETRY_h040','ATTEMPT.json'))&& ...
  isequal(g2_lp1_campaign_ledger('snapshot',Cd.receiptRoot).admits,{'soft1_S10'}));
 Hd=jsondecode(fileread(fullfile(sd,'HOLD.json')));At=jsondecode(fileread(fullfile(sd,'GEOMETRY_h040','ATTEMPT.json')));
 R{end+1}=t('G13b_hold_stage_geometry_attempt_19_real_digest',strcmp(Hd.stage,'GEOMETRY')&&At.checksPassed==19&&strcmp(At.canonicalSHA256,pol.qualification.canonicalSHA256)&&At.T3==30357);
 Vd=g2_lp2b1s10_verify(Cd);R{end+1}=t('G13c_verifier_partial_hold',strcmp(Vd.outcome,'VERIFIED_PARTIAL_HOLD')&&Vd.unchanged);
 % synthetic accepted closure with REAL geometry and a fabricated NON-SOLVING K
 Cs=mk('g14',true);GC=containers.Map('KeyType','char','ValueType','any');geoC=@(C,s,Ref,od)cachedGeometry(C,s,Ref,od,GC,cnt);
 fk=@(D,act,mats,polT,PM,expect)fakeK(D,act,mats,expect,Tq,pol,cnt,'ok');m0=cnt('mem');
 try,Os=g2_lp2b1s10_run('Run',true,'Token',C.token,'Test',tt(Cs,struct('gate',okGate,'memgate',memOK,'target',tgtC,'solve',fk,'geometry',geoC)));catch ME,Os=struct('stage',['EXCEPTION ' ME.identifier ': ' ME.message]);end
 nf=nFiles(Cs.runRoot);nl=nFiles(Cs.receiptRoot);
 R{end+1}=t('G14_real_geometry_fabricated_K_synthetic_STATE_TERMINAL',strcmp(Os.stage,'STATE_ACCEPTED')&&nf==11&&nl==4&&cnt('mem')-m0==2&&cnt('solve')==1&&cnt('sentinel')==0&& ...
  Os.geometry.pass&&Os.admissions==1&&Os.solveCalls==1&&strcmp(Os.terminal,'SINGLE_STATE_LIMIT_REACHED')&&strcmp(Os.geometry.actualClassification,'MATRIX_ADVANCE'));
 if strcmp(Os.stage,'STATE_ACCEPTED'),G=struct('stage',Os.stage,'geometry',Os.geometry,'S11',Os.S11,'files',nf,'ledgerFiles',nl);else,G=struct('stage',Os.stage);end
 Vs=g2_lp2b1s10_verify(Cs);R{end+1}=t('G14b_verifier_accepts_synthetic_closure',strcmp(Vs.outcome,'VERIFIED_ACCEPTED')&&Vs.unchanged&&isempty(Vs.problems));
 if isfile(fullfile(Cs.runRoot,'soft1','S10','STATE.mat'))
  [Sx,~,~]=g2_trajectory_record('read',fullfile(Cs.runRoot,'soft1','S10','STATE.mat'));
  R{end+1}=t('G14c_STATE_links_original_S9_and_qualification',strcmpi(Sx.parentSHA256,pol.parent.STATE.record.sha256)&&strcmp(Sx.canonicalSHA256,pol.qualification.canonicalSHA256)&& ...
   Sx.seedSpacing_mm==0.40&&isequal(Sx.tip_mm,[114.29544883822506 63.18559491151613])&&min(Sx.guideRingGap_mm)>=1&&Sx.T3==30357);
 else
  R{end+1}=t('G14c_STATE_links_original_S9_and_qualification',false);
 end
 h0=treeHash(Cs.runRoot);
 R{end+1}=t('G15_one_attempt_no_retry_after_success',refuses(@()g2_lp2b1s10_run('Run',true,'Token',C.token,'Test',tt(Cs,struct('gate',okGate,'memgate',memOK,'target',tgtC))),'G2LP2B1S10:HOLD_ONE_ATTEMPT')&&isequal(h0,treeHash(Cs.runRoot)));
 Ck=mk('g16',true);fkB=@(D,act,mats,polT,PM,expect)fakeK(D,act,mats,expect,Tq,pol,cnt,'gatesFail');
 R{end+1}=t('G16_failed_solver_gates_HOLD_no_STATE',refuses(@()g2_lp2b1s10_run('Run',true,'Token',C.token,'Test',tt(Ck,struct('gate',okGate,'memgate',memOK,'target',tgtC,'solve',fkB,'geometry',geoC))),'G2LP2B1S10:HOLD_K_EXTRACTION')&& ...
  isfile(fullfile(Ck.runRoot,'soft1','S10','SOLUTION.mat'))&&~isfile(fullfile(Ck.runRoot,'soft1','S10','STATE.mat'))&&~isfile(fullfile(Ck.runRoot,'soft1','TERMINAL.mat'))&& ...
  strcmp(getf(jsondecode(fileread(fullfile(Ck.runRoot,'soft1','S10','HOLD.json'))),'stage'),'ACCEPTANCE'));
 Vk=g2_lp2b1s10_verify(Ck);R{end+1}=t('G16b_verifier_partial_hold',strcmp(Vk.outcome,'VERIFIED_PARTIAL_HOLD'));
 Cn=mk('g17',true);fkN=@(D,act,mats,polT,PM,expect)fakeK(D,act,mats,expect,Tq,pol,cnt,'negKI');
 R{end+1}=t('G17_negative_KI_MTS_HOLD_no_STATE',refuses(@()g2_lp2b1s10_run('Run',true,'Token',C.token,'Test',tt(Cn,struct('gate',okGate,'memgate',memOK,'target',tgtC,'solve',fkN,'geometry',geoC))),'G2LP2B1S10:HOLD_K_EXTRACTION')&& ...
  ~isfile(fullfile(Cn.runRoot,'soft1','S10','STATE.mat')));
 Cq=mk('g18',true);fq=@(St,p)error('B1S10T:FORECAST','injected S11 forecast failure');
 try,Oq=g2_lp2b1s10_run('Run',true,'Token',C.token,'Test',tt(Cq,struct('gate',okGate,'memgate',memOK,'target',tgtC,'solve',fk,'geometry',geoC,'forecast',fq)));catch ME,Oq=struct('stage',ME.identifier);end
 [Tm,~,okt]=g2_trajectory_record('read',fullfile(Cq.runRoot,'soft1','TERMINAL.mat'));
 R{end+1}=t('G18_S11_forecast_failure_information_unavailable',strcmp(Oq.stage,'STATE_ACCEPTED')&&okt&&isempty(Tm.candidate.polyline_mm)&&startsWith(Tm.candidate.note,'S11 information unavailable (B1S10T:FORECAST)'));
 Vq=g2_lp2b1s10_verify(Cq);R{end+1}=t('G18b_verifier_flags_forecast_discrepancy',strcmp(Vq.outcome,'VERIFY_HOLD')&&any(strcmp(Vq.problems,'CHECK_S11_INFORMATION')));
 Cy=mk('g19',true);memSeq=memSequence(cnt,[true false]);
 R{end+1}=t('G19_pre_solve_memory_HOLD_after_MESH_PHASE',refuses(@()g2_lp2b1s10_run('Run',true,'Token',C.token,'Test',tt(Cy,struct('gate',okGate,'memgate',memSeq,'target',tgtC,'geometry',geoC))),'G2LP2B1S10:HOLD_MEMORY')&& ...
  isfile(fullfile(Cy.runRoot,'soft1','S10','PHASE.mat'))&&~isfile(fullfile(Cy.runRoot,'soft1','S10','SOLUTION.mat'))&&cnt('sentinel')==0&& ...
  strcmp(getf(jsondecode(fileread(fullfile(Cy.runRoot,'soft1','S10','HOLD.json'))),'stage'),'MEMORY'));
 R{end+1}=t('G20_cached_operation_meshed_once_two_real_meshings_total',cnt('geom')==1);
 % ---------------------------------------------------------------- J verifier on copies of the synthetic closure
 Jr=struct();
 Cj=cloneSet(Cs,mk('j1',false));Vj=g2_lp2b1s10_verify(Cj);R{end+1}=t('J1_copy_verifies',strcmp(Vj.outcome,'VERIFIED_ACCEPTED'));Jr.j1=Vj.outcome;
 Cj=cloneSet(Cs,mk('j2',false));wf(fullfile(Cj.runRoot,'soft1','S10','EXTRA.txt'),'x');Vj=g2_lp2b1s10_verify(Cj);R{end+1}=t('J2_extra_file_hold',strcmp(Vj.outcome,'VERIFY_HOLD'));Jr.j2=Vj.problems;
 Cj=cloneSet(Cs,mk('j3',false));delete(fullfile(Cj.runRoot,'soft1','TERMINAL.mat.manifest.json'));Vj=g2_lp2b1s10_verify(Cj);R{end+1}=t('J3_missing_manifest_hold',strcmp(Vj.outcome,'VERIFY_HOLD'));Jr.j3=Vj.problems;
 Cj=cloneSet(Cs,mk('j4',false));resave(fullfile(Cj.runRoot,'soft1','S10','MESH.mat'));Vj=g2_lp2b1s10_verify(Cj);R{end+1}=t('J4_tampered_MESH_link_hold',strcmp(Vj.outcome,'VERIFY_HOLD')&&any(strcmp(Vj.problems,'CHECK_LINKS')));Jr.j4=Vj.problems;
 Cj=cloneSet(Cs,mk('j5',false));delete(fullfile(Cj.receiptRoot,'ADMIT_soft1_S10.mat*'));Vj=g2_lp2b1s10_verify(Cj);R{end+1}=t('J5_missing_ledger_ADMIT_hold',strcmp(Vj.outcome,'VERIFY_HOLD'));Jr.j5=Vj.problems;
 Cj=cloneSet(Cs,mk('j6',false));Cj.token='OTHER';Vj=g2_lp2b1s10_verify(Cj);R{end+1}=t('J6_other_token_hold',strcmp(Vj.outcome,'VERIFY_HOLD')&&any(strcmp(Vj.problems,'CHECK_TOKEN')));Jr.j6=Vj.problems;
 Cj=cloneSet(Cs,mk('j7',false));Cj.policy.parent.STATE.record.sha256=repmat('1',1,64);Vj=g2_lp2b1s10_verify(Cj,'Target',tgtC);R{end+1}=t('J7_other_parent_hold',any(strcmp(Vj.problems,'CHECK_PARENT')));Jr.j7=Vj.problems;
 Cj=cloneSet(Cs,mk('j8',false));wf(fullfile(Cj.runRoot,'stray.txt'),'x');Vj=g2_lp2b1s10_verify(Cj);R{end+1}=t('J8_stray_run_root_file_hold',strcmp(Vj.outcome,'VERIFY_HOLD'));Jr.j8=Vj.problems;
end
R{end+1}=t('J9_no_records_outcome',strcmp(g2_lp2b1s10_verify(mk('j9',false)).outcome,'NO_RECORDS'));
% ---------------------------------------------------------------- H GO validator (pure)
gitOK=struct('isAncestor',@(h)true,'headParent',@()repmat('c',1,40),'changedFiles',@(h){au.goPath});
evOK=@(p)struct('exists',true,'sha256',repmat('e',1,64),'text',jsonencode(struct('passed',120,'total',120,'physicalSolves',0,'token',C.token)));
G0=struct('decision','GO_LP2B1_S10','decisionUrl','https://github.com/mfs9697/NewMetacomp/pull/80#issuecomment-1','approvedHead',repmat('c',1,40),'token',C.token, ...
 'campaignId',au.campaignId,'campaignScope',au.campaignScope,'runName',au.runName,'target','soft1-S10','admissions',1,'physicalSolves',1,'attemptsPerSolve',1, ...
 'seedSpacing_mm',0.40,'contractEvidenceFile',[au.contractEvidenceDir 'tests/x.json'],'contractEvidenceSHA256',repmat('e',1,64));
V=@(G,git,ev,tok)g2_lp2b1s10_go_validate(G,C,tok,git,ev);
R{end+1}=t('H1_valid_record_passes',V(G0,gitOK,evOK,C.token).pass);
mut={'decision','GO_LP2B1_EQ';'decisionUrl','https://example.com/x';'token','X';'campaignId','G2-LP2B1-EQ-001';'runName','run_lp2b1_eq_v1';'target','soft1-S11'; ...
 'admissions',2;'physicalSolves',2;'attemptsPerSolve',2;'seedSpacing_mm',0.45;'approvedHead','HEAD^';'contractEvidenceFile','docs/research/x.json'};
for k=1:size(mut,1),Gm=G0;Gm.(mut{k,1})=mut{k,2};R{end+1}=t(['H2_mutation_refused_' mut{k,1}],~V(Gm,gitOK,evOK,C.token).pass);end %#ok<AGROW>
R{end+1}=t('H3_caller_token_mismatch_refused',~V(G0,gitOK,evOK,'X').pass);
R{end+1}=t('H4_missing_field_refused',~V(rmfield(G0,'target'),gitOK,evOK,C.token).pass);
R{end+1}=t('H5_extra_activation_file_refused',~V(G0,setfield(gitOK,'changedFiles',@(h){au.goPath,'x.txt'}),evOK,C.token).pass); %#ok<SFLD>
R{end+1}=t('H6_wrong_parent_refused',~V(G0,setfield(gitOK,'headParent',@()repmat('d',1,40)),evOK,C.token).pass); %#ok<SFLD>
R{end+1}=t('H7_not_ancestor_refused',~V(G0,setfield(gitOK,'isAncestor',@(h)false),evOK,C.token).pass); %#ok<SFLD>
R{end+1}=t('H8_evidence_sha_mismatch_refused',~V(G0,gitOK,@(p)setfield(evOK(p),'sha256',repmat('f',1,64)),C.token).pass); %#ok<SFLD>
R{end+1}=t('H9_evidence_failed_tests_refused',~V(G0,gitOK,@(p)setfield(evOK(p),'text',jsonencode(struct('passed',119,'total',120,'physicalSolves',0,'token',C.token))),C.token).pass); %#ok<SFLD>
R{end+1}=t('H10_evidence_physical_solve_refused',~V(G0,gitOK,@(p)setfield(evOK(p),'text',jsonencode(struct('passed',120,'total',120,'physicalSolves',1,'token',C.token))),C.token).pass); %#ok<SFLD>
R{end+1}=t('H11_evidence_other_token_refused',~V(G0,gitOK,@(p)setfield(evOK(p),'text',jsonencode(struct('passed',120,'total',120,'physicalSolves',0,'token','Y'))),C.token).pass); %#ok<SFLD>
R{end+1}=t('H12_non_struct_refused',~V([],gitOK,evOK,C.token).pass&&~V('x',gitOK,evOK,C.token).pass);
% ---------------------------------------------------------------- I real git
RG=struct('notRun',true);if o.RealGit,[Ri,RG]=realGit(pol);R=[R,Ri];end
% ---------------------------------------------------------------- Z
R{end+1}=t('Z_no_physical_solve_sentinel_never_called',cnt('sentinel')==0);
R{end+1}=t('Z_repository_roots_still_absent',rootsAbsent(C));
rm=true;try,[~,~]=system(sprintf('attrib -R "%s\\*" /S /D',root));rmdir(root,'s');catch,rm=false;end
v=cellfun(@(r)r.pass,R);
T=struct('schema','NewMetacomp.G2.LP2B1S10.Tests.v1','passed',nnz(v),'total',numel(v),'failedTests',{cellfun(@(r)r.name,R(~v),'UniformOutput',false)}, ...
 'physicalSolves',0,'token',C.token,'policySHA256',C.policySHA256,'lp2b1s10SourceSHA256',C.lp2b1s10SourceSHA256,'sourceCommit',gitHead(C.repo), ...
 'tests',{R},'target',struct('checks',Tq.checks,'info',Tq.info,'parentSHA256',Tq.parentSHA256),'driverRealGeometry',G,'verifier',Jr,'realGit',RG, ...
 'tempRootRemoved',rm,'wallSeconds',toc(T0),'options',o,'matlab',version);
if ~isempty(o.OutFile),fid=fopen(o.OutFile,'w');fwrite(fid,jsonencode(T,'PrettyPrint',true),'char');fclose(fid);end
fprintf('LP2B1S10_TESTS %d/%d (%.1f s)\n',T.passed,T.total,T.wallSeconds);

 function Cx=mk(name,withReceipt)
  % test context: the real context with every write root inside the temp root
  Cx=C;b=fullfile(root,name);mkdir(b);Cx.runRoot=fullfile(b,'run');Cx.receiptRoot=fullfile(b,'receipt');Cx.goFile=fullfile(b,'GO.json');Cx.summaryFile=fullfile(b,'SUMMARY.json');
  if withReceipt
   g2_lp1_campaign_ledger('write',Cx.receiptRoot,'RECEIPT','RECEIPT.mat',struct('campaignId',pol.campaignId,'token',C.token,'fixture','INERT_TEST_RECEIPT'));
  end
 end
 function S=tt(Cx,ops)
  if ~isfield(ops,'solve'),ops.solve=sentinel;end
  S=struct('root',root,'context',Cx,'ops',ops);
 end
end

% =====================================================================
function r=t(name,ok),r=struct('name',name,'pass',isequal(ok,true));fprintf('LP2B1S10_TEST %-66s %d\n',name,r.pass);end
function ok=refuses(f,id)
try,f();ok=false;catch ME,ok=strcmp(ME.identifier,id);if ~ok,fprintf('  refused with %s: %s\n',ME.identifier,ME.message);end,end
end
function ok=rootsAbsent(C),ok=~isfolder(C.runRoot)&&~isfolder(C.receiptRoot)&&~isfile(C.summaryFile)&&~isfile(C.goFile);end
function M=bumpMem(cnt,m,ok)
cnt('mem')=cnt('mem')+1;M=struct('pass',ok,'minGiB',m,'freeGiB',9*ok+1,'reason','INJECTED');
end
function f=memSequence(cnt,seq)
k=0;f=@step;
 function M=step(m),k=k+1;M=bumpMem(cnt,m,seq(min(k,end)));end
end
function K=sentinelSolve(cnt),cnt('sentinel')=cnt('sentinel')+1;error('B1S10T:SENTINEL','The default solve operation must never be called in tests.');end
function Gq=cachedGeometry(C,s,Ref,od,GC,cnt)
% first call: the REAL unchanged g2_lp2b1eq_geometry; later calls: the cached result and a copy of its attempt folder
% (an injected, non-meshing operation). GC is a containers.Map (handle) holding 'G' and 'src'.
if ~isKey(GC,'G')
 cnt('geom')=cnt('geom')+1;GC('G')=g2_lp2b1eq_geometry(C,s,Ref,od);GC('src')=fullfile(od,'GEOMETRY_h040');
else
 copyfile(GC('src'),fullfile(od,'GEOMETRY_h040'));
end
Gq=GC('G');
end
function K=fakeK(D,act,mats,expect,Tq,pol,cnt,mode)
% injected NON-SOLVING operation: checks what the driver passes to the solver and returns the PARENT S9 K fields with a
% zero displacement vector of the new mesh length (a fixture; no FEM; never a physical result)
cnt('solve')=cnt('solve')+1;
ok=strcmp(g2_lp2b1eq_canon(D),pol.qualification.canonicalSHA256)&&numel(act.phaseForAssembly)==size(D.T6,1)&&mats(1).E==pol.bvp.E_MPa&& ...
 mats(2).E==pol.bvp.E_MPa*0.5&&mats(1).nu==0.35&&strcmp(mats(1).plane,'stress')&&expect.P_N==1&&expect.thickness_mm==12.7&&isequal(expect.load_mm,[254 203.2]);
assert(ok,'B1S10T:FAKE_INPUTS','Driver passed unexpected solver inputs.');
K=Tq.solution.K;K.u=zeros(2*size(D.X6,1),1);K.fixture='INERT_NON_SOLVING_OPERATION';
switch mode
 case 'gatesFail',K.pass=false;K.failedCriteria={'fixtureGate'};
 case 'negKI',K.KI=-abs(K.KI);
end
end
function n=nFiles(r),if ~isfolder(r),n=0;return,end;d=dir(fullfile(r,'**','*'));n=nnz(~[d.isdir]);end
function v=getf(s,f),if isstruct(s)&&isfield(s,f),v=s.(f);else,v='';end,end
function Cj=cloneSet(Cs,Cj)
copyfile(Cs.runRoot,Cj.runRoot);copyfile(Cs.receiptRoot,Cj.receiptRoot);
end
function resave(f),S=load(f);S.fixtureTamper=1;save(f,'-struct','S','-v7.3');end
function wf(p,txt),d=fileparts(p);if ~isfolder(d),mkdir(d);end;fid=fopen(p,'w');fwrite(fid,txt,'char');fclose(fid);end
function H=treeHash(root)
H=cell(0,2);if ~isfolder(root),return,end
d=dir(fullfile(root,'**','*'));d=d(~[d.isdir]);for k=1:numel(d),p=fullfile(d(k).folder,d(k).name);H(end+1,:)={p,lower(g2_sha256_file(p))};end %#ok<AGROW>
if ~isempty(H),H=sortrows(H,1);end
end
function h=gitHead(repo),[~,h]=system(sprintf('git -C "%s" rev-parse HEAD',repo));h=strtrim(h);end
function [R,Rec]=realGit(pol)
% real git through MATLAB system() (cmd.exe on Windows) on disposable inert fixtures outside the repository
R={};fx=fullfile(tempdir,sprintf('lp2b1s10_git_%s',datestr(now,'yyyymmddHHMMSSFFF')));fr=[fx '_root'];fn=[fx '_notrepo'];
[~,gv]=system('git --version');goF=pol.authorization.goPath;au=pol.authorization;
Rec=struct('matlab',version,'comSpec',getenv('ComSpec'),'git',strtrim(gv),'cases',struct([]));
try
 mkdir(fx);sh(sprintf('git init -q "%s"',fx));sh(sprintf('git -C "%s" config core.autocrlf false',fx));
 wf(fullfile(fx,'README_FIXTURE.txt'),'Inert LP2-B1-S10 git fixture; not an authorization; no token.');c0=commit(fx);
 wf(fullfile(fx,'evidence.txt'),'inert');c1=commit(fx);
 sh(sprintf('git -C "%s" checkout -q -b valid %s',fx,c1));wf(fullfile(fx,strrep(goF,'/',filesep)),'{"fixture":"INERT_NOT_AN_AUTHORIZATION"}');cA=commit(fx);
 sh(sprintf('git -C "%s" checkout -q -b extra %s',fx,c1));wf(fullfile(fx,strrep(goF,'/',filesep)),'{"fixture":"INERT"}');wf(fullfile(fx,'extra.txt'),'x');cX=commit(fx);
 sh(sprintf('git -C "%s" checkout -q -b revoked %s',fx,cA));sh(sprintf('git -C "%s" rm -q "%s"',fx,goF));cV=commit(fx);
 mkdir(fr);sh(sprintf('git init -q "%s"',fr));wf(fullfile(fr,'a.txt'),'root');cR=commit(fr);mkdir(fn);
 Rec.commits=struct('c0',c0,'c1',c1,'cA',cA,'cX',cX,'cV',cV,'cR',cR);
 tokF='FIXTURE-INERT-TOKEN';Cf=struct('repo',fx,'policy',pol,'token',tokF);
 evF=@(p)struct('exists',true,'sha256',repmat('b',1,64),'text',jsonencode(struct('passed',60,'total',60,'physicalSolves',0,'token',tokF)));
 G=struct('decision','GO_LP2B1_S10','decisionUrl','https://github.com/mfs9697/NewMetacomp/pull/80#issuecomment-1','approvedHead',c1,'token',tokF, ...
  'campaignId',au.campaignId,'campaignScope',au.campaignScope,'runName',au.runName,'target','soft1-S10','admissions',1,'physicalSolves',1,'attemptsPerSolve',1, ...
  'seedSpacing_mm',0.40,'contractEvidenceFile',[au.contractEvidenceDir 'x.json'],'contractEvidenceSHA256',repmat('b',1,64));
 K={'valid','valid',c1,fx,true,true;'wrong_parent','valid',c0,fx,false,false;'extra_file','extra',c1,fx,false,false;'post_revocation','revoked',c1,fx,false,false;
    'root_commit','',c1,fr,false,false;'not_a_repo','',c1,fn,false,false};
 for k=1:size(K,1)
  [nm,br,ah,rp,expV,expP]=K{k,:};if ~isempty(br),sh(sprintf('git -C "%s" checkout -q %s',rp,br));end
  Ck=Cf;Ck.repo=rp;Vk=g2_lp2b1s10_go_validate(setfield(G,'approvedHead',ah),Ck,tokF,[],evF); %#ok<SFLD>
  Pk=g2_lp2b1s10_external_run(ah,'','','ParentCheckOnly',true,'Repo',rp);Hp=g2_lp2a2_git('parent',rp);
  R{end+1}=t(['I_real_git_' nm],Vk.pass==expV&&Pk.pass==expP); %#ok<AGROW>
  c=struct('case',nm,'approvedHead',ah,'parentStatus',Hp.status,'parentValue',Hp.value,'command',strrep(Hp.command,rp,'<fixture>'),'validatorPass',Vk.pass,'failed',{Vk.failed},'externalPass',Pk.pass);
  if isempty(Rec.cases),Rec.cases=c;else,Rec.cases(end+1)=c;end
 end
 sh(sprintf('git -C "%s" checkout -q valid',fx));[s1,o1]=system(sprintf('git -C "%s" rev-parse HEAD^',fx));
 if ispc,R{end+1}=t('I_cmd_caret_defect_still_reproduced_HEAD_tilde_used',s1==0&&strcmp(strtrim(o1),cA));end
 try,g2_lp2a2_git('isAncestor',fx,'HEAD^');okm=false;catch ME,okm=strcmp(ME.identifier,'G2LP2A2:GIT_UNSAFE_ARG');end
 R{end+1}=t('I_metacharacter_argument_refused',okm);
catch ME
 fprintf('LP2B1S10 I ERROR %s: %s\n',ME.identifier,ME.message);R{end+1}=t('I_fixture_error',false);
end
for d={fx,fr,fn},if isfolder(d{1}),[~,~]=system(sprintf('attrib -R "%s\\*" /S /D',d{1}));try,rmdir(d{1},'s');catch,end,end,end
end
function sh(cmd),[st,o]=system(cmd);assert(st==0,'B1S10T:SETUP','fixture setup failed (%d): %s',st,o);end
function c=commit(root)
sh(sprintf('git -C "%s" add -A',root));sh(sprintf('git -C "%s" -c user.name=lp2b1s10-fixture -c user.email=fixture@example.invalid -c commit.gpgsign=false commit -q -m fixture',root));
[st,o]=system(sprintf('git -C "%s" rev-parse --verify HEAD',root));c=strtrim(o);assert(st==0&&~isempty(regexp(c,'^[0-9a-f]{40}$','once')),'B1S10T:SETUP','commit hash');
end
