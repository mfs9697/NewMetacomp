% LP2-B1-EQ stage 5 (zero FEM, no mesh generation, read-only inputs): diagnosis of the protectedTopology/tip
% sub-check of the replay. Every conjunct of the tip check is evaluated separately for both references, on the
% replay attempt arrays (= solve-mesh arrays by canonical digest) and on the archived 0.45 mm MESH.
ex='<repo>';
[~,c]=system(['git -C "',ex,'" rev-parse HEAD']);fprintf('SOURCE_COMMIT=%s\n',strtrim(c));
restoredefaultpath;addpath(fullfile(ex,'matlab','g2'));addpath(fullfile(ex,'matlab','g2','lp2b1eq'));
RR=fullfile(ex,'outputs','g2_lp2b1eq_readiness_v1');od=fullfile(RR,'diag_tip_v1');
try
 assert(~isfolder(od),'S5:Exists','exists');mkdir(od);
 C=g2_lp2b1eq_context('Preflight',false);E={};
 for k=1:2
  s=C.solves{k};Do=load(fullfile(ex,strrep(s.archived.MESH.path,'/',filesep)));
  Dn=load(fullfile(RR,'replay_v1',s.id,'GEOMETRY_h040','ATTEMPT_ARRAYS.mat'));
  for side={'old','new'}
   if strcmp(side{1},'old'),D=Do;else,D=Dn;end
   blk=unique(double(D.T6(1:2916,:)));U=intersect(blk,double(D.upperBankT6(:)));L=intersect(blk,double(D.lowerBankT6(:)));sh=intersect(U,L);
   tip=double(D.physicalTipNode);P=D.crackPolyline(end,:);x=D.X6(tip,:);
   e=struct('solveId',s.id,'mesh',side{1},'physicalTipNode',tip,'sharedBlockIds',sh(:).','sharedIsScalar',isscalar(sh),'sharedEqualsTip',isequal(sh,tip), ...
    'tipXY',x,'polylineTip',P,'tipMinusPolyline',x-P,'tipCoordinateBitwise',isequal(x,P),'distance_mm',norm(x-P),'X3tip',D.X3(min(tip,size(D.X3,1)),:), ...
    'tipInUpper',ismember(tip,D.upperBankT6),'tipInLower',ismember(tip,D.lowerBankT6),'upperLast',D.upperBankT6(end),'lowerLast',D.lowerBankT6(end));
   E{end+1}=e; %#ok<AGROW>
   fprintf('DIAG %s %-3s tip=%d shared=%s bitwise=%d d=%.3e dx=%.3e dy=%.3e\n',s.id,side{1},tip,mat2str(sh(:).'),e.tipCoordinateBitwise,e.distance_mm,x(1)-P(1),x(2)-P(2));
  end
  T=g2_lp2b1eq_topology(Dn,Do);fprintf('DIAG %s topology pass=%d tip=%d\n',s.id,T.pass,T.checks.tip);
 end
 fid=fopen(fullfile(od,'LP2B1EQ_DIAG_TIP.json'),'w');fwrite(fid,jsonencode(struct('schema','NewMetacomp.G2.LP2B1EQ.DiagTip.v1','physicalSolves',0,'entries',{E}),'PrettyPrint',true),'char');fclose(fid);
catch ME
 fprintf(2,'S5_ERROR %s: %s\n',ME.identifier,ME.message);for k=1:numel(ME.stack),fprintf(2,'  %s:%d\n',ME.stack(k).name,ME.stack(k).line);end
end
fprintf('MATLAB_PROCESSES_END=%d\n',numel(regexp(evalc('system(''tasklist /FI "IMAGENAME eq MATLAB.exe" /NH'');'),'MATLAB.exe')));
