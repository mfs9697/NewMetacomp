addpath('<a0-worktree>/scripts/g2/a0');
root='<repo>/outputs/g2_lp1_matrix_paths_v1/run_20261122_lp1_v1';
o='<scratch>/a0/A0_COMPARATOR_SELFTEST.json';
if isfile(o),delete(o);end
R=a0_compare_records(root,root,o,'selftest');
for i=1:numel(R.perturbationTests),p=R.perturbationTests(i);fprintf('PERTURB %s expected=%s observed=%s pass=%d\n',p.perturbation,p.expectedTier,p.observedTier,p.pass);end
disp(R.classesHistorical.soft2);disp(R.classesHistorical.numbers.soft2);
