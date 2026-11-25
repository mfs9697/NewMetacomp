function O=g2_lp2_run(varargin)
%G2_LP2_RUN  LP2-A1 continuation of one accepted S4 path, S5 to at most S8. Dry by default.
%
%  O = g2_lp2_run('Case','H')                                              % dry: no write, no mesh, no FEM
%  O = g2_lp2_run('Case','H','Run',true,'AuthToken',tok,'RunName',name)    % needs GO_LP2A
% Parent: the accepted A0 S4 state of the case (file SHA-256 pinned in G2_LP2A_POLICY_v1.json).
% Authorized path: gate -> token -> VG2 campaign validation -> receipt/RUN -> read-only verification
% of the existing chain (g2_lp2_verify) -> g2_lp2_chain with the unchanged LP1 operations
% (g2_lp2_forecast, g2_lp0_clearance, g2_lp2_classify, g2_lp1_admit_state + g2_lp2_admit_hook,
% g2_kinked_join, g2_lp1_audit, g2_m4b_ring_activation, g2_m4b_sif_partial, g2_mts_direction).
% Terminal handling, local/global HOLD separation and closure are in g2_lp2_chain. A closed
% campaign only verifies (VERIFY_ONLY, zero solves). Physical arrest is never inferred.
ip=inputParser;addParameter(ip,'Case','H',@ischar);addParameter(ip,'Run',false,@islogical);addParameter(ip,'AuthToken','',@ischar);
addParameter(ip,'RunName','run_lp2a_not_authorized',@(s)ischar(s)&&~isempty(regexp(s,'^run_[a-zA-Z0-9_]+$','once')));
parse(ip,varargin{:});o=ip.Results;
C=g2_lp2_context();pol=C.policy;ids={pol.cases.id};ix=find(strcmp(ids,o.Case));
assert(isscalar(ix),'G2LP2:HOLD_INPUT','Exactly H, stiff13, soft2, soft1 permitted.');c=pol.cases(ix);mask=reshape(c.mask,1,3);
Par=parentState(C,c.id);
if ~o.Run
 F=g2_lp2_forecast(Par.state,pol);Rc=g2_lp0_clearance(F.polyline_mm(1:end-1,:),F.polyline_mm(end,:),Par.geom,pol);
 T=g2_lp2_classify(Rc,mask,pol);
 O=struct('status','DRY_READY_NO_FEM','computed',0,'caseId',c.id,'token',C.token,'parentStateSHA256',Par.stateSHA256, ...
  'S5',struct('tip_mm',F.polyline_mm(end,:),'heading_deg',F.heading_deg,'arc_mm',F.arc_mm,'parentMTS_deg',F.parentMTS_deg, ...
  'classification',T.classification,'clearance',Rc.metrics));
 return
end
% ------------------------------------------------------------------ authorized path only
G=g2_lp2_scientific_gate(C);
assert(strcmp(o.AuthToken,C.token),'G2LP2:HOLD_SOURCE','Token does not bind the LP2-A policy, sources and parents.');
rd=fullfile(C.repo,'outputs','g2_lp2a_paths_v1',o.RunName);chain=fullfile(rd,c.id);
lroot=fullfile(C.repo,'outputs','g2_lp2a_campaign_ledger',G.campaignId);
Camp=g2_lp1_campaign_validate(struct('approvedRunName',G.approvedRunName,'campaignId',G.campaignId,'campaignScope',G.campaignScope), ...
 o.RunName,G.goFileSHA256,C.token,g2_lp1_campaign_ledger('snapshot',lroot),runFolderFacts(rd,C.token),[]);
masks=reshape([pol.cases.mask],3,[]).';
V=struct('rd',rd,'lroot',lroot,'ids',{ids},'masks',masks,'parents',struct(),'pol',pol,'token',C.token, ...
 'policySHA256',C.policySHA256,'g2SourceSHA256',C.g2SourceSHA256,'lp2SourceSHA256',C.lp2SourceSHA256);
