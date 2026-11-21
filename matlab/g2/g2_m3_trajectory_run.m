function R = g2_m3_trajectory_run(varargin)
%G2_M3_TRAJECTORY_RUN  Bounded two-step material-specific numerical crack path (Issue #39).
%
%  R = g2_m3_trajectory_run('Material','soft'|'stiff', ...)
% Options: 'ChainDir' (default outputs/g2_material_trajectories_v1/chain_<material>_v1),
%  'Run' (false = dry, read only, writes nothing), 'AuthToken' (required with Run:
%  G2M3RUN|<policy SHA>|<material>|maxState=2), 'MaxStateIndex' (<= policy cap 2),
%  'SimulateInterrupt' struct('point','review'|'state','step',k) for restart tests.
% G2_M3_TRAJECTORY_POLICY_v1.json / G2_M3_PREREGISTRATION.md. Per chain:
%  ROOT   PR #38 S0 material record (hash vs M2 ledger), S0 material solve recomputed and
%         required BITWISE equal; source hashes; policy SHA; material id and ratio
%  step k recurrence of g2_trajectory_run from the parent's own full-precision K; K1-K10;
%         new protected mesh (g2_kinked_join), saved-array 34/34 audit, new phase map +
%         verifier + negatives, new two-phase solve (g2_material_sif_on_mesh, all gates);
%         PHASE_MAP, SOLUTION, REVIEW, then STATE records (SHA manifests, never overwritten)
%  reuse  REVIEW/STATE re-verified (forecast, hashes, mesh content, 34/34, phase re-map and
%         verifier) without FEM; an interrupted REVIEW is promoted without FEM
% Any failure writes HOLD.mat in the step folder (Run) and stops; a chain with a HOLD is
% never reused. No third step, no onset, no toughness, no CZM.
ip=inputParser;
addParameter(ip,'Material','',@(s)ischar(s)||isstring(s));
addParameter(ip,'ChainDir','',@(s)ischar(s)||isstring(s));
addParameter(ip,'Run',false,@islogical);
addParameter(ip,'AuthToken','',@(s)ischar(s)||isstring(s));
addParameter(ip,'MaxStateIndex',2,@(v)isnumeric(v)&&isscalar(v));
addParameter(ip,'SimulateInterrupt',struct('point','','step',0),@isstruct);
parse(ip,varargin{:});o=ip.Results;
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
pol=jsondecode(fileread(fullfile(here,'G2_M3_TRAJECTORY_POLICY_v1.json')));
polSHA=g2_sha256_file(fullfile(here,'G2_M3_TRAJECTORY_POLICY_v1.json'));
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
 strcmpi(g2_sha256_file(json),b.cornellJSON_SHA256)&&strcmpi(g2_sha256_file(p0),b.trustedP0SHA256),'G2M3:PolicyHash','A pinned policy/JSON/P0 hash differs.');
mats=pol.materials;if iscell(mats),mats=[mats{:}];end
im=find(strcmp({mats.id},char(o.Material)));
assert(isscalar(im),'G2M3:Material','Unknown material id "%s".',char(o.Material));
mat=mats(im);
assert(o.MaxStateIndex>=1&&o.MaxStateIndex<=pol.scopeLimits.maxStateIndex&&o.MaxStateIndex==round(o.MaxStateIndex), ...
 'G2M3:StepCap','Requested MaxStateIndex %g exceeds the policy cap %d.',o.MaxStateIndex,pol.scopeLimits.maxStateIndex);
rel=['R',version('-release')];assert(strcmp(rel,pol.resources.matlabRelease),'G2M3:Release','MATLAB %s is not R2023a.',rel);
src=local_sources(here);R.sourceHashes=src;
[head,dirty]=local_git(repo);R.gitHead=head;R.dirtySource=dirty;
if o.Run
 expect=sprintf('G2M3RUN|%s|%s|maxState=%d',upper(polSHA),mat.id,pol.scopeLimits.maxStateIndex);
 assert(strcmp(char(o.AuthToken),expect),'G2M3:Authorization','Run token does not bind this policy SHA, material and step cap.');
 assert(~isempty(head)&&isempty(dirty),'G2M3:DirtySource','Uncommitted or untracked sources:\n%s',dirty);
