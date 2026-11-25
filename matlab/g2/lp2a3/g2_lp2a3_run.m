function O=g2_lp2a3_run(varargin)
%G2_LP2A3_RUN  LP2-A3 restricted continuation of one accepted LP2-A1 S8 path, S9 to at most S11.
%
%  O = g2_lp2a3_run('Case','H')                         dry: parent + S9 candidate + guards; no mesh, no write
%  O = g2_lp2a3_run('Case','H','Mesh',true)             dry + default-rung mesh and all pre-FEM audits; no write, no solve
%  O = g2_lp2a3_run('Case','H','Run',true,'AuthToken',tok)   needs GO_LP2A3_PHYSICAL (never at preparation)
% Parent: the ORIGINAL accepted LP2-A1 S8 STATE (g2_lp2a3_parent; pins, links, bitwise TERMINAL
% candidate). Authorized path: normal preflight -> GO file -> g2_lp2a3_go_validate (token, campaign,
% caps, evidence, git activation binding) -> g2_lp1_campaign_validate -> receipt/RUN -> read-only
% verification of the existing prefix (g2_lp2a3_verify) -> g2_lp2a3_chain with the unchanged
% operations (g2_lp2_forecast, g2_lp0_clearance, g2_lp2a3_classify = g2_lp2_classify + 1-mm guard,
% g2_lp1_admit_state + memory gate + g2_lp2a3_admit_hook, g2_lp2a3_mesh (0.45 mm only),
% g2_lp1_audit, g2_lp2a2_pairing_audit, g2_m4b_ring_activation, g2_m4b_sif_partial, g2_mts_direction).
ip=inputParser;addParameter(ip,'Case','H',@ischar);addParameter(ip,'Run',false,@islogical);addParameter(ip,'Mesh',false,@islogical);
addParameter(ip,'AuthToken','',@(s)ischar(s)||isstring(s));addParameter(ip,'Preflight',true,@islogical);parse(ip,varargin{:});o=ip.Results;
if o.Run&&~o.Preflight,error('G2LP2A3:HOLD_PREFLIGHT_REQUIRED','A physical call requires the normal preflight.');end
C=g2_lp2a3_context('Preflight',o.Preflight);pol=C.policy;ids={pol.cases.id};ix=find(strcmp(ids,o.Case));
assert(isscalar(ix),'G2LP2A3:HOLD_INPUT','Exactly H, stiff13, soft2, soft1 permitted.');c=pol.cases(ix);mask=reshape(c.mask,1,3);
if o.Run
 G=gate(C,char(o.AuthToken));   % authorization BEFORE anything else (no folder, no mesh, no solve)
end
Par=g2_lp2a3_parent(C,c.id);
if ~o.Run
 O=dry(C,c,mask,Par,o.Mesh);return
end
% ------------------------------------------------------------------ authorized path only
rd=C.runRoot;chain=fullfile(rd,c.id);lroot=C.ledgerRoot;
Camp=g2_lp1_campaign_validate(struct('approvedRunName',G.approvedRunName,'campaignId',G.campaignId,'campaignScope',G.campaignScope), ...
 pol.authorization.runName,G.goFileSHA256,C.token,g2_lp1_campaign_ledger('snapshot',lroot),runFolderFacts(rd,C.token),[]);
masks=reshape([pol.cases.mask],3,[]).';
V=struct('rd',rd,'lroot',lroot,'ids',{ids},'masks',masks,'parents',struct(),'pol',pol,'token',C.token,'policySHA256',C.policySHA256, ...
 'g2SourceSHA256',C.g2SourceSHA256,'lp2a2SourceSHA256',C.lp2a2SourceSHA256,'lp2a3SourceSHA256',C.lp2a3SourceSHA256);
for i=1:numel(ids),Pi=g2_lp2a3_parent(C,ids{i});V.parents.(ids{i})=struct('state',Pi.state,'stateSHA256',Pi.stateSHA256);end
if strcmp(Camp.mode,'VERIFY_ONLY')
 Vall=V;Vall.requireTerminal=true;Rv=g2_lp2a3_verify(Vall);
 assert(Rv.pass,'G2LP2A3:HOLD_RECORD_INTEGRITY','Verification failed: %s',strjoin(Rv.problems,'; '));
 [Tm,~,~]=g2_trajectory_record('read',fullfile(chain,'TERMINAL.mat'));
 O=struct('status',['VERIFIED_' Tm.classification],'computed',0,'caseId',c.id,'terminal',Tm.classification,'lastState',Tm.lastAcceptedState,'campaignMode',Camp.mode,'verification',Rv);
 return
