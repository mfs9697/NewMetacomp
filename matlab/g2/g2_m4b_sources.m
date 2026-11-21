function [S,setSHA] = g2_m4b_sources(here)
%G2_M4B_SOURCES  Hashed computation sources of G2-M4.B and their source-set SHA-256 (Issue #47).
%
%  [S,setSHA] = g2_m4b_sources(here)
% S: struct array (file, sha256). setSHA: SHA-256 of the newline-joined "file sha" lines
% in the fixed order below (computed by writing them to a temporary file). The set
% covers the controller, the new activation/oracle/verifier/SIF modules and every
% legacy module they call; analysis/report/fault scripts are not part of it (they
% are covered by the clean-tree rule and their own evidence hashes).
if nargin<1||isempty(here),here=fileparts(mfilename('fullpath'));end
files={'g2_m4b_campaign.m','g2_m4b_sources.m','g2_m4b_ring_owner_oracle.m','g2_m4b_ring_activation.m', ...
 'g2_m4b_activation_verify.m','g2_m4b_interface_balance.m','g2_m4b_sif_partial.m','check_g2_m4b_activation_negatives.m', ...
 'G2_M4B_POLICY_v2.json', ...
 'g2_t6_elasticity_phase.m','g2_material_phase_map.m','g2_material_phase_verify.m','g2_material_sif_on_mesh.m', ...
 'g2_t6_point_stress.m','check_g2_material_phase_controls.m','check_g2_m2_phase_controls.m','g2_t6_elasticity.m', ...
 'g2_trajectory_sif_on_mesh.m','g2_sif_interaction.m','g2_sif_cod_banks.m','g2_sif_cod.m','g2_williams_field.m', ...
 'g2_plane_D.m','g2_mts_direction.m','g2_kinked_mesh_auditor.m','g2_m2_state_adapter.m','g2_material_case_summary.m', ...
 'g2_material_ratio_table.m','g2_trajectory_record.m','g2_sha256_file.m'};
S=struct('file',files,'sha256','');
lines=cell(numel(files),1);
for k=1:numel(files)
 p=fullfile(here,files{k});
 assert(isfile(p),'G2M4B:SourceMissing','Missing source %s.',files{k});
 S(k).sha256=lower(g2_sha256_file(p));lines{k}=[files{k},' ',S(k).sha256];
end
tmp=[tempname,'.txt'];fid=fopen(tmp,'w');fwrite(fid,strjoin(lines,newline),'char');fclose(fid);
setSHA=lower(g2_sha256_file(tmp));delete(tmp);
end
