function O=g2_lp2b1s10_run(varargin)
%G2_LP2B1S10_RUN  Driver of the ONE prospective admission and solve of campaign G2-LP2B1-S10-001 (soft1 S10, 0.40 mm).
%  O = g2_lp2b1s10_run()                                   target qualification only (zero FEM, no write)
%  O = g2_lp2b1s10_run('Mesh',true,'ReplayRoot',dir)       + geometry-only 0.40 mm admission replay (writes under dir)
%  O = g2_lp2b1s10_run('Run',true,'Token',tok)             FUTURE authorized call only
% Physical call (Run=true), in this order, before any folder, mesh or solve: normal preflight (Preflight=false refuses:
% HOLD_PREFLIGHT_REQUIRED); the GO file accepted by g2_lp2b1s10_go_validate (HOLD_UNAUTHORIZED); run and receipt roots
% outside every historical root; no soft1 case folder (HOLD_ONE_ATTEMPT, no retry, no resumption); the campaign ledger
% RECEIPT bound to the token, written only by g2_lp2b1s10_external_run, and no ADMIT/HOLD yet (HOLD_NO_RECEIPT /
% HOLD_ONE_ATTEMPT); the target qualification (HOLD_TARGET); the 7 GiB memory gate (HOLD_MEMORY, before the folder).
% Then the admission (g2_lp1_admit_state: 5 GiB guard, ledger ADMIT_soft1_S10) and, in soft1/S10: geometry admission
% by the UNCHANGED g2_lp2b1eq_geometry with the stored FAILED_MESH as same-geometry baseline and the S9 clearance
% geometry as nominal geometry, plus the expected T3 / min angle / max ratio exactly (HOLD_MESH_QUALIFICATION before
% FEM); actual-polygon clearance and 1 mm guard (HOLD_INTERFACE_APPROACH); MESH, PHASE; 7 GiB and 5 GiB gates; the
% UNCHANGED g2_m4b_sif_partial with the original BVP; SOLUTION; 16 gates (HOLD_K_EXTRACTION); KI > 0 and admissible MTS
% root; kink admissibility recorded; STATE (all LP2-A3 fields, parent = ORIGINAL S9); TERMINAL with the S11 forecast
% for information only (no S11 mesh, admission or solve). Any error after soft1/S10 exists writes HOLD.json there
% and re-throws; partial records are preserved; nothing is retried.
% 'Test',T (zero-FEM tests only): T.root must be an existing folder under tempdir containing every root of T.context;
% T.ops may replace gate, head, target, geometry, memgate, freeRAM, solve, forecast. Otherwise refused.
ip=inputParser;addParameter(ip,'Run',false,@islogical);addParameter(ip,'Token','',@(x)ischar(x)||isstring(x));
addParameter(ip,'Preflight',true,@islogical);addParameter(ip,'Mesh',false,@islogical);addParameter(ip,'ReplayRoot','',@ischar);
addParameter(ip,'Test',[]);parse(ip,varargin{:});o=ip.Results;
if o.Run&&~o.Preflight,error('G2LP2B1S10:HOLD_PREFLIGHT_REQUIRED','A physical call requires the normal preflight; Preflight=false is for read-only replay and tests.');end
[C,ops]=setup(o);pol=C.policy;cd0=fullfile(C.runRoot,'soft1');sd=fullfile(cd0,'S10');
if o.Run
 G=ops.gate(C,char(o.Token));
 refuseHistorical(C,C.runRoot);refuseHistorical(C,C.receiptRoot);
 assert(~isfolder(cd0),'G2LP2B1S10:HOLD_ONE_ATTEMPT','soft1 already attempted in this campaign; no retry, no resumption.');
 L=g2_lp1_campaign_ledger('snapshot',C.receiptRoot);
 assert(isfolder(C.receiptRoot)&&L.integrityOK&&isstruct(L.receipt)&&isfield(L.receipt,'token')&&strcmp(L.receipt.token,C.token)&&strcmp(L.receipt.campaignId,pol.campaignId), ...
  'G2LP2B1S10:HOLD_NO_RECEIPT','No campaign receipt bound to this token: a physical call is possible only through g2_lp2b1s10_external_run.');
 assert(isempty(L.admits)&&isempty(L.holds)&&~L.closed,'G2LP2B1S10:HOLD_ONE_ATTEMPT','The campaign ledger already holds an admission or HOLD; no retry.');
 activationHead=ops.head();