end
chainRoot=fullfile(repo,'outputs','g2_material_trajectories_v1');
chain=char(o.ChainDir);if isempty(chain),chain=fullfile(chainRoot,['chain_',mat.id,'_v1']);end
chain=local_abs(chain);
assert(local_inside(chain,local_abs(chainRoot))&&~strcmpi(chain,local_abs(chainRoot)),'G2M3:ChainLocation','Chain must lie below %s.',chainRoot);
[~,cn]=fileparts(chain);assert(contains(cn,mat.id),'G2M3:ChainName','Chain folder name must contain the material id "%s".',mat.id);
other=setdiff({mats.id},mat.id);assert(~any(cellfun(@(x)contains(cn,x),other)),'G2M3:ChainName','Chain name names another material.');
R.chainDir=strrep(chain,repo,'<repo>');
% ---------- S0 sources and the read-only H-REC control
s0Mesh=fullfile(repo,b.s0Mesh);
assert(strcmpi(g2_sha256_file(s0Mesh),b.s0MeshSHA256),'G2M3:S0Mesh','S0 mesh hash.');
recS0=local_m2_record(repo,b,['S0_',mat.m2Case]);
parent0=struct('stateIndex',0,'crackPolyline_mm',pol.start.polyline_mm,'tip_mm',pol.start.polyline_mm(end,:), ...
 't',reshape(pol.start.tangent,1,2),'KI_perkN',recS0.KI_perkN,'KII_perkN',recS0.KII_perkN);
R.hrec=local_hrec(repo,b,pol,json);
assert(R.hrec.pass,'G2M3:HREC','The recurrence does not reproduce the homogeneous S1/S2 polylines.');
J=jsondecode(fileread(json));G=J.nominal_geometry_mm;
% ---------- ROOT
rootFile=fullfile(chain,'ROOT.mat');
holds=dir(fullfile(chain,'**','HOLD.mat'));
if ~isempty(holds)
 R.stage='HOLD_CHAIN_HAS_HOLD';R.message='This chain contains a HOLD record and is never reused.';
 if o.Run,error('G2M3:HoldChain','%s',R.message);end
 return
end
if isfile(rootFile)
 [Root,rootHash,ok]=g2_trajectory_record('read',rootFile);
 assert(ok,'G2M3:RootIntegrity','ROOT record integrity.');
 assert(strcmp(Root.material,mat.id)&&Root.ratio==mat.ratio&&strcmpi(Root.policySHA256,polSHA)&&isequal(Root.sourceHashes,src)&& ...
  strcmpi(Root.s0RecordSHA256,b.m2CaseSHA256.(['S0_',mat.m2Case]))&&Root.parent.KI_perkN==parent0.KI_perkN&&Root.parent.KII_perkN==parent0.KII_perkN, ...
  'G2M3:RootDrift','ROOT does not match the current material, policy, sources or S0 record.');
 parent=parent0;parentHash=rootHash;
