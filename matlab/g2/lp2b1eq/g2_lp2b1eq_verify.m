function R=g2_lp2b1eq_verify(C,varargin)
%G2_LP2B1EQ_VERIFY  Read-only replay of the G2-LP2B1-EQ-001 records (zero solves, zero writes).
%  R = g2_lp2b1eq_verify(C)                       C = g2_lp2b1eq_context('Preflight',false) (or a test context)
%  R = g2_lp2b1eq_verify(C,'MetricTol',1e-12,'Reference',refFn)   refFn(C,s) replaces g2_lp2b1eq_reference (tests)
% Expected record set per solve (exactly; no extra, no missing): GEOMETRY_h040/ATTEMPT.json,
% GEOMETRY_h040/ATTEMPT_ARRAYS.mat, MESH.mat, PHASE.mat(+manifest), SOLUTION.mat(+manifest), COMPARISON.mat(+manifest),
% COMPARISON.json. A folder with HOLD.json is a preserved partial attempt (files must be a subset of the expected set).
% Solve folders must be a prefix of the fixed order; EQB-H-S10 may exist only after a complete EQUIVALENT_CASE
% EQB-soft1-S9 (global stop). RECEIPT.mat in the receipt root bound to the token. For every complete solve:
% manifests, hash links, token, identifiers, canonical MESH digest == pin == ATTEMPT digest, attempt arrays SHA,
% recomputation of the comparison from the stored SOLUTION K and MESH and the ARCHIVED reference
% (g2_lp2b1eq_compare_case), bitwise equality with COMPARISON.mat (outcome, validity, validation, criteria, failed,
% metrics, vectors) and, for COMPARISON.json, the corrected WP5 closure comparison (lp2a2_eq_compare_records:
% raw-JSON failed-list grammar, class-aware empty normalization, every criterion and metric; representation
% tolerance MetricTol) plus exact text equality of outcome and validation list. No empty-list masking: a missing or
% malformed list is a problem. SHA-256, size and modification time of every file before and after are identical.
% Outcomes: NO_RECORDS | VERIFIED_EQUIVALENT | VERIFIED_NOT_EQUIVALENT | VERIFIED_INFRASTRUCTURE_HOLD |
% VERIFIED_PARTIAL_HOLD | VERIFY_HOLD (any problem; R.problems).
ip=inputParser;addParameter(ip,'MetricTol',1e-12,@isnumeric);addParameter(ip,'Reference',[]);parse(ip,varargin{:});o=ip.Results;
refFn=o.Reference;if isempty(refFn),refFn=@g2_lp2b1eq_reference;end
ids=reshape(cellfun(@(x)x.id,C.solves,'UniformOutput',false),1,[]);root=C.runRoot;
names=sort({'GEOMETRY_h040/ATTEMPT.json','GEOMETRY_h040/ATTEMPT_ARRAYS.mat','MESH.mat','PHASE.mat','PHASE.mat.manifest.json','SOLUTION.mat', ...
 'SOLUTION.mat.manifest.json','COMPARISON.mat','COMPARISON.mat.manifest.json','COMPARISON.json'});
R=struct('schema','NewMetacomp.G2.LP2B1EQ.Verify.v1','outcome','NO_RECORDS','problems',{{}},'solves',{{}},'unchanged',true,'physicalSolves',0, ...
 'token',C.token,'policySHA256',C.policySHA256,'metricTolerance',o.MetricTol,'receipt',struct('present',false,'tokenOK',false));
