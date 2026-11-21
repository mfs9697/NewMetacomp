function L = run_g2_m2_evolution_batch(~)
%RUN_G2_M2_EVOLUTION_BATCH  Issue #36: bonded-band shielding/steering at frozen S0, S1, S2 (+ S2alt).
%
%  L = run_g2_m2_evolution_batch()
% G2_M2_SHIELDING_STEERING_PREREGISTRATION.md / G2_M2_POLICY_v1.json. Stages:
%  G  global: release, clean committed tree, policy hashes, PR #35 module pin (git blobs
%     equal to 75a4bce), PR #35 benchmark record hash (no benchmark rerun if pinned)
%  per state S0 -> S1 -> S2: source + ledger, original auditor, adapter, phase map +
%     verifier + negatives, homogeneous regression, H1/M0 identity, Msoft, Mstiff,
%     ratio table (both uncertainty verdicts, steering); S2 also equals PR #35 run C
%  S2alt: preregistered alternative band mesh (built here, audited 34/34), same cases
%  summary: cross-state comparability, evolution reading, robustness classification
% A HOLD stops the current state and every later stage; earlier states are kept.
% Writes a NEW outputs/g2_material_evolution_v1/run_<time>/ (records never overwritten).
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
pol=jsondecode(fileread(fullfile(here,'G2_M2_POLICY_v1.json')));
polM=jsondecode(fileread(fullfile(here,'G2_MATERIAL_POLICY_v1.json')));
polT=jsondecode(fileread(fullfile(here,'G2_TRAJECTORY_POLICY_v1.json')));
outRoot=fullfile(repo,'outputs','g2_material_evolution_v1');if ~exist(outRoot,'dir'),mkdir(outRoot);end
folder=fullfile(outRoot,['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);
assert(~exist(folder,'dir'),'G2M2:RunExists','Run folder exists.');mkdir(folder);
diary(fullfile(folder,'m2_evolution_console.log'));cl=onCleanup(@()diary('off')); %#ok<NASGU>
L=struct('schema','NewMetacomp.G2.M2EvolutionLedger.v1','issue',36,'started',datestr(now,31),'status','RUNNING', ...
 'stages',struct([]),'states',struct(),'physicalFractureGrowthProven',false);
L.matlabRelease=['R',version('-release')];
L.policySHA256=g2_sha256_file(fullfile(here,'G2_M2_POLICY_v1.json'));
fprintf('G2_M2_EVOLUTION run %s, MATLAB %s, policy %s\n',strrep(folder,repo,'<repo>'),L.matlabRelease,L.policySHA256);
json=fullfile(repo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json');
p0=fullfile(repo,'outputs','g2_p010_isolated','run_20261118_163657_790','P010_ISOLATED_REGULAR_ONLY.mat');
Em=pol.materials.E_matrix_MPa;mk=@(E)struct('E',E,'nu',pol.materials.nu_matrix,'plane',pol.materials.plane);matM=mk(Em);
results=struct();
try
 % ================= G global
 assert(strcmp(L.matlabRelease,pol.resources.matlabRelease),'G2M2:Release','MATLAB %s is not R2023a.',L.matlabRelease);
 [s1,h]=system(sprintf('git -C "%s" rev-parse HEAD',repo));
 [s2,dt]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all -- matlab/g2 docs/research/crack-growth-gaps-2026',repo));
 assert(s1==0&&s2==0,'G2M2:Git','git unavailable.');L.gitHead=strtrim(h);
 assert(isempty(strtrim(dt)),'G2M2:DirtySource','Uncommitted or untracked sources:\n%s',dt);
 b=pol.base;
 assert(strcmpi(g2_sha256_file(fullfile(here,'G2_MATERIAL_POLICY_v1.json')),b.materialPolicyV1SHA256)&& ...
  strcmpi(g2_sha256_file(fullfile(here,'G2_TRAJECTORY_POLICY_v1.json')),b.trajectoryPolicyV1SHA256)&& ...
  strcmpi(g2_sha256_file(json),b.cornellJSON_SHA256)&&strcmpi(g2_sha256_file(p0),b.trustedP0SHA256),'G2M2:PolicyHash','A pinned policy/JSON/P0 hash differs.');
 mods=b.pr35QualifiedModulesMustBeByteIdenticalToParent;pinOK=true;pinInfo=struct();
 for k=1:numel(mods)
  [~,bh]=system(sprintf('git -C "%s" rev-parse HEAD:matlab/g2/%s',repo,mods{k}));
  [~,ph]=system(sprintf('git -C "%s" rev-parse %s:matlab/g2/%s',repo,b.parentHead,mods{k}));
  same=strcmp(strtrim(bh),strtrim(ph));pinOK=pinOK&&same;pinInfo.(matlab.lang.makeValidName(mods{k}))=same;
 end
 runC=fullfile(repo,b.pr35AcceptedRun);
 benchOK=strcmpi(g2_sha256_file(fullfile(runC,'BENCHMARK.mat')),b.pr35BenchmarkSHA256);
 [Bm,~,okB]=g2_trajectory_record('read',fullfile(runC,'BENCHMARK.mat'));
 assert(pinOK&&benchOK&&okB&&Bm.benchmark.pass,'G2M2:BenchmarkPin','PR #35 modules or benchmark not pinned: %s',jsonencode(pinInfo));
 src=[mods(:).',{'G2_M2_POLICY_v1.json','g2_m2_state_adapter.m','g2_material_case_summary.m','g2_material_ratio_table.m','check_g2_m2_phase_controls.m','run_g2_m2_evolution_batch.m'}];
 L.sourceHashes=cell2struct(cellfun(@(f)g2_sha256_file(fullfile(here,f)),src,'UniformOutput',false),matlab.lang.makeValidName(src),2);
 L=stage(L,'G_GLOBAL','PASS',struct('gitHead',L.gitHead,'pr35ModulesPinned',true,'benchmarkRecordSHA256',b.pr35BenchmarkSHA256, ...
  'benchmarkRerun',false,'benchmarkChecks',sprintf('%d/%d',nnz(cell2mat(struct2cell(Bm.benchmark.checks))),numel(fieldnames(Bm.benchmark.checks)))));
 % ================= states in ascending arclength
 st=pol.states;if ~iscell(st),st=num2cell(st);end
 for i=1:numel(st)
  S=st{i};P=S.polyline_mm;assert(size(P,2)==2&&size(P,1)==i+1,'G2M2:Polyline','%s polyline shape.',S.id);
  meshFile=fullfile(repo,S.mesh);
  % ---- source
  hm=g2_sha256_file(meshFile);
  assert(strcmpi(hm,S.meshSHA256),'G2M2:MeshHash','%s mesh hash %s.',S.id,hm);
  assert(ledger_has(fullfile(repo,S.ledger),S.meshSHA256,S.mesh),'G2M2:Ledger','%s mesh not in its committed ledger.',S.id);
  D=load(meshFile);
  assert(size(D.T6,1)==S.expectedT3,'G2M2:MeshSize','%s T3 count %d.',S.id,size(D.T6,1));
  rec=struct();
  switch S.id
   case 'S0'
    assert(strcmpi(g2_sha256_file(fullfile(repo,S.recordedK)),S.recordedKSHA256)&&ledger_has(fullfile(repo,S.ledger),S.recordedKSHA256,S.recordedK), ...
     'G2M2:S0Record','S0 WP2 record hash.');
    rec=load(fullfile(repo,S.recordedK));
   case 'S1'
    [S1r,hs,ok]=g2_wp3_state_io('load',fullfile(repo,S.state));
    assert(ok&&strcmpi(hs,S.stateSHA256)&&strcmpi(S1r.meshSHA256,hm),'G2M2:S1Record','S1 State record.');rec=S1r;
   case 'S2'
    chain=fullfile(repo,'outputs','g2_trajectory_chain_v1_attempt2');
    [Rev,rh,okv]=g2_trajectory_record('read',fullfile(chain,'STEP_002','REVIEW.mat'));
    [S2r,~,oks]=g2_wp3_state_io('load',fullfile(chain,'STEP_002','state'));
    assert(okv&&oks&&strcmpi(rh,S.reviewSHA256)&&strcmpi(Rev.meshSHA256,hm)&&strcmpi(S2r.reviewSHA256,rh),'G2M2:S2Record','S2 chain records.');rec=Rev;
  end
  % ---- original auditor (unchanged tools)
  if strcmp(S.id,'S0')
   C38=g2_independent_t6_checker(D,json);CP=g2_protected_tip_checker(D,json,p0);
   audOK=C38.pass&&CP.pass&&C38.gatesPassed==38&&CP.gatesPassed==24;audit=sprintf('%d/%d + %d/%d',C38.gatesPassed,C38.gatesTotal,CP.gatesPassed,CP.gatesTotal);
  else
   A=g2_kinked_mesh_auditor(D,json,p0,size(P,1));audOK=A.pass&&A.gatesPassed==34&&A.gatesTotal==34;audit=sprintf('%d/%d',A.gatesPassed,A.gatesTotal);
  end
  assert(audOK,'G2M2:Audit','%s original audit failed (%s).',S.id,audit);
  % ---- adapter
  [Dm,Ad]=g2_m2_state_adapter(D,S.id,P);
  assert(Ad.pass,'G2M2:Adapter','%s adapter: %s',S.id,strjoin(Ad.failed,', '));
  % ---- phase map, verifier, negatives, geometry metrics
  [PM,V,NC,geom]=phase_stage(Dm,polM,P);
  assert(PM.pass,'G2M2:PhaseMap','%s %s: %s',S.id,PM.stage,PM.message);
  assert(V.pass,'G2M2:PhaseVerify','%s verifier: %s',S.id,strjoin(V.failed,', '));
  assert(NC.pass,'G2M2:PhaseNegatives','%s: a phase negative control was accepted.',S.id);
  hP=g2_trajectory_record('write',fullfile(folder,['PHASE_MAP_',S.id,'.mat']),struct('schema','NewMetacomp.G2.MaterialPhaseMap.v1', ...
   'state',S.id,'phase',PM.phase,'annulusOf',PM.annulusOf,'interfaces',PM.interfaces,'verifier',V,'negatives',NC,'meshSHA256',hm,'adapter',Ad));
  % ---- homogeneous regression
  [SH,KH,bc,loadNode,regr]=homogeneous_stage(S.id,Dm,matM,polT,rec);
  assert(regr.pass,'G2M2:Regression','%s regression failed: %s',S.id,jsonencode(regr));
  % ---- identity, contrasts, ratios
  [Cs,idv]=material_cases(Dm,PM,SH,KH,loadNode,matM,mk,pol,polM,polT,folder,S.id);
  T=g2_material_ratio_table(Cs.H1,[Cs.M0,Cs.Msoft,Cs.Mstiff],polM,Dm.tipTangent(:).');
  extra=struct();
  if strcmp(S.id,'S2'),extra=pr35_regression(runC,Cs,T,folder);end
  results.(S.id)=struct('arc_mm',S.arc_mm,'meshSHA256',hm,'audit',audit,'adapter',Ad,'geometry',geom,'regression',regr, ...
   'identity',idv,'cases',Cs,'table',T,'phaseRecordSHA256',hP,'extra',extra,'tangentGlobal_deg',atan2d(Dm.tipTangent(2),Dm.tipTangent(1)));
  L=stage(L,['STATE_',S.id],'PASS',struct('audit',audit,'chords',geom.chordsPerCircle,'bandArea_mm2',geom.annulusArea_mm2, ...
   'qClearance_mm',geom.qClearance_mm,'R_soft',T(2).R_EDI,'R_stiff',T(3).R_EDI,'extra',extra));
  clear SH KH D Dm
 end
 % ================= S2alt robustness mesh
 alt=alt_stage(pol,polM,polT,mk,matM,json,p0,folder,results.S2);
 results.S2alt=alt;
 L=stage(L,'S2ALT',alt.status,struct('T3',alt.T3,'audit',alt.audit,'classification',alt.classification));
 % ================= summary
 L.summary=summarize(results,pol);
 L=stage(L,'SUMMARY','PASS',struct());
 L.status='GO';
catch ME
 fprintf(2,'HOLD %s: %s\n',ME.identifier,ME.message);
 L.status='HOLD';L.hold=struct('identifier',ME.identifier,'message',ME.message,'stack',ME.stack(1).name,'line',ME.stack(1).line);
end
L.results=strip_results(results);L.finished=datestr(now,31);
fid=fopen(fullfile(folder,'LEDGER.json'),'w');fwrite(fid,jsonencode(sanitize(L,repo),'PrettyPrint',true),'char');fclose(fid);
diary('off');
fl=dir(folder);fl=fl(~[fl.isdir]);fid=fopen(fullfile(folder,'SHA256SUMS.txt'),'w');
for k=1:numel(fl),if ~strcmp(fl(k).name,'SHA256SUMS.txt'),fprintf(fid,'%s *%s\n',lower(g2_sha256_file(fullfile(folder,fl(k).name))),fl(k).name);end,end
fclose(fid);
fprintf('G2_M2_EVOLUTION_STATUS=%s\n',L.status);
end

% =====================================================================
function [PM,V,NC,geom]=phase_stage(Dm,polM,P)
fg=polM.frozenGeometry;pm=polM.phaseMap;
c=reshape(fg.holeCenters_mm,[],2);if ~isequal(c(:,1),[152.4;152.4;152.4]),c=reshape(fg.holeCenters_mm.',[],2);end
geo=struct('centers',c,'holeR',fg.holeRadius_mm*ones(3,1),'interfaceR',fg.interfaceRadius_mm*ones(3,1));
PM=g2_material_phase_map(Dm.X6,Dm.T6,geo.centers,geo.holeR,geo.interfaceR, ...
 struct('onCircleTol_mm',pm.onCircleTolerance_mm,'minGap_mm',pm.minGapToNextT3Vertex_mm,'midsideTol_mm',pm.midsideOnChordTolerance_mm));
V=struct('pass',false,'failed',{{'not run'}});NC=struct('pass',false);geom=struct();
fprintf('PHASE_MAP pass=%d %s: %s\n',PM.pass,PM.stage,PM.message);
if ~PM.pass,return,end
qa=reshape(polM.sifGates.qAnnuli_mm,[],2);if size(qa,1)~=5,qa=reshape(polM.sifGates.qAnnuli_mm.',[],2);end
vopts=struct('onCircleTol_mm',pm.onCircleTolerance_mm,'minGap_mm',pm.minGapToNextT3Vertex_mm,'areaRelTol',pm.areaIdentityRelTol, ...
 'domainAreaRelTol',pm.plateAreaIdentityRelTol,'outerArea_mm2',prod(fg.plate_mm),'twins',[Dm.upperBankT6(:),Dm.lowerBankT6(:)], ...
 'tip',P(end,:),'tipGuideRadius_mm',fg.tipGuideRadius_mm,'qOuterRadii_mm',qa(:,2),'minQClearance_mm',polM.sifGates.minQSupportClearanceToReinforcement_mm, ...
 'voidTol_mm',pm.voidPenetrationTolerance_mm);
V=g2_material_phase_verify(Dm.X6,Dm.T6,PM.phase,geo.centers,geo.holeR,geo.interfaceR,vopts);
fprintf('PHASE_VERIFY pass=%d failed=[%s]\n',V.pass,strjoin(V.failed,','));
if ~V.pass,return,end
NC=check_g2_m2_phase_controls(Dm,PM,geo,vopts);   % M2 run A: state-aware N7 (PR #35 module run unchanged inside)
v=V.values;
x=Dm.X6(:,1);y=Dm.X6(:,2);T3=Dm.T6(:,1:3);
Ael=.5*((x(T3(:,2))-x(T3(:,1))).*(y(T3(:,3))-y(T3(:,1)))-(x(T3(:,3))-x(T3(:,1))).*(y(T3(:,2))-y(T3(:,1))));
geom=struct('counts',v.counts,'chordsPerCircle',v.chordsPerCircle,'holeVerticesPerCircle',v.holeVerticesPerCircle, ...
 'annulusArea_mm2',v.annulusArea_mm2,'annulusNominalArea_mm2',v.annulusNominalArea_mm2,'polygonVsNominalRel',v.polygonVsNominalRel, ...
 'bandVolumeFraction',sum(Ael(PM.phase==2))/sum(Ael),'tipToBand_mm',v.reinforcementNodeMinDistanceToTip_mm,'qClearance_mm',v.qClearance_mm, ...
 'mixedEdges',v.mixedEdges,'coincidentPairs',v.coincidentPairs,'domainAreaRelErr',v.domainAreaRelErr,'annulusAreaRelErr',v.annulusAreaRelErr);
end

function [SH,KH,bc,loadNode,regr]=homogeneous_stage(id,Dm,matM,polT,rec)
N=size(Dm.X6,1);f=polT.bvp.P_N/polT.bvp.thickness_mm;
nodeAt=@(xy)Dm.extraVertexNodes(vecnorm(reshape(Dm.extraVertexXY,[],2)-reshape(xy,1,2),2,2)<1e-9);
pin=nodeAt(polT.bvp.pin_mm);roller=nodeAt(polT.bvp.roller_mm);loadNode=nodeAt(polT.bvp.load_mm);
assert(isscalar(pin)&&isscalar(roller)&&isscalar(loadNode),'G2M2:Anchors','%s BVP anchors.',id);
F=zeros(2*N,1);F(2*loadNode)=-f;bc=struct('fixedDofs',[2*pin-1;2*pin;2*roller],'fixedValues',[0;0;0],'F',F);
SH=g2_t6_elasticity(Dm.X6,Dm.T6,matM,bc);
KH=g2_trajectory_sif_on_mesh(Dm,matM,polT);
Kr=hypot(KH.KI,KH.KII);regr=struct('id',id,'sifPass',KH.pass);
switch id
 case 'S0'
  tip=Dm.X3(Dm.physicalTipNode,:);an=[.4 2.6;.2 1.0;.4 1.6;.8 2.6;1.2 2.4];ed=zeros(5,3);
  for j=1:5,Rj=g2_sif_interaction(Dm.X6,Dm.T6,SH.u,matM,tip,[0 1],an(j,1),an(j,2),6);ed(j,:)=[Rj.KI,Rj.KII,Rj.J];end
  Cc=g2_sif_cod(Dm.X6,Dm.T6,SH.u,matM,tip,[0 1],[.1 1.5]);
  regr.wp2EDI_rel=max(abs(ed(:,1:2)-rec.ed(:,1:2)),[],'all')/Kr;regr.wp2J_rel=max(abs(ed(:,3)-rec.ed(:,3)))/max(abs(rec.ed(:,3)));
  regr.wp2COD_rel=max(abs([Cc.KI-rec.Cod.KI,Cc.KII-rec.Cod.KII]))/Kr;
  regr.pipelineEDI_vs_wp2_rel=max(abs(KH.EDI_all(:,1:2)-ed(:,1:2)),[],'all')/Kr;
  regr.adapterBankCOD_vs_wp2COD_rel=max(abs([KH.KI_COD-Cc.KI,KH.KII_COD-Cc.KII]))/Kr;
  regr.pass=KH.pass&&regr.wp2EDI_rel<=1e-12&&regr.wp2J_rel<=1e-12&&regr.wp2COD_rel<=1e-12&& ...
   regr.pipelineEDI_vs_wp2_rel<=1e-12&&regr.adapterBankCOD_vs_wp2COD_rel<=1e-10;
 case 'S1'
  regr.EDI_rel=max(abs([KH.KI-rec.KI_raw,KH.KII-rec.KII_raw]))/Kr;
  regr.COD_rel=max(abs([KH.KI_COD*sqrt(1000)-rec.KI_COD_MPa_sqrt_m_per_kN,KH.KII_COD*sqrt(1000)-rec.KII_COD_MPa_sqrt_m_per_kN]))/(Kr*sqrt(1000));
  regr.pass=KH.pass&&regr.EDI_rel<=1e-12&&regr.COD_rel<=1e-12;
 case 'S2'
  regr.EDI_COD_rel=max(abs([KH.KI-rec.sif.KI,KH.KII-rec.sif.KII,KH.KI_COD-rec.sif.KI_COD,KH.KII_COD-rec.sif.KII_COD]))/hypot(rec.sif.KI,rec.sif.KII);
  regr.pass=KH.pass&&regr.EDI_COD_rel<=1e-12;
 otherwise
  regr.pass=KH.pass;   % S2alt: no historical record
end
fprintf('REGRESSION %s pass=%d %s\n',id,regr.pass,jsonencode(regr));
end

function [Cs,idv]=material_cases(Dm,PM,SH,KH,loadNode,matM,mk,pol,polM,polT,folder,id)
Em=matM.E;f=polT.bvp.P_N/polT.bvp.thickness_mm;
H1=g2_material_case_summary('H1',KH,SH,loadNode,polT,1);
K0=g2_material_sif_on_mesh(Dm,PM.phase,[matM,mk(Em)],polT,PM);
im=polM.identityM0;Kref=hypot(KH.KI,KH.KII);
dK=full(max(abs(SH.K-K0.K),[],'all'))/full(max(abs(SH.K),[],'all'));
dU=max(abs(SH.u-K0.u))/max(abs(SH.u));
dKs=max(abs([KH.KI-K0.KI,KH.KII-K0.KII,KH.KI_COD-K0.KI_COD,KH.KII_COD-K0.KII_COD,reshape(KH.EDI_all(:,1:2)-K0.EDI_all(:,1:2),1,[])]))/Kref;
dE=abs(SH.strainEnergy-K0.strainEnergy_per_thickness)/SH.strainEnergy;
dR=max(abs(SH.reactions-K0.reactions))/f;
dC=abs(abs(SH.u(2*loadNode))-K0.compliance_mm_per_N*polT.bvp.P_N)/abs(SH.u(2*loadNode));
dT=abs(g2_mts_direction(KH.KI_MPa_sqrt_m_per_kN,KH.KII_MPa_sqrt_m_per_kN).theta_deg-g2_mts_direction(K0.KI_MPa_sqrt_m_per_kN,K0.KII_MPa_sqrt_m_per_kN).theta_deg);
idc=struct('stiffness',dK<=im.stiffnessMatrixRelTol,'displacement',dU<=im.displacementRelTol,'K',dKs<=im.KRelTolOfKref, ...
 'energy',dE<=im.energyRelTol,'reactions',dR<=im.reactionRelTolOfP,'compliance',dC<=im.complianceRelTol,'MTS',dT<=im.MTSAbsTol_deg,'M0gates',K0.pass);
idv=struct('checks',idc,'stiffness',dK,'displacement',dU,'K',dKs,'energy',dE,'reactions',dR,'compliance',dC,'MTS_deg',dT, ...
 'bitwiseUandEDI',isequal(SH.u,K0.u)&&isequal(KH.EDI_all,K0.EDI_all));
fprintf('IDENTITY %s: K %.3g u %.3g SIF %.3g energy %.3g reactions %.3g compliance %.3g MTS %.3g bitwise=%d\n',id,dK,dU,dKs,dE,dR,dC,dT,idv.bitwiseUandEDI);
M0=g2_material_case_summary('M0',K0,[],loadNode,polT,1);
write_case(folder,id,'H1',H1,SH.u);write_case(folder,id,'M0',M0,K0.u);
assert(all(cell2mat(struct2cell(idc))),'G2M2:Identity','%s M0 identity failed: %s',id,jsonencode(idv));
clear K0
Cs=struct('H1',H1,'M0',M0);
cases={'Msoft',.5;'Mstiff',2};
for i=1:2
 Kc=g2_material_sif_on_mesh(Dm,PM.phase,[matM,mk(cases{i,2}*Em)],polT,PM);
 Sm=g2_material_case_summary(cases{i,1},Kc,[],loadNode,polT,cases{i,2});
 write_case(folder,id,cases{i,1},Sm,Kc.u);
 assert(Kc.pass,'G2M2:ContrastGate','%s %s failed: %s',id,cases{i,1},strjoin(Kc.failedCriteria,', '));
 Cs.(cases{i,1})=Sm;clear Kc
end
end

function extra=pr35_regression(runC,Cs,T,folder)
ids={'H1','M0','Msoft','Mstiff'};same=struct();
for k=1:4
 [r,~,ok]=g2_trajectory_record('read',fullfile(runC,['CASE_',ids{k},'.mat']));
 [n,~,okn]=g2_trajectory_record('read',fullfile(folder,['CASE_S2_',ids{k},'.mat']));
 same.(ids{k})=ok&&okn&&isequal(r.u,n.u)&&isequal(r.EDI_all,n.EDI_all)&&isequal(r.EDI4x4,n.EDI4x4)&& ...
  isequal([r.KI_COD_raw r.KII_COD_raw],[n.KI_COD_raw n.KII_COD_raw])&&isequal(r.compliance_mm_per_N,n.compliance_mm_per_N)&&isequal(r.CMOD_mm,n.CMOD_mm);
end
Lc=jsondecode(fileread(fullfile(runC,'LEDGER.json')));Tc=Lc.results.ratios;
f={'R_EDI','R_COD','R_J','U_R','U_R_conservative','MTS_deg','dMTS_deg','complianceRatio','CMODratio'};dev=0;
for k=1:numel(Tc)
 for q=1:numel(f),dev=max(dev,abs(T(k).(f{q})-Tc(k).(f{q}))/max(abs(Tc(k).(f{q})),1e-9));end
end
extra=struct('caseArraysEqualPR35',same,'ratioTableMaxRelDevVsPR35Ledger',dev, ...
 'pass',all(cell2mat(struct2cell(same)))&&dev<=1e-12);
fprintf('PR35_REGRESSION arrays %s, ratio-table max rel dev %.3g -> pass=%d\n',jsonencode(same),dev,extra.pass);
assert(extra.pass,'G2M2:PR35Regression','S2 does not reproduce PR #35 run C.');
end

function alt=alt_stage(pol,polM,polT,mk,matM,json,p0,folder,S2)
A=pol.alternativeMeshS2;alt=struct('status','HOLD','T3',NaN,'audit','not run','classification',struct());
st=pol.states;if ~iscell(st),st=num2cell(st);end
D2=load(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))),st{3}.mesh));t=D2.tipTangent(:).';
% M2 run C: build from the SAVED full-precision S2 polyline (K1 needs exact 4 mm segments);
% it must equal the preregistered 10-decimal polyline to 1e-9 mm.
P=D2.crackPolyline;assert(max(abs(P-st{3}.polyline_mm),[],'all')<=1e-9,'G2M2:AltPolyline','Saved S2 polyline differs from the preregistered one.');clear D2
opts={'BottomVertices_mm',[25.4 482.6],'TopVertices_mm',254,'TipGuideRadius_mm',15,'TipGuideHface_mm',1.5,'GuideHface_mm',1.0,'Hmax_mm',5};
B=g2_kinked_join(P,'ExteriorOptions',opts,'ExpectedVertices',size(P,1),'MaxT3Elements',pol.resources.maxT3,'ExpectedTangent',t);
assert(B.pass,'G2M2:AltJoin','S2alt join HOLD: %s %s',B.stage,B.message);
X3=B.X3;T3=B.T3;X6=B.X6;T6=B.T6;upperBankT6=B.upperBankT6;lowerBankT6=B.lowerBankT6; %#ok<NASGU>
physicalTipNode=B.physicalTipNode;nodalQ=B.nodalQ;qActiveT6Rows=B.qActiveT6Rows;elementRows=B.elementRows; %#ok<NASGU>
collarOuterIDs=B.collarOuterIDs;extraVertexXY=B.extraVertexXY;extraVertexNodes=B.extraVertexNodes;crackPolyline=P; %#ok<NASGU>
tipTangent=t;tipNormal=[-t(2),t(1)];kinkNodeIDs=B.kinkNodeIDs;geometryOnly=true;approvedForLEFM=false; %#ok<NASGU>
plateXRange=B.plateXRange;includeHoles=true;mirrorControl=false; %#ok<NASGU>
mf=fullfile(folder,'S2ALT_KINKED_GEOMETRY_ONLY_candidate.mat');assert(~isfile(mf));
save(mf,'X3','T3','X6','T6','upperBankT6','lowerBankT6','physicalTipNode','nodalQ','qActiveT6Rows','elementRows', ...
 'collarOuterIDs','extraVertexXY','extraVertexNodes','crackPolyline','tipTangent','tipNormal','kinkNodeIDs', ...
 'geometryOnly','approvedForLEFM','plateXRange','includeHoles','mirrorControl','-v7.3');
alt.meshSHA256=g2_sha256_file(mf);D=load(mf);
C=g2_kinked_mesh_auditor(D,json,p0,size(P,1));
alt.T3=C.summary.T3elements;alt.audit=sprintf('%d/%d',C.gatesPassed,C.gatesTotal);
alt.minAngle_deg=C.summary.minAngle_deg;alt.maxNeighborRatio=C.summary.maxNeighborRatio;
assert(C.pass&&C.gatesPassed==34&&alt.T3<=pol.resources.maxT3&&alt.minAngle_deg>=20&&alt.maxNeighborRatio<=1.8,'G2M2:AltAudit','S2alt audit %s, T3 %d.',alt.audit,alt.T3);
[Dm,Ad]=g2_m2_state_adapter(D,'S2alt',P);assert(Ad.pass,'G2M2:AltAdapter','S2alt adapter.');
[PM,V,NC,geom]=phase_stage(Dm,polM,P);
assert(PM.pass&&V.pass&&NC.pass,'G2M2:AltPhase','S2alt phase stage failed.');
hP=g2_trajectory_record('write',fullfile(folder,'PHASE_MAP_S2alt.mat'),struct('schema','NewMetacomp.G2.MaterialPhaseMap.v1', ...
 'state','S2alt','phase',PM.phase,'annulusOf',PM.annulusOf,'interfaces',PM.interfaces,'verifier',V,'negatives',NC,'meshSHA256',alt.meshSHA256));
[SH,KH,~,loadNode,regr]=homogeneous_stage('S2alt',Dm,matM,polT,struct());
assert(regr.pass,'G2M2:AltH1','S2alt homogeneous SIF gates failed.');
[Cs,idv]=material_cases(Dm,PM,SH,KH,loadNode,matM,mk,pol,polM,polT,folder,'S2alt');
T=g2_material_ratio_table(Cs.H1,[Cs.M0,Cs.Msoft,Cs.Mstiff],polM,t);
cls=struct();
for k=2:3
 dO=S2.table(k).R_EDI-1;dA=T(k).R_EDI-1;
 if sign(dO)~=sign(dA),c='NOT_ROBUST';elseif abs(dA-dO)<=.10*abs(dO),c='ROBUST';else,c='SENSITIVE';end
 cls.(T(k).id)=struct('dR_orig',dO,'dR_alt',dA,'relChange',abs(dA-dO)/abs(dO),'class',c, ...
  'dMTS_orig_deg',S2.table(k).dMTS_deg,'dMTS_alt_deg',T(k).dMTS_deg);
end
alt.classification=cls;alt.geometry=geom;alt.identity=idv;alt.cases=Cs;alt.table=T;alt.phaseRecordSHA256=hP;
alt.H1vsS2_KI_rel=(KH.KI-S2.cases.H1.KI_raw)/S2.cases.H1.KI_raw;alt.H1vsS2_KII_rel=(KH.KII-S2.cases.H1.KII_raw)/S2.cases.H1.KII_raw;
alt.status='PASS';
fprintf('S2ALT T3=%d audit %s chords %s; soft dR %.5f vs %.5f (%s); stiff dR %.5f vs %.5f (%s)\n',alt.T3,alt.audit,mat2str(geom.chordsPerCircle), ...
 cls.Msoft.dR_alt,cls.Msoft.dR_orig,cls.Msoft.class,cls.Mstiff.dR_alt,cls.Mstiff.dR_orig,cls.Mstiff.class);
end

function U=summarize(results,pol)
ids={'S0','S1','S2'};U=struct();
A2=results.S2.geometry.annulusArea_mm2;c2=results.S2.geometry.chordsPerCircle;eq=true;
for k=1:3
 g=results.(ids{k}).geometry;eq=eq&&isequal(g.chordsPerCircle,c2)&&max(abs(g.annulusArea_mm2-A2)./A2)<=1e-4;
end
U.crossStateGeometry=ternary(eq,'GEOMETRY-EQUIVALENT','GEOMETRY-CONFOUNDED');
for m={'Msoft','Mstiff'}
 R=zeros(1,3);res=false(1,3);resc=false(1,3);dth=zeros(1,3);dthres=false(1,3);
 for k=1:3
  t=results.(ids{k}).table(strcmp({results.(ids{k}).table.id},m{1}));
  R(k)=t.R_EDI;res(k)=t.resolved;resc(k)=t.resolvedConservative;dth(k)=t.dMTS_deg;dthres(k)=t.dMTSresolved;
 end
 sg=sign(R-1);
 if all(res)&&all(sg==sg(1)),ev='PERSISTS_SAME_SIGN_ALL_RESOLVED';
 elseif any(res&sg>0)&&any(res&sg<0),ev='SIGN_CHANGE_BETWEEN_RESOLVED_STATES';
 else,ev='NOT_ALL_RESOLVED';end
 mg=abs(R-1);
 if all(diff(mg)>0),tr='MAGNITUDE_INCREASES_WITH_S';elseif all(diff(mg)<0),tr='MAGNITUDE_DECREASES_WITH_S';else,tr='MAGNITUDE_NON_MONOTONE';end
 U.(m{1})=struct('R',R,'resolvedPrimary',res,'resolvedConservative',resc,'evolution',ev,'magnitudeTrend',tr, ...
  'dMTS_deg',dth,'dMTSresolved',dthres,'steeringSameSignAllStates',all(sign(dth)==sign(dth(1))));
end
U.G_H1_1N_N_per_mm=arrayfun(@(k)results.(ids{k}).table(1).G_H1_1N_N_per_mm,1:3);
end

function r=ternary(c,a,b),if c,r=a;else,r=b;end,end

function ok=ledger_has(file,hash,path)
ok=false;if ~isfile(file),return,end
txt=splitlines(fileread(file));rel=regexprep(path,'^outputs/','');
for k=1:numel(txt)
 l=strtrim(txt{k});
 if startsWith(lower(l),lower(hash))&&endsWith(l,['*',rel]),ok=true;return,end
end
end

function write_case(folder,state,id,S,u)
R=S;R.schema='NewMetacomp.G2.MaterialCase.v1';R.state=state;R.u=u;
g2_trajectory_record('write',fullfile(folder,['CASE_',state,'_',id,'.mat']),R);
end

function L=stage(L,name,status,info)
s=struct('name',name,'status',status,'info',info);
if isempty(L.stages),L.stages=s;else,L.stages(end+1)=s;end
fprintf('STAGE %s %s\n',name,status);
end

function R=strip_results(R)
f=fieldnames(R);
for k=1:numel(f)
 if isfield(R.(f{k}),'cases')
  c=fieldnames(R.(f{k}).cases);
  for j=1:numel(c),R.(f{k}).cases.(c{j})=rmfield(R.(f{k}).cases.(c{j}),'chordTractions');end
 end
end
end

function s=sanitize(s,repo)
if ischar(s),s=strrep(strrep(s,repo,'<repo>'),strrep(repo,'\','/'),'<repo>');
elseif isstruct(s)
 for k=1:numel(s)
  f=fieldnames(s);
  for j=1:numel(f),s(k).(f{j})=sanitize(s(k).(f{j}),repo);end
 end
elseif iscell(s)
 for k=1:numel(s),s{k}=sanitize(s{k},repo);end
end
end
