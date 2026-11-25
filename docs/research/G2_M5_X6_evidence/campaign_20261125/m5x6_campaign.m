% M5-X6 campaign G2-M5-X6-001: six sequential authorized calls; stop on the first non-complete status.
ex='<repo>';
out='<scratch>\m5x6run\campaign';
addpath(fullfile(ex,'scripts','g2','m5','x6'));
RUN='run_m5x6_crossed_s4_b9_v1';ids={'X6-01','X6-02','X6-03','X6-04','X6-05','X6-06'};
calls=struct('config',{},'status',{},'computed',{},'reused',{},'campaignMode',{},'KI',{},'KII',{},'G',{},'J',{},'MTS_deg',{}, ...
 'seconds',{},'availableBefore_GiB',{},'availableAfter_GiB',{},'matlabUsedAfter_GiB',{},'hold',{});
try
 assert(~isfolder(out));mkdir(out);
 C=g2_m5x6_context();
 fprintf('CAMPAIGN_START commit=%s RAM=%.3f token=%s\n',C.preflight.sourceCommit,C.preflight.freePhysicalRAM_GiB,C.token);
 assert(C.preflight.freePhysicalRAM_GiB>=7,'CAMP:RAM','Operational 7 GiB safeguard not met at campaign start (%.3f GiB).',C.preflight.freePhysicalRAM_GiB);
 assert(isfile(fullfile(C.x6,'G2_M5_X6_SCIENTIFIC_GO_v1.json')),'CAMP:GO','GO file missing.');
 assert(~isfolder(fullfile(ex,'outputs','g2_m5x6_crossed_v1'))&&~isfolder(fullfile(ex,'outputs','g2_m5x6_campaign_ledger')),'CAMP:Fresh','Run or ledger already exists.');
 for k=1:6
  O=g2_m5x6_run('Config',ids{k},'Run',true,'AuthToken',C.token,'RunName',RUN);
  c=struct('config',ids{k},'status',O.status,'computed',O.computed,'reused',O.reused,'campaignMode',getf(O,'campaignMode'), ...
   'KI',NaN,'KII',NaN,'G',NaN,'J',NaN,'MTS_deg',NaN,'seconds',NaN,'availableBefore_GiB',NaN,'availableAfter_GiB',NaN,'matlabUsedAfter_GiB',NaN,'hold',getf(O,'hold'));
  if isfield(O,'state')
   S=O.state;c.KI=S.KI;c.KII=S.KII;c.G=S.G;c.J=S.J;c.MTS_deg=S.MTS_deg;c.seconds=S.resources.seconds;
   c.availableBefore_GiB=S.resources.availableBefore_GiB;c.availableAfter_GiB=S.resources.availableAfter_GiB;c.matlabUsedAfter_GiB=S.resources.matlabUsedAfter_GiB;
  end
  calls(end+1)=c; %#ok<SAGROW>
  fprintf('M5X6_CALL %s %s computed=%d mode=%s KI=%.9e KII=%+.9e G=%.9e MTS=%+.6f t=%.2fs RAM %.3f->%.3f closed=%d\n',ids{k},O.status,O.computed, ...
   c.campaignMode,c.KI,c.KII,c.G,c.MTS_deg,c.seconds,c.availableBefore_GiB,c.availableAfter_GiB,isfield(O,'campaignClosed'));
  if ~strcmp(O.status,'M5X6_STATE_COMPLETE'),fprintf(2,'M5X6_CAMPAIGN_STOP at %s: %s\n',ids{k},O.status);break,end
 end
catch ME
 fprintf(2,'M5X6_CAMPAIGN_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
fid=fopen(fullfile(out,'M5X6_CALLS.json'),'w');fwrite(fid,jsonencode(calls,'PrettyPrint',true),'char');fclose(fid);
fprintf('M5X6_CAMPAIGN_DONE completed=%d closedLedger=%d\n',nnz(strcmp({calls.status},'M5X6_STATE_COMPLETE')), ...
 isfile(fullfile(ex,'outputs','g2_m5x6_campaign_ledger','G2-M5-X6-001','CLOSED.mat')));
function v=getf(s,f)
if isfield(s,f),v=s.(f);else,v='';end
end