V.parents.(c.id)=struct('state',Par.state,'stateSHA256',Par.stateSHA256);
if strcmp(Camp.mode,'VERIFY_ONLY')
 Vall=allParents(V,C,ids);Vall.requireTerminal=true;Rv=g2_lp2_verify(Vall);
 assert(Rv.pass,'G2LP2:HOLD_RECORD_INTEGRITY','Verification failed: %s',strjoin(Rv.problems,'; '));
 [Tm,~,~]=g2_trajectory_record('read',fullfile(chain,'TERMINAL.mat'));
 O=struct('status',['VERIFIED_' Tm.classification],'computed',0,'reused',numel(Rv.cases.(c.id).acceptedStates),'caseId',c.id, ...
  'terminal',Tm.classification,'lastState',Tm.lastAcceptedState,'campaignMode',Camp.mode,'verification',Rv);
 return
end
if strcmp(Camp.mode,'OPEN_NEW')
 g2_lp1_campaign_ledger('write',lroot,'RECEIPT','RECEIPT.mat',struct('campaignId',G.campaignId,'runName',o.RunName, ...
  'goSHA256',G.goFileSHA256,'token',C.token,'sourceCommit',C.preflight.sourceCommit,'openedUTC',utcNow()));
end
if ~isfolder(rd),mkdir(rd);end
rf=fullfile(rd,'RUN.mat');
if isfile(rf),[rr,~,ok]=g2_trajectory_record('read',rf);assert(ok&&strcmp(rr.token,C.token),'G2LP2:HOLD_SOURCE','Run token drift.');
else
 assert(numel(dir(rd))<=2,'G2LP2:HOLD_RECORD_INTEGRITY','Nonempty run without RUN record.');
 g2_trajectory_record('write',rf,struct('schema','NewMetacomp.G2.LP2A.Run.v1','token',C.token,'sourceCommit',C.preflight.sourceCommit,'lp2SourceLines',{C.lp2SourceLines}));
end
if ~isfolder(chain),mkdir(chain);end
Vc=V;Vc.cases={c.id};Rv=g2_lp2_verify(Vc);   % existing prefix of THIS case: verify, never recompute
if ~Rv.pass
 g2_lp1_campaign_ledger('write',lroot,'HOLD',sprintf('HOLD_GLOBAL_%s_VERIFY_%s.mat',c.id,datestr(now,'yyyymmddTHHMMSSFFF')), ...
  struct('campaignId',G.campaignId,'caseId',c.id,'stateIndex',-1,'hold',struct('identifier','G2LP2:HOLD_RECORD_INTEGRITY','problems',{Rv.problems})));
 error('G2LP2:HOLD_RECORD_INTEGRITY','Existing chain fails verification: %s',strjoin(Rv.problems,'; '));
