function R=g2_trajectory_run(varargin)
%G2_TRAJECTORY_RUN  Policy-capped, restartable Cornell numerical trajectory.
%
% Source pattern: EdgeCrackHoleLEFM@a14d8872
%   verification/main_pencil_full_trajectory_run.m
%   src/trajectory/edge_pencil_numerical_checkpoint.m
% NEVER copy original 2-hole geometry, supports, K values or acceptance.
%
% Default dry preflight: reads seed State 1, external mesh, P0 patch, source
% hashes, policy, computes next MTS + K1-K10; NO file writes or new FEM.
% Run=true requires an explicit SHA-bound per-policy numerical authorization.
% The first frozen policy is MAX STATE INDEX 2 (one additional numerical step).
% Review MAT (hash-manifested) is committed BEFORE a numerical State. A child
% is never created on a HOLD. State files are not physical tip acceptance.
%
% A fresh MATLAB mesher/solver run is required to qualify step 2. No claims
% about tip-size convergence, actual fracture load or Cornell experiment.
here=fileparts(mfilename('fullpath'));
repo=fileparts(fileparts(here));
policyFile=fullfile(here,'G2_TRAJECTORY_POLICY_v1.json');
original=fullfile(repo,'docs','research', ...
 'crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json');
ip=inputParser;
addParameter(ip,'Run',false,@(x)islogical(x)&&isscalar(x));
addParameter(ip,'SeedStepDir','',@(x)ischar(x)||isstring(x));
addParameter(ip,'P0Mat','',@(x)ischar(x)||isstring(x));
addParameter(ip,'ChainDir',fullfile(repo,'outputs','g2_trajectory_chain_v1'), ...
 @(x)ischar(x)||isstring(x));
addParameter(ip,'MaxStateIndex',2,@(x)isnumeric(x)&&isscalar(x)&&isfinite(x)&&x==round(x));
addParameter(ip,'ForbidNewComputation',false,@(x)islogical(x)&&isscalar(x));
addParameter(ip,'AuthorizeNumericalMarch',struct(),@isstruct);
parse(ip,varargin{:});o=ip.Results;
R=struct('pass',false,'stage','HOLD_NOT_STARTED', ...
 'runRequested',o.Run,'physicalFractureGrowthProven',false, ...
 'experimentalAgreementProven',false,'candidateOnly',true, ...
 'newStatesCreated',0,'reviewsReused',0,'statesReused',0, ...
 'lastStateIndex',-1,'steps',struct([]),'forecast',struct(), ...
 'policySHA256','','stopReason','','message','','chainDir',char(o.ChainDir));
assert(isfile(policyFile)&&isfile(original),'G2Chain:MissingSource', ...
 'Pinned Cornell nominal geometry or frozen continuation policy is absent.');
policy=jsondecode(fileread(policyFile));
assert(strcmp(policy.schema,'NewMetacomp.G2.CornellTrajectoryPolicy.v1'), ...
 'G2Chain:PolicySchema','Incorrect policy schema.');
assert(o.MaxStateIndex>=2 && o.MaxStateIndex<=policy.scopeLimits.maxStateIndex, ...
 'G2Chain:StepCap','Requested steps exceed the immutable versioned policy.');
shaP=g2_sha256_file(policyFile);shaJ=g2_sha256_file(original);
assert(strcmpi(shaJ,policy.base.cornellJSON_SHA256), ...
 'G2Chain:SourceJSONChanged','Original Cornell source geometry hash changed.');
R.policySHA256=shaP;
source=local_source_hashes(here);
vendor=fullfile(here,'vendor_p010_a14d8872');
assert(strcmpi(which('main_m1i_increment_ring_geometry_only'), ...
 fullfile(vendor,'main_m1i_increment_ring_geometry_only.m'))&& ...
 strcmpi(which('T3toT6_fast'),fullfile(vendor,'T3toT6_fast.m')), ...
 'G2Chain:VendorShadowed','Use pinned six vendor functions, not startup paths.');
