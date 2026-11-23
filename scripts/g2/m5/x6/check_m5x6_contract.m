function T=check_m5x6_contract(C)
%CHECK_M5X6_CONTRACT  M5-X6 GO, gate, ledger, activation, driver and analysis contract tests. No FEM.
% C: g2_m5x6_context output. Every negative requires its exact MATLAB identifier and the message
% fragment of its branch; any other error, or none, fails. GO fixtures are in-memory only; no GO
% file is written. Ledger tests write only inside a fresh tempname folder that is removed.
rows=struct('name',{},'kind',{},'expected',{},'observed',{},'pass',{});
UN='G2M5X6:HOLD_UNAUTHORIZED_STATE';SRC='G2M5X6:HOLD_SOURCE';
% ---------------------------------------------------------------- GO validator (pure, in-memory)
Cs=struct('planSHA256',repmat('a',1,64),'a1SourceSHA256',repmat('b',1,64),'x6SourceSHA256',repmat('c',1,64), ...
 'meshManifestSHA256',repmat('d',1,64),'token','G2M5X6|fixture','plan',struct('authorization',C.plan.authorization));
ce=struct('pass',true,'passed',40,'total',40,'physicalSolves',0,'negativeTestsPassed',true,'token','G2M5X6|fixture');
txt=jsonencode(ce);good=struct('exists',true,'sha256',repmat('e',1,64),'text',txt);
cf='docs/research/G2_M5_X6_evidence/M5X6_CONTRACT.json';
G0=struct('decision','GO_M5_X6_PHYSICAL','reviewStatus','REVIEWED_ACCEPTED','scientificReviewer','fixture reviewer', ...
 'reviewURL','https://github.com/mfs9697/NewMetacomp/issues/0#fixture','approvedPlanSHA256',Cs.planSHA256, ...
 'approvedA1SourceSHA256',Cs.a1SourceSHA256,'approvedX6SourceSHA256',Cs.x6SourceSHA256, ...
 'approvedMeshManifestSHA256',Cs.meshManifestSHA256,'approvedToken',Cs.token, ...
 'approvedConfigurations',{{'X6-01','X6-02','X6-03','X6-04','X6-05','X6-06'}},'maxSolves',6,'revocationRequired',true, ...
 'contractEvidenceFile',cf,'contractEvidenceSHA256',good.sha256,'approvedRunName','run_m5x6_crossed_s4_b9_v1', ...
 'campaignId','G2-M5-X6-001','campaignScope','M5_X6_S4_B9_CROSSED_MAX6');
