function R=lp2a2_eq_closure_verify(execRepo,varargin)
%LP2A2_EQ_CLOSURE_VERIFY  Corrected READ-ONLY replay of the LP2-A2 equivalence record sets (version 2).
% Separate from, and outside the source digests of, the historical pinned g2_lp2a2_eq_verify
% (matlab/g2/lp2a2, not modified). It calls the ORIGINAL pinned context (digest and token checks of
% every pinned source) and the ORIGINAL pinned comparator g2_lp2a2_eq_compare, repeats the
% historical recomputation line for line, and replaces only the final list comparison by
% lp2a2_eq_failed_check (explicit, class-aware normalization of a legitimate empty JSON array;
% malformed lists rejected, mismatches preserved).
% Zero solves, zero writes to the records: files are opened for reading only; SHA-256, size and
% modification time of every file are taken before and after and must be identical.
%
%   R=lp2a2_eq_closure_verify(execRepo, 'RecordsRoot',dir, 'ReferenceDump',json, 'ReferenceArchive',json, 'MetricTol',tol)
%
%  execRepo          clone holding the pinned sources and the (git-ignored) records
%  RecordsRoot       default: execRepo/<policy.outputRoot>; may point at a copy (mutation tests only)
%  ReferenceDump     committed audit dump (verify/LP2A2_EQ_A2_AUDIT_DUMP.json): per-file SHA-256
%  ReferenceArchive  committed archive record (post/LP2A2_EQ_A2_ARCHIVE_RECORD.json): memberSHA256
% Outcome VERIFIED_V2 only if exactly four complete expected records pass every check;
% otherwise VERIFY_HOLD_V2 with the problems listed; NO_RECORDS if the root does not exist.
ip=inputParser;addParameter(ip,'RecordsRoot','',@ischar);addParameter(ip,'ReferenceDump','',@ischar);
addParameter(ip,'ReferenceArchive','',@ischar);addParameter(ip,'MetricTol',1e-12,@isnumeric);parse(ip,varargin{:});o=ip.Results;
addpath(fullfile(execRepo,'matlab','g2'),'-begin');addpath(fullfile(execRepo,'matlab','g2','lp2a2'),'-begin');
C=g2_lp2a2_eq_context('Preflight',false);pol=C.policy;
root=o.RecordsRoot;if isempty(root),root=fullfile(C.repo,pol.outputRoot);end
R=struct('schema','NewMetacomp.G2.LP2A2.EQ.ClosureVerify.v2','outcome','NO_RECORDS','problems',{{}},'solves',struct([]), ...
 'unchanged',true,'physicalSolves',0,'token',C.token,'policySHA256',C.policySHA256,'g2SourceSHA256',C.g2SourceSHA256, ...
 'lp2SourceSHA256',C.lp2SourceSHA256,'lp2a2SourceSHA256',C.lp2a2SourceSHA256,'archivedManifestSHA256',C.archivedManifestSHA256, ...
 'filesExpected',0,'filesFound',0,'extraFiles',{{}},'missingFiles',{{}},'reference',struct('dumpChecked',0,'archiveChecked',0,'mismatches',{{}}), ...
 'metricTolerance',o.MetricTol);
if ~isfolder(root),return,end
T0=treeInfo(root);
% ---- expected record set: exactly the six files of each of the four solves, nothing else
names={'COMPARISON.json','MESH.mat','PHASE.mat','PHASE.mat.manifest.json','SOLUTION.mat','SOLUTION.mat.manifest.json'};
expRel=cell(0,1);for k=1:numel(pol.solves),for n=names,expRel{end+1,1}=[pol.solves(k).id '/' n{1}];end,end %#ok<AGROW>
found={T0.rel}.';R.filesExpected=numel(expRel);R.filesFound=numel(found);
R.missingFiles=setdiff(expRel,found).';R.extraFiles=setdiff(found,expRel).';
if ~isempty(R.missingFiles),R.problems{end+1}=sprintf('RECORD_SET: %d expected file(s) missing',numel(R.missingFiles));end
if ~isempty(R.extraFiles),R.problems{end+1}=sprintf('RECORD_SET: %d unexpected file(s)',numel(R.extraFiles));end
% ---- committed reference hashes (optional)
refD=struct();refA=struct();
if ~isempty(o.ReferenceDump),refD=jsondecode(fileread(o.ReferenceDump)).solves;end
if ~isempty(o.ReferenceArchive),refA=jsondecode(fileread(o.ReferenceArchive)).memberSHA256;end
for q=1:numel(T0)
 rel=T0(q).rel;slash=strfind(rel,'/');if isempty(slash),continue,end;sid=rel(1:slash(1)-1);fn=rel(slash(1)+1:end);
 if ~isempty(fieldnames(refD))
  key=strrep(sid,'-','_');fk=strrep(fn,'.','_');
  if isfield(refD,key)&&isfield(refD.(key).sha256,fk)
   R.reference.dumpChecked=R.reference.dumpChecked+1;
   if ~strcmpi(refD.(key).sha256.(fk),T0(q).sha),R.reference.mismatches{end+1}=['dump: ' rel];end
  end
 end
 if ~isempty(fieldnames(refA))
  ak=matlab.lang.makeValidName(['outputs/g2_lp2a2_eq_v1/' rel]);
  if isfield(refA,ak)
   R.reference.archiveChecked=R.reference.archiveChecked+1;
   if ~strcmpi(refA.(ak),T0(q).sha),R.reference.mismatches{end+1}=['archive: ' rel];end
  end
 end
