function O=g2_m5x6_run(varargin)
%G2_M5X6_RUN  Bounded M5-X6 crossed S4 B9 solve: one preregistered configuration per call.
%
%  O = g2_m5x6_run('Config','X6-01')                                   % dry (default): no write, no FEM
%  O = g2_m5x6_run('Config','X6-01','Run',true,'AuthToken',tok,'RunName',name)   % needs GO_M5_X6
% Configurations (G2_M5_X6_PLAN_v1.json): the H path with each architecture material and each
% architecture path with H material, all on the qualified A1 Family B m = 9 meshes. The solve
% block is the unchanged A1 chain (g2_a1_run): mesh SHA + g2_a1_mesh_validate ->
% g2_material_phase_map -> g2_m4b_ring_activation -> g2_m4b_sif_partial, with the PATH-case mesh
% and the MATERIAL-case mask and ratio. Authorization: hard-coded GO (g2_m5x6_scientific_gate),
% token, and the unchanged VG2 campaign machinery under outputs/g2_m5x6_campaign_ledger/<id>/.
% At most six admissions; no resumption; any HOLD stops the configuration and is never retried.
ip=inputParser;addParameter(ip,'Config','X6-01',@ischar);addParameter(ip,'Run',false,@islogical);
addParameter(ip,'AuthToken','',@ischar);
addParameter(ip,'RunName','run_m5x6_not_authorized',@(s)ischar(s)&&~isempty(regexp(s,'^run_[a-zA-Z0-9_]+$','once')));
parse(ip,varargin{:});o=ip.Results;
C=g2_m5x6_context();
ix=find(strcmp({C.configurations.id},o.Config));
assert(isscalar(ix),'G2M5X6:HOLD_INPUT','Only the six preregistered configurations X6-01 ... X6-06 are permitted.');
cfg=C.configurations(ix);key=cfg.key;
if ~o.Run
 Q=g2_m5x6_configuration_check(C,cfg);
 O=struct('status','DRY_READY_NO_FEM','computed',0,'reused',0,'config',cfg.id,'key',key,'token',C.token, ...
  'check',rmfield(Q,{'D','PM','act','mats','meshValidation','lp'}));
 return
end
% ------------------------------------------------------------------ authorized path only
G=g2_m5x6_scientific_gate(C);
assert(strcmp(o.AuthToken,C.token),'G2M5X6:HOLD_SOURCE','Token does not bind the M5-X6 plan, sources and meshes.');
O=struct('status','','computed',0,'reused',0,'config',cfg.id,'key',key,'token',C.token);
rd=fullfile(C.repo,'outputs','g2_m5x6_crossed_v1',o.RunName);sd=fullfile(rd,key);
lroot=fullfile(C.repo,'outputs','g2_m5x6_campaign_ledger',G.campaignId);
Camp=g2_lp1_campaign_validate(struct('approvedRunName',G.approvedRunName,'campaignId',G.campaignId, ...
 'campaignScope',G.campaignScope),o.RunName,G.goFileSHA256,C.token, ...
 g2_lp1_campaign_ledger('snapshot',lroot),runFolderFacts(rd,C.token),[]);
O.campaignMode=Camp.mode;O.campaignId=G.campaignId;
statefile=fullfile(sd,'STATE.mat');
if strcmp(Camp.mode,'VERIFY_ONLY')
 assert(isfile(statefile),'G2LP1:HOLD_CAMPAIGN_CLOSED','Campaign is closed: no new state may be computed.');
end
Q=g2_m5x6_configuration_check(C,cfg);
if isfile(statefile)
 [St,~,ok]=g2_trajectory_record('read',statefile);
 assert(ok&&strcmp(St.key,key)&&strcmp(St.meshContentSHA256,cfg.meshContentSHA256)&&strcmp(St.token,C.token), ...
  'G2M5X6:HOLD_RECORD_INTEGRITY','Saved M5-X6 state differs.');
 O.reused=1;O.status='REUSED_ZERO_SOLVE';O.state=St;return
