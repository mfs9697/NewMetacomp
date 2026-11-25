% LP2-A2 activation A2: READ-ONLY diagnostic of the replay outcome VERIFY_HOLD (no solve, no write under the clone).
% Repeats, line for line, the recomputation of g2_lp2a2_eq_verify for each solve and reports (a) class/size of the
% recomputed and stored 'failed' lists and the exact isequal used by the replay, (b) criterion-by-criterion and
% metric-by-metric agreement between the recomputed comparison and the stored COMPARISON.json.
ex='<repo>';
out='<scratch>';
addpath(fullfile(ex,'matlab','g2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a2'),'-begin');
try
 C=g2_lp2a2_eq_context('Preflight',false);pol=C.policy;root=fullfile(C.repo,pol.outputRoot);
 before=treeHash(root);
 pol9=jsondecode(fileread(fullfile(C.here,'lp2','G2_LP2A_POLICY_v1.json')));pol9.caps.maxStateIndex=9;pol9.caps.maxArcLength_mm=61.4;
 lp=jsondecode(fileread(fullfile(C.here,'G2_LP1_POLICY_v2.json')));pm=jsondecode(fileread(fullfile(C.here,'G2_MATERIAL_POLICY_v1.json')));
 po=struct('onCircleTol_mm',pm.phaseMap.onCircleTolerance_mm,'minGap_mm',pm.phaseMap.minGapToNextT3Vertex_mm,'midsideTol_mm',pm.phaseMap.midsideOnChordTolerance_mm);
 Dg=struct('schema','NewMetacomp.G2.LP2A2.EQ.ReplayDiagnostic.v1','emptyProbe',struct( ...
  'isequal_cell1x0_double1x0',isequal(cell(1,0),zeros(1,0)),'isequal_cell1x0_double0x0',isequal(cell(1,0),[]),'jsondecodeEmptyArrayClass',class(jsondecode('[]'))),'solves',struct([]));
 for k=1:numel(pol.solves)
  s=pol.solves(k);sd=fullfile(root,s.id);f=@(n)fullfile(sd,n);
  Sx=load(f('SOLUTION.mat'));Sx=Sx.record;Cm=jsondecode(fileread(f('COMPARISON.json')));
  ab=fullfile(C.archiveBase,s.caseId);St=load(fullfile(ab,'S8','STATE.mat'));St=St.record;So=load(fullfile(ab,'S8','SOLUTION.mat'));So=So.record;
  Tm=load(fullfile(ab,'TERMINAL.mat'));Tm=Tm.record;Ma=load(fullfile(ab,'S8','MESH.mat'));D=load(f('MESH.mat'));
  PMn=g2_material_phase_map(D.X6,D.T6,lp.geometry.centres_mm,6.35*ones(3,1),19.05*ones(3,1),po);PMa=g2_material_phase_map(Ma.X6,Ma.T6,lp.geometry.centres_mm,6.35*ones(3,1),19.05*ones(3,1),po);
  Sn=St;Sn.KI=Sx.K.KI;Sn.KII=Sx.K.KII;F=g2_lp2_forecast(Sn,pol9);
  Nn=struct('K',Sx.K,'D',D,'activeArea_mm2',Sx.K.activeArea_mm2,'chordsPerCircle',arrayfun(@(q)size(q.chords,1),PMn.interfaces),'S9tip_mm',F.polyline_mm(end,:));
  An=struct('state',St,'K',So.K,'D',Ma,'S9tip_mm',Tm.candidate.polyline_mm(end,:),'chordsPerCircle',arrayfun(@(q)size(q.chords,1),PMa.interfaces));
  Rc=g2_lp2a2_eq_compare(Nn,An,pol.tolerances);
  fl=Cm.failed;if ischar(fl),fl={fl};end
  a=sort(Rc.failed(:)).';b=sort(fl(:)).';
  cf=fieldnames(Rc.criteria);critEq=true;for q=1:numel(cf),critEq=critEq&&isequal(logical(Rc.criteria.(cf{q})),logical(Cm.criteria.(cf{q})));end
  mf=fieldnames(Rc.metrics);dm=struct();mx=0;
  for q=1:numel(mf)
   x=double(Rc.metrics.(mf{q}));y=double(Cm.metrics.(mf{q}));d=max(abs(x(:)-y(:)));dm.(mf{q})=d;mx=max(mx,d);
  end
  E=struct('solveId',s.id,'recomputedPass',Rc.pass,'storedPass',logical(Cm.pass),'recomputedFailedClass',class(a),'recomputedFailedSize',size(a), ...
   'storedFailedClass',class(b),'storedFailedSize',size(b),'replayIsequal',isequal(a,b),'bothEmpty',isempty(a)&&isempty(b), ...
   'criteriaIdentical',critEq,'metricsMaxAbsDiff',mx,'metricAbsDiff',dm);
  if isempty(Dg.solves),Dg.solves=E;else,Dg.solves(end+1)=E;end
  fprintf('DIAG %s pass %d/%d failed recomputed %s %s stored %s %s isequal=%d bothEmpty=%d criteriaIdentical=%d metricsMaxAbsDiff=%.3g\n',s.id,Rc.pass,logical(Cm.pass), ...
   class(a),mat2str(size(a)),class(b),mat2str(size(b)),isequal(a,b),E.bothEmpty,critEq,mx);
 end
 Dg.recordsUnchanged=isequal(before,treeHash(root));Dg.physicalSolves=0;
 fprintf('DIAG_EMPTY isequal(cell(1,0),zeros(1,0))=%d isequal(cell(1,0),[])=%d jsondecode([])=%s unchanged=%d\n',Dg.emptyProbe.isequal_cell1x0_double1x0,Dg.emptyProbe.isequal_cell1x0_double0x0,Dg.emptyProbe.jsondecodeEmptyArrayClass,Dg.recordsUnchanged);
 fid=fopen(fullfile(out,'LP2A2_EQ_A2_REPLAY_DIAGNOSTIC.json'),'w');fwrite(fid,jsonencode(Dg,'PrettyPrint',true),'char');fclose(fid);
catch ME
 fprintf(2,'DIAG_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
function H=treeHash(root)
d=dir(fullfile(root,'**','*'));d=d(~[d.isdir]);H=cell(numel(d),2);
for k=1:numel(d),p=fullfile(d(k).folder,d(k).name);H{k,1}=p;H{k,2}=lower(g2_sha256_file(p));end
H=sortrows(H,1);
end
