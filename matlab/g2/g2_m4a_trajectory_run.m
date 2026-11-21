function R = g2_m4a_trajectory_run(varargin)
%G2_M4A_TRAJECTORY_RUN  G2-M4.A: two-step numerical path on the alternative mesh family (Issue #44).
%
%  R = g2_m4a_trajectory_run('Material','homogeneous'|'soft'|'stiff', ...)
% Options: 'ChainDir' (default outputs/g2_m4_alt_family_v1/chain_<material>_alt_v1), 'S0Dir'
%  (default outputs/g2_m4_alt_family_v1/S0ALT), 'Run' (false = dry, writes nothing),
%  'AuthToken' (G2M4ARUN|<policy SHA>|<material>|family=famB_m4alt|maxState=2),
%  'MaxStateIndex' (<= 2), 'SimulateInterrupt' struct('point','review'|'state','step',k).
% G2_M4_POLICY_v1.json / G2_M4_PREREGISTRATION.md. Per chain:
%  ROOT   shared S0ALT record and mesh verified (hash; re-audited 38/38, 24/24 and phase re-map
%         when the ROOT is created); the chain's OWN S0 solve on the alternative S0
%         (homogeneous: H1 + M0 identity + Msoft + Mstiff; soft/stiff: two-phase solve);
%         full-precision parent K from that solve (never from the original family)
%  step k G2-M3 recurrence; K1-K10; new mesh g2_kinked_join with the alternative exterior
%         options; saved-array 34/34; new phase stage; new solve(s); PHASE_MAP, SOLUTION(s),
%         REVIEW, then STATE (manifests, never overwritten)
%  reuse  REVIEW/STATE re-verified (forecast, hashes, mesh content, 34/34, phase re-map and
%         verifier, all solution records) without FEM; an interrupted REVIEW is promoted
% Any failure writes HOLD.mat (Run) and stops; a chain with a HOLD is never reused.
% No third step, no ring attribution (M4.B), no onset, toughness, arrest or CZM.
ip=inputParser;
addParameter(ip,'Material','',@(s)ischar(s)||isstring(s));
addParameter(ip,'ChainDir','',@(s)ischar(s)||isstring(s));
addParameter(ip,'S0Dir','',@(s)ischar(s)||isstring(s));
addParameter(ip,'Run',false,@islogical);
addParameter(ip,'AuthToken','',@(s)ischar(s)||isstring(s));
addParameter(ip,'MaxStateIndex',2,@(v)isnumeric(v)&&isscalar(v));
addParameter(ip,'SimulateInterrupt',struct('point','','step',0),@isstruct);
parse(ip,varargin{:});o=ip.Results;
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
addpath(fullfile(here,'vendor_p010_a14d8872'),'-begin');
polFile=fullfile(here,'G2_M4_POLICY_v1.json');pol=jsondecode(fileread(polFile));polSHA=g2_sha256_file(polFile);
polM=jsondecode(fileread(fullfile(here,'G2_MATERIAL_POLICY_v1.json')));
polT=jsondecode(fileread(fullfile(here,'G2_TRAJECTORY_POLICY_v1.json')));
json=fullfile(repo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json');
p0=fullfile(repo,'outputs','g2_p010_isolated','run_20261118_163657_790','P010_ISOLATED_REGULAR_ONLY.mat');
R=struct('pass',false,'stage','HOLD_NOT_STARTED','material',char(o.Material),'policySHA256',polSHA,'run',o.Run, ...
 'lastStateIndex',0,'statesReused',0,'reviewsPromoted',0,'statesComputed',0,'forecasts',struct([]),'message','');
% ---------- policy, material, caps, release, sources
b=pol.base;
assert(strcmpi(g2_sha256_file(fullfile(here,'G2_MATERIAL_POLICY_v1.json')),b.materialPolicyV1SHA256)&& ...
 strcmpi(g2_sha256_file(fullfile(here,'G2_TRAJECTORY_POLICY_v1.json')),b.trajectoryPolicyV1SHA256)&& ...
 strcmpi(g2_sha256_file(fullfile(here,'G2_M2_POLICY_v1.json')),b.m2PolicySHA256)&& ...
 strcmpi(g2_sha256_file(fullfile(here,'G2_M3_TRAJECTORY_POLICY_v1.json')),b.m3PolicySHA256)&& ...
 strcmpi(g2_sha256_file(json),b.cornellJSON_SHA256)&&strcmpi(g2_sha256_file(p0),b.trustedP0SHA256),'G2M4:PolicyHash','A pinned policy/JSON/P0 hash differs.');
mats=pol.materials;if iscell(mats),mats=[mats{:}];end
im=find(strcmp({mats.id},char(o.Material)));
assert(isscalar(im),'G2M4:Material','Unknown material id "%s".',char(o.Material));
mat=mats(im);
assert(o.MaxStateIndex>=1&&o.MaxStateIndex<=pol.scopeLimits.maxStateIndex&&o.MaxStateIndex==round(o.MaxStateIndex), ...
 'G2M4:StepCap','Requested MaxStateIndex %g exceeds the policy cap %d.',o.MaxStateIndex,pol.scopeLimits.maxStateIndex);
rel=['R',version('-release')];assert(strcmp(rel,pol.resources.matlabRelease),'G2M4:Release','MATLAB %s is not R2023a.',rel);
src=g2_m4a_sources(here);R.sourceHashes=src;
[head,dirty]=local_git(repo);R.gitHead=head;R.dirtySource=dirty;
fam=pol.altFamily.id;
if o.Run
 expect=sprintf('G2M4ARUN|%s|%s|family=%s|maxState=%d',upper(polSHA),mat.id,fam,pol.scopeLimits.maxStateIndex);
 assert(strcmp(char(o.AuthToken),expect),'G2M4:Authorization','Run token does not bind this policy SHA, material, family and step cap.');
 assert(~isempty(head)&&isempty(dirty),'G2M4:DirtySource','Uncommitted or untracked sources:\n%s',dirty);
end
chainRoot=fullfile(repo,'outputs','g2_m4_alt_family_v1');
chain=char(o.ChainDir);if isempty(chain),chain=fullfile(chainRoot,['chain_',mat.id,'_alt_v1']);end
chain=local_abs(chain);
assert(local_inside(chain,local_abs(chainRoot))&&~strcmpi(chain,local_abs(chainRoot)),'G2M4:ChainLocation','Chain must lie below %s.',chainRoot);
[~,cn]=fileparts(chain);assert(contains(cn,mat.id)&&~contains(cn,'S0ALT'),'G2M4:ChainName','Chain folder name must contain the material id "%s".',mat.id);
other=setdiff({mats.id},mat.id);assert(~any(cellfun(@(x)contains(cn,x),other)),'G2M4:ChainName','Chain name names another material.');
R.chainDir=strrep(chain,repo,'<repo>');
J=jsondecode(fileread(json));G=J.nominal_geometry_mm;
P0=reshape(pol.start.polyline_mm,[],2);if ~isequal(P0(:,1),[101.6;101.6]),P0=reshape(pol.start.polyline_mm.',[],2);end
t0=reshape(pol.start.tangent,1,2);
% ---------- HOLD chains are never reused
rootFile=fullfile(chain,'ROOT.mat');
holds=dir(fullfile(chain,'**','HOLD.mat'));
if ~isempty(holds)
 R.stage='HOLD_CHAIN_HAS_HOLD';R.message='This chain contains a HOLD record and is never reused.';
 if o.Run,error('G2M4:HoldChain','%s',R.message);end
 return
end
% ---------- shared alternative S0
S0=g2_m4a_s0alt('Mode','verify','S0Dir',o.S0Dir,'Reaudit',~isfile(rootFile));
R.s0RecordSHA256=S0.recordSHA256;
% ---------- ROOT
if isfile(rootFile)
 [Root,rootHash,ok]=g2_trajectory_record('read',rootFile);
 assert(ok,'G2M4:RootIntegrity','ROOT record integrity.');
 assert(strcmp(Root.material,mat.id)&&Root.ratio==mat.ratio&&strcmpi(Root.policySHA256,polSHA)&&isequal(Root.sourceHashes,src)&& ...
  strcmpi(Root.s0RecordSHA256,S0.recordSHA256)&&strcmpi(Root.s0MeshSHA256,S0.meshSHA256)&&strcmp(Root.family,fam), ...
  'G2M4:RootDrift','ROOT does not match the current material, policy, sources, family or S0ALT record.');
 Sm=local_check_solutions(fullfile(chain,'ROOT_S0'),Root.solutions,'G2M4:RootSolution');
 assert(Root.parent.KI_perkN==Sm.KI_perkN&&Root.parent.KII_perkN==Sm.KII_perkN&&isequal(Root.parent.crackPolyline_mm,P0), ...
  'G2M4:RootParent','ROOT parent K is not the chain''s own S0 solution.');
 parent=Root.parent;parentHash=rootHash;
else
 [Sols,ident]=local_solve(S0.Dm,S0.PM,mat,pol,polM,polT);
 Sm=Sols(1).S;
 parent0=struct('stateIndex',0,'crackPolyline_mm',P0,'tip_mm',P0(end,:),'t',t0,'KI_perkN',Sm.KI_perkN,'KII_perkN',Sm.KII_perkN);
 fprintf('G2_M4A_S0 %s: KI %.12f KII %+.12f per kN (own alternative-S0 solve)\n',mat.id,Sm.KI_perkN,Sm.KII_perkN);
 if ~o.Run
  F=local_forecast(parent0,G,pol);R.forecasts=F;R.s0=struct('KI_perkN',Sm.KI_perkN,'KII_perkN',Sm.KII_perkN,'identity',ident);
  R.pass=strcmp(F.status,'OK')&&F.admissibility.pass;
  R.stage='DRY_PREFLIGHT_NO_CHAIN';R.message='Dry: no files written. First step forecast only.';
  fprintf('G2_M4A_DRY %s: step-1 turn %.10f deg, tip (%.10f, %.10f), K1-K10 %d; NO_FILES=1\n',mat.id,F.localTurn_deg,F.tip_mm,F.admissibility.pass);
  return
 end
 assert(~isfolder(chain)||numel(dir(chain))<=2,'G2M4:ChainNotEmpty','Chain folder exists without ROOT; preserve and investigate.');
 if ~isfolder(chain),mkdir(chain);end
 try
  solRec=local_write_solutions(fullfile(chain,'ROOT_S0'),Sols,0,S0.meshSHA256,'');
 catch ME
  local_hold(fullfile(chain,'ROOT_S0'),0,ME.identifier,ME.message);
  R.stage='HOLD_ROOT';R.message=sprintf('%s: %s',ME.identifier,ME.message);fprintf(2,'G2_M4A_HOLD %s ROOT: %s\n',mat.id,R.message);return
 end
 Root=struct('schema','NewMetacomp.G2.M4A.Root.v1','family',fam,'material',mat.id,'ratio',mat.ratio,'policySHA256',polSHA, ...
  'sourceHashes',src,'gitHead',head,'s0RecordSHA256',S0.recordSHA256,'s0MeshSHA256',S0.meshSHA256, ...
  'parent',parent0,'solutions',solRec,'identityM0',ident,'created',datestr(now,31),'physicalFractureGrowthProven',false);
 rootHash=g2_trajectory_record('write',rootFile,Root);
 parent=parent0;parentHash=rootHash;
end
R.rootSHA256=rootHash;
% ---------- steps
for k=1:o.MaxStateIndex
 F=local_forecast(parent,G,pol);
 if isempty(R.forecasts),R.forecasts=F;else,R.forecasts(end+1)=F;end %#ok<AGROW>
 stepDir=fullfile(chain,sprintf('STEP_%03d',k));
 if ~strcmp(F.status,'OK')||~F.admissibility.pass
  R.stage='HOLD_DIRECTION_OR_GEOMETRY';R.message=sprintf('Step %d MTS/K1-K10 failed.',k);
  if o.Run,local_hold(stepDir,k,'G2M4:Geometry',R.message);end
  return
 end
 if sum(vecnorm(diff(F.polyline_mm,1,1),2,2))>pol.scopeLimits.maxArcLength_mm+1e-9
  R.stage='HOLD_ARC_CAP';R.message='Arc cap reached.';return
 end
 if isfile(fullfile(stepDir,'STATE.mat'))
  [St,stHash]=local_verify_step(stepDir,k,mat,polSHA,src,parentHash,F,true,json,p0,polM);
  R.statesReused=R.statesReused+1;
  fprintf('G2_M4A_REUSED_STATE_%s_%03d=1; NO_FEM_NO_REMESH=1\n',mat.id,k);
  parent=St;parentHash=stHash;R.lastStateIndex=k;continue
 end
 if isfile(fullfile(stepDir,'REVIEW.mat'))
  [Rev,revHash]=local_verify_step(stepDir,k,mat,polSHA,src,parentHash,F,false,json,p0,polM);
  if ~o.Run
   R.stage='DRY_REVIEW_PENDING_PROMOTION';R.lastStateIndex=k-1;R.pass=true;return
  end
  St=local_state(Rev,revHash,parentHash);stHash=g2_trajectory_record('write',fullfile(stepDir,'STATE.mat'),St);
  R.reviewsPromoted=R.reviewsPromoted+1;
  fprintf('G2_M4A_PROMOTED_REVIEW_%s_%03d=1; NO_FEM_NO_REMESH=1\n',mat.id,k);
  parent=St;parentHash=stHash;R.lastStateIndex=k;continue
 end
 if isfolder(stepDir)
  R.stage='HOLD_PARTIAL_STEP';R.message=sprintf('Step %d folder exists without a review; preserve and investigate.',k);
  if o.Run,error('G2M4:PartialStep','%s',R.message);end
  return
 end
 if ~o.Run
  R.stage='DRY_NEXT_STEP';R.pass=true;R.lastStateIndex=k-1;
  fprintf('G2_M4A_DRY %s: states verified through %d; next turn %.10f deg; NO_FILES=1\n',mat.id,k-1,F.localTurn_deg);
  return
 end
 mkdir(stepDir);
 try
  [St,stHash,stop]=local_compute_step(stepDir,k,F,parentHash,mat,pol,polSHA,polM,polT,src,head,json,p0,o.SimulateInterrupt);
 catch ME
  local_hold(stepDir,k,ME.identifier,ME.message);
  R.stage='HOLD_STEP';R.message=sprintf('%s: %s',ME.identifier,ME.message);R.holdIdentifier=ME.identifier;
  fprintf(2,'G2_M4A_HOLD %s step %d: %s\n',mat.id,k,R.message);
  return
 end
 if stop
  R.stage=['SIMULATED_INTERRUPT_AFTER_',upper(o.SimulateInterrupt.point)];R.lastStateIndex=k-strcmp(o.SimulateInterrupt.point,'review');
  R.pass=true;return
 end
 R.statesComputed=R.statesComputed+1;
 parent=St;parentHash=stHash;R.lastStateIndex=k;
end
R.pass=true;R.stage='STEP_CAP';R.message=sprintf('States verified through %d (policy cap %d).',R.lastStateIndex,pol.scopeLimits.maxStateIndex);
fprintf('G2_M4A_%s_STATES_THROUGH=%d STAGE=%s\n',upper(mat.id),R.lastStateIndex,R.stage);
end

% =====================================================================
function F=local_forecast(S,G,pol)
M=g2_mts_direction(S.KI_perkN,S.KII_perkN);
F=struct('status',M.status,'localTurn_deg',M.theta_deg,'theta_rad',M.theta_rad,'tip_mm',[NaN NaN],'tangent',[NaN NaN], ...
 'polyline_mm',S.crackPolyline_mm,'admissibility',struct('pass',false));
if ~strcmp(M.status,'OK'),return,end
d=pol.scopeLimits.increment_mm;
t=S.t(:).';n=[-t(2),t(1)];
tnew=cos(M.theta_rad)*t+sin(M.theta_rad)*n;
tip=S.tip_mm(:).'+d*tnew;
P=[S.crackPolyline_mm;tip];
A=g2_kink_admissibility(P,G,'ExpectedVertices',size(P,1),'DeltaA_mm',d,'ExpectedTangent',tnew);
F.tip_mm=tip;F.tangent=tnew;F.polyline_mm=P;F.admissibility=struct('pass',A.pass,'failedGates',{A.failedGates});
end

function [Sols,ident]=local_solve(Dm,PM,mat,pol,polM,polT)
% returns Sols(1) = driving case; homogeneous adds M0 (identity), Msoft, Mstiff on the same mesh
Em=pol.model.E_matrix_MPa;mk=@(E)struct('E',E,'nu',pol.model.nu_matrix,'plane',pol.model.plane);matM=mk(Em);
ident=struct();
if mat.ratio~=1
 K=g2_material_sif_on_mesh(Dm,PM.phase,[matM,mk(mat.ratio*Em)],polT,PM);
 S=g2_material_case_summary(mat.id,K,[],K.loadNode,polT,mat.ratio);
 Sols=struct('id',mat.id,'S',S,'u',K.u,'pass',K.pass,'failed',{K.failedCriteria});
 return
end
N=size(Dm.X6,1);f=polT.bvp.P_N/polT.bvp.thickness_mm;
nodeAt=@(xy)Dm.extraVertexNodes(vecnorm(reshape(Dm.extraVertexXY,[],2)-reshape(xy,1,2),2,2)<1e-9);
pin=nodeAt(polT.bvp.pin_mm);roller=nodeAt(polT.bvp.roller_mm);loadNode=nodeAt(polT.bvp.load_mm);
assert(isscalar(pin)&&isscalar(roller)&&isscalar(loadNode),'G2M4:Anchors','BVP anchors.');
Fv=zeros(2*N,1);Fv(2*loadNode)=-f;bc=struct('fixedDofs',[2*pin-1;2*pin;2*roller],'fixedValues',[0;0;0],'F',Fv);
SH=g2_t6_elasticity(Dm.X6,Dm.T6,matM,bc);
KH=g2_trajectory_sif_on_mesh(Dm,matM,polT);
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
ident=struct('checks',idc,'stiffness',dK,'displacement',dU,'K',dKs,'energy',dE,'reactions',dR,'compliance',dC,'MTS_deg',dT, ...
 'bitwiseUandEDI',isequal(SH.u,K0.u)&&isequal(KH.EDI_all,K0.EDI_all),'pass',all(cell2mat(struct2cell(idc))));
fprintf('G2_M4A_IDENTITY M0: K %.3g u %.3g SIF %.3g energy %.3g reactions %.3g compliance %.3g MTS %.3g bitwise=%d pass=%d\n', ...
 dK,dU,dKs,dE,dR,dC,dT,ident.bitwiseUandEDI,ident.pass);
M0=g2_material_case_summary('M0',K0,[],loadNode,polT,1);
Sols=struct('id','H1','S',H1,'u',SH.u,'pass',KH.pass&&ident.pass,'failed',{local_failed(KH,ident)});
Sols(2)=struct('id','M0','S',M0,'u',K0.u,'pass',K0.pass,'failed',{K0.failedCriteria});
clear SH K0
cases={'Msoft',.5;'Mstiff',2};
for i=1:2
 Kc=g2_material_sif_on_mesh(Dm,PM.phase,[matM,mk(cases{i,2}*Em)],polT,PM);
 Sm=g2_material_case_summary(cases{i,1},Kc,[],loadNode,polT,cases{i,2});
 Sols(end+1)=struct('id',cases{i,1},'S',Sm,'u',Kc.u,'pass',Kc.pass,'failed',{Kc.failedCriteria}); %#ok<AGROW>
 clear Kc
end
end

function f=local_failed(KH,ident)
f={};if ~KH.pass,f=[f,{'H1 SIF gates'}];end
if ~ident.pass,c=ident.checks;n=fieldnames(c);f=[f,strcat('M0 identity: ',n(~cellfun(@(q)c.(q),n))).'];end
end

function rec=local_write_solutions(dirp,Sols,k,meshHash,phaseHash)
% writes every solution record first (failed solves are preserved), then asserts the gates
if ~isfolder(dirp),mkdir(dirp);end
rec=repmat(struct('id','','file','','sha256','','pass',false),numel(Sols),1);
for i=1:numel(Sols)
 if i==1,fn='SOLUTION.mat';else,fn=['SOLUTION_',Sols(i).id,'.mat'];end
 Sol=Sols(i).S;Sol.schema='NewMetacomp.G2.M4A.Solution.v1';Sol.stateIndex=k;Sol.u=Sols(i).u;Sol.meshSHA256=meshHash;Sol.phaseSHA256=phaseHash;
 rec(i)=struct('id',Sols(i).id,'file',fn,'sha256',g2_trajectory_record('write',fullfile(dirp,fn),Sol),'pass',Sols(i).pass);
end
for i=1:numel(Sols)
 assert(Sols(i).pass,'G2M4:SIF','%s SIF/identity gates failed: %s',Sols(i).id,strjoin(Sols(i).failed,', '));
end
end

function Sm=local_check_solutions(dirp,rec,id)
Sm=[];
for i=1:numel(rec)
 [S,h,ok]=g2_trajectory_record('read',fullfile(dirp,rec(i).file));
 assert(ok&&strcmpi(h,rec(i).sha256)&&strcmp(S.id,rec(i).id)&&rec(i).pass&&S.pass,id,'Solution record %s.',rec(i).file);
 if i==1,Sm=S;end
end
end

function [St,stHash,stop]=local_compute_step(stepDir,k,F,parentHash,mat,pol,polSHA,polM,polT,src,head,json,p0,interrupt)
stop=false;P=F.polyline_mm;t=F.tangent;
opts=local_opts(pol.altFamily.exteriorOptions);
B=g2_kinked_join(P,'ExteriorOptions',opts,'ExpectedVertices',size(P,1),'MaxT3Elements',pol.mesh.T3max,'ExpectedTangent',t);
assert(B.pass,'G2M4:MeshHOLD','%s %s',B.stage,B.message);
meshFile=fullfile(stepDir,'KINKED_GEOMETRY_ONLY_candidate.mat');
local_save_mesh(meshFile,B,P,t,pol.altFamily.id);
meshHash=g2_sha256_file(meshFile);D=load(meshFile);
C=g2_kinked_mesh_auditor(D,json,p0,size(P,1));
assert(C.pass&&C.gatesPassed==34&&C.gatesTotal==34&&C.summary.T3elements<=pol.mesh.T3max&& ...
 C.summary.minAngle_deg>=pol.mesh.minAngle_deg&&C.summary.maxNeighborRatio<=pol.mesh.maxNeighborRatio&&C.summary.qActive==pol.mesh.qActiveParents, ...
 'G2M4:Audit','Independent audit %d/%d, T3 %d, angle %.3f, ratio %.3f.',C.gatesPassed,C.gatesTotal,C.summary.T3elements,C.summary.minAngle_deg,C.summary.maxNeighborRatio);
[Dm,Ad]=g2_m2_state_adapter(D,sprintf('A%d',k),P);assert(Ad.pass,'G2M4:Adapter','Adapter: %s',strjoin(Ad.failed,', '));
[PM,V,NC,geom]=g2_material_phase_stage(Dm,polM,P);
assert(PM.pass&&V.pass&&NC.pass,'G2M4:Phase','Phase stage failed (map %d, verifier %d, negatives %d).',PM.pass,V.pass,NC.pass);
phaseHash=g2_trajectory_record('write',fullfile(stepDir,'PHASE_MAP.mat'),struct('schema','NewMetacomp.G2.MaterialPhaseMap.v1', ...
 'stateIndex',k,'material',mat.id,'family',pol.altFamily.id,'phase',PM.phase,'annulusOf',PM.annulusOf,'interfaces',PM.interfaces,'verifierValues',V.values, ...
 'negatives',struct('pass',NC.pass,'tipToBand_mm',NC.tipToBand_mm,'N7s_rejected',NC.N7s_rejected),'meshSHA256',meshHash,'geometry',geom));
[Sols,ident]=local_solve(Dm,PM,mat,pol,polM,polT);
solRec=local_write_solutions(stepDir,Sols,k,meshHash,phaseHash);
S=Sols(1).S;sif=rmfield(S,'chordTractions');
Rev=struct('schema','NewMetacomp.G2.M4A.Review.v1','family',pol.altFamily.id,'stateIndex',k,'material',mat.id,'ratio',mat.ratio,'policySHA256',polSHA, ...
 'sourceHashes',src,'gitHead',head,'parentSHA256',parentHash,'polyline_mm',P,'tip_mm',F.tip_mm,'tangent',t, ...
 'localTurn_deg',F.localTurn_deg,'admissibility',F.admissibility,'meshFile','KINKED_GEOMETRY_ONLY_candidate.mat','meshSHA256',meshHash, ...
 'meshSummary',struct('T3elements',C.summary.T3elements,'minAngle_deg',C.summary.minAngle_deg,'maxNeighborRatio',C.summary.maxNeighborRatio,'qActive',C.summary.qActive), ...
 'auditGates',sprintf('%d/%d',C.gatesPassed,C.gatesTotal),'phaseFile','PHASE_MAP.mat','phaseSHA256',phaseHash,'geometry',geom, ...
 'solutions',solRec,'identityM0',ident,'sif',sif,'physicalFractureGrowthProven',false);
revHash=g2_trajectory_record('write',fullfile(stepDir,'REVIEW.mat'),Rev);
fprintf('G2_M4A_REVIEW_%s_%03d: tip (%.10f, %.10f) turn %.10f deg T3 %d audit %s chords %s KI %.9f KII %+.9f per kN\n', ...
 mat.id,k,F.tip_mm,F.localTurn_deg,C.summary.T3elements,Rev.auditGates,mat2str(geom.chordsPerCircle(:).'),S.KI_perkN,S.KII_perkN);
St=[];stHash='';
if strcmp(interrupt.point,'review')&&interrupt.step==k,stop=true;return,end
St=local_state(Rev,revHash,parentHash);
stHash=g2_trajectory_record('write',fullfile(stepDir,'STATE.mat'),St);
if strcmp(interrupt.point,'state')&&interrupt.step==k,stop=true;end
end

function St=local_state(Rev,revHash,parentHash)
s=Rev.sif;
St=struct('schema','NewMetacomp.G2.M4A.State.v1','family',Rev.family,'stateIndex',Rev.stateIndex,'material',Rev.material,'ratio',Rev.ratio, ...
 'parentSHA256',parentHash,'reviewSHA256',revHash,'policySHA256',Rev.policySHA256,'sourceHashes',Rev.sourceHashes, ...
 'crackPolyline_mm',Rev.polyline_mm,'tip_mm',Rev.tip_mm,'t',Rev.tangent,'localTurn_deg',Rev.localTurn_deg, ...
 'KI_perkN',s.KI_perkN,'KII_perkN',s.KII_perkN,'KI_raw',s.KI_raw,'KII_raw',s.KII_raw,'KI_COD_raw',s.KI_COD_raw,'KII_COD_raw',s.KII_COD_raw, ...
 'EDI_all',s.EDI_all,'EDI4x4',s.EDI4x4,'J',s.J,'meshSHA256',Rev.meshSHA256,'phaseSHA256',Rev.phaseSHA256,'solutions',Rev.solutions, ...
 'numericalOnly',true,'physical_onset',false,'physicalFractureGrowthProven',false);
end

function [Out,outHash]=local_verify_step(stepDir,k,mat,polSHA,src,parentHash,F,requireState,json,p0,polM)
[Rev,revHash,ok]=g2_trajectory_record('read',fullfile(stepDir,'REVIEW.mat'));
assert(ok,'G2M4:ReviewIntegrity','Step %d review integrity.',k);
assert(Rev.stateIndex==k&&strcmp(Rev.material,mat.id)&&Rev.ratio==mat.ratio&&strcmpi(Rev.policySHA256,polSHA)&& ...
 isequal(Rev.sourceHashes,src)&&strcmpi(Rev.parentSHA256,parentHash),'G2M4:ReviewLinks','Step %d review links (material/policy/sources/parent).',k);
assert(isequal(Rev.polyline_mm,F.polyline_mm)&&isequal(Rev.tangent,F.tangent),'G2M4:ForecastDrift','Step %d review path is not the forecast from its parent K.',k);
mf=fullfile(stepDir,Rev.meshFile);
assert(isfile(mf)&&strcmpi(g2_sha256_file(mf),Rev.meshSHA256),'G2M4:ReviewMeshHash','Step %d mesh hash.',k);
D=load(mf);
assert(isequal(D.crackPolyline,Rev.polyline_mm)&&isequal(D.tipTangent(:).',Rev.tangent(:).')&&isfield(D,'familyTag')&&strcmp(D.familyTag,Rev.family), ...
 'G2M4:ReviewMeshContent','Step %d mesh is not the reviewed geometry of this family.',k);
C=g2_kinked_mesh_auditor(D,json,p0,size(Rev.polyline_mm,1));ms=Rev.meshSummary;
assert(C.pass&&C.gatesPassed==34&&C.summary.T3elements==ms.T3elements&&C.summary.minAngle_deg==ms.minAngle_deg&& ...
 C.summary.maxNeighborRatio==ms.maxNeighborRatio&&C.summary.qActive==ms.qActive,'G2M4:ReviewReaudit','Step %d re-audit differs.',k);
[Ph,phHash,ok]=g2_trajectory_record('read',fullfile(stepDir,Rev.phaseFile));
assert(ok&&strcmpi(phHash,Rev.phaseSHA256)&&strcmpi(Ph.meshSHA256,Rev.meshSHA256),'G2M4:ReviewPhaseRecord','Step %d phase record.',k);
[Dm,Ad]=g2_m2_state_adapter(D,sprintf('A%d',k),Rev.polyline_mm);assert(Ad.pass,'G2M4:ReviewAdapter','Step %d adapter.',k);
[PM,V,NC]=g2_material_phase_stage(Dm,polM,Rev.polyline_mm);
assert(PM.pass&&V.pass&&NC.pass&&isequal(PM.phase,Ph.phase),'G2M4:ReviewPhase','Step %d saved phase labels are not the re-verified map.',k);
Vs=g2_material_phase_verify(Dm.X6,Dm.T6,Ph.phase,[152.4 69.85;152.4 120.65;152.4 171.45],6.35*ones(3,1),19.05*ones(3,1), ...
 struct('twins',[Dm.upperBankT6(:),Dm.lowerBankT6(:)],'tip',Rev.polyline_mm(end,:),'qOuterRadii_mm',2.6,'outerArea_mm2',508*203.2));
assert(Vs.pass,'G2M4:ReviewPhaseLabels','Step %d saved labels fail the verifier.',k);
Sm=local_check_solutions(stepDir,Rev.solutions,'G2M4:ReviewSolution');
assert(isequal(Sm.EDI_all,Rev.sif.EDI_all)&&Sm.KI_COD_raw==Rev.sif.KI_COD_raw&&strcmpi(Sm.meshSHA256,Rev.meshSHA256)&&strcmpi(Sm.phaseSHA256,Rev.phaseSHA256), ...
 'G2M4:ReviewSolution','Step %d solution record does not match the review.',k);
if requireState
 [St,stHash,ok]=g2_trajectory_record('read',fullfile(stepDir,'STATE.mat'));
 assert(ok,'G2M4:StateIntegrity','Step %d state integrity.',k);
 assert(strcmpi(St.reviewSHA256,revHash)&&strcmpi(St.parentSHA256,parentHash)&&isequal(St.crackPolyline_mm,Rev.polyline_mm)&& ...
  St.KI_perkN==Rev.sif.KI_perkN&&St.KII_perkN==Rev.sif.KII_perkN&&strcmp(St.material,mat.id),'G2M4:StateMismatch','Step %d state does not match its review.',k);
 Out=St;outHash=stHash;
else
 Out=Rev;outHash=revHash;
end
end

function local_save_mesh(meshFile,B,P,t,familyTag) %#ok<INUSD>
assert(~isfile(meshFile),'G2M4:MeshExists','Refusing to overwrite a mesh.');
X3=B.X3;T3=B.T3;X6=B.X6;T6=B.T6;upperBankT6=B.upperBankT6;lowerBankT6=B.lowerBankT6; %#ok<NASGU>
physicalTipNode=B.physicalTipNode;nodalQ=B.nodalQ;qActiveT6Rows=B.qActiveT6Rows;elementRows=B.elementRows; %#ok<NASGU>
collarOuterIDs=B.collarOuterIDs;extraVertexXY=B.extraVertexXY;extraVertexNodes=B.extraVertexNodes;crackPolyline=P; %#ok<NASGU>
tipTangent=t;tipNormal=[-t(2),t(1)];kinkNodeIDs=B.kinkNodeIDs;geometryOnly=true;approvedForLEFM=false; %#ok<NASGU>
plateXRange=B.plateXRange;includeHoles=true;mirrorControl=false; %#ok<NASGU>
save(meshFile,'X3','T3','X6','T6','upperBankT6','lowerBankT6','physicalTipNode','nodalQ','qActiveT6Rows','elementRows', ...
 'collarOuterIDs','extraVertexXY','extraVertexNodes','crackPolyline','tipTangent','tipNormal','kinkNodeIDs', ...
 'geometryOnly','approvedForLEFM','plateXRange','includeHoles','mirrorControl','familyTag','-v7.3');
end

function local_hold(stepDir,k,id,msg)
if ~isfolder(stepDir),mkdir(stepDir);end
f=fullfile(stepDir,'HOLD.mat');
if ~isfile(f)
 g2_trajectory_record('write',f,struct('schema','NewMetacomp.G2.M4A.Hold.v1','stateIndex',k,'identifier',id,'message',msg,'created',datestr(now,31)));
end
end

function o=local_opts(x)
if iscell(x),o=x(:).';else,o=num2cell(x(:).');end
for k=1:numel(o)
 if isnumeric(o{k}),o{k}=reshape(o{k},1,[]);end
end
end

function [head,dirty]=local_git(repo)
head='';dirty='git unavailable';
[s1,h]=system(sprintf('git -C "%s" rev-parse HEAD',repo));
[s2,d]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all -- matlab/g2 docs/research/crack-growth-gaps-2026',repo));
if s1==0&&s2==0,head=strtrim(h);dirty=strtrim(d);end
end

function p=local_abs(p)
p=char(p);if ~java.io.File(p).isAbsolute(),p=fullfile(pwd,p);end
p=char(java.io.File(p).getCanonicalPath());
end

function tf=local_inside(a,b)
a=lower(strrep(a,'/','\'));b=lower(strrep(b,'/','\'));
if ~endsWith(b,'\'),b=[b,'\'];end
tf=strcmp([a,'\'],b)||startsWith([a,'\'],b);
end
