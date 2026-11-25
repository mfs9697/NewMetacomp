% LP2-A2 equivalence campaign G2-LP2A2-EQ-001: post-revocation probe. Correct-token Run=true calls and the external wrapper
% must be refused (HOLD_UNAUTHORIZED) with no write, no solve and unchanged campaign records. No FEM.
ex='<repo>';
out='<scratch>\post';
addpath(fullfile(ex,'matlab','g2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a2'),'-begin');
try
 C=g2_lp2a2_eq_context();
 [~,hh]=system(sprintf('git -C "%s" rev-parse HEAD',ex));head=strtrim(hh);
 assert(~isfile(fullfile(ex,'matlab','g2','lp2a2','G2_LP2A2_EQ_GO.json')),'PR:GO','GO still present.');
 rd=fullfile(ex,'outputs','g2_lp2a2_eq_v1');
 H0=hashes(rd);L0=listing(fullfile(ex,'outputs'));[~,g0]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 ids={'EQ-H','EQ-stiff13','EQ-soft2','EQ-soft1'};P=struct('solveId',{},'identifier',{},'message',{});
 for k=1:4
  i='<no error>';m='';try,g2_lp2a2_eq_run(ids{k},'Run',true,'Token',C.token);catch ME,i=ME.identifier;m=ME.message;end
  P(end+1)=struct('solveId',ids{k},'identifier',i,'message',m); %#ok<SAGROW>
  fprintf('POSTREV_RUN %s %s | %s\n',ids{k},i,m);
 end
 W=g2_lp2a2_eq_campaign(C.token);
 fprintf('POSTREV_WRAPPER outcome=%s solvesCalled=%d reason=%s\n',W.outcome,W.solvesCalled,W.reason);
 H1=hashes(rd);L1=listing(fullfile(ex,'outputs'));[~,g1]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 R=struct('schema','NewMetacomp.G2.LP2A2.EQ.PostRevocation.v1','sourceCommit',head,'token',C.token,'probes',P, ...
  'wrapper',struct('outcome',W.outcome,'solvesCalled',W.solvesCalled,'reason',W.reason), ...
  'campaignFilesUnchanged',isequal(H0,H1),'campaignFiles',size(H0,1),'outputsListingUnchanged',isequal(L0,L1),'gitClean',isempty(strtrim(g0))&&isempty(strtrim(g1)),'physicalSolves',0);
 R.outputRootExistsAfter=isfolder(rd);R.wrapperReason=W.reason;
 R.pass=all(strcmp({P.identifier},'G2LP2A2:HOLD_UNAUTHORIZED'))&&strcmp(W.outcome,'HOLD_UNAUTHORIZED')&&W.solvesCalled==0&&R.campaignFilesUnchanged&&R.outputsListingUnchanged&&R.gitClean;
 fid=fopen(fullfile(out,'LP2A2_EQ_POST_REVOCATION.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
 fprintf('POSTREV_RESULT pass=%d files=%d (%d) listing=%d git=%d commit=%s\n',R.pass,R.campaignFilesUnchanged,R.campaignFiles,R.outputsListingUnchanged,R.gitClean,head);
catch ME
 fprintf(2,'POSTREV_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
function L=listing(folder)
d=dir(fullfile(folder,'**','*'));L=sort(strcat({d.folder},filesep,{d.name}))';
end
function H=hashes(root)
H=cell(0,2);if ~isfolder(root),return,end
d=dir(fullfile(root,'**','*'));d=d(~[d.isdir]);
for k=1:numel(d),f=fullfile(d(k).folder,d(k).name);H(end+1,:)={f,lower(g2_sha256_file(f))};end %#ok<AGROW>
if ~isempty(H),H=sortrows(H,1);end
end