ld=@(E)@(f)E;
ok('go_valid_fixture_accepted','go',@()isstruct(g2_m5x6_go_validate(G0,Cs,ld(good))));
goNeg('go_missing_field',rmfield(G0,'maxSolves'),UN,'Incomplete');
goNeg('go_a1_decision_refused',setf(G0,'decision','GO_A1_PHYSICAL'),UN,'decision or review');
goNeg('go_not_reviewed',setf(G0,'reviewStatus','PENDING'),UN,'decision or review');
goNeg('go_empty_reviewer',setf(G0,'scientificReviewer','  '),UN,'decision or review');
goNeg('go_foreign_review_url',setf(G0,'reviewURL','https://example.org/x'),UN,'decision or review');
goNeg('go_wrong_scope',setf(G0,'campaignScope','A1_S4_FAMILY_B_FIXED_PATH_MAX12'),UN,'scope, run name');
goNeg('go_bad_run_name',setf(G0,'approvedRunName','run-bad name'),UN,'scope, run name');
goNeg('go_a1_run_name_refused',setf(G0,'approvedRunName','run_a1_family_b_s4_v1'),UN,'scope, run name');
goNeg('go_a0_run_name_refused',setf(G0,'approvedRunName','run_a0_lp1_repro_v1'),UN,'scope, run name');
goNeg('go_lp1_run_name_refused',setf(G0,'approvedRunName','run_20261122_lp1_v1'),UN,'scope, run name');
goNeg('go_a1_campaign_refused',setf(G0,'campaignId','G2-A1-FB-001'),UN,'scope, run name');
goNeg('go_a0_campaign_refused',setf(G0,'campaignId','G2-LP1-A0-001'),UN,'scope, run name');
goNeg('go_five_configurations',setf(G0,'approvedConfigurations',{'X6-01','X6-02','X6-03','X6-04','X6-05'}),UN,'exactly the six');
goNeg('go_reordered_configurations',setf(G0,'approvedConfigurations',{'X6-02','X6-01','X6-03','X6-04','X6-05','X6-06'}),UN,'exactly the six');
goNeg('go_extra_configuration',setf(G0,'approvedConfigurations',{'X6-01','X6-02','X6-03','X6-04','X6-05','X6-06','X6-07'}),UN,'exactly the six');
goNeg('go_ceiling_seven',setf(G0,'maxSolves',7),UN,'exactly the six');
goNeg('go_no_revocation',setf(G0,'revocationRequired',false),UN,'exactly the six');
goNeg('go_plan_mismatch',setf(G0,'approvedPlanSHA256',repmat('f',1,64)),SRC,'does not bind');
goNeg('go_a1_source_mismatch',setf(G0,'approvedA1SourceSHA256',repmat('f',1,64)),SRC,'does not bind');
goNeg('go_x6_source_mismatch',setf(G0,'approvedX6SourceSHA256',repmat('f',1,64)),SRC,'does not bind');
goNeg('go_mesh_manifest_mismatch',setf(G0,'approvedMeshManifestSHA256',repmat('f',1,64)),SRC,'does not bind');
goNeg('go_token_mismatch',setf(G0,'approvedToken','G2M5X6|other'),SRC,'does not bind');
goNeg('go_contract_outside_dir',setf(G0,'contractEvidenceFile','matlab/g2/evidence/a1_preflight/x.json'),SRC,'not pinned');
goNeg('go_contract_dotdot',setf(G0,'contractEvidenceFile','docs/research/G2_M5_X6_evidence/../x.json'),SRC,'not pinned');
expect('go_contract_absent','go',@()g2_m5x6_go_validate(G0,Cs,ld(struct('exists',false,'sha256','','text',''))),SRC,'absent or changed');
expect('go_contract_changed','go',@()g2_m5x6_go_validate(setf(G0,'contractEvidenceSHA256',repmat('9',1,64)),Cs,ld(good)),SRC,'absent or changed');
bad=good;bad.text=jsonencode(setf(ce,'passed',39));
expect('go_contract_not_passed','go',@()g2_m5x6_go_validate(G0,Cs,ld(bad)),UN,'has not passed');
bad=good;bad.text=jsonencode(setf(ce,'physicalSolves',1));
expect('go_contract_with_solves','go',@()g2_m5x6_go_validate(G0,Cs,ld(bad)),UN,'has not passed');
bad=good;bad.text=jsonencode(rmfield(ce,'negativeTestsPassed'));
expect('go_contract_missing_field','go',@()g2_m5x6_go_validate(G0,Cs,ld(bad)),UN,'lacks required');
bad=good;bad.text=jsonencode(setf(ce,'token','G2M5X6|other'));
expect('go_contract_other_token','go',@()g2_m5x6_go_validate(G0,Cs,ld(bad)),SRC,'another token');
% ---------------------------------------------------------------- gate (real context; GO must be absent)
ok('gate_go_file_absent','gate',@()~isfile(fullfile(C.x6,'G2_M5_X6_SCIENTIFIC_GO_v1.json')));
expect('gate_refuses_without_go','gate',@()g2_m5x6_scientific_gate(C),UN,'no GO_M5_X6 record');
% ---------------------------------------------------------------- ledger hook (temp folder only)
tmp=tempname;mkdir(tmp);cl=onCleanup(@()rmdir(tmp,'s'));lr=fullfile(tmp,'ledger');
g2_lp1_campaign_ledger('write',lr,'RECEIPT','RECEIPT.mat',struct('campaignId','FIX-1','runName','run_fix','goSHA256','x','token','t'));
Co=struct('mode','CONTINUE');
for k=1:6,g2_m5x6_admit_hook(lr,Co,'FIX-1',sprintf('X6_0%d',k));end
L=g2_lp1_campaign_ledger('snapshot',lr);
ok('hook_six_admissions_recorded','ledger',@()L.integrityOK&&numel(L.admits)==6);
expect('hook_seventh_admission_refused','ledger',@()g2_m5x6_admit_hook(lr,Co,'FIX-1','X6_07'),UN,'six-solve ceiling');
lr2=fullfile(tmp,'ledger2');
g2_lp1_campaign_ledger('write',lr2,'RECEIPT','RECEIPT.mat',struct('campaignId','FIX-2','runName','run_fix','goSHA256','x','token','t'));
g2_m5x6_admit_hook(lr2,Co,'FIX-2','X6_01');
expect('hook_duplicate_key_refused','ledger',@()g2_m5x6_admit_hook(lr2,Co,'FIX-2','X6_01'),'G2LP1:HOLD_CAMPAIGN_INTEGRITY','already admitted');
expect('hook_closed_campaign_refused','ledger',@()g2_m5x6_admit_hook(lr2,struct('mode','VERIFY_ONLY'),'FIX-2','X6_02'),'G2LP1:HOLD_CAMPAIGN_CLOSED','closed');
sd=fullfile(tmp,'state_exists');mkdir(sd);
expect('admit_existing_state_never_retried','ledger',@()g2_lp1_admit_state(sd,99,[]),'G2LP1:HOLD_RECORD_INTEGRITY','never retried');
expect('admit_memory_guard_5GiB','ledger',@()g2_lp1_admit_state(fullfile(tmp,'new_state'),4.99,[]),'G2LP1:HOLD_MEMORY','5 GiB');
ok('admit_memory_guard_left_no_folder','ledger',@()~isfolder(fullfile(tmp,'new_state')));
% ---------------------------------------------------------------- driver (dry and static source order)
expect('driver_unknown_configuration','driver',@()g2_m5x6_run('Config','X6-07'),'G2M5X6:HOLD_INPUT','six preregistered');
expect('driver_diagonal_not_a_configuration','driver',@()g2_m5x6_run('Config','H_B9'),'G2M5X6:HOLD_INPUT','six preregistered');
src=fileread(fullfile(C.x6,'g2_m5x6_run.m'));runPart=src(strfind(src,'% ------------------------------------------------------------------ authorized path only'):end);
pg=strfind(runPart,'g2_m5x6_scientific_gate(C)');
firstOf=@(s)min([strfind(runPart,s),inf]);
ok('driver_gate_precedes_folders_ledger_solve','driver',@()isscalar(pg)&&pg<firstOf('mkdir(')&&pg<firstOf('g2_lp1_campaign_ledger(''write''')&& ...
 pg<firstOf('g2_m4b_sif_partial(')&&pg<firstOf('g2_trajectory_record(''write''')&&pg<firstOf('g2_lp1_admit_state('));
