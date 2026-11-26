% LP2-B1 stage 3 (zero FEM): attempt 2 of the preregistered candidates on the fixed soft1 S10 target (amendment A1)
ex='<repo>';
[~,c]=system(['git -C "',ex,'" rev-parse HEAD']);fprintf('SOURCE_COMMIT=%s\n',strtrim(c));
[~,st]=system(['git -C "',ex,'" status --short -- matlab scripts']);fprintf('SOURCE_STATUS=[%s]\n',strtrim(st));
lp=fullfile(ex,'matlab','g2','lp2b1');addpath(lp);
% static check of the LP2-B1 sources BEFORE any mesh (errors stop the stage)
fl=dir(fullfile(lp,'*.m'));nerr=0;
for i=1:numel(fl)
 m=checkcode(fullfile(lp,fl(i).name),'-id');
 for j=1:numel(m),fprintf('CHECKCODE %s:%d %s %s\n',fl(i).name,m(j).line,m(j).id,m(j).message);end
end
T=cellfun(@(f)mtree(fileread(fullfile(lp,f))),{fl.name},'UniformOutput',false);
for i=1:numel(T),if count(mtfind(T{i},'Kind','ERR'))>0,fprintf(2,'PARSE_ERROR %s\n',fl(i).name);nerr=nerr+1;end,end
fprintf('PARSE_ERRORS=%d\n',nerr);
if nerr==0
 try
  O=g2_lp2b1_wp1('target',fullfile(ex,'outputs','g2_lp2b1_geometry_v1','wp1_attempt2'));
  for i=1:numel(O.attempts),disp(O.attempts{i});end
  fprintf('WP1_TARGET_OUTCOME=%s\n',O.outcome);
 catch ME
  fprintf(2,'WP1_ERROR %s: %s\n',ME.identifier,ME.message);for k=1:numel(ME.stack),fprintf(2,'  %s:%d\n',ME.stack(k).name,ME.stack(k).line);end
 end
end
fprintf('MATLAB_PROCESSES_END=%d\n',numel(regexp(evalc('system(''tasklist /FI "IMAGENAME eq MATLAB.exe" /NH'');'),'MATLAB.exe')));
