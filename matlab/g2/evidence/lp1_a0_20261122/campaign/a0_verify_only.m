% G2-LP1-A0 post-closure VERIFY_ONLY calls (Issue #64, A0-3): one call per case with
% MaxStateIndex=4 under the still-present GO. Expected: computed=0, reused=5, promoted=0,
% campaignMode=VERIFY_ONLY; every byte of the run folder and campaign ledger unchanged.
repo='<repo>';cd(repo);addpath(fullfile(repo,'matlab','g2'),'-begin');
tok=['G2LP1|policy=074d7edc981920537726314f781f24b41ac7224c18d594d6a1b15343084e5091', ...
 '|source=9b634df22d2c44ba9f6465fa9c88f54274afa3a17aa5d43df1e2b2ac58b5c2b5', ...
 '|LP0=b4240d7ed9b534dbe188a35bac13587db45f8cd1a86a5c7a79c2e1dfa4a233f5|cases=H,stiff13,soft2,soft1|maxState=4'];
rn='run_a0_lp1_repro_v1';
rd=fullfile(repo,'outputs','g2_lp1_matrix_paths_v1',rn);lroot=fullfile(repo,'outputs','g2_lp1_campaign_ledger','G2-LP1-A0-001');
before=[hashTree(rd);hashTree(lroot)];
assert(isfile(fullfile(lroot,'CLOSED.mat')),'A0:Verify','Campaign is not closed; VERIFY_ONLY not applicable.');
cases={'H','stiff13','soft2','soft1'};V=struct('caseId',{},'status',{},'computed',{},'reused',{},'promoted',{},'mode',{},'error',{},'ok',{},'ramBefore_GiB',{});
for i=1:4
 [~,m]=memory;r0=m.PhysicalMemory.Available/2^30;err='';O=struct('status','ERROR','computed',NaN,'reused',NaN,'promoted',NaN);
 try
  O=g2_lp1_run('Case',cases{i},'MaxStateIndex',4,'Run',true,'AuthToken',tok,'RunName',rn);
 catch ME
  err=[ME.identifier,' | ',ME.message];
 end
 mode='';if isfield(O,'campaignMode'),mode=O.campaignMode;end
 ok=isempty(err)&&strcmp(O.status,'CASE_S4_COMPLETE_AWAIT_CAMPAIGN_REVIEW')&&O.computed==0&&O.reused==5&&O.promoted==0&&strcmp(mode,'VERIFY_ONLY');
 V(end+1)=struct('caseId',cases{i},'status',O.status,'computed',O.computed,'reused',O.reused,'promoted',O.promoted,'mode',mode,'error',err,'ok',ok,'ramBefore_GiB',r0); %#ok<SAGROW>
 fprintf('VERIFY_ONLY %s status=%s computed=%g reused=%g promoted=%g mode=%s ok=%d err=%s\n',cases{i},O.status,O.computed,O.reused,O.promoted,mode,ok,err);
 if ~ok,break,end
end
after=[hashTree(rd);hashTree(lroot)];
unchanged=isequal(before,after);
fprintf('VERIFY_ONLY_BYTES_UNCHANGED=%d files=%d\n',unchanged,size(before,1));
R=struct('schema','NewMetacomp.G2.LP1.A0.VerifyOnly.v1','calls',V,'filesHashed',size(before,1),'bytesUnchanged',unchanged, ...
 'pass',all([V.ok])&&numel(V)==4&&unchanged);
fid=fopen(fullfile(repo,'outputs','g2_lp1_a0_campaign_log','A0_VERIFY_ONLY.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
fprintf('A0_VERIFY_ONLY_PASS=%d\n',R.pass);

function H=hashTree(root)
d=dir(fullfile(root,'**','*'));d=d(~[d.isdir]);H=cell(numel(d),2);
for k=1:numel(d)
 f=fullfile(d(k).folder,d(k).name);fid=fopen(f,'r');b=fread(fid,inf,'*uint8');fclose(fid);
 md=java.security.MessageDigest.getInstance('SHA-256');md.update(b);
 H{k,1}=strrep(f,root,'');H{k,2}=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
end
H=sortrows(H,1);
end