end
if strcmp(Camp.mode,'OPEN_NEW')
 g2_lp1_campaign_ledger('write',lroot,'RECEIPT','RECEIPT.mat',struct('campaignId',G.campaignId,'runName',pol.authorization.runName, ...
  'goSHA256',G.goFileSHA256,'token',C.token,'sourceCommit',C.preflight.sourceCommit,'openedUTC',utcNow()));
end
if ~isfolder(rd),mkdir(rd);end
rf=fullfile(rd,'RUN.mat');
if isfile(rf),[rr,~,ok]=g2_trajectory_record('read',rf);assert(ok&&strcmp(rr.token,C.token),'G2LP2A3:HOLD_SOURCE','Run token drift.');
else
 assert(numel(dir(rd))<=2,'G2LP2A3:HOLD_RECORD_INTEGRITY','Nonempty run without RUN record.');
 g2_trajectory_record('write',rf,struct('schema','NewMetacomp.G2.LP2A3.Run.v1','token',C.token,'sourceCommit',C.preflight.sourceCommit,'lp2a3SourceLines',{C.lp2a3SourceLines}));
end
if ~isfolder(chain),mkdir(chain);end
Vc=V;Vc.cases={c.id};Rv=g2_lp2a3_verify(Vc);   % existing prefix of THIS case: verify, never recompute
if ~Rv.pass
 g2_lp1_campaign_ledger('write',lroot,'HOLD',sprintf('HOLD_GLOBAL_%s_VERIFY_%s.mat',c.id,datestr(now,'yyyymmddTHHMMSSFFF')), ...
  struct('campaignId',G.campaignId,'caseId',c.id,'stateIndex',-1,'hold',struct('identifier','G2LP2A3:HOLD_RECORD_INTEGRITY','problems',{Rv.problems})));
 error('G2LP2A3:HOLD_RECORD_INTEGRITY','Existing chain fails verification: %s',strjoin(Rv.problems,'; '));
end
addpath(fullfile(C.here,'vendor_p010_a14d8872'),'-begin');
W=workspace(C,c,mask,G);
env=struct('caseId',c.id,'mask',mask,'ids',{ids},'rd',rd,'chain',chain,'lroot',lroot,'campMode',Camp.mode,'campaignId',G.campaignId, ...
 'runName',pol.authorization.runName,'token',C.token,'pol',pol,'parent',Par.state,'parentHash',Par.stateSHA256,'geom',Par.geom, ...
 'verifyAll',@()g2_lp2a3_verify(setfield(V,'requireTerminal',true))); %#ok<SFLD>
ops=struct('forecast',@g2_lp2_forecast,'clearance',@g2_lp0_clearance,'classify',@g2_lp2a3_classify, ...
 'admit',@(sd,k)admit(sd,k,lroot,Camp,G.campaignId,c.id,pol), ...
 'computeState',@(sd,k,F,parent,ph)computeState(sd,k,F,parent,ph,W));
O=g2_lp2a3_chain(env,ops);O.campaignMode=Camp.mode;O.campaignId=G.campaignId;O.token=C.token;
end

