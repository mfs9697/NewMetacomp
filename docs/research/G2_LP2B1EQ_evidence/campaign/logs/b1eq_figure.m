% LP2-B1-EQ Ukrainian figure (no FEM; reads the independent audit JSON only)
addpath('<worktree>\scripts\g2\lp2b1eq');
try
 lp2b1eq_campaign_figures('<scratch>\lp2b1eqrun\verify\LP2B1EQ_AUDIT_v3.json', ...
  '<scratch>\lp2b1eqrun\figures');
 fprintf('FIG_DONE\n');
catch ME
 fprintf(2,'FIG_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
