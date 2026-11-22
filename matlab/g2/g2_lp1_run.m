function O=g2_lp1_run(varargin)
% Four bounded own-S0 paths. Default dry writes nothing and performs no FEM.
ip=inputParser;addParameter(ip,'Case','H',@ischar);addParameter(ip,'MaxStateIndex',4,@isnumeric);
addParameter(ip,'Run',false,@islogical);addParameter(ip,'AuthToken','',@ischar);
addParameter(ip,'RunName','run_20261122_lp1_v1',@(s)ischar(s)&&~isempty(regexp(s,'^run_[a-zA-Z0-9_]+$','once')));
addParameter(ip,'InterruptAfterReview',-1,@isnumeric);parse(ip,varargin{:});o=ip.Results;
assert(isscalar(o.MaxStateIndex)&&isfinite(o.MaxStateIndex)&&o.MaxStateIndex>=0&&o.MaxStateIndex<=4&&o.MaxStateIndex==fix(o.MaxStateIndex), ...
 'G2LP1:HOLD_UNAUTHORIZED_STATE','Only S0-S4 permitted.');
C=g2_lp1_context();pol=C.policy;ids={pol.cases.id};ix=find(strcmp(ids,o.Case));
assert(isscalar(ix),'G2LP1:HOLD_INPUT','Exactly H, stiff13, soft2, soft1 permitted.');c=pol.cases(ix);
O=struct('status','DRY_READY_NO_FEM','computed',0,'reused',0,'promoted',0,'caseId',c.id,'lastState',-1,'token',C.token,'states',{{}},'campaignComplete',false);
if ~o.Run,return,end
% A self-generated token and LP0 geometry pass cannot authorize FEM.
g2_lp1_scientific_gate(C);
assert(strcmp(o.AuthToken,C.token),'G2LP1:HOLD_SOURCE','Token does not bind policy, source, geometry qualification and case caps.');
rd=fullfile(C.repo,pol.runRoot,o.RunName);chain=fullfile(rd,c.id);
% H S0-S2 must be completed before any material-contrast case begins.
if ~strcmp(c.id,'H')
 hf=fullfile(rd,'H','S2','STATE.mat');
 assert(isfile(hf),'G2LP1:HOLD_UNAUTHORIZED_STATE', ...
  'Homogeneous H S0-S2 must be accepted first.');
 [hs,~,hok]=g2_trajectory_record('read',hf);
 assert(hok&&strcmp(hs.caseId,'H')&&hs.stateIndex==2&& ...
  isempty(dir(fullfile(rd,'H','**','HOLD.mat'))), ...
  'G2LP1:HOLD_RECORD_INTEGRITY','Homogeneous reference is incomplete or held.');
end
if isfolder(chain)&&~isempty(dir(fullfile(chain,'**','HOLD.mat'))),error('G2LP1:HOLD_RECORD_INTEGRITY','HOLD chain cannot be reused.');end
if o.MaxStateIndex>2
 for z=1:4
  sf=fullfile(rd,ids{z},'S2','STATE.mat');
  assert(isfile(sf)&&isempty(dir(fullfile(rd,ids{z},'**','HOLD.mat'))), ...
   'G2LP1:HOLD_UNAUTHORIZED_STATE','All four S0-S2 chains must qualify before any S3.');
  [ss,~,sok]=g2_trajectory_record('read',sf);
  assert(sok&&strcmp(ss.caseId,ids{z})&&ss.stateIndex==2, ...
   'G2LP1:HOLD_RECORD_INTEGRITY','Missing or altered S2 state record.');
 end
end
if ~isfolder(rd),mkdir(rd);end
rf=fullfile(rd,'RUN.mat');
if isfile(rf)
 [rr,~,ok]=g2_trajectory_record('read',rf);assert(ok&&strcmp(rr.token,C.token),'G2LP1:HOLD_SOURCE','Campaign token drift.');
else
 assert(numel(dir(rd))<=2,'G2LP1:HOLD_RECORD_INTEGRITY','Nonempty run without RUN record.');
 g2_trajectory_record('write',rf,struct('schema','NewMetacomp.G2.LP1.Run.v1','token',C.token,'sourceCommit',C.preflight.sourceCommit,'sourceLines',{C.sourceLines}));