end
addpath(fullfile(C.here,'vendor_p010_a14d8872'),'-begin');
polT=jsondecode(fileread(fullfile(C.here,'G2_TRAJECTORY_POLICY_v1.json')));
Gj=jsondecode(fileread(fullfile(C.repo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json')));
W=struct('C',C,'c',c,'mask',mask,'polT',polT,'Gn',Gj.nominal_geometry_mm,'Caud',struct('repo',C.repo,'here',C.here,'policy',pol));
env=struct('caseId',c.id,'mask',mask,'ids',{ids},'rd',rd,'chain',chain,'lroot',lroot,'campMode',Camp.mode,'campaignId',G.campaignId, ...
 'runName',o.RunName,'token',C.token,'pol',pol,'parent',Par.state,'parentHash',Par.stateSHA256,'geom',Par.geom, ...
 'verifyAll',@()g2_lp2_verify(setfield(allParents(V,C,ids),'requireTerminal',true))); %#ok<SFLD>
ops=struct('forecast',@g2_lp2_forecast,'clearance',@g2_lp0_clearance,'classify',@g2_lp2_classify, ...
 'admit',@(sd,k)g2_lp1_admit_state(sd,freeRAM(),@()g2_lp2_admit_hook(lroot,Camp,G.campaignId,c.id,k)), ...
 'computeState',@(sd,k,F,parent,ph)computeState(sd,k,F,parent,ph,W));
O=g2_lp2_chain(env,ops);O.campaignMode=Camp.mode;O.campaignId=G.campaignId;O.token=C.token;
end

function [St,sth,geomNew]=computeState(sd,k,F,parent,parentHash,W)
% One admitted state: unchanged LP1 mesh, audit, activation, solve, MTS and immutable records.
C=W.C;c=W.c;pol=C.policy;mask=W.mask;P=F.polyline_mm;t=F.tangent;
D=g2_kinked_join(P,'ExpectedVertices',k+2,'ExpectedTangent',t,'ExteriorOptions', ...
 {'BottomVertices_mm',[25.4 482.6],'TopVertices_mm',254,'TipGuideRadius_mm',15,'TipGuideHface_mm',1.5},'MaxT3Elements',40000);
if ~D.pass
 failedMesh=D;save(fullfile(sd,'FAILED_MESH.mat'),'failedMesh','-v7.3');
 error('G2LP2:HOLD_MESH_QUALITY','%s %s',D.stage,D.message);
end
D.tipTangent=t;mf=fullfile(sd,'MESH.mat');save(mf,'-struct','D','-v7.3');mh=lower(g2_sha256_file(mf));D=load(mf);
[A,PM]=g2_lp1_audit(D,k,W.Caud);geomNew=A.clearanceGeometry;
Ra=g2_lp0_clearance(P(1:end-1,:),P(end,:),geomNew,pol);Ta=g2_lp2_classify(Ra,mask,pol);
assert(Ra.pass,'G2LP2:HOLD_INTERFACE_APPROACH','Actual-polygon clearance failed: %s',strjoin(Ra.reasons,','));
act=g2_m4b_ring_activation(PM.annulusOf,mask);
Ph=struct('schema','NewMetacomp.G2.LP2A.Phase.v1','stateIndex',k,'caseId',c.id,'mask',mask,'meshSHA256',mh, ...
 'owner',PM.annulusOf,'labels',act.phaseForAssembly,'audit',A);
ph=lower(g2_trajectory_record('write',fullfile(sd,'PHASE.mat'),Ph));
assert(freeRAM()>=5,'G2LP1:HOLD_MEMORY','Less than 5 GiB free physical RAM; no automatic retry.');
Em=pol.bvp.E_MPa;mk=@(E)struct('E',E,'nu',pol.bvp.nu,'plane','stress');
expect=struct('P_N',1,'thickness_mm',12.7,'load_mm',[254 203.2],'E_matrix',Em);t0=tic;
K=g2_m4b_sif_partial(D,act,[mk(Em),mk(Em*c.ratio)],W.polT,PM,expect);secs=toc(t0);
S=struct('schema','NewMetacomp.G2.LP2A.Solution.v1','stateIndex',k,'caseId',c.id,'meshSHA256',mh,'phaseSHA256',ph, ...
 'policySHA256',C.policySHA256,'g2SourceSHA256',C.g2SourceSHA256,'lp2SourceSHA256',C.lp2SourceSHA256,'token',C.token,'K',K);
sh=lower(g2_trajectory_record('write',fullfile(sd,'SOLUTION.mat'),S));
assert(K.pass,'G2LP2:HOLD_K_EXTRACTION','Failed SIF gates: %s',strjoin(K.failedCriteria,','));
M=g2_mts_direction(K.KI,K.KII);assert(M.admissibleForStep&&M.stationarityResidual_rel<=1e-12,'G2LP2:HOLD_K_EXTRACTION','MTS root.');
Ka=g2_kink_admissibility(P,W.Gn,'DeltaA_mm',4,'ExpectedVertices',k+2,'ExpectedTangent',t,'TipGuideRadius_mm',15);
Kr=hypot(K.KI,K.KII);ed=K.EDI_all;tip=P(end,:);cen=pol.geometry.centres_mm;
St=struct('schema','NewMetacomp.G2.LP2A.State.v1','stateIndex',k,'caseId',c.id,'mask',mask,'ratio',c.ratio, ...
 'policySHA256',C.policySHA256,'g2SourceSHA256',C.g2SourceSHA256,'lp2SourceSHA256',C.lp2SourceSHA256,'token',C.token, ...
 'parentSHA256',parentHash,'sourceCommit',C.preflight.sourceCommit,'polyline_mm',P,'tangent',t,'normal',[-t(2),t(1)], ...
 'tip_mm',tip,'arc_mm',F.arc_mm,'heading_deg',F.heading_deg,'parentMTS_deg',F.parentMTS_deg, ...
 'KI',K.KI,'KII',K.KII,'KIIoverKI',K.KII/K.KI,'J',K.J,'G',Kr^2/Em,'MTS_deg',M.theta_deg,'EDI_all',ed, ...
 'KI_COD',K.KI_COD,'KII_COD',K.KII_COD,'CODminusEDI_rel',max(abs([K.KI_COD-K.KI,K.KII_COD-K.KII]))/Kr, ...
 'pathSpread_rel',max(max(ed(:,1:2))-min(ed(:,1:2)))/Kr,'quad4x4_rel',max(abs(K.EDI4x4-[K.KI,K.KII]))/Kr,'JoverGminus1',K.J/(Kr^2/Em)-1, ...
 'tipToRingCircle_mm',vecnorm(cen-tip,2,2).'-pol.geometry.ringR_mm,'tipToHoleCircle_mm',vecnorm(cen-tip,2,2).'-pol.geometry.holeR_mm, ...
 'clearance',Ra.metrics,'classification',Ta.classification,'kinkSummary',Ka.summary,'kinkGatesPass',Ka.pass, ...
 'phaseCounts',K.phaseCounts,'activeArea_mm2',K.activeArea_mm2,'ringStrainEnergy',K.ringStrainEnergy_per_thickness, ...
 'compliance_mm_per_N',K.compliance_mm_per_N,'meshSHA256',mh,'phaseSHA256',ph,'solutionSHA256',sh,'T3',size(D.T3,1), ...
 'solveSeconds',secs,'clearanceGeometry',geomNew,'numericalStatus','ACCEPTED','physicalFractureGrowthProven',false);
sth=lower(g2_trajectory_record('write',fullfile(sd,'STATE.mat'),St));
fprintf('G2_LP2A_ACCEPTED %s S%d s=%.4f KI=%.9g KII=%+.9g MTS=%+.5f tip=(%.4f,%.4f)\n',c.id,k,St.arc_mm,St.KI,St.KII,St.MTS_deg,tip);
end
function V=allParents(V,C,ids)
for i=1:numel(ids),Pi=parentState(C,ids{i});V.parents.(ids{i})=struct('state',Pi.state,'stateSHA256',Pi.stateSHA256);end
end
function Par=parentState(C,id)
% Accepted A0 S4 parent: file SHA-256 pins, record manifests, semantic links, clearance polygons.
pp=C.policy.parents.(id);d=fullfile(C.repo,strrep(C.policy.parents.run,'/',filesep),id,'S4');
h=struct('STATE',lower(g2_sha256_file(fullfile(d,'STATE.mat'))),'MESH',lower(g2_sha256_file(fullfile(d,'MESH.mat'))), ...
 'SOLUTION',lower(g2_sha256_file(fullfile(d,'SOLUTION.mat'))));
assert(strcmpi(h.STATE,pp.STATE)&&strcmpi(h.MESH,pp.MESH)&&strcmpi(h.SOLUTION,pp.SOLUTION),'G2LP2:HOLD_SOURCE','Parent S4 records of %s differ from the pins.',id);
[St,~,ok]=g2_trajectory_record('read',fullfile(d,'STATE.mat'));[So,~,ok2]=g2_trajectory_record('read',fullfile(d,'SOLUTION.mat'));
assert(ok&&ok2&&St.stateIndex==4&&strcmp(St.caseId,id)&&strcmpi(St.meshSHA256,h.MESH)&&strcmpi(St.solutionSHA256,h.SOLUTION)&& ...
 isequal(St.KI,So.K.KI)&&isequal(St.KII,So.K.KII)&&isequal(size(St.polyline_mm),[6 2]),'G2LP2:HOLD_RECORD_INTEGRITY','Parent S4 of %s fails its links.',id);
D=load(fullfile(d,'MESH.mat'));cen=C.policy.geometry.centres_mm;
O=g2_m4b_ring_owner_oracle(D.X6,D.T6,cen,6.35*ones(3,1),19.05*ones(3,1),struct('onCircleTol_mm',1e-9));
assert(O.pass,'G2LP2:HOLD_OWNER_MASK','Parent ring/hole polygons of %s not resolved.',id);
geom=struct('centres',cen,'ringPolygons',{cellfun(@(v)D.X6(v,:),O.ringVertices,'UniformOutput',false)}, ...
 'holePolygons',{cellfun(@(v)D.X6(v,:),O.holeVertices,'UniformOutput',false)});
Par=struct('state',St,'stateSHA256',h.STATE,'geom',geom);
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
