function W=g2_lp2b1eq_campaign(token,varargin)
%G2_LP2B1EQ_CAMPAIGN  PROSPECTIVE two-solve wrapper of G2-LP2B1-EQ-001 (called only by g2_lp2b1eq_external_run).
%  W = g2_lp2b1eq_campaign(tok)
% Prospective copy of the accepted WP5 wrapper g2_lp2a2_eq_campaign without the architecture contrast:
% 1. GO validation (g2_lp2b1eq_go_validate on the committed GO file) BEFORE any solve; failure -> HOLD_UNAUTHORIZED.
% 2. EQB-soft1-S9 then EQB-H-S10, one call each. ANY exception, any stage other than SOLVED_COMPARED, a driver
%    result without the required fields, an INPUT_INVALID comparison (verification-infrastructure HOLD) or a
%    NOT_EQUIVALENT comparison (numerical HOLD) stops the WHOLE campaign; the second solve is not called; attempted
%    folders are preserved; no retry.
% 3. Both EQUIVALENT_CASE -> EQUIVALENT_AT_0p40 (two fixed geometries only; no error bound, no contrast).
% 'Runner', 'Validator', 'Context' may be injected for zero-FEM tests.
ip=inputParser;addParameter(ip,'Runner',[]);addParameter(ip,'Validator',[]);addParameter(ip,'Context',[]);parse(ip,varargin{:});o=ip.Results;
C=o.Context;if isempty(C),C=g2_lp2b1eq_context();end
ids=cellfun(@(x)x.id,C.solves,'UniformOutput',false);
run=o.Runner;if isempty(run),run=@(id)g2_lp2b1eq_run(id,'Run',true,'Token',token);end
val=o.Validator;if isempty(val),val=@()defaultValidator(C,token);end
W=struct('campaignId',C.policy.campaignId,'token',C.token,'outcome','NOT_STARTED','holdKind','','stoppedAt','','reason','','solvesCalled',0,'results',{{}}, ...
 'next','read-only verification (g2_lp2b1eq_verify); archive on two physical devices; revoke the GO in a separate commit and verify refusal - on every outcome');
V=val();
if ~V.pass,W.outcome='HOLD_UNAUTHORIZED';W.holdKind='AUTHORIZATION';W.reason=strjoin(V.failed,', ');return,end
for k=1:numel(ids)
 W.solvesCalled=W.solvesCalled+1;
 try
  O=run(ids{k});
 catch ME
  W.outcome='HOLD_EXCEPTION';W.holdKind='INFRASTRUCTURE_OR_GATE';W.stoppedAt=ids{k};W.reason=[ME.identifier ': ' ME.message];return
 end
 W.results{end+1}=O;
 need={'stage','outcome','comparisonPass','newK','solutionSHA256','validation'};
 if ~isstruct(O)||~all(isfield(O,need))
  W.outcome='HOLD_INCOMPLETE_RECORD';W.holdKind='INFRASTRUCTURE';W.stoppedAt=ids{k};W.reason='driver result lacks required fields';return
 end
 if ~strcmp(O.stage,'SOLVED_COMPARED'),W.outcome='HOLD_STAGE';W.holdKind='INFRASTRUCTURE';W.stoppedAt=ids{k};W.reason=O.stage;return,end
 switch O.outcome
  case 'EQUIVALENT_CASE'
   if ~isequal(O.comparisonPass,true),W.outcome='HOLD_INCOMPLETE_RECORD';W.holdKind='INFRASTRUCTURE';W.stoppedAt=ids{k};W.reason='pass flag inconsistent';return,end
  case 'INPUT_INVALID'
   W.outcome='HOLD_VERIFICATION_INPUT';W.holdKind='VERIFICATION_INFRASTRUCTURE';W.stoppedAt=ids{k};W.reason=strjoin(O.validation,', ');return
  otherwise
   W.outcome='NOT_EQUIVALENT_HOLD';W.holdKind='NUMERICAL_EQUIVALENCE';W.stoppedAt=ids{k};W.reason=strjoin(O.failed,', ');return
 end
end
W.outcome='EQUIVALENT_AT_0p40';
end

function V=defaultValidator(C,token)
if ~isfile(C.goFile),V=struct('pass',false,'failed',{{'noGoFile'}});return,end
V=g2_lp2b1eq_go_validate(jsondecode(fileread(C.goFile)),C,token);
end
