function T = run_g2_m4b_r1_faults_batch(acceptedRun)
%RUN_G2_M4B_R1_FAULTS_BATCH  Tamper / restart / replay suite for G2-M4.B-R1 (Issue #50, R1 policy fault list).
%
%  T = run_g2_m4b_r1_faults_batch(acceptedRun)
% Disposable roots under <repo>/outputs/g2_m4b_r1_faults_v1/fault_<time>/ and byte copies of the
% accepted R1 run only. The accepted R1 run, the M4.B original-family run and the M2 S2alt files
% are hashed before and after and must be unchanged. Every test states its expected outcome.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
acceptedRun=char(acceptedRun);
root=fullfile(repo,'outputs','g2_m4b_r1_faults_v1',['fault_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);
assert(~exist(root,'dir'));mkdir(root);
diary(fullfile(root,'r1_faults_console.log'));cl=onCleanup(@()diary('off')); %#ok<NASGU>
pf=fullfile(here,'G2_M4B_R1_POLICY_v1.json');pol=jsondecode(fileread(pf));polSHA=lower(g2_sha256_file(pf));
[~,srcSHA]=g2_m4b_r1_sources(here);meshSHA=lower(pol.reference.meshSHA256);
tok=sprintf('G2M4BR1RUN|%s|src=%s|mesh=%s|cases=10',polSHA,srcSHA,meshSHA);
guard={acceptedRun,fullfile(repo,pol.reference.originalFamilyResults.run)};
before=cellfun(@hash_dir,guard,'UniformOutput',false);
m2files=cellfun(@(f)fullfile(repo,pol.reference.acceptedS2altBaselines.run,f),{'S2ALT_KINKED_GEOMETRY_ONLY_candidate.mat','PHASE_MAP_S2alt.mat','CASE_S2alt_H1.mat','CASE_S2alt_Msoft.mat','CASE_S2alt_Mstiff.mat'},'UniformOutput',false);
m2before=cellfun(@(f)lower(g2_sha256_file(f)),m2files,'UniformOutput',false);
tests=struct('name',{},'expected',{},'observed',{},'pass',{});
% ---- F01 dry writes nothing
s0=list_tree(fullfile(repo,'outputs'));R=g2_m4b_r1_campaign();s1=list_tree(fullfile(repo,'outputs'));
tests=add(tests,'F01_dry_writes_nothing','DRY_OK + no new files',sprintf('%s, new files %d',R.status,numel(setdiff(s1,s0))),strcmp(R.status,'DRY_OK')&&isequal(s0,s1));
% ---- F02 tampered S2alt bytes
tm=fullfile(root,'tampered_S2alt.mat');copyfile(fullfile(repo,pol.reference.mesh),tm);fid=fopen(tm,'a');fwrite(fid,uint8(0));fclose(fid);
R=g2_m4b_r1_campaign('MeshFile',tm);tests=add(tests,'F02_tampered_S2alt','HOLD_SOURCE',R.status,strcmp(R.status,'HOLD_SOURCE'));
% ---- F03 matched-geometry rule
Dalt=load(fullfile(repo,pol.reference.mesh));Dorig=load(fullfile(repo,pol.reference.matchedOriginal.mesh));
M0=g2_m4b_r1_matched_check(Dalt,Dorig);
tests=add(tests,'F03a_matched_S2alt_accepted','pass',sprintf('pass=%d',M0.pass),M0.pass);
m4a=fullfile(repo,'outputs','g2_m4_alt_family_v1','chain_homogeneous_alt_v1','STEP_002','KINKED_GEOMETRY_ONLY_candidate.mat');
Dm4a=load(m4a);M1=g2_m4b_r1_matched_check(Dm4a,Dorig);clear Dm4a
tests=add(tests,'F03b_M4A_alternative_S2_rejected','fail on polyline/tip',strjoin(M1.failed,','),~M1.pass&&any(strcmp(M1.failed,'polylineBitwise')));
Dp=Dalt;Dp.crackPolyline(end,1)=Dp.crackPolyline(end,1)+1e-12;M2=g2_m4b_r1_matched_check(Dp,Dorig);clear Dp
tests=add(tests,'F03c_polyline_perturbed_1e-12_rejected','fail on polyline',strjoin(M2.failed,','),~M2.pass&&any(strcmp(M2.failed,'polylineBitwise')));
Dt=Dalt;Dt.tipTangent=Dt.tipTangent*(1+eps);M3=g2_m4b_r1_matched_check(Dt,Dorig);clear Dt
tests=add(tests,'F03d_tangent_perturbed_rejected','fail on tangent',strjoin(M3.failed,','),~M3.pass&&any(strcmp(M3.failed,'tipTangentBitwise')));
clear Dorig
% ---- F04 activation mutations on the 112-gon
P=reshape(pol.reference.polyline_mm,[],2);[Dm,~]=g2_m2_state_adapter(Dalt,'S2alt',P);clear Dalt
polM=jsondecode(fileread(fullfile(here,'G2_MATERIAL_POLICY_v1.json')));polT=jsondecode(fileread(fullfile(here,'G2_TRAJECTORY_POLICY_v1.json')));
polV2=jsondecode(fileread(fullfile(here,'G2_M4B_POLICY_v2.json')));
[PM,geo,vopts]=phase_inputs(Dm,polM,polV2,pol,P);
mk=@(E)struct('E',E,'nu',pol.materials.nu,'plane',pol.materials.plane);
NC=check_g2_m4b_activation_negatives(Dm,PM,geo,vopts,mk);
for k=1:numel(NC.cases)
 tests=add(tests,['F04_',NC.cases(k).name],['rejected by ',NC.cases(k).expect],strjoin(NC.cases(k).failed,','),NC.cases(k).rejected);
end
% ---- F05 active-interface traction imbalance
Em=pol.materials.E_matrix_MPa;a=g2_m4b_ring_activation(PM.annulusOf,[1 0 0]);mats=[mk(Em),mk(.5*Em)];
N=size(Dm.X6,1);f=polT.bvp.P_N/polT.bvp.thickness_mm;
nodeAt=@(xy)Dm.extraVertexNodes(vecnorm(Dm.extraVertexXY-reshape(xy,1,2),2,2)<1e-9);
pin=nodeAt(polT.bvp.pin_mm);roller=nodeAt(polT.bvp.roller_mm);ld=nodeAt(polT.bvp.load_mm);
F=zeros(2*N,1);F(2*ld)=-f;bc=struct('fixedDofs',[2*pin-1;2*pin;2*roller],'fixedValues',[0;0;0],'F',F);
S=g2_t6_elasticity_phase(Dm.X6,Dm.T6,a.phaseForAssembly,mats,bc);B0=g2_m4b_interface_balance(S.phaseNodalForce,PM,1);
iN=PM.interfaces(1).vertexNodes(1);far=find(vecnorm(Dm.X6-[400 150],2,2)<5,1);
F2=F;F2(2*iN)=F2(2*iN)+1e-3*f;F2(2*far)=F2(2*far)-1e-3*f;bc.F=F2;
S2=g2_t6_elasticity_phase(Dm.X6,Dm.T6,a.phaseForAssembly,mats,bc);B1=g2_m4b_interface_balance(S2.phaseNodalForce,PM,1);
tests=add(tests,'F05_interface_traction_imbalance','clean <= 1e-8, perturbed > 1e-8',sprintf('clean %.3g, perturbed %.3g',B0.balanceRel,B1.balanceRel),B0.balanceRel<=1e-8&&B1.balanceRel>1e-8);
clear S S2
% ---- F06 wrong load / thickness
expect=struct('P_N',pol.bvp.P_N,'thickness_mm',pol.materials.thickness_mm,'load_mm',pol.bvp.load_mm,'E_matrix',Em);
pT=polT;pT.bvp.P_N=2;K=g2_m4b_sif_partial(Dm,a,mats,pT,PM,expect);
tests=add(tests,'F06a_wrong_load','loadThicknessModulus fails',strjoin(K.failedCriteria,','),~K.pass&&~K.criteria.loadThicknessModulus);
e2=expect;e2.thickness_mm=12;K=g2_m4b_sif_partial(Dm,a,mats,polT,PM,e2);
tests=add(tests,'F06b_wrong_thickness','loadThicknessModulus fails',strjoin(K.failedCriteria,','),~K.pass&&~K.criteria.loadThicknessModulus);
clear K Dm
% ---- F07 bad tokens
bads={strrep(tok,polSHA,repmat('0',1,64)),'policy';strrep(tok,srcSHA,repmat('1',1,64)),'source_set';strrep(tok,meshSHA,repmat('2',1,64)),'mesh';strrep(tok,'cases=10','cases=16'),'case_cap';'','empty'};
for k=1:size(bads,1)
 R=g2_m4b_r1_campaign('Run',true,'AuthToken',bads{k,1},'OutRoot',root);
 tests=add(tests,['F07_bad_token_',bads{k,2}],'HOLD_AUTH_TOKEN, no solve',sprintf('%s solves %d',R.status,R.solves),strcmp(R.status,'HOLD_AUTH_TOKEN')&&R.solves==0);
end
% ---- F08 policy drift
pc=fullfile(root,'G2_M4B_R1_POLICY_v1.json');t=fileread(pf);fid=fopen(pc,'w');fwrite(fid,strrep(t,'"physicalSolves": 10','"physicalSolves": 11'),'char');fclose(fid);
R=g2_m4b_r1_campaign('Run',true,'AuthToken',tok,'OutRoot',root,'PolicyFile',pc);
tests=add(tests,'F08_policy_drift','HOLD_POLICY_DRIFT',R.status,strcmp(R.status,'HOLD_POLICY_DRIFT'));
% ---- F09 dirty tree
uf=fullfile(here,'zz_m4b_r1_fault_untracked_tmp.m');fid=fopen(uf,'w');fwrite(fid,'% fault test','char');fclose(fid);
try,R=g2_m4b_r1_campaign('Run',true,'AuthToken',tok,'OutRoot',root);catch ME,R=struct('status',ME.identifier,'solves',NaN);end
delete(uf);
tests=add(tests,'F09_source_drift_dirty_tree','HOLD_DIRTY_SOURCE',R.status,strcmp(R.status,'HOLD_DIRTY_SOURCE'));
% ---- F10 RAM guard
R=g2_m4b_r1_campaign('SimulatedFreeGiB',4.9);
tests=add(tests,'F10a_low_ram_guard','HOLD_MEMORY',R.status,strcmp(R.status,'HOLD_MEMORY'));
[st,msg]=system(sprintf('powershell -NoProfile -ExecutionPolicy Bypass -File "%s" -MinFreeGiB 4',fullfile(here,'run_g2_m4b_r1.ps1')));
tests=add(tests,'F10b_launcher_guard_not_lowerable','nonzero exit, HOLD_RAM_POLICY',sprintf('exit %d',st),st~=0&&contains(msg,'HOLD_RAM_POLICY'));
% ---- F11 outside the R1 design (incl. M4.B masks not authorized for R1)
for cz={{'c0p5_110'},{'c2p0_011'},{'c0p5_101'},{'c0p5_1101'},{'none','none'}}
 R=g2_m4b_r1_campaign('Run',true,'AuthToken',tok,'OutRoot',root,'Cases',cz{1});
 tests=add(tests,['F11_outside_design_',strjoin(cz{1},'+')],'HOLD_CASE_OUTSIDE_DESIGN, no solve',sprintf('%s solves %d',R.status,R.solves),strcmp(R.status,'HOLD_CASE_OUTSIDE_DESIGN')&&R.solves==0);
end
% ---- F12 record tampering on byte copies
cp=@(name)copy_run(acceptedRun,fullfile(root,name));
c1=cp('copy_bytes');fid=fopen(fullfile(c1,'CASE_c2p0_101.mat'),'a');fwrite(fid,uint8(1));fclose(fid);
R=g2_m4b_r1_campaign('Run',true,'AuthToken',tok,'OutRoot',root,'RunDir',c1);
tests=add(tests,'F12a_record_bytes_tampered','HOLD_RECORD_INTEGRITY, no FEM',sprintf('%s solves %d',R.status,R.solves),strcmp(R.status,'HOLD_RECORD_INTEGRITY')&&R.solves==0);
c2=cp('copy_kii');resign(c2,'CASE_c0p5_100.mat',@flip_kii,true);
R=g2_m4b_r1_campaign('Run',true,'AuthToken',tok,'OutRoot',root,'RunDir',c2);
tests=add(tests,'F12b_KII_sign_reversed_resigned','HOLD_RECORD_INTEGRITY (EDI-from-u), no FEM',sprintf('%s solves %d',R.status,R.solves),strcmp(R.status,'HOLD_RECORD_INTEGRITY')&&R.solves==0);
c3=cp('copy_noledger');resign(c3,'CASE_c2p0_001.mat',@(r)r,false);
R=g2_m4b_r1_campaign('Run',true,'AuthToken',tok,'OutRoot',root,'RunDir',c3);
tests=add(tests,'F12c_resigned_without_ledger','HOLD_RECORD_INTEGRITY, no FEM',sprintf('%s solves %d',R.status,R.solves),strcmp(R.status,'HOLD_RECORD_INTEGRITY')&&R.solves==0);
c4=cp('copy_forged');src=load(fullfile(c4,'CASE_c0p5_100.mat'),'record');
delete(fullfile(c4,'CASE_c0p5_010.mat'));delete(fullfile(c4,'CASE_c0p5_010.mat.manifest.json'));
h=g2_trajectory_record('write',fullfile(c4,'CASE_c0p5_010.mat'),src.record);relabel_ledger(c4,'CASE_c0p5_010.mat',h);
R=g2_m4b_r1_campaign('Run',true,'AuthToken',tok,'OutRoot',root,'RunDir',c4);
tests=add(tests,'F12d_forged_case_record','HOLD_RECORD_INTEGRITY, no FEM',sprintf('%s solves %d',R.status,R.solves),strcmp(R.status,'HOLD_RECORD_INTEGRITY')&&R.solves==0);
c5=cp('copy_clean');R=g2_m4b_r1_campaign('Run',true,'AuthToken',tok,'OutRoot',root,'RunDir',c5);
tests=add(tests,'F12e_clean_copy_resumes_without_FEM','GO, 0 solves, 12 reused',sprintf('%s solves %d reused %d',R.status,R.solves,R.reused),strcmp(R.status,'GO')&&R.solves==0&&R.reused==12);
% ---- F13 interrupt / resume / replay
R1=g2_m4b_r1_campaign('Run',true,'AuthToken',tok,'OutRoot',root,'StopAfterSolves',2);rd=strrep(R1.runDir,'<repo>',repo);
R2=g2_m4b_r1_campaign('Run',true,'AuthToken',tok,'OutRoot',root,'RunDir',rd,'StopAfterSolves',0);
tests=add(tests,'F13a_interrupt_after_case','INTERRUPTED after 2 solves',sprintf('%s solves %d',R1.status,R1.solves),strcmp(R1.status,'INTERRUPTED')&&R1.solves==2);
tests=add(tests,'F13b_resume_reuses_without_FEM','INTERRUPTED, 0 solves, 2 reused',sprintf('%s solves %d reused %d',R2.status,R2.solves,R2.reused),strcmp(R2.status,'INTERRUPTED')&&R2.solves==0&&R2.reused==2);
R3=g2_m4b_r1_campaign('Run',true,'AuthToken',tok,'OutRoot',root,'RunDir',rd);
tests=add(tests,'F13c_resume_completes','GO with 10 new solves, 2 reused',sprintf('%s solves %d reused %d',R3.status,R3.solves,R3.reused),strcmp(R3.status,'GO')&&R3.solves==10&&R3.reused==2);
[same,detail]=compare_runs(acceptedRun,rd,cellstr(pol.design.physicalCaseIds));
tests=add(tests,'F13d_bit_identical_replay','all 10 records + 2 legacy controls bitwise equal',detail,same);
after=cellfun(@hash_dir,guard,'UniformOutput',false);
m2after=cellfun(@(f)lower(g2_sha256_file(f)),m2files,'UniformOutput',false);
tests=add(tests,'F14_accepted_runs_unchanged','R1 run, M4.B run and M2 S2alt files unchanged',sprintf('%d + %d files, %d M2 files',size(before{1},1),size(before{2},1),numel(m2files)), ...
 isequal(before,after)&&isequal(m2before,m2after));
T=struct('schema','NewMetacomp.G2.M4B.R1.Faults.v1','issue',50,'tests',tests,'passed',nnz([tests.pass]),'total',numel(tests), ...
 'pass',all([tests.pass]),'root',strrep(root,repo,'<repo>'),'finished',datestr(now,31));
fid=fopen(fullfile(root,'FAULTS.json'),'w');fwrite(fid,jsonencode(sanitize(T,repo),'PrettyPrint',true),'char');fclose(fid);
fprintf('G2_M4B_R1_FAULTS %d/%d pass=%d\n',T.passed,T.total,T.pass);
end

% =====================================================================
function tests=add(tests,name,expected,observed,pass)
tests(end+1)=struct('name',name,'expected',expected,'observed',observed,'pass',logical(pass));
fprintf('FAULT %-44s expected [%s] observed [%s] -> %d\n',name,expected,observed,pass);
end

function [PM,geo,vopts]=phase_inputs(Dm,polM,polV2,pol,P)
fg=polM.frozenGeometry;pm=polM.phaseMap;
c=reshape(fg.holeCenters_mm,[],2);if ~isequal(c(:,1),[152.4;152.4;152.4]),c=reshape(fg.holeCenters_mm.',[],2);end
PM=g2_material_phase_map(Dm.X6,Dm.T6,c,fg.holeRadius_mm*ones(3,1),fg.interfaceRadius_mm*ones(3,1), ...
 struct('onCircleTol_mm',pm.onCircleTolerance_mm,'minGap_mm',pm.minGapToNextT3Vertex_mm,'midsideTol_mm',pm.midsideOnChordTolerance_mm));
qa=reshape(polM.sifGates.qAnnuli_mm,[],2);if size(qa,1)~=5,qa=reshape(polM.sifGates.qAnnuli_mm.',[],2);end
geo=struct('centres',c,'holeR',polV2.rings.holeRadius_mm*ones(3,1),'ringR',polV2.rings.outerRadius_mm*ones(3,1));
vopts=struct('onCircleTol_mm',pm.onCircleTolerance_mm,'midsideTol_mm',pm.midsideOnChordTolerance_mm,'areaRelTol',pm.areaIdentityRelTol, ...
 'domainAreaRelTol',pm.plateAreaIdentityRelTol,'outerArea_mm2',prod(fg.plate_mm),'expectedChords',pol.reference.chordsPerRing, ...
 'E_matrix',pol.materials.E_matrix_MPa,'nu',pol.materials.nu,'thickness_mm',pol.materials.thickness_mm,'tip',P(end,:), ...
 'tipGuideRadius_mm',fg.tipGuideRadius_mm,'qOuterRadii_mm',qa(:,2),'minQClearance_mm',polM.sifGates.minQSupportClearanceToReinforcement_mm, ...
 'twins',[Dm.upperBankT6(:),Dm.lowerBankT6(:)]);
end

function d=copy_run(src,dst)
mkdir(dst);fl=dir(src);fl=fl(~[fl.isdir]);
for k=1:numel(fl),copyfile(fullfile(src,fl(k).name),fullfile(dst,fl(k).name));end
d=dst;
end

function resign(d,name,fn,updateLedger)
S=load(fullfile(d,name),'record');r=fn(S.record);
delete(fullfile(d,name));delete(fullfile(d,[name,'.manifest.json']));
h=g2_trajectory_record('write',fullfile(d,name),r);
if updateLedger,relabel_ledger(d,name,h);end
end

function r=flip_kii(r)
r.K.KII=-r.K.KII;r.K.EDI_all(:,2)=-r.K.EDI_all(:,2);r.K.KII_MPa_sqrt_m_per_kN=-r.K.KII_MPa_sqrt_m_per_kN;
r.K.KII_COD=-r.K.KII_COD;r.K.EDI4x4(2)=-r.K.EDI4x4(2);
end

function relabel_ledger(d,name,h)
f=fullfile(d,'CASE_LEDGER.txt');t=splitlines(strtrim(fileread(f)));
for k=1:numel(t),if endsWith(strtrim(t{k}),['*',name]),t{k}=sprintf('%s *%s',lower(h),name);end,end
fid=fopen(f,'w');fprintf(fid,'%s\n',t{:});fclose(fid);
end

function [same,detail]=compare_runs(a,b,ids)
same=true;bad={};
f={'u','EDI_all','EDI4x4','KI_COD','KII_COD','J','compliance_mm_per_N','CMOD_mm','reactions','strainEnergy_per_thickness', ...
 'phaseStrainEnergy_per_thickness','ringStrainEnergy_per_thickness','elementStrainEnergy_per_thickness','activeInterfaceBalanceRel'};
for k=1:numel(ids)
 ra=load(fullfile(a,['CASE_',ids{k},'.mat']),'record');rb=load(fullfile(b,['CASE_',ids{k},'.mat']),'record');
 for q=1:numel(f),if ~isequal(ra.record.K.(f{q}),rb.record.K.(f{q})),same=false;bad{end+1}=[ids{k},'.',f{q}];end,end %#ok<AGROW>
end
for id={'c0p5_111','c2p0_111'}
 ra=load(fullfile(a,['CONTROL_LEGACY_',id{1},'.mat']),'record');rb=load(fullfile(b,['CONTROL_LEGACY_',id{1},'.mat']),'record');
 if ~isequal(ra.record.u,rb.record.u)||~isequal(ra.record.EDI_all,rb.record.EDI_all),same=false;bad{end+1}=['legacy ',id{1}];end %#ok<AGROW>
end
if same,detail=sprintf('%d records x %d fields + 2 legacy controls bitwise equal',numel(ids),numel(f));else,detail=strjoin(bad,', ');end
end

function H=hash_dir(d)
fl=dir(d);fl=fl(~[fl.isdir]);H=cell(numel(fl),2);
for k=1:numel(fl),H{k,1}=fl(k).name;H{k,2}=lower(g2_sha256_file(fullfile(d,fl(k).name)));end
end

function s=list_tree(d)
fl=dir(fullfile(d,'**','*'));fl=fl(~[fl.isdir]);s=sort(fullfile({fl.folder},{fl.name}));
end

function s=sanitize(s,repo)
if ischar(s),s=strrep(strrep(s,repo,'<repo>'),strrep(repo,'\','/'),'<repo>');
elseif isstruct(s)
 for k=1:numel(s),f=fieldnames(s);for j=1:numel(f),s(k).(f{j})=sanitize(s(k).(f{j}),repo);end,end
elseif iscell(s)
 for k=1:numel(s),s{k}=sanitize(s{k},repo);end
end
end
