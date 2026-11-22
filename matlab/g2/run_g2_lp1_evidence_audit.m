function R=run_g2_lp1_evidence_audit()
% Independent final record/clearance check. Reads only accepted campaign bytes.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
root=fullfile(repo,'outputs/g2_lp1_matrix_paths_v1/run_20261122_lp1_v1');
pol=jsondecode(fileread(fullfile(here,'G2_LP1_POLICY_v2.json')));ids={'H','stiff13','soft2','soft1'};
rows=struct('caseId',{},'state',{},'stateSHA256',{},'pass',{});n=0;negative=0;
for c=1:4
 parent=[];parentHash='';
 for k=0:4
  sd=fullfile(root,ids{c},sprintf('S%d',k));[S,sh,ok]=g2_trajectory_record('read',fullfile(sd,'STATE.mat'));assert(ok);
  [Rev,rh,ok]=g2_trajectory_record('read',fullfile(sd,'REVIEW.mat'));assert(ok&&strcmpi(rh,S.reviewSHA256));
  expected=Rev;expected.schema='NewMetacomp.G2.LP1.State.v1';expected.reviewSHA256=lower(rh);assert(isequaln(S,expected));
  [Sol,h,ok]=g2_trajectory_record('read',fullfile(sd,'SOLUTION.mat'));assert(ok&&strcmpi(h,S.solutionSHA256));
  [Ph,h,ok]=g2_trajectory_record('read',fullfile(sd,'PHASE.mat'));assert(ok&&strcmpi(h,S.phaseSHA256));
  mf=fullfile(sd,'MESH.mat');assert(strcmpi(g2_sha256_file(mf),S.meshSHA256));D=load(mf);
  assert(isequal(D.crackPolyline,S.polyline_mm)&&isequal(D.tipTangent,S.tangent));
  O=g2_m4b_ring_owner_oracle(D.X6,D.T6,pol.geometry.centres_mm,6.35*ones(3,1),19.05*ones(3,1),struct('onCircleTol_mm',1e-9));
  assert(O.pass&&isequal(O.ownerOracle,Ph.owner));g=struct('centres',pol.geometry.centres_mm,'ringPolygons',{{}},'holePolygons',{{}});
  for j=1:3,g.ringPolygons{j}=D.X6(O.ringVertices{j},:);g.holePolygons{j}=D.X6(O.holeVertices{j},:);end
  a=g2_m4b_ring_activation(O.ownerOracle,reshape(pol.cases(c).mask,1,3));assert(isequal(a.phaseForAssembly,Ph.labels));
  rr=vecnorm(D.X6-S.polyline_mm(end,:),2,2);minimum=min(reshape(rr(D.T6(:)),[],6),[],2);
  for j=1:5,assert(all(O.ownerOracle(minimum<pol.qAnnuli_mm(j,2))==0));end
  if k==0
   assert(isequal(S.polyline_mm,pol.startPolyline_mm));
  else
   F=g2_lp1_forecast(parent,pol);assert(isequal(F.polyline_mm,S.polyline_mm)&&isequal(F.tangent,S.tangent)&&strcmpi(S.parentSHA256,parentHash));
   A=g2_lp0_clearance(S.polyline_mm(1:end-1,:),S.polyline_mm(end,:),g,pol);
   verifyClearance(S.clearance,A);
   bad=S.clearance;bad.metrics.qRingMargin_mm=bad.metrics.qRingMargin_mm+1;
   caught=false;try,verifyClearance(bad,A);catch,caught=true;end;assert(caught);negative=negative+1;
  end
  assert(Sol.K.KI==S.KI&&Sol.K.KII==S.KII&&Sol.K.pass&&all(cell2mat(struct2cell(Sol.K.criteria))));
  n=n+1;rows(n)=struct('caseId',ids{c},'state',k,'stateSHA256',lower(sh),'pass',true); %#ok<AGROW>
  parent=S;parentHash=sh;
 end
end
% Genuine dirty-source refusal. Remove only the new sentinel created here.
sentinel=fullfile(here,'LP1_DIRTY_SENTINEL.txt');assert(~isfile(sentinel));
fid=fopen(sentinel,'w');fprintf(fid,'intentional LP1 negative test');fclose(fid);
cleanup=onCleanup(@()removeSentinel(sentinel));p=g2_lp0_preflight();dirtyRejected=~p.pass&&strcmp(p.cause,'HOLD_SOURCE');
clear cleanup;assert(dirtyRejected);
R=struct('pass',all([rows.pass])&&negative==16&&dirtyRejected,'statesChecked',n,'forgedQClearanceRejected',negative, ...
 'dirtySourceRejected',dirtyRejected,'records',rows,'physicalSolves',0,'remeshes',0);
fid=fopen(fullfile(repo,'outputs/g2_lp0_20261122/INDEPENDENT_EVIDENCE_AUDIT.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
fprintf('G2_LP1_EVIDENCE_AUDIT %d/20; FORGED_Q %d/16; DIRTY_SOURCE %d; NO_FEM=1\n',n,negative,dirtyRejected);
end
function verifyClearance(saved,actual)
assert(actual.pass&&isequaln(saved,actual),'G2LP1Review:ForgedClearance','Saved clearance differs from actual closed polygons.');
end
function removeSentinel(p)
if isfile(p),delete(p);end
end
