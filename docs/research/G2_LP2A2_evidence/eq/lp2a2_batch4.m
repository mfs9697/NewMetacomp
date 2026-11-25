% LP2-A2 batch 4 (zero FEM): EQ contract tests E1-E6, geometry-only fallback-rung check of H S8, figures
ex='<repo>';o=fullfile(ex,'outputs');ev=fullfile(ex,'docs','research','G2_LP2A2_evidence');
g2=fullfile(ex,'matlab','g2');addpath(g2,'-begin');addpath(fullfile(g2,'vendor_p010_a14d8872'),'-begin');addpath(fullfile(g2,'lp2a2'),'-begin');addpath(fullfile(ex,'scripts','g2','lp2a2'),'-begin');
[~,c]=system(['git -C "',ex,'" rev-parse HEAD']);fprintf('SOURCE_COMMIT=%s\n',strtrim(c));
try
 T=g2_lp2a2_eq_tests();T.sourceCommit=strtrim(c);fid=fopen(fullfile(o,'LP2A2_EQ_TESTS.json'),'w');fwrite(fid,jsonencode(T,'PrettyPrint',true),'char');fclose(fid);
 fprintf('EQ_OUTPUT_ROOT_EXISTS=%d GO_FILE_EXISTS=%d\n',exist(fullfile(o,'g2_lp2a2_eq_v1'),'dir'),isfile(fullfile(g2,'lp2a2','G2_LP2A2_EQ_GO.json')));
catch ME,fprintf(2,'EQ_TESTS_ERROR %s: %s\n',ME.identifier,ME.message);disp(ME.stack(1));end
% ---- would H S8 at the fallback spacings be meshable for a supplementary equivalence experiment?
try
 lp=jsondecode(fileread(fullfile(g2,'G2_LP1_POLICY_v2.json')));Ca=struct('repo',ex,'here',g2,'policy',lp);
 S=load(fullfile(o,'g2_lp2a_paths_v1','run_lp2a_s5_s8_v1','H','S8','STATE.mat'));S=S.record;P=S.polyline_mm;t=S.tangent;N=size(P,1);
 opts={'BottomVertices_mm',[25.4 482.6],'TopVertices_mm',254,'TipGuideRadius_mm',15,'TipGuideHface_mm',1.5};F={};
 for hs=[0.45 0.40 0.50 0.35]
  [~,D]=evalc('g2_lp2a2_join(P,''ExpectedVertices'',N,''ExpectedTangent'',t,''ExteriorOptions'',[opts,{''SeedSpacing_mm'',hs}],''MaxT3Elements'',40000)');
  r=struct('seedSpacing_mm',hs,'stage',D.stage,'T3',size(D.T3,1),'minAngle_deg',D.summary.minAngle_deg,'maxNeighborRatio',D.summary.maxNeighborRatio,'auditPass',false,'pairingPass',false);
  if D.pass,D.tipTangent=t;[~,A,PM]=evalc('g2_lp1_audit(D,N-2,Ca)');r.auditPass=A.pass&&PM.pass&&A.meshAudit.gatesPassed==34;PA=g2_lp2a2_pairing_audit(D);r.pairingPass=PA.pass;r.bankPairsT6=PA.metrics.pairsT6;end
  F{end+1}=r; %#ok<AGROW>
  fprintf('H_S8_RUNG hs=%.2f stage=%s T3=%d minAng=%.3f ratio=%.4f audit=%d pairing=%d\n',hs,r.stage,r.T3,r.minAngle_deg,r.maxNeighborRatio,r.auditPass,r.pairingPass);
 end
 R=struct('schema','NewMetacomp.G2.LP2A2.HS8FallbackRungCheck.v1','physicalSolves',0,'sourceCommit',strtrim(c),'rows',{F});
 fid=fopen(fullfile(o,'LP2A2_HS8_RUNG_CHECK.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
catch ME,fprintf(2,'RUNG_ERROR %s\n',ME.message);end
try
 lp2a2_figures(ex,fullfile(ev,'LP2A2_TEST_SET.json'),fullfile(ev,'attempt2','LP2A2_MESH_QUALIFICATION_ATTEMPT2.json'),fullfile(o,'lp2a2_figures'));fprintf('FIG_DONE\n');
catch ME,fprintf(2,'FIG_ERROR %s: %s\n',ME.identifier,ME.message);disp(ME.stack(1));end
