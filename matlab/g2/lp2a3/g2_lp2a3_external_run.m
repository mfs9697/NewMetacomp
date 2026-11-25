function W=g2_lp2a3_external_run(approvedHead,tok,outDir,varargin)
%G2_LP2A3_EXTERNAL_RUN  Single external entry point of the LP2-A3 campaign G2-LP2A3-001 (prospective).
%  W = g2_lp2a3_external_run(approvedHead, tok, outDir)
%     Only after ALL of: activation parent check (g2_lp2a2_git: HEAD and HEAD~1 resolved with exit 0 and
%     exact 40-hex, HEAD~1 == approvedHead, 'diff --name-only approvedHead HEAD' == the GO file only);
%     run and ledger roots absent; normal context (preflight, unchanged 5 GiB guard); one MATLAB
%     process; R2023a; caller token == context token; 7-GiB memory gate. Then g2_lp2a3_run
%     ('Run',true) once per case in the fixed order H, stiff13, soft2, soft1. A GLOBAL_HOLD or an
%     exception of any case stops the campaign at once (no later case, no retry). Afterwards the
%     whole campaign is verified read-only (g2_lp2a3_verify, terminal required).
%     The >= 8.2 GiB requirement BEFORE MATLAB starts is checked by the pre-start script
%     scripts/g2/lp2a2/lp2a2_eq_prestart_check.ps1 (unchanged, default threshold) and recorded there.
%  P = g2_lp2a3_external_run(approvedHead,'','','ParentCheckOnly',true,'Repo',repo)
%     only the parent / changed-file check (real-git tests on an inert fixture); nothing else.
% Records: outDir/LP2A3_PRECHECK.json, outDir/LP2A3_CAMPAIGN.json (+ <repo>/outputs/LP2A3_CAMPAIGN.json).
ip=inputParser;addParameter(ip,'ParentCheckOnly',false,@islogical);addParameter(ip,'Repo','',@ischar);parse(ip,varargin{:});o=ip.Results;
here=fileparts(mfilename('fullpath'));pol=jsondecode(fileread(fullfile(here,'G2_LP2A3_POLICY_v1.json')));
repo=o.Repo;if isempty(repo),repo=fileparts(fileparts(fileparts(here)));end
if o.ParentCheckOnly,W=parentCheck(repo,approvedHead,pol.authorization.goPath);return,end
if ~isfolder(outDir),mkdir(outDir);end
R=struct('approvedHead',approvedHead,'campaignId',pol.authorization.campaignId);calls=0;res={};T0=tic;outcome='NOT_STARTED';reason='';
try
 Pc=parentCheck(repo,approvedHead,pol.authorization.goPath);R.parentCheck=Pc;
 fprintf('A3 head=%s parent=%s statuses=%s changed=[%s] pass=%d\n',Pc.head,Pc.parent,mat2str(Pc.statuses),strjoin(Pc.changedFiles,','),Pc.pass);
 assert(Pc.pass,'A3:Binding','Activation parent / changed-file check failed: no case started.');
 for r={pol.authorization.runRoot,pol.authorization.ledgerRoot},assert(~isfolder(fullfile(repo,strrep(r{1},'/',filesep))),'A3:Fresh','%s already exists.',r{1});end
 C=g2_lp2a3_context();assert(strcmp(strrep(C.repo,'\','/'),strrep(repo,'\','/')),'A3:Repo','Context repository differs.');
 R.engines=C.preflight.matlabProcesses;R.release=version('-release');R.tokenEqualsContext=strcmp(C.token,tok);
 R.memgate=g2_lp2a2_eq_memgate(pol.resources.freeRAMInsideMATLAB_GiB_min);
 wj(fullfile(outDir,'LP2A3_PRECHECK.json'),R);
 assert(R.tokenEqualsContext&&R.memgate.pass&&R.engines==1&&strcmp(R.release,'2023a'),'A3:Pre','Pre-run checks failed: no case started.');
 outcome='RUNNING';
 for k=1:numel(pol.cases)
  id=pol.cases(k).id;calls=calls+1;fprintf('A3_CASE_CALL %s %s\n',id,datestr(now,'HH:MM:SS'));
  O=g2_lp2a3_run('Case',id,'Run',true,'AuthToken',tok);res{end+1}=O; %#ok<AGROW>
  fprintf('A3_CASE_RETURN %s status=%s computed=%d terminal=%s last=S%d\n',id,O.status,O.computed,O.terminal,O.lastState);
  if strcmp(O.status,'GLOBAL_HOLD'),outcome='GLOBAL_HOLD';reason=[id ': ' O.hold.identifier];break,end
 end
 if strcmp(outcome,'RUNNING')
  Cv=g2_lp2a3_context('Preflight',false);V=verifier(Cv);Rv=g2_lp2a3_verify(V);R.finalVerify=Rv;
  if Rv.pass&&Rv.closed,outcome='CAMPAIGN_CLOSED_VERIFIED';else,outcome='VERIFY_HOLD';reason=strjoin(Rv.problems,'; ');end
 end
catch ME
 fprintf(2,'A3_EXTERNAL_EXCEPTION calls=%d %s: %s\n',calls,ME.identifier,ME.message);disp(getReport(ME));
 if calls==0,outcome='NOT_STARTED';else,outcome='HOLD_EXTERNAL_EXCEPTION';end
 reason=[ME.identifier ': ' ME.message];
end
W=struct('campaignId',pol.authorization.campaignId,'outcome',outcome,'reason',reason,'caseCalls',calls,'results',{res},'wallSeconds',toc(T0),'precheck',R);
wj(fullfile(outDir,'LP2A3_CAMPAIGN.json'),W);
if isfolder(fullfile(repo,'outputs')),wj(fullfile(repo,'outputs','LP2A3_CAMPAIGN.json'),W);end
fprintf('A3_RESULT outcome=%s caseCalls=%d reason=%s wall=%.1fs\n',outcome,calls,reason,W.wallSeconds);
end

function V=verifier(C)
pol=C.policy;ids={pol.cases.id};
V=struct('rd',C.runRoot,'lroot',C.ledgerRoot,'ids',{ids},'masks',reshape([pol.cases.mask],3,[]).','parents',struct(),'pol',pol,'token',C.token, ...
 'policySHA256',C.policySHA256,'g2SourceSHA256',C.g2SourceSHA256,'lp2a2SourceSHA256',C.lp2a2SourceSHA256,'lp2a3SourceSHA256',C.lp2a3SourceSHA256,'requireTerminal',true);
for i=1:numel(ids),P=g2_lp2a3_parent(C,ids{i});V.parents.(ids{i})=struct('state',P.state,'stateSHA256',P.stateSHA256);end
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
fid=fopen(f,'w');assert(fid>0,'A3:Write','Cannot write %s',f);fwrite(fid,jsonencode(S,'PrettyPrint',true),'char');fclose(fid);
end
