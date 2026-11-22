% G2-A1-FB-001 campaign driver (Issue #66). One MATLAB process, sequential, stop on any HOLD.
repo='<repo>';cd(repo);addpath(fullfile(repo,'matlab','g2'),'-begin');
RUN='run_a1_family_b_s4_v1';
TOK=['G2A1|policy=312e1e005b9ca85d743b672115609d7b02bb2f6ebbbae09658c0cdf1d9a8a013', ...
 '|source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947', ...
 '|meshes=ffee15fd508b5b13e78850cefd88e7d0b04308f70c468c0c1e85f7f78a0ecbc5', ...
 '|cases=H,stiff13,soft2,soft1|levels=3,6,9|maxSolves=12'];
logd=fullfile(repo,'outputs','g2_a1_campaign_log');if ~isfolder(logd),mkdir(logd);end
L=struct('startedUTC',char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss''Z''')),'calls',{{}});
try
 C=g2_a1_context();
 assert(strcmp(C.token,TOK),'A1DRV:TokenMismatch','Context token differs from the authorization record.');
 G=g2_a1_scientific_gate(C);
 fprintf('PREFLIGHT commit=%s go=%s campaign=%s run=%s RAM=%.3f GiB\n',C.preflight.sourceCommit,G.goFileSHA256,G.campaignId,G.approvedRunName,C.preflight.freePhysicalRAM_GiB);
 assert(strcmp(G.approvedRunName,RUN)&&strcmp(G.campaignId,'G2-A1-FB-001'),'A1DRV:Scope','GO scope differs.');
 assert(~isfolder(fullfile(repo,'outputs','g2_a1_fixed_path_v1',RUN))&&~isfolder(fullfile(repo,'outputs','g2_a1_campaign_ledger',G.campaignId)), ...
  'A1DRV:Exists','Run folder or ledger already exists.');
 L.preflight=struct('sourceCommit',C.preflight.sourceCommit,'goFileSHA256',G.goFileSHA256,'token',C.token,'freeRAM_GiB',C.preflight.freePhysicalRAM_GiB);
catch ME
 fprintf(2,'A1_PREFLIGHT_HOLD %s %s\n',ME.identifier,ME.message);exit(3);
end
cases={'H','stiff13','soft2','soft1'};
for ci=1:4
 for m=[3 6 9]
  key=sprintf('%s_B%d',cases{ci},m);
  try
   O=g2_a1_run('Case',cases{ci},'Level',m,'Run',true,'AuthToken',TOK,'RunName',RUN);
  catch ME
   fprintf(2,'A1_CALL_EXCEPTION %s %s %s\n',key,ME.identifier,ME.message);
   L.calls{end+1}=struct('key',key,'status','EXCEPTION','identifier',ME.identifier,'message',ME.message);
   writeLog(logd,L);exit(1);
  end
  r=struct('key',key,'status',O.status,'computed',O.computed,'reused',O.reused,'campaignMode',O.campaignMode);
  if ~strcmp(O.status,'A1_STATE_COMPLETE')
   if isfield(O,'hold'),r.hold=O.hold;end
   L.calls{end+1}=r;writeLog(logd,L);
   fprintf(2,'A1_STOP %s status=%s\n',key,O.status);exit(2);
  end
  s=O.state;r.KI=s.KI;r.KII=s.KII;r.G=s.G;r.J=s.J;r.MTS_deg=s.MTS_deg;r.resources=s.resources;
  if isfield(O,'campaignClosed'),r.campaignClosed=O.campaignClosed;end
  L.calls{end+1}=r;writeLog(logd,L);
  fprintf('A1_OK %-10s KI=%.12g KII=%.12g G=%.12g MTS=%.6f t=%.1fs avail=%.2f GiB\n',key,s.KI,s.KII,s.G,s.MTS_deg,s.resources.seconds,s.resources.availableAfter_GiB);
 end
end
L.finishedUTC=char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss''Z'''));writeLog(logd,L);
fprintf('A1_CAMPAIGN_DONE closed=%d\n',isfile(fullfile(repo,'outputs','g2_a1_campaign_ledger','G2-A1-FB-001','CLOSED.mat')));
exit(0);

function writeLog(d,L)
fid=fopen(fullfile(d,'A1_CALLS.json'),'w');fwrite(fid,jsonencode(L,'PrettyPrint',true),'char');fclose(fid);
end
