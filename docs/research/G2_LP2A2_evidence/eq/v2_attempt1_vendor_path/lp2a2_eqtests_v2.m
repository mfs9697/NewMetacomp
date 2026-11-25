% LP2-A2 SIF-equivalence package: full zero-FEM contract suite v2 (E1-E11) in the execution clone
ex='<repo>';o=fullfile(ex,'outputs');
addpath(fullfile(ex,'matlab','g2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a2'),'-begin');
[~,c]=system(['git -C "',ex,'" rev-parse HEAD']);fprintf('SOURCE_COMMIT=%s\n',strtrim(c));
T=g2_lp2a2_eq_tests();T.sourceCommit=strtrim(c);T.version='v2';
fid=fopen(fullfile(o,'LP2A2_EQ_TESTS_v2.json'),'w');fwrite(fid,jsonencode(T,'PrettyPrint',true),'char');fclose(fid);
fprintf('EQ_OUTPUT_ROOT_EXISTS=%d GO_FILE_EXISTS=%d\n',exist(fullfile(o,'g2_lp2a2_eq_v1'),'dir'),isfile(fullfile(ex,'matlab','g2','lp2a2','G2_LP2A2_EQ_GO.json')));
