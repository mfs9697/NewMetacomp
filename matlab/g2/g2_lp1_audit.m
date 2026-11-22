function [A,PM]=g2_lp1_audit(D,k,C)
% Re-audit arrays and actual mask geometry on compute AND replay, without FEM.
repo=C.repo;here=C.here;pol=C.policy;
j=fullfile(repo,'docs/research/crack-growth-gaps-2026/G2_SPECIMEN1_1990_GEOMETRY.json');
p0=fullfile(repo,'outputs/g2_p010_isolated/run_20261118_163657_790/P010_ISOLATED_REGULAR_ONLY.mat');
if k==0
 Q=g2_independent_t6_checker(D,j);T=g2_protected_tip_checker(D,j,p0);
 assert(Q.pass&&Q.gatesPassed==38&&T.pass&&T.gatesPassed==24,'G2LP1:HOLD_MESH_QUALITY','S0 audit failed.');
else
 Q=g2_kinked_mesh_auditor(D,j,p0,k+2);assert(Q.pass&&Q.gatesPassed==34,'G2LP1:HOLD_MESH_QUALITY','Kinked audit failed.');
end
assert(size(D.T3,1)<=40000,'G2LP1:HOLD_MESH_QUALITY','T3 budget.');
[~,V]=g2_m2_state_adapter(D,'LP1',D.crackPolyline);assert(V.pass,'G2LP1:HOLD_OWNER_MASK','Bank/schema adapter failed.');
A=g2_lp0_phase_audit(D,D.crackPolyline,pol);assert(A.pass,'G2LP1:HOLD_OWNER_MASK','Phase or activity qualification failed.');
pm=jsondecode(fileread(fullfile(here,'G2_MATERIAL_POLICY_v1.json')));
g=pol.geometry;PM=g2_material_phase_map(D.X6,D.T6,g.centres_mm,6.35*ones(3,1),19.05*ones(3,1), ...
 struct('onCircleTol_mm',pm.phaseMap.onCircleTolerance_mm,'minGap_mm',pm.phaseMap.minGapToNextT3Vertex_mm,'midsideTol_mm',pm.phaseMap.midsideOnChordTolerance_mm));
assert(PM.pass,'G2LP1:HOLD_OWNER_MASK','Phase re-map failed.');A.meshAudit=Q;
end
