function R=lp2b1_summary_diff(ex,outDir)
%LP2B1_SUMMARY_DIFF  Read-only: which fields of the saved join SUMMARY differ between the attempt-1 and attempt-2
% 0.40 mm target meshes (two MATLAB sessions). Every other saved array field is compared in LP2B1_POSTAUDIT.json.
assert(~isfolder(outDir),'LP2B1SD:Out','Output folder exists.');mkdir(outDir);
root=fullfile(ex,'outputs','g2_lp2b1_geometry_v1');
a=load(fullfile(root,'wp1','T_soft1_S10_h040','ATTEMPT_ARRAYS.mat'),'summary');b=load(fullfile(root,'wp1_attempt2','T_soft1_S10_h040','ATTEMPT_ARRAYS.mat'),'summary');
d={};walk(a.summary,b.summary,'summary');
R=struct('schema','NewMetacomp.G2.LP2B1.SummaryDiff.v1','differingPaths',{d},'onlyTiming',all(contains(lower(d),'seconds')));
R.values=cellfun(@(p)struct('path',p,'attempt1',getp(a,p),'attempt2',getp(b,p)),d,'UniformOutput',false);
fid=fopen(fullfile(outDir,'LP2B1_SUMMARY_DIFF.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
fprintf('LP2B1_SUMMARY_DIFF paths=%s onlyTiming=%d\n',strjoin(d,','),R.onlyTiming);
 function walk(x,y,p)
  if isstruct(x)&&isstruct(y)&&isscalar(x)&&isscalar(y)
   f=union(fieldnames(x),fieldnames(y));
   for i=1:numel(f)
    if ~isfield(x,f{i})||~isfield(y,f{i}),d{end+1}=[p '.' f{i}];continue,end %#ok<AGROW>
    walk(x.(f{i}),y.(f{i}),[p '.' f{i}]);
   end
  elseif ~isequal(x,y)
   d{end+1}=p;
  end
 end
end
function v=getp(s,p),v=eval(['s.' p]);end
