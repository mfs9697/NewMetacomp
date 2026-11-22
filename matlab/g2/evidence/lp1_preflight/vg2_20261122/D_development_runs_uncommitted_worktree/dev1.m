addpath(fullfile('<repo>','matlab','g2'),'-begin');
T=check_g2_lp1_contract(false);
bad=T.tests(~[T.tests.pass]);
for i=1:numel(bad),fprintf('FAILED %s expected=%s observed=%s\n',bad(i).name,bad(i).expected,bad(i).observed);end
fprintf('DEV pass=%d %d/%d\n',T.pass,T.passed,T.total);
