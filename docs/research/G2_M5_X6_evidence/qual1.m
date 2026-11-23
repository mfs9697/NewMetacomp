% M5-X6 qualification in the clean execution clone (no FEM)
ex='<repo>';
addpath(fullfile(ex,'scripts','g2','m5','x6'));
out='<scratch>\m5x6\Q_2a5127e';
try
 R=m5x6_qualify(out);
catch ME
 fprintf(2,'QUALIFY_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
