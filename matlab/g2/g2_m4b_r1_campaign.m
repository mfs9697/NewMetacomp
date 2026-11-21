function R = g2_m4b_r1_campaign(varargin)
%G2_M4B_R1_CAMPAIGN  Matched frozen S2alt ring-placement check (Issue #50, R1 policy v1).
%
%  R = g2_m4b_r1_campaign()                 dry preflight: B0 inventory (incl. matched geometry) + B1, writes NOTHING
%  R = g2_m4b_r1_campaign('Run',true,'AuthToken',tok)            new run: B0, B1, B2 anchors, B3 targets
%  R = g2_m4b_r1_campaign('Run',true,'AuthToken',tok,'RunDir',d)  resume: verified records reused, no FEM
% Generated from g2_m4b_campaign.m (PR #49, unchanged) with the R1 differences only:
%  - policy G2_M4B_R1_POLICY_v1.json; reference mesh = matched S2alt (3x112 chords);
%  - HOLD_MATCHED_S2ALT unless crackPolyline, tipTangent and tip coordinates equal the original S2
%    bitwise and the p010 core / collar / q-active counts are equal (g2_m4b_r1_matched_check);
%  - 10 physical cases (7 targets + 3 anchors), anchors bitwise equal to the M2 S2alt records;
%  - M4.B modules pinned to PR #49, legacy modules to PR #46; token G2M4BR1RUN|policy|src|mesh|cases=10.
% Every HOLD is an error 'G2M4B:HOLD_*' caught here: R.status = 'HOLD_*', nothing after it runs.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
ip=inputParser;
addParameter(ip,'Run',false,@islogical);
addParameter(ip,'AuthToken','',@(s)ischar(s)||isstring(s));
addParameter(ip,'RunDir','',@(s)ischar(s)||isstring(s));
addParameter(ip,'OutRoot',fullfile(repo,'outputs','g2_m4b_r1_s2alt_v1'),@(s)ischar(s)||isstring(s));
addParameter(ip,'Cases',{},@(c)iscell(c)||isstring(c));
addParameter(ip,'StopAfterSolves',inf,@(v)isnumeric(v)&&isscalar(v));
addParameter(ip,'PolicyFile','',@(s)ischar(s)||isstring(s));
addParameter(ip,'MeshFile','',@(s)ischar(s)||isstring(s));
addParameter(ip,'SimulatedFreeGiB',[],@(v)isempty(v)||isnumeric(v));
parse(ip,varargin{:});o=ip.Results;
R=struct('pass',false,'status','RUNNING','stage','B0','run',o.Run,'runDir','','solves',0,'reused',0, ...
 'hold',struct('identifier','','message',''),'physicalFractureGrowthProven',false);
canon=fullfile(here,'G2_M4B_R1_POLICY_v1.json');
try
 % ================= B0 inventory
 pf=char(o.PolicyFile);if isempty(pf),pf=canon;end
 if ~strcmpi(local_abs(pf),local_abs(canon)),local_hold('POLICY_DRIFT','Policy file %s is not the canonical R1 policy.',pf);end
 pol=jsondecode(fileread(pf));polSHA=lower(g2_sha256_file(pf));R.policySHA256=polSHA;
 ids=cellstr(pol.design.physicalCaseIds);ids=ids(:).';
 assert(numel(ids)==pol.design.physicalSolves&&numel(ids)==10&&numel(pol.design.targets)==7,'G2M4B:HOLD_POLICY_DRIFT','R1 design counts differ from 10/7.');
 req=cellstr(o.Cases);
 if isempty(req),req=ids;end
 bad=req(~ismember(req,ids));
 if ~isempty(bad)||numel(unique(req))~=numel(req),local_hold('CASE_OUTSIDE_DESIGN','Refused case(s) outside the preregistered 10 R1 physical ids: %s',strjoin(bad,', '));end
 [src,srcSHA]=g2_m4b_r1_sources(here);R.sourceSetSHA256=srcSHA;R.sources=src;
 meshSHA=lower(pol.reference.meshSHA256);
 tok=sprintf('G2M4BR1RUN|%s|src=%s|mesh=%s|cases=10',polSHA,srcSHA,meshSHA);R.expectedToken=tok;
 if o.Run&&~strcmp(char(o.AuthToken),tok),local_hold('AUTH_TOKEN','Run token does not bind this policy, source set, mesh and case cap.');end
 R.matlabRelease=['R',version('-release')];
 if ~strcmp(R.matlabRelease,pol.resources.matlabRelease),local_hold('RELEASE','MATLAB %s is not %s.',R.matlabRelease,pol.resources.matlabRelease);end
 R.pdeToolbox=license('test','PDE_Toolbox')==1&&~isempty(ver('pde'));
 if ~R.pdeToolbox,local_hold('TOOLBOX','PDE Toolbox not installed or not licensed.');end
 R.freeGiB=local_free_gib();
 if ~isempty(o.SimulatedFreeGiB),R.freeGiB=min(R.freeGiB,o.SimulatedFreeGiB);end
 if R.freeGiB<pol.resources.freePhysicalRAM_GiB_min,local_hold('MEMORY','Free physical RAM %.2f GiB below %g GiB.',R.freeGiB,pol.resources.freePhysicalRAM_GiB_min);end
 [R.gitHead,dirty]=local_git(repo);R.dirtySource=dirty;
 if o.Run&&(isempty(R.gitHead)||~isempty(dirty)),local_hold('DIRTY_SOURCE','Uncommitted or untracked sources:\n%s',dirty);end
 b=pol.base;
 pins={'G2_M4B_POLICY_v2.json',b.m4bPolicyV2SHA256;'G2_M4_POLICY_v1.json',b.m4PolicyV1SHA256;'G2_M2_POLICY_v1.json',b.m2PolicyV1SHA256; ...
  'G2_MATERIAL_POLICY_v1.json',b.materialPolicyV1SHA256;'G2_TRAJECTORY_POLICY_v1.json',b.trajectoryPolicyV1SHA256};
 for k=1:size(pins,1)
  if ~strcmpi(g2_sha256_file(fullfile(here,pins{k,1})),pins{k,2}),local_hold('POLICY_DRIFT','Historical policy %s changed.',pins{k,1});end
 end
 mods=cellstr(b.legacyModulesByteIdenticalToPR46Head);
 for k=1:numel(mods)
  [s1,bh]=system(sprintf('git -C "%s" rev-parse HEAD:matlab/g2/%s',repo,mods{k}));
  [s2,ph]=system(sprintf('git -C "%s" rev-parse %s:matlab/g2/%s',repo,b.pr46Head,mods{k}));
  if s1~=0||s2~=0||~strcmp(strtrim(bh),strtrim(ph)),local_hold('SOURCE','Legacy module %s differs from PR #46 head.',mods{k});end
 end
 mods=cellstr(b.m4bModulesByteIdenticalToPR49Head);
 for k=1:numel(mods)
  [s1,bh]=system(sprintf('git -C "%s" rev-parse HEAD:matlab/g2/%s',repo,mods{k}));
  [s2,ph]=system(sprintf('git -C "%s" rev-parse %s:matlab/g2/%s',repo,b.pr49Head,mods{k}));
  if s1~=0||s2~=0||~strcmp(strtrim(bh),strtrim(ph)),local_hold('SOURCE','M4.B module %s differs from PR #49 head.',mods{k});end
 end
 if ~strcmpi(g2_sha256_file(fullfile(repo,b.cornellJSON)),b.cornellJSON_SHA256)||~strcmpi(g2_sha256_file(fullfile(repo,b.trustedP0)),b.trustedP0SHA256)
  local_hold('SOURCE','Cornell JSON or trusted P0 hash differs.');end
 rf=pol.reference;mf=char(o.MeshFile);if isempty(mf),mf=fullfile(repo,rf.mesh);end
 if ~strcmpi(g2_sha256_file(mf),meshSHA),local_hold('SOURCE','Frozen S2alt mesh bytes differ from %s.',meshSHA);end
 if ~ledger_has(fullfile(repo,rf.meshLedger),meshSHA,rf.mesh),local_hold('SOURCE','S2alt mesh not in its committed ledger.');end
 mo=rf.matchedOriginal;
 if ~strcmpi(g2_sha256_file(fullfile(repo,mo.mesh)),mo.meshSHA256),local_hold('SOURCE','Original S2 mesh hash differs.');end
 D=load(mf);Dorig=load(fullfile(repo,mo.mesh));
 MC=g2_m4b_r1_matched_check(D,Dorig);R.matched=MC;clear Dorig
 if ~MC.pass,local_hold('MATCHED_S2ALT','S2alt is not the matched original-S2 geometry: %s',strjoin(MC.failed,', '));end
 ab=rf.acceptedS2altBaselines;bl=struct();
 for nm={'CASE_S2alt_H1','CASE_S2alt_M0','CASE_S2alt_Msoft','CASE_S2alt_Mstiff','PHASE_MAP_S2alt'}
  p=fullfile(repo,ab.run,[nm{1},'.mat']);
  if ~strcmpi(g2_sha256_file(p),ab.(nm{1}))||~ledger_has(fullfile(repo,ab.ledger),ab.(nm{1}),[ab.run,'/',nm{1},'.mat'])
   local_hold('SOURCE','Accepted baseline %s hash or ledger row differs.',nm{1});end
  [rec,~,okr]=g2_trajectory_record('read',p);if ~okr,local_hold('SOURCE','Baseline record %s manifest invalid.',nm{1});end
  bl.(nm{1})=rec;
 end
 R=stage(R,'B0_INVENTORY');
 % ================= B1 activation
 polM=jsondecode(fileread(fullfile(here,'G2_MATERIAL_POLICY_v1.json')));
 polT=jsondecode(fileread(fullfile(here,'G2_TRAJECTORY_POLICY_v1.json')));
 json=fullfile(repo,b.cornellJSON);p0=fullfile(repo,b.trustedP0);
 if size(D.T6,1)~=rf.expectedT3||size(D.X6,1)~=rf.expectedT6Nodes,local_hold('AUDIT','S2alt mesh size %d T3 / %d nodes.',size(D.T6,1),size(D.X6,1));end
 P=reshape(rf.polyline_mm,[],2);
 A=g2_kinked_mesh_auditor(D,json,p0,size(P,1));
 if ~(A.pass&&A.gatesPassed==34&&A.gatesTotal==34),local_hold('AUDIT','Kinked auditor %d/%d.',A.gatesPassed,A.gatesTotal);end
 [Dm,Ad]=g2_m2_state_adapter(D,'S2alt',P);
 if ~Ad.pass,local_hold('AUDIT','Adapter: %s',strjoin(Ad.failed,', '));end
 R.audit=sprintf('%d/%d',A.gatesPassed,A.gatesTotal);
 [PM,Vl,NCl,geoL,voptsL]=legacy_phase(Dm,polM,P);
 if ~PM.pass,local_hold('PHASE_MAP','%s: %s',PM.stage,PM.message);end
 if ~isequal(PM.phase,bl.PHASE_MAP_S2alt.phase)||~isequal(PM.annulusOf,bl.PHASE_MAP_S2alt.annulusOf),local_hold('PHASE_MAP','Phase map differs from the accepted PHASE_MAP_S2alt.');end
 if ~Vl.pass,local_hold('LEGACY_VERIFIER','Legacy verifier: %s',strjoin(Vl.failed,', '));end
 if ~NCl.pass,local_hold('LEGACY_VERIFIER','A legacy phase negative control was accepted.');end
 polV2=jsondecode(fileread(fullfile(here,'G2_M4B_POLICY_v2.json')));rg=polV2.rings;
 cen=reshape(rg.centres_mm,[],2);if ~isequal(cen(:,1),[152.4;152.4;152.4]),cen=reshape(rg.centres_mm.',[],2);end
 if max(abs(cen-geoL.centers),[],'all')>0,local_hold('OWNER_ORACLE','M4.B ring centres differ from the material policy centres.');end
 geo=struct('centres',cen,'holeR',rg.holeRadius_mm*ones(3,1),'ringR',rg.outerRadius_mm*ones(3,1));
 O=g2_m4b_ring_owner_oracle(Dm.X6,Dm.T6,geo.centres,geo.holeR,geo.ringR,struct('onCircleTol_mm',polM.phaseMap.onCircleTolerance_mm));
 if ~O.pass||~isequal(O.ownerOracle,PM.annulusOf),local_hold('OWNER_ORACLE','Oracle pass=%d, %d owner mismatches with annulusOf.',O.pass,nnz(O.ownerOracle~=PM.annulusOf));end
 Em=pol.materials.E_matrix_MPa;mk=@(E)struct('E',E,'nu',pol.materials.nu,'plane',pol.materials.plane);
 vopts=struct('onCircleTol_mm',polM.phaseMap.onCircleTolerance_mm,'midsideTol_mm',polM.phaseMap.midsideOnChordTolerance_mm, ...
  'areaRelTol',polM.phaseMap.areaIdentityRelTol,'domainAreaRelTol',polM.phaseMap.plateAreaIdentityRelTol,'outerArea_mm2',prod(polM.frozenGeometry.plate_mm), ...
  'expectedChords',rf.chordsPerRing,'E_matrix',Em,'nu',pol.materials.nu,'thickness_mm',pol.materials.thickness_mm,'tip',P(end,:), ...
  'tipGuideRadius_mm',voptsL.tipGuideRadius_mm,'qOuterRadii_mm',voptsL.qOuterRadii_mm,'minQClearance_mm',voptsL.minQClearance_mm, ...
  'twins',[Dm.upperBankT6(:),Dm.lowerBankT6(:)]);
 caseDef=struct();act=struct();Vact=struct();
 for k=1:numel(ids)
  cd_=case_def(ids{k},Em,mk);caseDef.(ids{k})=cd_;
  a=g2_m4b_ring_activation(PM.annulusOf,cd_.mask);act.(ids{k})=a;
  oo=vopts;oo.contrast=cd_.contrastForVerifier;
  V=g2_m4b_activation_verify(Dm.X6,Dm.T6,PM.annulusOf,a.phaseForAssembly,cd_.mask,cd_.mats,geo,oo);
  Vact.(ids{k})=rmfield(V,'ownerOracle');
  fprintf('M4B_ACTIVATION %-9s bits=%s pass=%d active=%d area=%.9f failed=[%s]\n',ids{k},a.bits,V.pass,a.activeElements,V.values.activeArea_mm2,strjoin(V.failed,','));
  if ~V.pass,local_hold('ACTIVATION','%s: %s',ids{k},strjoin(V.failed,', '));end
 end
 if ~isequal(act.c0p5_111.phaseForAssembly,PM.phase)||~isequal(act.c2p0_111.phaseForAssembly,PM.phase)||any(act.none.phaseForAssembly~=1)
  local_hold('ACTIVATION','Full-band or empty mask labels differ from PM.phase / all-matrix.');end
 NC=check_g2_m4b_activation_negatives(Dm,PM,geo,vopts,mk);
 if ~NC.pass,local_hold('NEGATIVE_CONTROL','An activation negative control was accepted or the positive control failed.');end
 R.B1=struct('audit',R.audit,'legacyVerifier',Vl.pass,'legacyNegatives',NCl.pass,'oracle',O.values,'activation',Vact,'negatives',NC);
 R=stage(R,'B1_ACTIVATION');
 if ~o.Run
  R.status='DRY_OK';R.pass=true;fprintf('G2_M4B_R1_CAMPAIGN DRY_OK (nothing written)\n');return
 end
 % ================= run folder
 outRoot=local_abs(char(o.OutRoot));
 if ~local_inside(outRoot,fullfile(repo,'outputs')),local_hold('RUN_EXISTS','OutRoot must be under <repo>/outputs.');end
 if isempty(char(o.RunDir))
  if ~isfolder(outRoot),mkdir(outRoot);end
  rd=fullfile(outRoot,['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);
  if exist(rd,'dir'),local_hold('RUN_EXISTS','Run folder exists.');end
  mkdir(rd);
  RUN=struct('schema','NewMetacomp.G2.M4B.R1.Run.v1','issue',50,'token',tok,'policySHA256',polSHA,'sourceSetSHA256',srcSHA, ...
   'meshSHA256',meshSHA,'gitHead',R.gitHead,'created',datestr(now,31),'sources',src,'matlabRelease',R.matlabRelease);
  write_json(fullfile(rd,'RUN.json'),RUN);
 else
  rd=local_abs(char(o.RunDir));
  if ~isfolder(rd)||~local_inside(rd,outRoot)||~isfile(fullfile(rd,'RUN.json')),local_hold('RECORD_INTEGRITY','Resume folder invalid.');end
  RUN=jsondecode(fileread(fullfile(rd,'RUN.json')));
  if ~strcmp(RUN.token,tok),local_hold('AUTH_TOKEN','Resume folder was created under another token.');end
 end
 R.runDir=strrep(rd,repo,'<repo>');
 diary(fullfile(rd,sprintf('console_%s.log',datestr(now,'yyyymmdd_HHMMSS_FFF'))));cl=onCleanup(@()diary('off')); %#ok<NASGU>
 fprintf('G2_M4B_R1_CAMPAIGN run %s policy %s src %s head %s\n',R.runDir,polSHA,srcSHA,R.gitHead);
 ctx=struct('rd',rd,'D',Dm,'PM',PM,'polT',polT,'pol',pol,'polSHA',polSHA,'srcSHA',srcSHA,'meshSHA',meshSHA,'budget',o.StopAfterSolves, ...
  'expect',struct('P_N',pol.bvp.P_N,'thickness_mm',pol.materials.thickness_mm,'load_mm',pol.bvp.load_mm,'E_matrix',Em));
 % ================= B2 baselines
 base={'none','c0p5_111','c2p0_111'};rec=struct();
 for k=1:numel(base)
  [rec.(base{k}),R,stop]=obtain_case(ctx,R,base{k},caseDef.(base{k}),act.(base{k}),Vact.(base{k}));
  if stop,return,end
 end
 leg=struct();
 for k=2:3
  [leg.(base{k}),R,stop]=obtain_legacy(ctx,R,base{k},caseDef.(base{k}));
  if stop,return,end
 end
 B2=baseline_checks(rec,leg,bl,act,PM);R.B2=B2;
 b2f=fullfile(rd,'B2_BASELINES.json');if ~isfile(b2f),write_json(b2f,B2);end
 if ~B2.pass,local_hold('BASELINE_REGRESSION','Baseline regression failed: %s',jsonencode(B2.checks));end
 R=stage(R,'B2_BASELINES');
 % ================= B3 subset cases
 todo=ids(ismember(ids,req)&~ismember(ids,base));
 for k=1:numel(todo)
  [rec.(todo{k}),R,stop]=obtain_case(ctx,R,todo{k},caseDef.(todo{k}),act.(todo{k}),Vact.(todo{k}));
  if stop,return,end
 end
 done=all(cellfun(@(c)isfield(rec,c),ids));
 if ~done,R.status='PARTIAL_CASE_SELECTION';R.pass=true;return,end
 % ================= manifest
 L=struct('physicalCase',{},'role',{},'recordSHA256',{},'pass',{});
 for k=1:numel(ids)
  role='target';if ismember(ids{k},base),role='anchor';end
  L(end+1)=struct('physicalCase',ids{k},'role',role,'recordSHA256',rec.(ids{k}).sha,'pass',rec.(ids{k}).pass); %#ok<AGROW>
 end
 Mf=struct('schema','NewMetacomp.G2.M4B.R1.CampaignManifest.v1','token',tok,'cases',L,'physicalSolves',numel(ids), ...
  'allPass',all([L.pass]),'B2',B2.pass,'matchedGeometry',MC.pass,'reviewStop','REVIEW_STOP_R1','physicalFractureGrowthProven',false);
 mfj=fullfile(rd,'CAMPAIGN_MANIFEST.json');if ~isfile(mfj),write_json(mfj,Mf);end
 R.manifest=Mf;
 if ~Mf.allPass,local_hold('SIF','An R1 case failed its gates.');end
 sums=fullfile(rd,'SHA256SUMS.txt');
 if ~isfile(sums)
  fl=dir(rd);fl=fl(~[fl.isdir]&~startsWith({fl.name},'console_'));fid=fopen(sums,'w');
  for k=1:numel(fl),fprintf(fid,'%s *%s\n',lower(g2_sha256_file(fullfile(rd,fl(k).name))),fl(k).name);end
  fclose(fid);
 end
 R=stage(R,'B3_TARGETS');R.status='GO';R.pass=true;
 fprintf('G2_M4B_R1_CAMPAIGN_STATUS=GO solves=%d reused=%d\n',R.solves,R.reused);
catch ME
 if startsWith(ME.identifier,'G2M4B:HOLD_'),R.status=extractAfter(ME.identifier,'G2M4B:');else,R.status='HOLD_UNEXPECTED_ERROR';end
 R.hold=struct('identifier',ME.identifier,'message',ME.message);
 fprintf(2,'G2_M4B_R1_CAMPAIGN %s: %s\n',R.status,ME.message);
 if o.Run&&~isempty(R.runDir)
  rd=strrep(R.runDir,'<repo>',repo);
  hf=fullfile(rd,sprintf('HOLD_%s.json',datestr(now,'yyyymmdd_HHMMSS_FFF')));
  write_json(hf,struct('status',R.status,'identifier',ME.identifier,'message',strrep(ME.message,repo,'<repo>'),'stage',R.stage));
 end
end
end

% =====================================================================
function [out,R,stop]=obtain_case(ctx,R,id,cd_,a,V)
stop=false;f=fullfile(ctx.rd,['CASE_',id,'.mat']);
ctok=sprintf('G2M4BR1CASE|%s|src=%s|mesh=%s|c=%s|mask=%s',ctx.polSHA,ctx.srcSHA,ctx.meshSHA,cd_.contrastLabel,a.bits);
if isfile(f)
 [rec,h,ok]=g2_trajectory_record('read',f);
 okL=ledger_has(fullfile(ctx.rd,'CASE_LEDGER.txt'),h,['CASE_',id,'.mat']);
 ok=ok&&okL&&strcmp(rec.caseId,id)&&strcmp(rec.caseToken,ctok)&&strcmp(rec.meshSHA256,ctx.meshSHA)&& ...
  strcmp(rec.sourceSetSHA256,ctx.srcSHA)&&strcmp(rec.policySHA256,ctx.polSHA)&&strcmp(rec.bits,a.bits)&&isequal(rec.phaseForAssembly,a.phaseForAssembly);
 if ok
  P=ctx.D.crackPolyline;E=g2_sif_interaction(ctx.D.X6,ctx.D.T6,rec.K.u,cd_.mats(1),P(end,:),ctx.D.tipTangent(:).',.4,2.6,6);
  ok=isequal([E.KI,E.KII,E.J],rec.K.EDI_all(1,:))&&rec.K.KII==rec.K.EDI_all(1,2)&&rec.K.KI==rec.K.EDI_all(1,1)&& ...
   (~rec.K.conditionalModeIISignGateEnforced||sign(rec.K.KII)==sign(rec.K.KII_COD));
 end
 if ~ok,local_hold('RECORD_INTEGRITY','Case record %s fails re-verification (manifest, ledger, token, labels or EDI-from-u).',id);end
 R.reused=R.reused+1;out=struct('rec',rec,'sha',lower(h),'pass',rec.K.pass&&rec.activation.pass);
 fprintf('M4B_CASE %-9s REUSED (verified, no FEM) sha %s\n',id,h);return
end
if R.solves>=ctx.budget
 R.status='INTERRUPTED';R.pass=false;stop=true;out=struct();
 fprintf('G2_M4B_CAMPAIGN INTERRUPTED before %s (simulated, %d solves)\n',id,R.solves);return
end
K=g2_m4b_sif_partial(ctx.D,a,cd_.mats,ctx.polT,ctx.PM,ctx.expect);R.solves=R.solves+1;
rec=struct('schema','NewMetacomp.G2.M4B.R1.CaseRecord.v1','caseId',id,'caseToken',ctok,'contrast',cd_.contrast,'contrastLabel',cd_.contrastLabel, ...
 'mask',a.mask,'bits',a.bits,'activeRings',a.activeRings,'ownerRing',a.ownerRing,'phaseForAssembly',a.phaseForAssembly, ...
 'mats',cd_.mats,'activation',V,'K',K,'meshSHA256',ctx.meshSHA,'policySHA256',ctx.polSHA,'sourceSetSHA256',ctx.srcSHA, ...
 'matlabRelease',['R',version('-release')],'created',datestr(now,31),'physicalFractureGrowthProven',false);
h=g2_trajectory_record('write',f,rec);
fid=fopen(fullfile(ctx.rd,'CASE_LEDGER.txt'),'a');fprintf(fid,'%s *CASE_%s.mat\n',lower(h),id);fclose(fid);
out=struct('rec',rec,'sha',lower(h),'pass',K.pass&&V.pass);
fprintf('M4B_CASE %-9s SOLVED pass=%d sha %s\n',id,out.pass,h);
if ~K.pass,local_hold('SIF','%s failed: %s',id,strjoin(K.failedCriteria,', '));end
end

function [out,R,stop]=obtain_legacy(ctx,R,id,cd_)
stop=false;f=fullfile(ctx.rd,['CONTROL_LEGACY_',id,'.mat']);
if isfile(f)
 [rec,h,ok]=g2_trajectory_record('read',f);
 ok=ok&&ledger_has(fullfile(ctx.rd,'CASE_LEDGER.txt'),h,['CONTROL_LEGACY_',id,'.mat'])&&strcmp(rec.caseId,id)&&strcmp(rec.policySHA256,ctx.polSHA);
 if ~ok,local_hold('RECORD_INTEGRITY','Legacy control %s fails re-verification.',id);end
 R.reused=R.reused+1;out=rec;fprintf('M4B_LEGACY %-9s REUSED\n',id);return
end
if R.solves>=ctx.budget
 R.status='INTERRUPTED';R.pass=false;stop=true;out=struct();return
end
K=g2_material_sif_on_mesh(ctx.D,ctx.PM.phase,cd_.mats,ctx.polT,ctx.PM);R.solves=R.solves+1;
rec=struct('schema','NewMetacomp.G2.M4B.R1.LegacyControl.v1','caseId',id,'policySHA256',ctx.polSHA,'pass',K.pass, ...
 'failedCriteria',{K.failedCriteria},'u',K.u,'EDI_all',K.EDI_all,'EDI4x4',K.EDI4x4,'KI_COD',K.KI_COD,'KII_COD',K.KII_COD, ...
 'J',K.J,'compliance_mm_per_N',K.compliance_mm_per_N,'CMOD_mm',K.CMOD_mm,'reactions',K.reactions, ...
 'strainEnergy_per_thickness',K.strainEnergy_per_thickness,'phaseStrainEnergy_per_thickness',K.phaseStrainEnergy_per_thickness);
h=g2_trajectory_record('write',f,rec);
fid=fopen(fullfile(ctx.rd,'CASE_LEDGER.txt'),'a');fprintf(fid,'%s *CONTROL_LEGACY_%s.mat\n',lower(h),id);fclose(fid);
out=rec;fprintf('M4B_LEGACY %-9s SOLVED pass=%d\n',id,K.pass);
end

function B=baseline_checks(rec,leg,bl,act,PM)
n=rec.none.rec.K;H=bl.CASE_S2alt_H1;c=struct();
c.none_u=isequal(n.u,H.u);c.none_EDI_all=isequal(n.EDI_all,H.EDI_all);c.none_EDI4x4=isequal(n.EDI4x4,H.EDI4x4);
c.none_COD=isequal([n.KI_COD,n.KII_COD],[H.KI_COD_raw,H.KII_COD_raw]);
c.none_CMOD=isequal(n.CMOD_mm,H.CMOD_mm);c.none_compliance=isequal(n.compliance_mm_per_N,H.compliance_mm_per_N);
c.none_noLabel2=all(rec.none.rec.phaseForAssembly==1);
pairs={'c0p5_111','CASE_S2alt_Msoft';'c2p0_111','CASE_S2alt_Mstiff'};dev=struct();
for k=1:2
 m=rec.(pairs{k,1}).rec.K;Bm=bl.(pairs{k,2});L=leg.(pairs{k,1});p=matlab.lang.makeValidName(pairs{k,1});
 c.([p,'_u'])=isequal(m.u,Bm.u);c.([p,'_EDI_all'])=isequal(m.EDI_all,Bm.EDI_all);c.([p,'_EDI4x4'])=isequal(m.EDI4x4,Bm.EDI4x4);
 c.([p,'_COD'])=isequal([m.KI_COD,m.KII_COD],[Bm.KI_COD_raw,Bm.KII_COD_raw]);c.([p,'_J'])=isequal(m.J,Bm.J);
 c.([p,'_compliance'])=isequal(m.compliance_mm_per_N,Bm.compliance_mm_per_N);c.([p,'_CMOD'])=isequal(m.CMOD_mm,Bm.CMOD_mm);
 c.([p,'_reactions'])=isequal(m.reactions,Bm.reactions);c.([p,'_strainEnergy'])=isequal(m.strainEnergy_per_thickness,Bm.strainEnergy_per_thickness);
 c.([p,'_phaseEnergy'])=isequal(m.phaseStrainEnergy_per_thickness,Bm.phaseStrainEnergy_per_thickness);
 c.([p,'_legacyPass'])=L.pass;
 c.([p,'_legacyEqualsNew'])=isequal(L.u,m.u)&&isequal(L.EDI_all,m.EDI_all)&&isequal(L.EDI4x4,m.EDI4x4)&&isequal([L.KI_COD,L.KII_COD],[m.KI_COD,m.KII_COD]) ...
  &&isequal(L.compliance_mm_per_N,m.compliance_mm_per_N)&&isequal(L.CMOD_mm,m.CMOD_mm)&&isequal(L.reactions,m.reactions);
 c.([p,'_labelsEqualPMphase'])=isequal(act.(pairs{k,1}).phaseForAssembly,PM.phase);
 dev.(p)=struct('maxAbs_u',max(abs(m.u-Bm.u)),'maxAbs_EDI',max(abs(m.EDI_all-Bm.EDI_all),[],'all'));
end
dev.none=struct('maxAbs_u',max(abs(n.u-H.u)),'maxAbs_EDI',max(abs(n.EDI_all-H.EDI_all),[],'all'));
f=fieldnames(c);ok=cellfun(@(k)c.(k),f);
B=struct('schema','NewMetacomp.G2.M4B.R1.Baselines.v1','pass',all(ok),'checks',c,'failed',{f(~ok)},'deviations',dev, ...
 'rule','bitwise (isequal) for none vs CASE_S2alt_H1 and for 111 vs CASE_S2alt_Msoft/Mstiff; legacy g2_material_sif_on_mesh PASS and equal');
fprintf('M4B_R1_B2 pass=%d failed=[%s]\n',B.pass,strjoin(B.failed,','));
end

function cd_=case_def(id,Em,mk)
if strcmp(id,'none')
 cd_=struct('mask',[0 0 0],'contrast',NaN,'contrastLabel','none','contrastForVerifier','none','mats',[mk(Em),mk(Em)]);return
end
tk=regexp(id,'^c(0p5|2p0)_([01]{3})$','tokens','once');
if isempty(tk),local_hold('CASE_OUTSIDE_DESIGN','Malformed case id %s.',id);end
c=str2double(strrep(tk{1},'p','.'));mask=tk{2}=='1';
if ~any(mask),local_hold('CASE_OUTSIDE_DESIGN','A contrast case needs at least one active ring.');end
lab=ternary(c==.5,'0.5','2');
cd_=struct('mask',mask,'contrast',c,'contrastLabel',lab,'contrastForVerifier',c,'mats',[mk(Em),mk(c*Em)]);
end

function [PM,V,NC,geo,vopts]=legacy_phase(Dm,polM,P)
fg=polM.frozenGeometry;pm=polM.phaseMap;
c=reshape(fg.holeCenters_mm,[],2);if ~isequal(c(:,1),[152.4;152.4;152.4]),c=reshape(fg.holeCenters_mm.',[],2);end
geo=struct('centers',c,'holeR',fg.holeRadius_mm*ones(3,1),'interfaceR',fg.interfaceRadius_mm*ones(3,1));
PM=g2_material_phase_map(Dm.X6,Dm.T6,geo.centers,geo.holeR,geo.interfaceR, ...
 struct('onCircleTol_mm',pm.onCircleTolerance_mm,'minGap_mm',pm.minGapToNextT3Vertex_mm,'midsideTol_mm',pm.midsideOnChordTolerance_mm));
V=struct('pass',false,'failed',{{'not run'}});NC=struct('pass',false);
qa=reshape(polM.sifGates.qAnnuli_mm,[],2);if size(qa,1)~=5,qa=reshape(polM.sifGates.qAnnuli_mm.',[],2);end
vopts=struct('onCircleTol_mm',pm.onCircleTolerance_mm,'minGap_mm',pm.minGapToNextT3Vertex_mm,'areaRelTol',pm.areaIdentityRelTol, ...
 'domainAreaRelTol',pm.plateAreaIdentityRelTol,'outerArea_mm2',prod(fg.plate_mm),'twins',[Dm.upperBankT6(:),Dm.lowerBankT6(:)], ...
 'tip',P(end,:),'tipGuideRadius_mm',fg.tipGuideRadius_mm,'qOuterRadii_mm',qa(:,2),'minQClearance_mm',polM.sifGates.minQSupportClearanceToReinforcement_mm, ...
 'voidTol_mm',pm.voidPenetrationTolerance_mm);
fprintf('LEGACY_PHASE_MAP pass=%d %s: %s\n',PM.pass,PM.stage,PM.message);
if ~PM.pass,return,end
V=g2_material_phase_verify(Dm.X6,Dm.T6,PM.phase,geo.centers,geo.holeR,geo.interfaceR,vopts);
fprintf('LEGACY_PHASE_VERIFY pass=%d failed=[%s]\n',V.pass,strjoin(V.failed,','));
if ~V.pass,return,end
NC=check_g2_m2_phase_controls(Dm,PM,geo,vopts);
end

function local_hold(code,varargin)
error(['G2M4B:HOLD_',code],varargin{:});
end

function R=stage(R,name)
R.stage=name;fprintf('STAGE %s PASS\n',name);
end

function g=local_free_gib()
try,[~,s]=memory;g=s.PhysicalMemory.Available/2^30;catch,g=NaN;end
end

function ok=ledger_has(file,hash,path)
ok=false;if ~isfile(file),return,end
txt=splitlines(fileread(file));rel=lower(regexprep(path,'^outputs/',''));
for k=1:numel(txt)
 l=lower(strtrim(txt{k}));
 if startsWith(l,lower(hash))&&endsWith(l,['*',rel]),ok=true;return,end
end
end

function write_json(f,s)
assert(~isfile(f),'G2M4B:HOLD_RUN_EXISTS','Refusing to overwrite %s.',f);
fid=fopen(f,'w');fwrite(fid,jsonencode(s,'PrettyPrint',true),'char');fclose(fid);
end

function [head,dirty]=local_git(repo)
head='';dirty='git unavailable';
[s1,h]=system(sprintf('git -C "%s" rev-parse HEAD',repo));
[s2,d]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all -- matlab/g2 docs/research/crack-growth-gaps-2026',repo));
if s1==0&&s2==0,head=strtrim(h);dirty=strtrim(d);end
end

function p=local_abs(p)
p=char(java.io.File(char(p)).getCanonicalPath());
end

function tf=local_inside(a,b)
a=lower(local_abs(a));b=lower(local_abs(b));tf=startsWith(a,[b,filesep])||strcmp(a,b);
end

function r=ternary(c,a,b),if c,r=a;else,r=b;end,end
