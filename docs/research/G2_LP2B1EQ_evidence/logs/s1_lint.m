% LP2-B1-EQ stage 1 (zero FEM, no data access): static code analysis of the new sources only
ex='<repo>';
[~,c]=system(['git -C "',ex,'" rev-parse HEAD']);fprintf('SOURCE_COMMIT=%s\n',strtrim(c));
fs=[dir(fullfile(ex,'matlab','g2','lp2b1eq','*.m'));dir(fullfile(ex,'scripts','g2','lp2b1eq','*.m'))];
for k=1:numel(fs)
 f=fullfile(fs(k).folder,fs(k).name);m=checkcode(f,'-id');
 fprintf('LINT %s %d\n',fs(k).name,numel(m));
 for i=1:numel(m),fprintf('  L%d %s: %s\n',m(i).line,m(i).id,m(i).message);end
end
fprintf('MATLAB_PROCESSES_END=%d\n',numel(regexp(evalc('system(''tasklist /FI "IMAGENAME eq MATLAB.exe" /NH'');'),'MATLAB.exe')));
