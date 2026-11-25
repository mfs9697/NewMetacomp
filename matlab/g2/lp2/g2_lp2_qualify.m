function R=g2_lp2_qualify(outDir)
%G2_LP2_QUALIFY  LP2-A no-FEM qualification. Writes only outDir.
% 1 context + preflight; 2 GO_LP2A absent, no LP2-A run or ledger folder; 3 protected hashes before;
% 4 WP1 S4 audit and S5 geometry (g2_lp2_s5_geometry); 5 mesh probe (S5 candidates) and vertex
% scan (synthetic outlook polylines) with the unchanged mesher, meshes in memory only; 6 contract
% tests (includes four dry driver calls); 7 protected hashes after. No physical solve; the real
% Run=true refusal probe is left to the GO session (this preparation must not invoke it).
assert(~isfolder(outDir),'LP2Q:Out','Output folder exists.');mkdir(outDir);ram=struct('stage',{},'freeGiB',{});
C=g2_lp2_context();ram=obs(ram,'context');lp2=C.lp2;
assert(~isfile(fullfile(lp2,'G2_LP2A_SCIENTIFIC_GO_v1.json')),'LP2Q:GO','GO_LP2A must be absent.');
roots={fullfile(C.repo,'outputs','g2_lp2a_paths_v1'),fullfile(C.repo,'outputs','g2_lp2a_campaign_ledger')};
assert(~any(cellfun(@isfolder,roots)),'LP2Q:Runs','An LP2-A run or ledger folder exists.');
prot={'outputs/g2_lp1_matrix_paths_v1','outputs/g2_lp1_campaign_ledger','outputs/g2_a1_fixed_path_v1','outputs/g2_a1_campaign_ledger', ...
 'outputs/g2_a1_geometry_v1','outputs/g2_m5x6_crossed_v1','outputs/g2_m5x6_campaign_ledger'};
H0=treeHashes(C.repo,prot);ram=obs(ram,'protected_before');
gj=fullfile(outDir,'LP2_S5_GEOMETRY.json');S=g2_lp2_s5_geometry(C.repo,gj);ram=obs(ram,'s5_geometry');
Mp=g2_lp2_mesh_probe(C.repo,gj,fullfile(outDir,'LP2_MESH_PROBE.json'));ram=obs(ram,'mesh_probe');
Ms=g2_lp2_mesh_scan(C.repo,gj,fullfile(outDir,'LP2_MESH_SCAN.json'));ram=obs(ram,'mesh_scan');
T=g2_lp2_contract(C);ram=obs(ram,'contract');
H1=treeHashes(C.repo,prot);ram=obs(ram,'protected_after');unchanged=isequal(H0,H1);noRun=~any(cellfun(@isfolder,roots));
s5=[S.rows.S5_geometry];isS5=cellfun(@(r)strcmp(r.probe,'S5_candidate'),Mp.rows);
p5=struct('pass',cellfun(@(r)r.pass,Mp.rows(isS5),'UniformOutput',false));scan=[Ms.rows{:}];
add=@(rows,n,k,o,p)[rows,struct('name',n,'kind',k,'expected','true','observed',o,'pass',p)];rows=T.rows;
rows=add(rows,'s4_a0_equals_lp1_and_recurrence','wp1',mat2str([S.rows.a0EqualsLP1]&[S.rows.recurrenceReproducesA0]),all([S.rows.a0EqualsLP1])&&all([S.rows.recurrenceReproducesA0])&&all([S.rows.a0RecordsVerify]));
rows=add(rows,'s5_candidates_matrix_advance_and_kink_gates','wp1',strjoin({s5.classification},','),all(strcmp({s5.classification},'MATRIX_ADVANCE'))&&all([s5.kinkGatesPass]));
rows=add(rows,'s5_candidate_meshes_audit_34of34','mesh',sprintf('%d/4',nnz([p5.pass])),numel(p5)==4&&all([p5.pass]));
sq=scan([scan.state]<=8);rows=add(rows,'synthetic_S6_S8_meshes_pass','mesh',sprintf('%d/%d',nnz([sq.pass]),numel(sq)),~isempty(sq)&&all([sq.pass]));
rows=add(rows,'protected_trees_unchanged','closure',sprintf('%d files',size(H0,1)),unchanged);
rows=add(rows,'no_lp2a_folder_created','closure',mat2str(noRun),noRun);
neg=rows(strcmp({rows.expected},'error'));
E=struct('schema','NewMetacomp.G2.LP2A.ContractEvidence.v1','pass',all([rows.pass]),'passed',nnz([rows.pass]),'total',numel(rows), ...
 'negativeTests',numel(neg),'negativeTestsPassed',all([neg.pass]),'physicalSolves',0,'token',C.token,'policySHA256',C.policySHA256, ...
 'g2SourceSHA256',C.g2SourceSHA256,'lp2SourceSHA256',C.lp2SourceSHA256,'parentManifestSHA256',C.parentManifestSHA256, ...
 'sourceCommit',C.preflight.sourceCommit,'rows',rows);
fid=fopen(fullfile(outDir,'LP2A_CONTRACT.json'),'w');fwrite(fid,jsonencode(E,'PrettyPrint',true),'char');fclose(fid);
st='LP2A_PREFLIGHT_PASS_SCIENTIFIC_HOLD';if ~E.pass,st='HOLD_LP2A_PREFLIGHT';end
scanByState=arrayfun(@(k)struct('state',k,'pass',nnz([scan([scan.state]==k).pass]),'total',nnz([scan.state]==k)),unique([scan.state]));
R=struct('schema','NewMetacomp.G2.LP2A.Qualification.v1','status',st,'sourceCommit',C.preflight.sourceCommit,'policySHA256',C.policySHA256, ...
 'g2SourceSHA256',C.g2SourceSHA256,'lp2SourceSHA256',C.lp2SourceSHA256,'lp2SourceLines',{C.lp2SourceLines}, ...
 'parentManifestSHA256',C.parentManifestSHA256,'token',C.token,'preflight',rmfield(C.preflight,intersect(fieldnames(C.preflight),{'matlabProcessInfo'})), ...
 'contractPassed',E.passed,'contractTotal',E.total,'meshScanByState',scanByState,'protectedFilesHashed',size(H0,1),'protectedUnchanged',unchanged, ...
 'goPresent',false,'physicalSolves',0,'ramObservations',ram);
fid=fopen(fullfile(outDir,'LP2A_QUALIFICATION.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
fprintf('LP2A_QUALIFY %s contract=%d/%d protected=%d files unchanged=%d token=%s\n',st,E.passed,E.total,size(H0,1),unchanged,C.token);
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