assert(isfolder(char(o.SeedStepDir))&&isfile(char(o.P0Mat)), ...
 'G2Chain:MissingSeed','Accepted WP3 step 1 and P0 MAT must exist.');
seed=char(o.SeedStepDir);
[S1,rootHash,ok,why]=g2_wp3_state_io('load',fullfile(seed,'state'));
assert(ok,'G2Chain:RootIntegrity','WP3 state 1 hash or schema HOLD: %s.',why);
assert(S1.stateIndex==1&&~S1.physical_onset&&S1.idealized_propagation_demo&& ...
 size(S1.crackPolyline_mm,1)==3&&S1.DeltaA_mm==policy.scopeLimits.increment_mm, ...
 'G2Chain:RootIdentity','Root must be the verified numerical WP3 state 1.');
assert(isfield(S1,'meshFile')&&isfield(S1,'meshSHA256'), ...
 'G2Chain:RootMesh','Missing qualified WP3 source mesh identity.');
rootMesh=fullfile(seed,S1.meshFile);
assert(isfile(rootMesh)&&strcmpi(g2_sha256_file(rootMesh),S1.meshSHA256), ...
 'G2Chain:RootMeshIntegrity','Saved WP3 mesh SHA-256 mismatch.');
assert(abs(S1.KI_MPa_sqrt_m_per_kN-.182585)<1e-4&& ...
       abs(S1.KII_MPa_sqrt_m_per_kN-.001514)<1e-4, ...
 'G2Chain:RootSIF','Root does not match the independently qualified first kink.');
p0Hash=g2_sha256_file(char(o.P0Mat));
assert(strcmpi(p0Hash,policy.base.trustedP0SHA256), ...
 'G2Chain:TrustedP0','P0 MAT differs from the independently audited 2443-q-parent source.');
roots=policy.base.allowedWP3State1;
trusted=false;
for j=1:numel(roots)
 trusted=trusted||(strcmpi(rootHash,roots(j).stateSHA256)&& ...
  strcmpi(S1.meshSHA256,roots(j).meshSHA256));
end
assert(trusted,'G2Chain:TrustedWP3Root', ...
 'WP3 source State/mesh hash pair is not in the committed verified evidence manifest.');
J=jsondecode(fileread(original));G=J.nominal_geometry_mm;
R.rootStateSHA256=rootHash;R.rootMeshSHA256=S1.meshSHA256;
R.P0MAT_SHA256=p0Hash;R.lastStateIndex=1;
% Dry preflight reads root and chain, but DOES NOT create even a directory.
P=S1.crackPolyline_mm;
M=g2_mts_direction(S1.KI_MPa_sqrt_m_per_kN, ...
 S1.KII_MPa_sqrt_m_per_kN);
R.forecast=local_forecast(S1,M,G);
if ~strcmp(M.status,'OK')||~R.forecast.admissibility.pass
 R.stage='HOLD_DIRECTION_OR_GEOMETRY';R.stopReason='GEOMETRY';
 R.message='The parent signed-MTS direction or geometric admissibility failed.';
 return
end
if ~o.Run
 R.pass=true;R.stage='DRY_PREFLIGHT_PASS';R.stopReason='PREFLIGHT_ONLY';
 fprintf('G2_TRAJECTORY_PREFLIGHT_PASS=1\n');
 fprintf('G2_TRAJECTORY_NEXT_TURN_DEG=%.12f, TRIAL_TIP_MM=(%.12f,%.12f)\n', ...
 M.theta_deg,R.forecast.tip_mm);
 fprintf('G2_TRAJECTORY_DRY_NO_MESH_NO_FEM_NO_FILES=1\n');
 return
end
A=o.AuthorizeNumericalMarch;
assert(isscalar(A)&&all(isfield(A,{'token','policySHA256','maxStateIndex'}))&& ...
 strcmp(char(A.token),'CORNELL_G2_BOUNDED_NUMERICAL_V1')&& ...
 strcmpi(char(A.policySHA256),shaP)&& ...
 o.MaxStateIndex<=A.maxStateIndex&&A.maxStateIndex<=policy.scopeLimits.maxStateIndex, ...
 'G2Chain:AuthorizationRequired', ...
 'A SHA-bound explicit numerical-march authorization for state 2 is required.');
