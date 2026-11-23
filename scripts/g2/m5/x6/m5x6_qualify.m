function R=m5x6_qualify(outDir)
%M5X6_QUALIFY  M5-X6 no-FEM qualification. Writes only outDir (and removes its own temp folders).
% 1 context + preflight (clean tree, R2023a/PDE, one engine, >= 5 GiB, A1 and plan pins);
% 2 GO_M5_X6 absent and no M5-X6 run or ledger folder; 3 protected-tree hashes before;
% 4 WP1.1 audit of the four A1 B9 diagonal solutions; 5 six dry driver calls (static mesh,
% polyline, phase-map and swapped-activation checks); 6 contract tests; 7 protected-tree hashes
% after and no M5-X6 folder created. The end-to-end Run=true refusal probe used for A1 is NOT
% executed here, because this preparation must not invoke the execution path; the gate is tested
% directly instead. No physical solve.
assert(~isfolder(outDir),'M5X6Q:Out','Output folder exists.');mkdir(outDir);
ram=struct('stage',{},'freeGiB',{});
C=g2_m5x6_context();ram=obs(ram,'context');
assert(~isfile(fullfile(C.x6,'G2_M5_X6_SCIENTIFIC_GO_v1.json')),'M5X6Q:GO','GO_M5_X6 must be absent for qualification.');
x6roots={fullfile(C.repo,'outputs','g2_m5x6_crossed_v1'),fullfile(C.repo,'outputs','g2_m5x6_campaign_ledger')};
assert(~any(cellfun(@isfolder,x6roots)),'M5X6Q:Runs','An M5-X6 run or ledger folder already exists.');
prot={'outputs/g2_a1_fixed_path_v1','outputs/g2_a1_campaign_ledger','outputs/g2_a1_geometry_v1','outputs/g2_lp1_matrix_paths_v1'};
H0=treeHashes(C.repo,prot);ram=obs(ram,'protected_before');
A=m5x6_audit_diagonal(C,fullfile(outDir,'M5X6_DIAGONAL_AUDIT.json'));ram=obs(ram,'diagonal_audit');
dry=cell(1,6);
for k=1:6
 d=g2_m5x6_run('Config',C.configurations(k).id);
 assert(strcmp(d.status,'DRY_READY_NO_FEM')&&d.computed==0&&strcmp(d.token,C.token),'M5X6Q:Dry','Dry call %s failed.',C.configurations(k).id);
 dry{k}=d.check;
 fprintf('M5X6_DRY %s %s path=%s material=%s mask=%s ratio=%g active=%d jump=%d qClear=%.3f mesh=%s\n',d.config,d.status, ...
  d.check.pathCase,d.check.materialCase,d.check.mask,d.check.ratio,d.check.activeElements,d.check.jumpEdges,d.check.qClearance_mm,d.check.meshGates);
end
dry=[dry{:}];ram=obs(ram,'dry');
T=check_m5x6_contract(C);ram=obs(ram,'contract');
H1=treeHashes(C.repo,prot);ram=obs(ram,'protected_after');
unchanged=isequal(H0,H1);noX6=~any(cellfun(@isfolder,x6roots));
add=@(rows,n,k,o,p)[rows,struct('name',n,'kind',k,'expected','true','observed',o,'pass',p)];
rows=T.rows;
for k=1:4,rows=add(rows,['diagonal_audit_' A.rows(k).key],'audit',mat2str(A.rows(k).pass),A.rows(k).pass);end
rows=add(rows,'diagonal_ring_areas_equal_across_meshes','audit',sprintf('%.3g',A.ringAreaEqualAcrossMeshes_maxRelDiff),A.ringAreaEqualAcrossMeshes_maxRelDiff<=1e-12);
for k=1:6,rows=add(rows,['dry_static_check_' dry(k).id],'dry',mat2str(dry(k).pass),dry(k).pass);end
rows=add(rows,'protected_trees_unchanged','closure',sprintf('%d files',numel(H0)),unchanged);
rows=add(rows,'no_m5x6_run_or_ledger_folder_created','closure',mat2str(noX6),noX6);
neg=rows(strcmp({rows.expected},'error'));
E=struct('schema','NewMetacomp.G2.M5X6.ContractEvidence.v1','pass',all([rows.pass]),'passed',nnz([rows.pass]),'total',numel(rows), ...
 'negativeTests',numel(neg),'negativeTestsPassed',all([neg.pass]),'physicalSolves',0,'token',C.token, ...
 'planSHA256',C.planSHA256,'a1SourceSHA256',C.a1SourceSHA256,'x6SourceSHA256',C.x6SourceSHA256, ...
 'meshManifestSHA256',C.meshManifestSHA256,'sourceCommit',C.preflight.sourceCommit,'rows',rows);
fid=fopen(fullfile(outDir,'M5X6_CONTRACT.json'),'w');fwrite(fid,jsonencode(E,'PrettyPrint',true),'char');fclose(fid);
st='M5X6_PREFLIGHT_PASS_SCIENTIFIC_HOLD';if ~E.pass,st='HOLD_M5_X6_PREFLIGHT';end
R=struct('schema','NewMetacomp.G2.M5X6.Qualification.v1','status',st,'sourceCommit',C.preflight.sourceCommit, ...
 'planSHA256',C.planSHA256,'a1PolicySHA256',C.a1.policySHA256,'a1SourceSHA256',C.a1SourceSHA256,'x6SourceSHA256',C.x6SourceSHA256, ...
 'x6SourceLines',{C.x6SourceLines},'meshManifestSHA256',C.meshManifestSHA256,'token',C.token, ...
 'preflight',rmfield(C.preflight,intersect(fieldnames(C.preflight),{'matlabProcessInfo'})), ...
 'diagonalAuditAllPass',A.allPass,'dryChecks',dry,'contractPassed',E.passed,'contractTotal',E.total, ...
 'protectedFilesHashed',numel(H0),'protectedUnchanged',unchanged,'noM5X6FolderCreated',noX6, ...
 'goPresent',false,'physicalSolves',0,'scientificGO',false,'ramObservations',ram);
fid=fopen(fullfile(outDir,'M5X6_QUALIFICATION.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
fprintf('M5X6_QUALIFY %s audit=%d dry=6 contract=%d/%d protected=%d files unchanged=%d token=%s\n', ...
 st,A.allPass,E.passed,E.total,numel(H0),unchanged,C.token);
end

function ram=obs(ram,stage)
[~,s]=memory;ram(end+1)=struct('stage',stage,'freeGiB',s.PhysicalMemory.Available/2^30);
fprintf('RAM_OBSERVATION %s %.6f GiB\n',stage,ram(end).freeGiB);
end
function H=treeHashes(repo,roots)
H=cell(0,2);
for r=1:numel(roots)
 d=dir(fullfile(repo,strrep(roots{r},'/',filesep),'**','*'));d=d(~[d.isdir]);
 for k=1:numel(d)
  f=fullfile(d(k).folder,d(k).name);H(end+1,:)={strrep(strrep(f,[repo filesep],''),filesep,'/'),lower(g2_sha256_file(f))}; %#ok<AGROW>
 end
end
H=sortrows(H,1);
end
