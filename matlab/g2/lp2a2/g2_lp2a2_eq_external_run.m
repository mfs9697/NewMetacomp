function W=g2_lp2a2_eq_external_run(approvedHead,tok,outDir,varargin)
%G2_LP2A2_EQ_EXTERNAL_RUN  Prospective external execution of the LP2-A2 equivalence campaign,
% activation attempt A2. Corrected successor of the historical attempt-1 script
% docs/research/G2_LP2A2_evidence/eq_campaign/lp2a2_eq_campaign_run.m (preserved unchanged), whose
% unquoted 'git rev-parse HEAD^' lost its caret in cmd.exe and stopped before the wrapper.
%  W = g2_lp2a2_eq_external_run(approvedHead, tok, outDir)
%     ONE call of the wrapper g2_lp2a2_eq_campaign(tok), and only after all of:
%      - activation parent check through g2_lp2a2_git: HEAD and HEAD~1 resolved with exit status 0
%        and exact 40-hex output, HEAD~1 == approvedHead, 'diff --name-only approvedHead HEAD' ==
%        the GO file only;
%      - output root absent; normal context (preflight, unchanged 5 GiB guard), the same repository;
%      - one MATLAB process, release 2023a, caller token == context token;
%      - pure GO validation g2_lp2a2_eq_go_validate (no FEM, no write);
%      - physical-memory gate g2_lp2a2_eq_memgate(policy minimum, 7 GiB inside MATLAB).
%     Any failed check or exception before the call: outcome NOT_CALLED, zero solves.
%     The >= 8.2 GiB available-memory requirement BEFORE MATLAB starts is checked by the launcher
%     scripts/g2/lp2a2/lp2a2_eq_prestart_check.ps1 (outside MATLAB) and recorded there.
%  P = g2_lp2a2_eq_external_run(approvedHead, '', '', 'ParentCheckOnly', true, 'Repo', repo)
%     only the pre-wrapper parent / changed-file check against repo (real-git integration tests on
%     an inert fixture): no context, no validator, no wrapper, no write.
% Records (normal mode): outDir/LP2A2_EQ_A2_DRYCHECK.json, outDir/LP2A2_EQ_A2_CAMPAIGN.json and
% <repo>/outputs/LP2A2_EQ_A2_CAMPAIGN.json (A2 = activation attempt 2).
ip=inputParser;addParameter(ip,'ParentCheckOnly',false,@islogical);addParameter(ip,'Repo','',@ischar);parse(ip,varargin{:});o=ip.Results;
here=fileparts(mfilename('fullpath'));
pol=jsondecode(fileread(fullfile(here,'G2_LP2A2_EQ_POLICY_v1.json')));
repo=o.Repo;if isempty(repo),repo=fileparts(fileparts(fileparts(here)));end
if o.ParentCheckOnly
 W=parentCheck(repo,approvedHead,pol.goFile);return