end
if ~isfolder(chain),mkdir(chain);end
addpath(fullfile(C.here,'vendor_p010_a14d8872'),'-begin');
polT=jsondecode(fileread(fullfile(C.here,'G2_TRAJECTORY_POLICY_v1.json')));
P=pol.startPolyline_mm;t=[0 1];parentHash=g2_lp1_digest([C.token,'|',c.id,'|S0']);parent=[];geom=[];
for k=0:o.MaxStateIndex
 sd=fullfile(chain,sprintf('S%d',k));
 clearance=struct('pass',false,'status','NOT_EVALUATED','reasons',{{}},'metrics',struct());
 try
  if k>0
   F=g2_lp1_forecast(parent,pol);P=F.polyline_mm;t=F.tangent;
   clearance=g2_lp0_clearance(P(1:end-1,:),P(end,:),geom,pol);
   assert(clearance.pass,['G2LP1:',clearance.status],'%s',strjoin(clearance.reasons,','));
  else,clearance=struct('pass',true,'status','INITIAL_S0','metrics',struct());end
  revfile=fullfile(sd,'REVIEW.mat');statefile=fullfile(sd,'STATE.mat');meshfile=fullfile(sd,'MESH.mat');
  if isfile(revfile)
   [R,rh,ok]=g2_trajectory_record('read',revfile);rh=lower(rh);assert(ok,'G2LP1:HOLD_RECORD_INTEGRITY','Review bytes changed.');
   assert(strcmpi(g2_sha256_file(meshfile),R.meshSHA256),'G2LP1:HOLD_RECORD_INTEGRITY','Mesh bytes changed.');D=load(meshfile);
   assert(isequal(D.crackPolyline,P)&&isequal(D.tipTangent,t),'G2LP1:HOLD_RECORD_INTEGRITY','Mesh geometry drift.');
   [A,PM]=g2_lp1_audit(D,k,C);geom=A.clearanceGeometry;
   [Ph,ph,ok]=g2_trajectory_record('read',fullfile(sd,'PHASE.mat'));
   assert(ok&&strcmpi(ph,R.phaseSHA256)&&strcmp(Ph.meshSHA256,R.meshSHA256)&&isequal(Ph.owner,PM.annulusOf)&& ...
    isequal(Ph.mask,reshape(c.mask,1,3)),'G2LP1:HOLD_OWNER_MASK','Phase record drift.');
   act=g2_m4b_ring_activation(PM.annulusOf,reshape(c.mask,1,3));
   assert(isequal(act.phaseForAssembly,Ph.labels),'G2LP1:HOLD_OWNER_MASK','Wrong activity labels.');
   [S,sh,ok]=g2_trajectory_record('read',fullfile(sd,'SOLUTION.mat'));
   assert(ok&&strcmpi(sh,R.solutionSHA256),'G2LP1:HOLD_RECORD_INTEGRITY','Solution bytes changed.');
   g2_lp1_validate_links(R,S,c,k,P,t,C.policySHA256,C.sourceSHA256,parentHash);
   if k>0
    again=g2_lp0_clearance(P(1:end-1,:),P(end,:),geom,pol);assert(again.pass,['G2LP1:',again.status],'Actual polygon clearance.');
   end
   wanted=R;wanted.schema='NewMetacomp.G2.LP1.State.v1';wanted.reviewSHA256=rh;
   if isfile(statefile)
    [St,sth,ok]=g2_trajectory_record('read',statefile);
    assert(ok&&isequaln(St,wanted),'G2LP1:HOLD_RECORD_INTEGRITY','State differs from qualified review.');O.reused=O.reused+1;
   else
    St=wanted;sth=g2_trajectory_record('write',statefile,St);O.promoted=O.promoted+1;
   end
  else
   assert(~isfolder(sd),'G2LP1:HOLD_RECORD_INTEGRITY','Partial unreviewed state is preserved, never retried.');
   mkdir(sd);resource();
   if k==0
    src=fullfile(C.repo,'outputs/g2_protected_mesh/run_20261118_165922_343_famA/GEOMETRY_ONLY_candidate.mat');
    D=load(src);[D,Ad]=g2_m2_state_adapter(D,'S0',P);assert(Ad.pass,'G2LP1:HOLD_OWNER_MASK','S0 adapter.');
   else
    opts={'BottomVertices_mm',[25.4 482.6],'TopVertices_mm',254,'TipGuideRadius_mm',15,'TipGuideHface_mm',1.5};
    D=g2_kinked_join(P,'ExpectedVertices',k+2,'ExpectedTangent',t,'ExteriorOptions',opts,'MaxT3Elements',40000);
    if ~D.pass
     failedMesh=D;save(fullfile(sd,'FAILED_MESH.mat'),'failedMesh','-v7.3');
     error('G2LP1:HOLD_MESH_QUALITY','%s %s',D.stage,D.message);
    end
    D.tipTangent=t;
   end
   save(meshfile,'-struct','D','-v7.3');mh=lower(g2_sha256_file(meshfile));D=load(meshfile);
   [A,PM]=g2_lp1_audit(D,k,C);geom=A.clearanceGeometry;
   if k>0
    clearance=g2_lp0_clearance(P(1:end-1,:),P(end,:),geom,pol);
    assert(clearance.pass,['G2LP1:',clearance.status],'%s',strjoin(clearance.reasons,','));
   end
   act=g2_m4b_ring_activation(PM.annulusOf,reshape(c.mask,1,3));
   Ph=struct('schema','NewMetacomp.G2.LP1.Phase.v1','stateIndex',k,'caseId',c.id,'mask',reshape(c.mask,1,3), ...
    'meshSHA256',mh,'owner',PM.annulusOf,'labels',act.phaseForAssembly,'audit',A);
   ph=lower(g2_trajectory_record('write',fullfile(sd,'PHASE.mat'),Ph));
   resource();Em=pol.bvp.E_MPa;mk=@(E)struct('E',E,'nu',pol.bvp.nu,'plane','stress');
   expect=struct('P_N',1,'thickness_mm',12.7,'load_mm',[254 203.2],'E_matrix',Em);
   K=g2_m4b_sif_partial(D,act,[mk(Em),mk(Em*c.ratio)],polT,PM,expect);O.computed=O.computed+1;
   S=struct('schema','NewMetacomp.G2.LP1.Solution.v1','stateIndex',k,'caseId',c.id,'meshSHA256',mh,'phaseSHA256',ph, ...
    'policySHA256',C.policySHA256,'sourceSHA256',C.sourceSHA256,'K',K);
   sh=lower(g2_trajectory_record('write',fullfile(sd,'SOLUTION.mat'),S));
   assert(K.pass,'G2LP1:HOLD_K_EXTRACTION','Failed SIF gates: %s',strjoin(K.failedCriteria,','));
   M=g2_mts_direction(K.KI,K.KII);assert(M.admissibleForStep&&M.stationarityResidual_rel<=1e-12,'G2LP1:HOLD_K_EXTRACTION','MTS root.');
   reg=regressH(c.id,k,P,K,C);
   R=struct('schema','NewMetacomp.G2.LP1.Review.v1','stateIndex',k,'caseId',c.id,'mask',reshape(c.mask,1,3),'ratio',c.ratio, ...
    'policySHA256',C.policySHA256,'sourceSHA256',C.sourceSHA256,'parentSHA256',parentHash,'sourceCommit',C.preflight.sourceCommit, ...
    'polyline_mm',P,'tangent',t,'normal',[-t(2),t(1)],'arc_mm',sum(vecnorm(diff(P),2,2)), ...
    'KI',K.KI,'KII',K.KII,'EDI_all',K.EDI_all,'MTS_deg',M.theta_deg,'G',hypot(K.KI,K.KII)^2/Em, ...
    'meshSHA256',mh,'phaseSHA256',ph,'solutionSHA256',sh,'clearance',clearance,'Hregression',reg, ...
    'physicalFractureGrowthProven',false);
   g2_lp1_validate_links(R,S,c,k,P,t,C.policySHA256,C.sourceSHA256,parentHash);
   rh=lower(g2_trajectory_record('write',revfile,R));
   if o.InterruptAfterReview==k,O.status='INTERRUPTED_AFTER_REVIEW';return,end
   St=R;St.schema='NewMetacomp.G2.LP1.State.v1';St.reviewSHA256=rh;
   sth=lower(g2_trajectory_record('write',statefile,St));
  end
  O.lastState=k;O.states{end+1}=St;parent=St;parentHash=lower(sth);
  fprintf('G2_LP1_ACCEPTED %s S%d s=%.10f KI=%.12g KII=%+.12g\n',c.id,k,St.arc_mm,St.KI,St.KII);
  clear D A PM Ph S K R
 catch ME
  if ~isfolder(sd),mkdir(sd);end
  stopCode='HOLD_RECORD_INTEGRITY';
  if startsWith(ME.identifier,'G2LP1:HOLD_'),stopCode=extractAfter(ME.identifier,'G2LP1:');end
  if ~clearance.pass&&startsWith(clearance.status,'HOLD_'),stopCode=clearance.status;end
  hold=struct('schema','NewMetacomp.G2.LP1.Hold.v1','stateIndex',k,'caseId',c.id, ...
   'identifier',ME.identifier,'stopCode',char(stopCode),'geometryReasons',{clearance.reasons}, ...
   'geometryMetrics',clearance.metrics,'message',ME.message, ...
   'parentSHA256',parentHash,'physicalArrest',false);
  hf=fullfile(sd,'HOLD.mat');if ~isfile(hf),g2_trajectory_record('write',hf,hold);end
  O.status='HOLD';O.hold=hold;fprintf(2,'G2_LP1_HOLD %s S%d %s: %s\n',c.id,k,ME.identifier,ME.message);return
 end
