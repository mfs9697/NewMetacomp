function W=g2_lp2b1s10_external_run(approvedHead,tok,outDir,varargin)
%G2_LP2B1S10_EXTERNAL_RUN  Single external entry point of the PROSPECTIVE campaign G2-LP2B1-S10-001.
%  W = g2_lp2b1s10_external_run(approvedHead, tok, outDir)       FUTURE use only, after an investigator GO
%     Only after ALL of: activation parent check (g2_lp2a2_git: HEAD and HEAD~1 exit 0 and exact 40-hex,
%     HEAD~1 == approvedHead, 'diff --name-only approvedHead HEAD' == the GO file only); run root, receipt root and
%     campaign summary absent; normal context (preflight, unchanged 5 GiB guard); one MATLAB engine; R2023a; caller
%     token == context token; 7 GiB memory gate; GO validation. Then the ledger RECEIPT (immutable, bound to token,
%     GO file SHA-256, heads) is written, g2_lp2b1s10_run('Run',true) is called ONCE (no retry), and
%     g2_lp2b1s10_verify replays all records read-only. Prospective copy of the accepted g2_lp2b1eq_external_run
%     without the two-solve campaign wrapper. The >= 8.2 GiB check BEFORE MATLAB starts is the unchanged pre-start
%     script scripts/g2/lp2a2/lp2a2_eq_prestart_check.ps1 (default threshold).
%  P = g2_lp2b1s10_external_run(approvedHead,'','','ParentCheckOnly',true,'Repo',repo)
%     only the parent / changed-file check (real-git tests on an inert fixture); nothing else.
% Records: outDir/LP2B1S10_PRECHECK.json, outDir/LP2B1S10_CAMPAIGN.json (+ <repo>/outputs/LP2B1S10_CAMPAIGN.json).
ip=inputParser;addParameter(ip,'ParentCheckOnly',false,@islogical);addParameter(ip,'Repo','',@ischar);parse(ip,varargin{:});o=ip.Results;
here=fileparts(mfilename('fullpath'));pol=jsondecode(fileread(fullfile(here,'G2_LP2B1S10_POLICY_v1.json')));au=pol.authorization;
repo=o.Repo;if isempty(repo),repo=fileparts(fileparts(fileparts(here)));end
if o.ParentCheckOnly,W=parentCheck(repo,approvedHead,au.goPath);return,end
if ~isfolder(outDir),mkdir(outDir);end
R=struct('approvedHead',approvedHead,'campaignId',pol.campaignId);calls=0;admissions=0;T0=tic;outcome='NOT_STARTED';reason='';Od=[];Rv=[];
try
 Pc=parentCheck(repo,approvedHead,au.goPath);R.parentCheck=Pc;
 fprintf('B1S10 head=%s parent=%s statuses=%s changed=[%s] pass=%d\n',Pc.head,Pc.parent,mat2str(Pc.statuses),strjoin(Pc.changedFiles,','),Pc.pass);
 assert(Pc.pass,'B1S10:Binding','Activation parent / changed-file check failed: no admission started.');
 for r={au.runRoot,au.receiptRoot},assert(~isfolder(fullfile(repo,strrep(r{1},'/',filesep))),'B1S10:Fresh','%s already exists.',r{1});end
 assert(~isfile(fullfile(repo,strrep(au.summaryPath,'/',filesep))),'B1S10:Fresh','%s already exists.',au.summaryPath);
 C=g2_lp2b1s10_context();assert(strcmp(strrep(C.repo,'\','/'),strrep(repo,'\','/')),'B1S10:Repo','Context repository differs.');
 R.engines=C.preflight.matlabProcesses;R.release=version('-release');v=ver('pde');R.pde='';if ~isempty(v),R.pde=v(1).Version;end
 R.tokenEqualsContext=strcmp(C.token,tok);R.memgate=g2_lp2a2_eq_memgate(pol.resources.freeRAMInsideMATLAB_GiB_min);
 wj(fullfile(outDir,'LP2B1S10_PRECHECK.json'),R);
 assert(R.tokenEqualsContext&&R.memgate.pass&&R.engines==1&&strcmp(R.release,'2023a')&&strcmp(R.pde,'3.10'),'B1S10:Pre','Pre-run checks failed: no admission started.');
 Vg=g2_lp2b1s10_go_validate(jsondecode(fileread(C.goFile)),C,tok);assert(Vg.pass,'B1S10:GO','GO record rejected: %s',strjoin(Vg.failed,', '));
 g2_lp1_campaign_ledger('write',C.receiptRoot,'RECEIPT','RECEIPT.mat',struct('campaignId',pol.campaignId,'runName',au.runName,'token',C.token, ...
  'approvedHead',approvedHead,'activationHead',Pc.head,'goFileSHA256',lower(g2_sha256_file(C.goFile)),'sourceCommit',C.preflight.sourceCommit, ...
  'openedUTC',char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss.SSS''Z'''))));
 outcome='RUNNING';calls=-1;
 Od=g2_lp2b1s10_run('Run',true,'Token',tok);calls=Od.solveCalls;admissions=Od.admissions;outcome=Od.stage;
catch ME
 fprintf(2,'B1S10_EXTERNAL_EXCEPTION %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
 if ~strcmp(outcome,'NOT_STARTED'),outcome='HOLD_EXTERNAL_EXCEPTION';end
 reason=[ME.identifier ': ' ME.message];
end
try
 if ~strcmp(outcome,'NOT_STARTED'),Rv=g2_lp2b1s10_verify(g2_lp2b1s10_context('Preflight',false));end
catch ME
 Rv=struct('outcome','VERIFY_ERROR','problems',{{[ME.identifier ': ' ME.message]}});
end
if calls<0   % the driver raised: count from the records actually present (never from intentions)
 cd0=fullfile(repo,strrep(au.runRoot,'/',filesep),'soft1','S10');calls=double(isfile(fullfile(cd0,'SOLUTION.mat')));admissions=double(isfolder(cd0));
end
W=struct('campaignId',pol.campaignId,'outcome',outcome,'reason',reason,'admissions',admissions,'solveCalls',calls,'driver',Od,'verification',Rv,'wallSeconds',toc(T0),'precheck',R);
wj(fullfile(outDir,'LP2B1S10_CAMPAIGN.json'),W);
if isfolder(fullfile(repo,'outputs')),wj(fullfile(repo,strrep(au.summaryPath,'/',filesep)),W);end
fprintf('B1S10_RESULT outcome=%s admissions=%d solveCalls=%d reason=%s wall=%.1fs\n',outcome,admissions,calls,reason,W.wallSeconds);
end

function P=parentCheck(repo,approvedHead,goFile)
A=g2_lp2a2_git('activationParent',repo,approvedHead);F=g2_lp2a2_git('changedFiles',repo,approvedHead);
P=struct('approvedHead',approvedHead,'head',A.head.value,'parent',A.parent.value, ...
 'commands',{{A.head.command,A.parent.command,F.command}},'statuses',[A.head.status A.parent.status F.status], ...
 'outputs',{{A.head.output,A.parent.output,F.output}},'changedFiles',{F.value},'parentOk',A.value, ...
 'filesOk',F.ok&&isequal(sort(reshape(F.value,1,[])),{goFile}));
P.pass=P.parentOk&&P.filesOk;
end
function wj(f,S)
fid=fopen(f,'w');assert(fid>0,'B1S10:Write','Cannot write %s',f);fwrite(fid,jsonencode(S,'PrettyPrint',true),'char');fclose(fid);
end