else
 S0chk=local_s0_recompute(repo,b,s0Mesh,recS0,mat,polM,polT,pol);
 R.s0Recompute=S0chk;
 assert(S0chk.bitwise,'G2M3:S0Recompute','Recomputed S0 material solve differs from the PR #38 record.');
 if ~o.Run
  F=local_forecast(parent0,G,pol);R.forecasts=F;
  R.pass=strcmp(F.status,'OK')&&F.admissibility.pass;
  R.stage='DRY_PREFLIGHT_NO_CHAIN';R.message='Dry: no files written. First step forecast only.';
  fprintf('G2_M3_DRY %s: S0 recompute bitwise=%d; step-1 turn %.10f deg, tip (%.10f, %.10f), K1-K10 %d; NO_FILES=1\n', ...
   mat.id,S0chk.bitwise,F.localTurn_deg,F.tip_mm,F.admissibility.pass);
  return
 end
 assert(~isfolder(chain)||numel(dir(chain))<=2,'G2M3:ChainNotEmpty','Chain folder exists without ROOT; preserve and investigate.');
 if ~isfolder(chain),mkdir(chain);end
 Root=struct('schema','NewMetacomp.G2.M3.Root.v1','material',mat.id,'ratio',mat.ratio,'policySHA256',polSHA, ...
  'sourceHashes',src,'gitHead',head,'s0MeshSHA256',b.s0MeshSHA256,'s0RecordSHA256',b.m2CaseSHA256.(['S0_',mat.m2Case]), ...
  'parent',parent0,'s0Recompute',S0chk,'hrec',R.hrec,'created',datestr(now,31),'physicalFractureGrowthProven',false);
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
  if o.Run,local_hold(stepDir,k,'G2M3:Geometry',R.message);end
  return
 end
 if sum(vecnorm(diff(F.polyline_mm,1,1),2,2))>pol.scopeLimits.maxArcLength_mm+1e-9
  R.stage='HOLD_ARC_CAP';R.message='Arc cap reached.';return
 end
 if isfile(fullfile(stepDir,'STATE.mat'))
  [St,stHash]=local_verify_step(stepDir,k,mat,polSHA,src,parentHash,F,true,json,p0,polM);
  R.statesReused=R.statesReused+1;
  fprintf('G2_M3_REUSED_STATE_%s_%03d=1; NO_FEM_NO_REMESH=1\n',mat.id,k);
  parent=St;parentHash=stHash;R.lastStateIndex=k;continue
 end
 if isfile(fullfile(stepDir,'REVIEW.mat'))
  [Rev,revHash]=local_verify_step(stepDir,k,mat,polSHA,src,parentHash,F,false,json,p0,polM);
  if ~o.Run
   R.stage='DRY_REVIEW_PENDING_PROMOTION';R.lastStateIndex=k-1;R.pass=true;return
  end
  St=local_state(Rev,revHash,parentHash);stHash=g2_trajectory_record('write',fullfile(stepDir,'STATE.mat'),St);
  R.reviewsPromoted=R.reviewsPromoted+1;
  fprintf('G2_M3_PROMOTED_REVIEW_%s_%03d=1; NO_FEM_NO_REMESH=1\n',mat.id,k);
  parent=St;parentHash=stHash;R.lastStateIndex=k;continue
 end
 if isfolder(stepDir)
  R.stage='HOLD_PARTIAL_STEP';R.message=sprintf('Step %d folder exists without a review; preserve and investigate.',k);
  if o.Run,error('G2M3:PartialStep','%s',R.message);end
  return
 end
 if ~o.Run
  R.stage='DRY_NEXT_STEP';R.pass=true;R.lastStateIndex=k-1;
  fprintf('G2_M3_DRY %s: states verified through %d; next turn %.10f deg; NO_FILES=1\n',mat.id,k-1,F.localTurn_deg);
  return
 end
 mkdir(stepDir);
 try
  [St,stHash,stop]=local_compute_step(stepDir,k,F,parentHash,mat,pol,polSHA,polM,polT,src,head,json,p0,o.SimulateInterrupt);
 catch ME
  local_hold(stepDir,k,ME.identifier,ME.message);
  R.stage='HOLD_STEP';R.message=sprintf('%s: %s',ME.identifier,ME.message);R.holdIdentifier=ME.identifier;
  fprintf(2,'G2_M3_HOLD %s step %d: %s\n',mat.id,k,R.message);
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
fprintf('G2_M3_%s_STATES_THROUGH=%d STAGE=%s\n',upper(mat.id),R.lastStateIndex,R.stage);
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

