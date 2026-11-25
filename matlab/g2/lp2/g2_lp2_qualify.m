function R=g2_lp2_qualify(outDir)
%G2_LP2_QUALIFY  LP2-A no-FEM (re)qualification after corrections C1-C3. Writes only outDir.
% 1 context + preflight; 2 GO_LP2A absent, no LP2-A run or ledger folder; 3 protected hashes before;
% 4 read-only S4 parent validation and S5 predictors (g2_lp2_s5_geometry, no mesh) compared with
%   the inherited original evidence docs/research/G2_LP2_evidence/LP2_S5_GEOMETRY.json;
% 5 provenance of the inherited mesh evidence (S5 probe, S6-S20 scan): the producing LP2 files
%   (forecast, classify, s5_geometry, mesh_probe, mesh_scan) must be byte-identical to those listed
%   in the original qualification, and the shared digest and parent pins unchanged; meshes are NOT
%   rebuilt; 6 contract tests incl. the non-solving campaign/verification tests and four dry calls;
%   7 protected hashes after. No physical solve. The real correct-token Run=true refusal probe with
%   no GO stays a mandatory activation-session check.
assert(~isfolder(outDir),'LP2Q:Out','Output folder exists.');mkdir(outDir);ram=struct('stage',{},'freeGiB',{});
C=g2_lp2_context();ram=obs(ram,'context');lp2=C.lp2;ev=fullfile(C.repo,'docs','research','G2_LP2_evidence');
assert(~isfile(fullfile(lp2,'G2_LP2A_SCIENTIFIC_GO_v1.json')),'LP2Q:GO','GO_LP2A must be absent.');
roots={fullfile(C.repo,'outputs','g2_lp2a_paths_v1'),fullfile(C.repo,'outputs','g2_lp2a_campaign_ledger')};
assert(~any(cellfun(@isfolder,roots)),'LP2Q:Runs','An LP2-A run or ledger folder exists.');
prot={'outputs/g2_lp1_matrix_paths_v1','outputs/g2_lp1_campaign_ledger','outputs/g2_a1_fixed_path_v1','outputs/g2_a1_campaign_ledger', ...
 'outputs/g2_a1_geometry_v1','outputs/g2_m5x6_crossed_v1','outputs/g2_m5x6_campaign_ledger'};
H0=treeHashes(C.repo,prot);ram=obs(ram,'protected_before');
% ---- S4 parents and S5 predictors versus the inherited evidence
S=g2_lp2_s5_geometry(C.repo,fullfile(outDir,'LP2_S5_GEOMETRY_recheck.json'));
O=jsondecode(fileread(fullfile(ev,'LP2_S5_GEOMETRY.json')));
same=true;for i=1:4
 a=S.rows(i);b=O.rows(i);
 same=same&&strcmp(a.caseId,b.caseId)&&strcmpi(a.a0StateSHA256,b.a0StateSHA256)&&isequal(a.S5_B0.polyline_mm,b.S5_B0.polyline_mm)&& ...
  isequal(a.S5_B0.tangent(:),b.S5_B0.tangent(:))&&strcmp(a.S5_geometry.classification,b.S5_geometry.classification)&& ...
  a.S5_geometry.kinkGatesPass==b.S5_geometry.kinkGatesPass&&a.outlook.frozenMTS.admissibleAdditionalStates==b.outlook.frozenMTS.admissibleAdditionalStates&& ...
  a.outlook.straight.admissibleAdditionalStates==b.outlook.straight.admissibleAdditionalStates;
end
ram=obs(ram,'s4_s5_recheck');
% ---- provenance of the inherited mesh evidence
Q1=jsondecode(fileread(fullfile(ev,'qualification_v1_86a88fa','LP2A_QUALIFICATION.json')));
old=containers.Map();for k=1:numel(Q1.lp2SourceLines),p=split(Q1.lp2SourceLines{k},' ');old(p{1})=p{2};end
dep={'g2_lp2_forecast.m','g2_lp2_classify.m','g2_lp2_s5_geometry.m','g2_lp2_mesh_probe.m','g2_lp2_mesh_scan.m'};
depOK=all(cellfun(@(f)isKey(old,f)&&strcmpi(old(f),g2_sha256_file(fullfile(lp2,f))),dep));
prov=struct('dependencies',{dep},'dependenciesUnchanged',depOK,'g2SourceUnchanged',strcmpi(Q1.g2SourceSHA256,C.g2SourceSHA256), ...
 'parentsUnchanged',strcmpi(Q1.parentManifestSHA256,C.parentManifestSHA256),'probeSHA256',lower(g2_sha256_file(fullfile(ev,'LP2_MESH_PROBE.json'))), ...
 'scanSHA256',lower(g2_sha256_file(fullfile(ev,'LP2_MESH_SCAN.json'))),'meshesRebuilt',false);
