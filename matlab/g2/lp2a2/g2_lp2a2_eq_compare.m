function R=g2_lp2a2_eq_compare(N,A,tol)
%G2_LP2A2_EQ_COMPARE  SIF-equivalence comparison of ONE new-family solution with its archived
% LP2-A1 S8 solution on the SAME geometry and material (pure function; no FEM, no I/O).
%  N.K  new g2_m4b_sif_partial result; N.D new joined mesh (X6, upperBankT6, lowerBankT6,
%       crackPolyline); N.activeArea_mm2, N.chordsPerCircle; N.S9tip_mm (forecast from N.K)
%  A.state  archived STATE record; A.K archived SOLUTION K; A.D archived MESH; A.S9tip_mm archived
%       TERMINAL candidate tip; A.chordsPerCircle
%  tol  the preregistered tolerances (G2_LP2A2_EQ_POLICY_v1.json, field tolerances)
% Every quantity is reported; pass requires every preregistered criterion.
Keq=hypot(A.K.KI,A.K.KII);m=struct();c=struct();
m.dKI_overKeq=(N.K.KI-A.K.KI)/Keq;m.dKII_overKeq=(N.K.KII-A.K.KII)/Keq;
m.dKIIoverKI=N.K.KII/N.K.KI-A.K.KII/A.K.KI;
Gn=(N.K.KI^2+N.K.KII^2)/tol.E_MPa;Ga=(A.K.KI^2+A.K.KII^2)/tol.E_MPa;m.dG_rel=Gn/Ga-1;m.dJ_rel=N.K.J/A.K.J-1;
m.newJoverGminus1=N.K.J/Gn-1;
Mn=g2_mts_direction(N.K.KI,N.K.KII);Ma=g2_mts_direction(A.K.KI,A.K.KII);m.dMTS_deg=Mn.theta_deg-Ma.theta_deg;
m.newCODminusEDI_rel=max(abs([N.K.KI_COD-N.K.KI,N.K.KII_COD-N.K.KII]))/hypot(N.K.KI,N.K.KII);
m.archivedCODminusEDI_rel=max(abs([A.K.KI_COD-A.K.KI,A.K.KII_COD-A.K.KII]))/Keq;m.dCODminusEDI=m.newCODminusEDI_rel-m.archivedCODminusEDI_rel;
spread=@(K)max(max(K.EDI_all(:,1:2))-min(K.EDI_all(:,1:2)))/hypot(K.KI,K.KII);quad=@(K)max(abs(K.EDI4x4-[K.KI,K.KII]))/hypot(K.KI,K.KII);
m.newPathSpread_rel=spread(N.K);m.archivedPathSpread_rel=spread(A.K);m.newQuad4x4_rel=quad(N.K);m.archivedQuad4x4_rel=quad(A.K);
m.dCompliance_rel=N.K.compliance_mm_per_N/A.K.compliance_mm_per_N-1;
m.dActiveArea_rel=(N.activeArea_mm2-A.K.activeArea_mm2)/max(A.K.activeArea_mm2,1);
m.S9tipDisplacement_mm=norm(N.S9tip_mm-A.S9tip_mm);
[o1,o2,sg]=openingDiff(N,A);m.openingNearTipRel=o1;m.openingWholeCrackRel=o2;
% reported only (NOT criteria): C8 compares the vector jump magnitude |u_U - u_L| as preregistered;
% the signed normal opening (u_U - u_L).n and the solver's own gates are reported separately
m.signedOpeningNearTipRel=sg.nearRel;m.signedOpeningWholeCrackRel=sg.wholeRel;m.newMinSignedOpening_mm=sg.newMin;m.archivedMinSignedOpening_mm=sg.archMin;
m.newSolverGatesPass=logical(N.K.pass);m.archivedSolverGatesPass=logical(A.K.pass);
c.C1_KI=abs(m.dKI_overKeq)<=tol.KI_overKeq;
c.C2_KII=abs(m.dKII_overKeq)<=tol.KII_overKeq;
c.C3_KIIoverKI=abs(m.dKIIoverKI)<=tol.KIIoverKI_abs;
c.C4_G_J=abs(m.dG_rel)<=tol.G_rel&&abs(m.dJ_rel)<=tol.J_rel&&abs(m.newJoverGminus1)<=tol.newJoverGminus1;
c.C5_MTS=abs(m.dMTS_deg)<=tol.MTS_deg&&Mn.admissibleForStep;
c.C6_COD_EDI=m.newCODminusEDI_rel<=tol.newCODminusEDI_gate&&abs(m.dCODminusEDI)<=tol.dCODminusEDI;
c.C7_EDI_spread_quadrature=m.newPathSpread_rel<=max(tol.spreadFloor,tol.spreadFactor*m.archivedPathSpread_rel)&& ...
 m.newQuad4x4_rel<=max(tol.quadFloor,tol.quadFactor*m.archivedQuad4x4_rel);