end
if strcmp(Camp.mode,'OPEN_NEW')
 g2_lp1_campaign_ledger('write',lroot,'RECEIPT','RECEIPT.mat',struct('campaignId',G.campaignId,'runName',o.RunName, ...
  'goSHA256',G.goFileSHA256,'token',C.token,'sourceCommit',C.preflight.sourceCommit,'openedUTC',utcNow()));
end
if ~isfolder(rd),mkdir(rd);end
rf=fullfile(rd,'RUN.mat');
if isfile(rf)
 [rr,~,ok]=g2_trajectory_record('read',rf);assert(ok&&strcmp(rr.token,C.token),'G2M5X6:HOLD_SOURCE','Run token drift.');
else
 assert(numel(dir(rd))<=2,'G2M5X6:HOLD_RECORD_INTEGRITY','Nonempty run without RUN record.');
 g2_trajectory_record('write',rf,struct('schema','NewMetacomp.G2.M5X6.Run.v1','token',C.token,'sourceCommit',C.preflight.sourceCommit));
end
try
 g2_lp1_admit_state(sd,freeRAM(),@()g2_m5x6_admit_hook(lroot,Camp,G.campaignId,key));
 lp=Q.lp;polT=jsondecode(fileread(fullfile(C.g2,'G2_TRAJECTORY_POLICY_v1.json')));
 expect=struct('P_N',1,'thickness_mm',12.7,'load_mm',[254 203.2],'E_matrix',Q.Em);
 [~,m0]=memory;[u0,~]=memory;t0=tic;
 K=g2_m4b_sif_partial(Q.D,Q.act,Q.mats,polT,Q.PM,expect);
 seconds=toc(t0);[u1,m1]=memory;O.computed=1;
 res=struct('seconds',seconds,'availableBefore_GiB',m0.PhysicalMemory.Available/2^30, ...
  'availableAfter_GiB',m1.PhysicalMemory.Available/2^30,'matlabUsedBefore_GiB',u0.MemUsedMATLAB/2^30, ...
  'matlabUsedAfter_GiB',u1.MemUsedMATLAB/2^30);
 S=struct('schema','NewMetacomp.G2.M5X6.Solution.v1','key',key,'config',cfg.id,'pathCase',cfg.pathCase, ...
  'materialCase',cfg.materialCase,'mask',Q.act.mask,'ratio',cfg.ratio,'meshContentSHA256',cfg.meshContentSHA256, ...
  'planSHA256',C.planSHA256,'a1SourceSHA256',C.a1SourceSHA256,'x6SourceSHA256',C.x6SourceSHA256,'token',C.token, ...
  'K',K,'resources',res,'mesh',Q.meshValidation.summary);
 sh=lower(g2_trajectory_record('write',fullfile(sd,'SOLUTION.mat'),S));
 assert(K.pass,'G2M5X6:HOLD_K_EXTRACTION','Failed SIF gates: %s',strjoin(K.failedCriteria,','));
 Mt=g2_mts_direction(K.KI,K.KII);assert(Mt.admissibleForStep,'G2M5X6:HOLD_K_EXTRACTION','MTS root not admissible.');
 Au=swappedMaterialAudit(K,Q,cfg);
 assert(Au.pass,'G2M5X6:HOLD_ACTIVATION','Swapped-material audit failed: %s',strjoin(Au.failed,','));
 St=struct('schema','NewMetacomp.G2.M5X6.State.v1','key',key,'config',cfg.id,'pathCase',cfg.pathCase, ...
  'materialCase',cfg.materialCase,'mask',Q.act.mask,'ratio',cfg.ratio,'meshContentSHA256',cfg.meshContentSHA256, ...
  'planSHA256',C.planSHA256,'a1SourceSHA256',C.a1SourceSHA256,'x6SourceSHA256',C.x6SourceSHA256,'token',C.token, ...
  'solutionSHA256',sh,'KI',K.KI,'KII',K.KII,'J',K.J,'G',hypot(K.KI,K.KII)^2/Q.Em,'MTS_deg',Mt.theta_deg, ...
  'KI_COD',K.KI_COD,'KII_COD',K.KII_COD,'EDI_all',K.EDI_all,'compliance_mm_per_N',K.compliance_mm_per_N, ...
  'swappedMaterialAudit',Au,'resources',res,'mesh',Q.meshValidation.summary,'physicalFractureGrowthProven',false);
 g2_trajectory_record('write',statefile,St);O.state=St;O.status='M5X6_STATE_COMPLETE';
