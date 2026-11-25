% LP2-A3 readiness evidence v1 in the clean LF execution clone: contract suite, four S9 default-rung dry
% qualifications, unchanged LP2-A2 (v3) and LP2-A1 contract suites. Zero FEM; nothing written under the
% clone except git-ignored JSON results in outputs/.
ex='<repo>';o=fullfile(ex,'outputs');
addpath(fullfile(ex,'matlab','g2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a3'),'-begin');
H=g2_lp2a2_git('head',ex);fprintf('SOURCE_COMMIT=%s status=%d\n',H.value,H.status);
[~,s]=memory;fprintf('RAM_INSIDE_MATLAB=%.3f\n',s.PhysicalMemory.Available/2^30);
wj=@(f,S)writeJ(fullfile(o,f),S);
% 3 unchanged LP2-A2 contract suite (v3, 80 tests)
try,T2=g2_lp2a2_eq_tests();T2.sourceCommit=H.value;wj('LP2A3_UNCHANGED_LP2A2_EQ_TESTS.json',T2);fprintf('EVID_LP2A2_EQ %d/%d\n',T2.passed,T2.total);
catch ME,fprintf('EVID_LP2A2_ERROR %s: %s\n',ME.identifier,ME.message);end
fprintf('EVID_GO_FILE=%d RUN_ROOT=%d LEDGER=%d\n',isfile(fullfile(ex,'matlab','g2','lp2a3','G2_LP2A3_GO.json')),isfolder(fullfile(o,'g2_lp2a3_paths_v1')),isfolder(fullfile(o,'g2_lp2a3_campaign_ledger')));
function writeJ(f,S),fid=fopen(f,'w');fwrite(fid,jsonencode(S,'PrettyPrint',true),'char');fclose(fid);end
