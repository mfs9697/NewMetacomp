% LP2-B1 stage 6 (zero FEM, no mesh generation): summary-difference check and corrected figures (v2)
ex='<repo>';
[~,c]=system(['git -C "',ex,'" rev-parse HEAD']);fprintf('SOURCE_COMMIT=%s\n',strtrim(c));
addpath(fullfile(ex,'scripts','g2','lp2b1'));
try,lp2b1_summary_diff(ex,fullfile(ex,'outputs','g2_lp2b1_geometry_v1','postaudit_v1_summary_diff'));catch ME,fprintf(2,'SD_ERROR %s: %s\n',ME.identifier,ME.message);end
try,lp2b1_figures(ex,fullfile(ex,'outputs','g2_lp2b1_geometry_v1','figures_v2'));catch ME,fprintf(2,'FIG_ERROR %s: %s\n',ME.identifier,ME.message);for k=1:numel(ME.stack),fprintf(2,'  %s:%d\n',ME.stack(k).name,ME.stack(k).line);end,end
fprintf('MATLAB_PROCESSES_END=%d\n',numel(regexp(evalc('system(''tasklist /FI "IMAGENAME eq MATLAB.exe" /NH'');'),'MATLAB.exe')));
