function K = g2_m4b_sif_partial(D,act,mats,policyT,PM,expect)
%G2_M4B_SIF_PARTIAL  Partial ring activation solve -> blind COD -> EDI on frozen S2 (Issue #47).
%
%  K = g2_m4b_sif_partial(D,act,mats,policyT,PM,expect)
%   D       saved S2 mesh structure (unchanged)
%   act     g2_m4b_ring_activation output (ownerRing, mask, phaseForAssembly)
%   mats    [matrix, active] material structs
%   policyT trajectory policy v1 (BVP and inherited SIF gates, unchanged)
%   PM      qualified phase map (interfaces of the three rings)
%   expect  M4.B policy bvp/material expectations (P_N, thickness_mm, load_mm, E_matrix)
% The solve, the blind bank COD and the five-annulus EDI (+4x4) are the SAME calls in
% the SAME order as g2_material_sif_on_mesh (unchanged legacy routine), so the full
% activation reproduces it bit for bit. Differences, all stricter or scoped:
%  - q support of every annulus must be free of ANY ring-owned element (ownerRing==0),
%    not only of label 2;
%  - interface nodal force balance / annulus resultant only on ACTIVE rings
%    (g2_m4b_interface_balance); passive rings carry no material jump and their
%    side-traction difference is reported as information only;
%  - explicit load / thickness / modulus gate against the M4.B policy.
% Extra outputs: per-ring strain energy (by owner), element strain energy, active area.
required={'X6','T6','crackPolyline','tipTangent','upperBankT6','lowerBankT6','extraVertexNodes','extraVertexXY'};
assert(all(isfield(D,required)),'G2M4B:SIFMeshSchema','Saved mesh lacks required fields.');
phase=act.phaseForAssembly;owner=act.ownerRing;
matM=mats(1);
P=D.crackPolyline;tip=P(end,:);t=D.tipTangent(:).';
thick=policyT.bvp.thickness_mm;f=policyT.bvp.P_N/thick;N=size(D.X6,1);
nodeAt=@(xy)D.extraVertexNodes(vecnorm(D.extraVertexXY-reshape(xy,1,2),2,2)<1e-9);
pin=nodeAt(policyT.bvp.pin_mm);roller=nodeAt(policyT.bvp.roller_mm);loadNode=nodeAt(policyT.bvp.load_mm);
assert(isscalar(pin)&&isscalar(roller)&&isscalar(loadNode),'G2M4B:BVPAnchors','Missing pin, roller or load vertex.');
F=zeros(2*N,1);F(2*loadNode)=-f;
loadOK=policyT.bvp.P_N==expect.P_N&&thick==expect.thickness_mm&&isequal(reshape(policyT.bvp.load_mm,1,2),reshape(expect.load_mm,1,2))&& ...
 nnz(F)==1&&F(2*loadNode)==-expect.P_N/expect.thickness_mm&&matM.E==expect.E_matrix&&policyT.bvp.E_MPa==expect.E_matrix;
bc=struct('fixedDofs',[2*pin-1;2*pin;2*roller],'fixedValues',[0;0;0],'F',F);
S=g2_t6_elasticity_phase(D.X6,D.T6,phase,mats,bc);
reac=S.reactions;
pinv=reshape(policyT.bvp.pin_mm,1,2);rolv=reshape(policyT.bvp.roller_mm,1,2);lodv=reshape(policyT.bvp.load_mm,1,2);
span=rolv(1)-pinv(1);momentArm=lodv(1)-pinv(1);
sta=[abs(reac(1))/f,abs(reac(2)+reac(3)-f)/f, ...
 abs(pinv(1)*reac(2)+rolv(1)*reac(3)-lodv(1)*f)/(abs(f)*span), ...
 abs(reac(3)/f-momentArm/span),abs(reac(2)/f-(span-momentArm)/span)];
lastLen=norm(P(end,:)-P(end-1,:));
C=g2_sif_cod_banks(D.X6,S.u,matM,tip,t,D.upperBankT6,D.lowerBankT6,lastLen,[.1 1.5]);
U=D.upperBankT6(:);L=D.lowerBankT6(:);
assert(numel(U)==numel(L)&&numel(U)>3&&max(vecnorm(D.X6(U,:)-D.X6(L,:),2,2))<1e-9,'G2M4B:WholeCrackTwins','Saved bank node pairs invalid.');
d=[S.u(2*U-1)-S.u(2*L-1),S.u(2*U)-S.u(2*L)];
ds=diff(P,1,1);lens=vecnorm(ds,2,2);tt=ds./lens;nn=[-tt(:,2),tt(:,1)];staPath=[0;cumsum(lens)];
arc=nan(numel(U),1);segID=ones(numel(U),1);
for k=1:numel(U)
 x=D.X6(U(k),:);best=inf;
 for j=1:size(tt,1)
  h=max(0,min(lens(j),dot(x-P(j,:),tt(j,:))));dist=norm(x-(P(j,:)+h*tt(j,:)));
  if dist<best,best=dist;segID(k)=j;arc(k)=staPath(j)+h;end
 end
 assert(best<1e-8,'G2M4B:BankOffPolyline','Whole-crack bank node %d is off the polyline.',k);
end
opening=sum(d.*nn(segID,:),2);minOpening=min(opening);
[~,im]=min(arc);CMOD=opening(im);
an=[.4 2.6;.2 1.0;.4 1.6;.8 2.6;1.2 2.4];   % registered annuli (unchanged)
ed=zeros(size(an,1),3);qmax=0;qPhaseOK=true;qOwnerOK=true;qActive=zeros(size(an,1),1);
r6=vecnorm(D.X6-tip,2,2);rE=min(reshape(r6(D.T6(:)),[],6),[],2);
for j=1:size(an,1)
 E=g2_sif_interaction(D.X6,D.T6,S.u,matM,tip,t,an(j,1),an(j,2),6);
 ed(j,:)=[E.KI,E.KII,E.J];qmax=max(qmax,E.maxSupportRadius);qActive(j)=E.activeElements;
 support=rE<an(j,2);
 qPhaseOK=qPhaseOK&&all(phase(E.activeRows)==1)&&all(phase(support)==1);
 qOwnerOK=qOwnerOK&&all(owner(E.activeRows)==0)&&all(owner(support)==0);
end
E4=g2_sif_interaction(D.X6,D.T6,S.u,matM,tip,t,.4,2.6,4);
[~,Ep]=g2_plane_D(matM);
Kr=hypot(ed(1,1),ed(1,2));
assert(isfinite(Kr)&&Kr>0,'G2M4B:ZeroSIF','No tensile signed SIF exists.');
ratio=abs(ed(1,2)/ed(1,1));signMatch=sign(ed(1,2))==sign(C.KII);
v=policyT.verification;
qGate=qmax<policyT.numerics.coreRadius_mm*cos(pi/policyT.numerics.protectedSectors);
% ---- interface diagnostics: active rings gated, passive rings informational
fP=S.phaseNodalForce;actR=act.activeRings(:).';
if size(fP,2)<2,fP(:,2)=0;end
B=g2_m4b_interface_balance(fP,PM,actR);
nb=numel(PM.interfaces);sideL2=nan(nb,1);chordT=cell(nb,1);
for h=1:nb
 [chordT{h},sideL2(h)]=chord_tractions(D.X6,D.T6,S.u,phase,mats,PM.interfaces(h));
end
energyId=abs(S.strainEnergy-S.externalWork)/S.strainEnergy;
gm=struct('interfaceNodalForceBalanceRelTol',1e-8,'annulusResultantRelTol',1e-8,'heterogeneousEnergyIdentityRelTol',1e-9);
criteria=struct( ...
 'elasticEquilibrium',S.relativeResidual<=v.elasticRelativeResidualMax&&max(sta)<=v.elasticRelativeResidualMax, ...
 'blindCODversusEDI',max(abs([ed(1,1)-C.KI,ed(1,2)-C.KII]))/Kr<=v.COD_EDI_maxFractionOfKref, ...
 'contourIndependence',max(max(ed(:,1:2))-min(ed(:,1:2)))/Kr<=v.pathSpread_maxFraction, ...
 'JenergyIdentity',abs(ed(1,3)/((ed(1,1)^2+ed(1,2)^2)/Ep)-1)<=v.JEnergyIdentityMaxFraction, ...
 'EDIquadrature',max(abs([E4.KI-ed(1,1),E4.KII-ed(1,2)]))/Kr<=v.quadratureDriftMaxFraction, ...
 'qSupportInsideCore',qGate, ...
 'wholeCrackOpening',minOpening>=v.minWholeCrackNormalOpening_mm, ...
 'KIpositive',ed(1,1)>0, ...
 'conditionalHighMixityKIIagreement',ratio<=v.highMixitySignGateAbsKIIoverKI||signMatch, ...
 'qSupportMatrixPhaseOnly',qPhaseOK, ...
 'qSupportRingOwnerFree',qOwnerOK, ...
 'heterogeneousEnergyIdentity',energyId<=gm.heterogeneousEnergyIdentityRelTol, ...
 'activeInterfaceNodalForceBalance',B.balanceRel<=gm.interfaceNodalForceBalanceRelTol, ...
 'activeAnnulusResultant',B.resultantRel<=gm.annulusResultantRelTol, ...
 'stiffnessPositiveDefinite',S.KffPositiveDefinite, ...
 'loadThicknessModulus',loadOK);
vals=cell2mat(struct2cell(criteria));fields=fieldnames(criteria);
s1k=sqrt(1000);
ringU=accumarray(owner+1,S.elementStrainEnergy,[4 1]);
x=D.X6(:,1);y=D.X6(:,2);T3=D.T6(:,1:3);
Ael=.5*((x(T3(:,2))-x(T3(:,1))).*(y(T3(:,3))-y(T3(:,1)))-(x(T3(:,3))-x(T3(:,1))).*(y(T3(:,2))-y(T3(:,1))));
K=struct('pass',all(vals),'status','HOLD_M4B_SIF_VERIFICATION','criteria',criteria,'failedCriteria',{fields(~vals)}, ...
 'KI',ed(1,1),'KII',ed(1,2),'J',ed(1,3),'KI_COD',C.KI,'KII_COD',C.KII, ...
 'KI_MPa_sqrt_m_per_kN',ed(1,1)*s1k,'KII_MPa_sqrt_m_per_kN',ed(1,2)*s1k, ...
 'EDI_all',ed,'EDI4x4',[E4.KI,E4.KII],'qActiveElements',qActive,'qSupportMaxRadius_mm',qmax, ...
 'codFitPairs',C.pairsInWindow,'Ep_matrix',Ep, ...
 'relativeResidual',S.relativeResidual,'statics',sta,'staticsMax',max(sta),'reactions',reac, ...
 'strainEnergy_per_thickness',S.strainEnergy,'externalWork_per_thickness',S.externalWork, ...
 'phaseStrainEnergy_per_thickness',S.phaseStrainEnergy,'energyIdentityRel',energyId, ...
 'ringStrainEnergy_per_thickness',ringU,'elementStrainEnergy_per_thickness',S.elementStrainEnergy, ...
 'activeInterfaceBalanceRel',B.balanceRel,'activeAnnulusResultantRel',B.resultantRel,'activeRingResultantRel',B.perRingResultantRel, ...
 'interfaceSideL2Rel',sideL2,'interfaceSideL2Gated',ismember(1:nb,actR).','chordTractions',{chordT}, ...
 'KffPositiveDefinite',S.KffPositiveDefinite,'phaseDminEig',S.phaseDminEig,'phaseCounts',S.phaseCounts, ...
 'activeArea_mm2',sum(Ael(phase==2)),'ringArea_mm2',accumarray(owner+1,Ael,[4 1]), ...
 'u',S.u,'loadNode',loadNode,'uyLoad_mm',S.u(2*loadNode),'compliance_mm_per_N',abs(S.u(2*loadNode))/policyT.bvp.P_N, ...
 'CMOD_mm',CMOD,'fullPolyOpeningMin_mm',minOpening,'fullPolyOpening_mm',opening,'wholeCrackArclength_mm',arc, ...
 'KII_sign_edi_vs_cod_match',signMatch,'conditionalModeIISignGateEnforced',ratio>v.highMixitySignGateAbsKIIoverKI, ...
 'physicalFractureGrowthProven',false);
if K.pass,K.status='M4B_SIF_VERIFIED';end
fprintf('G2_M4B_SIF bits=%s pass=%d KI=%.9g KII=%+.9g MPa sqrt(m)/kN, COD %.9g / %+.9g, C=%.9g mm/N\n', ...
 act.bits,K.pass,K.KI_MPa_sqrt_m_per_kN,K.KII_MPa_sqrt_m_per_kN,C.KI*s1k,C.KII*s1k,K.compliance_mm_per_N);
end

function [T,sideL2]=chord_tractions(X6,T6,u,phase,mats,I)
% Integrated traction on every chord from each side (3-point Gauss); same formula as the
% legacy routine. For a passive ring both sides are matrix and the difference is only
% the T6 stress discontinuity (information, not a gate).
ch=I.chords;gp=[.5-sqrt(15)/10,.5,.5+sqrt(15)/10];gw=[5 8 5]/18;n=size(ch,1);
c0=mean(X6(I.vertexNodes,:),1);
A=X6(ch(:,1),:);Bv=X6(ch(:,2),:);L=vecnorm(Bv-A,2,2);tv=(Bv-A)./L;nv=[tv(:,2),-tv(:,1)];
fl=sum(nv.*(.5*(A+Bv)-c0),2)<0;nv(fl,:)=-nv(fl,:);
T=struct('angle_rad',atan2(.5*(A(:,2)+Bv(:,2))-c0(2),.5*(A(:,1)+Bv(:,1))-c0(1)),'length_mm',L, ...
 'tn_inner',zeros(n,1),'tt_inner',zeros(n,1),'tn_outer',zeros(n,1),'tt_outer',zeros(n,1));
for side=1:2
 own=I.innerOwner;if side==2,own=I.outerOwner;end
 tn=zeros(n,1);tt=tn;
 for q=1:3
  p=A+gp(q)*(Bv-A);Dk=zeros(3,3,n);
  for i=1:n,Dk(:,:,i)=g2_plane_D(mats(phase(own(i))));end
  s=g2_t6_point_stress(X6,T6,u,Dk,own,p);
  tx=s(:,1).*nv(:,1)+s(:,3).*nv(:,2);ty=s(:,3).*nv(:,1)+s(:,2).*nv(:,2);
  tn=tn+gw(q)*(tx.*nv(:,1)+ty.*nv(:,2));tt=tt+gw(q)*(-tx.*nv(:,2)+ty.*nv(:,1));
 end
 if side==1,T.tn_inner=tn;T.tt_inner=tt;else,T.tn_outer=tn;T.tt_outer=tt;end
end
sideL2=sqrt(sum(L.*((T.tn_inner-T.tn_outer).^2+(T.tt_inner-T.tt_outer).^2))/max(sum(L.*(T.tn_outer.^2+T.tt_outer.^2)),realmin));
end
