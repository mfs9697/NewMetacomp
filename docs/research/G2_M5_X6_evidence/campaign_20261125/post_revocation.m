% M5-X6 post-revocation probe: correct-token Run=true calls must be refused with no write. No FEM.
ex='<repo>';
out='<scratch>\m5x6run\post_revocation';
addpath(fullfile(ex,'scripts','g2','m5','x6'));
try
 assert(~isfolder(out));mkdir(out);
 C=g2_m5x6_context();assert(~isfile(fullfile(C.x6,'G2_M5_X6_SCIENTIFIC_GO_v1.json')),'PR:GO','GO still present.');
 L0=listing(fullfile(ex,'outputs'));H0=hashes(fullfile(ex,'outputs','g2_m5x6_crossed_v1'),fullfile(ex,'outputs','g2_m5x6_campaign_ledger'));
 [~,g0]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 P=struct('config',{},'identifier',{},'message',{});
 for id={'X6-01','X6-06'}
  i='<no error>';m='';
  try,g2_m5x6_run('Config',id{1},'Run',true,'AuthToken',C.token,'RunName','run_m5x6_crossed_s4_b9_v1');catch ME,i=ME.identifier;m=ME.message;end
  P(end+1)=struct('config',id{1},'identifier',i,'message',m); %#ok<SAGROW>
  fprintf('POSTREV %s %s | %s\n',id{1},i,m);
 end
 L1=listing(fullfile(ex,'outputs'));H1=hashes(fullfile(ex,'outputs','g2_m5x6_crossed_v1'),fullfile(ex,'outputs','g2_m5x6_campaign_ledger'));
 [~,g1]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 R=struct('schema','NewMetacomp.G2.M5X6.PostRevocation.v1','sourceCommit',C.preflight.sourceCommit,'token',C.token,'probes',P, ...
  'outputsListingUnchanged',isequal(L0,L1),'campaignFilesUnchanged',isequal(H0,H1),'campaignFiles',size(H0,1),'gitClean',isempty(strtrim(g0))&&isempty(strtrim(g1)),'physicalSolves',0);
 R.pass=all(strcmp({P.identifier},'G2M5X6:HOLD_UNAUTHORIZED_STATE'))&&R.outputsListingUnchanged&&R.campaignFilesUnchanged&&R.gitClean;
 fid=fopen(fullfile(out,'M5X6_POST_REVOCATION.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
 fprintf('POSTREV_RESULT pass=%d listing=%d files=%d (%d) git=%d commit=%s\n',R.pass,R.outputsListingUnchanged,R.campaignFilesUnchanged,R.campaignFiles,R.gitClean,C.preflight.sourceCommit);
catch ME
 fprintf(2,'POSTREV_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
function L=listing(folder)
d=dir(fullfile(folder,'**','*'));L=sort(strcat({d.folder},filesep,{d.name}))';
end
function H=hashes(varargin)
H=cell(0,2);
for r=1:numel(varargin)
 d=dir(fullfile(varargin{r},'**','*'));d=d(~[d.isdir]);
 for k=1:numel(d),f=fullfile(d(k).folder,d(k).name);H(end+1,:)={f,lower(g2_sha256_file(f))};end %#ok<AGROW>
end
H=sortrows(H,1);
end
