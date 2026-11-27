% LP2-B1-EQ stage 2 (zero FEM, no mesh): WP0 archived-reference qualification under the REAL preflight
ex='<repo>';
[~,c]=system(['git -C "',ex,'" rev-parse HEAD']);fprintf('SOURCE_COMMIT=%s\n',strtrim(c));
[~,st]=system(['git -C "',ex,'" status --porcelain --untracked-files=all']);fprintf('SOURCE_STATUS=[%s]\n',strtrim(st));
restoredefaultpath;addpath(fullfile(ex,'matlab','g2'));addpath(fullfile(ex,'matlab','g2','lp2b1eq'));addpath(fullfile(ex,'scripts','g2','lp2b1eq'));
RR=fullfile(ex,'outputs','g2_lp2b1eq_readiness_v1');od=fullfile(RR,'wp0_v4');
try
 assert(~isfolder(od),'S2:Exists','wp0_v4 exists');mkdir(od);
 C=g2_lp2b1eq_context();fprintf('PREFLIGHT pass=%d free=%.3f engines=%d commit=%s\n',C.preflight.pass,C.preflight.freePhysicalRAM_GiB,C.preflight.matlabProcesses,C.preflight.sourceCommit);
 fprintf('TOKEN %s\n',C.token);
 W=struct('schema','NewMetacomp.G2.LP2B1EQ.WP0.v1','physicalSolves',0,'meshBuilds',0,'token',C.token,'policySHA256',C.policySHA256, ...
  'referenceManifestSHA256',C.referenceManifestSHA256,'qualificationManifestSHA256',C.qualificationManifestSHA256,'preflight',C.preflight,'solves',{{}});
 for k=1:2
  s=C.solves{k};Ref=g2_lp2b1eq_reference(C,s);K=Ref.solution.K;
  e=struct('solveId',s.id,'pass',Ref.pass,'checks',Ref.checks,'stateSHA256',Ref.stateSHA256,'solutionSHA256',Ref.solutionSHA256,'meshSHA256',Ref.meshSHA256,'phaseSHA256',Ref.phaseSHA256, ...
   'parentSHA256',Ref.state.parentSHA256,'arc_mm',Ref.state.arc_mm,'tip_mm',Ref.state.tip_mm,'tangent',Ref.state.tangent,'KI',K.KI,'KII',K.KII,'J',K.J,'G',Ref.state.G, ...
   'KI_COD',K.KI_COD,'KII_COD',K.KII_COD,'EDI_all',K.EDI_all,'EDI4x4',K.EDI4x4,'compliance_mm_per_N',K.compliance_mm_per_N,'activeArea_mm2',K.activeArea_mm2, ...
   'activeAreaRecomputed_mm2',Ref.archivedActiveAreaRecomputed_mm2,'gates',K.criteria,'uLength',Ref.uLength,'N_T6',Ref.N_T6,'uFinite',all(isfinite(K.u)), ...
   'loadNode',Ref.loadNode,'pinNode',Ref.pinNode,'rollerNode',Ref.rollerNode,'uyLoad_mm',K.uyLoad_mm,'uPin',K.u(2*Ref.pinNode+(-1:0)).','uyRoller',K.u(2*Ref.rollerNode), ...
   'mts',Ref.mts,'banks',Ref.banks,'maxJump_mm',Ref.maxJump_mm,'maxJumpNearTip_mm',Ref.maxJumpNearTip_mm,'chordsPerCircle',Ref.chordsPerCircle, ...
   'nextState',Ref.nextState,'nextTip_mm',Ref.nextTip_mm,'pinnedNextTip_mm',reshape(s.nextPredictor.tip_mm,1,2),'nextTipBitwise',isequal(Ref.nextTip_mm,reshape(s.nextPredictor.tip_mm,1,2)), ...
   'qualificationCanonicalSHA256',s.qualification.canonicalSHA256);
  W.solves{end+1}=e;fprintf('WP0 %s pass=%d checks=%d/%d next=%s tip=(%.17g,%.17g) uLen=%d N6=%d KI=%.17g KII=%.17g\n',s.id,Ref.pass, ...
   nnz(cell2mat(struct2cell(Ref.checks))),numel(fieldnames(Ref.checks)),Ref.nextState,Ref.nextTip_mm,Ref.uLength,Ref.N_T6,K.KI,K.KII);
  f=fieldnames(Ref.checks);for i=1:numel(f),fprintf('   %-22s %d\n',f{i},Ref.checks.(f{i}));end
 end
 W.pass=all(cellfun(@(x)x.pass,W.solves));
 fid=fopen(fullfile(od,'LP2B1EQ_WP0_REFERENCES.json'),'w');fwrite(fid,jsonencode(W,'PrettyPrint',true),'char');fclose(fid);
 fprintf('WP0_RESULT pass=%d\n',W.pass);
catch ME
 fprintf(2,'S2_ERROR %s: %s\n',ME.identifier,ME.message);for k=1:numel(ME.stack),fprintf(2,'  %s:%d\n',ME.stack(k).name,ME.stack(k).line);end
end
fprintf('MATLAB_PROCESSES_END=%d\n',numel(regexp(evalc('system(''tasklist /FI "IMAGENAME eq MATLAB.exe" /NH'');'),'MATLAB.exe')));

