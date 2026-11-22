% G2-A1-FB-001 post-closure: zero-solve VERIFY_ONLY calls, ledger inventory, analysis (no FEM).
repo='<repo>';cd(repo);addpath(fullfile(repo,'matlab','g2'),'-begin');
addpath('<worktree>/scripts/report','-begin');
RUN='run_a1_family_b_s4_v1';C=g2_a1_context();TOK=C.token;
logd=fullfile(repo,'outputs','g2_a1_campaign_log');
lroot=fullfile(repo,'outputs','g2_a1_campaign_ledger','G2-A1-FB-001');
cases={'H','stiff13','soft2','soft1'};V={};
try
 for ci=1:4
  for m=[3 6 9]
   O=g2_a1_run('Case',cases{ci},'Level',m,'Run',true,'AuthToken',TOK,'RunName',RUN);
   V{end+1}=struct('key',O.key,'status',O.status,'computed',O.computed,'reused',O.reused,'campaignMode',O.campaignMode); %#ok<SAGROW>
   assert(strcmp(O.status,'REUSED_ZERO_SOLVE')&&O.computed==0&&strcmp(O.campaignMode,'VERIFY_ONLY'),'A1VER:Mode','%s not VERIFY_ONLY reuse',O.key);
   fprintf('VERIFY %s %s computed=%d mode=%s\n',O.key,O.status,O.computed,O.campaignMode);
  end
 end
catch ME
 fprintf(2,'A1_VERIFY_FAIL %s %s\n',ME.identifier,ME.message);exit(1);
end
L=g2_lp1_campaign_ledger('snapshot',lroot);
d=dir(lroot);d=d(~[d.isdir]);inv=struct('file',{},'sha256',{});
for k=1:numel(d),inv(end+1)=struct('file',d(k).name,'sha256',lower(g2_sha256_file(fullfile(d(k).folder,d(k).name))));end %#ok<SAGROW>
[Cl,~,okc]=g2_trajectory_record('read',fullfile(lroot,'CLOSED.mat'));assert(okc,'A1VER:Closed','CLOSED record failed verification');
R=struct('verifyCalls',{V},'nAdmits',numel(L.admits),'ledgerIntegrityOK',L.integrityOK,'ledgerClosed',L.closed, ...
 'ledgerFiles',inv,'closedKeys',{Cl.keys},'closedStateSHA256',{Cl.stateSHA256});
fid=fopen(fullfile(logd,'A1_VERIFY_ONLY.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
fprintf('LEDGER admits=%d files=%d\n',numel(L.admits),numel(inv));
A=g2_a1_analyze(repo,RUN,fullfile(logd,'A1_ANALYSIS.json'));
if ~A.allChecksPass,fprintf(2,'A1_ANALYSIS_CHECK_FAIL\n');exit(2);end
exit(0);
