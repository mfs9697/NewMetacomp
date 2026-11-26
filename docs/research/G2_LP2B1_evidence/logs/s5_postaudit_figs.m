% LP2-B1 stage 5 (zero FEM, no mesh generation): read-only post-audit of saved attempts, then figures
ex='<repo>';
[~,c]=system(['git -C "',ex,'" rev-parse HEAD']);fprintf('SOURCE_COMMIT=%s\n',strtrim(c));
[~,st]=system(['git -C "',ex,'" status --short -- matlab scripts']);fprintf('SOURCE_STATUS=[%s]\n',strtrim(st));
addpath(fullfile(ex,'scripts','g2','lp2b1'));
try
 A=lp2b1_postaudit(ex,fullfile(ex,'outputs','g2_lp2b1_geometry_v1','postaudit_v1'));
catch ME
 fprintf(2,'POSTAUDIT_ERROR %s: %s\n',ME.identifier,ME.message);for k=1:numel(ME.stack),fprintf(2,'  %s:%d\n',ME.stack(k).name,ME.stack(k).line);end
end
try
 lp2b1_figures(ex,fullfile(ex,'outputs','g2_lp2b1_geometry_v1','figures_v1'));
catch ME
 fprintf(2,'FIG_ERROR %s: %s\n',ME.identifier,ME.message);for k=1:numel(ME.stack),fprintf(2,'  %s:%d\n',ME.stack(k).name,ME.stack(k).line);end
end
fprintf('MATLAB_PROCESSES_END=%d\n',numel(regexp(evalc('system(''tasklist /FI "IMAGENAME eq MATLAB.exe" /NH'');'),'MATLAB.exe')));