function [St,stHash,stop]=local_compute_step(stepDir,k,F,parentHash,mat,pol,polSHA,polM,polT,src,head,json,p0,interrupt)
stop=false;P=F.polyline_mm;t=F.tangent;
opts={'BottomVertices_mm',[25.4 482.6],'TopVertices_mm',254,'TipGuideRadius_mm',15,'TipGuideHface_mm',1.5};
B=g2_kinked_join(P,'ExteriorOptions',opts,'ExpectedVertices',size(P,1),'MaxT3Elements',pol.mesh.T3max,'ExpectedTangent',t);
assert(B.pass,'G2M3:MeshHOLD','%s %s',B.stage,B.message);
meshFile=fullfile(stepDir,'KINKED_GEOMETRY_ONLY_candidate.mat');
local_save_mesh(meshFile,B,P,t);
meshHash=g2_sha256_file(meshFile);D=load(meshFile);
C=g2_kinked_mesh_auditor(D,json,p0,size(P,1));
assert(C.pass&&C.gatesPassed==34&&C.gatesTotal==34&&C.summary.T3elements<=pol.mesh.T3max&& ...
 C.summary.minAngle_deg>=pol.mesh.minAngle_deg&&C.summary.maxNeighborRatio<=pol.mesh.maxNeighborRatio&&C.summary.qActive==pol.mesh.qActiveParents, ...
 'G2M3:Audit','Independent audit %d/%d, T3 %d, angle %.3f, ratio %.3f.',C.gatesPassed,C.gatesTotal,C.summary.T3elements,C.summary.minAngle_deg,C.summary.maxNeighborRatio);
[Dm,Ad]=g2_m2_state_adapter(D,sprintf('M%d',k),P);assert(Ad.pass,'G2M3:Adapter','Adapter: %s',strjoin(Ad.failed,', '));
[PM,V,NC,geom]=g2_material_phase_stage(Dm,polM,P);
assert(PM.pass&&V.pass&&NC.pass,'G2M3:Phase','Phase stage failed (map %d, verifier %d, negatives %d).',PM.pass,V.pass,NC.pass);
phaseHash=g2_trajectory_record('write',fullfile(stepDir,'PHASE_MAP.mat'),struct('schema','NewMetacomp.G2.MaterialPhaseMap.v1', ...
 'stateIndex',k,'material',mat.id,'phase',PM.phase,'annulusOf',PM.annulusOf,'interfaces',PM.interfaces,'verifierValues',V.values, ...
 'negatives',struct('pass',NC.pass,'tipToBand_mm',NC.tipToBand_mm,'N7s_rejected',NC.N7s_rejected),'meshSHA256',meshHash,'geometry',geom));
Em=pol.model.E_matrix_MPa;mk=@(E)struct('E',E,'nu',pol.model.nu_matrix,'plane',pol.model.plane);
K=g2_material_sif_on_mesh(Dm,PM.phase,[mk(Em),mk(mat.ratio*Em)],polT,PM);
S=g2_material_case_summary(mat.id,K,[],K.loadNode,polT,mat.ratio);
Sol=S;Sol.schema='NewMetacomp.G2.M3.Solution.v1';Sol.stateIndex=k;Sol.u=K.u;Sol.meshSHA256=meshHash;Sol.phaseSHA256=phaseHash;
solHash=g2_trajectory_record('write',fullfile(stepDir,'SOLUTION.mat'),Sol);
assert(K.pass,'G2M3:SIF','SIF gates failed: %s',strjoin(K.failedCriteria,', '));
sif=rmfield(S,'chordTractions');
Rev=struct('schema','NewMetacomp.G2.M3.Review.v1','stateIndex',k,'material',mat.id,'ratio',mat.ratio,'policySHA256',polSHA, ...
 'sourceHashes',src,'gitHead',head,'parentSHA256',parentHash,'polyline_mm',P,'tip_mm',F.tip_mm,'tangent',t, ...
 'localTurn_deg',F.localTurn_deg,'admissibility',F.admissibility,'meshFile','KINKED_GEOMETRY_ONLY_candidate.mat','meshSHA256',meshHash, ...
 'meshSummary',struct('T3elements',C.summary.T3elements,'minAngle_deg',C.summary.minAngle_deg,'maxNeighborRatio',C.summary.maxNeighborRatio,'qActive',C.summary.qActive), ...
 'auditGates',sprintf('%d/%d',C.gatesPassed,C.gatesTotal),'phaseFile','PHASE_MAP.mat','phaseSHA256',phaseHash,'geometry',geom, ...
 'solutionFile','SOLUTION.mat','solutionSHA256',solHash,'sif',sif,'physicalFractureGrowthProven',false);