ok('driver_dry_branch_has_no_solve_or_write','driver',@()dryClean(src));
ok('driver_never_reads_a0_a1_go','driver',@()isempty(strfind(src,'G2_A1_SCIENTIFIC_GO'))&&isempty(strfind(src,'G2_LP1_SCIENTIFIC_GO'))&& ...
 isempty(strfind(fileread(fullfile(C.x6,'g2_m5x6_scientific_gate.m')),'G2_A1_SCIENTIFIC_GO')));
ok('driver_no_resume_record','driver',@()~isempty(strfind(src,'runFolderFacts(rd,C.token),[])')));
ok('driver_admission_ceiling_six','driver',@()~isempty(strfind(fileread(fullfile(C.x6,'g2_m5x6_admit_hook.m')),'numel(L.admits)<6')));
% ---------------------------------------------------------------- activation negatives (H_B9 mesh, no solve)
cfg=C.configurations(1);Q=g2_m5x6_configuration_check(C,cfg);D=Q.D;PM=Q.PM;
ok('x601_static_check_passes','activation',@()Q.pass&&strcmp(Q.mask,'101')&&Q.activeElements==sum(Q.ringElements([1 3])));
H=g2_m4b_ring_activation(PM.annulusOf,[0 0 0]);
ok('swap_detected_x601_vs_h_labels','activation',@()~isequal(H.phaseForAssembly,Q.act.phaseForAssembly)&& ...
 nnz(H.phaseForAssembly~=Q.act.phaseForAssembly)==Q.activeElements);
