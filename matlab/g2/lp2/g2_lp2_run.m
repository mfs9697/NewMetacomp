function O=g2_lp2_run(varargin)
%G2_LP2_RUN  LP2-A1 continuation of one accepted S4 path, S5 to at most S8. Dry by default.
%
%  O = g2_lp2_run('Case','H')                                              % dry: no write, no mesh, no FEM
%  O = g2_lp2_run('Case','H','Run',true,'AuthToken',tok,'RunName',name)    % needs GO_LP2A
% Parent: the accepted A0 S4 state of the case (file SHA-256 pinned in G2_LP2A_POLICY_v1.json).
% Each state reuses the unchanged LP1 chain: g2_lp2_forecast (same MTS recurrence as
% g2_lp1_forecast) -> g2_lp0_clearance -> g2_lp2_classify -> admission (VG2 ledger) ->
% g2_kinked_join -> g2_lp1_audit -> g2_m4b_ring_activation -> g2_m4b_sif_partial -> MTS.
% A candidate that is not MATRIX_ADVANCE ends the case with a TERMINAL record (no mesh, no solve);
% a HOLD ends it with HOLD + TERMINAL(NUMERICAL_HOLD) records and is never retried; an accepted
% S8 ends it with CAMPAIGN_LIMIT_REACHED. Physical arrest is never inferred.
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
O=struct('status','','computed',0,'reused',0,'caseId',c.id,'token',C.token,'states',{{}});
rd=fullfile(C.repo,'outputs','g2_lp2a_paths_v1',o.RunName);chain=fullfile(rd,c.id);
lroot=fullfile(C.repo,'outputs','g2_lp2a_campaign_ledger',G.campaignId);
Camp=g2_lp1_campaign_validate(struct('approvedRunName',G.approvedRunName,'campaignId',G.campaignId,'campaignScope',G.campaignScope), ...
 o.RunName,G.goFileSHA256,C.token,g2_lp1_campaign_ledger('snapshot',lroot),runFolderFacts(rd,C.token),[]);
