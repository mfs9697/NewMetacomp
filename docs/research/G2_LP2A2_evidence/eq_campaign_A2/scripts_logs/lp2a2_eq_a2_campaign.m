% LP2-A2 equivalence campaign G2-LP2A2-EQ-001, activation A2 (authorization PR #71 issuecomment-7171931196).
% Exactly ONE call of the pinned corrected entry point g2_lp2a2_eq_external_run(approvedHead,tok,outDir);
% the entry point performs its own pre-wrapper checks and calls g2_lp2a2_eq_campaign(tok) at most once.
% No other solver, driver or wrapper call in this script; no retry.
ex='<repo>';
outDir='<scratch>';
addpath(fullfile(ex,'matlab','g2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a2'),'-begin');
approvedHead='a4561f88dfeda31752ae6c268d2d4d74e16b60a7';
TOK=['G2LP2A2EQ|policy=6f2c290b37d4f8291f428ec8b9e0a886fe6b31fc901bee5781f2518e67c94756|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947', ...
 '|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca|lp2a2source=f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd', ...
 '|archivedS8=da951c99c0d8c1d5dd731986d8f3b30e3db3f71854166a634d35b739757def8d|solves=EQ-H,EQ-stiff13,EQ-soft2,EQ-soft1|limit=4'];
fprintf('A2_ENTRY_CALL g2_lp2a2_eq_external_run start %s which=%s\n',datestr(now,'yyyy-mm-dd HH:MM:SS'),which('g2_lp2a2_eq_external_run'));
try
 W=g2_lp2a2_eq_external_run(approvedHead,TOK,outDir);
 fprintf('A2_ENTRY_RETURN outcome=%s solvesCalled=%g wrapperCalled=%d\n',W.outcome,W.solvesCalled,W.wrapperCalled);
catch ME
 fprintf(2,'A2_ENTRY_EXCEPTION %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
fprintf('A2_ENTRY_END %s\n',datestr(now,'yyyy-mm-dd HH:MM:SS'));
