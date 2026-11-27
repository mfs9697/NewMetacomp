function Ref=g2_lp2b1eq_reference(C,s)
%G2_LP2B1EQ_REFERENCE  Read-only qualification of ONE archived LP2-A3 reference (WP0; zero FEM, no mesh, no write).
%  Ref = g2_lp2b1eq_reference(C, s)     C = g2_lp2b1eq_context, s = policy solve entry (C.solves{k})
% Checks (every one named in Ref.checks; Ref.pass = all; the driver refuses a physical call unless pass):
%  records     STATE/PHASE/SOLUTION read through their manifests (g2_trajectory_record), file SHA-256 = pins,
%              MESH SHA-256 = pin; ADMIT record and manifest = pins
%  links       STATE -> MESH/PHASE/SOLUTION, PHASE -> MESH, SOLUTION -> MESH/PHASE, LP2-A3 token in STATE and
%              SOLUTION; identity (case, state, mask, ratio, 0.45 mm rung 1, ACCEPTED)
%  parent      parentSHA256 = pinned parent STATE; recurrence g2_lp2_forecast(parent) == polyline/tangent bitwise
%  K           all K fields present, finite, real; EDI_all 5x3; EDI4x4 1x2; positive KI, signed KII, J > 0,
%              compliance > 0; all 16 gates true; STATE K/J/compliance/active area bitwise equal to SOLUTION K
%  u           double, real, finite, length 2*N_T6 of the archived MESH; ordering: pin node (25.4,0) ux=uy=0,
%              roller (482.6,0) uy=0, K.uyLoad_mm == u(2*loadNode) at (254,203.2), compliance == |u(2*loadNode)|/1 N
%  mts         archived MTS root admissible, status OK, stationarity <= 1e-12
%  banks       paired upper/lower banks, unique stations covering [0, arc], one shared node = physical tip,
%              nonzero jump normalizations (near tip and whole crack) from the archived u
%  phase       PHASE labels give the archived active area bitwise (solver formula); 76 chords per circle
%  nextTip     g2_lp2_forecast(STATE) tip == pinned next tip bitwise == source record (soft1: TERMINAL candidate and
%              FAILED_MESH polyline; H: accepted S11 STATE tip, whose parent link is this STATE)
%  exported    STATE values bitwise equal to the committed LP2-A3 record dump (A3 exported data)
INT='G2LP2B1EQ:HOLD_REFERENCE';repo=C.repo;fp=@(p)fullfile(repo,strrep(p,'/',filesep));
a=s.archived;c=struct();P3=C.a3.policy;
[St,sth,o1]=g2_trajectory_record('read',fp(a.STATE.record.path));[Ph,phs,o2]=g2_trajectory_record('read',fp(a.PHASE.record.path));
[So,sos,o3]=g2_trajectory_record('read',fp(a.SOLUTION.record.path));[Ad,~,o4]=g2_trajectory_record('read',fp(a.ADMIT.record.path));
mh=lower(g2_sha256_file(fp(a.MESH.path)));
c.records=o1&&o2&&o3&&o4&&strcmpi(sth,a.STATE.record.sha256)&&strcmpi(phs,a.PHASE.record.sha256)&&strcmpi(sos,a.SOLUTION.record.sha256)&&strcmpi(mh,a.MESH.sha256);
assert(c.records,INT,'%s: archived records fail their manifests or pins.',s.id);
Ma=load(fp(a.MESH.path));K=So.K;
c.links=strcmpi(St.meshSHA256,mh)&&strcmpi(St.phaseSHA256,phs)&&strcmpi(St.solutionSHA256,sos)&&strcmpi(Ph.meshSHA256,mh)&& ...
 strcmpi(So.meshSHA256,mh)&&strcmpi(So.phaseSHA256,phs)&&strcmp(St.token,C.a3.token)&&strcmp(So.token,C.a3.token);
c.identity=strcmp(St.caseId,s.caseId)&&St.stateIndex==s.stateIndex&&isequal(reshape(St.mask,1,3),reshape(s.mask,1,3))&&St.ratio==s.ratio&& ...
 isequal(St.seedRung,1)&&isequal(St.seedSpacing_mm,0.45)&&strcmp(St.numericalStatus,'ACCEPTED')&&strcmp(So.caseId,s.caseId)&&So.stateIndex==s.stateIndex&& ...
 strcmp(Ph.caseId,s.caseId)&&Ph.stateIndex==s.stateIndex&&strcmp(Ad.caseId,s.caseId)&&Ad.stateIndex==s.stateIndex;
% ---- parent provenance and recurrence
if strcmp(s.caseId,'soft1')
 Par=g2_lp2a3_parent(C.a3,'soft1');parent=Par.state;ph=Par.stateSHA256;geomNominal=Par.geom;pps=s.parent.STATE.sha256;
 c.parentRecords=Par.terminalComparison.bitwiseEqual&&strcmpi(ph,pps);   % LP2-A1 S8 pins, links and terminal (g2_lp2a3_parent)
