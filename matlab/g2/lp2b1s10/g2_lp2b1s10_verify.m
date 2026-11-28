function R=g2_lp2b1s10_verify(C,varargin)
%G2_LP2B1S10_VERIFY  Read-only replay of the G2-LP2B1-S10-001 records (zero solves, zero writes).
%  R = g2_lp2b1s10_verify(C)                         C = g2_lp2b1s10_context('Preflight',false) (or a test context)
%  R = g2_lp2b1s10_verify(C,'Target',fn)             fn(C) replaces g2_lp2b1s10_target (tests)
% Ledger (receipt root): integrity, RECEIPT bound to the token and campaign, ADMIT keys exactly {soft1_S10} when a case
% folder exists, no foreign entry. Run root: only soft1/; soft1 holds S10/ and, when complete, TERMINAL.mat(+manifest).
% Complete record set in S10 (exactly): GEOMETRY_h040/ATTEMPT.json, GEOMETRY_h040/ATTEMPT_ARRAYS.mat, MESH.mat,
% PHASE.mat(+m), SOLUTION.mat(+m), STATE.mat(+m). With HOLD.json: preserved partial attempt (subset of the set, no STATE,
% no TERMINAL). For a complete set: manifests; hash links STATE->MESH/PHASE/SOLUTION, PHASE/SOLUTION->MESH; token,
% identifiers, parent = ORIGINAL S9 (pinned); canonical MESH digest == pin == ATTEMPT digest; ATTEMPT arrays SHA;
% polyline/tangent/arc/heading == recomputed signed-MTS forecast of the parent (bitwise); K.pass and all 16 gates;
% STATE K/J/compliance/area == SOLUTION K bitwise; G, mixity, MTS root, COD/EDI/spread/quadrature recomputed; guide gaps
% and ring distances recomputed; TERMINAL binds the STATE and its S11 candidate == g2_lp2_forecast(STATE) bitwise.
% SHA-256, size and modification time of every file before and after are identical.
% Outcomes: NO_RECORDS | VERIFIED_ACCEPTED | VERIFIED_PARTIAL_HOLD | VERIFY_HOLD (any problem; R.problems).
ip=inputParser;addParameter(ip,'Target',[]);parse(ip,varargin{:});tf=ip.Results.Target;if isempty(tf),tf=@g2_lp2b1s10_target;end
pol=C.policy;root=C.runRoot;R=struct('schema','NewMetacomp.G2.LP2B1S10.Verify.v1','outcome','NO_RECORDS','problems',{{}},'unchanged',true,'physicalSolves',0, ...
 'token',C.token,'policySHA256',C.policySHA256,'ledger',struct(),'files',{{}},'state',[]);
if ~isfolder(root)&&~isfolder(C.receiptRoot),return,end
T0=[treeInfo(root);treeInfo(C.receiptRoot)];
L=g2_lp1_campaign_ledger('snapshot',C.receiptRoot);
R.ledger=struct('integrityOK',L.integrityOK,'receipt',isstruct(L.receipt),'admits',{L.admits},'holds',numel(L.holds),'closed',L.closed);
if ~(L.integrityOK&&isstruct(L.receipt)&&strcmp(L.receipt.token,C.token)&&strcmp(L.receipt.campaignId,pol.campaignId)),bad('LEDGER: integrity, receipt or token');end
cd0=fullfile(root,'soft1');sd=fullfile(cd0,'S10');
if isfolder(root)
 d=dir(root);d=d(~ismember({d.name},{'.','..'}));if ~isequal({d.name},{'soft1'})&&~isempty(d),bad('RECORD_SET: run root must contain only soft1/');end
end
if ~isfolder(cd0)
 if ~isempty(L.admits),bad('LEDGER: ADMIT without a case folder');end
 R.outcome=ternary(isempty(R.problems),'NO_RECORDS','VERIFY_HOLD');R.unchanged=isequal(T0,[treeInfo(root);treeInfo(C.receiptRoot)]);return
end
if ~isequal(sort(cellstr(L.admits)),{'soft1_S10'}),bad('LEDGER: ADMIT keys must be exactly soft1_S10');end
Ti=treeInfo(cd0);rel={Ti.rel};R.files=rel;
full=sort({'S10/GEOMETRY_h040/ATTEMPT.json','S10/GEOMETRY_h040/ATTEMPT_ARRAYS.mat','S10/MESH.mat','S10/PHASE.mat','S10/PHASE.mat.manifest.json', ...
 'S10/SOLUTION.mat','S10/SOLUTION.mat.manifest.json','S10/STATE.mat','S10/STATE.mat.manifest.json','TERMINAL.mat','TERMINAL.mat.manifest.json'});
