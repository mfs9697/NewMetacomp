ex='<repo>';addpath(fullfile(ex,'matlab','g2','lp2'));
out=['<scratch>' datestr(now,'HHMMSS')];
try,R=g2_lp2_qualify(out);catch ME,fprintf(2,'LP2Q_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));end
