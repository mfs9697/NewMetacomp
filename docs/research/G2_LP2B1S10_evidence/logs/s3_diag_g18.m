% LP2-B1-S10 diagnosis of test G18 (zero FEM, no mesh): replicate the TERMINAL candidate path with the injected failing
% S11 forecast, write/read the record under tempdir and print each condition of the test
ex='<repo>';
restoredefaultpath;g2d=fullfile(ex,'matlab','g2');for f={'','lp2','lp2a2','lp2a3','lp2b1','lp2b1eq'},addpath(fullfile(g2d,f{1}));end;addpath(fullfile(g2d,'lp2b1s10'));
try
 fq=@(St,p)error('B1S10T:FORECAST','injected S11 forecast failure');
 cand=struct('polyline_mm',[],'classification','','guideRingGap_mm',[],'clearancePass',[],'clearance',struct(),'tipToRingCircle_mm',[],'note','');
 try
  F11=fq(1,2); %#ok<NASGU>
 catch ME
  fprintf('CAUGHT id=[%s] msg=[%s]\n',ME.identifier,ME.message);cand.note=sprintf('S11 information unavailable (%s)',ME.identifier);
 end
 d=fullfile(tempdir,sprintf('b1s10_diag_%s',datestr(now,'yyyymmddHHMMSSFFF')));mkdir(d);
 g2_trajectory_record('write',fullfile(d,'TERMINAL.mat'),struct('schema','x','candidate',cand,'stateIndex',10,'physicalFractureGrowthProven',false));
 [Tm,~,okt]=g2_trajectory_record('read',fullfile(d,'TERMINAL.mat'));
 fprintf('okt=%d isempty=%d class=%s size=%s note=[%s] startsWith=%d\n',okt,isempty(Tm.candidate.polyline_mm),class(Tm.candidate.polyline_mm),mat2str(size(Tm.candidate.polyline_mm)), ...
  Tm.candidate.note,startsWith(Tm.candidate.note,'S11 information unavailable (B1S10T:FORECAST)'));
 rmdir(d,'s');
catch ME
 fprintf(2,'DIAG_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
