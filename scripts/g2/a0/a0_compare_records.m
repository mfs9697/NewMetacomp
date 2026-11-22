function R=a0_compare_records(histRoot,newRoot,outFile,mode)
%A0_COMPARE_RECORDS Read-only comparison of A0 records against the 20 historical LP1 states (Issue #60).
%   R = a0_compare_records(histRoot,newRoot,outFile)            % normal A0 comparison
%   R = a0_compare_records(histRoot,histRoot,outFile,'selftest') % dry validation, no new records
% Plain LOAD of saved records only; no project function, mesher, solver or record
% writer. Preregistered tiers (G2_LP1_A0_PREREGISTRATION_UA.md, section 5):
%   A EXACT       every numerical array bitwise equal; integer arrays equal
%   B ROUNDOFF    integer arrays equal; |dK|/|K|<=1e-10, |dG|/G<=2e-10, |dMTS|<=1e-8 deg,
%                 coordinates <=1e-8 mm, other graded fields rel<=1e-8
%   C EQUIVALENT  within the v2 regression limits for every case (1e-5 mm, |dK|/|K|<=1e-5,
%                 |dG|/G<=2e-5, |dMTS|<=1e-3 deg), |dF_G|<=4e-5, |dd|<=1e-5 mm, S4 classes unchanged
%   D NOT REPRODUCED  anything else, or any invariant mismatch, or a missing state
% Provenance fields are EXPECTED to differ in a genuine A0 run (source set, commit,
% parent chain, MAT byte hashes, token); they are checked for self-consistency instead.
if nargin<4,mode='compare';end
selftest=strcmp(mode,'selftest');
assert(~isfile(outFile),'A0:Output','Refusing to overwrite %s',outFile);
cases={'H','stiff13','soft2','soft1'};
H=loadSet(histRoot);
if selftest,N=H;else,N=loadSet(newRoot);end
R=struct('schema','NewMetacomp.G2.LP1.A0.Comparison.v1','mode',mode,'states',[], ...
 'noFEM',true,'noMesh',true,'noRecordWritten',true);
rows=compareSets(H,N,cases,selftest);
R.states=rows;R.worstTier=worstTier({rows.tier});
R.classesHistorical=s4classes(H,cases);R.classesNew=s4classes(N,cases);
R.classesUnchanged=isequal(rmfield(R.classesHistorical,'numbers'),rmfield(R.classesNew,'numbers'));
[R.classesNew.maxAbsDeltaFG,R.classesNew.maxAbsDeltaOffset_mm]=pathDeltas(H,N,cases);
R.provenance=provenance(N,newRoot,selftest);
R.verdict=verdict(R);
if selftest
 R.perturbationTests=perturbationTests(H,cases);
 R.selftestPass=strcmp(R.verdict,'A0_REPRODUCED_EXACT')&&all([R.perturbationTests.pass]);
end
fid=fopen(outFile,'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
fprintf('A0_COMPARE mode=%s worstTier=%s verdict=%s classesUnchanged=%d\n',mode,R.worstTier,R.verdict,R.classesUnchanged);
if selftest,fprintf('A0_COMPARE_SELFTEST pass=%d perturbations=%d/%d\n',R.selftestPass, ...
  nnz([R.perturbationTests.pass]),numel(R.perturbationTests));end
end

% ------------------------------------------------------------------ loading
function S=loadSet(root)
assert(isfolder(root),'A0:Input','Run root not found.');
S=struct();cases={'H','stiff13','soft2','soft1'};
for c=1:4
 for k=0:4
  d=fullfile(root,cases{c},sprintf('S%d',k));e=struct('present',false);
  if isfile(fullfile(d,'STATE.mat'))
   e.present=true;
   a=load(fullfile(d,'STATE.mat'));e.st=a.record;
   a=load(fullfile(d,'REVIEW.mat'));e.rv=a.record;
   a=load(fullfile(d,'SOLUTION.mat'));e.sol=a.record;
   a=load(fullfile(d,'PHASE.mat'));e.ph=a.record;
   e.mesh=load(fullfile(d,'MESH.mat'),'T3','X3','T6','X6','crackPolyline','tipTangent');
   e.fileSHA=struct('MESH',fsha(fullfile(d,'MESH.mat')),'PHASE',fsha(fullfile(d,'PHASE.mat')), ...
    'SOLUTION',fsha(fullfile(d,'SOLUTION.mat')),'REVIEW',fsha(fullfile(d,'REVIEW.mat')),'STATE',fsha(fullfile(d,'STATE.mat')));
  end
  S.(sprintf('%s_S%d',cases{c},k))=e;
 end
end
a=load(fullfile(root,'RUN.mat'));S.RUN=a.record;
end

% ------------------------------------------------------------------ comparison
function rows=compareSets(H,N,cases,selftest)
rows=struct('state',{},'tier',{},'invariantFailures',{},'maxDiff',{},'reasons',{},'integerArraysEqual',{});
for c=1:4
 for k=0:4
  key=sprintf('%s_S%d',cases{c},k);rows(end+1)=compareState(key,H.(key),N.(key),selftest); %#ok<AGROW>
 end
end
end

function r=compareState(key,h,n,~)
r=struct('state',key,'tier','D','invariantFailures',{{}},'maxDiff',struct(),'reasons',{{}},'integerArraysEqual',false);
if ~h.present||~n.present,r.reasons={'missing state'};return,end
inv={};
for f={'policySHA256','caseId','mask','ratio','stateIndex','physicalFractureGrowthProven'}
 if ~isequal(h.st.(f{1}),n.st.(f{1})),inv{end+1}=f{1};end %#ok<AGROW>
end
if ~isequal(h.st.clearance.status,n.st.clearance.status),inv{end+1}='clearance.status';end
if ~isequal(n.rv.KI,n.st.KI)||~isequal(n.rv.polyline_mm,n.st.polyline_mm),inv{end+1}='REVIEW!=STATE';end
if ~(isequal(n.sol.K.pass,true)&&isempty(n.sol.K.failedCriteria)),inv{end+1}='SIF gates';end
if ~isequal(n.ph.audit.pass,true),inv{end+1}='phase audit';end
if ~isequal(h.ph.audit.meshAudit.gatesPassed,n.ph.audit.meshAudit.gatesPassed)||~isequal(n.ph.audit.meshAudit.gatesPassed,n.ph.audit.meshAudit.gatesTotal)
 inv{end+1}='mesh audit gates';end
if ~isequal(h.sol.K.qActiveElements,n.sol.K.qActiveElements),inv{end+1}='q-support element counts';end
r.invariantFailures=inv;
% integer / topology arrays
intEq=isequal(h.mesh.T3,n.mesh.T3)&&isequal(h.mesh.T6,n.mesh.T6)&& ...
 isequal(h.ph.owner,n.ph.owner)&&isequal(h.ph.labels,n.ph.labels)&&isequal(h.sol.K.phaseCounts,n.sol.K.phaseCounts);
Kref=hypot(h.st.KI,h.st.KII);
d=struct();
d.coord_mm=max([maxabs(h.st.polyline_mm,n.st.polyline_mm),maxabs(h.mesh.crackPolyline,n.mesh.crackPolyline), ...
 xyDiff(h.mesh.X3,n.mesh.X3),xyDiff(h.mesh.X6,n.mesh.X6)]);
d.K_rel=max(abs([h.st.KI-n.st.KI,h.st.KII-n.st.KII]))/Kref;
d.G_rel=abs(n.st.G/h.st.G-1);
d.MTS_deg=abs(h.st.MTS_deg-n.st.MTS_deg);
d.tangent=maxabs(h.st.tangent,n.st.tangent);
d.EDI_rel=maxabs(h.st.EDI_all(:,1:2),n.st.EDI_all(:,1:2))/Kref;
d.COD_rel=max(abs([h.sol.K.KI_COD-n.sol.K.KI_COD,h.sol.K.KII_COD-n.sol.K.KII_COD]))/Kref;
d.J_rel=abs(n.sol.K.J/h.sol.K.J-1);
d.compliance_rel=abs(n.sol.K.compliance_mm_per_N/h.sol.K.compliance_mm_per_N-1);
d.energy_rel=abs(n.sol.K.strainEnergy_per_thickness/h.sol.K.strainEnergy_per_thickness-1);
d.reactions_rel=maxabs(h.sol.K.reactions,n.sol.K.reactions)/max(abs(h.sol.K.reactions));
d.u_rel=relvec(h.sol.K.u,n.sol.K.u);
d.clearance_mm=clearDiff(h.st.clearance,n.st.clearance);
exact=intEq&&all(structfun(@(x)x==0,d))&&isequal(h.st.EDI_all,n.st.EDI_all)&&isequal(h.sol.K.u,n.sol.K.u);
r.maxDiff=d;r.integerArraysEqual=intEq;
if ~isempty(inv),r.tier='D';r.reasons=[{'invariant mismatch'},inv];return,end
if exact,r.tier='A';return,end
if intEq&&d.K_rel<=1e-10&&d.G_rel<=2e-10&&d.MTS_deg<=1e-8&&d.coord_mm<=1e-8&&d.tangent<=1e-10&& ...
  max([d.EDI_rel,d.COD_rel,d.J_rel,d.compliance_rel,d.energy_rel,d.u_rel,d.reactions_rel])<=1e-8&&d.clearance_mm<=1e-8
 r.tier='B';return
end
if d.coord_mm<=1e-5&&d.K_rel<=1e-5&&d.G_rel<=2e-5&&d.MTS_deg<=1e-3
 r.tier='C';r.reasons={'beyond round-off; within v2 regression limits'};if ~intEq,r.reasons{end+1}='mesh topology or phase arrays differ';end
 return
end
r.tier='D';r.reasons={'beyond v2 regression limits'};
end

function t=worstTier(ts)
order='ABCD';t='A';for i=1:numel(ts),if find(order==ts{i})>find(order==t),t=ts{i};end,end
end

function v=verdict(R)
if any(cellfun(@(x)any(strcmp(x,'missing state')),{R.states.reasons}))
 v='A0_HOLD_INCOMPLETE';return
end
if ~R.provenance.pass,v='A0_NOT_REPRODUCED_PROVENANCE';return,end
switch R.worstTier
 case 'A',v='A0_REPRODUCED_EXACT';
 case 'B',v='A0_REPRODUCED_ROUNDOFF';
 case 'C'
  if R.classesUnchanged&&R.classesNew.maxAbsDeltaFG<=4e-5&&R.classesNew.maxAbsDeltaOffset_mm<=1e-5
   v='A0_EQUIVALENT_REVIEW_REQUIRED';else,v='A0_NOT_REPRODUCED';end
 otherwise,v='A0_NOT_REPRODUCED';
end
end

% ------------------------------------------------------------------ provenance
function P=provenance(N,root,selftest)
P=struct('pass',true,'notes',{{}});
% VG2 (Issue #62): A0 must run under the campaign-bound VG2 source set. The A0-P0 pin
% 6f7fb3ea... is historical; no physical campaign ever ran under it.
expSrc='9b634df22d2c44ba9f6465fa9c88f54274afa3a17aa5d43df1e2b2ac58b5c2b5';
expTok=['G2LP1|policy=074d7edc981920537726314f781f24b41ac7224c18d594d6a1b15343084e5091|source=',expSrc, ...
 '|LP0=b4240d7ed9b534dbe188a35bac13587db45f8cd1a86a5c7a79c2e1dfa4a233f5|cases=H,stiff13,soft2,soft1|maxState=4'];
if selftest
 P.notes{end+1}='selftest: provenance compared with itself; source-set and token checks not applicable';
else
 if ~strcmp(N.RUN.token,expTok),P.pass=false;P.notes{end+1}='RUN token is not the A0 token';end
end
cases={'H','stiff13','soft2','soft1'};
for c=1:4
 prev='';
 for k=0:4
  e=N.(sprintf('%s_S%d',cases{c},k));if ~e.present,continue,end
  if ~selftest&&~strcmp(e.st.sourceSHA256,expSrc),P.pass=false;P.notes{end+1}=sprintf('%s S%d source set',cases{c},k);end
  links=strcmpi(e.st.meshSHA256,e.fileSHA.MESH)&&strcmpi(e.st.phaseSHA256,e.fileSHA.PHASE)&& ...
   strcmpi(e.st.solutionSHA256,e.fileSHA.SOLUTION)&&strcmpi(e.st.reviewSHA256,e.fileSHA.REVIEW);
  if ~links,P.pass=false;P.notes{end+1}=sprintf('%s S%d file-hash links',cases{c},k);end
  if k>0&&~strcmpi(e.st.parentSHA256,prev),P.pass=false;P.notes{end+1}=sprintf('%s S%d parent chain',cases{c},k);end
  prev=e.fileSHA.STATE;
 end
end
P.root=strrep(root,'\','/');
end

% ------------------------------------------------------------------ S4 classes (SR1 rules)
function C=s4classes(S,cases)
E=3268.115;C=struct();num=struct();dFG=0;dOff=0; %#ok<NASGU>
for c=2:4
 m=cases{c};F=struct();
 for k=0:4
  hm=S.(sprintf('%s_S%d',m,k));hh=S.(sprintf('H_S%d',k));
  if ~hm.present||~hh.present,F=[];break,end
  FG=hm.st.G/hh.st.G-1;
  Gc=@(K)(K.KI_COD^2+K.KII_COD^2)/E;
  FGc=Gc(hm.sol.K)/Gc(hh.sol.K)-1;
  vars=[edivar(hm.sol.K,hh.sol.K,E),FGc];Up=max(max(abs(vars-FG)),1e-5*(k>0));
  Ucons=(hm.st.G/hh.st.G)*(abs(Gc(hm.sol.K)-hm.st.G)/hm.st.G+abs(Gc(hh.sol.K)-hh.st.G)/hh.st.G);
  tc=@(K)mts(K.KI_COD,K.KII_COD);
  Ut(k+1)=abs(tc(hm.sol.K)-hm.st.MTS_deg)+abs(tc(hh.sol.K)-hh.st.MTS_deg); %#ok<AGROW>
  if k==4
   d=(hm.st.polyline_mm(end,:)-hh.st.polyline_mm(end,:))*hh.st.normal(:);
   Ud=4*sum((4-(0:3)).*deg2rad(Ut(1:4)));
   F=struct('F_G',FG,'U_primary',Up,'U_cons',Ucons,'d_mm',d,'U_d_cons_mm',Ud, ...
    'FG_primary',abs(FG)>2*Up&&sign(FG)==sign(FGc),'FG_conservative',abs(FG)>Ucons&&sign(FG)==sign(FGc), ...
    'offset_cautious',abs(d)>2*Ud);
  end
 end
 if isempty(F),C.(m)=struct('FG_primary','INCOMPLETE','FG_conservative','INCOMPLETE','offset_cautious','INCOMPLETE');num.(m)=struct();continue,end
 C.(m)=struct('FG_primary',F.FG_primary,'FG_conservative',F.FG_conservative,'offset_cautious',F.offset_cautious);
 num.(m)=F;
end
C.numbers=num;C.maxAbsDeltaFG=0;C.maxAbsDeltaOffset_mm=0;
end

function [dFG,dOff]=pathDeltas(H,N,cases)
% Largest change, across all 15 material states, of F_G and of the signed offset d.
dFG=0;dOff=0;
for c=2:4
 for k=0:4
  a=sprintf('%s_S%d',cases{c},k);b=sprintf('H_S%d',k);
  if ~(H.(a).present&&H.(b).present&&N.(a).present&&N.(b).present),dFG=inf;dOff=inf;return,end
  f1=H.(a).st.G/H.(b).st.G-1;f2=N.(a).st.G/N.(b).st.G-1;dFG=max(dFG,abs(f2-f1));
  d1=(H.(a).st.polyline_mm(end,:)-H.(b).st.polyline_mm(end,:))*H.(b).st.normal(:);
  d2=(N.(a).st.polyline_mm(end,:)-N.(b).st.polyline_mm(end,:))*N.(b).st.normal(:);dOff=max(dOff,abs(d2-d1));
 end
end
end

function v=edivar(KM,KH,E)
v=zeros(1,5);g=@(r)(r(1)^2+r(2)^2)/E;
for i=2:5,v(i-1)=g(KM.EDI_all(i,:))/g(KH.EDI_all(i,:))-1;end
v(5)=g(KM.EDI4x4)/g(KH.EDI4x4)-1;
end
function t=mts(KI,KII),t=rad2deg(2*atan2(-2*KII,KI+hypot(KI,sqrt(8)*KII)));end

% ------------------------------------------------------------------ selftest perturbations (memory only)
function T=perturbationTests(H,cases)
spec={ ...
 'K_relative_1e-12','B',@(e)setK(e,1+1e-12); ...
 'K_relative_1e-7','C',@(e)setK(e,1+1e-7); ...
 'K_relative_1e-3','D',@(e)setK(e,1+1e-3); ...
 'coordinate_1e-9_mm','B',@(e)shiftPoly(e,1e-9); ...
 'coordinate_1e-3_mm','D',@(e)shiftPoly(e,1e-3); ...
 'mesh_topology_changed','C',@(e)swapT3(e); ...
 'policy_changed','D',@(e)setField(e,'policySHA256',repmat('0',1,64)); ...
 'mask_changed','D',@(e)setField(e,'mask',[1 1 1]); ...
 'SIF_gate_failed','D',@(e)failK(e)};
T=struct('perturbation',{},'expectedTier',{},'observedTier',{},'pass',{});
key='soft2_S3';
for i=1:size(spec,1)
 n=spec{i,3}(H.(key));r=compareState(key,H.(key),n,true);
 T(end+1)=struct('perturbation',spec{i,1},'expectedTier',spec{i,2},'observedTier',r.tier,'pass',strcmp(r.tier,spec{i,2})); %#ok<AGROW>
end
% missing state and provenance
N=H;N.('soft1_S4').present=false;rr=compareState('soft1_S4',H.('soft1_S4'),N.('soft1_S4'),true);
T(end+1)=struct('perturbation','missing_state','expectedTier','D','observedTier',rr.tier,'pass',strcmp(rr.tier,'D'));
N=H;N.('H_S2').st.parentSHA256=repmat('f',1,64);P=provenance(N,'selftest',true);
T(end+1)=struct('perturbation','broken_parent_chain','expectedTier','PROVENANCE_FAIL','observedTier',char(string(~P.pass)),'pass',~P.pass);
P=provenance(H,'selftest',false);
T(end+1)=struct('perturbation','historical_records_as_A0','expectedTier','PROVENANCE_FAIL','observedTier',char(string(~P.pass)),'pass',~P.pass);
end
function e=setK(e,f),e.st.KI=e.st.KI*f;e.rv.KI=e.st.KI;e.st.G=(e.st.KI^2+e.st.KII^2)/3268.115;end
function e=shiftPoly(e,dx),e.st.polyline_mm(end,1)=e.st.polyline_mm(end,1)+dx;e.rv.polyline_mm=e.st.polyline_mm;end
function e=swapT3(e),e.mesh.T3([1 2],:)=e.mesh.T3([2 1],:);end
function e=setField(e,f,v),e.st.(f)=v;end
function e=failK(e),e.sol.K.failedCriteria={'synthetic'};end

% ------------------------------------------------------------------ utilities
function m=maxabs(a,b),if ~isequal(size(a),size(b)),m=inf;else,m=max(abs(double(a(:))-double(b(:))),[],'omitnan');if isempty(m),m=0;end,end,end
function m=xyDiff(a,b),m=maxabs(a,b);end
function m=relvec(a,b),if ~isequal(size(a),size(b)),m=inf;else,m=max(abs(a(:)-b(:)))/max(abs(a(:)));end,end
function m=clearDiff(a,b)
m=0;if ~isfield(a,'metrics')||~isstruct(a.metrics)||isempty(fieldnames(a.metrics)),return,end
f=fieldnames(a.metrics);
for i=1:numel(f)
 x=a.metrics.(f{i});y=b.metrics.(f{i});
 if isnumeric(x)&&isnumeric(y)
  if ~isequal(size(x),size(y)),m=inf;return,end
  z=abs(x(:)-y(:));z=z(isfinite(z));if ~isempty(z),m=max(m,max(z));end
  if ~isequal(isinf(x),isinf(y)),m=inf;return,end
 end
end
end
function h=fsha(file)
fid=fopen(file,'r');b=fread(fid,inf,'*uint8');fclose(fid);
md=java.security.MessageDigest.getInstance('SHA-256');md.update(b);
h=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
end