revHash=g2_trajectory_record('write',fullfile(stepDir,'REVIEW.mat'),Rev);
fprintf('G2_M3_REVIEW_%s_%03d: tip (%.10f, %.10f) turn %.10f deg T3 %d audit %s KI %.9f KII %+.9f per kN\n', ...
 mat.id,k,F.tip_mm,F.localTurn_deg,C.summary.T3elements,Rev.auditGates,S.KI_perkN,S.KII_perkN);
St=[];stHash='';
if strcmp(interrupt.point,'review')&&interrupt.step==k,stop=true;return,end
St=local_state(Rev,revHash,parentHash);
stHash=g2_trajectory_record('write',fullfile(stepDir,'STATE.mat'),St);
if strcmp(interrupt.point,'state')&&interrupt.step==k,stop=true;end
end

function St=local_state(Rev,revHash,parentHash)
s=Rev.sif;
St=struct('schema','NewMetacomp.G2.M3.MaterialState.v1','stateIndex',Rev.stateIndex,'material',Rev.material,'ratio',Rev.ratio, ...
 'parentSHA256',parentHash,'reviewSHA256',revHash,'policySHA256',Rev.policySHA256,'sourceHashes',Rev.sourceHashes, ...
 'crackPolyline_mm',Rev.polyline_mm,'tip_mm',Rev.tip_mm,'t',Rev.tangent,'localTurn_deg',Rev.localTurn_deg, ...
 'KI_perkN',s.KI_perkN,'KII_perkN',s.KII_perkN,'KI_raw',s.KI_raw,'KII_raw',s.KII_raw,'KI_COD_raw',s.KI_COD_raw,'KII_COD_raw',s.KII_COD_raw, ...
 'EDI_all',s.EDI_all,'EDI4x4',s.EDI4x4,'J',s.J,'meshSHA256',Rev.meshSHA256,'phaseSHA256',Rev.phaseSHA256,'solutionSHA256',Rev.solutionSHA256, ...
 'numericalOnly',true,'physical_onset',false,'physicalFractureGrowthProven',false);
end

function [Out,outHash]=local_verify_step(stepDir,k,mat,polSHA,src,parentHash,F,requireState,json,p0,polM)
[Rev,revHash,ok]=g2_trajectory_record('read',fullfile(stepDir,'REVIEW.mat'));
assert(ok,'G2M3:ReviewIntegrity','Step %d review integrity.',k);
assert(Rev.stateIndex==k&&strcmp(Rev.material,mat.id)&&Rev.ratio==mat.ratio&&strcmpi(Rev.policySHA256,polSHA)&& ...
 isequal(Rev.sourceHashes,src)&&strcmpi(Rev.parentSHA256,parentHash),'G2M3:ReviewLinks','Step %d review links (material/policy/sources/parent).',k);
assert(isequal(Rev.polyline_mm,F.polyline_mm)&&isequal(Rev.tangent,F.tangent),'G2M3:ForecastDrift','Step %d review path is not the forecast from its parent K.',k);
mf=fullfile(stepDir,Rev.meshFile);
assert(isfile(mf)&&strcmpi(g2_sha256_file(mf),Rev.meshSHA256),'G2M3:ReviewMeshHash','Step %d mesh hash.',k);
D=load(mf);
assert(isequal(D.crackPolyline,Rev.polyline_mm)&&isequal(D.tipTangent(:).',Rev.tangent(:).'),'G2M3:ReviewMeshContent','Step %d mesh is not the reviewed geometry.',k);
C=g2_kinked_mesh_auditor(D,json,p0,size(Rev.polyline_mm,1));ms=Rev.meshSummary;
assert(C.pass&&C.gatesPassed==34&&C.summary.T3elements==ms.T3elements&&C.summary.minAngle_deg==ms.minAngle_deg&& ...
 C.summary.maxNeighborRatio==ms.maxNeighborRatio&&C.summary.qActive==ms.qActive,'G2M3:ReviewReaudit','Step %d re-audit differs.',k);