if ~isfolder(root),return,end
T0=[treeInfo(root);treeInfo(C.receiptRoot)];
[Rr,~,okr]=g2_trajectory_record('read',fullfile(C.receiptRoot,'RECEIPT.mat'));
R.receipt=struct('present',okr,'tokenOK',okr&&strcmp(Rr.token,C.token)&&strcmp(Rr.campaignId,C.policy.campaignId));
if ~R.receipt.tokenOK,bad('RECEIPT: missing, failing its manifest or bound to another token');end
d=dir(root);d=d([d.isdir]&~ismember({d.name},{'.','..'}));present=reshape({d.name},1,[]);
top=dir(root);top=top(~[top.isdir]);if ~isempty(top),bad(sprintf('RECORD_SET: %d unexpected file(s) at the run root',numel(top)));end
extra=setdiff(present,ids);if ~isempty(extra),bad(['RECORD_SET: unexpected folder(s) ' strjoin(extra,',')]);end
pres=ismember(ids,present);
if any(pres)&&~isequal(pres,[true(1,find(pres,1,'last')) false(1,numel(ids)-find(pres,1,'last'))]),bad('ORDER: solve folders are not a prefix of the fixed order');end
last='';
for k=find(pres)
 s=C.solves{k};sd=fullfile(root,s.id);r=struct('solveId',s.id,'kind','','outcome','','pass',false,'problems',{{}},'compare',[]);
 Ti=treeInfo(sd);rel={Ti.rel};
 if any(strcmp(rel,'HOLD.json'))
  r.kind='PARTIAL_HOLD';rest=setdiff(rel,{'HOLD.json'});
  if ~all(ismember(rest,names)),r.problems{end+1}='RECORD_SET: partial folder holds unexpected files';end
  try,H=jsondecode(fileread(fullfile(sd,'HOLD.json')));r.hold=H;catch,r.problems{end+1}='HOLD.json unreadable';end
 elseif isequal(sort(rel),names)
  r.kind='COMPLETE';
  try
   r=complete(r,C,s,sd,refFn,o.MetricTol);
  catch ME
   r.problems{end+1}=['RECOMPUTE_ERROR: ' ME.identifier ': ' ME.message];
  end
 else
  r.kind='INCOMPLETE';r.missing=setdiff(names,rel);r.extra=setdiff(rel,names);r.problems{end+1}='RECORD_SET: incomplete or extra files without a HOLD record';
 end
 if k<find(pres,1,'last')&&~(strcmp(r.kind,'COMPLETE')&&strcmp(r.outcome,'EQUIVALENT_CASE')&&isempty(r.problems))
  r.problems{end+1}='GLOBAL_STOP: a later solve exists after a non-equivalent, partial or failing solve';
 end
 for q=r.problems,bad([s.id ': ' q{1}]);end
 R.solves{end+1}=r;last=r;
end
T1=[treeInfo(root);treeInfo(C.receiptRoot)];
R.unchanged=isequal({T0.rel},{T1.rel})&&isequal({T0.sha},{T1.sha})&&isequal([T0.bytes],[T1.bytes])&&isequal([T0.datenum],[T1.datenum]);
if ~R.unchanged,bad('records changed during replay');end
R.files=rmfield(T0,'datenum');
if ~isempty(R.problems),R.outcome='VERIFY_HOLD';
elseif isempty(last),R.outcome='VERIFY_HOLD';R.problems{end+1}='run root without solve folders';
elseif strcmp(last.kind,'PARTIAL_HOLD'),R.outcome='VERIFIED_PARTIAL_HOLD';
elseif strcmp(last.outcome,'INPUT_INVALID'),R.outcome='VERIFIED_INFRASTRUCTURE_HOLD';
elseif strcmp(last.outcome,'NOT_EQUIVALENT'),R.outcome='VERIFIED_NOT_EQUIVALENT';
elseif numel(R.solves)==numel(ids)&&strcmp(last.outcome,'EQUIVALENT_CASE'),R.outcome='VERIFIED_EQUIVALENT';
else,R.outcome='VERIFIED_PARTIAL_HOLD';
end
 function bad(x),R.problems{end+1}=x;end
end

