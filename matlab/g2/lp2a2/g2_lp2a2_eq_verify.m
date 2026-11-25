function R=g2_lp2a2_eq_verify()
%G2_LP2A2_EQ_VERIFY  Read-only replay of the LP2-A2 equivalence records (zero solves, zero writes).
% For every existing solve folder in the policy output root: the four records exist; MESH, PHASE and
% SOLUTION hashes agree with the links in SOLUTION/COMPARISON; the comparison is recomputed from the
% stored SOLUTION K, the stored MESH and the pinned archived S8 records and must reproduce the stored
% pass/failed. The SHA-256 of every file under the output root is taken before and after and must be
% identical (records not modified). Without records: outcome NO_RECORDS and nothing is created.
C=g2_lp2a2_eq_context('Preflight',false);pol=C.policy;root=fullfile(C.repo,pol.outputRoot);
R=struct('outcome','NO_RECORDS','solves',{{}},'problems',{{}},'unchanged',true,'physicalSolves',0);
if ~isfolder(root),return,end
before=treeHash(root);
pol9=jsondecode(fileread(fullfile(C.here,'lp2','G2_LP2A_POLICY_v1.json')));pol9.caps.maxStateIndex=9;pol9.caps.maxArcLength_mm=61.4;
lp=jsondecode(fileread(fullfile(C.here,'G2_LP1_POLICY_v2.json')));pm=jsondecode(fileread(fullfile(C.here,'G2_MATERIAL_POLICY_v1.json')));
po=struct('onCircleTol_mm',pm.phaseMap.onCircleTolerance_mm,'minGap_mm',pm.phaseMap.minGapToNextT3Vertex_mm,'midsideTol_mm',pm.phaseMap.midsideOnChordTolerance_mm);
for k=1:numel(pol.solves)
 s=pol.solves(k);sd=fullfile(root,s.id);if ~isfolder(sd),continue,end
 f=@(n)fullfile(sd,n);r=struct('solveId',s.id,'pass',false);
 if ~all(cellfun(@isfile,{f('MESH.mat'),f('PHASE.mat'),f('SOLUTION.mat'),f('COMPARISON.json')}))
  R.problems{end+1}=[s.id ': incomplete records'];R.solves{end+1}=r;continue %#ok<AGROW>
 end
 Sx=load(f('SOLUTION.mat'));Sx=Sx.record;Cm=jsondecode(fileread(f('COMPARISON.json')));
 mh=lower(g2_sha256_file(f('MESH.mat')));ph=lower(g2_sha256_file(f('PHASE.mat')));sh=lower(g2_sha256_file(f('SOLUTION.mat')));
 links=strcmp(Sx.meshSHA256,mh)&&strcmp(Sx.phaseSHA256,ph)&&strcmp(Cm.solutionSHA256,sh)&&strcmp(Cm.meshSHA256,mh)&&strcmp(Sx.token,C.token);
 ab=fullfile(C.archiveBase,s.caseId);St=load(fullfile(ab,'S8','STATE.mat'));St=St.record;So=load(fullfile(ab,'S8','SOLUTION.mat'));So=So.record;
 Tm=load(fullfile(ab,'TERMINAL.mat'));Tm=Tm.record;Ma=load(fullfile(ab,'S8','MESH.mat'));D=load(f('MESH.mat'));
 PMn=g2_material_phase_map(D.X6,D.T6,lp.geometry.centres_mm,6.35*ones(3,1),19.05*ones(3,1),po);PMa=g2_material_phase_map(Ma.X6,Ma.T6,lp.geometry.centres_mm,6.35*ones(3,1),19.05*ones(3,1),po);
 Sn=St;Sn.KI=Sx.K.KI;Sn.KII=Sx.K.KII;F=g2_lp2_forecast(Sn,pol9);
 Nn=struct('K',Sx.K,'D',D,'activeArea_mm2',Sx.K.activeArea_mm2,'chordsPerCircle',arrayfun(@(q)size(q.chords,1),PMn.interfaces),'S9tip_mm',F.polyline_mm(end,:));
 An=struct('state',St,'K',So.K,'D',Ma,'S9tip_mm',Tm.candidate.polyline_mm(end,:),'chordsPerCircle',arrayfun(@(q)size(q.chords,1),PMa.interfaces));
 Rc=g2_lp2a2_eq_compare(Nn,An,pol.tolerances);
 fl=Cm.failed;if ischar(fl),fl={fl};end
 r.links=links;r.recomputedPass=Rc.pass;r.storedPass=logical(Cm.pass);r.reproduced=isequal(Rc.pass,logical(Cm.pass))&&isequal(sort(Rc.failed(:)).',sort(fl(:)).');
 r.pass=links&&r.reproduced;R.solves{end+1}=r; %#ok<AGROW>
 if ~r.pass,R.problems{end+1}=[s.id ': links or comparison not reproduced'];end %#ok<AGROW>
end
R.unchanged=isequal(before,treeHash(root));
if ~R.unchanged,R.problems{end+1}='records changed during replay';end
if isempty(R.problems),R.outcome='VERIFIED';else,R.outcome='VERIFY_HOLD';end
end

function H=treeHash(root)
d=dir(fullfile(root,'**','*'));d=d(~[d.isdir]);H=cell(numel(d),2);
for k=1:numel(d),p=fullfile(d(k).folder,d(k).name);H{k,1}=p;H{k,2}=lower(g2_sha256_file(p));end
H=sortrows(H,1);
end