[Ph,phHash,ok]=g2_trajectory_record('read',fullfile(stepDir,Rev.phaseFile));
assert(ok&&strcmpi(phHash,Rev.phaseSHA256)&&strcmpi(Ph.meshSHA256,Rev.meshSHA256),'G2M3:ReviewPhaseRecord','Step %d phase record.',k);
[Dm,Ad]=g2_m2_state_adapter(D,sprintf('M%d',k),Rev.polyline_mm);assert(Ad.pass,'G2M3:ReviewAdapter','Step %d adapter.',k);
[PM,V,NC]=g2_material_phase_stage(Dm,polM,Rev.polyline_mm);
assert(PM.pass&&V.pass&&NC.pass&&isequal(PM.phase,Ph.phase),'G2M3:ReviewPhase','Step %d saved phase labels are not the re-verified map.',k);
Vs=g2_material_phase_verify(Dm.X6,Dm.T6,Ph.phase,[152.4 69.85;152.4 120.65;152.4 171.45],6.35*ones(3,1),19.05*ones(3,1), ...
 struct('twins',[Dm.upperBankT6(:),Dm.lowerBankT6(:)],'tip',Rev.polyline_mm(end,:),'qOuterRadii_mm',2.6,'outerArea_mm2',508*203.2));
assert(Vs.pass,'G2M3:ReviewPhaseLabels','Step %d saved labels fail the verifier.',k);
[Sol,solHash,ok]=g2_trajectory_record('read',fullfile(stepDir,Rev.solutionFile));
assert(ok&&strcmpi(solHash,Rev.solutionSHA256)&&isequal(Sol.EDI_all,Rev.sif.EDI_all)&&Sol.KI_COD_raw==Rev.sif.KI_COD_raw, ...
 'G2M3:ReviewSolution','Step %d solution record.',k);
if requireState
 [St,stHash,ok]=g2_trajectory_record('read',fullfile(stepDir,'STATE.mat'));
 assert(ok,'G2M3:StateIntegrity','Step %d state integrity.',k);
 assert(strcmpi(St.reviewSHA256,revHash)&&strcmpi(St.parentSHA256,parentHash)&&isequal(St.crackPolyline_mm,Rev.polyline_mm)&& ...
  St.KI_perkN==Rev.sif.KI_perkN&&St.KII_perkN==Rev.sif.KII_perkN&&strcmp(St.material,mat.id),'G2M3:StateMismatch','Step %d state does not match its review.',k);
 Out=St;outHash=stHash;
else
 Out=Rev;outHash=revHash;
end
end

function local_save_mesh(meshFile,B,P,t)
assert(~isfile(meshFile),'G2M3:MeshExists','Refusing to overwrite a mesh.');
X3=B.X3;T3=B.T3;X6=B.X6;T6=B.T6;upperBankT6=B.upperBankT6;lowerBankT6=B.lowerBankT6; %#ok<NASGU>
physicalTipNode=B.physicalTipNode;nodalQ=B.nodalQ;qActiveT6Rows=B.qActiveT6Rows;elementRows=B.elementRows; %#ok<NASGU>
collarOuterIDs=B.collarOuterIDs;extraVertexXY=B.extraVertexXY;extraVertexNodes=B.extraVertexNodes;crackPolyline=P; %#ok<NASGU>
tipTangent=t;tipNormal=[-t(2),t(1)];kinkNodeIDs=B.kinkNodeIDs;geometryOnly=true;approvedForLEFM=false; %#ok<NASGU>
plateXRange=B.plateXRange;includeHoles=true;mirrorControl=false; %#ok<NASGU>
save(meshFile,'X3','T3','X6','T6','upperBankT6','lowerBankT6','physicalTipNode','nodalQ','qActiveT6Rows','elementRows', ...
 'collarOuterIDs','extraVertexXY','extraVertexNodes','crackPolyline','tipTangent','tipNormal','kinkNodeIDs', ...
 'geometryOnly','approvedForLEFM','plateXRange','includeHoles','mirrorControl','-v7.3');