function r=complete(r,C,s,sd,refFn,mtol)
f=@(n)fullfile(sd,strrep(n,'/',filesep));P={};
[Ph,ph,o1]=g2_trajectory_record('read',f('PHASE.mat'));[So,sh,o2]=g2_trajectory_record('read',f('SOLUTION.mat'));[Cb,cmh,o3]=g2_trajectory_record('read',f('COMPARISON.mat'));
if ~(o1&&o2&&o3),P{end+1}='MANIFEST: PHASE, SOLUTION or COMPARISON record fails its manifest';r.problems=P;return,end
mh=lower(g2_sha256_file(f('MESH.mat')));raw=fileread(f('COMPARISON.json'));Cj=jsondecode(raw);D=load(f('MESH.mat'));
At=jsondecode(fileread(f('GEOMETRY_h040/ATTEMPT.json')));ah=lower(g2_sha256_file(f('GEOMETRY_h040/ATTEMPT_ARRAYS.mat')));canon=g2_lp2b1eq_canon(D);
L=struct('phaseMesh',strcmpi(Ph.meshSHA256,mh),'solutionMesh',strcmpi(So.meshSHA256,mh),'solutionPhase',strcmpi(So.phaseSHA256,ph), ...
 'comparisonSolution',strcmpi(Cb.solutionSHA256,sh)&&strcmpi(Cj.solutionSHA256,sh),'comparisonMesh',strcmpi(Cb.meshSHA256,mh)&&strcmpi(Cj.meshSHA256,mh), ...
 'comparisonPhase',strcmpi(Cb.phaseSHA256,ph)&&strcmpi(Cj.phaseSHA256,ph),'jsonBindsRecord',isfield(Cj,'comparisonRecordSHA256')&&strcmpi(Cj.comparisonRecordSHA256,cmh), ...
 'archivedPin',strcmpi(Cb.archivedSolutionSHA256,s.archived.SOLUTION.record.sha256)&&strcmpi(So.archivedSolutionSHA256,s.archived.SOLUTION.record.sha256), ...
 'token',strcmp(So.token,C.token)&&strcmp(Cb.token,C.token)&&strcmp(Ph.token,C.token),'policy',strcmpi(So.policySHA256,C.policySHA256), ...
 'identity',strcmp(So.solveId,s.id)&&strcmp(Cb.solveId,s.id)&&strcmp(Ph.solveId,s.id)&&strcmp(So.caseId,s.caseId)&&strcmp(Cj.solveId,s.id), ...
 'canonical',strcmpi(canon,s.qualification.canonicalSHA256)&&strcmpi(So.canonicalSHA256,canon)&&strcmpi(Ph.canonicalSHA256,canon)&&strcmpi(At.canonicalSHA256,canon), ...
 'attemptArrays',strcmpi(At.arraysFileSHA256,ah)&&isequal(At.pass,true));