end
W=[];called=false;T0=tic;R=struct('activationLabel','A2','approvedHead',approvedHead);
if ~isfolder(outDir),mkdir(outDir);end
try
 Pc=parentCheck(repo,approvedHead,pol.goFile);R.parentCheck=Pc;
 fprintf('A2 head=%s parent=%s approved=%s statuses=%s changed=[%s] pass=%d\n',Pc.head,Pc.parent,approvedHead,mat2str(Pc.statuses),strjoin(Pc.changedFiles,','),Pc.pass);
 assert(Pc.pass,'A2:Binding','Activation parent / changed-file check failed: no wrapper call, no attempt consumed.');
 assert(~isfolder(fullfile(repo,pol.outputRoot)),'A2:Fresh','Output root already exists.');
 C=g2_lp2a2_eq_context();    % normal preflight, 5 GiB guard unchanged
 assert(strcmp(strrep(C.repo,'\','/'),strrep(repo,'\','/')),'A2:Repo','Context repository differs from the checked repository.');
 [~,s2]=memory;R.ramAfterContext_GiB=s2.PhysicalMemory.Available/2^30;R.engines=C.preflight.matlabProcesses;R.release=version('-release');
 R.tokenEqualsContext=strcmp(C.token,tok);
 R.memgate=g2_lp2a2_eq_memgate(pol.resources.freeRAMInsideMATLAB_GiB_min);
 G=jsondecode(fileread(fullfile(repo,pol.goFile)));V=g2_lp2a2_eq_go_validate(G,C,tok);R.goValidate=V;R.goFields=G;
 fprintf('A2 ram=%.3f memgate=%d engines=%d release=%s token=%d goValidate=%d failed=[%s]\n',R.ramAfterContext_GiB,R.memgate.pass,R.engines,R.release,R.tokenEqualsContext,V.pass,strjoin(V.failed,','));
 wj(fullfile(outDir,'LP2A2_EQ_A2_DRYCHECK.json'),R);
 assert(V.pass&&R.tokenEqualsContext&&R.memgate.pass&&R.engines==1&&strcmp(R.release,'2023a'),'A2:Pre','Pre-run checks failed: no wrapper call, no attempt consumed.');
 fprintf('A2_CALL g2_lp2a2_eq_campaign start %s\n',datestr(now,'HH:MM:SS'));
 called=true;
 W=g2_lp2a2_eq_campaign(tok);
catch ME
 fprintf(2,'A2_EXTERNAL_EXCEPTION called=%d %s: %s\n',called,ME.identifier,ME.message);disp(getReport(ME));
 if called,W=struct('campaignId',pol.campaignId,'outcome','HOLD_EXTERNAL_EXCEPTION','stoppedAt','','reason',[ME.identifier ': ' ME.message],'solvesCalled',NaN,'results',{{}},'contrast',[]);
 else,W=struct('campaignId',pol.campaignId,'outcome','NOT_CALLED','stoppedAt','','reason',[ME.identifier ': ' ME.message],'solvesCalled',0,'results',{{}},'contrast',[]);
  if ~isfile(fullfile(outDir,'LP2A2_EQ_A2_DRYCHECK.json')),wj(fullfile(outDir,'LP2A2_EQ_A2_DRYCHECK.json'),R);end
 end
end
W.activationLabel='A2';W.wallSeconds=toc(T0);W.wrapperCalled=called;
wj(fullfile(outDir,'LP2A2_EQ_A2_CAMPAIGN.json'),W);
if isfolder(fullfile(repo,'outputs')),wj(fullfile(repo,'outputs','LP2A2_EQ_A2_CAMPAIGN.json'),W);end
fprintf('A2_RESULT outcome=%s stoppedAt=%s reason=%s solvesCalled=%g wrapperCalled=%d wall=%.1fs\n',W.outcome,W.stoppedAt,W.reason,W.solvesCalled,called,W.wallSeconds);
for k=1:numel(W.results)
 O=W.results{k};
 if isstruct(O)&&isfield(O,'stage')
  cp='n/a';if isfield(O,'comparisonPass'),cp=num2str(O.comparisonPass);end
  fl='';if isfield(O,'failed')&&~isempty(O.failed),fl=strjoin(cellstr(O.failed),',');end
  ki=NaN;kii=NaN;if isfield(O,'newK'),ki=O.newK.KI;kii=O.newK.KII;end
  fprintf('A2_SOLVE %s stage=%s comparisonPass=%s failed=[%s] KI=%.12g KII=%.12g\n',O.solveId,O.stage,cp,fl,ki,kii);
 end
end
end

function P=parentCheck(repo,approvedHead,goFile)
% Shared pre-wrapper check: g2_lp2a2_git only (HEAD~1, exit status, exact 40-hex output).
A=g2_lp2a2_git('activationParent',repo,approvedHead);F=g2_lp2a2_git('changedFiles',repo,approvedHead);
P=struct('approvedHead',approvedHead,'head',A.head.value,'parent',A.parent.value, ...
 'commands',{{A.head.command,A.parent.command,F.command}},'statuses',[A.head.status A.parent.status F.status], ...
 'outputs',{{A.head.output,A.parent.output,F.output}},'changedFiles',{F.value},'parentOk',A.value, ...
 'filesOk',F.ok&&isequal(sort(F.value(:)).',{goFile}));
P.pass=P.parentOk&&P.filesOk;
end

function wj(f,S)
fid=fopen(f,'w');assert(fid>0,'A2:Write','Cannot write %s',f);fwrite(fid,jsonencode(S,'PrettyPrint',true),'char');fclose(fid);
end
