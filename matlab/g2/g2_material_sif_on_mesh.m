function K = g2_material_sif_on_mesh(D,phase,mats,policyT,PM)
%G2_MATERIAL_SIF_ON_MESH  Two-phase solve -> blind COD -> EDI on the frozen State 2 mesh (Issue #33).
%
%  K = g2_material_sif_on_mesh(D,phase,mats,policyT,PM)
%   D       saved State 2 mesh structure (unchanged)
%   phase   element labels (1 matrix, 2 reinforcement) from the qualified phase map
%   mats    [matrix, reinforcement] material structs
%   policyT trajectory policy v1 (BVP and the inherited SIF gates, unchanged)
%   PM      phase-map result (interfaces) used for the interface diagnostics
% Same post-processing as g2_trajectory_sif_on_mesh (unchanged): blind bank COD on the
% final segment first, then signed EDI on the five registered q annuli, both with the
% MATRIX material only. Added gates: q support of every annulus in the matrix phase,
% heterogeneous energy identity, interface nodal force balance, annulus resultant,
% positive-definite K_ff. Also returns u, compliance, CMOD, phase energies and the
% chord-wise interface tractions from both sides. No crack growth, no onset.
required={'X6','T6','crackPolyline','tipTangent','upperBankT6','lowerBankT6','extraVertexNodes','extraVertexXY'};
assert(all(isfield(D,required)),'G2Material:SIFMeshSchema','Saved mesh lacks required fields.');
matM=mats(1);
P=D.crackPolyline;tip=P(end,:);t=D.tipTangent(:).';
thick=policyT.bvp.thickness_mm;f=policyT.bvp.P_N/thick;N=size(D.X6,1);
nodeAt=@(xy)D.extraVertexNodes(vecnorm(D.extraVertexXY-reshape(xy,1,2),2,2)<1e-9);
pin=nodeAt(policyT.bvp.pin_mm);roller=nodeAt(policyT.bvp.roller_mm);loadNode=nodeAt(policyT.bvp.load_mm);
assert(isscalar(pin)&&isscalar(roller)&&isscalar(loadNode),'G2Material:BVPAnchors','Missing pin, roller or load vertex.');
F=zeros(2*N,1);F(2*loadNode)=-f;
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
assert(numel(U)==numel(L)&&numel(U)>3&&max(vecnorm(D.X6(U,:)-D.X6(L,:),2,2))<1e-9,'G2Material:WholeCrackTwins','Saved bank node pairs invalid.');
d=[S.u(2*U-1)-S.u(2*L-1),S.u(2*U)-S.u(2*L)];
ds=diff(P,1,1);lens=vecnorm(ds,2,2);tt=ds./lens;nn=[-tt(:,2),tt(:,1)];staPath=[0;cumsum(lens)];
arc=nan(numel(U),1);segID=ones(numel(U),1);
for k=1:numel(U)
 x=D.X6(U(k),:);best=inf;
 for j=1:size(tt,1)
  h=max(0,min(lens(j),dot(x-P(j,:),tt(j,:))));dist=norm(x-(P(j,:)+h*tt(j,:)));
  if dist<best,best=dist;segID(k)=j;arc(k)=staPath(j)+h;end
 end
 assert(best<1e-8,'G2Material:BankOffPolyline','Whole-crack bank node %d is off the polyline.',k);
end
opening=sum(d.*nn(segID,:),2);minOpening=min(opening);
[~,im]=min(arc);CMOD=opening(im);
% EDI on the registered q annuli, matrix material; q-phase gate on each support
an=[.4 2.6;.2 1.0;.4 1.6;.8 2.6;1.2 2.4];   % the registered annuli of g2_trajectory_sif_on_mesh
ed=zeros(size(an,1),3);qmax=0;qPhaseOK=true;qActive=zeros(size(an,1),1);
r6=vecnorm(D.X6-tip,2,2);rE=min(reshape(r6(D.T6(:)),[],6),[],2);
for j=1:size(an,1)
 E=g2_sif_interaction(D.X6,D.T6,S.u,matM,tip,t,an(j,1),an(j,2),6);
 ed(j,:)=[E.KI,E.KII,E.J];qmax=max(qmax,E.maxSupportRadius);qActive(j)=E.activeElements;
 support=rE<an(j,2);                         % every element with a node where q > 0
 qPhaseOK=qPhaseOK&&all(phase(E.activeRows)==1)&&all(phase(support)==1);
end
E4=g2_sif_interaction(D.X6,D.T6,S.u,matM,tip,t,.4,2.6,4);
[~,Ep]=g2_plane_D(matM);
Kr=hypot(ed(1,1),ed(1,2));
assert(isfinite(Kr)&&Kr>0,'G2Material:ZeroSIF','No tensile signed SIF exists.');
ratio=abs(ed(1,2)/ed(1,1));signMatch=sign(ed(1,2))==sign(C.KII);
v=policyT.verification;
qGate=qmax<policyT.numerics.coreRadius_mm*cos(pi/policyT.numerics.protectedSectors);
% ---- interface diagnostics
iNodes=[];resultant=0;nb=numel(PM.interfaces);sideL2=zeros(nb,1);chordT=cell(nb,1);
fP=S.phaseNodalForce;
for h=1:nb
 I=PM.interfaces(h);nodes=[I.vertexNodes;I.midsideNodes];iNodes=[iNodes;nodes]; %#ok<AGROW>
 f2=fP([2*nodes-1;2*nodes],2);
 scale=sum(abs(f2))+realmin;
 resultant=max(resultant,max(abs([sum(fP(2*nodes-1,2)),sum(fP(2*nodes,2))]))/scale);
 [chordT{h},sideL2(h)]=chord_tractions(D.X6,D.T6,S.u,phase,mats,I);
end
iDof=[2*iNodes-1;2*iNodes];
if size(fP,2)>=2&&any(phase==2)
 balance=max(abs(fP(iDof,1)+fP(iDof,2)))/max(max(abs(fP(iDof,2))),realmin);
else
 balance=0;
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
 'heterogeneousEnergyIdentity',energyId<=gm.heterogeneousEnergyIdentityRelTol, ...
 'interfaceNodalForceBalance',balance<=gm.interfaceNodalForceBalanceRelTol, ...
 'annulusResultant',resultant<=gm.annulusResultantRelTol, ...
 'stiffnessPositiveDefinite',S.KffPositiveDefinite);
