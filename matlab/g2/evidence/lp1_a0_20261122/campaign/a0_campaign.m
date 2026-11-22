% G2-LP1-A0 campaign G2-LP1-A0-001 (Issue #64): exactly the eight preregistered controller
% calls, one MATLAB session, one fixed execution checkout. Stops the WHOLE campaign at the
% first HOLD, error or unexpected count. No retry, no resume record, no other call.
repo='<repo>';cd(repo);addpath(fullfile(repo,'matlab','g2'),'-begin');
tok=['G2LP1|policy=074d7edc981920537726314f781f24b41ac7224c18d594d6a1b15343084e5091', ...
 '|source=9b634df22d2c44ba9f6465fa9c88f54274afa3a17aa5d43df1e2b2ac58b5c2b5', ...
 '|LP0=b4240d7ed9b534dbe188a35bac13587db45f8cd1a86a5c7a79c2e1dfa4a233f5|cases=H,stiff13,soft2,soft1|maxState=4'];
rn='run_a0_lp1_repro_v1';
seq={'H',2,3,0;'stiff13',2,3,0;'soft2',2,3,0;'soft1',2,3,0;'H',4,2,3;'stiff13',4,2,3;'soft2',4,2,3;'soft1',4,2,3};
logdir=fullfile(repo,'outputs','g2_lp1_a0_campaign_log');assert(~isfolder(logdir),'A0:Log','Campaign log folder exists.');mkdir(logdir);
calls=struct('index',{},'caseId',{},'maxStateIndex',{},'startUTC',{},'endUTC',{},'seconds',{},'ramBefore_GiB',{},'ramAfter_GiB',{}, ...
 'status',{},'computed',{},'reused',{},'promoted',{},'lastState',{},'campaignMode',{},'campaignClosed',{},'error',{},'expectedOK',{});
utc=@()char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss.SSS''Z'''));
terminal='A0_CAMPAIGN_COMPLETE';
for i=1:size(seq,1)
 [cs,ms,expC,expR]=seq{i,:};
 [~,m]=memory;r0=m.PhysicalMemory.Available/2^30;t0=tic;s0=utc();
 fprintf('A0_CALL %d START case=%s MaxStateIndex=%d RAM=%.3f GiB %s\n',i,cs,ms,r0,s0);
 err='';O=struct('status','ERROR','computed',NaN,'reused',NaN,'promoted',NaN,'lastState',NaN);
 try
  O=g2_lp1_run('Case',cs,'MaxStateIndex',ms,'Run',true,'AuthToken',tok,'RunName',rn);
 catch ME
  err=[ME.identifier,' | ',ME.message];
 end
 [~,m]=memory;r1=m.PhysicalMemory.Available/2^30;
 mode='';if isfield(O,'campaignMode'),mode=O.campaignMode;end
 closed=isfield(O,'campaignClosed')&&isequal(O.campaignClosed,true);
 expStatus='BOUNDED_PREFIX_COMPLETE';if ms==4,expStatus='CASE_S4_COMPLETE_AWAIT_CAMPAIGN_REVIEW';end
 expMode='CONTINUE';if i==1,expMode='OPEN_NEW';end
 okc=isempty(err)&&strcmp(O.status,expStatus)&&O.computed==expC&&O.reused==expR&&O.promoted==0&&O.lastState==ms&&strcmp(mode,expMode)&&(closed==(i==8));
 calls(end+1)=struct('index',i,'caseId',cs,'maxStateIndex',ms,'startUTC',s0,'endUTC',utc(),'seconds',toc(t0),'ramBefore_GiB',r0,'ramAfter_GiB',r1, ...
  'status',O.status,'computed',O.computed,'reused',O.reused,'promoted',O.promoted,'lastState',O.lastState,'campaignMode',mode, ...
  'campaignClosed',closed,'error',err,'expectedOK',okc); %#ok<SAGROW>
 if isfield(O,'hold'),calls(end).error=[calls(end).error,' HOLD:',O.hold.stopCode,' ',O.hold.message];end
 fprintf('A0_CALL %d END status=%s computed=%g reused=%g promoted=%g last=%g mode=%s closed=%d expectedOK=%d %.1fs err=%s\n', ...
  i,O.status,O.computed,O.reused,O.promoted,O.lastState,mode,closed,okc,toc(t0),calls(end).error);
 fid=fopen(fullfile(logdir,'A0_CALLS.json'),'w');fwrite(fid,jsonencode(calls,'PrettyPrint',true),'char');fclose(fid);
 if ~okc
  terminal=sprintf('HOLD_A0_STOPPED_AT_CALL_%d',i);fprintf(2,'A0_CAMPAIGN_STOP %s\n',terminal);break
 end
end
R=struct('schema','NewMetacomp.G2.LP1.A0.CampaignLog.v1','campaignId','G2-LP1-A0-001','runName',rn,'token',tok, ...
 'terminal',terminal,'calls',calls,'totalComputed',sum([calls.computed]),'finishedUTC',utc());
fid=fopen(fullfile(logdir,'A0_CAMPAIGN_RESULT.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
fprintf('A0_CAMPAIGN_TERMINAL %s totalComputed=%g\n',terminal,R.totalComputed);
