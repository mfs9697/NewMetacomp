repo='<repo>';
addpath('<vg2-worktree>/scripts/g2/a0');
root=fullfile(repo,'outputs','g2_lp1_matrix_paths_v1','run_20261122_lp1_v1');
o='<scratch>/vg2/A0_COMPARATOR_SELFTEST_VG2.json';
if isfile(o),delete(o);end
R=a0_compare_records(root,root,o,'selftest');
for i=1:numel(R.perturbationTests),p=R.perturbationTests(i);fprintf('PERTURB %s expected=%s observed=%s pass=%d\n',p.perturbation,p.expectedTier,p.observedTier,p.pass);end
