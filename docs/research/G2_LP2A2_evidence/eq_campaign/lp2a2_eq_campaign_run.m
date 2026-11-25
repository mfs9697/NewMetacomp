% LP2-A2 equivalence campaign G2-LP2A2-EQ-001 (authorized: PR #71 issuecomment-7167996437): ONE external call of the wrapper.
% Before the wrapper: head/activation-binding check, pure GO validation (dry, no solve), memory margin, output root absent.
% The wrapper g2_lp2a2_eq_campaign(tok) is called exactly once; no retry, no other solve call, no code change.
ex='<repo>';
out='<scratch>\campaign';
addpath(fullfile(ex,'matlab','g2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a2'),'-begin');
TOK=['G2LP2A2EQ|policy=bc1f86e7750aaea653cd7544c8fff0ad757843a23bd00608145dad70dcd8a330|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947', ...
 '|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca|lp2a2source=00c99e93915ad2c0dbd4eaeb307d94d65b4c71300f94a0f073aadacb9c5a61c2', ...
 '|archivedS8=da951c99c0d8c1d5dd731986d8f3b30e3db3f71854166a634d35b739757def8d|solves=EQ-H,EQ-stiff13,EQ-soft2,EQ-soft1|limit=4'];
W=[];called=false;T0=tic;
try
 R=struct();[~,h]=system(sprintf('git -C "%s" rev-parse HEAD',ex));R.head=strtrim(h);[~,h2]=system(sprintf('git -C "%s" rev-parse HEAD^',ex));R.headParent=strtrim(h2);
 fprintf('CAMP head=%s parent=%s\n',R.head,R.headParent);
 assert(strcmp(R.headParent,'4d3701e1ccc91b7512db9052c927f32af52e2479'),'CAMP:Binding','HEAD^ is not the approved head.');
 assert(~isfolder(fullfile(ex,'outputs','g2_lp2a2_eq_v1')),'CAMP:Fresh','Output root already exists.');
 C=g2_lp2a2_eq_context();    % normal preflight, 5 GiB guard unchanged
 [~,s2]=memory;R.ramAfterContext_GiB=s2.PhysicalMemory.Available/2^30;R.engines=C.preflight.matlabProcesses;R.release=version('-release');R.tokenEqualsApproved=strcmp(C.token,TOK);
 R.memgate=g2_lp2a2_eq_memgate(7);
 G=jsondecode(fileread(fullfile(ex,C.policy.goFile)));V=g2_lp2a2_eq_go_validate(G,C,TOK);
 R.goValidate=V;R.goFields=G;
 fprintf('CAMP ram=%.3f memgate=%d engines=%d release=%s token=%d goValidate=%d failed=[%s]\n',R.ramAfterContext_GiB,R.memgate.pass,R.engines,R.release,R.tokenEqualsApproved,V.pass,strjoin(V.failed,','));
 fid=fopen(fullfile(out,'LP2A2_EQ_GO_DRYCHECK.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
 assert(V.pass&&R.tokenEqualsApproved&&R.memgate.pass&&R.engines==1&&strcmp(R.release,'2023a'),'CAMP:Pre','Pre-run checks failed: no wrapper call, no attempt consumed.');
 assert(R.ramAfterContext_GiB>=7.3,'CAMP:Margin','Available %.3f GiB < 7.3 GiB margin: no wrapper call, no attempt consumed.',R.ramAfterContext_GiB);
 fprintf('CAMP_CALL g2_lp2a2_eq_campaign start %s\n',datestr(now,'HH:MM:SS'));
 called=true;
 W=g2_lp2a2_eq_campaign(TOK);
catch ME
 fprintf(2,'CAMP_EXTERNAL_EXCEPTION called=%d %s: %s\n',called,ME.identifier,ME.message);disp(getReport(ME));
 if called,W=struct('campaignId','G2-LP2A2-EQ-001','outcome','HOLD_EXTERNAL_EXCEPTION','stoppedAt','','reason',[ME.identifier ': ' ME.message],'solvesCalled',NaN,'results',{{}},'contrast',[]);
 else,W=struct('campaignId','G2-LP2A2-EQ-001','outcome','NOT_CALLED','stoppedAt','','reason',[ME.identifier ': ' ME.message],'solvesCalled',0,'results',{{}},'contrast',[]);end
end
W.wallSeconds=toc(T0);W.wrapperCalled=called;
js=jsonencode(W,'PrettyPrint',true);
for f={fullfile(ex,'outputs','LP2A2_EQ_CAMPAIGN.json'),fullfile(out,'LP2A2_EQ_CAMPAIGN.json')}
 fid=fopen(f{1},'w');fwrite(fid,js,'char');fclose(fid);
end
fprintf('CAMP_RESULT outcome=%s stoppedAt=%s reason=%s solvesCalled=%g wrapperCalled=%d wall=%.1fs\n',W.outcome,W.stoppedAt,W.reason,W.solvesCalled,called,W.wallSeconds);
for k=1:numel(W.results)
 O=W.results{k};
 if isstruct(O)&&isfield(O,'stage')
  cp='n/a';if isfield(O,'comparisonPass'),cp=num2str(O.comparisonPass);end
  fl='';if isfield(O,'failed')&&~isempty(O.failed),fl=strjoin(cellstr(O.failed),',');end
  ki=NaN;kii=NaN;if isfield(O,'newK'),ki=O.newK.KI;kii=O.newK.KII;end
  fprintf('CAMP_SOLVE %s stage=%s comparisonPass=%s failed=[%s] T3=%d archivedT3=%d KI=%.12g KII=%.12g\n',O.solveId,O.stage,cp,fl,O.T3,O.archivedT3,ki,kii);
 end
end
if isstruct(W.contrast)&&isfield(W.contrast,'pass'),fprintf('CAMP_CONTRAST pass=%d dFG=%s ddTheta=%s\n',W.contrast.pass,mat2str(W.contrast.dFG,6),mat2str(W.contrast.ddTheta_deg,6));end
d=dir(fullfile(ex,'outputs','g2_lp2a2_eq_v1'));fprintf('CAMP_FOLDERS %s\n',strjoin({d([d.isdir]&~ismember({d.name},{'.','..'})).name},','));
