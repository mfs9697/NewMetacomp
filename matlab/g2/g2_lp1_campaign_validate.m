function D=g2_lp1_campaign_validate(G,runName,goSHA,token,L,F,Rs)
%G2_LP1_CAMPAIGN_VALIDATE Pure campaign-scope decision for one authorized LP1 campaign (VG2, Issue #62).
% Opens no file and writes nothing. Called by g2_lp1_run after the scientific gate and
% token check and BEFORE any run-root folder, ledger entry, mesh, state or solve.
%   G      validated GO (fields approvedRunName, campaignId, campaignScope)
%   runName  RunName of this controller call
%   goSHA  SHA-256 of the GO file bytes actually read by the gate
%   token  context token of this call
%   L      ledger snapshot (g2_lp1_campaign_ledger('snapshot',...)):
%          integrityOK, receipt ([] or struct), admits (cellstr 'case_Sk'),
%          holds (struct array: file, sha256, caseId, stateIndex), resumes (cellstr hold SHA),
%          closed (logical)
%   F      run-folder facts: exists, hasRunRecord, runTokenMatches
%   Rs     [] or struct('record',decoded resume JSON,'sha256',file SHA) from the
%          hard-coded matlab/g2/G2_LP1_CAMPAIGN_RESUME_v1.json
% Returns D.mode = 'OPEN_NEW' | 'CONTINUE' | 'VERIFY_ONLY' and D.consumeResume
% (SHA of the reviewed hold, or ''). At most ONE reviewed resumption per campaign.
D=struct('mode','','consumeResume','','campaignId',G.campaignId,'runName',runName);
maxResumptions=1;
% (1) the call must use the approved campaign run
assert(ischar(runName)&&strcmp(runName,G.approvedRunName),'G2LP1:HOLD_CAMPAIGN_SCOPE', ...
 'RunName is not the run approved by the scientific GO.');
% (2) every ledger record must verify
assert(isstruct(L)&&isfield(L,'integrityOK')&&isequal(L.integrityOK,true),'G2LP1:HOLD_CAMPAIGN_INTEGRITY', ...
 'Campaign ledger record failed verification.');
if isempty(L.receipt)
 % (3) no receipt: only a clean, never-started campaign may open
 assert(~F.exists,'G2LP1:HOLD_CAMPAIGN_INTEGRITY','Run folder exists without a campaign receipt.');
 assert(isempty(L.admits)&&isempty(L.holds)&&isempty(L.resumes)&&~L.closed,'G2LP1:HOLD_CAMPAIGN_INTEGRITY', ...
  'Ledger entries exist without a campaign receipt.');
 D.mode='OPEN_NEW';return
end
% (4) the receipt must bind exactly this GO, campaign, run and token
r=L.receipt;
assert(isstruct(r)&&all(isfield(r,{'campaignId','runName','goSHA256','token'}))&& ...
 strcmp(r.campaignId,G.campaignId)&&strcmp(r.runName,runName)&&strcmpi(r.goSHA256,goSHA)&&strcmp(r.token,token), ...
 'G2LP1:HOLD_CAMPAIGN_INTEGRITY','Campaign receipt does not bind this GO, campaign, run and token.');
% (5) run folder consistency
if ~F.exists
 assert(isempty(L.admits),'G2LP1:HOLD_CAMPAIGN_INTEGRITY','Admitted states are missing from the run folder.');
else
 assert(~F.hasRunRecord||F.runTokenMatches,'G2LP1:HOLD_CAMPAIGN_INTEGRITY','Run record token differs from the campaign token.');
end
% (6) a closed campaign permits only zero-solve verification
if L.closed,D.mode='VERIFY_ONLY';return,end
% (7) pre-admission memory HOLDs require a reviewed, bound resumption (at most one)
open=setdiff(cellfun(@lower,{L.holds.sha256},'UniformOutput',false),cellfun(@lower,L.resumes,'UniformOutput',false));
if ~isempty(open)
 assert(isscalar(open),'G2LP1:HOLD_CAMPAIGN_REVIEW_REQUIRED','More than one unreviewed pre-admission HOLD.');
 assert(~isempty(Rs),'G2LP1:HOLD_CAMPAIGN_REVIEW_REQUIRED','Unreviewed pre-admission memory HOLD; scientist review required.');
 assert(numel(L.resumes)<maxResumptions,'G2LP1:HOLD_CAMPAIGN_REVIEW_REQUIRED','Reviewed resumption allowance exhausted.');
 x=Rs.record;
 assert(isstruct(x)&&all(isfield(x,{'decision','campaignId','holdRecordSHA256','scientificReviewer','reviewURL'}))&& ...
  ischar(x.decision)&&strcmp(x.decision,'RESUME_AFTER_PREADMISSION_MEMORY_HOLD')&& ...
  ischar(x.campaignId)&&strcmp(x.campaignId,G.campaignId)&& ...
  ischar(x.holdRecordSHA256)&&strcmpi(x.holdRecordSHA256,open{1})&& ...
  ischar(x.scientificReviewer)&&~isempty(strtrim(x.scientificReviewer))&& ...
  ischar(x.reviewURL)&&startsWith(x.reviewURL,'https://github.com/mfs9697/NewMetacomp/'), ...
  'G2LP1:HOLD_CAMPAIGN_REVIEW_REQUIRED','Resume record does not bind this campaign and HOLD.');
 D.consumeResume=lower(open{1});
end
D.mode='CONTINUE';
end
