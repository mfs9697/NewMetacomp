function T = g2_wp3_one_step(parentDir, outDir, p0MAT, varargin)
%G2_WP3_ONE_STEP  ONE deterministic idealized-demo crack step (WP3_PREREGISTRATION s.7).
%
%  T = g2_wp3_one_step(parentDir, outDir, p0MAT, 'Authorize','ONE_IDEALIZED_DEMO_STEP')
% Transaction: verify parent state (hash) -> MTS forecast (status OK) -> admissibility
% K1-K10 -> kinked family-A mesh -> save -> independent kink-aware audit of the SAVED
% MAT -> WP2 idealized BVP + EDI/COD with C1, C2, M2, M3, M4, QK -> write the child
% state in the NEW folder outDir. The parent folder is never written to.
% Fail-closed: anything else returns T.status = 'HOLD_*' and writes no state.
%  - no or wrong token                 -> HOLD_NOT_AUTHORIZED
%  - parent stateIndex ~= 0            -> HOLD_SECOND_STEP_NOT_AUTHORIZED (no multi-step campaign)
%  - parent hash/schema mismatch       -> HOLD_STATE_INTEGRITY
% Tags: idealized_propagation_demo = true, physical_onset = false. Millimetres.
ip=inputParser;addParameter(ip,'Authorize','',@(s)ischar(s)||isstring(s));parse(ip,varargin{:});o=ip.Results;
T=struct('status','HOLD_NOT_STARTED','outDir',outDir,'parentHash','','childHash','','detail',struct());
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
json=fullfile(repo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json');
if ~strcmp(char(o.Authorize),'ONE_IDEALIZED_DEMO_STEP'),T.status='HOLD_NOT_AUTHORIZED';return,end
[S0,h0,ok,why]=g2_wp3_state_io('load',parentDir);T.parentHash=h0;
if ~ok,T.status=why;return,end
if S0.stateIndex~=0,T.status='HOLD_SECOND_STEP_NOT_AUTHORIZED';return,end
before=dir_hashes(parentDir);
M=g2_mts_direction(S0.KI_MPa_sqrt_m_per_kN,S0.KII_MPa_sqrt_m_per_kN);T.detail.mts=M;
if ~strcmp(M.status,'OK'),T.status=['HOLD_MTS_',M.status];return,end
t0=S0.t(:).';n0=[-t0(2),t0(1)];t1=cos(M.theta_rad)*t0+sin(M.theta_rad)*n0;
P1=[S0.crackPolyline_mm;S0.tip_mm(:).'+S0.DeltaA_mm*t1];
J=jsondecode(fileread(json));
A=g2_kink_admissibility(P1,J.nominal_geometry_mm,'DeltaA_mm',S0.DeltaA_mm,'ExpectedTangent',t1);T.detail.admissibility=A.gates;
if ~A.pass,T.status='HOLD_GEOMETRY_ADMISSIBILITY';return,end
assert(~exist(outDir,'dir'),'G2Step:Exists','Refusing to overwrite %s',outDir);mkdir(outDir);
opts={'BottomVertices_mm',[25.4 482.6],'TopVertices_mm',254,'TipGuideRadius_mm',15,'TipGuideHface_mm',1.5};
R=g2_kinked_join(P1,'ExteriorOptions',opts,'MaxT3Elements',40000,'ExpectedTangent',t1);
T.detail.joinStage=R.stage;T.detail.joinGates=R.gates;
if ~R.pass,T.status='HOLD_MESH';return,end
X3=R.X3;T3=R.T3;X6=R.X6;T6=R.T6;upperBankT6=R.upperBankT6;lowerBankT6=R.lowerBankT6; %#ok<NASGU>
physicalTipNode=R.physicalTipNode;nodalQ=R.nodalQ;qActiveT6Rows=R.qActiveT6Rows;elementRows=R.elementRows; %#ok<NASGU>
collarOuterIDs=R.collarOuterIDs;extraVertexXY=R.extraVertexXY;extraVertexNodes=R.extraVertexNodes; %#ok<NASGU>
crackPolyline=P1;tipTangent=t1;tipNormal=[-t1(2),t1(1)];kinkNodeIDs=R.kinkNodeIDs;mirrorControl=false; %#ok<NASGU>
geometryOnly=true;approvedForLEFM=false;plateXRange=R.plateXRange;includeHoles=true; %#ok<NASGU>
meshMAT=fullfile(outDir,'KINKED_GEOMETRY_ONLY_candidate.mat');
save(meshMAT,'X3','T3','X6','T6','upperBankT6','lowerBankT6','physicalTipNode','nodalQ','qActiveT6Rows','elementRows', ...
 'collarOuterIDs','extraVertexXY','extraVertexNodes','crackPolyline','tipTangent','tipNormal','kinkNodeIDs','mirrorControl', ...
 'geometryOnly','approvedForLEFM','plateXRange','includeHoles','-v7.3');
meshHash=g2_sha256_file(meshMAT);
D=load(meshMAT);
C=g2_kinked_mesh_auditor(D,json,p0MAT);T.detail.auditGates=sprintf('%d/%d',C.gatesPassed,C.gatesTotal);
if ~C.pass,T.status='HOLD_INDEPENDENT_AUDIT';T.detail.auditFailed=C.failedGates;return,end
K=g2_wp3_sif_on_mesh(D,struct('E',S0.bvp.E_MPa,'nu',S0.bvp.nu,'plane',S0.bvp.plane));T.detail.sif=K;
if ~K.pass,T.status='HOLD_SIF_CRITERIA';return,end
S1=S0;S1.stateIndex=1;S1.parentStateSHA256=h0;S1.crackPolyline_mm=P1;S1.tip_mm=P1(end,:);S1.t=t1;S1.n=[-t1(2),t1(1)];
S1.KI_MPa_sqrt_m_per_kN=K.KI_MPa_sqrt_m_per_kN;S1.KII_MPa_sqrt_m_per_kN=K.KII_MPa_sqrt_m_per_kN;
S1.KI_COD_MPa_sqrt_m_per_kN=K.KI_COD*sqrt(1000);S1.KII_COD_MPa_sqrt_m_per_kN=K.KII_COD*sqrt(1000);
S1.KI_raw=K.KI;S1.KII_raw=K.KII;S1.sifCriteria=K.criteria;S1.appliedTheta_rad=M.theta_rad;
S1.meshFile='KINKED_GEOMETRY_ONLY_candidate.mat';S1.meshSHA256=meshHash;S1.auditGates=T.detail.auditGates;
S1.idealized_propagation_demo=true;S1.physical_onset=false;S1.created=datestr(now,31);
S1.note='ONE idealized numerical demo step (Issue #24); not a physical propagation event; no further step authorized';
T.childHash=g2_wp3_state_io('save',fullfile(outDir,'state'),S1);
after=dir_hashes(parentDir);
if ~isequal(before,after),T.status='HOLD_PARENT_MODIFIED';return,end
T.status='ACCEPTED_ONE_IDEALIZED_DEMO_STEP';T.detail.meshSHA256=meshHash;
end

function H=dir_hashes(d)
f=dir(fullfile(d,'**','*'));f=f(~[f.isdir]);H=cell(numel(f),2);
for k=1:numel(f),H{k,1}=fullfile(f(k).folder,f(k).name);H{k,2}=g2_sha256_file(H{k,1});end
H=sortrows(H,1);
end
