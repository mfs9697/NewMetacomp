function R=g2_a1_prephysical_batch(outDir)
%G2_A1_PREPHYSICAL_BATCH  A1 no-FEM qualification (Issue #66). Writes only outDir and outputs/.
% 1 context + preflight (clean tree, R2023a/PDE, one engine, >= 5 GiB); 2 regenerate the Family B
% candidates into the policy meshRoot if absent and require all twelve content SHA-256 values to
% equal G2_A1_POLICY_v1.json; 3 twelve dry runner calls; 4 check_g2_a1_contract; 5 a Run=true
% probe with the CORRECT token that must be refused by the absent A1 GO before any run folder
% or ledger entry. No physical solve.
assert(~isfolder(outDir),'G2A1Batch:Out','Output folder exists.');mkdir(outDir);
ram=struct('stage',{},'freeGiB',{});
C=g2_a1_context();ram=obs(ram,'context');pol=C.policy;
assert(~isfile(fullfile(C.here,'G2_A1_SCIENTIFIC_GO_v1.json')),'G2A1Batch:GO','A1 GO must be absent for this batch.');
meshRoot=fullfile(C.repo,strrep(pol.meshRoot,'/',filesep));
base=fileparts(fileparts(fileparts(fullfile(C.repo,strrep(pol.baselineS4.H.path,'/',filesep)))));
if ~isfolder(meshRoot),Q=g2_a1_geometry_qualification(base,meshRoot);else,Q=jsondecode(fileread(fullfile(meshRoot,'A1_GEOMETRY_QUALIFICATION.json')));end
assert(Q.pass,'G2A1Batch:Geometry','Geometry qualification failed.');
keys=fieldnames(pol.meshes);shaOK=true;
for k=1:numel(keys)
 parts=split(keys{k},'_B');M=load(fullfile(meshRoot,parts{1},['B' parts{2}],'MESH.mat'));
 shaOK=shaOK&&strcmp(g2_a1_mesh_content_sha(M),pol.meshes.(keys{k}).contentSHA256);
end
assert(shaOK&&numel(keys)==12,'G2A1Batch:MeshSHA','Regenerated meshes differ from the preregistration.');
ram=obs(ram,'geometry');
cases={'H','stiff13','soft2','soft1'};dry=0;
for c=1:4
 for m=[3 6 9]
  d=g2_a1_run('Case',cases{c},'Level',m);
  assert(strcmp(d.status,'DRY_READY_NO_FEM')&&d.computed==0&&strcmp(d.token,C.token),'G2A1Batch:Dry','Dry call failed.');dry=dry+1;
 end
end
ram=obs(ram,'dry');
T=check_g2_a1_contract(fullfile(C.repo,strrep(pol.baselineS4.H.path,'/',filesep)));
fid=fopen(fullfile(outDir,'CONTRACT_TESTS.json'),'w');fwrite(fid,jsonencode(T,'PrettyPrint',true),'char');fclose(fid);
ram=obs(ram,'contract');
runRoot=fullfile(C.repo,'outputs','g2_a1_fixed_path_v1');ledRoot=fullfile(C.repo,'outputs','g2_a1_campaign_ledger');
b=[listing(runRoot);listing(ledRoot)];probe=['run_a1_probe_',datestr(now,'yyyymmddTHHMMSSFFF')];id='<no error>';msg='';
try
 g2_a1_run('Case','H','Level',3,'Run',true,'AuthToken',C.token,'RunName',probe);
catch ME
 id=ME.identifier;msg=ME.message;
end
refused=strcmp(id,'G2A1:HOLD_UNAUTHORIZED_STATE')&&contains(msg,'no separate A1 GO')&&isequal(b,[listing(runRoot);listing(ledRoot)]);
assert(refused,'G2A1Batch:Guard','No-GO refusal failed (%s).',id);
ram=obs(ram,'end');
R=struct('schema','NewMetacomp.G2.A1.PrephysicalBatch.v1','status','A1_TESTS_PASS_SCIENTIFIC_HOLD', ...
 'sourceCommit',C.preflight.sourceCommit,'policySHA256',C.policySHA256,'sourceSHA256',C.sourceSHA256, ...
 'meshManifestSHA256',C.meshManifestSHA256,'token',C.token,'geometryRows',numel(Q.rows),'meshContentSHAEqual',shaOK, ...
 'dryCalls',dry,'contractPassed',T.passed,'contractTotal',T.total,'refusalIdentifier',id,'ramObservations',ram, ...
 'physicalSolves',0,'scientificGO',false);
fid=fopen(fullfile(outDir,'PREPHYSICAL_RESULT.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
fprintf('G2_A1_PREPHYSICAL_PASS geometry=%d meshSHA=%d dry=%d contract=%d/%d refusal=%s token=%s\n', ...
 numel(Q.rows),shaOK,dry,T.passed,T.total,id,C.token);
end

function ram=obs(ram,stage)
[~,s]=memory;ram(end+1)=struct('stage',stage,'freeGiB',s.PhysicalMemory.Available/2^30);
fprintf('RAM_OBSERVATION %s %.6f GiB\n',stage,ram(end).freeGiB);
end
function L=listing(folder)
if ~isfolder(folder),L={};return,end
d=dir(fullfile(folder,'**','*'));L=sort(strcat({d.folder},filesep,{d.name}))';
end
