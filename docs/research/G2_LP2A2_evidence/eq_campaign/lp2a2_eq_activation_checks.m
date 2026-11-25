% LP2-A2 equivalence campaign G2-LP2A2-EQ-001: MATLAB activation checks in the clean execution clone, GO ABSENT.
% No mesh, no FEM, no writes under the execution clone. Results are written to the scratch folder only.
ex='<repo>';
out='<scratch>\pre';
addpath(fullfile(ex,'matlab','g2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a2'),'-begin');
TOK=['G2LP2A2EQ|policy=bc1f86e7750aaea653cd7544c8fff0ad757843a23bd00608145dad70dcd8a330|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947', ...
 '|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca|lp2a2source=00c99e93915ad2c0dbd4eaeb307d94d65b4c71300f94a0f073aadacb9c5a61c2', ...
 '|archivedS8=da951c99c0d8c1d5dd731986d8f3b30e3db3f71854166a634d35b739757def8d|solves=EQ-H,EQ-stiff13,EQ-soft2,EQ-soft1|limit=4'];
try
 R=struct();
 [~,h]=system(sprintf('git -C "%s" rev-parse HEAD',ex));R.head=strtrim(h);
 fprintf('ACT head=%s\n',R.head);
 assert(strcmp(R.head,'4d3701e1ccc91b7512db9052c927f32af52e2479'),'ACT:Head','Execution clone is not at the approved head.');
 [~,s]=memory;R.ramInsideMATLAB_GiB=s.PhysicalMemory.Available/2^30;R.release=version('-release');R.versionFull=version;R.pde=~isempty(ver('pde'));
 R.pdeVersion='';v=ver('pde');if ~isempty(v),R.pdeVersion=v(1).Version;end
 R.createpdeExists=exist('createpde','file')~=0;
 R.goFileAbsent=~isfile(fullfile(ex,'matlab','g2','lp2a2','G2_LP2A2_EQ_GO.json'));
 outRoot=fullfile(ex,'outputs','g2_lp2a2_eq_v1');R.outputRootAbsentBefore=~isfolder(outRoot);
 [~,g0]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));R.gitCleanBefore=isempty(strtrim(g0));
 assert(R.goFileAbsent&&R.outputRootAbsentBefore&&R.gitCleanBefore,'ACT:State','GO file, output root or dirty tree.');
 C=g2_lp2a2_eq_context();   % normal preflight (inherited 5 GiB guard unchanged)
 pf=C.preflight;if isfield(pf,'matlabProcessInfo'),pf=rmfield(pf,'matlabProcessInfo');end
 R.preflight=pf;R.tokenEqualsApproved=strcmp(C.token,TOK);R.tokenFromContext=C.token;
 % coordinator activation rule: AFTER loading the context the memory gate (7 GiB, unchanged) passes AND Available >= 7.3 GiB AND exactly one MATLAB engine
 M=g2_lp2a2_eq_memgate(7);R.memgate=M;[~,s2]=memory;R.ramAfterContext_GiB=s2.PhysicalMemory.Available/2^30;
 R.margin73=R.ramAfterContext_GiB>=7.3;R.exactlyOneEngine=C.preflight.matlabProcesses==1;
 fprintf('ACT ram0=%.3f ramAfterContext=%.3f memgate=%d(%.3f) margin7.3=%d release=%s pde=%d engines=%d token=%d\n',R.ramInsideMATLAB_GiB,R.ramAfterContext_GiB,M.pass,M.freeGiB,R.margin73,R.release,R.pde,C.preflight.matlabProcesses,R.tokenEqualsApproved);
 assert(M.pass,'ACT:Memgate','Memory gate failed: %s',M.reason);
 assert(R.margin73,'ACT:Margin','Available %.3f GiB after context is below the 7.3 GiB activation margin.',R.ramAfterContext_GiB);
 assert(R.exactlyOneEngine,'ACT:Engines','Not exactly one MATLAB engine.');
 assert(R.tokenEqualsApproved,'ACT:Token','Token differs.');
 L0=listing(fullfile(ex,'outputs'));
 % ---- correct-token Run=true probe on EQ-H: must be refused before any folder/mesh/solve
 id1='<no error>';msg1='';
 try,g2_lp2a2_eq_run('EQ-H','Run',true,'Token',TOK);catch ME,id1=ME.identifier;msg1=ME.message;end
 fprintf('ACT_PROBE_RUN %s | %s\n',id1,msg1);
 % ---- external wrapper with the GO absent: HOLD_UNAUTHORIZED, zero solves
 W=g2_lp2a2_eq_campaign(TOK);
 fprintf('ACT_PROBE_WRAPPER outcome=%s solvesCalled=%d reason=%s\n',W.outcome,W.solvesCalled,W.reason);
 L1=listing(fullfile(ex,'outputs'));[~,g1]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 R.probeRun=struct('identifier',id1,'message',msg1,'expectedIdentifier','G2LP2A2:HOLD_UNAUTHORIZED');
 R.probeRun.pass=strcmp(id1,'G2LP2A2:HOLD_UNAUTHORIZED');
 R.probeWrapper=struct('outcome',W.outcome,'solvesCalled',W.solvesCalled,'reason',W.reason,'resultsEmpty',isempty(W.results));
 R.probeWrapper.pass=strcmp(W.outcome,'HOLD_UNAUTHORIZED')&&W.solvesCalled==0&&isempty(W.results);
 R.outputsListingUnchanged=isequal(L0,L1);R.outputRootAbsentAfter=~isfolder(outRoot);R.gitCleanAfter=isempty(strtrim(g1));
 R.physicalSolves=0;
 R.allMatlabChecksPass=R.tokenEqualsApproved&&M.pass&&R.margin73&&R.exactlyOneEngine&&R.ramInsideMATLAB_GiB>=7&&strcmp(R.release,'2023a')&&R.pde&&R.createpdeExists&&C.preflight.matlabProcesses==1&& ...
  R.probeRun.pass&&R.probeWrapper.pass&&R.outputsListingUnchanged&&R.outputRootAbsentAfter&&R.gitCleanAfter&&R.goFileAbsent;
 fid=fopen(fullfile(out,'LP2A2_EQ_ACTIVATION_CHECKS.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
 fprintf('ACT_RESULT matlabChecks=%d ram=%.3f outputsUnchanged=%d rootAbsent=%d gitClean=%d physicalSolves=0\n',R.allMatlabChecksPass,R.ramInsideMATLAB_GiB,R.outputsListingUnchanged,R.outputRootAbsentAfter,R.gitCleanAfter);
catch ME
 fprintf(2,'ACT_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
function L=listing(folder)
d=dir(fullfile(folder,'**','*'));L=sort(strcat({d.folder},filesep,{d.name}))';
end