O.campaignMode=Camp.mode;O.campaignId=G.campaignId;tf=fullfile(chain,'TERMINAL.mat');
if strcmp(Camp.mode,'VERIFY_ONLY'),assert(isfile(tf),'G2LP1:HOLD_CAMPAIGN_CLOSED','Campaign is closed: no new state may be computed.');end
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
addpath(fullfile(C.here,'vendor_p010_a14d8872'),'-begin');
polT=jsondecode(fileread(fullfile(C.here,'G2_TRAJECTORY_POLICY_v1.json')));
Gj=jsondecode(fileread(fullfile(C.repo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json')));Gn=Gj.nominal_geometry_mm;
Caud=struct('repo',C.repo,'here',C.here,'policy',pol);
parent=Par.state;parentHash=Par.stateSHA256;geom=Par.geom;
for k=5:pol.caps.maxStateIndex
 sd=fullfile(chain,sprintf('S%d',k));sf=fullfile(sd,'STATE.mat');
 if isfile(sf)
  [St,sth,ok]=g2_trajectory_record('read',sf);
  assert(ok&&St.stateIndex==k&&strcmp(St.caseId,c.id)&&strcmpi(St.parentSHA256,parentHash)&&strcmp(St.token,C.token), ...
   'G2LP2:HOLD_RECORD_INTEGRITY','Saved LP2 state S%d differs.',k);
  O.reused=O.reused+1;O.states{end+1}=St;parent=St;parentHash=lower(sth);geom=St.clearanceGeometry;continue
 end
 if isfile(tf),break,end
 F=g2_lp2_forecast(parent,pol);P=F.polyline_mm;t=F.tangent;
 Rc=g2_lp0_clearance(P(1:end-1,:),P(end,:),geom,pol);T=g2_lp2_classify(Rc,mask,pol);
 if ~strcmp(T.classification,'MATRIX_ADVANCE')
  writeTerminal(tf,c,T.classification,parent,parentHash,F,Rc,T,C,'candidate segment fails a guard; no mesh, no solve');break
 end
 try
  g2_lp1_admit_state(sd,freeRAM(),@()g2_lp2_admit_hook(lroot,Camp,G.campaignId,c.id,k));
  D=g2_kinked_join(P,'ExpectedVertices',k+2,'ExpectedTangent',t,'ExteriorOptions', ...
   {'BottomVertices_mm',[25.4 482.6],'TopVertices_mm',254,'TipGuideRadius_mm',15,'TipGuideHface_mm',1.5},'MaxT3Elements',40000);
  if ~D.pass
   failedMesh=D;save(fullfile(sd,'FAILED_MESH.mat'),'failedMesh','-v7.3');
   error('G2LP2:HOLD_MESH_QUALITY','%s %s',D.stage,D.message);
  end
  D.tipTangent=t;mf=fullfile(sd,'MESH.mat');save(mf,'-struct','D','-v7.3');mh=lower(g2_sha256_file(mf));D=load(mf);
  [A,PM]=g2_lp1_audit(D,k,Caud);geomNew=A.clearanceGeometry;
  Ra=g2_lp0_clearance(P(1:end-1,:),P(end,:),geomNew,pol);Ta=g2_lp2_classify(Ra,mask,pol);
  assert(Ra.pass,'G2LP2:HOLD_INTERFACE_APPROACH','Actual-polygon clearance failed: %s',strjoin(Ra.reasons,','));
  act=g2_m4b_ring_activation(PM.annulusOf,mask);
  Ph=struct('schema','NewMetacomp.G2.LP2A.Phase.v1','stateIndex',k,'caseId',c.id,'mask',mask,'meshSHA256',mh, ...
   'owner',PM.annulusOf,'labels',act.phaseForAssembly,'audit',A);
  ph=lower(g2_trajectory_record('write',fullfile(sd,'PHASE.mat'),Ph));
  assert(freeRAM()>=5,'G2LP1:HOLD_MEMORY','Less than 5 GiB free physical RAM; no automatic retry.');
  Em=pol.bvp.E_MPa;mk=@(E)struct('E',E,'nu',pol.bvp.nu,'plane','stress');
  expect=struct('P_N',1,'thickness_mm',12.7,'load_mm',[254 203.2],'E_matrix',Em);t0=tic;
  K=g2_m4b_sif_partial(D,act,[mk(Em),mk(Em*c.ratio)],polT,PM,expect);secs=toc(t0);O.computed=O.computed+1;
  S=struct('schema','NewMetacomp.G2.LP2A.Solution.v1','stateIndex',k,'caseId',c.id,'meshSHA256',mh,'phaseSHA256',ph, ...
   'policySHA256',C.policySHA256,'g2SourceSHA256',C.g2SourceSHA256,'lp2SourceSHA256',C.lp2SourceSHA256,'token',C.token,'K',K);
  sh=lower(g2_trajectory_record('write',fullfile(sd,'SOLUTION.mat'),S));
  assert(K.pass,'G2LP2:HOLD_K_EXTRACTION','Failed SIF gates: %s',strjoin(K.failedCriteria,','));
  M=g2_mts_direction(K.KI,K.KII);assert(M.admissibleForStep&&M.stationarityResidual_rel<=1e-12,'G2LP2:HOLD_K_EXTRACTION','MTS root.');
  Ka=g2_kink_admissibility(P,Gn,'DeltaA_mm',4,'ExpectedVertices',k+2,'ExpectedTangent',t,'TipGuideRadius_mm',15);
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
  sth=lower(g2_trajectory_record('write',sf,St));
  O.states{end+1}=St;parent=St;parentHash=sth;geom=geomNew;
  fprintf('G2_LP2A_ACCEPTED %s S%d s=%.4f KI=%.9g KII=%+.9g MTS=%+.5f tip=(%.4f,%.4f)\n',c.id,k,St.arc_mm,St.KI,St.KII,St.MTS_deg,tip);
  clear D A PM Ph S K
 catch ME
  O.status='HOLD';O.hold=struct('identifier',ME.identifier,'message',ME.message);
  pre=strcmp(ME.identifier,'G2LP1:HOLD_MEMORY')&&~isfolder(sd);camp=startsWith(ME.identifier,'G2LP1:HOLD_CAMPAIGN_')&&~isfolder(sd);
  hold=struct('schema','NewMetacomp.G2.LP2A.Hold.v1','stateIndex',k,'caseId',c.id,'identifier',ME.identifier,'message',ME.message, ...
   'parentSHA256',parentHash,'physicalArrest',false);
  if pre
   g2_lp1_campaign_ledger('write',lroot,'HOLD',sprintf('HOLD_PREADMISSION_MEMORY_%s_S%d_%s.mat',c.id,k,datestr(now,'yyyymmddTHHMMSSFFF')), ...
    struct('campaignId',G.campaignId,'caseId',c.id,'stateIndex',k,'hold',hold));
  elseif ~camp
   if ~isfolder(sd),mkdir(sd);end
   hf=fullfile(sd,'HOLD.mat');if ~isfile(hf),g2_trajectory_record('write',hf,hold);end
   writeTerminal(tf,c,'NUMERICAL_HOLD',parent,parentHash,F,Rc,T,C,[ME.identifier ': ' ME.message]);
  end
  fprintf(2,'G2_LP2A_HOLD %s S%d %s: %s\n',c.id,k,ME.identifier,ME.message);return
 end
end
if ~isfile(tf)&&parent.stateIndex==pol.caps.maxStateIndex
 p9=pol;p9.caps.maxStateIndex=pol.caps.maxStateIndex+1;p9.caps.maxArcLength_mm=pol.caps.maxArcLength_mm+4;
 F=g2_lp2_forecast(parent,p9);Rc=g2_lp0_clearance(F.polyline_mm(1:end-1,:),F.polyline_mm(end,:),geom,pol);T=g2_lp2_classify(Rc,mask,pol);
 writeTerminal(tf,c,'CAMPAIGN_LIMIT_REACHED',parent,parentHash,F,Rc,T,C,['S8 accepted; S9 candidate classified ' T.classification ' for information only']);
end
[Tm,~,okT]=g2_trajectory_record('read',tf);assert(okT,'G2LP2:HOLD_RECORD_INTEGRITY','Terminal record failed verification.');
O.terminal=Tm.classification;O.lastState=Tm.lastAcceptedState;O.status=['TERMINAL_' Tm.classification];
% closure once all four cases are terminal
tfs=cellfun(@(id)fullfile(rd,id,'TERMINAL.mat'),ids,'UniformOutput',false);
if all(cellfun(@isfile,tfs))&&~isfile(fullfile(lroot,'CLOSED.mat'))&&~strcmp(Camp.mode,'VERIFY_ONLY')
 shs=cell(1,4);for z=1:4,[~,shs{z},okz]=g2_trajectory_record('read',tfs{z});assert(okz,'G2LP2:HOLD_RECORD_INTEGRITY','Terminal record failed.');end
 g2_lp1_campaign_ledger('write',lroot,'CLOSED','CLOSED.mat',struct('campaignId',G.campaignId,'runName',o.RunName, ...
  'cases',{ids},'terminalSHA256',{lower(shs)},'closedUTC',utcNow()));
 O.campaignClosed=true;
end
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
function writeTerminal(tf,c,cls,parent,parentHash,F,Rc,T,C,note)
tip=parent.polyline_mm(end,:);cen=C.policy.geometry.centres_mm;
R=struct('schema','NewMetacomp.G2.LP2A.Terminal.v1','caseId',c.id,'mask',reshape(c.mask,1,3),'classification',cls, ...
 'lastAcceptedState',parent.stateIndex,'lastTip_mm',tip,'lastArc_mm',sum(vecnorm(diff(parent.polyline_mm),2,2)), ...
 'lastTipToRingCircle_mm',vecnorm(cen-tip,2,2).'-C.policy.geometry.ringR_mm,'lastTipToHoleCircle_mm',vecnorm(cen-tip,2,2).'-C.policy.geometry.holeR_mm, ...
 'candidatePolyline_mm',F.polyline_mm,'candidateClassification',T.classification,'candidateConstraints',T.constraints, ...
 'candidateClearance',Rc.metrics,'activeInterfaceClearance_mm',T.activeInterfaceClearance_mm,'passiveContourClearance_mm',T.passiveContourClearance_mm, ...
 'parentSHA256',parentHash,'token',C.token,'note',note,'interfaceEncounter',false,'physicalArrest',false);
g2_trajectory_record('write',tf,R);
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