expect('config_mesh_pin_mismatch','activation',@()g2_m5x6_configuration_check(C,setf(cfg,'meshContentSHA256',repmat('0',1,64))),SRC,'differs from the preregistration');
expect('config_mask_not_policy','activation',@()g2_m5x6_configuration_check(C,setf(cfg,'mask',[0 1 1])),'G2M5X6:HOLD_INPUT','not a policy');
expect('config_ratio_not_policy','activation',@()g2_m5x6_configuration_check(C,setf(cfg,'ratio',0.5)),'G2M5X6:HOLD_INPUT','not a policy');
vo=verOpts(C,D);
W=g2_m4b_activation_verify(D.X6,D.T6,PM.annulusOf,H.phaseForAssembly,[1 0 1],Q.mats,vo.geo,setf(vo.o,'contrast',2));
ok('verifier_rejects_labels_not_from_mask','activation',@()~W.pass&&any(strcmp(W.failed,'phaseFromMask')));
mb=Q.mats;mb(2).E=Q.Em*0.5;
W=g2_m4b_activation_verify(D.X6,D.T6,PM.annulusOf,Q.act.phaseForAssembly,[1 0 1],mb,vo.geo,setf(vo.o,'contrast',2));
ok('verifier_rejects_wrong_ring_modulus','activation',@()~W.pass&&any(strcmp(W.failed,'materialsAdmissible')));
ow=PM.annulusOf;i=find(ow==2,1);ow(i)=0;
W=g2_m4b_activation_verify(D.X6,D.T6,ow,Q.act.phaseForAssembly,[1 0 1],Q.mats,vo.geo,setf(vo.o,'contrast',2));
ok('verifier_rejects_tampered_owner','activation',@()~W.pass&&any(strcmp(W.failed,'oracleAgreement')));
% ---------------------------------------------------------------- decomposition identities (pure)
rng(20261123);q=1+rand(200,4);mx=0;
for k=1:200,d=m5x6_decompose(q(k,1),q(k,2),q(k,3),q(k,4),'relative');mx=max([mx,abs(d.identityResidual),abs(d.multiplicativeResidual)]);end
ok('decomposition_exact_identity','analysis',@()mx<=4*eps);
d=m5x6_decompose(2,2.2,2,2.2,'relative');
ok('decomposition_pure_material','analysis',@()d.F_path==0&&abs(d.F_int)<=eps&&abs(d.F_mat-0.1)<=eps);
d=m5x6_decompose(2,2,1.9,1.9,'absolute');
ok('decomposition_pure_path','analysis',@()d.F_mat==0&&abs(d.F_int)<=eps&&abs(d.F_path+0.1)<=eps);
d=m5x6_decompose(1,1.1,0.95,1.06,'relative');
ok('decomposition_shapley_sum','analysis',@()abs(d.shapley_mat+d.shapley_path-d.F_tot)<=4*eps&&abs(d.refXX_mat+d.F_path-d.F_tot)<=4*eps);
expect('analysis_refuses_without_campaign','analysis',@()m5x6_analyze(C.repo,'run_m5x6_crossed_s4_b9_v1','G2-M5-X6-001',fullfile(tmp,'a.json')), ...
 'G2M5X6:HOLD_NOT_EXECUTED','has not been executed');