vals=cell2mat(struct2cell(criteria));fields=fieldnames(criteria);
s1k=sqrt(1000);
K=struct('pass',all(vals),'status','HOLD_MATERIAL_SIF_VERIFICATION','criteria',criteria,'failedCriteria',{fields(~vals)}, ...
 'KI',ed(1,1),'KII',ed(1,2),'J',ed(1,3),'KI_COD',C.KI,'KII_COD',C.KII, ...
 'KI_MPa_sqrt_m_per_kN',ed(1,1)*s1k,'KII_MPa_sqrt_m_per_kN',ed(1,2)*s1k, ...
 'EDI_all',ed,'EDI4x4',[E4.KI,E4.KII],'qActiveElements',qActive,'qSupportMaxRadius_mm',qmax, ...
 'codFitPairs',C.pairsInWindow,'Ep_matrix',Ep, ...
 'relativeResidual',S.relativeResidual,'statics',sta,'staticsMax',max(sta),'reactions',reac, ...
 'strainEnergy_per_thickness',S.strainEnergy,'externalWork_per_thickness',S.externalWork, ...
 'phaseStrainEnergy_per_thickness',S.phaseStrainEnergy,'energyIdentityRel',energyId, ...
 'interfaceBalanceRel',balance,'annulusResultantRel',resultant,'interfaceSideL2Rel',sideL2,'chordTractions',{chordT}, ...
 'KffPositiveDefinite',S.KffPositiveDefinite,'phaseDminEig',S.phaseDminEig,'phaseCounts',S.phaseCounts, ...
 'u',S.u,'loadNode',loadNode,'uyLoad_mm',S.u(2*loadNode),'compliance_mm_per_N',abs(S.u(2*loadNode))/policyT.bvp.P_N, ...
 'CMOD_mm',CMOD,'fullPolyOpeningMin_mm',minOpening,'fullPolyOpening_mm',opening,'wholeCrackArclength_mm',arc, ...
 'KII_sign_edi_vs_cod_match',signMatch,'conditionalModeIISignGateEnforced',ratio>v.highMixitySignGateAbsKIIoverKI, ...
 'K',S.K,'physicalFractureGrowthProven',false);
if K.pass,K.status='MATERIAL_SIF_VERIFIED';end
fprintf('G2_MATERIAL_SIF_PASS=%d KI=%.9g KII=%+.9g MPa sqrt(m)/kN, COD %.9g / %+.9g, C=%.9g mm/N\n', ...
 K.pass,K.KI_MPa_sqrt_m_per_kN,K.KII_MPa_sqrt_m_per_kN,C.KI*s1k,C.KII*s1k,K.compliance_mm_per_N);
end

function [T,sideL2]=chord_tractions(X6,T6,u,phase,mats,I)
% Integrated traction (normal, tangential) on every interface chord from each side (3-point Gauss).
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
