function lp2a2_eq_closure_run(stage,execRepo,outDir,refDump,refArchive,hashcheck)
%LP2A2_EQ_CLOSURE_RUN  Driver of the LP2-A2 read-only verification closure (zero solves, no GO, no write to records).
%  stage 'verify'  pinned context, historical replay (reproduces VERIFY_HOLD), corrected replay v2, file hashes
%  stage 'tests'   JSON round-trip regression and mutation tests (on a copy)
%  stage 'final'   corrected replay again; the 24 files compared with stage 'verify' and the committed references
%  Writes LP2A2_EQ_CLOSURE_<STAGE>.json into outDir (outside the records).
if ~isfolder(outDir),mkdir(outDir);end
here=fileparts(mfilename('fullpath'));addpath(here);
addpath(fullfile(execRepo,'matlab','g2'),'-begin');addpath(fullfile(execRepo,'matlab','g2','lp2a2'),'-begin');
t0=tic;
switch stage
 case 'verify'
  Z=struct('stage','verify','schema','NewMetacomp.G2.LP2A2.EQ.ClosureStage.v1');
  Z.git=gitInfo(execRepo);
  C=g2_lp2a2_eq_context('Preflight',false);
  H=jsondecode(fileread(hashcheck));
  Z.pins=struct('policySHA256',C.policySHA256,'g2SourceSHA256',C.g2SourceSHA256,'lp2SourceSHA256',C.lp2SourceSHA256, ...
   'lp2a2SourceSHA256',C.lp2a2SourceSHA256,'archivedManifestSHA256',C.archivedManifestSHA256,'token',C.token);
  Z.pinsEqualHistoricalCampaignPins=strcmp(C.token,H.token)&&strcmp(C.policySHA256,H.policySHA256)&&strcmp(C.g2SourceSHA256,H.g2SourceSHA256) ...
   &&strcmp(C.lp2SourceSHA256,H.lp2SourceSHA256)&&strcmp(C.lp2a2SourceSHA256,H.lp2a2SourceSHA256)&&strcmp(C.archivedManifestSHA256,H.archivedManifestSHA256);
  Z.goFilePresent=isfile(fullfile(execRepo,'matlab','g2','lp2a2','G2_LP2A2_EQ_GO.json'));
  Lg=g2_lp2a2_eq_verify();
  Z.legacyReplay=struct('outcome',Lg.outcome,'unchanged',Lg.unchanged,'physicalSolves',Lg.physicalSolves,'problems',{Lg.problems}, ...
   'solves',{cellfun(@(r)struct('solveId',r.solveId,'links',r.links,'recomputedPass',r.recomputedPass,'storedPass',r.storedPass,'reproduced',r.reproduced,'pass',r.pass),Lg.solves,'UniformOutput',false)});
  Z.v2=lp2a2_eq_closure_verify(execRepo,'ReferenceDump',refDump,'ReferenceArchive',refArchive);
  Z.gitAfter=gitInfo(execRepo);
 case 'tests'
  Z=lp2a2_eq_closure_tests(execRepo,outDir,'ReferenceDump',refDump,'ReferenceArchive',refArchive,'Scratch',fullfile(outDir,'tmp_cases'));
  if isfolder(fullfile(outDir,'tmp_cases')),rmdir(fullfile(outDir,'tmp_cases'),'s');end
  Z.stage='tests';
 case 'final'
  Z=struct('stage','final','schema','NewMetacomp.G2.LP2A2.EQ.ClosureStage.v1');
  Z.git=gitInfo(execRepo);
  Z.v2=lp2a2_eq_closure_verify(execRepo,'ReferenceDump',refDump,'ReferenceArchive',refArchive);
  P=jsondecode(fileread(fullfile(outDir,'LP2A2_EQ_CLOSURE_VERIFY.json')));
  a=P.v2.files;b=Z.v2.files;
  Z.filesEqualToStageVerify=numel(a)==numel(b)&&isequal({a.rel}.',{b.rel}.')&&isequal({a.sha}.',{b.sha}.')&&isequal([a.bytes].',[b.bytes].');
  Z.gitAfter=gitInfo(execRepo);
 otherwise
  error('Unknown stage %s',stage);
end
Z.elapsed_s=toc(t0);Z.matlab=version;Z.physicalSolves=0;
fid=fopen(fullfile(outDir,['LP2A2_EQ_CLOSURE_' upper(stage) '.json']),'w');fwrite(fid,jsonencode(Z,'PrettyPrint',true),'char');fclose(fid);
if isfield(Z,'v2'),fprintf('CLOSURE_%s v2 outcome=%s solvesPass=%d unchanged=%d problems=%d files=%d refDump=%d refArchive=%d refMismatch=%d\n', ...
  upper(stage),Z.v2.outcome,Z.v2.nSolvesPass,Z.v2.unchanged,numel(Z.v2.problems),Z.v2.filesFound,Z.v2.reference.dumpChecked,Z.v2.reference.archiveChecked,numel(Z.v2.reference.mismatches));end
if isfield(Z,'legacyReplay'),fprintf('CLOSURE_LEGACY outcome=%s unchanged=%d\n',Z.legacyReplay.outcome,Z.legacyReplay.unchanged);end
end

function G=gitInfo(ex)
[~,h]=system(sprintf('git -C "%s" rev-parse HEAD',ex));[~,s]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
G=struct('head',strtrim(h),'statusClean',isempty(strtrim(s)));
end
