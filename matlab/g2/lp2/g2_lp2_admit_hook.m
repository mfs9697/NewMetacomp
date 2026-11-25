function g2_lp2_admit_hook(lroot,Camp,cid,caseId,k)
%G2_LP2_ADMIT_HOOK  Admission of one LP2-A state (called by g2_lp1_admit_state before mkdir).
% Refuses a closed campaign, a seventeenth admission, a state outside S5-S8 and a repeated key.
assert(~strcmp(Camp.mode,'VERIFY_ONLY'),'G2LP1:HOLD_CAMPAIGN_CLOSED','Campaign is closed: no new state may be computed.');
assert(k>=5&&k<=8,'G2LP2:HOLD_UNAUTHORIZED_STATE','Only S5-S8 may be admitted.');
L=g2_lp1_campaign_ledger('snapshot',lroot);
assert(isequal(L.integrityOK,true),'G2LP1:HOLD_CAMPAIGN_INTEGRITY','Campaign ledger record failed verification.');
assert(numel(L.admits)<16,'G2LP2:HOLD_UNAUTHORIZED_STATE','The sixteen-solve ceiling is reached.');
key=sprintf('%s_S%d',caseId,k);name=['ADMIT_' key '.mat'];
assert(~isfile(fullfile(lroot,name))&&~any(strcmp(L.admits,key)),'G2LP1:HOLD_CAMPAIGN_INTEGRITY','State %s was already admitted; review required.',key);
g2_lp1_campaign_ledger('write',lroot,'ADMIT',name,struct('campaignId',cid,'stateKey',key,'caseId',caseId,'stateIndex',k, ...
 'admittedUTC',char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss.SSS''Z'''))));
end
