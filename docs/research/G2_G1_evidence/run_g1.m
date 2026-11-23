% G1 read-only field post-processing (no boundary-value problem)
ex='<repo>';
wt='<worktree>';
addpath(fullfile(wt,'scripts','g2','m5','g1'));
out='<scratch>\g1\out1';
t0=tic;
try
 R=g1_field_analysis(ex,out);
catch ME
 fprintf(2,'G1_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
fprintf('G1_ELAPSED %.1f s\n',toc(t0));