assert(~o.ForbidNewComputation||isfolder(char(o.ChainDir)), ...
 'G2Chain:NewWorkForbidden','No established chain; no new computation allowed.');
chain=char(o.ChainDir);rootFile=fullfile(chain,'ROOT.mat');
if isfolder(chain)
 assert(isfile(rootFile)&&isfile([rootFile,'.manifest.json']), ...
  'G2Chain:PartialChain','A chain folder exists without its complete root manifest.');
 [Root,~,valid,why]=g2_trajectory_record('read',rootFile);
 assert(valid,'G2Chain:RootRecordIntegrity','Root manifest failed: %s.',why);
 assert(strcmpi(Root.rootHash,rootHash)&&strcmpi(Root.rootMeshHash,S1.meshSHA256)&& ...
   strcmpi(Root.policySHA256,shaP)&&strcmpi(Root.p0SHA256,p0Hash)&& ...
   isequal(Root.sourceHashes,source), ...
   'G2Chain:SourceDrift','Saved chain sources differ from current files.');
else
 mkdir(chain);
 Root=struct('schema','NewMetacomp.G2.TrajectoryRoot.v1','stateIndex',1, ...
  'rootHash',rootHash,'rootMeshHash',S1.meshSHA256, ...
  'p0SHA256',p0Hash,'policySHA256',shaP, ...
  'sourceHashes',source,'seedDirectory',seed, ...
  'numericalOnly',true,'physicalFractureGrowthProven',false);
 g2_trajectory_record('write',rootFile,Root);