r.links=L;lv=cell2mat(struct2cell(L));ln=fieldnames(L);
if ~all(lv),P{end+1}=['LINKS: ' strjoin(ln(~lv).',',')];end
% ---- recomputation from stored K and MESH and the archived reference
Ref=refFn(C,s);if ~Ref.pass,P{end+1}='REFERENCE: archived reference no longer qualifies';end
Rc=g2_lp2b1eq_compare_case(C,s,Ref,So.K,D,Ph.chordsPerCircle);
lp=jsondecode(fileread(fullfile(C.here,'G2_LP1_POLICY_v2.json')));pm=jsondecode(fileread(fullfile(C.here,'G2_MATERIAL_POLICY_v1.json')));
po=struct('onCircleTol_mm',pm.phaseMap.onCircleTolerance_mm,'minGap_mm',pm.phaseMap.minGapToNextT3Vertex_mm,'midsideTol_mm',pm.phaseMap.midsideOnChordTolerance_mm);
PMn=g2_material_phase_map(D.X6,D.T6,lp.geometry.centres_mm,6.35*ones(3,1),19.05*ones(3,1),po);
ch=arrayfun(@(q)size(q.chords,1),PMn.interfaces);if ~isequal(ch(:).',reshape(Ph.chordsPerCircle,1,3)),P{end+1}='PHASE: stored chords differ from the recomputed phase map';end
% ---- bitwise equality with the MAT comparison record
B=struct('outcome',isequal(Cb.outcome,Rc.outcome),'valid',isequal(Cb.valid,Rc.valid),'validation',isequal(sort(Cb.validation(:)).',sort(Rc.validation(:)).'), ...
 'criteria',isequal(Cb.criteria,Rc.criteria),'failed',isequal(sort(Cb.failed(:)).',sort(Rc.failed(:)).'),'metrics',isequal(Cb.metrics,Rc.metrics),'vectors',isequal(Cb.vectors,Rc.vectors), ...
 'pass',isequal(Cb.pass,Rc.pass));
bv=cell2mat(struct2cell(B));bn=fieldnames(B);if ~all(bv),P{end+1}=['MAT_RECORD: ' strjoin(bn(~bv).',',')];end
% ---- JSON record: exact outcome/validation text, then the corrected WP5 closure comparison
jv=isfield(Cj,'validation')&&(iscell(Cj.validation)||(isa(Cj.validation,'double')&&isempty(Cj.validation)));
if jv,vl=Cj.validation;if ~iscell(vl),vl=cell(1,0);end,else,vl={};end
Jx=struct('outcome',isfield(Cj,'outcome')&&strcmp(Cj.outcome,Rc.outcome),'valid',isfield(Cj,'valid')&&isequal(Cj.valid,Rc.valid), ...
 'validation',jv&&isequal(sort(vl(:)).',sort(Rc.validation(:)).'),'validationRaw',~isempty(regexp(raw,'"validation"\s*:\s*\[','once')));
r.jsonExact=Jx;jx=cell2mat(struct2cell(Jx));if ~all(jx),P{end+1}=['JSON_RECORD: ' strjoin(fieldnames(Jx).',',')];end
if Rc.valid
 Q=lp2a2_eq_compare_records(raw,Cj,Rc,mtol);
 r.compare=rmfield(Q,'failed');r.compare.failedListRawOK=Q.failed.rawOK;r.compare.failedListEqual=Q.failed.equal;
 for q=Q.problems,P{end+1}=['JSON_CLOSURE: ' q{1}];end %#ok<AGROW>
 for v={'newChordsPerCircle','archivedChordsPerCircle','newNextTip_mm','archivedNextTip_mm'}
  if ~(isfield(Cj,'vectors')&&isfield(Cj.vectors,v{1})&&isequal(reshape(Cj.vectors.(v{1}),1,[]),Rc.vectors.(v{1}))),P{end+1}=['JSON_VECTOR: ' v{1}];end %#ok<AGROW>
 end
else
 Fq=lp2a2_eq_failed_check(raw,Cj,Rc.failed,fieldnames(Rc.criteria));
 if ~(Fq.rawOK&&Fq.storedOK&&Fq.equal),P{end+1}=['JSON_FAILED_LIST: ' Fq.why];end
end
r.outcome=Rc.outcome;r.recomputedPass=Rc.pass;r.storedPass=Cb.pass;r.problems=P;r.pass=isempty(P);
end

function T=treeInfo(root)
T=struct('rel',{},'bytes',{},'datenum',{},'sha',{});if ~isfolder(root),T=T(:);return,end
d=dir(fullfile(root,'**','*'));d=d(~[d.isdir]);
for k=1:numel(d)
 p=fullfile(d(k).folder,d(k).name);rel=strrep(p(numel(root)+2:end),filesep,'/');
 T(end+1,1)=struct('rel',rel,'bytes',d(k).bytes,'datenum',d(k).datenum,'sha',lower(g2_sha256_file(p))); %#ok<AGROW>
end
[~,o]=sort({T.rel});T=T(o);
end
