function O=g2_a1_run(varargin)
%G2_A1_RUN  Bounded A1 fixed-path Family B solve: one case x one level per call (Issue #66).
%
%  O = g2_a1_run('Case','H','Level',3)                         % dry (default): no write, no FEM
%  O = g2_a1_run('Case','H','Level',3,'Run',true,'AuthToken',tok,'RunName',name)   % needs GO_A1
% Frozen S4 geometry of the A0 path; Family B level m in {3,6,9}; at most twelve solves per
% campaign. Physics is the unchanged NewMetacomp chain: g2_material_phase_map ->
% g2_m4b_ring_activation -> g2_m4b_sif_partial (g2_t6_elasticity_phase, blind COD, signed
% five-annulus EDI) with the LP1 policy v2 BVP and materials. The mesh is the preregistered
% candidate (content SHA-256 pinned in G2_A1_POLICY_v1.json), re-validated before any solve.
% Authorization: hard-coded A1 GO (g2_a1_scientific_gate), token, and the VG2 campaign
% machinery (g2_lp1_campaign_validate / g2_lp1_campaign_ledger / g2_lp1_admit_state) under
% outputs/g2_a1_campaign_ledger/<campaignId>/. No resumption mechanism exists for A1.
ip=inputParser;addParameter(ip,'Case','H',@ischar);addParameter(ip,'Level',3,@isnumeric);
addParameter(ip,'Run',false,@islogical);addParameter(ip,'AuthToken','',@ischar);
addParameter(ip,'RunName','run_a1_not_authorized',@(s)ischar(s)&&~isempty(regexp(s,'^run_[a-zA-Z0-9_]+$','once')));
parse(ip,varargin{:});o=ip.Results;
assert(isscalar(o.Level)&&any(o.Level==[3 6 9]),'G2A1:HOLD_UNAUTHORIZED_STATE','Only Family B levels 3, 6, 9 are permitted.');
C=g2_a1_context();pol=C.policy;
lp=jsondecode(fileread(fullfile(C.here,'G2_LP1_POLICY_v2.json')));
assert(strcmpi(g2_sha256_file(fullfile(C.here,'G2_LP1_POLICY_v2.json')),pol.lp1PolicySHA256),'G2A1:HOLD_SOURCE','LP1 policy v2 drift.');
ids={lp.cases.id};ix=find(strcmp(ids,o.Case));
assert(isscalar(ix),'G2A1:HOLD_INPUT','Exactly H, stiff13, soft2, soft1 permitted.');c=lp.cases(ix);
key=sprintf('%s_B%d',c.id,o.Level);
O=struct('status','DRY_READY_NO_FEM','computed',0,'reused',0,'caseId',c.id,'level',o.Level,'key',key,'token',C.token);
if ~o.Run,return,end
G=g2_a1_scientific_gate(C);
assert(strcmp(o.AuthToken,C.token),'G2A1:HOLD_SOURCE','Token does not bind the A1 policy, source and mesh manifest.');
rd=fullfile(C.repo,'outputs','g2_a1_fixed_path_v1',o.RunName);sd=fullfile(rd,key);
lroot=fullfile(C.repo,'outputs','g2_a1_campaign_ledger',G.campaignId);
Camp=g2_lp1_campaign_validate(G,o.RunName,G.goFileSHA256,C.token, ...
 g2_lp1_campaign_ledger('snapshot',lroot),runFolderFacts(rd,C.token),[]);
O.campaignMode=Camp.mode;O.campaignId=G.campaignId;
statefile=fullfile(sd,'STATE.mat');
if strcmp(Camp.mode,'VERIFY_ONLY')
 assert(isfile(statefile),'G2LP1:HOLD_CAMPAIGN_CLOSED','Campaign is closed: no new state may be computed.');
end
% preregistered mesh and its A0 S4 baseline (content SHA-256), re-validated, no FEM
D=load(fullfile(C.repo,strrep(pol.meshRoot,'/',filesep),c.id,sprintf('B%d',o.Level),'MESH.mat'));
assert(strcmp(g2_a1_mesh_content_sha(D),pol.meshes.(key).contentSHA256),'G2A1:HOLD_SOURCE','Mesh content differs from the preregistration.');
D0=load(fullfile(C.repo,strrep(pol.baselineS4.(c.id).path,'/',filesep)));
assert(strcmp(g2_a1_mesh_content_sha(D0),pol.baselineS4.(c.id).contentSHA256),'G2A1:HOLD_SOURCE','Baseline S4 mesh differs.');
V=g2_a1_mesh_validate(D,D0);assert(V.pass,'G2A1:HOLD_MESH_QUALITY','A1 mesh validation failed: %s',strjoin(V.failedGates,','));
if isfile(statefile)
 [St,~,ok]=g2_trajectory_record('read',statefile);
 assert(ok&&strcmp(St.key,key)&&strcmp(St.meshContentSHA256,pol.meshes.(key).contentSHA256)&&strcmp(St.sourceSHA256,C.sourceSHA256), ...
  'G2A1:HOLD_RECORD_INTEGRITY','Saved A1 state differs.');
 O.reused=1;O.status='REUSED_ZERO_SOLVE';O.state=St;return
end
if strcmp(Camp.mode,'OPEN_NEW')
 g2_lp1_campaign_ledger('write',lroot,'RECEIPT','RECEIPT.mat',struct('campaignId',G.campaignId,'runName',o.RunName, ...
  'goSHA256',G.goFileSHA256,'token',C.token,'sourceCommit',C.preflight.sourceCommit,'openedUTC',utcNow()));
end
if ~isfolder(rd),mkdir(rd);end
rf=fullfile(rd,'RUN.mat');
if isfile(rf)
 [rr,~,ok]=g2_trajectory_record('read',rf);assert(ok&&strcmp(rr.token,C.token),'G2A1:HOLD_SOURCE','Run token drift.');
else
 assert(numel(dir(rd))<=2,'G2A1:HOLD_RECORD_INTEGRITY','Nonempty run without RUN record.');
 g2_trajectory_record('write',rf,struct('schema','NewMetacomp.G2.A1.Run.v1','token',C.token,'sourceCommit',C.preflight.sourceCommit));
end
try
 g2_lp1_admit_state(sd,freeRAM(),@()admitHook(lroot,Camp,G.campaignId,key));
 addpath(fullfile(C.here,'vendor_p010_a14d8872'),'-begin');
 pm=jsondecode(fileread(fullfile(C.here,'G2_MATERIAL_POLICY_v1.json')));g=lp.geometry;
 PM=g2_material_phase_map(D.X6,D.T6,g.centres_mm,6.35*ones(3,1),19.05*ones(3,1),struct('onCircleTol_mm', ...
  pm.phaseMap.onCircleTolerance_mm,'minGap_mm',pm.phaseMap.minGapToNextT3Vertex_mm,'midsideTol_mm',pm.phaseMap.midsideOnChordTolerance_mm));
 assert(PM.pass,'G2A1:HOLD_OWNER_MASK','Phase map failed.');
 act=g2_m4b_ring_activation(PM.annulusOf,reshape(c.mask,1,3));
 Em=lp.bvp.E_MPa;mk=@(E)struct('E',E,'nu',lp.bvp.nu,'plane','stress');
 expect=struct('P_N',1,'thickness_mm',12.7,'load_mm',[254 203.2],'E_matrix',Em);
 polT=jsondecode(fileread(fullfile(C.here,'G2_TRAJECTORY_POLICY_v1.json')));
 [~,m0]=memory;[u0,~]=memory;t0=tic;
 K=g2_m4b_sif_partial(D,act,[mk(Em),mk(Em*c.ratio)],polT,PM,expect);
 seconds=toc(t0);[u1,m1]=memory;O.computed=1;
 res=struct('seconds',seconds,'availableBefore_GiB',m0.PhysicalMemory.Available/2^30, ...
  'availableAfter_GiB',m1.PhysicalMemory.Available/2^30,'matlabUsedBefore_GiB',u0.MemUsedMATLAB/2^30, ...
  'matlabUsedAfter_GiB',u1.MemUsedMATLAB/2^30);
 S=struct('schema','NewMetacomp.G2.A1.Solution.v1','key',key,'caseId',c.id,'level',o.Level, ...
  'meshContentSHA256',pol.meshes.(key).contentSHA256,'policySHA256',C.policySHA256,'sourceSHA256',C.sourceSHA256, ...
  'K',K,'resources',res,'mesh',V.summary);
 sh=lower(g2_trajectory_record('write',fullfile(sd,'SOLUTION.mat'),S));
 assert(K.pass,'G2A1:HOLD_K_EXTRACTION','Failed SIF gates: %s',strjoin(K.failedCriteria,','));
 Mt=g2_mts_direction(K.KI,K.KII);assert(Mt.admissibleForStep,'G2A1:HOLD_K_EXTRACTION','MTS root not admissible.');
 St=struct('schema','NewMetacomp.G2.A1.State.v1','key',key,'caseId',c.id,'level',o.Level, ...
  'meshContentSHA256',pol.meshes.(key).contentSHA256,'policySHA256',C.policySHA256,'sourceSHA256',C.sourceSHA256, ...
  'solutionSHA256',sh,'KI',K.KI,'KII',K.KII,'J',K.J,'G',hypot(K.KI,K.KII)^2/Em,'MTS_deg',Mt.theta_deg, ...
  'KI_COD',K.KI_COD,'KII_COD',K.KII_COD,'EDI_all',K.EDI_all,'resources',res,'mesh',V.summary, ...
  'physicalFractureGrowthProven',false);
 g2_trajectory_record('write',statefile,St);O.state=St;O.status='A1_STATE_COMPLETE';
catch ME
 O.status='HOLD';O.hold=struct('identifier',ME.identifier,'message',ME.message);
 pre=strcmp(ME.identifier,'G2LP1:HOLD_MEMORY')&&~isfolder(sd);
 camp=startsWith(ME.identifier,'G2LP1:HOLD_CAMPAIGN_')&&~isfolder(sd);
 hold=struct('schema','NewMetacomp.G2.A1.Hold.v1','key',key,'identifier',ME.identifier,'message',ME.message,'physicalArrest',false);
 if pre
  g2_lp1_campaign_ledger('write',lroot,'HOLD',sprintf('HOLD_PREADMISSION_MEMORY_%s_%s.mat',key,datestr(now,'yyyymmddTHHMMSSFFF')), ...
   struct('campaignId',G.campaignId,'caseId',c.id,'stateIndex',o.Level,'hold',hold));
 elseif ~camp
  if ~isfolder(sd),mkdir(sd);end
  hf=fullfile(sd,'HOLD.mat');if ~isfile(hf),g2_trajectory_record('write',hf,hold);end
 end
 fprintf(2,'G2_A1_HOLD %s %s: %s\n',key,ME.identifier,ME.message);return
end
% closure once all twelve preregistered states exist
keys=sort(fieldnames(pol.meshes));sf=cellfun(@(k)fullfile(rd,k,'STATE.mat'),keys,'UniformOutput',false);
if all(cellfun(@isfile,sf))&&~isfile(fullfile(lroot,'CLOSED.mat'))
 shs=cell(size(sf));for z=1:numel(sf),[~,shs{z},okz]=g2_trajectory_record('read',sf{z});assert(okz,'G2A1:HOLD_RECORD_INTEGRITY','State failed verification.');end
 g2_lp1_campaign_ledger('write',lroot,'CLOSED','CLOSED.mat',struct('campaignId',G.campaignId,'runName',o.RunName, ...
  'keys',{keys},'stateSHA256',{lower(shs)},'closedUTC',utcNow()));
 O.campaignClosed=true;
end
end

function admitHook(lroot,Camp,cid,key)
assert(~strcmp(Camp.mode,'VERIFY_ONLY'),'G2LP1:HOLD_CAMPAIGN_CLOSED','Campaign is closed: no new state may be computed.');
L=g2_lp1_campaign_ledger('snapshot',lroot);
assert(numel(L.admits)<12,'G2A1:HOLD_UNAUTHORIZED_STATE','The twelve-solve ceiling is reached.');
name=sprintf('ADMIT_%s.mat',key);
assert(~isfile(fullfile(lroot,name)),'G2LP1:HOLD_CAMPAIGN_INTEGRITY','Admitted state folder is missing; review required.');
g2_lp1_campaign_ledger('write',lroot,'ADMIT',name,struct('campaignId',cid,'stateKey',key,'admittedUTC',utcNow()));
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
