% LP2-A2 equivalence campaign G2-LP2A2-EQ-001, activation A2: MATLAB checks in the clean execution clone, GO ABSENT.
% No mesh, no FEM, no write under the execution clone; results go to the scratch folder only.
% Correct-token refusal demonstrated through the driver (g2_lp2a2_eq_run Run=true); the wrapper and the
% external entry point are NOT invoked here (the entry point is invoked once, after activation).
ex='<repo>';
out='<scratch>';
addpath(fullfile(ex,'matlab','g2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a2'),'-begin');
TOK=['G2LP2A2EQ|policy=6f2c290b37d4f8291f428ec8b9e0a886fe6b31fc901bee5781f2518e67c94756|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947', ...
 '|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca|lp2a2source=f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd', ...
 '|archivedS8=da951c99c0d8c1d5dd731986d8f3b30e3db3f71854166a634d35b739757def8d|solves=EQ-H,EQ-stiff13,EQ-soft2,EQ-soft1|limit=4'];
try
 R=struct('activationLabel','A2');
 H=g2_lp2a2_git('head',ex);R.head=H.value;R.headStatus=H.status;
 fprintf('A2ACT head=%s status=%d\n',R.head,H.status);
 assert(H.ok&&strcmp(R.head,'a4561f88dfeda31752ae6c268d2d4d74e16b60a7'),'A2ACT:Head','Execution clone is not at the approved head.');
 [~,s]=memory;R.ramInsideMATLAB_GiB=s.PhysicalMemory.Available/2^30;R.release=version('-release');R.versionFull=version;
 v=ver('pde');R.pde=~isempty(v);R.pdeVersion='';if R.pde,R.pdeVersion=v(1).Version;end
 R.createpdeExists=exist('createpde','file')~=0;
 R.goFileAbsent=~isfile(fullfile(ex,'matlab','g2','lp2a2','G2_LP2A2_EQ_GO.json'));
 outRoot=fullfile(ex,'outputs','g2_lp2a2_eq_v1');R.outputRootAbsentBefore=~isfolder(outRoot);
 [~,g0]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));R.gitCleanBefore=isempty(strtrim(g0));
 assert(R.goFileAbsent&&R.outputRootAbsentBefore&&R.gitCleanBefore,'A2ACT:State','GO file, output root or dirty tree.');
 C=g2_lp2a2_eq_context();   % normal preflight (5 GiB guard unchanged)
 pf=C.preflight;if isfield(pf,'matlabProcessInfo'),pf=rmfield(pf,'matlabProcessInfo');end
 R.preflight=pf;R.tokenEqualsAuthorization=strcmp(C.token,TOK);R.tokenFromContext=C.token;
 M=g2_lp2a2_eq_memgate(C.policy.resources.freeRAMInsideMATLAB_GiB_min);R.memgate=M;[~,s2]=memory;R.ramAfterContext_GiB=s2.PhysicalMemory.Available/2^30;
 R.exactlyOneEngine=C.preflight.matlabProcesses==1;
 fprintf('A2ACT ram0=%.3f ramAfterContext=%.3f memgate=%d(%.3f) release=%s pde=%d(%s) engines=%d token=%d\n',R.ramInsideMATLAB_GiB,R.ramAfterContext_GiB,M.pass,M.freeGiB,R.release,R.pde,R.pdeVersion,C.preflight.matlabProcesses,R.tokenEqualsAuthorization);
 L0=listing(fullfile(ex,'outputs'));
 id1='<no error>';msg1='';
 try,g2_lp2a2_eq_run('EQ-H','Run',true,'Token',TOK);catch ME,id1=ME.identifier;msg1=ME.message;end
 fprintf('A2ACT_PROBE_RUN %s | %s\n',id1,msg1);
 L1=listing(fullfile(ex,'outputs'));[~,g1]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 R.probeRun=struct('call','g2_lp2a2_eq_run(''EQ-H'',''Run'',true,''Token'',tok)','identifier',id1,'message',msg1,'expectedIdentifier','G2LP2A2:HOLD_UNAUTHORIZED','pass',strcmp(id1,'G2LP2A2:HOLD_UNAUTHORIZED'));
 R.outputsListingUnchanged=isequal(L0,L1);R.outputRootAbsentAfter=~isfolder(outRoot);R.gitCleanAfter=isempty(strtrim(g1));
 R.physicalSolves=0;R.wrapperInvoked=false;R.externalEntryInvoked=false;
 R.allMatlabChecksPass=R.tokenEqualsAuthorization&&M.pass&&R.exactlyOneEngine&&strcmp(R.release,'2023a')&&R.pde&&R.createpdeExists&& ...
  R.probeRun.pass&&R.outputsListingUnchanged&&R.outputRootAbsentAfter&&R.gitCleanAfter&&R.goFileAbsent;
 fid=fopen(fullfile(out,'LP2A2_EQ_A2_ACTIVATION_CHECKS.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
 fprintf('A2ACT_RESULT matlabChecks=%d outputsUnchanged=%d rootAbsent=%d gitClean=%d physicalSolves=0\n',R.allMatlabChecksPass,R.outputsListingUnchanged,R.outputRootAbsentAfter,R.gitCleanAfter);
catch ME
 fprintf(2,'A2ACT_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
function L=listing(folder)
d=dir(fullfile(folder,'**','*'));L=sort(strcat({d.folder},filesep,{d.name}))';
end
