% LP2-B1-S10 stage 4 (zero FEM): final target qualification under the real preflight, geometry-only 0.40 mm replay of
% the exact target (unchanged g2_lp2b1eq_geometry, FAILED_MESH baseline), raw exports for the independent hashcheck
ex='<repo>';
[~,c]=system(['git -C "',ex,'" rev-parse HEAD']);fprintf('SOURCE_COMMIT=%s\n',strtrim(c));
[~,st]=system(['git -C "',ex,'" status --porcelain --untracked-files=all']);fprintf('SOURCE_STATUS=[%s]\n',strtrim(st));
restoredefaultpath;g2d=fullfile(ex,'matlab','g2');for f={'','lp2','lp2a2','lp2a3','lp2b1','lp2b1eq'},addpath(fullfile(g2d,f{1}));end
addpath(fullfile(ex,'scripts','g2','lp2a2','closure'));addpath(fullfile(g2d,'lp2b1s10'));addpath(fullfile(ex,'scripts','g2','lp2b1eq'));
RR=fullfile(ex,'outputs','g2_lp2b1s10_readiness_v1');w0=fullfile(RR,'wp0_v2');rp=fullfile(RR,'replay_v1');xp=fullfile(RR,'export_v1');
try
 assert(~isfolder(w0)&&~isfolder(rp)&&~isfolder(xp),'S4:Exists','stage folders exist');mkdir(w0);mkdir(rp);
 C=g2_lp2b1s10_context();pf=C.preflight;if isfield(pf,'matlabProcessInfo'),pf=rmfield(pf,'matlabProcessInfo');end
 Tq=g2_lp2b1s10_target(C);
 W=struct('schema','NewMetacomp.G2.LP2B1S10.WP0.v1','physicalSolves',0,'sourceCommit',strtrim(c),'preflight',pf,'token',C.token,'policySHA256',C.policySHA256, ...
  'lp2b1s10SourceSHA256',C.lp2b1s10SourceSHA256,'target',struct('pass',Tq.pass,'checks',Tq.checks,'failed',{Tq.failed},'info',Tq.info,'parentSHA256',Tq.parentSHA256, ...
  'forecastPolyline_mm',Tq.forecast.polyline_mm,'forecastTangent',Tq.forecast.tangent),'rootsAbsent',~isfolder(C.runRoot)&&~isfolder(C.receiptRoot)&&~isfile(C.summaryFile)&&~isfile(C.goFile));
 fid=fopen(fullfile(w0,'LP2B1S10_WP0.json'),'w');fwrite(fid,jsonencode(W,'PrettyPrint',true),'char');fclose(fid);
 fprintf('WP0 target=%d failed=[%s] roots=%d\n',Tq.pass,strjoin(Tq.failed,','),W.rootsAbsent);
 t0=tic;O=g2_lp2b1s10_run('Mesh',true,'ReplayRoot',rp);g=O.geometry;
 f=fieldnames(g.checks);for k=1:numel(f),fprintf('GEOM %-28s %d\n',f{k},g.checks.(f{k}));end
 f=fieldnames(g.expected);for k=1:numel(f),fprintf('EXPECT %-26s %d\n',f{k},g.expected.(f{k}));end
 fprintf('REPLAY pass=%d canonical=%s T3=%d minAng=%.15f ratio=%.16f chords=%s class=%s gap=%s topo=%d (%.1f s)\n',g.pass,g.canonicalSHA256,g.T3,g.minAngle_deg,g.maxNeighborRatio, ...
  mat2str(g.chordsPerCircle),g.actualClassification,mat2str(g.guideRingGap_mm,17),g.topology.pass,toc(t0));
 rel=@(p)strrep(strrep(p,[ex filesep],''),'\','/');
 sets=struct('name',{'Q_soft1_S10','R_soft1_S10'},'source',{C.policy.qualification.arrays.path,rel(fullfile(rp,'soft1_S10','GEOMETRY_h040','ATTEMPT_ARRAYS.mat'))}, ...
  'expectedCanonicalSHA256',{C.policy.qualification.canonicalSHA256,C.policy.qualification.canonicalSHA256});
 lp2b1eq_export(ex,sets,xp);fprintf('EXPORT done\n');
 fprintf('S4_RESULT wp0=%d replay=%d roots=%d\n',Tq.pass,g.pass,~isfolder(C.runRoot)&&~isfolder(C.receiptRoot));
catch ME
 fprintf(2,'S4_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