end
% Reusable review -> numerical state controller. The INITIAL frozen policy
% permits only state 2, but the loop itself uses policy-controlled caps.
% Future campaigns must have a separately committed versioned policy and
% separately authorized chain, not a mutation of the existing V1 manifest.
parent=S1;parentHash=rootHash;
runLog=fullfile(chain,['RUN_',datestr(now,'yyyymmdd_HHMMSS_FFF'),'.log']);
assert(~isfile(runLog),'G2Chain:RunLogExists','Refusing to overwrite run log.');
diary(runLog);diaryCleanup=onCleanup(@()diary('off')); %#ok<NASGU>
for k=S1.stateIndex+1:o.MaxStateIndex
 M=g2_mts_direction(parent.KI_MPa_sqrt_m_per_kN, ...
                    parent.KII_MPa_sqrt_m_per_kN);
 F=local_forecast(parent,M,G);
 R.forecast=F;
 if ~strcmp(M.status,'OK')||~F.admissibility.pass
  R.pass=false;R.stage='HOLD_DIRECTION_OR_GEOMETRY';
  R.stopReason='GEOMETRY';R.message='Independent MTS/K1-K10 admission failed.';
  fprintf(2,'G2_TRAJECTORY_HOLD_DIRECTION_AT_STATE=%d\n',k);
  return
 end
 arc=sum(vecnorm(diff(F.polyline_mm,1,1),2,2));
 if arc>policy.scopeLimits.maxArcLength_mm+1e-9
  R.pass=true;R.stage='ARC_CAP';R.stopReason='ARC_CAP';
  fprintf('G2_TRAJECTORY_ARC_CAP=1 NEXT_ARC_MM=%.9f\n',arc);
  return
 end
 stepDir=fullfile(chain,sprintf('STEP_%03d',k));
 reviewFile=fullfile(stepDir,'REVIEW.mat');stateDir=fullfile(stepDir,'state');
 if isfolder(stateDir)
  [child,childHash,ok,why]=g2_wp3_state_io('load',stateDir);
  assert(ok,'G2Chain:ChildStateIntegrity','Saved child State: %s.',why);
  [review,reviewHash,v,why]=g2_trajectory_record('read',reviewFile);
  assert(v,'G2Chain:ChildReviewIntegrity','Saved review: %s.',why);
  local_verify_child(child,review,parent,parentHash,reviewHash,shaP,stepDir,source);
  assert(isequal(review.polyline_mm,F.polyline_mm), ...
   'G2Chain:ForecastDrift','Saved review path differs from current MTS forecast.');
  R.statesReused=R.statesReused+1;
  R.steps=[R.steps;local_step_summary(child,review,'REUSED_VERIFIED_STATE')]; %#ok<AGROW>
  fprintf('G2_TRAJECTORY_REUSED_STATE_%03d=1; NO_FEM_NO_REMESH=1\n',k);
  parent=child;parentHash=childHash;R.lastStateIndex=k;
  continue
 end
 if isfile(reviewFile)
  [review,reviewHash,v,why]=g2_trajectory_record('read',reviewFile);
  assert(v,'G2Chain:ReviewIntegrity','Saved interrupted review: %s.',why);
  local_verify_review(review,parent,parentHash,shaP,stepDir,source);
  assert(isequal(review.polyline_mm,F.polyline_mm), ...
   'G2Chain:ForecastDrift','Saved review no longer matches MTS recurrence.');
  child=local_child_state(parent,review,parentHash,reviewHash,shaP);
  childHash=g2_wp3_state_io('save',stateDir,child);
  R.reviewsReused=R.reviewsReused+1;
  R.steps=[R.steps;local_step_summary(child,review,'RESUMED_VERIFIED_REVIEW')]; %#ok<AGROW>
  fprintf('G2_TRAJECTORY_REUSED_REVIEW_%03d=1; NO_FEM_NO_REMESH=1\n',k);
  parent=child;parentHash=childHash;R.lastStateIndex=k;
  continue
 end
 if o.ForbidNewComputation
  R.stage='HOLD_NEW_COMPUTATION_FORBIDDEN';R.stopReason='POLICY';
  return
 end
 assert(~isfolder(stepDir),'G2Chain:PartialStep', ...
  'An unreviewed step directory already exists; preserve and investigate it.');
 mkdir(stepDir);
 try
  % No automatic Hgrad retries, rotation fallback or threshold relaxation.
  Pnew=F.polyline_mm;
  opts={'BottomVertices_mm',[25.4 482.6], ...
       'TopVertices_mm',254,'TipGuideRadius_mm',15, ...
       'TipGuideHface_mm',1.5};
  B=g2_kinked_join(Pnew,'ExteriorOptions',opts, ...
   'ExpectedVertices',size(Pnew,1),'MaxT3Elements', ...
   policy.numerics.primaryT3Budget,'ExpectedTangent',F.tangent);
  assert(B.pass,'G2Chain:MeshHOLD','%s %s',B.stage,B.message);
  X3=B.X3;T3=B.T3;X6=B.X6;T6=B.T6; %#ok<NASGU>
  upperBankT6=B.upperBankT6;lowerBankT6=B.lowerBankT6; %#ok<NASGU>
  physicalTipNode=B.physicalTipNode;nodalQ=B.nodalQ; %#ok<NASGU>
  qActiveT6Rows=B.qActiveT6Rows;elementRows=B.elementRows; %#ok<NASGU>
  collarOuterIDs=B.collarOuterIDs;extraVertexXY=B.extraVertexXY; %#ok<NASGU>
  extraVertexNodes=B.extraVertexNodes;crackPolyline=Pnew; %#ok<NASGU>
  tipTangent=F.tangent;tipNormal=[-tipTangent(2),tipTangent(1)]; %#ok<NASGU>
  kinkNodeIDs=B.kinkNodeIDs;geometryOnly=true;approvedForLEFM=false; %#ok<NASGU>
  plateXRange=B.plateXRange;includeHoles=true;mirrorControl=false; %#ok<NASGU>
  meshFile=fullfile(stepDir,'KINKED_GEOMETRY_ONLY_candidate.mat');
  save(meshFile,'X3','T3','X6','T6','upperBankT6','lowerBankT6', ...
   'physicalTipNode','nodalQ','qActiveT6Rows','elementRows', ...
   'collarOuterIDs','extraVertexXY','extraVertexNodes', ...
   'crackPolyline','tipTangent','tipNormal','kinkNodeIDs', ...
   'geometryOnly','approvedForLEFM','plateXRange', ...
   'includeHoles','mirrorControl','-v7.3');
  meshHash=g2_sha256_file(meshFile);
  D=load(meshFile);
  C=g2_kinked_mesh_auditor(D,original,char(o.P0Mat),size(Pnew,1));
  assert(C.pass&&C.gatesPassed==C.gatesTotal, ...
   'G2Chain:AuditHOLD','Independent multi-kink audit failed: %s', ...
   strjoin(C.failedGates,', '));
  mat=struct('E',parent.bvp.E_MPa,'nu',parent.bvp.nu, ...
   'plane',parent.bvp.plane);
  K=g2_trajectory_sif_on_mesh(D,mat,policy);
  assert(K.pass,'G2Chain:SIFHOLD', ...
    'Whole-crack opening/EDI/COD/SIF gates failed: %s', ...
    strjoin(K.failedCriteria,', '));
  assert(isequal(source,local_source_hashes(here)), ...
   'G2Chain:SourceChangedDuringRun','Numerical kernel changed during run.');
  review=struct('schema','NewMetacomp.G2.TrajectoryReview.v1', ...
   'stateIndex',k,'parentStateSHA256',parentHash, ...
   'policySHA256',shaP,'sourceHashes',source, ...
   'p0SHA256',p0Hash,'meshFile', ...
   'KINKED_GEOMETRY_ONLY_candidate.mat','meshSHA256',meshHash, ...
   'polyline_mm',Pnew,'tip_mm',F.tip_mm,'tangent',F.tangent, ...
   'localTurn_deg',M.theta_deg,'forecast',F, ...
   'geometryGateCount',C.gatesTotal,'geometryGatesPassed',C.gatesPassed, ...
   'geometryPass',C.pass,'geometrySummary',C.summary, ...
   'meshJoinPass',B.pass,'meshSummary',B.summary, ...
   'sif',K,'sifPass',K.pass, ...
   'numericallyQualified',true,'physicalFractureGrowthProven',false, ...
   'tipAccepted',false,'eligibleForAutomaticPhysicalAcceptance',false);
  reviewHash=g2_trajectory_record('write',reviewFile,review);
  child=local_child_state(parent,review,parentHash,reviewHash,shaP);
  childHash=g2_wp3_state_io('save',stateDir,child);
  R.newStatesCreated=R.newStatesCreated+1;
  R.steps=[R.steps;local_step_summary(child,review,'NEW_NUMERICAL_STATE')]; %#ok<AGROW>
  R.lastStateIndex=k;
  fprintf('G2_TRAJECTORY_STEP_%03d_NUMERICALLY_QUALIFIED=1\n',k);
  fprintf('G2_TRAJECTORY_KI=%.9f KII=%+.9f MPa sqrt(m)/kN\n', ...
   child.KI_MPa_sqrt_m_per_kN,child.KII_MPa_sqrt_m_per_kN);
  parent=child;parentHash=childHash;
 catch ME
  R.pass=false;R.stage='HOLD_NUMERICAL_STEP';
  R.stopReason=local_classify(ME.identifier);
  R.message=getReport(ME,'extended','hyperlinks','off');
  fprintf(2,'G2_TRAJECTORY_HOLD_STATE_%03d=%s: %s\n',k,R.stopReason,ME.message);
  H=struct('schema','NewMetacomp.G2.TrajectoryHold.v1', ...
   'stateIndex',k,'identifier',ME.identifier,'message',R.message, ...
   'reason',R.stopReason,'policySHA256',shaP, ...
   'parentSHA256',parentHash,'physicalFractureGrowthProven',false);
  g2_trajectory_record('write',fullfile(stepDir,'HOLD.mat'),H);
  return
 end
