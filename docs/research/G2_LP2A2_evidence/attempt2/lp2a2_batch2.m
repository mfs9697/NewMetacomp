% LP2-A2 batch 2 (zero FEM): EQ package tests, spacing exploration, attempt-2 qualification (ladder)
ex='<repo>';o=fullfile(ex,'outputs');
addpath(fullfile(ex,'matlab','g2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a2'),'-begin');
[~,c]=system(['git -C "',ex,'" rev-parse HEAD']);fprintf('SOURCE_COMMIT=%s\n',strtrim(c));
try
 T=g2_lp2a2_eq_tests();fid=fopen(fullfile(o,'LP2A2_EQ_TESTS.json'),'w');fwrite(fid,jsonencode(T,'PrettyPrint',true),'char');fclose(fid);
catch ME,fprintf(2,'EQ_TESTS_ERROR %s: %s\n',ME.identifier,ME.message);disp(ME.stack(1));end
try
 t0=tic;X=g2_lp2a2_explore_spacing(ex,[0.45 0.40 0.50 0.35],fullfile(o,'LP2A2_SPACING_EXPLORATION.json'));fprintf('EXPLORE_DONE %d rows %.1f s\n',numel(X.rows),toc(t0));
catch ME,fprintf(2,'EXPLORE_ERROR %s\n',ME.message);end
try
 ts=fullfile(ex,'docs','research','G2_LP2A2_evidence','LP2A2_TEST_SET.json');fprintf('TESTSET_SHA256=%s\n',lower(g2_sha256_file(ts)));
 t0=tic;Q=g2_lp2a2_qualify_mesh(ex,ts,fullfile(o,'LP2A2_MESH_QUALIFICATION_ATTEMPT2.json'),[],'ladder');fprintf('LP2A2_QUAL2_DONE rows=%d seconds=%.1f\n',numel(Q.rows),toc(t0));
catch ME,fprintf(2,'QUAL2_ERROR %s\n',ME.message);end
