repo='<repo>';
addpath('<worktree>/scripts/report','-begin');
o='<scratch>/a1/figs3';
if isfolder(o),rmdir(o,'s');end
F=g2_a1_report_figures(fullfile(repo,'outputs','g2_a1_geometry_v1'),fullfile(repo,'outputs','g2_lp1_matrix_paths_v1','run_20261122_lp1_v1','H','S4','MESH.mat'),o, ...
 fullfile(repo,'outputs','g2_a1_campaign_log','A1_ANALYSIS.json'));
fprintf('FIGS_DONE\n');
