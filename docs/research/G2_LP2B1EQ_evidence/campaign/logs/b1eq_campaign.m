% LP2-B1-EQ campaign G2-LP2B1-EQ-001 (authorization PR #79 issuecomment-7211904299): exactly ONE call of the
% pinned entry point g2_lp2b1eq_external_run(approvedHead,tok,outDir). No other driver/campaign/solver call; no retry.
ex='<repo>';
outDir='<scratch>\lp2b1eqrun\campaign';
% path set identical to g2_lp2b1eq_context lines 13-14 (g2_lp2a2_git is needed by the parent check before the context)
restoredefaultpath;g2d=fullfile(ex,'matlab','g2');for f={'','lp2','lp2a2','lp2a3','lp2b1'},addpath(fullfile(g2d,f{1}));end
addpath(fullfile(ex,'scripts','g2','lp2a2','closure'));addpath(fullfile(g2d,'lp2b1eq'));
assert(~isempty(which('g2_lp2a2_git'))&&~isempty(which('g2_lp2a2_eq_memgate'))&&~isempty(which('g2_lp2b1eq_external_run')),'B1EQ:Path','Entry dependencies not on path; entry NOT called.');
approvedHead='7d0df53f35b30c4e33734c40fdda33e987ea96ee';
TOK=['G2LP2B1EQ|policy=b113a7c6d7b2e8fe9950d817ccca3c851c05f1e347c73f66c604b9c41e54eecb|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947', ...
 '|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca|lp2a2source=f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd', ...
 '|lp2a3source=fa3bcecfa9cd3044253d5a72253e2058bccd044d32345f51650dcd775f42e002|lp2b1source=9c7a1260e3bde5b59e1d93c47bc99cc4d7b89f9b0cc6e874572fb378f1717bee', ...
 '|lp2b1eqsource=74a0edd827daca5714a1347705abc1429a7a573116ad3c438f9e5a1c12dfbf1f|closure=76614f269810c6970544bca0c1c0f84ebf9131935554ebd75e57e24f819f65f7', ...
 '|references=63014a95ebeebd127ae094e9254331d6e32e314902b6c1d6ac2bf8abbeb3d89d|qualification=441b1eadf330a720255f2c6b178c0c51a822e4ad99a24d0318230c0884c5d5ad', ...
 '|solves=EQB-soft1-S9,EQB-H-S10|limit=2|seed=0.40|campaign=G2-LP2B1-EQ-001|run=run_lp2b1_eq_v1'];
fprintf('B1EQ_ENTRY_CALL g2_lp2b1eq_external_run start %s which=%s\n',datestr(now,'yyyy-mm-dd HH:MM:SS'),which('g2_lp2b1eq_external_run'));
try
 W=g2_lp2b1eq_external_run(approvedHead,TOK,outDir);
 fprintf('B1EQ_ENTRY_RETURN outcome=%s solvesCalled=%d\n',W.outcome,W.solvesCalled);
 if isstruct(W.verification)&&isfield(W.verification,'outcome'),fprintf('B1EQ_VERIFY outcome=%s\n',W.verification.outcome);end
catch ME
 fprintf(2,'B1EQ_ENTRY_EXCEPTION %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
fprintf('B1EQ_ENTRY_END %s\n',datestr(now,'yyyy-mm-dd HH:MM:SS'));
