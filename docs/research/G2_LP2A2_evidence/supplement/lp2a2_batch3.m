% LP2-A2 batch 3 (zero FEM): supplementary diagnostics and memorandum figures
ex='<repo>';o=fullfile(ex,'outputs');ev=fullfile(ex,'docs','research','G2_LP2A2_evidence');
addpath(fullfile(ex,'matlab','g2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a2'),'-begin');addpath(fullfile(ex,'scripts','g2','lp2a2'),'-begin');
[~,c]=system(['git -C "',ex,'" rev-parse HEAD']);fprintf('SOURCE_COMMIT=%s\n',strtrim(c));
try
 t0=tic;S=g2_lp2a2_supplement(ex,fullfile(ev,'LP2A2_TEST_SET.json'),fullfile(ev,'attempt2','LP2A2_MESH_QUALIFICATION_ATTEMPT2.json'),fullfile(o,'LP2A2_SUPPLEMENT.json'));
 fprintf('SUPP_DONE %d rows %.1f s\n',numel(S.rows),toc(t0));
catch ME,fprintf(2,'SUPP_ERROR %s: %s\n',ME.identifier,ME.message);disp(ME.stack(1));end
try
 lp2a2_figures(ex,fullfile(ev,'LP2A2_TEST_SET.json'),fullfile(ev,'attempt2','LP2A2_MESH_QUALIFICATION_ATTEMPT2.json'),fullfile(o,'lp2a2_figures'));fprintf('FIG_DONE\n');
catch ME,fprintf(2,'FIG_ERROR %s: %s\n',ME.identifier,ME.message);disp(ME.stack(1));end