else
 [parent,ph,op]=g2_trajectory_record('read',fp(s.parent.STATE.record.path));pps=s.parent.STATE.record.sha256;
 [Ap,~,oa]=g2_trajectory_record('read',fp(s.parent.ADMIT.record.path));
 assert(op&&strcmpi(ph,pps),INT,'%s: parent STATE.',s.id);geomNominal=parent.clearanceGeometry;
 c.parentRecords=oa&&strcmp(Ap.caseId,s.caseId)&&Ap.stateIndex==s.stateIndex-1&&strcmpi(parent.parentSHA256,s.parent.grandparent.sha256)&& ...
  strcmp(parent.numericalStatus,'ACCEPTED')&&parent.stateIndex==s.stateIndex-1&&strcmp(parent.caseId,s.caseId);
end
F=g2_lp2_forecast(parent,P3);
c.parent=strcmpi(St.parentSHA256,pps)&&strcmpi(ph,St.parentSHA256)&&isequal(F.polyline_mm,St.polyline_mm)&& ...
 isequal(F.tangent,St.tangent)&&isequal(St.tip_mm,St.polyline_mm(end,:))&&isequal(Ma.crackPolyline,St.polyline_mm);
% ---- archived K
fin=@(x)isnumeric(x)&&isreal(x)&&~isempty(x)&&all(isfinite(x(:)));
need={'KI','KII','J','KI_COD','KII_COD','EDI_all','EDI4x4','compliance_mm_per_N','activeArea_mm2','u','loadNode','uyLoad_mm','pass','criteria'};
c.Kfields=all(isfield(K,need))&&all(cellfun(@(f)fin(K.(f)),setdiff(need,{'pass','criteria'})))&&isequal(size(K.EDI_all),[5 3])&&numel(K.EDI4x4)==2;
c.Kvalues=c.Kfields&&K.KI>0&&K.J>0&&K.compliance_mm_per_N>0&&K.activeArea_mm2>=0&&isequal(K.KI,K.EDI_all(1,1))&&isequal(K.KII,K.EDI_all(1,2));
gv=cell2mat(struct2cell(K.criteria));c.gates16=islogical(K.pass)&&K.pass&&numel(gv)==16&&all(gv);
c.stateEqualsSolution=isequal(St.KI,K.KI)&&isequal(St.KII,K.KII)&&isequal(St.J,K.J)&&isequal(St.compliance_mm_per_N,K.compliance_mm_per_N)&& ...
 isequal(St.activeArea_mm2,K.activeArea_mm2)&&isequal(St.KI_COD,K.KI_COD)&&isequal(St.KII_COD,K.KII_COD)&&isequal(St.EDI_all,K.EDI_all);
% ---- displacement vector and its node ordering (interleaved ux, uy per T6 node)
N6=size(Ma.X6,1);u=K.u;
c.uShape=isa(u,'double')&&isreal(u)&&isvector(u)&&numel(u)==2*N6&&all(isfinite(u));
at=@(xy)find(vecnorm(Ma.X6-reshape(xy,1,2),2,2)<1e-9);   % policy vectors decode as columns
pin=at(P3.bvp.pin_mm);rol=at(P3.bvp.roller_mm);ld=at(P3.bvp.load_mm);
c.uOrdering=c.uShape&&isscalar(pin)&&isscalar(rol)&&isscalar(ld)&&ld==K.loadNode&&u(2*pin-1)==0&&u(2*pin)==0&&u(2*rol)==0&& ...
 isequal(K.uyLoad_mm,u(2*ld))&&isequal(K.compliance_mm_per_N,abs(u(2*ld))/P3.bvp.P_N);
M=g2_mts_direction(K.KI,K.KII);c.mts=M.admissibleForStep&&strcmp(M.status,'OK')&&M.stationarityResidual_rel<=1e-12;
% ---- banks, stations, normalizations
B=g2_lp2b1eq_banks(Ma);arc=sum(vecnorm(diff(St.polyline_mm),2,2));
c.banks=isempty(B.problems)&&B.s(1)==0&&abs(B.s(end)-arc)<=1e-9&&B.n>=2;
jm=NaN;jn=NaN;
if c.banks&&c.uShape
 U=reshape(u,2,[]).';j=vecnorm(U(B.up,:)-U(B.lo,:),2,2);nt=vecnorm(B.x-St.tip_mm,2,2)<=3.3+1e-9;jm=max(j);jn=max(j(nt));
