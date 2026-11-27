% LP2-B1-EQ closure (READ-ONLY; after revocation of GO_LP2B1_EQ):
% 1 post-revocation correct-token refusals for BOTH solves under the real preflight, zero writes;
% 2 the read-only verifier g2_lp2b1eq_verify (tree unchanged);
% 3 a full dump of every run/receipt record plus raw little-endian float64 exports (shape in the index) of the new and
%   archived arrays, for the independent Python audit. Archived records are read by their policy paths directly.
ex='<repo>';
out='<scratch>\lp2b1eqrun';
restoredefaultpath;g2d=fullfile(ex,'matlab','g2');for f={'','lp2','lp2a2','lp2a3','lp2b1'},addpath(fullfile(g2d,f{1}));end
addpath(fullfile(ex,'scripts','g2','lp2a2','closure'));addpath(fullfile(g2d,'lp2b1eq'));
TOK=['G2LP2B1EQ|policy=b113a7c6d7b2e8fe9950d817ccca3c851c05f1e347c73f66c604b9c41e54eecb|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947', ...
 '|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca|lp2a2source=f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd', ...
 '|lp2a3source=fa3bcecfa9cd3044253d5a72253e2058bccd044d32345f51650dcd775f42e002|lp2b1source=9c7a1260e3bde5b59e1d93c47bc99cc4d7b89f9b0cc6e874572fb378f1717bee', ...
 '|lp2b1eqsource=74a0edd827daca5714a1347705abc1429a7a573116ad3c438f9e5a1c12dfbf1f|closure=76614f269810c6970544bca0c1c0f84ebf9131935554ebd75e57e24f819f65f7', ...
 '|references=63014a95ebeebd127ae094e9254331d6e32e314902b6c1d6ac2bf8abbeb3d89d|qualification=441b1eadf330a720255f2c6b178c0c51a822e4ad99a24d0318230c0884c5d5ad', ...
 '|solves=EQB-soft1-S9,EQB-H-S10|limit=2|seed=0.40|campaign=G2-LP2B1-EQ-001|run=run_lp2b1_eq_v1'];
ids={'EQB-soft1-S9','EQB-H-S10'};summ=fullfile(ex,'outputs','LP2B1EQ_CAMPAIGN.json');
% ---------------------------------------------------------------- 1 post-revocation refusals (real preflight)
try
 C=g2_lp2b1eq_context();H=g2_lp2a2_git('head',ex);
 assert(~isfile(C.goFile),'POST:GO','GO still present.');
 T0=treeHash(C.runRoot);T0r=treeHash(C.receiptRoot);s0=lower(g2_sha256_file(summ));L0=listing(fullfile(ex,'outputs'));[~,g0]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 P=struct('solveId',{},'identifier',{},'message',{});
 for k=1:2,i='<no error>';m='';try,g2_lp2b1eq_run(ids{k},'Run',true,'Token',TOK);catch ME,i=ME.identifier;m=ME.message;end,P(end+1)=struct('solveId',ids{k},'identifier',i,'message',m);fprintf('POSTREV %s %s\n',ids{k},i);end %#ok<SAGROW>
 T1=treeHash(C.runRoot);T1r=treeHash(C.receiptRoot);s1=lower(g2_sha256_file(summ));L1=listing(fullfile(ex,'outputs'));[~,g1]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 PR=struct('sourceCommit',H.value,'tokenEqualsAuthorization',strcmp(C.token,TOK),'goAbsent',~isfile(C.goFile),'probes',P,'runFilesUnchanged',isequal(T0,T1), ...
  'receiptUnchanged',isequal(T0r,T1r),'summaryUnchanged',strcmp(s0,s1),'outputsListingUnchanged',isequal(L0,L1),'runFiles',size(T0,1),'receiptFiles',size(T0r,1), ...
  'gitClean',isempty(strtrim(g0))&&isempty(strtrim(g1)),'physicalSolves',0,'externalEntryInvoked',false);
 PR.pass=all(strcmp({P.identifier},'G2LP2B1EQ:HOLD_UNAUTHORIZED'))&&PR.runFilesUnchanged&&PR.receiptUnchanged&&PR.summaryUnchanged&&PR.outputsListingUnchanged&&PR.gitClean&&PR.tokenEqualsAuthorization&&PR.goAbsent;
 wj(fullfile(out,'post','LP2B1EQ_POST_REVOCATION.json'),PR);fprintf('POSTREV_RESULT pass=%d runFiles=%d receipt=%d\n',PR.pass,PR.runFiles,PR.receiptFiles);