Mp=jsondecode(fileread(fullfile(ev,'LP2_MESH_PROBE.json')));Ms=jsondecode(fileread(fullfile(ev,'LP2_MESH_SCAN.json')));
pr=Mp.rows;if iscell(pr),p5=cellfun(@(r)strcmp(r.probe,'S5_candidate')&&r.pass,pr);else,p5=arrayfun(@(r)strcmp(r.probe,'S5_candidate')&&r.pass,pr);end
sc=Ms.rows;if iscell(sc),sc=[sc{:}];end;s68=sc([sc.state]<=8);
% ---- contract
T=g2_lp2_contract(C);ram=obs(ram,'contract');
H1=treeHashes(C.repo,prot);ram=obs(ram,'protected_after');unchanged=isequal(H0,H1);noRun=~any(cellfun(@isfolder,roots));
add=@(rows,n,k,o,p)[rows,struct('name',n,'kind',k,'expected','true','observed',o,'pass',p)];rows=T.rows;
rows=add(rows,'s4_parents_revalidated','wp1',mat2str([S.rows.a0EqualsLP1]&[S.rows.recurrenceReproducesA0]&[S.rows.a0RecordsVerify]), ...
 all([S.rows.a0EqualsLP1])&&all([S.rows.recurrenceReproducesA0])&&all([S.rows.a0RecordsVerify]));
rows=add(rows,'s5_predictors_identical_to_original','wp1',mat2str(same),same);
rows=add(rows,'inherited_mesh_evidence_provenance','mesh',sprintf('deps=%d g2=%d parents=%d',depOK,prov.g2SourceUnchanged,prov.parentsUnchanged), ...
 depOK&&prov.g2SourceUnchanged&&prov.parentsUnchanged);
rows=add(rows,'inherited_s5_meshes_4of4_and_s6_s8_24of24','mesh',sprintf('%d/4, %d/%d',nnz(p5),nnz([s68.pass]),numel(s68)),nnz(p5)==4&&numel(s68)==24&&all([s68.pass]));
rows=add(rows,'protected_trees_unchanged','closure',sprintf('%d files',size(H0,1)),unchanged);
rows=add(rows,'no_lp2a_folder_created','closure',mat2str(noRun),noRun);
neg=rows(strcmp({rows.expected},'error'));
E=struct('schema','NewMetacomp.G2.LP2A.ContractEvidence.v2','pass',all([rows.pass]),'passed',nnz([rows.pass]),'total',numel(rows), ...
 'negativeTests',numel(neg),'negativeTestsPassed',all([neg.pass]),'physicalSolves',0,'token',C.token,'policySHA256',C.policySHA256, ...
 'g2SourceSHA256',C.g2SourceSHA256,'lp2SourceSHA256',C.lp2SourceSHA256,'parentManifestSHA256',C.parentManifestSHA256, ...
 'sourceCommit',C.preflight.sourceCommit,'inheritedMeshEvidence',prov,'rows',rows);
fid=fopen(fullfile(outDir,'LP2A_CONTRACT.json'),'w');fwrite(fid,jsonencode(E,'PrettyPrint',true),'char');fclose(fid);
st='LP2A_PREFLIGHT_PASS_SCIENTIFIC_HOLD';if ~E.pass,st='HOLD_LP2A_PREFLIGHT';end
R=struct('schema','NewMetacomp.G2.LP2A.Qualification.v2','status',st,'sourceCommit',C.preflight.sourceCommit,'policySHA256',C.policySHA256, ...
 'g2SourceSHA256',C.g2SourceSHA256,'lp2SourceSHA256',C.lp2SourceSHA256,'lp2SourceLines',{C.lp2SourceLines}, ...
 'parentManifestSHA256',C.parentManifestSHA256,'token',C.token,'preflight',rmfield(C.preflight,intersect(fieldnames(C.preflight),{'matlabProcessInfo'})), ...
 'contractPassed',E.passed,'contractTotal',E.total,'negativeTests',E.negativeTests,'inheritedMeshEvidence',prov, ...
 'original',struct('sourceCommit',Q1.sourceCommit,'token',Q1.token,'policySHA256',Q1.policySHA256,'lp2SourceSHA256',Q1.lp2SourceSHA256,'contract',sprintf('%d/%d',Q1.contractPassed,Q1.contractTotal)), ...
 'protectedFilesHashed',size(H0,1),'protectedUnchanged',unchanged,'goPresent',false,'physicalSolves',0,'ramObservations',ram);
fid=fopen(fullfile(outDir,'LP2A_QUALIFICATION.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
fprintf('LP2A_QUALIFY %s contract=%d/%d (negatives %d) protected=%d unchanged=%d token=%s\n',st,E.passed,E.total,E.negativeTests,size(H0,1),unchanged,C.token);
end
function ram=obs(ram,stage)
[~,s]=memory;ram(end+1)=struct('stage',stage,'freeGiB',s.PhysicalMemory.Available/2^30);fprintf('RAM_OBSERVATION %s %.3f GiB\n',stage,ram(end).freeGiB);
end
function H=treeHashes(repo,roots)
H=cell(0,2);
for r=1:numel(roots)
 d=dir(fullfile(repo,strrep(roots{r},'/',filesep),'**','*'));d=d(~[d.isdir]);
 for k=1:numel(d),f=fullfile(d(k).folder,d(k).name);H(end+1,:)={strrep(strrep(f,[repo filesep],''),filesep,'/'),lower(g2_sha256_file(f))};end %#ok<AGROW>
end
H=sortrows(H,1);
end
