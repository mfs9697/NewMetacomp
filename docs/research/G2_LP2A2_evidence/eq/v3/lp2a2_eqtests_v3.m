% LP2-A2 SIF-equivalence package: zero-FEM contract suite v3 (E1-E11 + E12 real git) in the execution clone
ex='<repo>';o=fullfile(ex,'outputs');
addpath(fullfile(ex,'matlab','g2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a2'),'-begin');
H=g2_lp2a2_git('head',ex);fprintf('SOURCE_COMMIT=%s status=%d\n',H.value,H.status);
T=g2_lp2a2_eq_tests();T.sourceCommit=H.value;T.version='v3';
fid=fopen(fullfile(o,'LP2A2_EQ_TESTS_v3.json'),'w');fwrite(fid,jsonencode(T,'PrettyPrint',true),'char');fclose(fid);
fprintf('EQ_OUTPUT_ROOT_EXISTS=%d GO_FILE_EXISTS=%d\n',exist(fullfile(o,'g2_lp2a2_eq_v1'),'dir'),isfile(fullfile(ex,'matlab','g2','lp2a2','G2_LP2A2_EQ_GO.json')));
