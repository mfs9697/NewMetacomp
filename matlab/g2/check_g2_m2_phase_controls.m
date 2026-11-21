function C = check_g2_m2_phase_controls(D,PM,geo,vopts)
%CHECK_G2_M2_PHASE_CONTROLS  State-aware phase negative controls for Issue #36 (wraps PR #35, unchanged).
%
%  C = check_g2_m2_phase_controls(D,PM,geo,vopts)
% Runs check_g2_material_phase_controls (PR #35, byte-identical) unchanged. Its N7 uses a
% FIXED q radius of 45 mm, designed at State 2 (nearest band node 42.14 mm from the tip).
% At other tips the band can be farther (S0: about 48.45 mm), so a 45 mm domain does not
% cross a band there and the verifier correctly accepts it (M2 run A HOLD, see
% G2_M2_RUNLOG.md). This wrapper:
%  - requires every other PR #35 case to be rejected, as before;
%  - requires the PR #35 N7 verdict to match geometry: rejected iff 45 mm > tip-to-band
%    distance (the verifier must neither miss a real crossing nor invent one);
%  - adds N7s: a q radius of (tip-to-band distance + 1 mm), which always reaches a band,
%    and must be rejected.
NC=check_g2_material_phase_controls(D,PM,geo,vopts);
tip=vopts.tip(:).';rN=vecnorm(D.X6-tip,2,2);
band=unique(D.T6(PM.phase==2,:));dBand=min(rN(band));
names={NC.cases.name};i7=find(strcmp(names,'N7_q_domain_crossing_band'));
others=setdiff(1:numel(NC.cases),i7);
okOthers=all([NC.cases(others).rejected]);
n7Expected=45>dBand;n7Observed=NC.cases(i7).rejected;
o=vopts;o.qOuterRadii_mm=[vopts.qOuterRadii_mm(:);dBand+1];
V=g2_material_phase_verify(D.X6,D.T6,PM.phase,geo.centers,geo.holeR,geo.interfaceR,o);
n7s=~V.pass&&any(strcmp(V.failed,'qSupportMatrixOnly'));
C=struct('pass',okOthers&&(n7Observed==n7Expected)&&n7s,'pr35',NC,'tipToBand_mm',dBand, ...
 'N7_fixed45_expectedRejected',n7Expected,'N7_fixed45_observedRejected',n7Observed, ...
 'N7s_radius_mm',dBand+1,'N7s_rejected',n7s,'N7s_verifierFailed',{V.failed},'otherCasesRejected',okOthers);
C.cases=NC.cases;
fprintf('M2_PHASE_NEG tip-to-band %.3f mm: PR35 N7(45 mm) expected rejected=%d observed=%d; N7s(%.3f mm) rejected=%d; others rejected=%d -> pass=%d\n', ...
 dBand,n7Expected,n7Observed,dBand+1,n7s,okOthers,C.pass);
end
