% LP2-A3 campaign G2-LP2A3-001 (authorization PR #75 issuecomment-7175877170): exactly ONE call of the
% pinned entry point g2_lp2a3_external_run(approvedHead,tok,outDir). No other driver/solver call; no retry.
ex='<repo>';
outDir='<scratch>';
addpath(fullfile(ex,'matlab','g2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a3'),'-begin');
approvedHead='2348ba11b9ebe1e33a723b11055a3603b846383e';
TOK=['G2LP2A3|policy=7a6e17f8baa85c6e6f10186bfab3a9c10c9363e0acb5e532c00095961bf45d43|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947', ...
 '|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca|lp2a2source=f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd', ...
 '|lp2a3source=fa3bcecfa9cd3044253d5a72253e2058bccd044d32345f51650dcd775f42e002|parentsS8=da951c99c0d8c1d5dd731986d8f3b30e3db3f71854166a634d35b739757def8d', ...
 '|qualification=a77f49200f9f95b36260f44306afd4b05690d8ec9353c4fa71f4b5adbe5d4ded|cases=H,stiff13,soft2,soft1|states=S9-S11|maxAdmissions=12|seed=0.45|campaign=G2-LP2A3-001|run=run_lp2a3_s9_s11_v1'];
fprintf('A3_ENTRY_CALL g2_lp2a3_external_run start %s which=%s\n',datestr(now,'yyyy-mm-dd HH:MM:SS'),which('g2_lp2a3_external_run'));
try
 W=g2_lp2a3_external_run(approvedHead,TOK,outDir);
 fprintf('A3_ENTRY_RETURN outcome=%s caseCalls=%d\n',W.outcome,W.caseCalls);
catch ME
 fprintf(2,'A3_ENTRY_EXCEPTION %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
fprintf('A3_ENTRY_END %s\n',datestr(now,'yyyy-mm-dd HH:MM:SS'));
