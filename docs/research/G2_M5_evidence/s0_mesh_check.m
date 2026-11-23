% M5: are the four LP1 S0 meshes array-identical? (plain load, no FEM)
repo='<repo>';addpath(fullfile(repo,'matlab','g2'),'-begin');
r=fullfile(repo,'outputs','g2_lp1_matrix_paths_v1','run_20261122_lp1_v1');cs={'H','stiff13','soft2','soft1'};
M=cell(1,4);for k=1:4,M{k}=load(fullfile(r,cs{k},'S0','MESH.mat'));end
f=fieldnames(M{1});fprintf('FIELDS %s\n',strjoin(f.',','));
for k=2:4
 same={};diff={};
 for j=1:numel(f)
  if isfield(M{k},f{j})&&isequaln(M{1}.(f{j}),M{k}.(f{j})),same{end+1}=f{j};else,diff{end+1}=f{j};end %#ok<AGROW>
 end
 fprintf('S0 %s vs H: differing fields = {%s}\n',cs{k},strjoin(diff,','));
 fprintf('S0 %s contentSHA equal = %d\n',cs{k},strcmp(g2_a1_mesh_content_sha(M{1}),g2_a1_mesh_content_sha(M{k})));
end
exit(0);
