function T = g2_material_ratio_table(H,Ms,pol,tangent)
%G2_MATERIAL_RATIO_TABLE  R_mat, both uncertainty verdicts, mixity, MTS steering (Issue #36).
%
%  T = g2_material_ratio_table(H,Ms,pol,tangent)
% H, Ms: g2_material_case_summary records (H1 and the phase cases of ONE state/mesh).
% pol: a policy with uncertainty.coverageFactor. tangent: that state's terminal unit tangent.
% The core computation is a verbatim copy of the local function ratios() of
% run_g2_material_contrast_batch.m (PR #35). Appended fields (Issue #36): global
% tangent angle, global MTS direction, and an independent bracketed MTS root check.
E=H.Ep_matrix;G=@(k)(k(:,1).^2+k(:,2).^2)/E;
mts=@(KI,KII)g2_mts_direction(KI,KII).theta_deg;s1k=sqrt(1000);
gH=G(H.EDI_all(:,1:2));gH4=G(H.EDI4x4);gHc=G([H.KI_COD_raw,H.KII_COD_raw]);thH=mts(H.KI_perkN,H.KII_perkN);
thHc=mts(H.KI_COD_perkN,H.KII_COD_perkN);thH4=mts(H.EDI4x4(1)*s1k,H.EDI4x4(2)*s1k);
thHall=arrayfun(@(c)mts(H.EDI_all(c,1)*s1k,H.EDI_all(c,2)*s1k),1:5).';
cf=pol.uncertainty.coverageFactor;
tg=atan2d(tangent(2),tangent(1));
T=struct([]);
for i=1:numel(Ms)
 M=Ms(i);gM=G(M.EDI_all(:,1:2));gM4=G(M.EDI4x4);gMc=G([M.KI_COD_raw,M.KII_COD_raw]);
 Rc=gM./gH;R=Rc(1);R4=gM4/gH4;Rcod=gMc/gHc;Rj=M.J/H.J;
 UR=max([max(abs(Rc-R)),abs(R4-R),abs(Rcod-R)]);
 dGM=abs(gM(1)-gMc)/gM(1);dGH=abs(gH(1)-gHc)/gH(1);Ucons=R*(dGM+dGH);
 resolved=abs(R-1)>cf*UR&&sign(Rcod-1)==sign(R-1);
 resolvedCons=abs(R-1)>Ucons&&sign(Rcod-1)==sign(R-1);
 uKII=max([abs(M.KII_raw-M.KII_COD_raw),max(M.EDI_all(:,2))-min(M.EDI_all(:,2)),abs(M.EDI4x4(2)-M.KII_raw)]);
 kiiRes=abs(M.KII_raw)>uKII&&sign(M.KII_COD_raw)==sign(M.KII_raw);
 th=mts(M.KI_perkN,M.KII_perkN);thc=mts(M.KI_COD_perkN,M.KII_COD_perkN);th4=mts(M.EDI4x4(1)*s1k,M.EDI4x4(2)*s1k);
 thall=arrayfun(@(c)mts(M.EDI_all(c,1)*s1k,M.EDI_all(c,2)*s1k),1:5).';
 dth=th-thH;Udth=max([abs((thc-thHc)-dth),abs((th4-thH4)-dth),max(abs((thall-thHall)-dth))]);
 t=struct('id',M.id,'ratio',M.ratio, ...
  'KI_perkN',M.KI_perkN,'KII_perkN',M.KII_perkN,'KI_COD_perkN',M.KI_COD_perkN,'KII_COD_perkN',M.KII_COD_perkN, ...
  'KI_phys_1N_MPa_sqrt_m',M.KI_raw/s1k,'KII_phys_1N_MPa_sqrt_m',M.KII_raw/s1k, ...
  'G_1N_N_per_mm',gM(1),'G_1N_J_per_m2',1000*gM(1),'J_1N_N_per_mm',M.J,'G_COD_1N_N_per_mm',gMc, ...
  'R_EDI',R,'R_COD',Rcod,'R_J',Rj,'R_EDI4x4',R4,'R_contours',Rc.','U_R',UR,'coverage',cf,'resolved',resolved, ...
  'U_R_conservative',Ucons,'resolvedConservative',resolvedCons, ...
  'KI_ratio',M.KI_raw/H.KI_raw,'KII_ratio',M.KII_raw/H.KII_raw,'KII_uncertainty_raw',uKII,'KII_signResolved',kiiRes, ...
  'mixity_deg',atand(M.KII_raw/M.KI_raw),'mixity_COD_deg',atand(M.KII_COD_raw/M.KI_COD_raw), ...
  'MTS_deg',th,'MTS_COD_deg',thc,'dMTS_deg',dth,'U_dMTS_deg',Udth,'dMTSresolved',abs(dth)>cf*Udth, ...
  'compliance_mm_per_N',M.compliance_mm_per_N,'complianceRatio',M.compliance_mm_per_N/H.compliance_mm_per_N, ...
  'CMOD_mm',M.CMOD_mm,'CMODratio',M.CMOD_mm/H.CMOD_mm, ...
  'strainEnergy_N_mm',M.strainEnergy_per_thickness*M.thickness_mm,'energyRatio',M.strainEnergy_per_thickness/H.strainEnergy_per_thickness, ...
  'reinforcementEnergyFraction',M.phaseStrainEnergy_per_thickness(end)/sum(M.phaseStrainEnergy_per_thickness));
 % ---- Issue #36 additions
 t.tangentGlobal_deg=tg;t.MTSglobal_deg=tg+th;t.MTSglobal_H1_deg=tg+thH;
 t.MTSrootCheck_rad=root_check(M.KI_perkN,M.KII_perkN,th);
 t.G_H1_1N_N_per_mm=gH(1);t.mixity_H1_deg=atand(H.KII_raw/H.KI_raw);t.MTS_H1_deg=thH;
 if isempty(T),T=t;else,T(end+1)=t;end %#ok<AGROW>
end
end

function e=root_check(KI,KII,thdeg)
% Independent bracketed root of KI sin(th) + KII (3 cos(th) - 1) = 0 on (-pi/2, pi/2).
f=@(x)KI*sin(x)+KII*(3*cos(x)-1);
x=fzero(f,[-pi/2,pi/2],optimset('TolX',1e-15));
e=abs(x-thdeg*pi/180);
end