end
R.pass=true;R.stage='STEP_CAP';R.stopReason='STEP_CAP';
fprintf('G2_TRAJECTORY_STOP_STEP_CAP=%d; PHYSICAL_GROWTH_PROVEN=0\n',o.MaxStateIndex);
end

% ======================================================================
function F=local_forecast(S,M,G)
F=struct('status',M.status,'tip_mm',[], ...
 'tangent',[],'polyline_mm',[],'admissibility',struct());
if ~strcmp(M.status,'OK'),return,end
t=S.t(:).';n=[-t(2),t(1)];
tnew=cos(M.theta_rad)*t+sin(M.theta_rad)*n;
tip=S.tip_mm(:).'+S.DeltaA_mm*tnew;
P=[S.crackPolyline_mm;tip];
A=g2_kink_admissibility(P,G,'ExpectedVertices',size(P,1), ...
 'DeltaA_mm',S.DeltaA_mm,'ExpectedTangent',tnew);
F.tip_mm=tip;F.tangent=tnew;F.polyline_mm=P;
F.localTurn_deg=M.theta_deg;F.admissibility=A;
end

function S2=local_child_state(S1,Review,parentHash,reviewHash,policyHash)
S2=S1;S2.stateIndex=Review.stateIndex;
S2.parentStateSHA256=parentHash;S2.reviewSHA256=reviewHash;
S2.policySHA256=policyHash;S2.sourceHashes=Review.sourceHashes;
S2.crackPolyline_mm=Review.polyline_mm;S2.tip_mm=Review.tip_mm;
S2.t=Review.tangent;S2.n=[-Review.tangent(2),Review.tangent(1)];
S2.KI_MPa_sqrt_m_per_kN=Review.sif.KI_MPa_sqrt_m_per_kN;
S2.KII_MPa_sqrt_m_per_kN=Review.sif.KII_MPa_sqrt_m_per_kN;
S2.KI_raw=Review.sif.KI;S2.KII_raw=Review.sif.KII;
S2.KI_COD_MPa_sqrt_m_per_kN=Review.sif.KI_COD*sqrt(1000);
S2.KII_COD_MPa_sqrt_m_per_kN=Review.sif.KII_COD*sqrt(1000);
S2.sifCriteria=Review.sif.criteria;
S2.meshSHA256=Review.meshSHA256;S2.meshFile=Review.meshFile;
S2.auditGates=sprintf('%d/%d',Review.geometryGatesPassed,Review.geometryGateCount);
S2.idealized_propagation_demo=true;S2.physical_onset=false;
S2.numericallyQualified=true;S2.tipAccepted=false;
S2.physicalFractureGrowthProven=false;
S2.eligibleForAutomaticPhysicalAcceptance=false;
S2.appliedTheta_rad=deg2rad(Review.localTurn_deg);
S2.created=datestr(now,31);
S2.note='Policy-capped qualified NUMERICAL trajectory state, not physical propagation.';
end

