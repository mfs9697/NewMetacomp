% LP2-B1 stage 1 (zero FEM, no mesh generation): read-only reconstruction of the soft1 S10 failure
ex='<repo>';
[~,c]=system(['git -C "',ex,'" rev-parse HEAD']);fprintf('SOURCE_COMMIT=%s\n',strtrim(c));
[~,st]=system(['git -C "',ex,'" status --short -- matlab scripts']);fprintf('SOURCE_STATUS=[%s]\n',strtrim(st));
addpath(fullfile(ex,'matlab','g2','lp2b1'));
try
 W=g2_lp2b1_wp0(fullfile(ex,'outputs','g2_lp2b1_geometry_v1','wp0_attempt1'));
 disp(W.checks);
 fprintf('WP0_PASS=%d\n',W.pass);
catch ME
 fprintf(2,'WP0_ERROR %s: %s\n',ME.identifier,ME.message);for k=1:numel(ME.stack),fprintf(2,'  %s:%d\n',ME.stack(k).name,ME.stack(k).line);end
end
fprintf('MATLAB_PROCESSES_END=%d\n',numel(regexp(evalc('system(''tasklist /FI "IMAGENAME eq MATLAB.exe" /NH'');'),'MATLAB.exe')));
