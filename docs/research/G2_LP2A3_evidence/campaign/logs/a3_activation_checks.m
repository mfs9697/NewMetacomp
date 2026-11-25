% LP2-A3 campaign G2-LP2A3-001: MATLAB checks in the clean execution clone with the GO ABSENT.
% Real preflight; correct-token refusal through the driver; no mesh, no FEM, no write under the clone.
ex='<repo>';
out='<scratch>';
addpath(fullfile(ex,'matlab','g2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a3'),'-begin');
TOK=['G2LP2A3|policy=7a6e17f8baa85c6e6f10186bfab3a9c10c9363e0acb5e532c00095961bf45d43|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947', ...
 '|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca|lp2a2source=f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd', ...
 '|lp2a3source=fa3bcecfa9cd3044253d5a72253e2058bccd044d32345f51650dcd775f42e002|parentsS8=da951c99c0d8c1d5dd731986d8f3b30e3db3f71854166a634d35b739757def8d', ...
 '|qualification=a77f49200f9f95b36260f44306afd4b05690d8ec9353c4fa71f4b5adbe5d4ded|cases=H,stiff13,soft2,soft1|states=S9-S11|maxAdmissions=12|seed=0.45|campaign=G2-LP2A3-001|run=run_lp2a3_s9_s11_v1'];
try
 R=struct();H=g2_lp2a2_git('head',ex);R.head=H.value;assert(H.ok&&strcmp(R.head,'2348ba11b9ebe1e33a723b11055a3603b846383e'),'A3ACT:Head','Not at the approved head.');
 [~,s]=memory;R.ramInsideMATLAB_GiB=s.PhysicalMemory.Available/2^30;R.release=version('-release');v=ver('pde');R.pde=~isempty(v);R.pdeVersion='';if R.pde,R.pdeVersion=v(1).Version;end
 C=g2_lp2a3_context();   % real preflight (5 GiB guard unchanged)
 pf=C.preflight;if isfield(pf,'matlabProcessInfo'),pf=rmfield(pf,'matlabProcessInfo');end;R.preflight=pf;
 R.tokenEqualsAuthorization=strcmp(C.token,TOK);R.goAbsent=~isfile(C.goFile);R.rootsAbsent=~isfolder(C.runRoot)&&~isfolder(C.ledgerRoot)&&~isfile(fullfile(ex,'outputs','LP2A3_CAMPAIGN.json'));
 R.memgate=g2_lp2a2_eq_memgate(C.policy.resources.freeRAMInsideMATLAB_GiB_min);R.engines=C.preflight.matlabProcesses;
 L0=listing(fullfile(ex,'outputs'));[~,g0]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 id='<no error>';msg='';try,g2_lp2a3_run('Case','H','Run',true,'AuthToken',TOK);catch ME,id=ME.identifier;msg=ME.message;end
 L1=listing(fullfile(ex,'outputs'));[~,g1]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 R.probe=struct('identifier',id,'message',msg,'pass',strcmp(id,'G2LP2A3:HOLD_UNAUTHORIZED'));
 R.outputsUnchanged=isequal(L0,L1);R.gitClean=isempty(strtrim(g0))&&isempty(strtrim(g1));R.physicalSolves=0;R.externalEntryInvoked=false;
 R.allPass=R.tokenEqualsAuthorization&&R.goAbsent&&R.rootsAbsent&&R.memgate.pass&&R.engines==1&&strcmp(R.release,'2023a')&&R.pde&&R.probe.pass&&R.outputsUnchanged&&R.gitClean;
 fid=fopen(fullfile(out,'LP2A3_ACTIVATION_CHECKS.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
 fprintf('A3ACT ram=%.3f memgate=%d(%.3f) engines=%d release=%s pde=%s token=%d probe=%s unchanged=%d clean=%d ALL=%d\n',R.ramInsideMATLAB_GiB,R.memgate.pass,R.memgate.freeGiB,R.engines,R.release,R.pdeVersion,R.tokenEqualsAuthorization,id,R.outputsUnchanged,R.gitClean,R.allPass);
catch ME
 fprintf(2,'A3ACT_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
function L=listing(folder),d=dir(fullfile(folder,'**','*'));L=sort(strcat({d.folder},filesep,{d.name}))';end