end
c.normalization=jm>0&&jn>0;
% ---- phase labels, active area, chords
lp=jsondecode(fileread(fullfile(C.here,'G2_LP1_POLICY_v2.json')));pm=jsondecode(fileread(fullfile(C.here,'G2_MATERIAL_POLICY_v1.json')));
po=struct('onCircleTol_mm',pm.phaseMap.onCircleTolerance_mm,'minGap_mm',pm.phaseMap.minGapToNextT3Vertex_mm,'midsideTol_mm',pm.phaseMap.midsideOnChordTolerance_mm);
PMa=g2_material_phase_map(Ma.X6,Ma.T6,lp.geometry.centres_mm,6.35*ones(3,1),19.05*ones(3,1),po);chA=arrayfun(@(q)size(q.chords,1),PMa.interfaces);
act=g2_m4b_ring_activation(PMa.annulusOf,logical(reshape(s.mask,1,3)));
aA=activeArea(Ma,Ph.labels);
c.phase=isequal(act.phaseForAssembly(:),Ph.labels(:))&&isequal(PMa.annulusOf(:),Ph.owner(:))&&isequal(aA,K.activeArea_mm2)&&isequal(chA(:).',[76 76 76]);
% ---- next-state predictor (state specific)
Fn=g2_lp2_forecast(St,P3);np=s.nextPredictor;tipN=Fn.polyline_mm(end,:);
if strcmp(np.state,'S10')
 [Tm,~,ot]=g2_trajectory_record('read',fp(np.TERMINAL.record.path));Fm=load(fp(np.FAILED_MESH.path));
 src=ot&&isequal(Tm.candidate.polyline_mm,Fn.polyline_mm)&&isequal(Fm.failedMesh.crackPolyline,Fn.polyline_mm)&&strcmpi(Tm.parentSHA256,sth)&&Tm.lastAcceptedState==9;
else
 [S11,~,o11]=g2_trajectory_record('read',fp(np.STATE.record.path));
 src=o11&&isequal(S11.tip_mm,tipN)&&isequal(S11.polyline_mm,Fn.polyline_mm)&&isequal(S11.tangent,Fn.tangent)&&strcmpi(S11.parentSHA256,sth)&&S11.stateIndex==11;
end
c.nextTip=Fn.stateIndex==s.stateIndex+1&&strcmp(np.state,sprintf('S%d',Fn.stateIndex))&&isequal(tipN,reshape(np.tip_mm,1,2))&&src;
% ---- A3 exported data (committed record dump)
Dm=jsondecode(fileread(fullfile(repo,'docs','research','G2_LP2A3_evidence','campaign','verify','LP2A3_RECORD_DUMP.json')));
ss=Dm.cases.(s.caseId).states;if ~iscell(ss),ss=num2cell(ss);end
e=ss{cellfun(@(x)strcmp(x.folder,sprintf('S%d',s.stateIndex)),ss)}.state;
c.exported=isequal(e.KI,St.KI)&&isequal(e.KII,St.KII)&&isequal(e.J,St.J)&&isequal(e.G,St.G)&&isequal(e.compliance_mm_per_N,St.compliance_mm_per_N)&& ...
 isequal(e.activeArea_mm2,St.activeArea_mm2)&&isequal(e.KI_COD,St.KI_COD)&&isequal(e.KII_COD,St.KII_COD)&&isequal(e.EDI_all,St.EDI_all)&& ...
 isequal(reshape(e.tip_mm,1,2),St.tip_mm)&&strcmpi(e.meshSHA256,mh)&&strcmpi(e.phaseSHA256,phs)&&strcmpi(e.solutionSHA256,sos)&&strcmpi(e.parentSHA256,St.parentSHA256);
Ref=struct('solveId',s.id,'pass',all(cell2mat(struct2cell(c))),'checks',c,'state',St,'stateSHA256',sth,'solution',So,'solutionSHA256',sos, ...
 'phase',Ph,'phaseSHA256',phs,'mesh',Ma,'meshSHA256',mh,'chordsPerCircle',chA(:).','nominalGeometry',geomNominal,'nextState',np.state, ...
 'nextTip_mm',tipN,'archivedActiveAreaRecomputed_mm2',aA,'banks',struct('pairs',B.n,'tipNode',B.tipNode,'stationMax_mm',B.s(end),'arc_mm',arc), ...
 'maxJump_mm',jm,'maxJumpNearTip_mm',jn,'uLength',numel(u),'N_T6',N6,'loadNode',K.loadNode,'pinNode',pin,'rollerNode',rol, ...
 'mts',struct('theta_deg',M.theta_deg,'status',M.status,'stationarity',M.stationarityResidual_rel));
end

function A=activeArea(D,labels)
% identical formula to g2_m4b_sif_partial: signed T3-vertex areas of the T6 elements, summed over label 2
x=D.X6(:,1);y=D.X6(:,2);T3=D.T6(:,1:3);
Ael=.5*((x(T3(:,2))-x(T3(:,1))).*(y(T3(:,3))-y(T3(:,1)))-(x(T3(:,3))-x(T3(:,1))).*(y(T3(:,2))-y(T3(:,1))));
A=sum(Ael(labels==2));
end
