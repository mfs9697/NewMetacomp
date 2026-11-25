% LP2-A3 readiness evidence v1 in the clean LF execution clone: contract suite, four S9 default-rung dry
% qualifications, unchanged LP2-A2 (v3) and LP2-A1 contract suites. Zero FEM; nothing written under the
% clone except git-ignored JSON results in outputs/.
ex='<repo>';o=fullfile(ex,'outputs');
addpath(fullfile(ex,'matlab','g2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a3'),'-begin');
H=g2_lp2a2_git('head',ex);fprintf('SOURCE_COMMIT=%s status=%d\n',H.value,H.status);
[~,s]=memory;fprintf('RAM_INSIDE_MATLAB=%.3f\n',s.PhysicalMemory.Available/2^30);
wj=@(f,S)writeJ(fullfile(o,f),S);
% 2 four S9 candidates (default rung only; no write, no solve)
D=struct('schema','NewMetacomp.G2.LP2A3.S9Dry.v1','sourceCommit',H.value,'physicalSolves',0,'cases',{{}});
for id={'H','stiff13','soft2','soft1'}
 try,O=g2_lp2a3_run('Case',id{1},'Mesh',true,'Preflight',false);D.cases{end+1}=O;
  fprintf('EVID_S9 %s bitwise=%d cls=%s gap=%s mesh=%d %s T3=%d audit=%s pairing=%s chords=%s actual=%s\n',id{1},O.terminalComparison.bitwiseEqual,O.S9.classification, ...
   mat2str(O.S9.guard.gap_mm,8),O.mesh.pass,O.mesh.stage,O.mesh.T3,O.mesh.meshAuditGates,O.mesh.pairing,mat2str(O.mesh.chordsPerCircle),O.mesh.actualClassification);
 catch ME,fprintf('EVID_S9_ERROR %s %s: %s\n',id{1},ME.identifier,ME.message);D.cases{end+1}=struct('caseId',id{1},'error',[ME.identifier ': ' ME.message]);end
end
D.token=O.token;wj('LP2A3_S9_DRY_v1.json',D);
fprintf('EVID_GO_FILE=%d RUN_ROOT=%d LEDGER=%d\n',isfile(fullfile(ex,'matlab','g2','lp2a3','G2_LP2A3_GO.json')),isfolder(fullfile(o,'g2_lp2a3_paths_v1')),isfolder(fullfile(o,'g2_lp2a3_campaign_ledger')));
function writeJ(f,S),fid=fopen(f,'w');fwrite(fid,jsonencode(S,'PrettyPrint',true),'char');fclose(fid);end
