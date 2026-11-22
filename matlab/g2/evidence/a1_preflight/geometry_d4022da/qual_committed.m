repo='<repo>';cd(repo);
addpath(fullfile(repo,'matlab','g2'),'-begin');addpath(fullfile(repo,'matlab','g2','vendor_p010_a14d8872'),'-begin');
hist=fullfile(repo,'outputs','g2_lp1_matrix_paths_v1','run_20261122_lp1_v1');
a0=fullfile(repo,'outputs','g2_lp1_matrix_paths_v1','run_a0_lp1_repro_v1');
cases={'H','stiff13','soft2','soft1'};
for c=1:4
 Dh=load(fullfile(hist,cases{c},'S4','MESH.mat'));Da=load(fullfile(a0,cases{c},'S4','MESH.mat'));
 fprintf('BASELINE %s historicalContent=%s a0Content=%s equal=%d\n',cases{c},g2_a1_mesh_content_sha(Dh),g2_a1_mesh_content_sha(Da), ...
  strcmp(g2_a1_mesh_content_sha(Dh),g2_a1_mesh_content_sha(Da)));
end
R=g2_a1_geometry_qualification(hist,fullfile(repo,'outputs','g2_a1_geometry_v1'));
for i=1:numel(R.rows),r=R.rows(i);fprintf('MESHSHA %s_B%d content=%s file=%s\n',r.caseId,r.m,r.contentSHA256,r.fileSHA256);end
