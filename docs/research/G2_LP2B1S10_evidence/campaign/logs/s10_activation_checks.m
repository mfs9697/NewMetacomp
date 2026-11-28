% LP2-B1-S10 campaign G2-LP2B1-S10-001 (authorization PR #82 issuecomment-7237508619): MATLAB checks in the clean
% execution clone at the approved head with the GO ABSENT. Real preflight; correct-token refusal through the driver;
% the external wrapper is NOT called (it is invoked exactly once, after activation); no mesh, no FEM, no write under the clone.
ex='<repo>';
out='<scratch>\lp2b1s10run\pre';
restoredefaultpath;g2d=fullfile(ex,'matlab','g2');for f={'','lp2','lp2a2','lp2a3','lp2b1','lp2b1eq'},addpath(fullfile(g2d,f{1}));end
addpath(fullfile(ex,'scripts','g2','lp2a2','closure'));addpath(fullfile(g2d,'lp2b1s10'));
TOK=['G2LP2B1S10|policy=f57433eccc5641ba253da52b723a0de6b1ad299793aa227235d309e57f120171|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947', ...
 '|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca|lp2a2source=f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd', ...
 '|lp2a3source=fa3bcecfa9cd3044253d5a72253e2058bccd044d32345f51650dcd775f42e002|lp2b1source=9c7a1260e3bde5b59e1d93c47bc99cc4d7b89f9b0cc6e874572fb378f1717bee', ...
 '|lp2b1eqsource=74a0edd827daca5714a1347705abc1429a7a573116ad3c438f9e5a1c12dfbf1f|closure=76614f269810c6970544bca0c1c0f84ebf9131935554ebd75e57e24f819f65f7', ...
 '|lp2b1s10source=d544fcfde1cfaa1e7118e0c5959551bdddb1cd477739bcf55376c45fe8388ab9|parent=9f3c173fadd370ae3e455b3aef3d5aa4d1f3035faf6100d717d4175ae33f194b', ...
 '|qualification=773f42aef75b13542efc6a169c9f526f6e64597a8d359df0ab067abf6cf161df|eqcampaign=91ff13fa86617f8236b09c439f7048f4542520e79c31003c01f07957e5cf17b9', ...
 '|case=soft1|state=S10|admissions=1|seed=0.40|campaign=G2-LP2B1-S10-001|run=run_lp2b1_s10_v1'];
try
 R=struct();R.attempt=1;
 dep={'g2_lp2a2_git','g2_lp2a2_eq_memgate','g2_lp2b1s10_external_run','g2_lp2b1s10_run','g2_lp2b1s10_verify','g2_lp2b1s10_go_validate','g2_lp2b1eq_geometry','g2_m4b_sif_partial','g2_lp1_admit_state','g2_lp1_campaign_ledger'};
 R.dependencies=cellfun(@(f)strrep(which(f),ex,'<repo>'),dep,'UniformOutput',false);R.dependenciesResolved=all(~cellfun(@isempty,R.dependencies));
 H=g2_lp2a2_git('head',ex);R.head=H.value;assert(H.ok&&strcmp(R.head,'0fcee176a5e294b7c8d7f33711ad7d3897be6538'),'S10ACT:Head','Not at the approved head.');
 [~,s]=memory;R.ramInsideMATLAB_GiB=s.PhysicalMemory.Available/2^30;R.release=version('-release');v=ver('pde');R.pde=~isempty(v);R.pdeVersion='';if R.pde,R.pdeVersion=v(1).Version;end
 C=g2_lp2b1s10_context();   % real preflight (5 GiB guard unchanged)
 pf=C.preflight;if isfield(pf,'matlabProcessInfo'),pf=rmfield(pf,'matlabProcessInfo');end;R.preflight=pf;
 R.tokenEqualsAuthorization=strcmp(C.token,TOK);R.goAbsent=~isfile(C.goFile);R.policySHA256=C.policySHA256;
 R.rootsAbsent=~isfolder(C.runRoot)&&~isfolder(C.receiptRoot)&&~isfile(C.summaryFile)&&~isfolder(fileparts(C.runRoot))&&~isfolder(fileparts(C.receiptRoot));
 R.memgate=g2_lp2a2_eq_memgate(C.policy.resources.freeRAMInsideMATLAB_GiB_min);R.engines=C.preflight.matlabProcesses;
 L0=listing(fullfile(ex,'outputs'));[~,g0]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 id='<no error>';msg='';try,g2_lp2b1s10_run('Run',true,'Token',TOK);catch ME,id=ME.identifier;msg=ME.message;end
 R.probe=struct('identifier',id,'message',msg,'pass',strcmp(id,'G2LP2B1S10:HOLD_UNAUTHORIZED'));fprintf('PREACT_PROBE soft1-S10 %s\n',id);
 L1=listing(fullfile(ex,'outputs'));[~,g1]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 R.outputsUnchanged=isequal(L0,L1);R.outputsEntries=numel(L0);R.gitClean=isempty(strtrim(g0))&&isempty(strtrim(g1));
 R.rootsStillAbsent=~isfolder(C.runRoot)&&~isfolder(C.receiptRoot)&&~isfile(C.summaryFile)&&~isfile(C.goFile);
 R.physicalSolves=0;R.externalEntryInvoked=false;
 R.allPass=R.dependenciesResolved&&R.tokenEqualsAuthorization&&R.goAbsent&&R.rootsAbsent&&R.memgate.pass&&R.engines==1&&strcmp(R.release,'2023a')&&strcmp(R.pdeVersion,'3.10')&&R.probe.pass&&R.outputsUnchanged&&R.gitClean&&R.rootsStillAbsent;
 fid=fopen(fullfile(out,'LP2B1S10_ACTIVATION_CHECKS.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
 fprintf('S10ACT ram=%.3f memgate=%d(%.3f) engines=%d release=%s pde=%s token=%d go=%d roots=%d unchanged=%d clean=%d ALL=%d\n',R.ramInsideMATLAB_GiB,R.memgate.pass,R.memgate.freeGiB,R.engines,R.release,R.pdeVersion,R.tokenEqualsAuthorization,R.goAbsent,R.rootsAbsent,R.outputsUnchanged,R.gitClean,R.allPass);
catch ME
 fprintf(2,'S10ACT_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
function L=listing(folder),d=dir(fullfile(folder,'**','*'));L=sort(strcat({d.folder},filesep,{d.name}))';end
