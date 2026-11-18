function L = run_g2_material_contrast_batch(chainDir)
%RUN_G2_MATERIAL_CONTRAST_BATCH  Issue #33: frozen State 2 two-phase contrast, stop on first HOLD.
%
%  L = run_g2_material_contrast_batch(chainDir)   % chainDir = <repo>/outputs/g2_trajectory_chain_v1_attempt2
% Stages (G2_MATERIAL_CONTRAST_PREREGISTRATION.md s.5):
%  S0 SOURCE   clean committed tree, chain/mesh/policy/JSON/P0 hashes, record integrity,
%              34/34 re-audit of the saved mesh (unchanged auditor), frozen polyline
%  S1 PHASE    topological mapper, independent geometric verifier, phase negatives
%  S2 BENCH    exact coated-hole benchmark + SIF-level q-phase negative control
%  S3 IDENTITY H1 (unchanged solver + SIF) versus M0 (phase-aware, ratio 1)
%  S4 CONTRAST Msoft (0.5), Mstiff (2), all gates
%  S5 RATIOS   G, R_mat with uncertainty, mixity, MTS forecast, compliance, CMOD
% Writes a NEW outputs/g2_material_contrast_v1/run_<time>/ (records never overwritten),
% LEDGER.json and SHA256SUMS.txt. The chain is read only. No crack growth.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
chainDir=char(chainDir);
pol=jsondecode(fileread(fullfile(here,'G2_MATERIAL_POLICY_v1.json')));
polT=jsondecode(fileread(fullfile(here,'G2_TRAJECTORY_POLICY_v1.json')));
outRoot=fullfile(repo,'outputs','g2_material_contrast_v1');if ~exist(outRoot,'dir'),mkdir(outRoot);end
folder=fullfile(outRoot,['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);
assert(~exist(folder,'dir'),'G2Material:RunExists','Run folder exists.');mkdir(folder);
diary(fullfile(folder,'material_contrast_console.log'));cl=onCleanup(@()diary('off')); %#ok<NASGU>
L=struct('schema','NewMetacomp.G2.MaterialContrastLedger.v1','issue',33,'started',datestr(now,31), ...
 'status','RUNNING','stages',struct([]),'physicalFractureGrowthProven',false);
L.matlabRelease=['R',version('-release')];   % version('-release') returns '2023a' (run A HOLD)
L.policySHA256=g2_sha256_file(fullfile(here,'G2_MATERIAL_POLICY_v1.json'));
fprintf('G2_MATERIAL_CONTRAST run %s, MATLAB %s, policy %s\n',strrep(folder,repo,'<repo>'),L.matlabRelease,L.policySHA256);
try
 % ================= S0 SOURCE
 assert(strcmp(L.matlabRelease,pol.resources.matlabRelease),'G2Material:Release','MATLAB %s is not R2023a.',L.matlabRelease);
 [s1,h]=system(sprintf('git -C "%s" rev-parse HEAD',repo));
 [s2,dt]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all -- matlab/g2 docs/research/crack-growth-gaps-2026',repo));
 assert(s1==0&&s2==0,'G2Material:Git','git unavailable.');L.gitHead=strtrim(h);
 assert(isempty(strtrim(dt)),'G2Material:DirtySource','Uncommitted or untracked sources:\n%s',dt);
 src={'G2_MATERIAL_POLICY_v1.json','g2_t6_elasticity_phase.m','g2_material_phase_map.m','g2_material_phase_verify.m', ...
  'g2_coated_hole_exact.m','g2_t6_point_stress.m','g2_material_sif_on_mesh.m','check_g2_material_benchmark.m', ...
  'check_g2_material_phase_controls.m','run_g2_material_contrast_batch.m','g2_t6_elasticity.m','g2_trajectory_sif_on_mesh.m', ...
  'g2_sif_interaction.m','g2_sif_cod_banks.m','g2_williams_field.m','g2_plane_D.m','g2_mts_direction.m','g2_kinked_mesh_auditor.m', ...
  'g2_trajectory_record.m','g2_wp3_state_io.m','g2_sha256_file.m','G2_TRAJECTORY_POLICY_v1.json'};
 L.sourceHashes=cell2struct(cellfun(@(f)g2_sha256_file(fullfile(here,f)),src,'UniformOutput',false),matlab.lang.makeValidName(src),2);
 jsonFile=fullfile(repo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json');
 p0Mat=fullfile(repo,'outputs','g2_p010_isolated','run_20261118_163657_790','P010_ISOLATED_REGULAR_ONLY.mat');
 meshFile=fullfile(chainDir,'STEP_002','KINKED_GEOMETRY_ONLY_candidate.mat');
 hs=struct('root',g2_sha256_file(fullfile(chainDir,'ROOT.mat')),'review',g2_sha256_file(fullfile(chainDir,'STEP_002','REVIEW.mat')), ...
  'state2',g2_sha256_file(fullfile(chainDir,'STEP_002','state','state.mat')),'mesh',g2_sha256_file(meshFile), ...
  'trajectoryPolicy',g2_sha256_file(fullfile(here,'G2_TRAJECTORY_POLICY_v1.json')),'cornellJSON',g2_sha256_file(jsonFile),'p0',g2_sha256_file(p0Mat));
 b=pol.base;
 ok=strcmpi(hs.root,b.rootSHA256)&&strcmpi(hs.review,b.reviewSHA256)&&strcmpi(hs.state2,b.state2SHA256)&&strcmpi(hs.mesh,b.meshSHA256)&& ...
  strcmpi(hs.trajectoryPolicy,b.trajectoryPolicySHA256)&&strcmpi(hs.cornellJSON,b.cornellJSON_SHA256)&&strcmpi(hs.p0,b.trustedP0SHA256);
 assert(ok,'G2Material:SourceHash','A pinned source hash differs: %s',jsonencode(hs));
 [~,~,okR]=g2_trajectory_record('read',fullfile(chainDir,'ROOT.mat'));
 [Rev,revHash,okV]=g2_trajectory_record('read',fullfile(chainDir,'STEP_002','REVIEW.mat'));
 [S2,~,okS]=g2_wp3_state_io('load',fullfile(chainDir,'STEP_002','state'));
 assert(okR&&okV&&okS&&strcmpi(Rev.meshSHA256,hs.mesh)&&strcmpi(S2.reviewSHA256,revHash),'G2Material:ChainIntegrity','Chain record integrity failed.');
 D=load(meshFile);
 Pf=pol.frozenGeometry.crackPolyline_mm;Pf=reshape(Pf,[],2);if size(Pf,1)~=4,Pf=reshape(pol.frozenGeometry.crackPolyline_mm.',[],2);end
 assert(max(abs(D.crackPolyline-Pf),[],'all')<=pol.frozenGeometry.crackPolylineTolerance_mm,'G2Material:Polyline','Saved crack is not the frozen polyline.');
 assert(size(D.T6,1)==pol.frozenGeometry.expectedT3&&size(D.X6,1)==pol.frozenGeometry.expectedT6Nodes,'G2Material:MeshSize','Mesh size differs.');
 A=g2_kinked_mesh_auditor(D,jsonFile,p0Mat,size(D.crackPolyline,1));
 gs=Rev.geometrySummary;
 assert(A.pass&&A.gatesPassed==34&&A.gatesTotal==34&&A.summary.T3elements==gs.T3elements&&A.summary.minAngle_deg==gs.minAngle_deg&& ...
  A.summary.maxNeighborRatio==gs.maxNeighborRatio&&A.summary.qActive==gs.qActive,'G2Material:Reaudit','34/34 re-audit failed.');
 L=stage(L,'S0_SOURCE','PASS',struct('hashes',hs,'audit',sprintf('%d/%d',A.gatesPassed,A.gatesTotal), ...
  'minAngle_deg',A.summary.minAngle_deg,'maxNeighborRatio',A.summary.maxNeighborRatio,'qActive',A.summary.qActive,'gitHead',L.gitHead));
 % ================= S1 PHASE
 fg=pol.frozenGeometry;geo=struct('centers',reshape(fg.holeCenters_mm,[],2),'holeR',fg.holeRadius_mm*ones(3,1),'interfaceR',fg.interfaceRadius_mm*ones(3,1));
 if ~isequal(geo.centers(:,1),[152.4;152.4;152.4]),geo.centers=reshape(fg.holeCenters_mm.',[],2);end
 assert(isequal(geo.centers,[152.4 69.85;152.4 120.65;152.4 171.45]),'G2Material:HoleCenters','Hole centres parse.');
 pm=pol.phaseMap;
 PM=g2_material_phase_map(D.X6,D.T6,geo.centers,geo.holeR,geo.interfaceR, ...
  struct('onCircleTol_mm',pm.onCircleTolerance_mm,'minGap_mm',pm.minGapToNextT3Vertex_mm,'midsideTol_mm',pm.midsideOnChordTolerance_mm));
 fprintf('PHASE_MAP pass=%d %s: %s\n',PM.pass,PM.stage,PM.message);
 assert(PM.pass,'G2Material:PhaseMap','%s: %s',PM.stage,PM.message);
 tip=D.crackPolyline(end,:);qa=reshape(pol.sifGates.qAnnuli_mm,[],2);if size(qa,1)~=5,qa=reshape(pol.sifGates.qAnnuli_mm.',[],2);end
 vopts=struct('onCircleTol_mm',pm.onCircleTolerance_mm,'minGap_mm',pm.minGapToNextT3Vertex_mm,'areaRelTol',pm.areaIdentityRelTol, ...
  'domainAreaRelTol',pm.plateAreaIdentityRelTol,'outerArea_mm2',prod(fg.plate_mm),'twins',[D.upperBankT6(:),D.lowerBankT6(:)], ...
  'tip',tip,'tipGuideRadius_mm',fg.tipGuideRadius_mm,'qOuterRadii_mm',qa(:,2),'minQClearance_mm',pol.sifGates.minQSupportClearanceToReinforcement_mm, ...
  'voidTol_mm',pm.voidPenetrationTolerance_mm);
 V=g2_material_phase_verify(D.X6,D.T6,PM.phase,geo.centers,geo.holeR,geo.interfaceR,vopts);
 disp(V.checks);disp(V.values);
 assert(V.pass,'G2Material:PhaseVerify','Verifier failed: %s',strjoin(V.failed,', '));
 NC=check_g2_material_phase_controls(D,PM,geo,vopts);
 assert(NC.pass,'G2Material:PhaseNegatives','A phase negative control was accepted.');
 phase=PM.phase;
 h=g2_trajectory_record('write',fullfile(folder,'PHASE_MAP.mat'),struct('schema','NewMetacomp.G2.MaterialPhaseMap.v1', ...
  'phase',phase,'annulusOf',PM.annulusOf,'interfaces',PM.interfaces,'verifier',V,'negatives',NC,'meshSHA256',hs.mesh,'policySHA256',L.policySHA256));
 L=stage(L,'S1_PHASE','PASS',struct('counts',PM.counts,'chordsPerCircle',V.values.chordsPerCircle,'annulusArea_mm2',V.values.annulusArea_mm2, ...
  'polygonVsNominalRel',V.values.polygonVsNominalRel,'domainAreaRelErr',V.values.domainAreaRelErr,'qClearance_mm',V.values.qClearance_mm, ...
  'coincidentPairs',V.values.coincidentPairs,'negatives',sprintf('%d/%d rejected',nnz([NC.cases.rejected]),numel(NC.cases)),'recordSHA256',h));
 % ================= S2 BENCHMARK
 Bm=check_g2_material_benchmark(pol);
 h=g2_trajectory_record('write',fullfile(folder,'BENCHMARK.mat'),struct('schema','NewMetacomp.G2.MaterialBenchmark.v1','benchmark',Bm));
 assert(Bm.pass,'G2Material:Benchmark','Benchmark failed: %s',strjoin(Bm.failed,', '));
 % SIF-level q-phase negative control: one q-active element relabelled reinforcement (ratio 2)
 Em=pol.materials.E_matrix_MPa;nu=pol.materials.nu_matrix;mk=@(E,n)struct('E',E,'nu',n,'plane',pol.materials.plane);
 matM=mk(Em,nu);
 E0=g2_sif_interaction(D.X6,D.T6,zeros(2*size(D.X6,1),1),matM,tip,D.tipTangent(:).',.4,2.6,4);
 pq=ones(size(phase));pq(E0.activeRows(1))=2;   % all matrix except one q element: no contrast result before M0
 Kq=g2_material_sif_on_mesh(D,pq,[matM,mk(2*Em,pol.materials.nu_reinforcement)],polT,PM);
 assert(~Kq.criteria.qSupportMatrixPhaseOnly&&~Kq.pass,'G2Material:QPhaseNegative','SIF q-phase gate accepted a reinforcement element.');
 L=stage(L,'S2_BENCHMARK','PASS',struct('checks',Bm.checks,'dispRelErr',Bm.values.dispRelErr,'energyRelErr',Bm.values.energyRelErr, ...
  'interfaceMomentRelErr',Bm.values.interfaceMomentRelErr,'order',Bm.values.observedOrderFinestPair,'identity_u',Bm.values.identityRatio1_u, ...
  'referenceAssembly',Bm.values.referenceAssemblyRel,'negSwapped',Bm.values.negativeSwapped,'negDetached_eu',Bm.values.negativeDetached.eu, ...
  'sifQPhaseNegativeRejected',true,'recordSHA256',h));
 clear Kq
 % ================= S3 IDENTITY
 N=size(D.X6,1);thick=polT.bvp.thickness_mm;f=polT.bvp.P_N/thick;
 nodeAt=@(xy)D.extraVertexNodes(vecnorm(D.extraVertexXY-reshape(xy,1,2),2,2)<1e-9);
 pin=nodeAt(polT.bvp.pin_mm);roller=nodeAt(polT.bvp.roller_mm);loadNode=nodeAt(polT.bvp.load_mm);
 F=zeros(2*N,1);F(2*loadNode)=-f;bc=struct('fixedDofs',[2*pin-1;2*pin;2*roller],'fixedValues',[0;0;0],'F',F);
 SH=g2_t6_elasticity(D.X6,D.T6,matM,bc);
 KH=g2_trajectory_sif_on_mesh(D,matM,polT);
 regr=max(abs([KH.KI-Rev.sif.KI,KH.KII-Rev.sif.KII,KH.KI_COD-Rev.sif.KI_COD,KH.KII_COD-Rev.sif.KII_COD]))/hypot(Rev.sif.KI,Rev.sif.KII);
 assert(KH.pass&&regr<=1e-12,'G2Material:H1','H1 does not reproduce the recorded State 2 K (rel %.3g).',regr);
 H1=summ('H1',KH,SH,loadNode,polT,1);
 K0=g2_material_sif_on_mesh(D,phase,[matM,mk(Em,pol.materials.nu_reinforcement)],polT,PM);
 id=pol.identityM0;Kref=hypot(KH.KI,KH.KII);
 dK=full(max(abs(SH.K-K0.K),[],'all'))/full(max(abs(SH.K),[],'all'));
 dU=max(abs(SH.u-K0.u))/max(abs(SH.u));
 dKs=max(abs([KH.KI-K0.KI,KH.KII-K0.KII,KH.KI_COD-K0.KI_COD,KH.KII_COD-K0.KII_COD,reshape(KH.EDI_all(:,1:2)-K0.EDI_all(:,1:2),1,[])]))/Kref;
 dE=abs(SH.strainEnergy-K0.strainEnergy_per_thickness)/SH.strainEnergy;
 dR=max(abs(SH.reactions-K0.reactions))/f;
 dC=abs(abs(SH.u(2*loadNode))-K0.compliance_mm_per_N*polT.bvp.P_N)/abs(SH.u(2*loadNode));
 dT=abs(g2_mts_direction(KH.KI_MPa_sqrt_m_per_kN,KH.KII_MPa_sqrt_m_per_kN).theta_deg-g2_mts_direction(K0.KI_MPa_sqrt_m_per_kN,K0.KII_MPa_sqrt_m_per_kN).theta_deg);
 bitwise=isequal(SH.u,K0.u)&&isequal(KH.EDI_all,K0.EDI_all);
 idc=struct('stiffness',dK<=id.stiffnessMatrixRelTol,'displacement',dU<=id.displacementRelTol,'K',dKs<=id.KRelTolOfKref, ...
  'energy',dE<=id.energyRelTol,'reactions',dR<=id.reactionRelTolOfP,'compliance',dC<=id.complianceRelTol,'MTS',dT<=id.MTSAbsTol_deg,'M0gates',K0.pass);
 idv=struct('stiffness',dK,'displacement',dU,'K',dKs,'energy',dE,'reactions',dR,'compliance',dC,'MTS_deg',dT,'bitwiseUandEDI',bitwise,'H1regressionVsRecorded',regr);
 fprintf('IDENTITY H1 vs M0: K %.3g u %.3g SIF %.3g energy %.3g reactions %.3g compliance %.3g MTS %.3g deg bitwise=%d\n',dK,dU,dKs,dE,dR,dC,dT,bitwise);
 M0=summ('M0',K0,[],loadNode,polT,1);
 hH=write_case(folder,'H1',H1,SH.u);hM0=write_case(folder,'M0',M0,K0.u);
 clear SH
 assert(all(cell2mat(struct2cell(idc))),'G2Material:Identity','M0 identity failed: %s',jsonencode(idv));
 L=stage(L,'S3_IDENTITY','PASS',struct('checks',idc,'values',idv,'H1recordSHA256',hH,'M0recordSHA256',hM0));
 clear K0
 % ================= S4 CONTRAST
 cases={'Msoft',0.5;'Mstiff',2};Mres=struct([]);
 for i=1:2
  Kc=g2_material_sif_on_mesh(D,phase,[matM,mk(cases{i,2}*Em,pol.materials.nu_reinforcement)],polT,PM);
  Sm=summ(cases{i,1},Kc,[],loadNode,polT,cases{i,2});
  hc=write_case(folder,cases{i,1},Sm,Kc.u);
  if ~Kc.pass
   L=stage(L,['S4_',cases{i,1}],'HOLD',struct('failed',{Kc.failedCriteria},'recordSHA256',hc));
   error('G2Material:ContrastGate','%s failed: %s',cases{i,1},strjoin(Kc.failedCriteria,', '));
  end
  L=stage(L,['S4_',cases{i,1}],'PASS',struct('KI',Sm.KI_perkN,'KII',Sm.KII_perkN,'recordSHA256',hc));
  if isempty(Mres),Mres=Sm;else,Mres(end+1)=Sm;end %#ok<AGROW>
  clear Kc
 end
 % ================= S5 RATIOS
 T=ratios(H1,[M0,Mres],pol);
 L=stage(L,'S5_RATIOS','PASS',struct('table',T));
 L.results=struct('H1',H1,'M0',M0,'Msoft',Mres(1),'Mstiff',Mres(2),'ratios',T);
 L.status='GO';
catch ME
 fprintf(2,'HOLD %s: %s\n',ME.identifier,ME.message);
 L.status='HOLD';L.hold=struct('identifier',ME.identifier,'message',ME.message);
end
L.finished=datestr(now,31);
fid=fopen(fullfile(folder,'LEDGER.json'),'w');fwrite(fid,jsonencode(sanitize(L,repo),'PrettyPrint',true),'char');fclose(fid);
diary('off');
fl=dir(folder);fl=fl(~[fl.isdir]);fid=fopen(fullfile(folder,'SHA256SUMS.txt'),'w');
for k=1:numel(fl),if ~strcmp(fl(k).name,'SHA256SUMS.txt'),fprintf(fid,'%s *%s\n',lower(g2_sha256_file(fullfile(folder,fl(k).name))),fl(k).name);end,end
fclose(fid);
fprintf('G2_MATERIAL_CONTRAST_STATUS=%s\n',L.status);
end

% =====================================================================
function L=stage(L,name,status,info)
s=struct('name',name,'status',status,'info',info);
if isempty(L.stages),L.stages=s;else,L.stages(end+1)=s;end
fprintf('STAGE %s %s\n',name,status);
end

function S=summ(id,K,SH,loadNode,polT,ratio)
s1k=sqrt(1000);
S=struct('id',id,'ratio',ratio,'pass',K.pass,'KI_raw',K.KI,'KII_raw',K.KII,'KI_COD_raw',K.KI_COD,'KII_COD_raw',K.KII_COD, ...
 'EDI_all',K.EDI_all,'EDI4x4',K.EDI4x4,'J',K.J,'KI_perkN',K.KI_MPa_sqrt_m_per_kN,'KII_perkN',K.KII_MPa_sqrt_m_per_kN, ...
 'KI_COD_perkN',K.KI_COD*s1k,'KII_COD_perkN',K.KII_COD*s1k,'criteria',K.criteria,'relativeResidual',K.relativeResidual, ...
 'staticsMax',K.staticsMax,'fullPolyOpeningMin_mm',K.fullPolyOpeningMin_mm);
if ~isempty(SH)
 S.strainEnergy_per_thickness=SH.strainEnergy;S.compliance_mm_per_N=abs(SH.u(2*loadNode))/polT.bvp.P_N;
 S.reactions=SH.reactions;S.phaseStrainEnergy_per_thickness=SH.strainEnergy;
 U=K.fullPolyOpening_mm;[~,im]=min(K.wholeCrackArclength_mm);S.CMOD_mm=U(im);
 S.interfaceBalanceRel=NaN;S.annulusResultantRel=NaN;S.interfaceSideL2Rel=NaN(3,1);S.chordTractions={};
else
 S.strainEnergy_per_thickness=K.strainEnergy_per_thickness;S.compliance_mm_per_N=K.compliance_mm_per_N;
 S.reactions=K.reactions;S.phaseStrainEnergy_per_thickness=K.phaseStrainEnergy_per_thickness;S.CMOD_mm=K.CMOD_mm;
 S.interfaceBalanceRel=K.interfaceBalanceRel;S.annulusResultantRel=K.annulusResultantRel;S.interfaceSideL2Rel=K.interfaceSideL2Rel;
 S.chordTractions=K.chordTractions;
end
S.Ep_matrix=polT.bvp.E_MPa;S.thickness_mm=polT.bvp.thickness_mm;
end

function h=write_case(folder,id,S,u)
R=S;R.schema='NewMetacomp.G2.MaterialCase.v1';R.u=u;
h=g2_trajectory_record('write',fullfile(folder,['CASE_',id,'.mat']),R);
end

function T=ratios(H,Ms,pol)
E=H.Ep_matrix;G=@(k)(k(:,1).^2+k(:,2).^2)/E;
mts=@(KI,KII)g2_mts_direction(KI,KII).theta_deg;s1k=sqrt(1000);
gH=G(H.EDI_all(:,1:2));gH4=G(H.EDI4x4);gHc=G([H.KI_COD_raw,H.KII_COD_raw]);thH=mts(H.KI_perkN,H.KII_perkN);
thHc=mts(H.KI_COD_perkN,H.KII_COD_perkN);thH4=mts(H.EDI4x4(1)*s1k,H.EDI4x4(2)*s1k);
thHall=arrayfun(@(c)mts(H.EDI_all(c,1)*s1k,H.EDI_all(c,2)*s1k),1:5).';
cf=pol.uncertainty.coverageFactor;
T=struct([]);
for i=1:numel(Ms)
 M=Ms(i);gM=G(M.EDI_all(:,1:2));gM4=G(M.EDI4x4);gMc=G([M.KI_COD_raw,M.KII_COD_raw]);
 Rc=gM./gH;R=Rc(1);R4=gM4/gH4;Rcod=gMc/gHc;Rj=M.J/H.J;
 UR=max([max(abs(Rc-R)),abs(R4-R),abs(Rcod-R)]);
 dGM=abs(gM(1)-gMc)/gM(1);dGH=abs(gH(1)-gHc)/gH(1);Ucons=R*(dGM+dGH);
 resolved=abs(R-1)>cf*UR&&sign(Rcod-1)==sign(R-1);
 resolvedCons=abs(R-1)>Ucons&&sign(Rcod-1)==sign(R-1);
 uKII=max([abs(M.KII_raw-M.KII_COD_raw),max(M.EDI_all(:,2))-min(M.EDI_all(:,2)),abs(M.EDI4x4(2)-M.KII_raw)]);
 kiiRes=abs(M.KII_raw)>uKII&&sign(M.KII_COD_raw)==sign(M.KII_raw);
 th=mts(M.KI_perkN,M.KII_perkN);thc=mts(M.KI_COD_perkN,M.KII_COD_perkN);th4=mts(M.EDI4x4(1)*s1k,M.EDI4x4(2)*s1k);
 thall=arrayfun(@(c)mts(M.EDI_all(c,1)*s1k,M.EDI_all(c,2)*s1k),1:5).';
 dth=th-thH;Udth=max([abs((thc-thHc)-dth),abs((th4-thH4)-dth),max(abs((thall-thHall)-dth))]);
 t=struct('id',M.id,'ratio',M.ratio, ...
  'KI_perkN',M.KI_perkN,'KII_perkN',M.KII_perkN,'KI_COD_perkN',M.KI_COD_perkN,'KII_COD_perkN',M.KII_COD_perkN, ...
  'KI_phys_1N_MPa_sqrt_m',M.KI_raw/s1k,'KII_phys_1N_MPa_sqrt_m',M.KII_raw/s1k, ...
  'G_1N_N_per_mm',gM(1),'G_1N_J_per_m2',1000*gM(1),'J_1N_N_per_mm',M.J,'G_COD_1N_N_per_mm',gMc, ...
  'R_EDI',R,'R_COD',Rcod,'R_J',Rj,'R_EDI4x4',R4,'R_contours',Rc.','U_R',UR,'coverage',cf,'resolved',resolved, ...
  'U_R_conservative',Ucons,'resolvedConservative',resolvedCons, ...
  'KI_ratio',M.KI_raw/H.KI_raw,'KII_ratio',M.KII_raw/H.KII_raw,'KII_uncertainty_raw',uKII,'KII_signResolved',kiiRes, ...
  'mixity_deg',atand(M.KII_raw/M.KI_raw),'mixity_COD_deg',atand(M.KII_COD_raw/M.KI_COD_raw), ...
  'MTS_deg',th,'MTS_COD_deg',thc,'dMTS_deg',dth,'U_dMTS_deg',Udth,'dMTSresolved',abs(dth)>cf*Udth, ...
  'compliance_mm_per_N',M.compliance_mm_per_N,'complianceRatio',M.compliance_mm_per_N/H.compliance_mm_per_N, ...
  'CMOD_mm',M.CMOD_mm,'CMODratio',M.CMOD_mm/H.CMOD_mm, ...
  'strainEnergy_N_mm',M.strainEnergy_per_thickness*M.thickness_mm,'energyRatio',M.strainEnergy_per_thickness/H.strainEnergy_per_thickness, ...
  'reinforcementEnergyFraction',M.phaseStrainEnergy_per_thickness(end)/sum(M.phaseStrainEnergy_per_thickness));
 fprintf(['RATIO %-6s r=%-4g R_EDI=%.6f R_COD=%.6f R_J=%.6f U_R=%.3g resolved=%d (cons U=%.3g resolved=%d) ', ...
  'KI/KI_H1=%.6f KII/KII_H1=%.6f KII_res=%d psi=%.4f deg MTS=%.5f dMTS=%+.5f(U %.2g) C/C_H1=%.6f CMOD/CMOD_H1=%.6f\n'], ...
  M.id,M.ratio,R,Rcod,Rj,UR,resolved,Ucons,resolvedCons,t.KI_ratio,t.KII_ratio,kiiRes,t.mixity_deg,th,dth,Udth,t.complianceRatio,t.CMODratio);
 if isempty(T),T=t;else,T(end+1)=t;end %#ok<AGROW>
end
uKIIH=max([abs(H.KII_raw-H.KII_COD_raw),max(H.EDI_all(:,2))-min(H.EDI_all(:,2)),abs(H.EDI4x4(2)-H.KII_raw)]);
fprintf('H1: KI=%.9f KII=%+.9f per kN, G_1N=%.6e N/mm, MTS=%.5f deg, C=%.6e mm/N, CMOD=%.6e mm, KII_res=%d\n', ...
 H.KI_perkN,H.KII_perkN,gH(1),thH,H.compliance_mm_per_N,H.CMOD_mm,abs(H.KII_raw)>uKIIH&&sign(H.KII_COD_raw)==sign(H.KII_raw));
end

function s=sanitize(s,repo)
% replace absolute repository paths in strings by <repo>
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
