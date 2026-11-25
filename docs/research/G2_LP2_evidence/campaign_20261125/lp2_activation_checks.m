% LP2-A1 activation checks in the clean execution clone, GO ABSENT. No FEM, no writes.
ex='<repo>';
out='<scratch>';
addpath(fullfile(ex,'matlab','g2','lp2'));
TOK=['G2LP2A|policy=093a546b9bae54d8fab0026420c8d85dced85f0e0e6ed212d597b3fd1aa6eec5|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947', ...
 '|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca|parents=0dcc572f42605fc39d005de2ebcbba243147128dee7621bb57a30f16ebdd76f6', ...
 '|cases=H,stiff13,soft2,soft1|states=S5-S8|maxSolves=16'];
try
 assert(~isfolder(out));mkdir(out);R=struct();
 [~,s]=memory;R.ramInsideMATLAB_GiB=s.PhysicalMemory.Available/2^30;R.release=version('-release');R.pde=~isempty(ver('pde'));
 C=g2_lp2_context();R.preflight=rmfield(C.preflight,'matlabProcessInfo');R.tokenEqualsApproved=strcmp(C.token,TOK);
 fprintf('ACT ram=%.3f release=%s pde=%d engines=%d token=%d commit=%s\n',R.ramInsideMATLAB_GiB,R.release,R.pde,C.preflight.matlabProcesses,R.tokenEqualsApproved,C.preflight.sourceCommit);
 assert(R.tokenEqualsApproved,'ACT:Token','Token differs.');assert(~isfile(fullfile(C.lp2,'G2_LP2A_SCIENTIFIC_GO_v1.json')),'ACT:GO','GO present.');
 dry=cell(1,4);ids={C.policy.cases.id};
 for k=1:4
  d=g2_lp2_run('Case',ids{k});dry{k}=struct('case',ids{k},'status',d.status,'computed',d.computed,'tokenOK',strcmp(d.token,TOK), ...
   'parentStateSHA256',d.parentStateSHA256,'S5tip',d.S5.tip_mm,'S5class',d.S5.classification);
  fprintf('ACT_DRY %s %s parent=%s S5=(%.6f,%.6f) %s\n',ids{k},d.status,d.parentStateSHA256(1:12),d.S5.tip_mm,d.S5.classification);
 end
 R.dry=[dry{:}];
 L0=listing(fullfile(ex,'outputs'));[~,g0]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));id='<no error>';msg='';
 try,g2_lp2_run('Case','H','Run',true,'AuthToken',C.token,'RunName','run_lp2a_s5_s8_v1');catch ME,id=ME.identifier;msg=ME.message;end
 L1=listing(fullfile(ex,'outputs'));[~,g1]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 R.probe=struct('identifier',id,'message',msg,'outputsUnchanged',isequal(L0,L1),'gitClean',isempty(strtrim(g0))&&isempty(strtrim(g1)), ...
  'runFolder',isfolder(fullfile(ex,'outputs','g2_lp2a_paths_v1')),'ledger',isfolder(fullfile(ex,'outputs','g2_lp2a_campaign_ledger')));
 R.probe.pass=strcmp(id,'G2LP2:HOLD_UNAUTHORIZED_STATE')&&contains(msg,'no GO_LP2A record')&&R.probe.outputsUnchanged&&R.probe.gitClean&&~R.probe.runFolder&&~R.probe.ledger;
 fprintf('ACT_PROBE %s | %s | unchanged=%d git=%d run=%d ledger=%d pass=%d\n',id,msg,R.probe.outputsUnchanged,R.probe.gitClean,R.probe.runFolder,R.probe.ledger,R.probe.pass);
 R.allMatlabChecksPass=R.tokenEqualsApproved&&R.ramInsideMATLAB_GiB>=7&&strcmp(R.release,'2023a')&&R.pde&&C.preflight.matlabProcesses==1&& ...
  all(strcmp({R.dry.status},'DRY_READY_NO_FEM'))&&all([R.dry.computed]==0)&&R.probe.pass;
 fid=fopen(fullfile(out,'LP2_ACTIVATION_CHECKS.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
 fprintf('ACT_RESULT matlabChecks=%d ram=%.3f physicalSolves=0\n',R.allMatlabChecksPass,R.ramInsideMATLAB_GiB);
catch ME
 fprintf(2,'ACT_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
function L=listing(folder)
d=dir(fullfile(folder,'**','*'));L=sort(strcat({d.folder},filesep,{d.name}))';
end