end

function local_hold(stepDir,k,id,msg)
if ~isfolder(stepDir),mkdir(stepDir);end
f=fullfile(stepDir,'HOLD.mat');
if ~isfile(f)
 g2_trajectory_record('write',f,struct('schema','NewMetacomp.G2.M3.Hold.v1','stateIndex',k,'identifier',id,'message',msg,'created',datestr(now,31)));
end
end

function rec=local_m2_record(repo,b,key)
f=fullfile(repo,b.m2Run,['CASE_',key,'.mat']);
h=g2_sha256_file(f);
assert(strcmpi(h,b.m2CaseSHA256.(key)),'G2M3:M2RecordHash','PR #38 record %s hash %s.',key,h);
txt=fileread(fullfile(repo,b.m2Ledger));
assert(contains(lower(txt),lower([b.m2CaseSHA256.(key),' *g2_material_evolution_v1/run_20261121_132226_301/CASE_',key,'.mat'])),'G2M3:M2Ledger','%s not in the M2 ledger.',key);
[rec,~,ok]=g2_trajectory_record('read',f);assert(ok,'G2M3:M2Record','PR #38 record %s integrity.',key);
end

function H=local_hrec(repo,b,pol,json)
% read-only control: the recurrence on the homogeneous records must reproduce S1 and S2
J=jsondecode(fileread(json));G=J.nominal_geometry_mm;
r0=local_m2_record(repo,b,'S0_H1');r1=local_m2_record(repo,b,'S1_H1');
% Amendment A1: WP3 seeded the homogeneous S1 from the PREREGISTERED SIX-DIGIT State 0 K
% (WP3_PREREGISTRATION.md A9: 0.166436 / +0.018827), not from the full-precision record.
S0six=struct('crackPolyline_mm',pol.start.polyline_mm,'tip_mm',pol.start.polyline_mm(end,:),'t',reshape(pol.start.tangent,1,2),'KI_perkN',.166436,'KII_perkN',.018827);
F1=local_forecast(S0six,G,pol);
S0full=S0six;S0full.KI_perkN=r0.KI_perkN;S0full.KII_perkN=r0.KII_perkN;
F1full=local_forecast(S0full,G,pol);
m1=load(fullfile(repo,'outputs','g2_wp3_state','run_20261118_185808_963','step1_a','KINKED_GEOMETRY_ONLY_candidate.mat'),'crackPolyline','tipTangent');
m2=load(fullfile(repo,'outputs','g2_trajectory_chain_v1_attempt2','STEP_002','KINKED_GEOMETRY_ONLY_candidate.mat'),'crackPolyline','tipTangent');
S1=struct('crackPolyline_mm',m1.crackPolyline,'tip_mm',m1.crackPolyline(end,:),'t',m1.tipTangent(:).','KI_perkN',r1.KI_perkN,'KII_perkN',r1.KII_perkN);
F2=local_forecast(S1,G,pol);
hp=pol.base.homogeneousPolylines_mm;
H=struct('S1_vsSaved_max_mm',max(abs(F1.polyline_mm-m1.crackPolyline),[],'all'),'S1_vsPreregistered_max_mm',max(abs(F1.polyline_mm-hp.S1),[],'all'), ...
 'S2_vsSaved_max_mm',max(abs(F2.polyline_mm-m2.crackPolyline),[],'all'),'S2_vsPreregistered_max_mm',max(abs(F2.polyline_mm-hp.S2),[],'all'), ...
 'S1_turn_deg',F1.localTurn_deg,'S2_turn_deg',F2.localTurn_deg, ...
 'S1_fullPrecisionTipOffset_mm',norm(F1full.tip_mm-m1.crackPolyline(end,:)),'S1_fullPrecisionTurn_deg',F1full.localTurn_deg);
H.pass=H.S1_vsSaved_max_mm<=1e-12&&H.S2_vsSaved_max_mm<=1e-12&&H.S1_vsPreregistered_max_mm<=1e-9&&H.S2_vsPreregistered_max_mm<=1e-9;
fprintf('G2_M3_HREC S1(six-digit K) dev saved %.3g / prereg %.3g mm; S2(full-precision S1 K) dev saved %.3g / prereg %.3g mm; S1 full-precision offset %.3g mm -> pass=%d\n', ...
 H.S1_vsSaved_max_mm,H.S1_vsPreregistered_max_mm,H.S2_vsSaved_max_mm,H.S2_vsPreregistered_max_mm,H.S1_fullPrecisionTipOffset_mm,H.pass);
end

function S0=local_s0_recompute(repo,b,s0Mesh,rec,mat,polM,polT,pol)
D=load(s0Mesh);[Dm,Ad]=g2_m2_state_adapter(D,'S0',pol.start.polyline_mm);assert(Ad.pass,'G2M3:S0Adapter','S0 adapter.');
[PM,V,NC]=g2_material_phase_stage(Dm,polM,pol.start.polyline_mm);assert(PM.pass&&V.pass&&NC.pass,'G2M3:S0Phase','S0 phase stage.');
Em=pol.model.E_matrix_MPa;mk=@(E)struct('E',E,'nu',pol.model.nu_matrix,'plane',pol.model.plane);
K=g2_material_sif_on_mesh(Dm,PM.phase,[mk(Em),mk(mat.ratio*Em)],polT,PM);
S0=struct('pass',K.pass,'bitwise',K.pass&&isequal(K.u,rec.u)&&isequal(K.EDI_all,rec.EDI_all)&&isequal(K.EDI4x4,rec.EDI4x4)&& ...
 isequal([K.KI_COD,K.KII_COD],[rec.KI_COD_raw,rec.KII_COD_raw]),'KI_perkN',K.KI_MPa_sqrt_m_per_kN,'KII_perkN',K.KII_MPa_sqrt_m_per_kN);
fprintf('G2_M3_S0_RECOMPUTE %s pass=%d bitwise=%d\n',mat.id,S0.pass,S0.bitwise);
end

function H=local_sources(here)
names={'g2_m3_trajectory_run.m','g2_material_phase_stage.m','g2_material_phase_map.m','g2_material_phase_verify.m', ...
 'check_g2_material_phase_controls.m','check_g2_m2_phase_controls.m','g2_m2_state_adapter.m','g2_material_case_summary.m', ...
 'g2_t6_elasticity_phase.m','g2_material_sif_on_mesh.m','g2_t6_point_stress.m','g2_trajectory_record.m','g2_kink_admissibility.m', ...
 'g2_kinked_join.m','g2_kinked_exterior_mesh.m','g2_kinked_regular_block.m','g2_kinked_mesh_auditor.m','g2_mts_direction.m', ...
 'g2_polyline_frame.m','g2_sif_interaction.m','g2_sif_cod_banks.m','g2_williams_field.m','g2_plane_D.m','g2_sha256_file.m', ...
 'g2_independent_t6_jacobian.m','g2_pde_toolbox_preflight.m','G2_M3_TRAJECTORY_POLICY_v1.json','G2_MATERIAL_POLICY_v1.json', ...
 'G2_TRAJECTORY_POLICY_v1.json','G2_M2_POLICY_v1.json'};
vn={'build_m1i_trial_tip_annulus_p010.m','build_m1i_trial_tip_disk_p010.m','build_twohole_literal_annulus.m', ...
 'cut_twohole_literal_annulus.m','T3toT6_fast.m','main_m1i_increment_ring_geometry_only.m'};
all=[names,strcat('vendor_p010_a14d8872/',vn)];
H=repmat(struct('file','','sha256',''),numel(all),1);
for j=1:numel(all)
 f=fullfile(here,strrep(all{j},'/',filesep));assert(isfile(f),'G2M3:MissingSource','Missing source %s.',all{j});
 H(j).file=all{j};H(j).sha256=g2_sha256_file(f);
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
