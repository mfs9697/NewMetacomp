function S = g2_material_case_summary(id,K,SH,loadNode,polT,ratio)
%G2_MATERIAL_CASE_SUMMARY  Case record used by the material ratio table (Issue #36).
% Verbatim copy of the local function summ() of run_g2_material_contrast_batch.m
% (PR #35, unchanged there): K is a g2_trajectory_sif_on_mesh (H1, with SH the
% homogeneous solve) or g2_material_sif_on_mesh (SH = []) output.
s1k=sqrt(1000);
S=struct('id',id,'ratio',ratio,'pass',K.pass,'KI_raw',K.KI,'KII_raw',K.KII,'KI_COD_raw',K.KI_COD,'KII_COD_raw',K.KII_COD, ...
 'EDI_all',K.EDI_all,'EDI4x4',K.EDI4x4,'J',K.J,'KI_perkN',K.KI_MPa_sqrt_m_per_kN,'KII_perkN',K.KII_MPa_sqrt_m_per_kN, ...
 'KI_COD_perkN',K.KI_COD*s1k,'KII_COD_perkN',K.KII_COD*s1k,'criteria',K.criteria,'relativeResidual',K.relativeResidual, ...
 'staticsMax',K.staticsMax,'fullPolyOpeningMin_mm',K.fullPolyOpeningMin_mm);
if ~isempty(SH)
 S.strainEnergy_per_thickness=SH.strainEnergy;S.compliance_mm_per_N=abs(SH.u(2*loadNode))/polT.bvp.P_N;
 S.reactions=SH.reactions;S.phaseStrainEnergy_per_thickness=SH.strainEnergy;
 U=K.fullPolyOpening_mm;[~,im]=min(K.wholeCrackArclength_mm);S.CMOD_mm=U(im);
 S.interfaceBalanceRel=NaN;S.annulusResultantRel=NaN;S.interfaceSideL2Rel=NaN(3,1);S.chordTractions={};
else
 S.strainEnergy_per_thickness=K.strainEnergy_per_thickness;S.compliance_mm_per_N=K.compliance_mm_per_N;
 S.reactions=K.reactions;S.phaseStrainEnergy_per_thickness=K.phaseStrainEnergy_per_thickness;S.CMOD_mm=K.CMOD_mm;
 S.interfaceBalanceRel=K.interfaceBalanceRel;S.annulusResultantRel=K.annulusResultantRel;S.interfaceSideL2Rel=K.interfaceSideL2Rel;
 S.chordTractions=K.chordTractions;
end
S.Ep_matrix=polT.bvp.E_MPa;S.thickness_mm=polT.bvp.thickness_mm;
end