function local_verify_review(Rev,Parent,parentHash,policyHash,stepDir,src)
assert(strcmp(Rev.schema,'NewMetacomp.G2.TrajectoryReview.v1')&& ...
 Rev.stateIndex==Parent.stateIndex+1&& ...
 strcmpi(Rev.parentStateSHA256,parentHash)&& ...
 strcmpi(Rev.policySHA256,policyHash)&&isequal(Rev.sourceHashes,src)&& ...
 Rev.geometryPass&&Rev.sifPass&& ...
 Rev.geometryGateCount==Rev.geometryGatesPassed&& ...
 ~Rev.physicalFractureGrowthProven, ...
 'G2Chain:ReviewMismatch','Review provenance, gates or numerical-only status mismatch.');
assert(isequal(Rev.polyline_mm(1:end-1,:),Parent.crackPolyline_mm)&& ...
 isequal(Rev.polyline_mm(end,:),Rev.tip_mm), ...
 'G2Chain:ReviewPath','Review path is not a one-segment continuation of the parent.');
assert(isfile(fullfile(stepDir,Rev.meshFile))&& ...
 strcmpi(g2_sha256_file(fullfile(stepDir,Rev.meshFile)),Rev.meshSHA256), ...
 'G2Chain:ReviewMeshSHA','Audited mesh bytes differ from review manifest.');
