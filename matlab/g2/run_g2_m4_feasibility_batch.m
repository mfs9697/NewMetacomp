function L=run_g2_m4_feasibility_batch()
%RUN_G2_M4_FEASIBILITY_BATCH  G2-M4.0 zero-state feasibility of an alternative S0 (Issue #44).
%
% Mesh-only, no FEM, no SIF, no crack advance, no MAT written. Writes a NEW folder
% outputs/g2_m4_feasibility/run_* with the console log, FEASIBILITY.json and SHA256SUMS.txt.
%  F0 source lock: SHA-256 of the PR #41 sources, policies, the PR #41 chain ROOT/STATE
%     records, the WP2 famA S0 mesh and the M2 ledger (read only).
%  F1 builder identity: the exact WP2 famA call of g2_join_protected_mesh is re-run in
%     memory and must reproduce the SAVED famA arrays bitwise (proves which routine and
%     which options made the historical S0).
%  F2 alternative S0: the same routine, same physical geometry, crack, holes, band radii,
%     anchors and frozen p010 core/collar, with the exterior options of the PR #38 S2alt
%     family ('GuideHface_mm',1.0,'Hmax_mm',5): join gates, the independent 38-gate and
%     24-gate protected-tip audits of the arrays, the S0 schema adapter, the PR #38 phase
%     stage (mapper, verifier, state-aware negatives), chord counts, band polygon areas
%     and exterior-node independence from famA.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
vendor=fullfile(here,'vendor_p010_a14d8872');addpath(vendor,'-begin');
outRoot=fullfile(repo,'outputs','g2_m4_feasibility');if ~isfolder(outRoot),mkdir(outRoot);end
folder=fullfile(outRoot,['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);assert(~isfolder(folder));mkdir(folder);
diary(fullfile(folder,'batch_console.log'));c=onCleanup(@()diary('off')); %#ok<NASGU>
fprintf('STAGE=G2_M4_0_FEASIBILITY\nDATE=%s\nMATLAB_RELEASE=%s\nNO_FEM=1; NO_SIF=1; NO_STATE=1; NO_MAT_WRITTEN=1\n',datestr(now,31),version('-release'));
L=struct('schema','NewMetacomp.G2.M4.Feasibility.v1','issue',44,'status','HOLD');L.stages={};
json=fullfile(repo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json');
p0=fullfile(repo,'outputs','g2_p010_isolated','run_20261118_163657_790','P010_ISOLATED_REGULAR_ONLY.mat');
polM=jsondecode(fileread(fullfile(here,'G2_MATERIAL_POLICY_v1.json')));
try
 % ---------------- F0 source lock
 [h,d]=git(repo);L.gitHead=h;L.dirty=d;
 files={'matlab/g2/G2_M3_TRAJECTORY_POLICY_v1.json','matlab/g2/G2_MATERIAL_POLICY_v1.json','matlab/g2/G2_TRAJECTORY_POLICY_v1.json', ...
  'matlab/g2/G2_M2_POLICY_v1.json','matlab/g2/g2_m3_trajectory_run.m','matlab/g2/g2_material_phase_map.m','matlab/g2/g2_material_phase_verify.m', ...
  'matlab/g2/g2_material_phase_stage.m','matlab/g2/g2_t6_elasticity_phase.m','matlab/g2/g2_material_sif_on_mesh.m','matlab/g2/g2_trajectory_sif_on_mesh.m', ...
  'matlab/g2/g2_join_protected_mesh.m','matlab/g2/g2_protected_exterior_mesh.m','matlab/g2/g2_p010_cornell_regular_block.m', ...
  'matlab/g2/g2_independent_t6_checker.m','matlab/g2/g2_protected_tip_checker.m','matlab/g2/g2_kinked_join.m','matlab/g2/g2_kinked_exterior_mesh.m', ...
  'matlab/g2/g2_kinked_mesh_auditor.m','matlab/g2/g2_m2_state_adapter.m','matlab/g2/run_g2_protected_mesh_batch.m', ...
  'matlab/g2/evidence/m2_20261121/SHA256SUMS_original_outputs.txt','matlab/g2/evidence/m3_20261121/SHA256SUMS_original_outputs.txt', ...
  'docs/research/crack-growth-gaps-2026/G2_SPECIMEN1_1990_GEOMETRY.json', ...
  'outputs/g2_protected_mesh/run_20261118_165922_343_famA/GEOMETRY_ONLY_candidate.mat', ...
  'outputs/g2_p010_isolated/run_20261118_163657_790/P010_ISOLATED_REGULAR_ONLY.mat'};
 for m={'soft','stiff'}
  for r={'ROOT.mat','STEP_001/STATE.mat','STEP_002/STATE.mat'}
   files{end+1}=['outputs/g2_material_trajectories_v1/chain_',m{1},'_v1/',r{1}]; %#ok<AGROW>
  end
 end
 src=repmat(struct('file','','sha256',''),numel(files),1);
 for k=1:numel(files)
  f=fullfile(repo,strrep(files{k},'/',filesep));assert(isfile(f),'G2M4F:Missing','Missing %s',files{k});
  src(k).file=files{k};src(k).sha256=lower(g2_sha256_file(f));
 end
 pol3=jsondecode(fileread(fullfile(here,'G2_M3_TRAJECTORY_POLICY_v1.json')));
 s0=fullfile(repo,pol3.base.s0Mesh);
 assert(strcmpi(g2_sha256_file(s0),pol3.base.s0MeshSHA256),'G2M4F:S0Hash','famA S0 mesh hash differs from the M3 policy pin.');
 led3=lower(fileread(fullfile(repo,'matlab','g2','evidence','m3_20261121','SHA256SUMS_original_outputs.txt')));
 chainOK=true;
 for k=1:numel(src)
  if startsWith(src(k).file,'outputs/g2_material_trajectories_v1/')
   chainOK=chainOK&&contains(led3,[src(k).sha256,' *',erase(src(k).file,'outputs/')]);
  end
 end
 assert(chainOK,'G2M4F:ChainLedger','A PR #41 chain record is not in the M3 SHA ledger.');
 L.sources=src;L=stage(L,'F0_SOURCE_LOCK','PASS',struct('files',numel(src),'pr41ChainRecordsInLedger',chainOK));
 % ---------------- F1 builder identity (famA)
 optA={'BottomVertices_mm',[25.4 482.6],'TopVertices_mm',254,'TipGuideRadius_mm',15,'TipGuideHface_mm',1.5};
 DA=load(s0);
 RA=g2_join_protected_mesh('ExteriorOptions',optA,'MaxT3Elements',40000);
 same=RA.pass&&isequal(RA.X3,DA.X3)&&isequal(RA.T3,DA.T3)&&isequal(RA.X6,DA.X6)&&isequal(RA.T6,DA.T6)&& ...
  isequal(RA.upperBankT6,DA.upperBankT6)&&isequal(RA.lowerBankT6,DA.lowerBankT6)&&isequal(RA.nodalQ,DA.nodalQ);
 fprintf('F1 famA rebuild bitwise=%d (T3 %d)\n',same,size(RA.T3,1));
 assert(same,'G2M4F:BuilderIdentity','The WP2 famA call does not reproduce the saved S0 arrays.');
 L=stage(L,'F1_BUILDER_IDENTITY','PASS',struct('famA_T3',size(DA.T3,1),'bitwise',same,'options',{optA}));
 clear RA
 % ---------------- F2 alternative S0
 optB=[optA,{'GuideHface_mm',1.0,'Hmax_mm',5}];
 RB=g2_join_protected_mesh('ExteriorOptions',optB,'MaxT3Elements',40000);
 fprintf('F2 alt join pass=%d stage=%s failed=[%s]\n',RB.pass,RB.stage,strjoin(RB.failedGates,','));
 assert(RB.pass,'G2M4F:AltJoin','HOLD_ALT_S0: join %s',strjoin(RB.failedGates,','));
 DB=struct('X3',RB.X3,'T3',RB.T3,'X6',RB.X6,'T6',RB.T6,'upperBankT6',RB.upperBankT6,'lowerBankT6',RB.lowerBankT6, ...
  'physicalTipNode',RB.physicalTipNode,'nodalQ',RB.nodalQ,'qActiveT6Rows',RB.qActiveT6Rows,'elementRows',RB.elementRows, ...
  'collarOuterIDs',RB.collarOuterIDs,'summary',RB.summary,'gates',RB.gates,'geometryOnly',true,'approvedForLEFM',false, ...
  'p010GlobalProtectedMeshQualified',false,'extraVertexXY',RB.extraVertexXY,'extraVertexNodes',RB.extraVertexNodes, ...
  'includeHoles',RB.includeHoles,'plateXRange',RB.plateXRange,'familyTag','famB_m4alt');
 C38=g2_independent_t6_checker(DB,json);CP=g2_protected_tip_checker(DB,json,p0);
 fprintf('F2 alt audits 38-gate %d/%d, protected-tip %d/%d\n',C38.gatesPassed,C38.gatesTotal,CP.gatesPassed,CP.gatesTotal);
 aud=struct('join',sprintf('%d/%d',nnz(cell2mat(struct2cell(RB.gates))),numel(fieldnames(RB.gates))), ...
  'independent38',sprintf('%d/%d',C38.gatesPassed,C38.gatesTotal),'protectedTip',sprintf('%d/%d',CP.gatesPassed,CP.gatesTotal));
 assert(C38.pass&&C38.gatesPassed==38&&CP.pass&&CP.gatesPassed==CP.gatesTotal,'G2M4F:AltAudit','HOLD_ALT_S0: audits %s',jsonencode(aud));
 P0=[101.6 0;101.6 25.4];
 [Dm,Ad]=g2_m2_state_adapter(DB,'S0',P0);assert(Ad.pass,'G2M4F:Adapter','HOLD_ALT_S0: adapter %s',strjoin(Ad.failed,','));
 [PM,V,NC,geom]=g2_material_phase_stage(Dm,polM,P0);
 assert(PM.pass&&V.pass&&NC.pass,'G2M4F:Phase','HOLD_ALT_S0: phase map %d verifier %d negatives %d',PM.pass,V.pass,NC.pass);
 % famA geometry for comparison (same phase stage, read only)
 [DmA,AdA]=g2_m2_state_adapter(DA,'S0',P0);assert(AdA.pass);
 [PMA,VA,NCA,geomA]=g2_material_phase_stage(DmA,polM,P0);assert(PMA.pass&&VA.pass&&NCA.pass);
 % exterior independence: exterior T3 nodes of alt that coincide with famA nodes
 core=unique(RB.T3([RB.elementRows.core;RB.elementRows.collar],:));ext=setdiff(unique(RB.T3),core);
 [tf]=ismember(round(RB.X3(ext,:)*1e9),round(DA.X3*1e9),'rows');
 nom=pi*(19.05^2-6.35^2);
 ind=struct('exteriorNodesAlt',numel(ext),'exteriorNodesCoincidingWithFamA',nnz(tf),'coreCollarT3Shared',2916, ...
  'famA_T3',size(DA.T3,1),'alt_T3',size(RB.T3,1),'alt_minAngle_deg',RB.summary.minAngle_deg,'alt_maxNeighborRatio',RB.summary.maxNeighborRatio);
 gcmp=struct('chords_famA',geomA.chordsPerCircle(:).','chords_alt',geom.chordsPerCircle(:).', ...
  'bandArea_famA_mm2',geomA.annulusArea_mm2(:).','bandArea_alt_mm2',geom.annulusArea_mm2(:).','bandArea_nominal_mm2',nom, ...
  'polyVsNominal_famA',geomA.polygonVsNominalRel(:).','polyVsNominal_alt',geom.polygonVsNominalRel(:).', ...
  'altVsFamA_bandAreaRel',(geom.annulusArea_mm2(:).'-geomA.annulusArea_mm2(:).')./geomA.annulusArea_mm2(:).', ...
  'bandVolumeFraction_famA',geomA.bandVolumeFraction,'bandVolumeFraction_alt',geom.bandVolumeFraction, ...
  'qClearance_famA_mm',geomA.qClearance_mm,'qClearance_alt_mm',geom.qClearance_mm,'tipToBand_alt_mm',geom.tipToBand_mm);
 fprintf('F2 alt T3 %d (famA %d); chords alt %s famA %s; band area rel alt-famA %s; exterior nodes coinciding %d/%d\n', ...
  size(RB.T3,1),size(DA.T3,1),mat2str(gcmp.chords_alt),mat2str(gcmp.chords_famA),mat2str(gcmp.altVsFamA_bandAreaRel,4),nnz(tf),numel(ext));
 L=stage(L,'F2_ALT_S0','PASS',struct('options',{optB},'audits',aud,'adapter',Ad.checks,'phase',struct('map',PM.pass,'verifier',V.pass,'negatives',NC.pass), ...
  'independence',ind,'geometry',gcmp,'joinSummary',RB.summary));
 L.status='FEASIBLE';
catch ME
 fprintf(2,'HOLD %s: %s\n',ME.identifier,ME.message);
 L.status='HOLD_ALT_S0';L.hold=struct('identifier',ME.identifier,'message',ME.message);
end
L.finished=datestr(now,31);
txt=jsonencode(L,'PrettyPrint',true);txt=strrep(txt,strrep(repo,'\','\\'),'<repo>');
fid=fopen(fullfile(folder,'FEASIBILITY.json'),'w');fwrite(fid,txt,'char');fclose(fid);
diary('off');
fl=dir(folder);fl=fl(~[fl.isdir]);fid=fopen(fullfile(folder,'SHA256SUMS.txt'),'w');
for k=1:numel(fl),if ~strcmp(fl(k).name,'SHA256SUMS.txt'),fprintf(fid,'%s *%s\n',lower(g2_sha256_file(fullfile(folder,fl(k).name))),fl(k).name);end,end
fclose(fid);
fprintf('G2_M4_FEASIBILITY_STATUS=%s FOLDER=%s\n',L.status,folder);
end

function L=stage(L,name,status,info)
s=struct('name',name,'status',status,'info',info);
L.stages{end+1}=s;
fprintf('STAGE %s %s\n',name,status);
end

function [h,d]=git(repo)
[~,h]=system(sprintf('git -C "%s" rev-parse HEAD',repo));[~,d]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all -- matlab/g2',repo));
h=strtrim(h);d=strtrim(d);
end
