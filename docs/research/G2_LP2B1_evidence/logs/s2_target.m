% LP2-B1 stage 2 (zero FEM): preregistered candidate spacings on the fixed soft1 S10 target
ex='<repo>';
[~,c]=system(['git -C "',ex,'" rev-parse HEAD']);fprintf('SOURCE_COMMIT=%s\n',strtrim(c));
[~,st]=system(['git -C "',ex,'" status --short -- matlab scripts']);fprintf('SOURCE_STATUS=[%s]\n',strtrim(st));
addpath(fullfile(ex,'matlab','g2','lp2b1'));
try
 O=g2_lp2b1_wp1('target',fullfile(ex,'outputs','g2_lp2b1_geometry_v1','wp1'));
 for i=1:numel(O.attempts),disp(O.attempts{i});end
 fprintf('WP1_TARGET_OUTCOME=%s\n',O.outcome);
catch ME
 fprintf(2,'WP1_ERROR %s: %s\n',ME.identifier,ME.message);for k=1:numel(ME.stack),fprintf(2,'  %s:%d\n',ME.stack(k).name,ME.stack(k).line);end
end
fprintf('MATLAB_PROCESSES_END=%d\n',numel(regexp(evalc('system(''tasklist /FI "IMAGENAME eq MATLAB.exe" /NH'');'),'MATLAB.exe')));
