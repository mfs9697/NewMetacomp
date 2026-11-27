% LP2-B1-S10 stage 2 (zero FEM): focused readiness suite (real geometry, real git), A0 under the real preflight
ex='<repo>';
[~,c]=system(['git -C "',ex,'" rev-parse HEAD']);fprintf('SOURCE_COMMIT=%s\n',strtrim(c));
[~,st]=system(['git -C "',ex,'" status --porcelain --untracked-files=all']);fprintf('SOURCE_STATUS=[%s]\n',strtrim(st));
restoredefaultpath;g2d=fullfile(ex,'matlab','g2');for f={'','lp2','lp2a2','lp2a3','lp2b1','lp2b1eq'},addpath(fullfile(g2d,f{1}));end
addpath(fullfile(ex,'scripts','g2','lp2a2','closure'));addpath(fullfile(g2d,'lp2b1s10'));
RR=fullfile(ex,'outputs','g2_lp2b1s10_readiness_v1');tag=getenv('B1S10_TESTS_TAG');if isempty(tag),tag='tests_v1';end
od=fullfile(RR,tag);
try
 assert(~isfolder(od),'S2:Exists','%s exists',tag);mkdir(od);
 T=g2_lp2b1s10_tests('OutFile',fullfile(od,'LP2B1S10_TESTS.json'));
 fprintf('S2_RESULT %d/%d failed=[%s]\n',T.passed,T.total,strjoin(T.failedTests,','));
catch ME
 fprintf(2,'S2_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
