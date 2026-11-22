% Read-only A0 comparison: preregistered tiers A-D (scripts/g2/a0/a0_compare_records.m) and an
% SR1 full-field extract of the new run plus independent mesh quality. No project computation.
repo='<repo>';
addpath(fullfile(repo,'scripts','g2','a0'));addpath(fullfile(repo,'scripts','g2','sr1'));
hist=fullfile(repo,'outputs','g2_lp1_matrix_paths_v1','run_20261122_lp1_v1');
new=fullfile(repo,'outputs','g2_lp1_matrix_paths_v1','run_a0_lp1_repro_v1');
o='<scratch>/a0x/';
R=a0_compare_records(hist,new,[o 'A0_COMPARISON.json']);
for i=1:numel(R.states)
 s=R.states(i);d=s.maxDiff;
 if isempty(fieldnames(d)),fprintf('STATE %s tier=%s reasons=%s\n',s.state,s.tier,strjoin(s.reasons,';'));continue,end
 fprintf('STATE %s tier=%s int=%d coord=%.3g K=%.3g G=%.3g MTS=%.3g EDI=%.3g COD=%.3g J=%.3g u=%.3g comp=%.3g clear=%.3g\n', ...
  s.state,s.tier,s.integerArraysEqual,d.coord_mm,d.K_rel,d.G_rel,d.MTS_deg,d.EDI_rel,d.COD_rel,d.J_rel,d.u_rel,d.compliance_rel,d.clearance_mm);
end
fprintf('PROVENANCE pass=%d notes=%s\n',R.provenance.pass,strjoin(R.provenance.notes,' ; '));
fprintf('A0_VERDICT %s worstTier=%s classesUnchanged=%d dFG=%.3g dOff=%.3g\n',R.verdict,R.worstTier,R.classesUnchanged, ...
 R.classesNew.maxAbsDeltaFG,R.classesNew.maxAbsDeltaOffset_mm);
sr1_extract_records(new,[o 'A0_NEW_records_full.json']);
sr1_mesh_quality(new,[o 'A0_NEW_mesh_quality.json']);
