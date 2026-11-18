function B = check_g2_material_benchmark(pol)
%CHECK_G2_MATERIAL_BENCHMARK  Two-phase T6 qualification against the exact coated hole (Issue #33, M1).
%
%  B = check_g2_material_benchmark(pol)   % pol = jsondecode(G2_MATERIAL_POLICY_v1.json)
% 1. Self-check of the exact field (finite-difference strains -> Hooke vs Airy stresses;
%    hole, interface and outer residuals).
% 2. PDE Toolbox meshes of the coated disk with the interface as a face boundary,
%    straight T3 -> T6, phase labels by g2_material_phase_map and g2_material_phase_verify.
% 3. g2_t6_elasticity_phase with the exact displacement on the outer circle for each ratio and
%    Hmax: nodal displacement, strain-energy and interface traction-moment errors (both sides).
% 4. Ratio-1 identity with the homogeneous g2_t6_elasticity; stiffness equal to an
%    independent element-loop assembly with a 6-point rule.
% 5. Negative controls (swapped phases, partially detached interface) must fail the gates.
bm=pol.benchmark;a=bm.a_mm;b=bm.b_mm;c=bm.c_mm;S=bm.remoteUniaxialStress_MPa;
Em=pol.materials.E_matrix_MPa;nu=pol.materials.nu_matrix;plane=pol.materials.plane;
ratios=bm.ratios(:).';H=bm.Hmax_mm(:).';
B=struct('pass',false,'checks',struct(),'values',struct());
mk=@(E)struct('E',E,'nu',nu,'plane',plane);
% ---------------- 1. exact field self-check
selfErr=zeros(size(ratios));resid=zeros(size(ratios));
for k=1:numel(ratios)
 X=g2_coated_hole_exact(a,b,c,ratios(k)*Em,Em,nu,S);
 [rr,tt]=meshgrid([linspace(a*1.02,b*.98,7),linspace(b*1.02,c*.98,7)],linspace(0,2*pi,13));
 Q=[rr(:).*cos(tt(:)),rr(:).*sin(tt(:))];hs=1e-4;
 [~,s0]=X.field(Q);
 [ux1]=X.field(Q+[hs 0]);[ux0]=X.field(Q-[hs 0]);[uy1]=X.field(Q+[0 hs]);[uy0]=X.field(Q-[0 hs]);
 dudx=(ux1-ux0)/(2*hs);dudy=(uy1-uy0)/(2*hs);
 ep=[dudx(:,1),dudy(:,2),dudy(:,1)+dudx(:,2)];
 sF=zeros(size(s0));
 for i=1:size(Q,1)
  Ei=Em;if hypot(Q(i,1),Q(i,2))<b,Ei=ratios(k)*Em;end
  sF(i,:)=(g2_plane_D(mk(Ei))*ep(i,:).').';
 end
 selfErr(k)=max(abs(sF(:)-s0(:)))/max(abs(s0(:)));
 Pa=X.polar(a);Pi=X.polar(b*(1-1e-12));Po=X.polar(b*(1+1e-12));Pc=X.polar(c);
 resid(k)=max(abs([Pa.srr0,Pa.srr2,Pa.srt2,Pi.ur0-Po.ur0,Pi.g-Po.g,Pi.h-Po.h,Pi.srr0-Po.srr0,Pi.srr2-Po.srr2,Pi.srt2-Po.srt2, ...
  Pc.srr0-S/2,Pc.srr2-S/2,Pc.srt2+S/2]))/S;
end
B.values.exactSelfCheckRel=selfErr;B.values.exactResidualRel=resid;
B.checks.exactFieldSelfConsistent=all(selfErr<=bm.exactFieldSelfCheckRelTol)&&all(resid<=1e-9);
fprintf('BENCH_EXACT_SELFCHECK max %.3g, residual max %.3g\n',max(selfErr),max(resid));
% ---------------- 2-3. meshes and solves
eu=nan(numel(ratios),numel(H));eU=eu;eT=eu;eTside=eu;meshInfo=struct([]);
for j=1:numel(H)
 Mh=coated_mesh(a,b,c,H(j));
 Pm=g2_material_phase_map(Mh.X6,Mh.T6,[0 0],a,b,struct('onCircleTol_mm',1e-9,'minGap_mm',1e-3));
 assert(Pm.pass,'G2Bench:PhaseMap','Benchmark phase map failed: %s',Pm.message);
 Vf=g2_material_phase_verify(Mh.X6,Mh.T6,Pm.phase,[0 0],a,b,struct('outerArea_mm2',polyarea(Mh.X6(Mh.outerRing,1),Mh.X6(Mh.outerRing,2))));
 assert(Vf.pass,'G2Bench:PhaseVerify','Benchmark phase verifier failed: %s',strjoin(Vf.failed,', '));
 meshInfo(j).Hmax=H(j);meshInfo(j).T6=size(Mh.T6,1);meshInfo(j).nodes=size(Mh.X6,1);meshInfo(j).counts=Pm.counts; %#ok<AGROW>
 meshInfo(j).chords=size(Pm.interfaces(1).chords,1);
 fprintf('BENCH_MESH Hmax=%.2f T6=%d nodes=%d matrix/band=%d/%d chords=%d\n',H(j),size(Mh.T6,1),size(Mh.X6,1),Pm.counts,meshInfo(j).chords);
 for k=1:numel(ratios)
  X=g2_coated_hole_exact(a,b,c,ratios(k)*Em,Em,nu,S);
  R=solve_case(Mh,Pm.phase,[mk(Em),mk(ratios(k)*Em)],X);
  eu(k,j)=R.eu;eU(k,j)=R.eU;eT(k,j)=R.eT;eTside(k,j)=R.eTside;
  fprintf('BENCH ratio=%g Hmax=%.2f e_u=%.4g e_U=%.4g e_T=%.4g sides=%.4g res=%.2g PD=%d balance=%.2g\n', ...
   ratios(k),H(j),R.eu,R.eU,R.eT,R.eTside,R.res,R.pd,R.balance);
  if j==numel(H),fin(k)=R; end %#ok<AGROW>
 end
 if j==1,Mc=Mh;Pc=Pm;end
 if j==2,Mmid=Mh;Pmid=Pm;end
 if j==numel(H),Mf=Mh;Pf=Pm;end
end
ord=log(eu(:,end-1)./eu(:,end))./log(H(end-1)/H(end));
B.values.mesh=meshInfo;B.values.ratios=ratios;B.values.Hmax=H;
B.values.dispRelErr=eu;B.values.energyRelErr=eU;B.values.interfaceMomentRelErr=eT;B.values.interfaceSideDiscrepancy=eTside;
B.values.observedOrderFinestPair=ord;
B.checks.finestDisplacement=all(eu(:,end)<=bm.finestDisplacementRelErrorMax);
B.checks.finestEnergy=all(eU(:,end)<=bm.finestEnergyRelErrorMax);
B.checks.finestInterfaceTraction=all(eT(:,end)<=bm.finestInterfaceTractionMomentRelErrorMax);
B.checks.observedOrder=all(ord>=bm.minObservedOrderFinestPair);
B.checks.monotoneDecrease=all(all(diff(eu,1,2)<0));
B.checks.finestResidual=all(arrayfun(@(r)r.res,fin)<=1e-8);
B.checks.finestPositiveDefinite=all(arrayfun(@(r)r.pd,fin));
B.checks.finestInterfaceNodalBalance=all(arrayfun(@(r)r.balance,fin)<=1e-8);
B.checks.finestEnergyIdentity=all(arrayfun(@(r)r.energyId,fin)<=1e-9);
% ---------------- 4. identity and independent reference assembly
X1=g2_coated_hole_exact(a,b,c,Em,Em,nu,S);
bc=dir_bc(Mmid,X1);
Sh=g2_t6_elasticity(Mmid.X6,Mmid.T6,mk(Em),bc);
Sp=g2_t6_elasticity_phase(Mmid.X6,Mmid.T6,Pmid.phase,[mk(Em),mk(Em)],bc);
idU=max(abs(Sh.u-Sp.u))/max(abs(Sh.u));idK=full(max(abs(Sh.K-Sp.K),[],'all'))/full(max(abs(Sh.K),[],'all'));
B.values.identityRatio1_u=idU;B.values.identityRatio1_K=idK;
B.checks.identityRatio1=idU<=bm.identityRatio1RelTol&&idK<=bm.identityRatio1RelTol;
Kref=reference_assembly(Mc.X6,Mc.T6,Pc.phase,[mk(Em),mk(2*Em)]);
Sp2=g2_t6_elasticity_phase(Mc.X6,Mc.T6,Pc.phase,[mk(Em),mk(2*Em)],dir_bc(Mc,X1));
refRel=full(max(abs(Sp2.K-Kref),[],'all'))/full(max(abs(Kref),[],'all'));
B.values.referenceAssemblyRel=refRel;B.checks.referenceAssembly=refRel<=bm.referenceAssemblyRelTol;
fprintf('BENCH_IDENTITY u=%.3g K=%.3g  REFERENCE_ASSEMBLY=%.3g\n',idU,idK,refRel);
% ---------------- 5. negative controls at the finest level (ratio 2)
k2=find(ratios==2,1);X2=g2_coated_hole_exact(a,b,c,2*Em,Em,nu,S);
Rs=solve_case(Mf,3-Pf.phase,[mk(Em),mk(2*Em)],X2);
[Md,phd]=detach_half(Mf,Pf);
Rd=solve_case(Md,phd,[mk(Em),mk(2*Em)],X2);
Pmd=g2_material_phase_map(Md.X6,Md.T6,[0 0],a,b,struct());
Vd=g2_material_phase_verify(Md.X6,Md.T6,phd,[0 0],a,b,struct());
gateFail=@(R)R.eu>bm.finestDisplacementRelErrorMax||R.eU>bm.finestEnergyRelErrorMax||R.eT>bm.finestInterfaceTractionMomentRelErrorMax;
B.values.negativeSwapped=struct('eu',Rs.eu,'eU',Rs.eU,'eT',Rs.eT);
B.values.negativeDetached=struct('eu',Rd.eu,'eU',Rd.eU,'eT',Rd.eT,'jump_mm',Rd.jump,'mapperStage',Pmd.stage,'verifierFailed',{Vd.failed});
B.checks.negativeSwappedFails=gateFail(Rs);
B.checks.negativeDetachedFails=gateFail(Rd)&&~Pmd.pass&&~Vd.pass&&Rd.jump>0;
fprintf('BENCH_NEG swapped e_u=%.3g e_U=%.3g e_T=%.3g | detached e_u=%.3g e_U=%.3g jump=%.3g mapper=%s verifier=%d\n', ...
 Rs.eu,Rs.eU,Rs.eT,Rd.eu,Rd.eU,Rd.jump,Pmd.stage,Vd.pass);
B.values.finestRatio2=struct('eu',eu(k2,end),'eU',eU(k2,end));
B.values.exactConstants=struct('ratios',ratios);
f=fieldnames(B.checks);ok=cellfun(@(q)B.checks.(q),f);
B.pass=all(ok);B.failed=f(~ok);
B.plot=struct('X6',Mc.X6,'T6',Mc.T6,'phase',Pc.phase);
fprintf('G2_MATERIAL_BENCHMARK_PASS=%d (%d/%d checks)\n',B.pass,nnz(ok),numel(ok));
end

% =====================================================================
function R=solve_case(Mh,phase,mats,X)
bc=dir_bc(Mh,X);
Sp=g2_t6_elasticity_phase(Mh.X6,Mh.T6,phase,mats,bc);
[uex]=X.field(Mh.X6);uh=[Sp.u(1:2:end),Sp.u(2:2:end)];
R.eu=max(vecnorm(uh-uex,2,2))/max(vecnorm(uex,2,2));
R.eU=abs(Sp.strainEnergy-X.energy)/X.energy;
R.energyId=abs(Sp.strainEnergy-Sp.externalWork)/Sp.strainEnergy;
R.res=Sp.relativeResidual;R.pd=Sp.KffPositiveDefinite;
% interface moments from each side (3-point Gauss on every chord)
P=g2_material_phase_map(Mh.X6,Mh.T6,[0 0],X.a,X.b,struct());
if P.pass
 I=P.interfaces(1);ch=I.chords;gp=[.5-sqrt(15)/10,.5,.5+sqrt(15)/10];gw=[5 8 5]/18;
 Mside=zeros(2,3);
 for side=1:2
  own=I.innerOwner;if side==2,own=I.outerOwner;end
  pts=zeros(0,2);el=zeros(0,1);wl=zeros(0,1);nrm=zeros(0,2);
  for q=1:3
   p=Mh.X6(ch(:,1),:)+gp(q)*(Mh.X6(ch(:,2),:)-Mh.X6(ch(:,1),:));
   L=vecnorm(Mh.X6(ch(:,2),:)-Mh.X6(ch(:,1),:),2,2);
   tv=(Mh.X6(ch(:,2),:)-Mh.X6(ch(:,1),:))./L;nv=[tv(:,2),-tv(:,1)];
   flip=sum(nv.*p,2)<0;nv(flip,:)=-nv(flip,:);
   pts=[pts;p];el=[el;own];wl=[wl;gw(q)*L];nrm=[nrm;nv]; %#ok<AGROW>
  end
  Dk=zeros(3,3,numel(el));
  for i=1:numel(el),Dk(:,:,i)=g2_plane_D(mats(phase(el(i))));end
  s=g2_t6_point_stress(Mh.X6,Mh.T6,Sp.u,Dk,el,pts);
  tx=s(:,1).*nrm(:,1)+s(:,3).*nrm(:,2);ty=s(:,3).*nrm(:,1)+s(:,2).*nrm(:,2);
  tn=tx.*nrm(:,1)+ty.*nrm(:,2);tt=-tx.*nrm(:,2)+ty.*nrm(:,1);th=atan2(pts(:,2),pts(:,1));
  Mside(side,:)=[sum(wl.*tn),sum(wl.*tn.*cos(2*th)),sum(wl.*tt.*sin(2*th))];
 end
 ref=X.interfaceMoments;
 R.eT=max(max(abs(Mside-ref)./abs(ref)));
 R.eTside=max(abs(Mside(1,:)-Mside(2,:))./abs(ref));
 iDof=[2*[I.vertexNodes;I.midsideNodes]-1;2*[I.vertexNodes;I.midsideNodes]];
 f1=Sp.phaseNodalForce(iDof,1);f2=Sp.phaseNodalForce(iDof,2);
 R.balance=max(abs(f1+f2))/max(abs(f2));
 R.jump=0;
else
 R.eT=inf;R.eTside=inf;R.balance=inf;
 % detached interface: displacement jump between coincident node pairs
 [~,~,g]=uniquetol(Mh.X6,1e-9,'ByRows',true,'DataScale',1);
 cnt=accumarray(g,1);jump=0;
 for k=find(cnt>1).'
  ids=find(g==k);jump=max(jump,norm(Sp.u(2*ids(1)-1:2*ids(1))-Sp.u(2*ids(2)-1:2*ids(2))));
 end
 R.jump=jump;
end
end

function bc=dir_bc(Mh,X)
nodes=Mh.outerNodes;uex=X.field(Mh.X6(nodes,:));
bc=struct('fixedDofs',[2*nodes-1;2*nodes],'fixedValues',[uex(:,1);uex(:,2)],'F',zeros(2*size(Mh.X6,1),1));
end

function Mh=coated_mesh(a,b,c,h)
gd=[1 0 0 c;1 0 0 b;1 0 0 a].';
[dl,~]=decsg(gd,'(C3+C2)-C1',char('C3','C2','C1').');
model=createpde(1);geometryFromEdges(model,dl);
msh=generateMesh(model,'GeometricOrder','linear','Hmax',h,'Hmin',h/4,'Hgrad',1.3);
X=msh.Nodes.';T=msh.Elements.';
ar=(X(T(:,2),1)-X(T(:,1),1)).*(X(T(:,3),2)-X(T(:,1),2))-(X(T(:,3),1)-X(T(:,1),1)).*(X(T(:,2),2)-X(T(:,1),2));
T(ar<0,[2 3])=T(ar<0,[3 2]);
[X6,T6]=t3_to_t6(X,T);
r=hypot(X6(:,1),X6(:,2));
vt=unique(T(:));ring=vt(abs(r(vt)-c)<1e-9);[~,i]=sort(atan2(X6(ring,2),X6(ring,1)));ring=ring(i);
E=[T6(:,[1 2 4]);T6(:,[2 3 5]);T6(:,[3 1 6])];key=sort(E(:,1:2),2);
onOut=all(ismember(key,ring),2);
[~,~,ie]=unique(key,'rows');cnt=accumarray(ie,1);bnd=onOut&cnt(ie)==1;
Mh=struct('X6',X6,'T6',T6,'outerRing',ring,'outerNodes',unique([E(bnd,1);E(bnd,2);E(bnd,3)]));
end

function [X6,T6]=t3_to_t6(X,T)
M=size(T,1);E=[T(:,[1 2]);T(:,[2 3]);T(:,[3 1])];
[Eu,~,ie]=unique(sort(E,2),'rows');
mid=size(X,1)+(1:size(Eu,1))';
X6=[X;.5*(X(Eu(:,1),:)+X(Eu(:,2),:))];
T6=[T,reshape(mid(ie),M,3)];
end

function K=reference_assembly(X6,T6,phase,mats)
% Independent element loop: 6-point Dunavant (degree 4) rule, explicit B matrix.
qp=[0.445948490915965 0.445948490915965;0.445948490915965 0.108103018168070;0.108103018168070 0.445948490915965; ...
    0.091576213509771 0.091576213509771;0.091576213509771 0.816847572980459;0.816847572980459 0.091576213509771];
w=[0.223381589678011*[1 1 1],0.109951743655322*[1 1 1]]/2;
N=size(X6,1);M=size(T6,1);ii=zeros(144*M,1);jj=ii;vv=ii;p=0;
for e=1:M
 D=g2_plane_D(mats(phase(e)));nd=T6(e,:);x=X6(nd,1);y=X6(nd,2);Ke=zeros(12);
 for g=1:6
  r=qp(g,1);s=qp(g,2);t=1-r-s;
  dNr=[1-4*t,4*r-1,0,4*(t-r),4*s,-4*s];dNs=[1-4*t,0,4*s-1,-4*r,4*r,4*(t-s)];
  J=[dNr*x,dNs*x;dNr*y,dNs*y];G=J.'\[dNr;dNs];
  Bm=zeros(3,12);Bm(1,1:2:end)=G(1,:);Bm(2,2:2:end)=G(2,:);Bm(3,1:2:end)=G(2,:);Bm(3,2:2:end)=G(1,:);
  Ke=Ke+w(g)*det(J)*(Bm.'*D*Bm);
 end
 dof=reshape([2*nd-1;2*nd],1,12);[I,Jx]=ndgrid(dof,dof);
 ii(p+1:p+144)=I(:);jj(p+1:p+144)=Jx(:);vv(p+1:p+144)=Ke(:);p=p+144;
end
K=sparse(ii,jj,vv,2*N,2*N);K=(K+K.')/2;
end

function [Md,phd]=detach_half(Mh,P)
% Duplicate the interface nodes (vertices and midsides) with y > 0 for band elements only.
I=P.interfaces(1);nodes=unique([I.vertexNodes;I.midsideNodes]);
nodes=nodes(Mh.X6(nodes,2)>1e-6);
newID=size(Mh.X6,1)+(1:numel(nodes))';map=zeros(size(Mh.X6,1),1);map(nodes)=newID;
X6=[Mh.X6;Mh.X6(nodes,:)];T6=Mh.T6;band=find(P.phase==2);
for e=band.'
 for q=1:6,if map(T6(e,q))>0,T6(e,q)=map(T6(e,q));end,end
end
Md=struct('X6',X6,'T6',T6,'outerRing',Mh.outerRing,'outerNodes',Mh.outerNodes);phd=P.phase;
end
