% LP2-B1-EQ stage 3 (zero FEM): geometry-only 0.40 mm admission replay of the two fixed references, real preflight,
% then raw exports of the qualification and replay canonical arrays for the independent Python hashcheck
ex='<repo>';
[~,c]=system(['git -C "',ex,'" rev-parse HEAD']);fprintf('SOURCE_COMMIT=%s\n',strtrim(c));
[~,st]=system(['git -C "',ex,'" status --porcelain --untracked-files=all']);fprintf('SOURCE_STATUS=[%s]\n',strtrim(st));
restoredefaultpath;addpath(fullfile(ex,'matlab','g2'));addpath(fullfile(ex,'matlab','g2','lp2b1eq'));addpath(fullfile(ex,'scripts','g2','lp2b1eq'));
RR=fullfile(ex,'outputs','g2_lp2b1eq_readiness_v1');rp=fullfile(RR,'replay_v3');
try
 assert(~isfolder(rp),'S3:Exists','replay_v3 exists');mkdir(rp);
 ids={'EQB-soft1-S9','EQB-H-S10'};O=cell(1,2);
 for k=1:2
  t0=tic;O{k}=g2_lp2b1eq_run(ids{k},'Mesh',true,'ReplayRoot',rp);g=O{k}.geometry;
  fprintf('REPLAY %s pass=%d canonical=%s attempt=%s T3=%d minAngle=%.9f ratio=%.13f activeArea=%.17g chords=%s (%.1f s)\n',ids{k},g.pass,g.canonicalSHA256, ...
   g.attemptChecks,g.T3,g.minAngle_deg,g.maxNeighborRatio,g.activeAreaGeometric_mm2,mat2str(g.chordsPerCircle),toc(t0));
  f=fieldnames(g.checks);for i=1:numel(f),fprintf('   %-30s %d\n',f{i},g.checks.(f{i}));end
  fprintf('   topology pass=%d blockNodes=%d bankPairs=%d DOFs=%d tip %d->%d\n',g.topology.pass,g.topology.blockNodes,g.topology.bankPairsInBlock,g.topology.distinctBankDOFsInBlock,g.topology.tipOld,g.topology.tipNew);
  fprintf('   stations new=%d arch=%d near=%d/%d matched=%d\n',g.stations.nNew,g.stations.nArchived,g.stations.nearNew,g.stations.nearArchived,g.stations.nearMatched);
 end
 C=g2_lp2b1eq_context('Preflight',false);q1=C.solves{1}.qualification;q2=C.solves{2}.qualification;
 rel=@(id)['outputs/g2_lp2b1eq_readiness_v1/replay_v3/' id '/GEOMETRY_h040/ATTEMPT_ARRAYS.mat'];
 sets=struct('name',{'Q_EQB-soft1-S9','Q_EQB-H-S10','P_EQB-soft1-S9','P_EQB-H-S10'},'source',{q1.arrays.path,q2.arrays.path,rel(ids{1}),rel(ids{2})}, ...
  'expectedCanonicalSHA256',{q1.canonicalSHA256,q2.canonicalSHA256,q1.canonicalSHA256,q2.canonicalSHA256});
 X=lp2b1eq_export(ex,sets,fullfile(RR,'export_v3'));fprintf('EXPORT sets=%d\n',numel(X.sets));
 fprintf('REPLAY_RESULT pass=%d,%d\n',O{1}.geometry.pass,O{2}.geometry.pass);
catch ME
 fprintf(2,'S3_ERROR %s: %s\n',ME.identifier,ME.message);for k=1:numel(ME.stack),fprintf(2,'  %s:%d\n',ME.stack(k).name,ME.stack(k).line);end
end
fprintf('MATLAB_PROCESSES_END=%d\n',numel(regexp(evalc('system(''tasklist /FI "IMAGENAME eq MATLAB.exe" /NH'');'),'MATLAB.exe')));

