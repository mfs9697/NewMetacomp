function S = g2_t6_elasticity_phase(X6,T6,phase,mats,bc)
%G2_T6_ELASTICITY_PHASE  Multi-phase plane elasticity on straight-sided T6 (Issue #33).
%
%  S = g2_t6_elasticity_phase(X6,T6,phase,mats,bc)
%   X6, T6, bc  as in g2_t6_elasticity (unchanged; mm, N, MPa, per unit thickness)
%   phase       M-by-1 positive integer label of every element
%   mats        struct array, mats(p) = struct('E',..,'nu',..,'plane',..) for label p
% Perfect bond: phases share the nodal DOFs of T6 (no duplication, no interface
% elements). Voids are absent elements; nothing is filled. Each element uses its own
% D_e = g2_plane_D(mats(phase(e))). The kinematics, 3-point rule and assembly
% order are the same as g2_t6_elasticity, so equal moduli give the same
% floating-point stiffness.
% Extra outputs: phaseStrainEnergy (per label), phaseNodalForce (2N-by-nPhase,
% K_p*u from the elements of label p only), elementDminEig, KffPositiveDefinite.
assert(size(X6,2)==2&&size(T6,2)==6,'G2T6P:Shape','Expected N-by-2 coordinates and M-by-6 elements.');
N=size(X6,1);M=size(T6,1);nd=2*N;
phase=phase(:);
assert(numel(phase)==M&&all(phase>=1)&&all(phase==round(phase))&&max(phase)<=numel(mats), ...
 'G2T6P:Phase','Every element needs a valid phase label.');
nP=numel(mats);Dp=zeros(3,3,nP);minEig=zeros(nP,1);
for p=1:nP
 assert(isfinite(mats(p).E)&&mats(p).E>0&&mats(p).nu>-1&&mats(p).nu<.5,'G2T6P:Material','Inadmissible material %d.',p);
 Dp(:,:,p)=g2_plane_D(mats(p));minEig(p)=min(eig(Dp(:,:,p)));
end
assert(all(minEig>0),'G2T6P:DnotPD','A phase constitutive matrix is not positive definite.');
D11=reshape(Dp(1,1,phase),M,1);D12=reshape(Dp(1,2,phase),M,1);
D22=reshape(Dp(2,2,phase),M,1);D33=reshape(Dp(3,3,phase),M,1);
[x,y]=deal(reshape(X6(T6(:),1),M,6),reshape(X6(T6(:),2),M,6));
J11=x(:,2)-x(:,1);J12=x(:,3)-x(:,1);J21=y(:,2)-y(:,1);J22=y(:,3)-y(:,1);
detJ=J11.*J22-J12.*J21;
assert(all(detJ>0),'G2T6P:Jacobian','%d elements with nonpositive Jacobian.',nnz(detJ<=0));
qp=[1/6 1/6;2/3 1/6;1/6 2/3];w=[1/6;1/6;1/6];
Ke=zeros(M,12,12);
for g=1:3
 [dNr,dNs]=t6_dN(qp(g,1),qp(g,2));
 Nx=(J22*dNr-J21*dNs)./detJ;Ny=(-J12*dNr+J11*dNs)./detJ;
 c=w(g)*detJ;
 for a=1:6
  for b=1:6
   kuu=c.*(D11.*Nx(:,a).*Nx(:,b)+D33.*Ny(:,a).*Ny(:,b));
   kuv=c.*(D12.*Nx(:,a).*Ny(:,b)+D33.*Ny(:,a).*Nx(:,b));
   kvu=c.*(D12.*Ny(:,a).*Nx(:,b)+D33.*Nx(:,a).*Ny(:,b));
   kvv=c.*(D22.*Ny(:,a).*Ny(:,b)+D33.*Nx(:,a).*Nx(:,b));
   Ke(:,2*a-1,2*b-1)=Ke(:,2*a-1,2*b-1)+kuu;
   Ke(:,2*a-1,2*b)  =Ke(:,2*a-1,2*b)  +kuv;
   Ke(:,2*a,2*b-1)  =Ke(:,2*a,2*b-1)  +kvu;
   Ke(:,2*a,2*b)    =Ke(:,2*a,2*b)    +kvv;
  end
 end
end
dof=zeros(M,12);dof(:,1:2:end)=2*T6-1;dof(:,2:2:end)=2*T6;
I=repmat(dof,1,12);Jc=kron(dof,ones(1,12));
K=sparse(I(:),Jc(:),Ke(:),nd,nd);
K=(K+K.')/2;
fixed=bc.fixedDofs(:);ufix=bc.fixedValues(:);
assert(numel(unique(fixed))==numel(fixed),'G2T6P:DuplicateBC','Duplicate fixed DOFs.');
free=setdiff((1:nd)',fixed);
F=bc.F(:);assert(numel(F)==nd,'G2T6P:F','F must have 2N entries.');
u=zeros(nd,1);u(fixed)=ufix;
rhs=F(free)-K(free,fixed)*ufix;
u(free)=K(free,free)\rhs;
r=K*u-F;
[~,cholFlag,~]=chol(K(free,free),'vector');   % AMD-ordered sparse Cholesky: positive definiteness only
% per-phase energies and internal nodal forces (elements of one label only)
Ue=zeros(M,12);ux=u(dof);Ue(:)=ux(:);
eE=zeros(M,1);
for i=1:12
 for j=1:12,eE=eE+.5*Ue(:,i).*Ke(:,i,j).*Ue(:,j);end
end
phaseU=accumarray(phase,eE,[nP 1]);
fP=zeros(nd,nP);
for p=1:nP
 sel=phase==p;
 if ~any(sel),continue,end
 KeU=zeros(nnz(sel),12);
 for i=1:12
  for j=1:12,KeU(:,i)=KeU(:,i)+Ke(sel,i,j).*Ue(sel,j);end
 end
 ds=dof(sel,:);fP(:,p)=accumarray(ds(:),KeU(:),[nd 1]);
end
S=struct('u',u,'K',K,'freeDofs',free, ...
 'relativeResidual',norm(r(free))/max(norm(rhs),eps), ...
 'reactions',r(fixed),'fixedDofs',fixed, ...
 'strainEnergy',.5*(u.'*K*u),'externalWork',.5*(F.'*u+r(fixed).'*ufix), ...
 'phaseStrainEnergy',phaseU,'elementStrainEnergy',eE,'phaseNodalForce',fP, ...
 'phaseDminEig',minEig,'KffPositiveDefinite',cholFlag==0, ...
 'dofs',nd,'elements',M,'phaseCounts',accumarray(phase,1,[nP 1]));
end

function [dNr,dNs]=t6_dN(r,s)
t=1-r-s;
dNr=[-(4*t-1),4*r-1,0,4*(t-r),4*s,-4*s];
dNs=[-(4*t-1),0,4*s-1,-4*r,4*r,4*(t-s)];
end