c.C8_crackOpening=o1<=tol.openingNearTipRel&&o2<=tol.openingWholeCrackRel;
c.C9_phaseActivation=logical(N.K.pass)&&isequal(N.chordsPerCircle,A.chordsPerCircle)&&abs(m.dActiveArea_rel)<=tol.activeArea_rel;
c.C10_S9predictor=m.S9tipDisplacement_mm<=tol.S9tipDisplacement_mm;
c.C11_compliance=abs(m.dCompliance_rel)<=tol.compliance_rel;
v=cell2mat(struct2cell(c));f=fieldnames(c);
R=struct('pass',all(v),'criteria',c,'criteriaPassed',nnz(v),'criteriaTotal',numel(v),'failed',{f(~v)},'metrics',m);
end

function [nearRel,wholeRel,sg]=openingDiff(N,A)
% crack-face jump |u_upper - u_lower| along the crack. Near tip (<= 3.3 mm): identical node positions
% in both families (protected kernel and collar) -> direct comparison. Whole crack: archived jump
% interpolated linearly in arc length onto the new-family stations. The same comparison is repeated
% for the signed normal opening (u_upper - u_lower).n_segment (reported only).
[sN,jN,xN,gN]=jumps(N.D,N.K.u);[sA,jA,xA,gA]=jumps(A.D,A.K.u);P=N.D.crackPolyline;tip=P(end,:);
nt=vecnorm(xN-tip,2,2)<=3.3+1e-9;ix=find(nt);d=inf(numel(ix),1);e=d;
for i=1:numel(ix),[dd,k]=min(vecnorm(xA-xN(ix(i),:),2,2));if dd<=1e-9,d(i)=abs(jN(ix(i))-jA(k));e(i)=abs(gN(ix(i))-gA(k));end,end
nearRel=max(d)/max(jN(nt));
ji=interp1(sA,jA,sN,'linear');wholeRel=max(abs(ji-jN))/max(jN);
gi=interp1(sA,gA,sN,'linear');
sg=struct('nearRel',max(e)/max(abs(gN(nt))),'wholeRel',max(abs(gi-gN))/max(abs(gN)),'newMin',min(gN),'archMin',min(gA));
end

function [s,j,x,g]=jumps(D,u)
U=reshape(u,2,[]).';up=D.upperBankT6(:);lo=D.lowerBankT6(:);P=D.crackPolyline;
x=D.X6(up,:);[s,kq]=station(x,P);[s,o]=sort(s);up=up(o);x=x(o,:);kq=kq(o);
sl=station(D.X6(lo,:),P);[~,o]=sort(sl);lo=lo(o);
assert(numel(up)==numel(lo)&&max(vecnorm(D.X6(up,:)-D.X6(lo,:),2,2))<=1e-9,'G2LP2A2:EQ_BANKS','Banks do not pair by station.');
J=U(up,:)-U(lo,:);j=vecnorm(J,2,2);
tt=diff(P);tt=tt./vecnorm(tt,2,2);nn=[-tt(:,2),tt(:,1)];g=sum(J.*nn(kq,:),2);
end

function [s,k]=station(X,P)
tt=diff(P);L=vecnorm(tt,2,2);tt=tt./L;Sv=[0;cumsum(L)];M=size(X,1);dk=inf(M,numel(L));lk=dk;
for q=1:numel(L),l=max(0,min(L(q),(X-P(q,:))*tt(q,:).'));dk(:,q)=vecnorm(X-(P(q,:)+l*tt(q,:)),2,2);lk(:,q)=l;end
[~,k]=min(dk,[],2);s=Sv(k)+lk(sub2ind(size(lk),(1:M)',k));
end