% =====================================================================
function G=gate(C,tok)
assert(isfile(C.goFile),'G2LP2A3:HOLD_UNAUTHORIZED','No GO_LP2A3_PHYSICAL record (%s): the campaign is prepared, not authorized.',C.policy.authorization.goPath);
fid=fopen(C.goFile,'r');raw=fread(fid,inf,'*uint8');fclose(fid);
md=java.security.MessageDigest.getInstance('SHA-256');md.update(raw);goSHA=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
try,Gd=jsondecode(native2unicode(raw.','UTF-8'));catch,Gd=[];end
G=g2_lp2a3_go_validate(Gd,C,tok);
assert(G.pass,'G2LP2A3:HOLD_UNAUTHORIZED','GO record rejected: %s',strjoin(G.failed,', '));
G.goFileSHA256=goSHA;G.approvedHead=Gd.approvedHead;
end

function admit(sd,k,lroot,Camp,cid,caseId,pol)
% 7-GiB physical-memory gate BEFORE the state folder exists (failure: pre-admission memory HOLD,
% global), then the unchanged g2_lp1_admit_state (5-GiB guard, partial-state refusal) with the
% LP2-A3 hook (closed campaign, S9-S11, 12 total, 3 per case, repeated / out-of-order key).
Mg=g2_lp2a2_eq_memgate(pol.resources.freeRAMInsideMATLAB_GiB_min);
assert(Mg.pass,'G2LP1:HOLD_MEMORY','Pre-admission memory gate: %s',Mg.reason);
g2_lp1_admit_state(sd,freeRAM(),@()g2_lp2a3_admit_hook(lroot,Camp,cid,caseId,k,pol));
end

function W=workspace(C,c,mask,G)
W=struct('C',C,'c',c,'mask',mask,'G',G,'polT',jsondecode(fileread(fullfile(C.here,'G2_TRAJECTORY_POLICY_v1.json'))), ...
 'Gn',getfield(jsondecode(fileread(fullfile(C.repo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json'))),'nominal_geometry_mm'), ...
 'Caud',struct('repo',C.repo,'here',C.here,'policy',C.lp2Policy)); %#ok<GFLD>
end

function [D,A,PM,PA,Ra,Ta,act]=preFEM(P,t,k,W)
% Default-rung mesh and every pre-FEM audit of one candidate (shared by dry and authorized paths).
pol=W.C.policy;op=pol.meshFamily.ExteriorOptions;
xo={'BottomVertices_mm',op.BottomVertices_mm(:).','TopVertices_mm',op.TopVertices_mm,'TipGuideRadius_mm',op.TipGuideRadius_mm,'TipGuideHface_mm',op.TipGuideHface_mm};
D=g2_lp2a3_mesh(P,'ExpectedVertices',k+2,'ExpectedTangent',t,'ExteriorOptions',xo,'MaxT3Elements',op.MaxT3Elements);
A=[];PM=[];PA=[];Ra=[];Ta=[];act=[];
if ~D.pass,return,end
PA=D.pairingAudit;D=rmfield(D,intersect(fieldnames(D),{'ladder','pairingAudit'}));D.tipTangent=t;
[A,PM]=g2_lp1_audit(D,k,W.Caud);
Ra=g2_lp0_clearance(P(1:end-1,:),P(end,:),A.clearanceGeometry,pol);Ta=g2_lp2a3_classify(Ra,W.mask,pol,P(end,:));
act=g2_m4b_ring_activation(PM.annulusOf,W.mask);
end

function [St,sth,geomNew]=computeState(sd,k,F,parent,parentHash,W)
% One admitted state: default-rung mesh, inherited audits, pairing, actual clearance, activation,
% memory gate, unchanged solve, MTS and immutable records.
C=W.C;c=W.c;pol=C.policy;mask=W.mask;P=F.polyline_mm;t=F.tangent;
[D,A,PM,PA,Ra,Ta,act]=preFEM(P,t,k,W);
if ~D.pass
 failedMesh=D;save(fullfile(sd,'FAILED_MESH.mat'),'failedMesh','-v7.3');
 error('G2LP2A3:HOLD_MESH_QUALITY','Default rung (0.45 mm) failed: %s %s',D.stage,D.message);
end
assert(PA.pass,'G2LP2A3:HOLD_PAIRING','Pairing audit: %s',strjoin(PA.failedGates,','));
assert(Ra.pass&&strcmp(Ta.classification,'MATRIX_ADVANCE'),'G2LP2A3:HOLD_INTERFACE_APPROACH','Actual-polygon clearance / guard failed: %s',Ta.classification);
geomNew=A.clearanceGeometry;
mf=fullfile(sd,'MESH.mat');save(mf,'-struct','D','-v7.3');mh=lower(g2_sha256_file(mf));D=load(mf);
Ph=struct('schema','NewMetacomp.G2.LP2A3.Phase.v1','stateIndex',k,'caseId',c.id,'mask',mask,'meshSHA256',mh, ...
 'owner',PM.annulusOf,'labels',act.phaseForAssembly,'audit',A,'pairingAudit',PA);
ph=lower(g2_trajectory_record('write',fullfile(sd,'PHASE.mat'),Ph));
Mg=g2_lp2a2_eq_memgate(pol.resources.freeRAMInsideMATLAB_GiB_min);
assert(Mg.pass,'G2LP1:HOLD_MEMORY','Pre-solve memory gate: %s',Mg.reason);
assert(freeRAM()>=5,'G2LP1:HOLD_MEMORY','Less than 5 GiB free physical RAM; no automatic retry.');
Em=pol.bvp.E_MPa;mk=@(E)struct('E',E,'nu',pol.bvp.nu,'plane','stress');
expect=struct('P_N',1,'thickness_mm',12.7,'load_mm',[254 203.2],'E_matrix',Em);t0=tic;
K=g2_m4b_sif_partial(D,act,[mk(Em),mk(Em*c.ratio)],W.polT,PM,expect);secs=toc(t0);
S=struct('schema','NewMetacomp.G2.LP2A3.Solution.v1','stateIndex',k,'caseId',c.id,'meshSHA256',mh,'phaseSHA256',ph, ...
 'policySHA256',C.policySHA256,'g2SourceSHA256',C.g2SourceSHA256,'lp2a2SourceSHA256',C.lp2a2SourceSHA256,'lp2a3SourceSHA256',C.lp2a3SourceSHA256, ...
 'token',C.token,'K',K,'memoryGate',Mg,'approvedHead',W.G.approvedHead);
sh=lower(g2_trajectory_record('write',fullfile(sd,'SOLUTION.mat'),S));
assert(K.pass,'G2LP2A3:HOLD_K_EXTRACTION','Failed SIF gates: %s',strjoin(K.failedCriteria,','));
M=g2_mts_direction(K.KI,K.KII);assert(K.KI>0&&M.admissibleForStep&&strcmp(M.status,'OK')&&M.stationarityResidual_rel<=1e-12,'G2LP2A3:HOLD_K_EXTRACTION','MTS root.');
Ka=g2_kink_admissibility(P,W.Gn,'DeltaA_mm',4,'ExpectedVertices',k+2,'ExpectedTangent',t,'TipGuideRadius_mm',15);
Kr=hypot(K.KI,K.KII);ed=K.EDI_all;tip=P(end,:);cen=pol.geometry.centres_mm;
St=struct('schema','NewMetacomp.G2.LP2A3.State.v1','stateIndex',k,'caseId',c.id,'mask',mask,'ratio',c.ratio, ...
 'policySHA256',C.policySHA256,'g2SourceSHA256',C.g2SourceSHA256,'lp2a2SourceSHA256',C.lp2a2SourceSHA256,'lp2a3SourceSHA256',C.lp2a3SourceSHA256,'token',C.token, ...
 'parentSHA256',parentHash,'sourceCommit',C.preflight.sourceCommit,'polyline_mm',P,'tangent',t,'normal',[-t(2),t(1)], ...
 'tip_mm',tip,'arc_mm',F.arc_mm,'heading_deg',F.heading_deg,'parentMTS_deg',F.parentMTS_deg, ...
 'KI',K.KI,'KII',K.KII,'KIIoverKI',K.KII/K.KI,'J',K.J,'G',Kr^2/Em,'MTS_deg',M.theta_deg,'EDI_all',ed, ...
 'KI_COD',K.KI_COD,'KII_COD',K.KII_COD,'CODminusEDI_rel',max(abs([K.KI_COD-K.KI,K.KII_COD-K.KII]))/Kr, ...
 'pathSpread_rel',max(max(ed(:,1:2))-min(ed(:,1:2)))/Kr,'quad4x4_rel',max(abs(K.EDI4x4-[K.KI,K.KII]))/Kr,'JoverGminus1',K.J/(Kr^2/Em)-1, ...
 'tipToRingCircle_mm',vecnorm(cen-tip,2,2).'-pol.geometry.ringR_mm,'tipToHoleCircle_mm',vecnorm(cen-tip,2,2).'-pol.geometry.holeR_mm, ...
 'guideRingGap_mm',Ta.ringProximity.gap_mm,'clearance',Ra.metrics,'classification',Ta.classification,'kinkSummary',Ka.summary,'kinkGatesPass',Ka.pass, ...
 'phaseCounts',K.phaseCounts,'activeArea_mm2',K.activeArea_mm2,'ringStrainEnergy',K.ringStrainEnergy_per_thickness, ...
 'compliance_mm_per_N',K.compliance_mm_per_N,'meshSHA256',mh,'phaseSHA256',ph,'solutionSHA256',sh,'T3',size(D.T3,1), ...
 'seedRung',1,'seedSpacing_mm',0.45,'pairingGates',PA.gatesPassed,'meshAuditGates',A.meshAudit.gatesPassed, ...
 'solveSeconds',secs,'clearanceGeometry',geomNew,'numericalStatus','ACCEPTED','physicalFractureGrowthProven',false);
sth=lower(g2_trajectory_record('write',fullfile(sd,'STATE.mat'),St));
fprintf('G2_LP2A3_ACCEPTED %s S%d s=%.4f KI=%.9g KII=%+.9g MTS=%+.5f tip=(%.4f,%.4f)\n',c.id,k,St.arc_mm,St.KI,St.KII,St.MTS_deg,tip);
end

function O=dry(C,c,mask,Par,doMesh)
% Geometry-only qualification of the S9 candidate: no write, no solve.
pol=C.policy;F=Par.S9forecast;P=F.polyline_mm;
R=g2_lp0_clearance(P(1:end-1,:),P(end,:),Par.geom,pol);T=g2_lp2a3_classify(R,mask,pol,P(end,:));
cen=pol.geometry.centres_mm;tip=P(end,:);
O=struct('status','DRY_READY_NO_FEM','physicalSolves',0,'caseId',c.id,'mask',mask,'token',C.token,'parentStateSHA256',Par.stateSHA256, ...
 'parentKI',Par.state.KI,'parentKII',Par.state.KII,'parentTangent',Par.state.tangent,'parentTip_mm',Par.state.tip_mm, ...
 'terminalComparison',Par.terminalComparison,'S9',struct('polyline_mm',P,'tip_mm',tip,'tangent',F.tangent,'heading_deg',F.heading_deg, ...
 'arc_mm',F.arc_mm,'parentMTS_deg',F.parentMTS_deg,'classification',T.classification,'constraints',T.constraints,'clearance',R.metrics, ...
 'clearancePass',R.pass,'guard',T.ringProximity,'tipToRingCircle_mm',vecnorm(cen-tip,2,2).'-pol.geometry.ringR_mm),'mesh',[]);
if ~doMesh||~strcmp(T.classification,'MATRIX_ADVANCE'),return,end
addpath(fullfile(C.here,'vendor_p010_a14d8872'),'-begin');
W=workspace(C,c,mask,struct('approvedHead',''));
M=struct('pass',false,'stage','','message','','failedGates',{{}},'T3',NaN,'seedRung',1,'seedSpacing_mm',0.45);
try
 [D,A,PM,PA,Ra,Ta]=preFEM(P,F.tangent,9,W);
 M.stage=D.stage;M.message=D.message;M.failedGates=D.failedGates;
 if D.pass
  chords=arrayfun(@(q)size(q.chords,1),PM.interfaces);
  M=struct('pass',D.pass&&PA.pass&&A.pass&&PM.pass&&Ra.pass&&strcmp(Ta.classification,'MATRIX_ADVANCE')&&isequal(chords(:).',[76 76 76]), ...
   'stage',D.stage,'message',D.message,'failedGates',{D.failedGates},'T3',size(D.T3,1),'seedRung',1,'seedSpacing_mm',0.45, ...
   'meshAuditGates',sprintf('%d/%d',A.meshAudit.gatesPassed,A.meshAudit.gatesTotal),'phaseAuditPass',A.pass,'phaseMapPass',PM.pass, ...
   'pairing',sprintf('%d/10',PA.gatesPassed),'pairingPass',PA.pass,'bankPairsT6',PA.metrics.pairsT6,'chordsPerCircle',chords, ...
   'actualClearancePass',Ra.pass,'actualClassification',Ta.classification,'actualGuideRingGap_mm',Ta.ringProximity.gap_mm,'joinSummary',D.summary);
 end
catch ME
 M.stage='EXCEPTION';M.message=[ME.identifier ': ' ME.message];
end
O.mesh=M;
end

function F=runFolderFacts(rd,token)
F=struct('exists',isfolder(rd),'hasRunRecord',isfile(fullfile(rd,'RUN.mat')),'runTokenMatches',false);
if F.hasRunRecord,[r,~,ok]=g2_trajectory_record('read',fullfile(rd,'RUN.mat'));F.runTokenMatches=ok&&strcmp(r.token,token);end
end
function g=freeRAM()
[~,s]=memory;g=s.PhysicalMemory.Available/2^30;
end
function s=utcNow()
s=char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss.SSS''Z'''));
end