end
if ~isempty(R.reference.mismatches),R.problems{end+1}=sprintf('REFERENCE: %d file hash(es) differ from the committed reference',numel(R.reference.mismatches));end
if ~isempty(o.ReferenceDump)&&R.reference.dumpChecked~=R.filesExpected&&isempty(R.missingFiles),R.problems{end+1}='REFERENCE: committed audit dump did not cover every expected file';end
if ~isempty(o.ReferenceArchive)&&R.reference.archiveChecked~=R.filesExpected&&isempty(R.missingFiles),R.problems{end+1}='REFERENCE: committed archive record did not cover every expected file';end
% ---- sources of the historical replay (not modified; read-only)
pol9=jsondecode(fileread(fullfile(C.here,'lp2','G2_LP2A_POLICY_v1.json')));pol9.caps.maxStateIndex=9;pol9.caps.maxArcLength_mm=61.4;
lp=jsondecode(fileread(fullfile(C.here,'G2_LP1_POLICY_v2.json')));pm=jsondecode(fileread(fullfile(C.here,'G2_MATERIAL_POLICY_v1.json')));
po=struct('onCircleTol_mm',pm.phaseMap.onCircleTolerance_mm,'minGap_mm',pm.phaseMap.minGapToNextT3Vertex_mm,'midsideTol_mm',pm.phaseMap.midsideOnChordTolerance_mm);
S=[];
for k=1:numel(pol.solves)
 s=pol.solves(k);sd=fullfile(root,s.id);f=@(n)fullfile(sd,n);
 r=struct('solveId',s.id,'recordsComplete',false,'links',struct(),'manifestsOK',false,'recomputedPass',false,'storedPass',false, ...
  'failedRecomputed',{{}},'failedStored',{{}},'failedNormalization','','compare',struct(),'pass',false,'problems',{{}});
 try
  if ~all(cellfun(@(n)isfile(f(n)),names)),r.problems{end+1}='RECORD_SET: incomplete records';S=[S r];R.problems{end+1}=[s.id ': incomplete records']; %#ok<AGROW>
   continue,end
  r.recordsComplete=true;
  Sx=load(f('SOLUTION.mat'));Sx=Sx.record;raw=fileread(f('COMPARISON.json'));Cm=jsondecode(raw);
  mh=lower(g2_sha256_file(f('MESH.mat')));ph=lower(g2_sha256_file(f('PHASE.mat')));sh=lower(g2_sha256_file(f('SOLUTION.mat')));
  L=struct('solutionMeshLink',strcmp(Sx.meshSHA256,mh),'solutionPhaseLink',strcmp(Sx.phaseSHA256,ph), ...
   'comparisonSolutionLink',strcmp(Cm.solutionSHA256,sh),'comparisonMeshLink',strcmp(Cm.meshSHA256,mh), ...
   'comparisonArchivedSolutionPin',strcmpi(Cm.archivedSolutionSHA256,pol.pins.archivedS8.(s.caseId).SOLUTION), ...
   'token',strcmp(Sx.token,C.token),'solveIdEqual',strcmp(Cm.solveId,s.id),'caseIdEqual',strcmp(Cm.caseId,s.caseId));
  mfs={'PHASE.mat','PHASE.mat.manifest.json',ph,'NewMetacomp.G2.LP2A2.EQ.Phase.v1';'SOLUTION.mat','SOLUTION.mat.manifest.json',sh,'NewMetacomp.G2.LP2A2.EQ.Solution.v1'};
  mok=true;
  for q=1:size(mfs,1)
   M=jsondecode(fileread(f(mfs{q,2})));
   mok=mok&&strcmpi(M.SHA256,mfs{q,3})&&double(M.bytes)==dir(f(mfs{q,1})).bytes&&strcmp(M.recordSchema,mfs{q,4});
  end
  r.links=L;r.manifestsOK=mok;
  lk=all(cell2mat(struct2cell(L)))&&mok;
  % ---- recomputation (line for line as g2_lp2a2_eq_verify)
  ab=fullfile(C.archiveBase,s.caseId);St=load(fullfile(ab,'S8','STATE.mat'));St=St.record;So=load(fullfile(ab,'S8','SOLUTION.mat'));So=So.record;
  Tm=load(fullfile(ab,'TERMINAL.mat'));Tm=Tm.record;Ma=load(fullfile(ab,'S8','MESH.mat'));D=load(f('MESH.mat'));
  PMn=g2_material_phase_map(D.X6,D.T6,lp.geometry.centres_mm,6.35*ones(3,1),19.05*ones(3,1),po);PMa=g2_material_phase_map(Ma.X6,Ma.T6,lp.geometry.centres_mm,6.35*ones(3,1),19.05*ones(3,1),po);
  Sn=St;Sn.KI=Sx.K.KI;Sn.KII=Sx.K.KII;F=g2_lp2_forecast(Sn,pol9);
  Nn=struct('K',Sx.K,'D',D,'activeArea_mm2',Sx.K.activeArea_mm2,'chordsPerCircle',arrayfun(@(q)size(q.chords,1),PMn.interfaces),'S9tip_mm',F.polyline_mm(end,:));
  An=struct('state',St,'K',So.K,'D',Ma,'S9tip_mm',Tm.candidate.polyline_mm(end,:),'chordsPerCircle',arrayfun(@(q)size(q.chords,1),PMa.interfaces));
  Rc=g2_lp2a2_eq_compare(Nn,An,pol.tolerances);
  Q=lp2a2_eq_compare_records(raw,Cm,Rc,o.MetricTol);
  r.recomputedPass=Rc.pass;r.storedPass=isfield(Cm,'pass')&&islogical(Cm.pass)&&isscalar(Cm.pass)&&Cm.pass;
  r.failedRecomputed=Q.failed.recomputed;r.failedStored=Q.failed.stored;r.failedNormalization=Q.failed.note;
  Qs=rmfield(Q,'failed');Qs.failedListRawOK=Q.failed.rawOK;Qs.failedListEqual=Q.failed.equal;r.compare=Qs;
  r.problems=Q.problems;if ~lk,r.problems{end+1}='LINKS: a hash link, token, identifier or manifest check failed';end
  r.pass=lk&&Q.ok&&Rc.pass&&r.storedPass;
 catch ME
  r.problems{end+1}=['RECOMPUTE_ERROR: ' ME.identifier ': ' ME.message];
 end
 if ~r.pass,R.problems{end+1}=[s.id ': ' strjoin(r.problems,' | ')];end
 S=[S r]; %#ok<AGROW>