catch ME,fprintf(2,'POSTREV_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));end
% ---------------------------------------------------------------- 2 read-only verifier
try
 Cv=g2_lp2b1eq_context('Preflight',false);h0=treeHash(Cv.runRoot);Rv=g2_lp2b1eq_verify(Cv);Rv2=Rv;
 Rv2.treeUnchanged=isequal(h0,treeHash(Cv.runRoot));wj(fullfile(out,'verify','LP2B1EQ_VERIFY_POSTREV.json'),Rv2);
 fprintf('VERIFY outcome=%s unchanged=%d\n',Rv.outcome,Rv2.treeUnchanged);
catch ME,fprintf(2,'VERIFY_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));end
% ---------------------------------------------------------------- 3 full dump + raw exports
try
 pol=Cv.policy;fp=@(p)fullfile(ex,strrep(p,'/',filesep));raw=fullfile(out,'verify','raw');mkdir(raw);IX=struct('file',{},'shape',{},'class',{});
 A=struct('schema','NewMetacomp.G2.LP2B1EQ.RecordDump.v1','token',Cv.token,'files',struct(),'receipt',[],'solves',struct());
 A.files.run=relHash(Cv.runRoot,ex);A.files.receipt=relHash(Cv.receiptRoot,ex);
 if isfile(fullfile(Cv.receiptRoot,'RECEIPT.mat')),[Rc,rch,okr]=g2_trajectory_record('read',fullfile(Cv.receiptRoot,'RECEIPT.mat'));A.receipt=struct('record',Rc,'sha256',rch,'manifestOK',okr);end
 for k=1:2
  s=Cv.solves{k};id=s.id;fn=strrep(id,'-','_');sd=fullfile(Cv.runRoot,id);E=struct('solveId',id,'folderExists',isfolder(sd),'files',{{}});
  a=s.archived;[Sa,~,~]=g2_trajectory_record('read',fp(a.STATE.record.path));[Soa,~,~]=g2_trajectory_record('read',fp(a.SOLUTION.record.path));
  [Pha,~,~]=g2_trajectory_record('read',fp(a.PHASE.record.path));Ma=load(fp(a.MESH.path));
  E.archived=struct('state',small(Sa),'K',small(Soa.K),'phase',small(Pha),'meshT3',size(Ma.T3,1),'meshX6',size(Ma.X6,1));
  [IX]=ex64(IX,raw,[fn '_arch_u'],Soa.K.u);[IX]=ex64(IX,raw,[fn '_arch_X6'],Ma.X6);[IX]=ex64(IX,raw,[fn '_arch_T6'],Ma.T6);
  [IX]=ex64(IX,raw,[fn '_arch_up'],Ma.upperBankT6);[IX]=ex64(IX,raw,[fn '_arch_lo'],Ma.lowerBankT6);[IX]=ex64(IX,raw,[fn '_arch_poly'],Ma.crackPolyline);
  [IX]=ex64(IX,raw,[fn '_arch_statePoly'],Sa.polyline_mm);[IX]=ex64(IX,raw,[fn '_arch_tangent'],Sa.tangent);
  if isfield(Pha,'owner'),[IX]=ex64(IX,raw,[fn '_arch_owner'],Pha.owner);end
  if isfield(Pha,'labels'),[IX]=ex64(IX,raw,[fn '_arch_labels'],Pha.labels);end
  Q=load(fp(s.qualification.arrays.path));E.qualificationFields=fieldnames(Q);
  for q=reshape(fieldnames(Q),1,[]),x=Q.(q{1});if (isnumeric(x)||islogical(x))&&~isempty(x),[IX]=ex64(IX,raw,[fn '_qual_' q{1}],x);end,end
  if isfolder(sd)
   d=dir(sd);E.files=sort({d(~[d.isdir]).name});
   if isfile(fullfile(sd,'MESH.mat'))
    D=load(fullfile(sd,'MESH.mat'));E.meshFields=fieldnames(D);E.meshCanonical=g2_lp2b1eq_canon(D);E.meshFileSHA256=lower(g2_sha256_file(fullfile(sd,'MESH.mat')));
    for q={'X3','T3','X6','T6','upperBankT6','lowerBankT6','nodalQ','qActiveT6Rows','crackPolyline'},[IX]=ex64(IX,raw,[fn '_new_' q{1}],D.(q{1}));end
    E.meshScalars=small(rmfield(D,intersect(fieldnames(D),{'X3','T3','X6','T6','upperBankT6','lowerBankT6','nodalQ','qActiveT6Rows','crackPolyline'})));
   end
   if isfile(fullfile(sd,'PHASE.mat'))
    [Ph,phh,okp]=g2_trajectory_record('read',fullfile(sd,'PHASE.mat'));E.phase=small(Ph);E.phaseSHA256=phh;E.phaseManifestOK=okp;
    [IX]=ex64(IX,raw,[fn '_new_owner'],Ph.owner);[IX]=ex64(IX,raw,[fn '_new_labels'],Ph.labels);
    E.phaseAudit=struct('auditPass',fieldOr(Ph.audit,'pass'),'pairingPass',fieldOr(Ph.pairingAudit,'pass'),'auditGates',fieldOr(fieldOr(Ph.audit,'meshAudit'),'gatesPassed'),'pairingGates',fieldOr(Ph.pairingAudit,'gatesPassed'));
   end
   if isfile(fullfile(sd,'SOLUTION.mat'))
    [So,soh,oks]=g2_trajectory_record('read',fullfile(sd,'SOLUTION.mat'));E.solution=small(rmfield(So,'K'));E.solutionSHA256=soh;E.solutionManifestOK=oks;
    E.K=small(So.K);[IX]=ex64(IX,raw,[fn '_new_u'],So.K.u);
    M=g2_mts_direction(So.K.KI,So.K.KII);E.newMTS=small(M);
   end
   if isfile(fullfile(sd,'COMPARISON.mat'))
    [Cm,cmh,okc]=g2_trajectory_record('read',fullfile(sd,'COMPARISON.mat'));E.comparisonMat=Cm;E.comparisonSHA256=cmh;E.comparisonManifestOK=okc;
   end
   if isfile(fullfile(sd,'HOLD.json')),E.hold=jsondecode(fileread(fullfile(sd,'HOLD.json')));end
  end
  A.solves.(fn)=E;fprintf('DUMP %s exists=%d files=%d\n',id,E.folderExists,numel(E.files));
 end
 wj(fullfile(out,'verify','LP2B1EQ_RECORD_DUMP.json'),A);wj(fullfile(raw,'RAW_INDEX.json'),IX);fprintf('DUMP done raw=%d\n',numel(IX));
catch ME,fprintf(2,'DUMP_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));end

function IX=ex64(IX,raw,name,x)
f=fullfile(raw,[name '.f64']);fid=fopen(f,'w','l');fwrite(fid,double(x(:)),'float64');fclose(fid);
IX(end+1)=struct('file',[name '.f64'],'shape',size(x),'class',class(x));
end
function S=small(S)
% keep scalars, strings and small arrays (<= 64 elements); recurse into scalar structs; drop the rest
if ~isstruct(S)||~isscalar(S),return,end
f=fieldnames(S);
for k=1:numel(f)
 x=S.(f{k});
 if isstruct(x)&&isscalar(x),S.(f{k})=small(x);
 elseif isstruct(x)||iscell(x)
  if numel(x)>64,S=rmfield(S,f{k});end
 elseif ischar(x)||isstring(x)
 elseif (isnumeric(x)||islogical(x))&&numel(x)>64,S=rmfield(S,f{k});
 elseif isa(x,'function_handle'),S=rmfield(S,f{k});
 end
end
end
function v=fieldOr(S,f),if isstruct(S)&&isfield(S,f),v=S.(f);else,v=[];end,end
function L=listing(folder),d=dir(fullfile(folder,'**','*'));L=sort(strcat({d.folder},filesep,{d.name}))';end
function H=treeHash(root)
H=cell(0,2);if ~isfolder(root),return,end
d=dir(fullfile(root,'**','*'));d=d(~[d.isdir]);for k=1:numel(d),p=fullfile(d(k).folder,d(k).name);H(end+1,:)={p,lower(g2_sha256_file(p))};end %#ok<AGROW>
if ~isempty(H),H=sortrows(H,1);end
end
function S=relHash(root,ex)
H=treeHash(root);S=struct('path',strrep(strrep(H(:,1),[ex filesep],''),'\','/'),'sha256',H(:,2));
end
function wj(f,S),fid=fopen(f,'w');fwrite(fid,jsonencode(S,'PrettyPrint',true),'char');fclose(fid);end