ok('analysis_wrote_nothing','analysis',@()~isfile(fullfile(tmp,'a.json')));
% ---------------------------------------------------------------- summary
neg=rows(strcmp({rows.expected},'error'));
T=struct('schema','NewMetacomp.G2.M5X6.ContractTests.v1','pass',all([rows.pass]),'passed',nnz([rows.pass]), ...
 'total',numel(rows),'negativeTests',numel(neg),'negativeTestsPassed',all([neg.pass]),'physicalSolves',0, ...
 'token',C.token,'rows',rows);
fprintf('M5X6_CONTRACT %d/%d (negatives %d)\n',T.passed,T.total,numel(neg));
for r=rows(~[rows.pass]),fprintf(2,'M5X6_CONTRACT_FAIL %s: %s\n',r.name,r.observed);end

 function ok(name,kind,f)
  try,v=isequal(f(),true);obs=mat2str(v);catch ME,v=false;obs=['error ' ME.identifier ': ' ME.message];end
  rows(end+1)=struct('name',name,'kind',kind,'expected','true','observed',obs,'pass',v);
 end
 function expect(name,kind,f,id,frag)
  try,f();obs='no error';v=false;
  catch ME,obs=[ME.identifier ': ' ME.message];v=strcmp(ME.identifier,id)&&contains(ME.message,frag);end
  rows(end+1)=struct('name',name,'kind',kind,'expected','error','observed',obs,'pass',v);
 end
 function goNeg(name,G,id,frag)
  expect(name,'go',@()g2_m5x6_go_validate(G,Cs,ld(good)),id,frag);
 end
end

function s=setf(s,f,v)
s.(f)=v;
end
function t=dryClean(src)
a=strfind(src,'if ~o.Run');b=strfind(src,'% ------------------------------------------------------------------ authorized path only');
dry=src(a(1):b(1));
t=isempty(strfind(dry,'g2_m4b_sif_partial'))&&isempty(strfind(dry,'mkdir'))&&isempty(strfind(dry,'''write'''))&& ...
 isempty(strfind(dry,'g2_lp1_admit_state'))&&~isempty(strfind(dry,'return'));
end
function V=verOpts(C,D)
pm=jsondecode(fileread(fullfile(C.g2,'G2_MATERIAL_POLICY_v1.json')));lp=jsondecode(fileread(fullfile(C.g2,'G2_LP1_POLICY_v2.json')));
g=lp.geometry;cen=reshape(g.centres_mm,[],2);if ~isequal(cen(:,1),[152.4;152.4;152.4]),cen=reshape(g.centres_mm.',[],2);end
qa=reshape(pm.sifGates.qAnnuli_mm,[],2);if size(qa,1)~=5,qa=reshape(pm.sifGates.qAnnuli_mm.',[],2);end
fg=pm.frozenGeometry;P=D.crackPolyline;
V.geo=struct('centres',cen,'holeR',6.35*ones(3,1),'ringR',19.05*ones(3,1));
V.o=struct('onCircleTol_mm',pm.phaseMap.onCircleTolerance_mm,'midsideTol_mm',pm.phaseMap.midsideOnChordTolerance_mm, ...
 'areaRelTol',pm.phaseMap.areaIdentityRelTol,'domainAreaRelTol',pm.phaseMap.plateAreaIdentityRelTol,'outerArea_mm2',prod(fg.plate_mm), ...
 'expectedChords',76,'E_matrix',lp.bvp.E_MPa,'nu',lp.bvp.nu,'thickness_mm',lp.bvp.thickness_mm,'tip',P(end,:), ...
 'tipGuideRadius_mm',fg.tipGuideRadius_mm,'qOuterRadii_mm',qa(:,2),'minQClearance_mm',pm.sifGates.minQSupportClearanceToReinforcement_mm, ...
 'twins',[D.upperBankT6(:),D.lowerBankT6(:)]);
end