end

function local_verify_child(S,Rev,Parent,parentHash,reviewHash,policyHash,stepDir,src)
local_verify_review(Rev,Parent,parentHash,policyHash,stepDir,src);
assert(S.stateIndex==Rev.stateIndex&& ...
 strcmpi(S.parentStateSHA256,parentHash)&& ...
 strcmpi(S.reviewSHA256,reviewHash)&& ...
 strcmpi(S.policySHA256,policyHash)&& ...
 strcmpi(S.meshSHA256,Rev.meshSHA256)&& ...
 isequal(S.crackPolyline_mm,Rev.polyline_mm)&& ...
 S.KI_MPa_sqrt_m_per_kN==Rev.sif.KI_MPa_sqrt_m_per_kN&& ...
 S.KII_MPa_sqrt_m_per_kN==Rev.sif.KII_MPa_sqrt_m_per_kN&& ...
 ~S.physical_onset&&~S.physicalFractureGrowthProven, ...
 'G2Chain:ChildMismatch','Numerical child State no longer matches its review.');
end

function S=local_step_summary(State,Rev,label)
S=struct('stateIndex',State.stateIndex,'status',label, ...
 'tip_mm',State.tip_mm,'KI_MPa_sqrt_m_per_kN', ...
 State.KI_MPa_sqrt_m_per_kN,'KII_MPa_sqrt_m_per_kN', ...
 State.KII_MPa_sqrt_m_per_kN,'localTurn_deg',Rev.localTurn_deg, ...
 'meshT3Elements',Rev.meshSummary.T3elements, ...
 'independentGeometryGates',Rev.geometryGatesPassed, ...
 'physicalFractureGrowthProven',false);
end

function H=local_source_hashes(here)
names={'g2_trajectory_run.m','g2_trajectory_record.m', ...
 'g2_trajectory_sif_on_mesh.m','g2_kink_admissibility.m', ...
 'g2_kinked_join.m','g2_kinked_exterior_mesh.m', ...
 'g2_kinked_regular_block.m','g2_kinked_mesh_auditor.m', ...
 'g2_mts_direction.m','g2_polyline_frame.m', ...
 'g2_sif_interaction.m','g2_sif_cod_banks.m', ...
 'g2_t6_elasticity.m','g2_plane_D.m', ...
 'g2_independent_t6_jacobian.m','g2_wp3_state_io.m', ...
 'g2_sha256_file.m'};
H=repmat(struct('file','','sha256',''),numel(names)+6,1);
for j=1:numel(names)
 file=fullfile(here,names{j});assert(isfile(file), ...
 'G2Chain:MissingKernel','Missing mandatory kernel %s.',names{j});
 H(j).file=names{j};H(j).sha256=g2_sha256_file(file);
end
vn={'build_m1i_trial_tip_annulus_p010.m', ...
 'build_m1i_trial_tip_disk_p010.m','build_twohole_literal_annulus.m', ...
 'cut_twohole_literal_annulus.m','T3toT6_fast.m', ...
 'main_m1i_increment_ring_geometry_only.m'};
for j=1:numel(vn)
 file=fullfile(here,'vendor_p010_a14d8872',vn{j});
 assert(isfile(file),'G2Chain:MissingVendor','Missing pinned p010 source.');
 H(numel(names)+j).file=['vendor_p010_a14d8872/',vn{j}];
 H(numel(names)+j).sha256=g2_sha256_file(file);
end
end

function reason=local_classify(id)
reason='SOURCE';
if contains(id,'Mesh')||contains(id,'EXTERIOR')||contains(id,'CAD')
 reason='GEOMETRY';
elseif contains(id,'Audit')
 reason='TOPOLOGY';
elseif contains(id,'SIF')||contains(id,'COD')||contains(id,'EDI')
 reason='SIF_COMPARE';
elseif contains(id,'RAM')
 reason='RAM';
end
end
