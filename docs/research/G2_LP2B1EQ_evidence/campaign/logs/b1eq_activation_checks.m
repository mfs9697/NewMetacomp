% LP2-B1-EQ campaign G2-LP2B1-EQ-001 (authorization PR #79 issuecomment-7211904299): MATLAB checks in the clean
% execution clone at the approved head with the GO ABSENT. Real preflight; correct-token refusal through the driver for
% BOTH solves; the external wrapper is NOT called (it is invoked exactly once, after activation); no mesh, no FEM,
% no write under the clone.
ex='<repo>';
out='<scratch>\lp2b1eqrun\pre';
% path set identical to g2_lp2b1eq_context lines 13-14 (attempt 1 omitted lp2a2 -> g2_lp2a2_git undefined, no probe ran)
restoredefaultpath;g2d=fullfile(ex,'matlab','g2');for f={'','lp2','lp2a2','lp2a3','lp2b1'},addpath(fullfile(g2d,f{1}));end
addpath(fullfile(ex,'scripts','g2','lp2a2','closure'));addpath(fullfile(g2d,'lp2b1eq'));
TOK=['G2LP2B1EQ|policy=b113a7c6d7b2e8fe9950d817ccca3c851c05f1e347c73f66c604b9c41e54eecb|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947', ...
 '|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca|lp2a2source=f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd', ...
 '|lp2a3source=fa3bcecfa9cd3044253d5a72253e2058bccd044d32345f51650dcd775f42e002|lp2b1source=9c7a1260e3bde5b59e1d93c47bc99cc4d7b89f9b0cc6e874572fb378f1717bee', ...
 '|lp2b1eqsource=74a0edd827daca5714a1347705abc1429a7a573116ad3c438f9e5a1c12dfbf1f|closure=76614f269810c6970544bca0c1c0f84ebf9131935554ebd75e57e24f819f65f7', ...
 '|references=63014a95ebeebd127ae094e9254331d6e32e314902b6c1d6ac2bf8abbeb3d89d|qualification=441b1eadf330a720255f2c6b178c0c51a822e4ad99a24d0318230c0884c5d5ad', ...
 '|solves=EQB-soft1-S9,EQB-H-S10|limit=2|seed=0.40|campaign=G2-LP2B1-EQ-001|run=run_lp2b1_eq_v1'];
try
 R=struct();R.attempt=2;R.previousAttempt='attempt 1: script path defect (lp2a2 not on path), stopped at line 1, no context/probe/write';
 dep={'g2_lp2a2_git','g2_lp2a2_eq_memgate','g2_lp2b1eq_external_run','g2_lp2b1eq_campaign','g2_lp2b1eq_run','g2_lp2b1eq_verify','g2_m4b_sif_partial','g2_lp2_forecast','g2_lp2b1_attempt','g2_trajectory_record'};
 R.dependencies=cellfun(@(f)strrep(which(f),ex,'<repo>'),dep,'UniformOutput',false);R.dependenciesResolved=all(~cellfun(@isempty,R.dependencies));
 H=g2_lp2a2_git('head',ex);R.head=H.value;assert(H.ok&&strcmp(R.head,'7d0df53f35b30c4e33734c40fdda33e987ea96ee'),'B1EQACT:Head','Not at the approved head.');
 [~,s]=memory;R.ramInsideMATLAB_GiB=s.PhysicalMemory.Available/2^30;R.release=version('-release');v=ver('pde');R.pde=~isempty(v);R.pdeVersion='';if R.pde,R.pdeVersion=v(1).Version;end
 C=g2_lp2b1eq_context();   % real preflight (5 GiB guard unchanged)
 pf=C.preflight;if isfield(pf,'matlabProcessInfo'),pf=rmfield(pf,'matlabProcessInfo');end;R.preflight=pf;
 R.tokenEqualsAuthorization=strcmp(C.token,TOK);R.goAbsent=~isfile(C.goFile);
 R.summaryPath='outputs/LP2B1EQ_CAMPAIGN.json';
 R.rootsAbsent=~isfolder(C.runRoot)&&~isfolder(C.receiptRoot)&&~isfile(fullfile(ex,'outputs','LP2B1EQ_CAMPAIGN.json'))&&~isfolder(fileparts(C.runRoot))&&~isfolder(fileparts(C.receiptRoot));
 R.memgate=g2_lp2a2_eq_memgate(C.policy.resources.freeRAMInsideMATLAB_GiB_min);R.engines=C.preflight.matlabProcesses;
 L0=listing(fullfile(ex,'outputs'));[~,g0]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 ids={'EQB-soft1-S9','EQB-H-S10'};P=struct('solveId',{},'identifier',{},'message',{},'pass',{});
 for k=1:2
  id='<no error>';msg='';try,g2_lp2b1eq_run(ids{k},'Run',true,'Token',TOK);catch ME,id=ME.identifier;msg=ME.message;end
  P(end+1)=struct('solveId',ids{k},'identifier',id,'message',msg,'pass',strcmp(id,'G2LP2B1EQ:HOLD_UNAUTHORIZED')); %#ok<SAGROW>
  fprintf('PREACT_PROBE %s %s\n',ids{k},id);
 end
 L1=listing(fullfile(ex,'outputs'));[~,g1]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 R.probes=P;R.outputsUnchanged=isequal(L0,L1);R.outputsEntries=numel(L0);R.gitClean=isempty(strtrim(g0))&&isempty(strtrim(g1));
 R.rootsStillAbsent=~isfolder(C.runRoot)&&~isfolder(C.receiptRoot)&&~isfile(fullfile(ex,'outputs','LP2B1EQ_CAMPAIGN.json'));
 R.physicalSolves=0;R.externalEntryInvoked=false;
 R.allPass=R.dependenciesResolved&&R.tokenEqualsAuthorization&&R.goAbsent&&R.rootsAbsent&&R.memgate.pass&&R.engines==1&&strcmp(R.release,'2023a')&&R.pde&&all([P.pass])&&R.outputsUnchanged&&R.gitClean&&R.rootsStillAbsent;
 fid=fopen(fullfile(out,'LP2B1EQ_ACTIVATION_CHECKS.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
 fprintf('B1EQACT ram=%.3f memgate=%d(%.3f) engines=%d release=%s pde=%s token=%d unchanged=%d clean=%d ALL=%d\n',R.ramInsideMATLAB_GiB,R.memgate.pass,R.memgate.freeGiB,R.engines,R.release,R.pdeVersion,R.tokenEqualsAuthorization,R.outputsUnchanged,R.gitClean,R.allPass);
catch ME
 fprintf(2,'B1EQACT_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
function L=listing(folder),d=dir(fullfile(folder,'**','*'));L=sort(strcat({d.folder},filesep,{d.name}))';end
