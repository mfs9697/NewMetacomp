function g2_lp2a3_admit_hook(lroot,Camp,cid,caseId,k,pol)
%G2_LP2A3_ADMIT_HOOK  Admission of one LP2-A3 state (called by g2_lp1_admit_state before mkdir).
% Refuses a closed campaign, a state outside S9-S11, a thirteenth admission, a fourth admission of
% one case, a repeated key and an out-of-order key (S(k) only after an ADMIT of S(k-1), S9 first).
c=pol.caps;
assert(~strcmp(Camp.mode,'VERIFY_ONLY'),'G2LP1:HOLD_CAMPAIGN_CLOSED','Campaign is closed: no new state may be computed.');
assert(isnumeric(k)&&isscalar(k)&&k==round(k)&&k>=c.firstStateIndex&&k<=c.maxStateIndex,'G2LP2A3:HOLD_UNAUTHORIZED_STATE','Only S%d-S%d may be admitted.',c.firstStateIndex,c.maxStateIndex);
L=g2_lp1_campaign_ledger('snapshot',lroot);
assert(isequal(L.integrityOK,true),'G2LP1:HOLD_CAMPAIGN_INTEGRITY','Campaign ledger record failed verification.');
ad=cellstr(L.admits);
assert(numel(ad)<c.maxAdmissions,'G2LP2A3:HOLD_UNAUTHORIZED_STATE','The %d-admission ceiling is reached.',c.maxAdmissions);
mine=ad(startsWith(ad,[caseId '_S']));
assert(numel(mine)<c.statesPerCaseMax,'G2LP2A3:HOLD_UNAUTHORIZED_STATE','Case %s already has %d admissions.',caseId,c.statesPerCaseMax);
key=sprintf('%s_S%d',caseId,k);name=['ADMIT_' key '.mat'];
assert(~isfile(fullfile(lroot,name))&&~any(strcmp(ad,key)),'G2LP1:HOLD_CAMPAIGN_INTEGRITY','State %s was already admitted; review required.',key);
want=arrayfun(@(j)sprintf('%s_S%d',caseId,j),c.firstStateIndex:k-1,'UniformOutput',false);
assert(isequal(sort(mine(:)).',sort(want)),'G2LP1:HOLD_CAMPAIGN_INTEGRITY','State %s is out of order (admitted: %s).',key,strjoin(mine,','));
g2_lp1_campaign_ledger('write',lroot,'ADMIT',name,struct('campaignId',cid,'stateKey',key,'caseId',caseId,'stateIndex',k, ...
 'admittedUTC',char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss.SSS''Z'''))));
end
