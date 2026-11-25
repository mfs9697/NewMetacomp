% LP2-A2 predeclared test set, built in the execution clone at the committed sources (no mesh, no FEM)
ex='<repo>';
addpath(fullfile(ex,'matlab','g2','lp2a2'),'-begin');
[~,c]=system(['git -C "',ex,'" rev-parse HEAD']);fprintf('SOURCE_COMMIT=%s\n',strtrim(c));
out=fullfile(ex,'docs','research','G2_LP2A2_evidence','LP2A2_TEST_SET.json');if ~exist(fileparts(out),'dir'),mkdir(fileparts(out));end
T=g2_lp2a2_testset(ex,out);disp(T.counts)
for i=1:numel(T.rows),r=T.rows{i};fprintf('TESTSET %-28s %-3s %-22s N=%-2d arc=%.1f guard=%d\n',r.id,r.group,r.label,r.vertices,r.arc_mm,r.guardRow);end
fprintf('TESTSET_SHA256=%s\n',lower(g2_sha256_file(out)));
