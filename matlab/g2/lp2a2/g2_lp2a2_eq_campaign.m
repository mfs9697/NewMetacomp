function W=g2_lp2a2_eq_campaign(token,varargin)
%G2_LP2A2_EQ_CAMPAIGN  PREPARED external wrapper of the four-solve LP2-A2 equivalence campaign.
%  W = g2_lp2a2_eq_campaign(tok)   % only after an investigator GO; never run at preparation
% 1. GO validation (g2_lp2a2_eq_go_validate on the committed GO file) and contract-evidence SHA
%    check BEFORE any solve; failure -> HOLD_UNAUTHORIZED, zero solves.
% 2. EQ-H, EQ-stiff13, EQ-soft2, EQ-soft1 in this order, one call each. ANY exception, any stage
%    other than SOLVED_COMPARED, any missing record field (incomplete write) or a failed comparison
%    stops the WHOLE campaign; later solves are not called; attempted folders are preserved; no
%    retry, no alternate clone.
% 3. After four passing solves: architecture contrast (g2_lp2a2_eq_contrast) -> EQUIVALENT or
%    NOT_EQUIVALENT_HOLD.
% Afterwards, whatever the outcome (also on HOLD): read-only replay g2_lp2a2_eq_verify, archive on
% two physical devices, revoke the GO in a separate commit and verify the refusal (W.next).
% Limitation: the one-attempt guard is the local solve folder; deleting it or using an independent
% clone would defeat it - prevented only by protocol and the archive/ledger review.
% 'Runner', 'Validator', 'Context' may be injected for zero-FEM tests.
ip=inputParser;addParameter(ip,'Runner',[]);addParameter(ip,'Validator',[]);addParameter(ip,'Context',[]);parse(ip,varargin{:});o=ip.Results;
C=o.Context;if isempty(C),C=g2_lp2a2_eq_context();end
pol=C.policy;ids={pol.solves.id};
run=o.Runner;if isempty(run),run=@(id)g2_lp2a2_eq_run(id,'Run',true,'Token',token);end
val=o.Validator;if isempty(val),val=@()defaultValidator(C,token);end
W=struct('campaignId',pol.campaignId,'token',C.token,'outcome','NOT_STARTED','stoppedAt','','reason','','solvesCalled',0,'results',{{}},'contrast',[], ...
 'next','read-only replay (g2_lp2a2_eq_verify); archive on two physical devices; revoke the GO in a separate commit and verify refusal - also after any HOLD');
V=val();
if ~V.pass,W.outcome='HOLD_UNAUTHORIZED';W.reason=strjoin(V.failed,', ');return,end
KN=struct();
for k=1:numel(ids)
 W.solvesCalled=W.solvesCalled+1;
 try
  O=run(ids{k});
 catch ME
  W.outcome='HOLD_EXCEPTION';W.stoppedAt=ids{k};W.reason=[ME.identifier ': ' ME.message];return
 end
 W.results{end+1}=O;
 need={'stage','comparisonPass','newK','solutionSHA256'};
 if ~isstruct(O)||~all(isfield(O,need))
  W.outcome='HOLD_INCOMPLETE_RECORD';W.stoppedAt=ids{k};W.reason='driver result lacks required fields';return
 end
 if ~strcmp(O.stage,'SOLVED_COMPARED'),W.outcome='HOLD_STAGE';W.stoppedAt=ids{k};W.reason=O.stage;return,end
 if ~O.comparisonPass,W.outcome='NOT_EQUIVALENT_HOLD';W.stoppedAt=ids{k};W.reason=strjoin(O.failed,', ');return,end
 KN.(pol.solves(k).caseId)=O.newK;
end
KA=struct();
for k=1:numel(ids)
 c=pol.solves(k).caseId;So=load(fullfile(C.archiveBase,c,'S8','SOLUTION.mat'));KA.(c)=So.record.K;
end
R=g2_lp2a2_eq_contrast(KN,KA,pol.tolerances);W.contrast=R;
if R.pass,W.outcome='EQUIVALENT';else,W.outcome='NOT_EQUIVALENT_HOLD';W.stoppedAt='contrast';W.reason=strjoin(R.failed,', ');end
end

function V=defaultValidator(C,token)
gf=fullfile(C.repo,C.policy.goFile);
if ~isfile(gf),V=struct('pass',false,'failed',{{'noGoFile'}});return,end
V=g2_lp2a2_eq_go_validate(jsondecode(fileread(gf)),C,token);
end
