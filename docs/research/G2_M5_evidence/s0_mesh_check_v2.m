function s0_mesh_check_v2(repo,outJson)
%S0_MESH_CHECK_V2  M5 correction C1: machine-readable S0 mesh identity (plain load, no FEM).
%  s0_mesh_check_v2(repo,outJson)
% For the four LP1 S0 meshes (historical run run_20261122_lp1_v1, bitwise equal to the A0 rerun):
% raw MAT-file SHA-256, mesh content SHA-256 (g2_a1_mesh_content_sha over X3,T3,X6,T6, banks, tip,
% nodalQ, q rows, extra vertices, collar IDs) and element-by-element isequaln of every stored field
% against H. Writes a path-free JSON; the Python analysis derives its flags from this file.
addpath(fullfile(repo,'matlab','g2'),'-begin');
rel='outputs/g2_lp1_matrix_paths_v1/run_20261122_lp1_v1';cs={'H','stiff13','soft2','soft1'};
M=cell(1,4);R=struct('case',{},'meshFile',{},'rawMatFileSHA256',{},'meshContentSHA256',{},'fieldsCompared',{},'differingFieldsVsH',{},'arraysIdenticalToH',{});
for k=1:4
 p=fullfile(repo,strrep(rel,'/',filesep),cs{k},'S0','MESH.mat');M{k}=load(p);
end
f=fieldnames(M{1});
for k=1:4
 d={};for j=1:numel(f),if ~(isfield(M{k},f{j})&&isequaln(M{1}.(f{j}),M{k}.(f{j}))),d{end+1}=f{j};end,end %#ok<AGROW>
 extra=setdiff(fieldnames(M{k}),f);d=[d,extra(:).'];
 R(k)=struct('case',cs{k},'meshFile',[rel '/' cs{k} '/S0/MESH.mat'], ...
  'rawMatFileSHA256',lower(g2_sha256_file(fullfile(repo,strrep(rel,'/',filesep),cs{k},'S0','MESH.mat'))), ...
  'meshContentSHA256',g2_a1_mesh_content_sha(M{k}),'fieldsCompared',numel(f),'differingFieldsVsH',{d},'arraysIdenticalToH',isempty(d));
 fprintf('S0 %-8s raw=%s content=%s differing={%s}\n',cs{k},R(k).rawMatFileSHA256(1:16),R(k).meshContentSHA256(1:16),strjoin(d,','));
end
O=struct('schema','NewMetacomp.G2.M5.S0MeshContentCheck.v1','noFEM',true,'fieldNames',{f.'},'cases',R);
fid=fopen(outJson,'w');fwrite(fid,jsonencode(O,'PrettyPrint',true),'char');fclose(fid);
fprintf('S0_CHECK_V2_DONE\n');
end