catch ME
 O.status='HOLD';O.hold=struct('identifier',ME.identifier,'message',ME.message);
 pre=strcmp(ME.identifier,'G2LP1:HOLD_MEMORY')&&~isfolder(sd);
 camp=(startsWith(ME.identifier,'G2LP1:HOLD_CAMPAIGN_')||contains(ME.message,'six-solve ceiling'))&&~isfolder(sd);
 hold=struct('schema','NewMetacomp.G2.M5X6.Hold.v1','key',key,'identifier',ME.identifier,'message',ME.message,'physicalArrest',false);
 if pre
  g2_lp1_campaign_ledger('write',lroot,'HOLD',sprintf('HOLD_PREADMISSION_MEMORY_%s_%s.mat',key,datestr(now,'yyyymmddTHHMMSSFFF')), ...
   struct('campaignId',G.campaignId,'caseId',cfg.id,'stateIndex',ix,'hold',hold));
 elseif ~camp
  if ~isfolder(sd),mkdir(sd);end
  hf=fullfile(sd,'HOLD.mat');if ~isfile(hf),g2_trajectory_record('write',hf,hold);end
 end
 fprintf(2,'G2_M5X6_HOLD %s %s: %s\n',key,ME.identifier,ME.message);return
end
% closure once all six preregistered states exist
keys={C.configurations.key};sf=cellfun(@(k)fullfile(rd,k,'STATE.mat'),keys,'UniformOutput',false);
if all(cellfun(@isfile,sf))&&~isfile(fullfile(lroot,'CLOSED.mat'))
 shs=cell(size(sf));for z=1:numel(sf),[~,shs{z},okz]=g2_trajectory_record('read',sf{z});assert(okz,'G2M5X6:HOLD_RECORD_INTEGRITY','State failed verification.');end
 g2_lp1_campaign_ledger('write',lroot,'CLOSED','CLOSED.mat',struct('campaignId',G.campaignId,'runName',o.RunName, ...
  'keys',{keys},'stateSHA256',{lower(shs)},'closedUTC',utcNow()));
 O.campaignClosed=true;
end
end

function Au=swappedMaterialAudit(K,Q,cfg)
% Independent post-solve confirmation that the solved material is the MATERIAL case on the PATH mesh.
act=Q.act;M=numel(act.phaseForAssembly);on=act.activeRings(:).';ringA=Q.ringArea_mm2(:).';
c=struct();
c.phaseCounts=isequal(K.phaseCounts(:).',[M-act.activeElements,act.activeElements]);
if isempty(on)
 c.activeArea=K.activeArea_mm2==0;c.modulusRatio=K.phaseDminEig(2)==K.phaseDminEig(1);
 c.phaseTwoEnergy=K.phaseStrainEnergy_per_thickness(2)==0;
else
 c.activeArea=abs(K.activeArea_mm2-sum(ringA(on)))<=1e-12*sum(ringA(on));
 c.modulusRatio=abs(K.phaseDminEig(2)/K.phaseDminEig(1)-cfg.ratio)<=1e-12;
 c.phaseTwoEnergy=K.phaseStrainEnergy_per_thickness(2)>0;
end
c.ringEnergySum=abs(sum(K.ringStrainEnergy_per_thickness)/K.strainEnergy_per_thickness-1)<=1e-10;
c.interfaceGating=isequal(logical(K.interfaceSideL2Gated(:).'),ismember(1:3,on))&&numel(K.activeRingResultantRel)==numel(on);
v=cell2mat(struct2cell(c));f=fieldnames(c);
Au=struct('pass',all(v),'checks',c,'failed',{f(~v)});
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