end
R.solves=S;if isempty(S),S=struct('pass',{});end
T1=treeInfo(root);R.unchanged=isequal({T0.rel},{T1.rel})&&isequal({T0.sha},{T1.sha})&&isequal([T0.bytes],[T1.bytes])&&isequal([T0.datenum],[T1.datenum]);
if ~R.unchanged,R.problems{end+1}='records changed during replay';end
R.files=rmfield(T0,'datenum');
R.nSolvesPass=sum([S.pass]);
if isempty(R.problems)&&numel(S)==4&&all([S.pass]),R.outcome='VERIFIED_V2';else,R.outcome='VERIFY_HOLD_V2';end
end

function T=treeInfo(root)
% relative path (forward slashes), size, modification time, lower-case SHA-256 of every file under root
d=dir(fullfile(root,'**','*'));d=d(~[d.isdir]);T=struct('rel',{},'bytes',{},'datenum',{},'sha',{});
for k=1:numel(d)
 p=fullfile(d(k).folder,d(k).name);rel=strrep(p(numel(root)+2:end),filesep,'/');
 T(end+1)=struct('rel',rel,'bytes',d(k).bytes,'datenum',d(k).datenum,'sha',lower(g2_sha256_file(p))); %#ok<AGROW>
end
[~,o]=sort({T.rel});T=T(o);
end