end
% Only a separate four-case campaign audit can issue REVIEW_STOP_LP1.
O.status='CASE_S4_COMPLETE_AWAIT_CAMPAIGN_REVIEW';
if o.MaxStateIndex<4,O.status='BOUNDED_PREFIX_COMPLETE';end
end

function resource()
[~,s]=memory;assert(s.PhysicalMemory.Available/2^30>=5,'G2LP1:HOLD_MEMORY','Less than 5 GiB free physical RAM; no automatic retry.');
end
function R=regressH(id,k,P,K,C)
R=struct('applicable',strcmp(id,'H')&&k<=2,'pass',true);if ~R.applicable,return,end
f=fullfile(C.repo,'outputs/g2_material_evolution_v1/run_20261121_132226_301',sprintf('CASE_S%d_H1.mat',k));
B=load(f,'record');B=B.record;
if k==0,Q=C.policy.startPolyline_mm;
elseif k==1,D=load(fullfile(C.repo,'outputs/g2_wp3_state/run_20261118_185808_963/step1_a/KINKED_GEOMETRY_ONLY_candidate.mat'),'crackPolyline');Q=D.crackPolyline;
else,D=load(fullfile(C.repo,'outputs/g2_trajectory_chain_v1_attempt2/STEP_002/KINKED_GEOMETRY_ONLY_candidate.mat'),'crackPolyline');Q=D.crackPolyline;end
R.coordinateError_mm=max(abs(P-Q),[],'all');R.Kerror=max(abs([K.KI-B.KI_raw,K.KII-B.KII_raw]))/hypot(B.KI_raw,B.KII_raw);
R.Gerror=abs((K.KI^2+K.KII^2)/(B.KI_raw^2+B.KII_raw^2)-1);m=g2_mts_direction(K.KI,K.KII);b=g2_mts_direction(B.KI_raw,B.KII_raw);R.MTSerror_deg=abs(m.theta_deg-b.theta_deg);
t=C.policy.homogeneousRegression;R.pass=R.coordinateError_mm<=t.coordinateAbs_mm&&R.Kerror<=t.KRelativeToHypot&&R.Gerror<=t.GRelative&&R.MTSerror_deg<=t.MTSAbs_deg;
assert(R.pass,'G2LP1:HOLD_BASELINE_REGRESSION','H S%d regression: %s',k,jsonencode(R));
end
