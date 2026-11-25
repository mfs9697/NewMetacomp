% LP2-A2 geometry-only mesh qualification on the predeclared test set (zero FEM, meshes in memory)
ex='<repo>';
addpath(fullfile(ex,'matlab','g2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a2'),'-begin');
[~,c]=system(['git -C "',ex,'" rev-parse HEAD']);fprintf('SOURCE_COMMIT=%s\n',strtrim(c));
ts=fullfile(ex,'docs','research','G2_LP2A2_evidence','LP2A2_TEST_SET.json');
fprintf('TESTSET_SHA256=%s\n',lower(g2_sha256_file(ts)));
t0=tic;
Q=g2_lp2a2_qualify_mesh(ex,ts,fullfile(ex,'outputs','LP2A2_MESH_QUALIFICATION.json'));
fprintf('LP2A2_QUAL_DONE rows=%d seconds=%.1f\n',numel(Q.rows),toc(t0));
