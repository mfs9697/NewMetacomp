% A1 post-revocation probe (no FEM): the gate must refuse, nothing may be written.
repo='<repo>';cd(repo);addpath(fullfile(repo,'matlab','g2'),'-begin');
lst=@()[dir(fullfile(repo,'outputs','g2_a1_fixed_path_v1','**','*'));dir(fullfile(repo,'outputs','g2_a1_campaign_ledger','**','*'))];
n0=numel(lst());C=g2_a1_context();
fprintf('POSTREV commit=%s token=%s goFileExists=%d\n',C.preflight.sourceCommit,C.token,isfile(fullfile(C.here,'G2_A1_SCIENTIFIC_GO_v1.json')));
id='';
try
 g2_a1_run('Case','H','Level',9,'Run',true,'AuthToken',C.token,'RunName','run_a1_family_b_s4_v1');
catch ME
 id=ME.identifier;fprintf('POSTREV_REFUSED %s %s\n',ME.identifier,ME.message);
end
D=g2_a1_run('Case','H','Level',9);n1=numel(lst());
fprintf('POSTREV dry=%s filesBefore=%d filesAfter=%d\n',D.status,n0,n1);
ok=strcmp(id,'G2A1:HOLD_UNAUTHORIZED_STATE')&&n0==n1&&strcmp(D.status,'DRY_READY_NO_FEM');
fprintf('POSTREV_RESULT %d\n',ok);
% result figures from saved records only
addpath('<worktree>/scripts/report','-begin');
o='<scratch>/a1/figs2';
if isfolder(o),rmdir(o,'s');end
F=g2_a1_report_figures(fullfile(repo,'outputs','g2_a1_geometry_v1'),fullfile(repo,'outputs','g2_lp1_matrix_paths_v1','run_20261122_lp1_v1','H','S4','MESH.mat'),o, ...
 fullfile(repo,'outputs','g2_a1_campaign_log','A1_ANALYSIS.json'));
fprintf('FIGS_DONE\n');
exit(double(~ok));
