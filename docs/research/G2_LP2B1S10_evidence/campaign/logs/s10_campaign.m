% LP2-B1-S10 campaign G2-LP2B1-S10-001 (authorization PR #82 issuecomment-7237508619): exactly ONE call of the
% pinned entry point g2_lp2b1s10_external_run(approvedHead,tok,outDir). No other driver/solver call; no retry.
ex='<repo>';
outDir='<scratch>\lp2b1s10run\campaign';
% path set identical to g2_lp2b1s10_context (g2_lp2a2_git is needed by the parent check before the context loads)
restoredefaultpath;g2d=fullfile(ex,'matlab','g2');for f={'','lp2','lp2a2','lp2a3','lp2b1','lp2b1eq'},addpath(fullfile(g2d,f{1}));end
addpath(fullfile(ex,'scripts','g2','lp2a2','closure'));addpath(fullfile(g2d,'lp2b1s10'));
assert(~isempty(which('g2_lp2a2_git'))&&~isempty(which('g2_lp2a2_eq_memgate'))&&~isempty(which('g2_lp2b1s10_external_run')),'S10:Path','Entry dependencies not on path; entry NOT called.');
approvedHead='0fcee176a5e294b7c8d7f33711ad7d3897be6538';
TOK=['G2LP2B1S10|policy=f57433eccc5641ba253da52b723a0de6b1ad299793aa227235d309e57f120171|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947', ...
 '|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca|lp2a2source=f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd', ...
 '|lp2a3source=fa3bcecfa9cd3044253d5a72253e2058bccd044d32345f51650dcd775f42e002|lp2b1source=9c7a1260e3bde5b59e1d93c47bc99cc4d7b89f9b0cc6e874572fb378f1717bee', ...
 '|lp2b1eqsource=74a0edd827daca5714a1347705abc1429a7a573116ad3c438f9e5a1c12dfbf1f|closure=76614f269810c6970544bca0c1c0f84ebf9131935554ebd75e57e24f819f65f7', ...
 '|lp2b1s10source=d544fcfde1cfaa1e7118e0c5959551bdddb1cd477739bcf55376c45fe8388ab9|parent=9f3c173fadd370ae3e455b3aef3d5aa4d1f3035faf6100d717d4175ae33f194b', ...
 '|qualification=773f42aef75b13542efc6a169c9f526f6e64597a8d359df0ab067abf6cf161df|eqcampaign=91ff13fa86617f8236b09c439f7048f4542520e79c31003c01f07957e5cf17b9', ...
 '|case=soft1|state=S10|admissions=1|seed=0.40|campaign=G2-LP2B1-S10-001|run=run_lp2b1_s10_v1'];
fprintf('S10_ENTRY_CALL g2_lp2b1s10_external_run start %s which=%s\n',datestr(now,'yyyy-mm-dd HH:MM:SS'),which('g2_lp2b1s10_external_run'));
try
 W=g2_lp2b1s10_external_run(approvedHead,TOK,outDir);
 fprintf('S10_ENTRY_RETURN outcome=%s admissions=%d solveCalls=%d\n',W.outcome,W.admissions,W.solveCalls);
 if isstruct(W.verification)&&isfield(W.verification,'outcome'),fprintf('S10_VERIFY outcome=%s\n',W.verification.outcome);end
catch ME
 fprintf(2,'S10_ENTRY_EXCEPTION %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
fprintf('S10_ENTRY_END %s\n',datestr(now,'yyyy-mm-dd HH:MM:SS'));
