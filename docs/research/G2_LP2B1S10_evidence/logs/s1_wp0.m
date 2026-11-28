% LP2-B1-S10 stage 1 (zero FEM): static analysis of the new module, real-preflight context, target qualification
ex='<repo>';
[~,c]=system(['git -C "',ex,'" rev-parse HEAD']);fprintf('SOURCE_COMMIT=%s\n',strtrim(c));
[~,st]=system(['git -C "',ex,'" status --porcelain --untracked-files=all']);fprintf('SOURCE_STATUS=[%s]\n',strtrim(st));
restoredefaultpath;g2d=fullfile(ex,'matlab','g2');for f={'','lp2','lp2a2','lp2a3','lp2b1','lp2b1eq'},addpath(fullfile(g2d,f{1}));end
addpath(fullfile(ex,'scripts','g2','lp2a2','closure'));addpath(fullfile(g2d,'lp2b1s10'));
RR=fullfile(ex,'outputs','g2_lp2b1s10_readiness_v1');od=fullfile(RR,'wp0_v1');
try
 assert(~isfolder(od),'S1:Exists','wp0_v1 exists');mkdir(od);
 fl=dir(fullfile(g2d,'lp2b1s10','*.m'));L=struct('file',{},'messages',{});
 for k=1:numel(fl),m=checkcode(fullfile(fl(k).folder,fl(k).name),'-id');L(end+1)=struct('file',fl(k).name,'messages',{arrayfun(@(x)sprintf('%d %s %s',x.line,x.id,x.message),m,'UniformOutput',false)}); %#ok<SAGROW>
  fprintf('LINT %s %d\n',fl(k).name,numel(m));for j=1:numel(m),fprintf('  %d %s %s\n',m(j).line,m(j).id,m(j).message);end,end
 C=g2_lp2b1s10_context();pf=C.preflight;if isfield(pf,'matlabProcessInfo'),pf=rmfield(pf,'matlabProcessInfo');end
 fprintf('TOKEN=%s\n',C.token);
 Tq=g2_lp2b1s10_target(C);
 f=fieldnames(Tq.checks);for k=1:numel(f),fprintf('TARGET %-18s %d\n',f{k},Tq.checks.(f{k}));end
 O=g2_lp2b1s10_run();
 W=struct('schema','NewMetacomp.G2.LP2B1S10.WP0.v1','physicalSolves',0,'sourceCommit',strtrim(c),'preflight',pf,'token',C.token,'policySHA256',C.policySHA256, ...
  'lp2b1s10SourceSHA256',C.lp2b1s10SourceSHA256,'parentManifestSHA256',C.parentManifestSHA256,'qualificationManifestSHA256',C.qualificationManifestSHA256, ...
  'eqEvidenceManifestSHA256',C.eqEvidenceManifestSHA256,'target',struct('pass',Tq.pass,'checks',Tq.checks,'failed',{Tq.failed},'info',Tq.info,'parentSHA256',Tq.parentSHA256, ...
  'forecastPolyline_mm',Tq.forecast.polyline_mm),'driverDry',O,'lint',L,'rootsAbsent',~isfolder(C.runRoot)&&~isfolder(C.receiptRoot)&&~isfile(C.summaryFile)&&~isfile(C.goFile));
 fid=fopen(fullfile(od,'LP2B1S10_WP0.json'),'w');fwrite(fid,jsonencode(W,'PrettyPrint',true),'char');fclose(fid);
 fprintf('S1_RESULT target=%d failed=[%s] dry=%s roots=%d\n',Tq.pass,strjoin(Tq.failed,','),O.stage,W.rootsAbsent);
catch ME
 fprintf(2,'S1_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
