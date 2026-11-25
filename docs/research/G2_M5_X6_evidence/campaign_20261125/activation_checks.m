% M5-X6 Step 1 activation checks in the clean execution clone, GO ABSENT. No FEM.
ex='<repo>';
out='<scratch>\m5x6run\activation';
addpath(fullfile(ex,'scripts','g2','m5','x6'));
TOK=['G2M5X6|plan=e6153735e76b09382a24376002110f7f07485d27db12aaca09108419e43fea52|a1policy=312e1e005b9ca85d743b672115609d7b02bb2f6ebbbae09658c0cdf1d9a8a013', ...
 '|a1source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947|x6source=f21d7d44a2de33922dd766c226320cec0695252f24d5516908f500c3a8d8e6bb', ...
 '|meshes=9c3d0f4560da34216c674cf8af5a9f6782d28ab80ec86076f284e55278904ad8|configs=X6-01,X6-02,X6-03,X6-04,X6-05,X6-06|maxSolves=6'];
try
 assert(~isfolder(out));mkdir(out);R=struct();
 C=g2_m5x6_context();R.preflight=rmfield(C.preflight,'matlabProcessInfo');
 R.tokenEqualsApproved=strcmp(C.token,TOK);fprintf('ACT token=%d RAM=%.3f commit=%s\n',R.tokenEqualsApproved,C.preflight.freePhysicalRAM_GiB,C.preflight.sourceCommit);
 assert(R.tokenEqualsApproved,'ACT:Token','Token differs from the approved token.');
 assert(~isfile(fullfile(C.x6,'G2_M5_X6_SCIENTIFIC_GO_v1.json')),'ACT:GO','GO must be absent.');
 A=m5x6_audit_diagonal(C,fullfile(out,'ACT_DIAGONAL_AUDIT.json'));R.diagonalAllPass=A.allPass;
 dry=cell(1,6);
 for k=1:6
  d=g2_m5x6_run('Config',C.configurations(k).id);
  dry{k}=struct('id',d.config,'status',d.status,'computed',d.computed,'tokenOK',strcmp(d.token,TOK),'pass',d.check.pass, ...
   'mask',d.check.mask,'ratio',d.check.ratio,'activeElements',d.check.activeElements,'meshContentSHA256',d.check.meshContentSHA256);
  fprintf('ACT_DRY %s %s pass=%d active=%d\n',d.config,d.status,d.check.pass,d.check.activeElements);
 end
 R.dry=[dry{:}];
 % count method of the earlier qualification snapshot (MATLAB dir with **)
 dd=dir(fullfile(ex,'outputs','g2_a1_fixed_path_v1','**','*'));dd=dd(~[dd.isdir]);
 ff=strcat({dd.folder},filesep,{dd.name});R.qualCountMethod=struct('entries',numel(ff),'unique',numel(unique(ff)));
 fprintf('ACT_DIR_COUNT entries=%d unique=%d (g2_a1_fixed_path_v1)\n',numel(ff),numel(unique(ff)));
 % refusal probe: real Run=true path with the CORRECT token, GO absent
 L0=listing(fullfile(ex,'outputs'));[~,g0]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 id='<no error>';msg='';t0=tic;
 try
  g2_m5x6_run('Config','X6-01','Run',true,'AuthToken',C.token,'RunName','run_m5x6_crossed_s4_b9_v1');
 catch ME
  id=ME.identifier;msg=ME.message;
 end
 L1=listing(fullfile(ex,'outputs'));[~,g1]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 R.probe=struct('identifier',id,'message',msg,'seconds',toc(t0),'outputsListingUnchanged',isequal(L0,L1),'outputsEntries',numel(L0), ...
  'gitStatusBefore',g0,'gitStatusAfter',g1,'runFolderExists',isfolder(fullfile(ex,'outputs','g2_m5x6_crossed_v1')), ...
  'ledgerExists',isfolder(fullfile(ex,'outputs','g2_m5x6_campaign_ledger')));
 R.probe.pass=strcmp(id,'G2M5X6:HOLD_UNAUTHORIZED_STATE')&&contains(msg,'no GO_M5_X6 record')&&R.probe.outputsListingUnchanged&& ...
  isempty(strtrim(g0))&&isempty(strtrim(g1))&&~R.probe.runFolderExists&&~R.probe.ledgerExists;
 fprintf('ACT_PROBE %s | %s | listingUnchanged=%d run=%d ledger=%d pass=%d\n',id,msg,R.probe.outputsListingUnchanged,R.probe.runFolderExists,R.probe.ledgerExists,R.probe.pass);
 [~,s]=memory;R.freeRAM_end_GiB=s.PhysicalMemory.Available/2^30;
 R.allPass=R.tokenEqualsApproved&&R.diagonalAllPass&&all([R.dry.pass])&&all(strcmp({R.dry.status},'DRY_READY_NO_FEM'))&&all([R.dry.computed]==0)&&R.probe.pass;
 fid=fopen(fullfile(out,'ACTIVATION_CHECKS.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
 fprintf('ACT_RESULT allPass=%d physicalSolves=0 RAMend=%.3f\n',R.allPass,R.freeRAM_end_GiB);
catch ME
 fprintf(2,'ACT_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
function L=listing(folder)
d=dir(fullfile(folder,'**','*'));L=sort(strcat({d.folder},filesep,{d.name}))';
end
