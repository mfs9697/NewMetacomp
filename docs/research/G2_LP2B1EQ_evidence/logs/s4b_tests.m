% LP2-B1-EQ stage 4 (zero FEM): readiness test suite; output name passed in TESTNAME (never overwritten)
ex='<repo>';
[~,c]=system(['git -C "',ex,'" rev-parse HEAD']);fprintf('SOURCE_COMMIT=%s\n',strtrim(c));
[~,st]=system(['git -C "',ex,'" status --porcelain --untracked-files=all']);fprintf('SOURCE_STATUS=[%s]\n',strtrim(st));
restoredefaultpath;addpath(fullfile(ex,'matlab','g2'));addpath(fullfile(ex,'matlab','g2','lp2b1eq'));addpath(fullfile(ex,'scripts','g2','lp2b1eq'));
RR=fullfile(ex,'outputs','g2_lp2b1eq_readiness_v1');tn=getenv('LP2B1EQ_TESTNAME');tn='tests_v2';
od=fullfile(RR,tn);
try
 assert(~isfolder(od),'S4:Exists','%s exists',tn);mkdir(od);
 T=g2_lp2b1eq_tests('OutFile',fullfile(od,'LP2B1EQ_TESTS.json'));
 fprintf('TESTS_RESULT %d/%d failed=[%s]\n',T.passed,T.total,strjoin(T.failedTests,','));
catch ME
 fprintf(2,'S4_ERROR %s: %s\n',ME.identifier,ME.message);for k=1:numel(ME.stack),fprintf(2,'  %s:%d\n',ME.stack(k).name,ME.stack(k).line);end
end
fprintf('MATLAB_PROCESSES_END=%d\n',numel(regexp(evalc('system(''tasklist /FI "IMAGENAME eq MATLAB.exe" /NH'');'),'MATLAB.exe')));