end
Tq=ops.target(C);
assert(Tq.pass,'G2LP2B1S10:HOLD_TARGET','Target qualification fails: %s',strjoin(Tq.failed,', '));
P=Tq.forecast.polyline_mm;t=Tq.forecast.tangent;k=10;
O=struct('caseId','soft1','stateIndex',k,'token',C.token,'run',o.Run,'solveCalls',0,'admissions',0,'stage','TARGET_QUALIFIED','target',summTarget(Tq),'geometry',[]);
if ~o.Run
 if ~o.Mesh,return,end
 rr=o.ReplayRoot;assert(~isempty(rr),'G2LP2B1S10:HOLD_INPUT','ReplayRoot is required for a geometry replay.');
 refuseHistorical(C,rr);
 assert(~under(rr,C.runRoot)&&~under(rr,C.receiptRoot)&&~under(C.runRoot,rr)&&~under(C.receiptRoot,rr),'G2LP2B1S10:HOLD_INPUT','The replay root must be separate from the run and receipt roots.');
 od=fullfile(rr,'soft1_S10');assert(~isfolder(od),'G2LP2B1S10:HOLD_OVERWRITE','Replay folder exists: %s',od);mkdir(od);
 [Gq,Q]=admitGeometry(C,ops,Tq,P,t,k,od);O.geometry=summGeo(Gq,Q);O.stage='GEOMETRY_REPLAY_NO_SOLVE';
 wj(fullfile(od,'GEOMETRY_REPLAY.json'),O);return
