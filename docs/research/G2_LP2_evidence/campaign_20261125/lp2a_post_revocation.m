% LP2-A1 post-revocation probe: correct-token Run=true calls must be refused with no write. No FEM.
ex='<repo>';
out='<scratch>';
addpath(fullfile(ex,'matlab','g2','lp2'));
try
 assert(~isfolder(out));mkdir(out);C=g2_lp2_context();assert(~isfile(fullfile(C.lp2,'G2_LP2A_SCIENTIFIC_GO_v1.json')),'PR:GO','GO still present.');
 rd=fullfile(ex,'outputs','g2_lp2a_paths_v1','run_lp2a_s5_s8_v1');lroot=fullfile(ex,'outputs','g2_lp2a_campaign_ledger','G2-LP2A-001');
 H0=hashes(rd,lroot);L0=listing(fullfile(ex,'outputs'));[~,g0]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 P=struct('caseId',{},'identifier',{},'message',{});
 for id={'H','soft1'}
  i='<no error>';m='';try,g2_lp2_run('Case',id{1},'Run',true,'AuthToken',C.token,'RunName','run_lp2a_s5_s8_v1');catch ME,i=ME.identifier;m=ME.message;end
  P(end+1)=struct('caseId',id{1},'identifier',i,'message',m); %#ok<SAGROW>
  fprintf('POSTREV %s %s | %s\n',id{1},i,m);
 end
 H1=hashes(rd,lroot);L1=listing(fullfile(ex,'outputs'));[~,g1]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 R=struct('schema','NewMetacomp.G2.LP2A.PostRevocation.v1','sourceCommit',C.preflight.sourceCommit,'token',C.token,'probes',P, ...
  'campaignFilesUnchanged',isequal(H0,H1),'campaignFiles',size(H0,1),'outputsListingUnchanged',isequal(L0,L1),'gitClean',isempty(strtrim(g0))&&isempty(strtrim(g1)),'physicalSolves',0);
 R.pass=all(strcmp({P.identifier},'G2LP2:HOLD_UNAUTHORIZED_STATE'))&&R.campaignFilesUnchanged&&R.outputsListingUnchanged&&R.gitClean;
 fid=fopen(fullfile(out,'LP2A_POST_REVOCATION.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
 fprintf('POSTREV_RESULT pass=%d files=%d (%d) listing=%d git=%d commit=%s\n',R.pass,R.campaignFilesUnchanged,R.campaignFiles,R.outputsListingUnchanged,R.gitClean,C.preflight.sourceCommit);
catch ME
 fprintf(2,'POSTREV_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
function L=listing(folder)
d=dir(fullfile(folder,'**','*'));L=sort(strcat({d.folder},filesep,{d.name}))';
end
function H=hashes(varargin)
H=cell(0,2);for r=1:numel(varargin),d=dir(fullfile(varargin{r},'**','*'));d=d(~[d.isdir]);
 for k=1:numel(d),f=fullfile(d(k).folder,d(k).name);H(end+1,:)={f,lower(g2_sha256_file(f))};end,end %#ok<AGROW>
H=sortrows(H,1);
end
