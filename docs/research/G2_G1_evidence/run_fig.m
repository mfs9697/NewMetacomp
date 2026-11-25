wt='<worktree>';addpath(fullfile(wt,'scripts','g2','m5','g1'));
d='<scratch>\g1\out1';
o='<scratch>\g1\fig1';
try, g1_figures(d,o); disp('G1_FIG_DONE'); catch ME, fprintf(2,'G1_FIG_ERROR %s: %s\n',ME.identifier,ME.message); disp(getReport(ME)); end
