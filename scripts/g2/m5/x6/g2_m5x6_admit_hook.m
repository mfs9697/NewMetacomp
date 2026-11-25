function g2_m5x6_admit_hook(lroot,Camp,cid,key)
%G2_M5X6_ADMIT_HOOK  Admission entry of one M5-X6 state (called by g2_lp1_admit_state before mkdir).
% Refuses a closed campaign, a seventh admission and a second admission of the same key.
assert(~strcmp(Camp.mode,'VERIFY_ONLY'),'G2LP1:HOLD_CAMPAIGN_CLOSED','Campaign is closed: no new state may be computed.');
L=g2_lp1_campaign_ledger('snapshot',lroot);
assert(isequal(L.integrityOK,true),'G2LP1:HOLD_CAMPAIGN_INTEGRITY','Campaign ledger record failed verification.');
assert(numel(L.admits)<6,'G2M5X6:HOLD_UNAUTHORIZED_STATE','The six-solve ceiling is reached.');
name=sprintf('ADMIT_%s.mat',key);
assert(~isfile(fullfile(lroot,name))&&~any(strcmp(L.admits,key)),'G2LP1:HOLD_CAMPAIGN_INTEGRITY', ...
 'State %s was already admitted; review required.',key);
g2_lp1_campaign_ledger('write',lroot,'ADMIT',name,struct('campaignId',cid,'stateKey',key, ...
 'admittedUTC',char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss.SSS''Z'''))));
end
