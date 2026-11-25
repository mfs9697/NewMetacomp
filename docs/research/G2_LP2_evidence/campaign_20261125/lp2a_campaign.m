% LP2-A1 campaign G2-LP2A-001: four sequential authorized calls with an EXTERNAL global-stop rule.
% A case may be followed by the next one only if it returned TERMINAL_*, its chain/terminal/ledger
% verify (g2_lp2_verify) and the ledger holds no HOLD entry. Any exception, GLOBAL_HOLD, other
% status, failed verification or ledger HOLD stops the entire campaign (no retry, no resumption).
ex='<repo>';
out='<scratch>';
addpath(fullfile(ex,'matlab','g2','lp2'));
RUN='run_lp2a_s5_s8_v1';CID='G2-LP2A-001';ids={'H','stiff13','soft2','soft1'};
calls=struct('caseId',{},'status',{},'computed',{},'reused',{},'terminal',{},'lastState',{},'seconds',{},'admitsAfter',{},'holdsAfter',{}, ...
 'verifyPass',{},'verifyProblems',{},'decision',{},'error',{});
stop='';closed=false;
try
 assert(~isfolder(out));mkdir(out);
 C=g2_lp2_context();[~,s]=memory;ram0=s.PhysicalMemory.Available/2^30;
 fprintf('LP2A_CAMPAIGN_START commit=%s RAM_inside=%.3f token=%s\n',C.preflight.sourceCommit,ram0,C.token);
 assert(ram0>=7,'CAMP:RAM','Operational 7 GiB safeguard not met inside MATLAB (%.3f GiB).',ram0);
 assert(isfile(fullfile(C.lp2,'G2_LP2A_SCIENTIFIC_GO_v1.json')),'CAMP:GO','GO file missing.');
 rd=fullfile(ex,'outputs','g2_lp2a_paths_v1',RUN);lroot=fullfile(ex,'outputs','g2_lp2a_campaign_ledger',CID);
 assert(~isfolder(rd)&&~isfolder(lroot),'CAMP:Fresh','Run or ledger already exists.');
 pol=C.policy;V=struct('rd',rd,'lroot',lroot,'ids',{ids},'masks',reshape([pol.cases.mask],3,[]).','parents',struct(),'pol',pol, ...
  'token',C.token,'policySHA256',C.policySHA256,'g2SourceSHA256',C.g2SourceSHA256,'lp2SourceSHA256',C.lp2SourceSHA256);
 A0=fullfile(ex,strrep(pol.parents.run,'/',filesep));
 for i=1:4,f=fullfile(A0,ids{i},'S4','STATE.mat');[St,~,~]=g2_trajectory_record('read',f);V.parents.(ids{i})=struct('state',St,'stateSHA256',lower(g2_sha256_file(f)));end
 for i=1:4
  c=struct('caseId',ids{i},'status','','computed',NaN,'reused',NaN,'terminal','','lastState',NaN,'seconds',NaN,'admitsAfter',NaN,'holdsAfter',NaN, ...
   'verifyPass',false,'verifyProblems',{{}},'decision','','error','');
  t0=tic;
  try
   O=g2_lp2_run('Case',ids{i},'Run',true,'AuthToken',C.token,'RunName',RUN);
   c.status=O.status;c.computed=O.computed;c.reused=O.reused;if isfield(O,'terminal'),c.terminal=O.terminal;c.lastState=O.lastState;end
   if isfield(O,'campaignClosed')&&O.campaignClosed,closed=true;end
  catch ME
   c.status='EXCEPTION';c.error=[ME.identifier ': ' ME.message];
  end
  c.seconds=toc(t0);
  L=g2_lp1_campaign_ledger('snapshot',lroot);c.admitsAfter=numel(L.admits);c.holdsAfter=numel(L.holds);
  if startsWith(c.status,'TERMINAL_')
   Vc=V;Vc.cases={ids{i}};Vc.requireTerminal=false;Rv=g2_lp2_verify(Vc);c.verifyPass=Rv.pass;c.verifyProblems=Rv.problems;
   T=fullfile(rd,ids{i},'TERMINAL.mat');
   if Rv.pass&&isfile(T)&&c.holdsAfter==0&&isequal(L.integrityOK,true)&&c.admitsAfter<=16,c.decision='CONTINUE';
   else,c.decision='GLOBAL_STOP';stop=sprintf('%s: verification/ledger check failed after terminal (%s)',ids{i},strjoin(Rv.problems,'; '));end
  else
   c.decision='GLOBAL_STOP';stop=sprintf('%s: status %s %s',ids{i},c.status,c.error);
  end
  calls(end+1)=c; %#ok<SAGROW>
  fprintf('LP2A_CALL %-7s %s computed=%g reused=%g terminal=%s last=S%g admits=%d holds=%d verify=%d t=%.1fs -> %s\n',ids{i},c.status,c.computed,c.reused, ...
   c.terminal,c.lastState,c.admitsAfter,c.holdsAfter,c.verifyPass,c.seconds,c.decision);
  if ~strcmp(c.decision,'CONTINUE'),fprintf(2,'LP2A_GLOBAL_STOP %s\n',stop);break,end
 end
 closedFile=isfile(fullfile(lroot,'CLOSED.mat'));
 if isempty(stop)&&~closedFile,stop='all four cases terminal but CLOSED missing';fprintf(2,'LP2A_GLOBAL_STOP %s\n',stop);end
catch ME
 stop=['WRAPPER_EXCEPTION ' ME.identifier ': ' ME.message];fprintf(2,'LP2A_GLOBAL_STOP %s\n',stop);disp(getReport(ME));
end
R=struct('calls',calls,'globalStop',stop,'closedReturned',closed,'closedFile',exist('closedFile','var')&&closedFile);
fid=fopen(fullfile(out,'LP2A_CALLS.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
fprintf('LP2A_CAMPAIGN_DONE globalStop="%s" closed=%d\n',stop,R.closedFile);