if any(strcmp(rel,'S10/HOLD.json'))
 if ~all(ismember(setdiff(rel,{'S10/HOLD.json'}),full))||any(ismember(rel,{'S10/STATE.mat','TERMINAL.mat'})),bad('PARTIAL: unexpected files with HOLD.json');end
 try,Hj=jsondecode(fileread(fullfile(sd,'HOLD.json')));R.hold=Hj;if ~all(isfield(Hj,{'stage','identifier'})),bad('PARTIAL: HOLD.json fields');end,catch,bad('PARTIAL: HOLD.json unreadable');end
 R.outcome=ternary(isempty(R.problems),'VERIFIED_PARTIAL_HOLD','VERIFY_HOLD');R.unchanged=isequal(T0,[treeInfo(root);treeInfo(C.receiptRoot)]);
 if ~R.unchanged,bad('UNCHANGED: files changed during verification');R.outcome='VERIFY_HOLD';end
 return
end
if ~isequal(sort(rel),full),bad(sprintf('RECORD_SET: expected 11 files, found [%s]',strjoin(rel,', ')));end
try
 [St,sth,o1]=g2_trajectory_record('read',fullfile(sd,'STATE.mat'));[So,soh,o2]=g2_trajectory_record('read',fullfile(sd,'SOLUTION.mat'));
 [Ph,phh,o3]=g2_trajectory_record('read',fullfile(sd,'PHASE.mat'));[Tm,~,o4]=g2_trajectory_record('read',fullfile(cd0,'TERMINAL.mat'));
 if ~(o1&&o2&&o3&&o4),bad('MANIFEST: a record fails its manifest');end
 mh=lower(g2_sha256_file(fullfile(sd,'MESH.mat')));D=load(fullfile(sd,'MESH.mat'));K=So.K;
 Aj=jsondecode(fileread(fullfile(sd,'GEOMETRY_h040','ATTEMPT.json')));q=pol.qualification;
 chk('LINKS',strcmpi(St.meshSHA256,mh)&&strcmpi(St.phaseSHA256,phh)&&strcmpi(St.solutionSHA256,soh)&&strcmpi(Ph.meshSHA256,mh)&&strcmpi(So.meshSHA256,mh)&&strcmpi(So.phaseSHA256,phh));
 chk('TOKEN',strcmp(St.token,C.token)&&strcmp(So.token,C.token)&&strcmp(Ph.token,C.token)&&strcmp(Tm.token,C.token)&&strcmp(St.policySHA256,C.policySHA256));
 chk('IDENTITY',St.stateIndex==10&&strcmp(St.caseId,'soft1')&&isequal(reshape(St.mask,1,3),[1 0 0])&&St.ratio==0.5&&strcmp(St.numericalStatus,'ACCEPTED')&& ...
  St.seedSpacing_mm==0.40&&strcmp(St.campaignId,pol.campaignId)&&~St.physicalFractureGrowthProven);
 chk('PARENT',strcmpi(St.parentSHA256,pol.parent.STATE.record.sha256));
 chk('CANONICAL',strcmpi(g2_lp2b1eq_canon(D),q.canonicalSHA256)&&strcmpi(Aj.canonicalSHA256,q.canonicalSHA256)&&strcmpi(St.canonicalSHA256,q.canonicalSHA256)&& ...
  strcmpi(Aj.arraysFileSHA256,g2_sha256_file(fullfile(sd,'GEOMETRY_h040','ATTEMPT_ARRAYS.mat')))&&Aj.checksPassed==19&&Aj.pass&&size(D.T3,1)==St.T3);
 Tq=tf(C);F=Tq.forecast;
 chk('GEOMETRY',Tq.pass&&isequal(St.polyline_mm,F.polyline_mm)&&isequal(St.tangent,F.tangent)&&isequal(St.arc_mm,F.arc_mm)&&isequal(St.heading_deg,F.heading_deg)&& ...
  isequal(D.crackPolyline,St.polyline_mm)&&isequal(St.tip_mm,St.polyline_mm(end,:)));
 g=struct2cell(K.criteria);
 chk('GATES',isequal(K.pass,true)&&numel(g)==16&&all(cellfun(@(x)isequal(x,true),g)));
 chk('STATE_EQUALS_SOLUTION',isequal(St.KI,K.KI)&&isequal(St.KII,K.KII)&&isequal(St.J,K.J)&&isequal(St.compliance_mm_per_N,K.compliance_mm_per_N)&& ...
  isequal(St.activeArea_mm2,K.activeArea_mm2)&&isequal(St.phaseCounts,K.phaseCounts)&&isequal(St.EDI_all,K.EDI_all));
 M=g2_mts_direction(K.KI,K.KII);Kr=hypot(K.KI,K.KII);Em=pol.bvp.E_MPa;ed=K.EDI_all;
 chk('DERIVED',K.KI>0&&strcmp(M.status,'OK')&&M.admissibleForStep&&M.stationarityResidual_rel<=pol.tolerances.mtsStationarity_rel&&isequal(St.MTS_deg,M.theta_deg)&& ...
  isequal(St.G,Kr^2/Em)&&isequal(St.KIIoverKI,K.KII/K.KI)&&isequal(St.CODminusEDI_rel,max(abs([K.KI_COD-K.KI,K.KII_COD-K.KII]))/Kr)&& ...
  isequal(St.pathSpread_rel,max(max(ed(:,1:2))-min(ed(:,1:2)))/Kr)&&isequal(St.quad4x4_rel,max(abs(K.EDI4x4-[K.KI,K.KII]))/Kr)&&isequal(St.JoverGminus1,K.J/(Kr^2/Em)-1));
 cen=pol.geometry.centres_mm;tip=St.tip_mm;gR=pol.ringProximityGuard;
 chk('DISTANCES',isequal(St.tipToRingCircle_mm,vecnorm(cen-tip,2,2).'-pol.geometry.ringR_mm)&&isequal(St.guideRingGap_mm,vecnorm(cen-tip,2,2).'-gR.ringR_mm-gR.guideRadius_mm)&& ...
  min(St.guideRingGap_mm)>=gR.minGap_mm&&strcmp(St.classification,'MATRIX_ADVANCE'));
 chk('TERMINAL',strcmp(Tm.classification,'SINGLE_STATE_LIMIT_REACHED')&&Tm.lastAcceptedState==10&&strcmpi(Tm.stateSHA256,sth)&&strcmpi(Tm.parentSHA256,sth)&& ...
  strcmpi(Tm.originalParentSHA256,pol.parent.STATE.record.sha256)&&isequal(Tm.candidateIsInformationOnly,true)&&~Tm.physicalArrest&&~Tm.interfaceEncounter);
 try
  F11=g2_lp2_forecast(St,C.a3.policy);chk('S11_INFORMATION',isequal(Tm.candidate.polyline_mm,F11.polyline_mm));
 catch
  chk('S11_INFORMATION',isempty(Tm.candidate.polyline_mm)&&startsWith(Tm.candidate.note,'S11 information unavailable'));
 end
 R.state=struct('KI',St.KI,'KII',St.KII,'G',St.G,'J',St.J,'MTS_deg',St.MTS_deg,'heading_deg',St.heading_deg,'tip_mm',St.tip_mm,'guideRingGap_mm',St.guideRingGap_mm, ...
  'tipToRingCircle_mm',St.tipToRingCircle_mm,'activeArea_mm2',St.activeArea_mm2,'compliance_mm_per_N',St.compliance_mm_per_N,'stateSHA256',sth,'S11',Tm.candidate.classification);
catch ME
 bad(['READ: ' ME.identifier ': ' ME.message]);
end
R.unchanged=isequal(T0,[treeInfo(root);treeInfo(C.receiptRoot)]);if ~R.unchanged,bad('UNCHANGED: files changed during verification');end
R.outcome=ternary(isempty(R.problems),'VERIFIED_ACCEPTED','VERIFY_HOLD');
 function bad(m),R.problems{end+1}=m;end
 function chk(n,ok),if ~isequal(ok,true),bad(['CHECK_' n]);end,end
end

function T=treeInfo(root)
T=struct('rel',{},'sha256',{},'bytes',{},'datenum',{});if ~isfolder(root),return,end
d=dir(fullfile(root,'**','*'));d=d(~[d.isdir]);
for k=1:numel(d)
 p=fullfile(d(k).folder,d(k).name);T(end+1)=struct('rel',strrep(extractAfter(p,numel(root)+1),'\','/'),'sha256',lower(g2_sha256_file(p)),'bytes',d(k).bytes,'datenum',d(k).datenum); %#ok<AGROW>
end
if ~isempty(T),[~,o]=sort({T.rel});T=T(o);T=T(:);end
end
function v=ternary(c,a,b),if c,v=a;else,v=b;end,end