end
% ------------------------------------------------------------------ authorized path (never executed at readiness)
Mg0=ops.memgate(pol.resources.freeRAMInsideMATLAB_GiB_min);
assert(Mg0.pass,'G2LP2B1S10:HOLD_MEMORY','Pre-admission memory gate: %s',Mg0.reason);
mkdir(cd0);
g2_lp1_admit_state(sd,ops.freeRAM(),@()admitHook(C));O.admissions=1;stage='GEOMETRY';
try
 [Gq,Q]=admitGeometry(C,ops,Tq,P,t,k,sd);O.geometry=summGeo(Gq,Q);
 assert(Gq.pass&&Q.pass,'G2LP2B1S10:HOLD_MESH_QUALIFICATION','soft1 S10: 0.40 mm admission failed before FEM: %s',strjoin([failedNames(Gq.checks),failedNames(Q.checks)],', '));
 stage='CLEARANCE';a3=C.a3.policy;
 Ra=g2_lp0_clearance(P(1:end-1,:),P(end,:),Gq.A.clearanceGeometry,a3);Ta=g2_lp2a3_classify(Ra,[1 0 0],a3,P(end,:));
 assert(Ra.pass&&strcmp(Ta.classification,'MATRIX_ADVANCE'),'G2LP2B1S10:HOLD_INTERFACE_APPROACH','Actual-polygon clearance / guard failed: %s',Ta.classification);
 stage='MESH';D=Gq.D;mf=fullfile(sd,'MESH.mat');save(mf,'-struct','D','-v7.3');mh=lower(g2_sha256_file(mf));D=load(mf);
 assert(strcmpi(g2_lp2b1eq_canon(D),pol.qualification.canonicalSHA256),'G2LP2B1S10:HOLD_MESH_QUALIFICATION','Reloaded MESH canonical digest differs from the pin.');
 stage='PHASE';
 Ph=struct('schema','NewMetacomp.G2.LP2B1S10.Phase.v1','stateIndex',k,'caseId','soft1','mask',[1 0 0],'meshSHA256',mh,'canonicalSHA256',Gq.canonicalSHA256, ...
  'owner',Gq.PM.annulusOf,'labels',Gq.act.phaseForAssembly,'chordsPerCircle',Gq.chordsPerCircle,'audit',Gq.A,'pairingAudit',Gq.PA,'token',C.token);
 ph=lower(g2_trajectory_record('write',fullfile(sd,'PHASE.mat'),Ph));
 stage='MEMORY';Mg=ops.memgate(pol.resources.freeRAMInsideMATLAB_GiB_min);
 assert(Mg.pass,'G2LP2B1S10:HOLD_MEMORY','Pre-solve memory gate: %s',Mg.reason);
 assert(ops.freeRAM()>=pol.resources.preflightGuard_GiB,'G2LP2B1S10:HOLD_MEMORY','Less than %g GiB free physical RAM; no retry.',pol.resources.preflightGuard_GiB);
 stage='SOLVE';polT=jsondecode(fileread(fullfile(C.here,'G2_TRAJECTORY_POLICY_v1.json')));Em=pol.bvp.E_MPa;mk=@(E)struct('E',E,'nu',pol.bvp.nu,'plane','stress');
 expect=struct('P_N',1,'thickness_mm',12.7,'load_mm',[254 203.2],'E_matrix',Em);   % literal values of LP2-A3, equal to the policy BVP
 assert(pol.bvp.P_N==expect.P_N&&pol.bvp.thickness_mm==expect.thickness_mm&&isequal(pol.bvp.load_mm(:).',expect.load_mm),'G2LP2B1S10:HOLD_SOURCE','BVP.');
 t0=tic;O.solveCalls=1;K=ops.solve(D,Gq.act,[mk(Em),mk(Em*pol.target.ratio)],polT,Gq.PM,expect);secs=toc(t0);
 stage='SOLUTION';
 S=struct('schema','NewMetacomp.G2.LP2B1S10.Solution.v1','stateIndex',k,'caseId','soft1','meshSHA256',mh,'phaseSHA256',ph,'canonicalSHA256',Gq.canonicalSHA256, ...
  'policySHA256',C.policySHA256,'g2SourceSHA256',C.g2SourceSHA256,'lp2b1s10SourceSHA256',C.lp2b1s10SourceSHA256,'token',C.token,'K',K,'solveSeconds',secs, ...
  'memoryGate',Mg,'approvedHead',G.approvedHead,'activationHead',activationHead,'goFileSHA256',G.goFileSHA256);
 sh=lower(g2_trajectory_record('write',fullfile(sd,'SOLUTION.mat'),S));
 stage='ACCEPTANCE';
 fc=fieldOr(K,'failedCriteria');if ~iscellstr(fc),fc={};end   % message arguments are evaluated even when the assertion passes
 assert(isstruct(K)&&isfield(K,'pass')&&isequal(K.pass,true),'G2LP2B1S10:HOLD_K_EXTRACTION','Failed SIF gates: %s',strjoin(fc,','));
 M=g2_mts_direction(K.KI,K.KII);
 assert(K.KI>0&&M.admissibleForStep&&strcmp(M.status,'OK')&&M.stationarityResidual_rel<=pol.tolerances.mtsStationarity_rel,'G2LP2B1S10:HOLD_K_EXTRACTION','MTS root.');
 Gn=getfield(jsondecode(fileread(fullfile(C.repo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json'))),'nominal_geometry_mm'); %#ok<GFLD>
 Ka=g2_kink_admissibility(P,Gn,'DeltaA_mm',4,'ExpectedVertices',k+2,'ExpectedTangent',t,'TipGuideRadius_mm',15);
 stage='STATE';F=Tq.forecast;Kr=hypot(K.KI,K.KII);ed=K.EDI_all;tip=P(end,:);cen=pol.geometry.centres_mm;geomNew=Gq.A.clearanceGeometry;
 St=struct('schema','NewMetacomp.G2.LP2B1S10.State.v1','stateIndex',k,'caseId','soft1','mask',[1 0 0],'ratio',pol.target.ratio, ...
  'policySHA256',C.policySHA256,'g2SourceSHA256',C.g2SourceSHA256,'lp2b1s10SourceSHA256',C.lp2b1s10SourceSHA256,'token',C.token, ...
  'parentSHA256',Tq.parentSHA256,'parentSchema',Tq.parent.schema,'sourceCommit',activationHead,'polyline_mm',P,'tangent',t,'normal',[-t(2),t(1)], ...
  'tip_mm',tip,'arc_mm',F.arc_mm,'heading_deg',F.heading_deg,'parentMTS_deg',F.parentMTS_deg, ...
  'KI',K.KI,'KII',K.KII,'KIIoverKI',K.KII/K.KI,'J',K.J,'G',Kr^2/Em,'MTS_deg',M.theta_deg,'EDI_all',ed, ...
  'KI_COD',K.KI_COD,'KII_COD',K.KII_COD,'CODminusEDI_rel',max(abs([K.KI_COD-K.KI,K.KII_COD-K.KII]))/Kr, ...
  'pathSpread_rel',max(max(ed(:,1:2))-min(ed(:,1:2)))/Kr,'quad4x4_rel',max(abs(K.EDI4x4-[K.KI,K.KII]))/Kr,'JoverGminus1',K.J/(Kr^2/Em)-1, ...
  'tipToRingCircle_mm',vecnorm(cen-tip,2,2).'-pol.geometry.ringR_mm,'tipToHoleCircle_mm',vecnorm(cen-tip,2,2).'-pol.geometry.holeR_mm, ...
  'guideRingGap_mm',Ta.ringProximity.gap_mm,'clearance',Ra.metrics,'classification',Ta.classification,'kinkSummary',Ka.summary,'kinkGatesPass',Ka.pass, ...
  'phaseCounts',K.phaseCounts,'activeArea_mm2',K.activeArea_mm2,'ringStrainEnergy',K.ringStrainEnergy_per_thickness, ...
  'compliance_mm_per_N',K.compliance_mm_per_N,'meshSHA256',mh,'phaseSHA256',ph,'solutionSHA256',sh,'T3',size(D.T3,1), ...
  'seedRung',[],'seedSpacing_mm',pol.meshFamily.seedSpacing_mm,'canonicalSHA256',Gq.canonicalSHA256,'qualificationArraysSHA256',pol.qualification.arrays.sha256, ...
  'pairingGates',Gq.PA.gatesPassed,'meshAuditGates',Gq.A.meshAudit.gatesPassed,'solveSeconds',secs,'clearanceGeometry',geomNew, ...
  'campaignId',pol.campaignId,'numericalStatus','ACCEPTED','physicalFractureGrowthProven',false);
 sth=lower(g2_trajectory_record('write',fullfile(sd,'STATE.mat'),St));
 stage='TERMINAL';
 cand=struct('polyline_mm',[],'classification','','guideRingGap_mm',[],'clearancePass',[],'clearance',struct(),'tipToRingCircle_mm',[],'note','');
 try
  F11=ops.forecast(St,C.a3.policy);R11=g2_lp0_clearance(F11.polyline_mm(1:end-1,:),F11.polyline_mm(end,:),geomNew,C.a3.policy);
  T11=g2_lp2a3_classify(R11,[1 0 0],C.a3.policy,F11.polyline_mm(end,:));tip11=F11.polyline_mm(end,:);
  cand=struct('polyline_mm',F11.polyline_mm,'classification',T11.classification,'guideRingGap_mm',T11.ringProximity.gap_mm,'clearancePass',R11.pass, ...
   'clearance',R11.metrics,'tipToRingCircle_mm',vecnorm(cen-tip11,2,2).'-pol.geometry.ringR_mm,'note','S11 forecast for information only: no mesh, admission or solve');
 catch ME
  cand.note=sprintf('S11 information unavailable (%s)',ME.identifier);
 end
 Tr=struct('schema','NewMetacomp.G2.LP2B1S10.Terminal.v1','caseId','soft1','mask',[1 0 0],'classification','SINGLE_STATE_LIMIT_REACHED','lastAcceptedState',k, ...
  'parentSHA256',sth,'stateSHA256',sth,'originalParentSHA256',Tq.parentSHA256,'lastTip_mm',tip,'lastArc_mm',F.arc_mm,'lastTipToRingCircle_mm',St.tipToRingCircle_mm, ...
  'candidate',cand,'candidateIsInformationOnly',true,'token',C.token,'campaignId',pol.campaignId,'interfaceEncounter',false,'physicalArrest',false);
 g2_trajectory_record('write',fullfile(cd0,'TERMINAL.mat'),Tr);
 O.stage='STATE_ACCEPTED';O.stateSHA256=sth;O.solutionSHA256=sh;O.K=struct('KI',K.KI,'KII',K.KII,'MTS_deg',M.theta_deg);O.terminal=Tr.classification;
 O.S11=rmfield(cand,'clearance');O.activationHead=activationHead;
 fprintf('G2_LP2B1S10_ACCEPTED soft1 S10 s=%.4f KI=%.9g KII=%+.9g MTS=%+.5f tip=(%.4f,%.4f)\n',St.arc_mm,St.KI,St.KII,St.MTS_deg,tip);
catch ME
 holdRecord(sd,stage,ME);rethrow(ME);
end
end

% =====================================================================
function [Gq,Q]=admitGeometry(C,ops,Tq,P,t,k,od)
% the unchanged LP2-B1-EQ geometry admission with the same-geometry FAILED_MESH baseline, plus the exact expectations
pol=C.policy;s=struct('qualification',pol.qualification,'mask',[1 0 0],'stateIndex',k,'ratio',pol.target.ratio,'id','soft1-S10');
Ref=struct('mesh',Tq.failedMesh,'state',struct('polyline_mm',P,'tangent',t),'nominalGeometry',Tq.nominalGeometry);
Gq=ops.geometry(C,s,Ref,od);ex=pol.meshFamily.expected;ck=struct();ind=fieldOr(Gq.attempt,'independent');
ck.expectedT3=isequal(fieldOr(Gq.attempt,'T3'),ex.T3)&&(isempty(Gq.D)||size(Gq.D.T3,1)==ex.T3);
ck.expectedMinAngle=isstruct(ind)&&isequal(ind.minAngle_deg,ex.minAngle_deg)&&ind.minAngle_deg>=ex.limits.minAngle_deg;
ck.expectedMaxRatio=isstruct(ind)&&isequal(ind.maxNeighborRatio,ex.maxNeighborRatio)&&ind.maxNeighborRatio<=ex.limits.maxNeighborRatio;
ck.expectedChords=isequal(Gq.chordsPerCircle,reshape(ex.chordsPerCircle,1,3));
ck.qParents2443=~isempty(Gq.D)&&numel(Gq.D.qActiveT6Rows)==ex.qActiveT6Parents;
ck.T3Limit=~isempty(Gq.D)&&size(Gq.D.T3,1)<=ex.limits.maxT3;
au=fieldOr(Gq.attempt,'audit');ck.attemptGuide1mm=isstruct(au)&&min(au.guideRingGap_mm)>=1&&strcmp(au.actualClassification,'MATRIX_ADVANCE')&&strcmp(au.nominalClassification,'MATRIX_ADVANCE');
v=cellfun(@(x)isequal(x,true),struct2cell(ck));Q=struct('pass',all(v),'checks',ck);
end
function [C,ops]=setup(o)
if isempty(o.Test)
 C=g2_lp2b1s10_context('Preflight',o.Preflight);ops=defaults(C);return
end
T=o.Test;tr=cpath(T.root);
assert(isfolder(tr)&&under(tr,tempdir),'G2LP2B1S10:HOLD_TEST_INJECTION','Injected operations are allowed only under a tempdir test root.');
C=T.context;assert(under(C.runRoot,tr)&&under(C.receiptRoot,tr)&&under(C.goFile,tr),'G2LP2B1S10:HOLD_TEST_INJECTION','Every test root must lie inside the test root.');
C.test=true;ops=defaults(C);
if isfield(T,'ops'),f=fieldnames(T.ops);for k=1:numel(f),ops.(f{k})=T.ops.(f{k});end,end
end
function ops=defaults(C)
ops=struct('gate',@gate,'head',@()headOf(C),'target',@g2_lp2b1s10_target,'geometry',@g2_lp2b1eq_geometry, ...
 'memgate',@(m)g2_lp2a2_eq_memgate(m),'freeRAM',@freeRAM,'solve',@g2_m4b_sif_partial,'forecast',@g2_lp2_forecast);
end
function admitHook(C)
% campaign ledger admission (exactly one): integrity, receipt bound to the token, no earlier ADMIT, key soft1_S10
L=g2_lp1_campaign_ledger('snapshot',C.receiptRoot);
assert(L.integrityOK&&isstruct(L.receipt)&&strcmp(L.receipt.token,C.token),'G2LP1:HOLD_CAMPAIGN_INTEGRITY','Campaign ledger record failed verification.');
assert(isempty(L.admits)&&~isfile(fullfile(C.receiptRoot,'ADMIT_soft1_S10.mat')),'G2LP2B1S10:HOLD_ONE_ATTEMPT','soft1 S10 was already admitted; no retry.');
g2_lp1_campaign_ledger('write',C.receiptRoot,'ADMIT','ADMIT_soft1_S10.mat',struct('campaignId',C.policy.campaignId,'stateKey','soft1_S10','caseId','soft1', ...
 'stateIndex',10,'token',C.token,'admittedUTC',char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss.SSS''Z'''))));
end
function G=gate(C,tok)
assert(isfile(C.goFile),'G2LP2B1S10:HOLD_UNAUTHORIZED','No GO_LP2B1_S10 record (%s): the campaign is prepared, not authorized.',C.policy.authorization.goPath);
fid=fopen(C.goFile,'r');raw=fread(fid,inf,'*uint8');fclose(fid);
md=java.security.MessageDigest.getInstance('SHA-256');md.update(raw);goSHA=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
try,Gd=jsondecode(native2unicode(raw.','UTF-8'));catch,Gd=[];end
G=g2_lp2b1s10_go_validate(Gd,C,tok);
assert(G.pass,'G2LP2B1S10:HOLD_UNAUTHORIZED','GO record rejected: %s',strjoin(G.failed,', '));
G.goFileSHA256=goSHA;G.approvedHead=Gd.approvedHead;
end
function h=headOf(C)
H=g2_lp2a2_git('head',C.repo);assert(H.ok,'G2LP2B1S10:HOLD_GIT','git rev-parse HEAD failed (status %d): %s',H.status,H.output);h=H.value;
end
function refuseHistorical(C,root)
for k=1:numel(C.historicalRoots)
 assert(~under(root,C.historicalRoots{k})&&~under(C.historicalRoots{k},root),'G2LP2B1S10:HOLD_HISTORICAL_ROOT','Refusing to write at or under a historical root: %s',C.historicalRoots{k});
end
end
function t=under(p,root)
a=lower(cpath(p));b=lower(cpath(root));if ~endsWith(b,filesep),b=[b filesep];end;t=startsWith([a filesep],b);
end
function p=cpath(p),p=char(java.io.File(char(p)).getCanonicalPath());end
function holdRecord(sd,stage,ME)
f=fullfile(sd,'HOLD.json');if isfolder(sd)&&~isfile(f)
 wj(f,struct('schema','NewMetacomp.G2.LP2B1S10.Hold.v1','stage',stage,'identifier',ME.identifier,'message',ME.message,'physicalArrest',false, ...
  'utc',char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss.SSS''Z'''))));end
end
function n=failedNames(c),f=fieldnames(c);v=cellfun(@(x)isequal(x,true),struct2cell(c));n=f(~v).';end
function s=summTarget(T)
s=struct('pass',T.pass,'checks',T.checks,'parentSHA256',T.parentSHA256,'info',T.info);
end
function g=summGeo(G,Q)
g=struct('pass',G.pass&&Q.pass,'checks',G.checks,'expected',Q.checks,'canonicalSHA256',G.canonicalSHA256,'metadataSHA256',G.metadataSHA256,'chordsPerCircle',G.chordsPerCircle, ...
 'activeAreaGeometric_mm2',G.activeAreaGeometric_mm2,'stations',G.stations,'attemptChecks',sprintf('%d/%d',fieldOr(G.attempt,'checksPassed'),fieldOr(G.attempt,'checksTotal')), ...
 'attemptCanonicalSHA256',fieldOr(G.attempt,'canonicalSHA256'),'attemptArraysSHA256',fieldOr(G.attempt,'arraysFileSHA256'),'T3',fieldOr(G.attempt,'T3'), ...
 'minAngle_deg',NaN,'maxNeighborRatio',NaN,'topology',G.topology,'actualClassification','','guideRingGap_mm',[]);
ind=fieldOr(G.attempt,'independent');if isstruct(ind),g.minAngle_deg=ind.minAngle_deg;g.maxNeighborRatio=ind.maxNeighborRatio;end
au=fieldOr(G.attempt,'audit');if isstruct(au),g.actualClassification=au.actualClassification;g.guideRingGap_mm=au.guideRingGap_mm;end
end
function v=fieldOr(s,f),if isstruct(s)&&isfield(s,f),v=s.(f);else,v=[];end,end
function g=freeRAM(),[~,s]=memory;g=s.PhysicalMemory.Available/2^30;end
function wj(f,S)
fid=fopen(f,'w');assert(fid>0,'G2LP2B1S10:Write','Cannot write %s',f);fwrite(fid,jsonencode(S,'PrettyPrint',true),'char');fclose(fid);
end
