function S = g2_t6_elasticity(X6,T6,mat,bc)
%G2_T6_ELASTICITY  Linear plane elasticity with straight-sided quadratic T6 elements.
%
%  S = g2_t6_elasticity(X6,T6,mat,bc)
%   X6  N-by-2 node coordinates (mm); T6 M-by-6 [v1 v2 v3 m12 m23 m31]
%   mat struct: E (MPa), nu, plane = 'stress' | 'strain'
%   bc  struct: fixedDofs (indices into the 2N DOF vector, DOF 2k-1 = u_x of
%       node k, 2k = u_y), fixedValues (same size), F (2N-by-1 nodal forces, N
%       per unit thickness)
% Returns u (2N-by-1), the relative residual of the free equations, the
% reactions at the fixed DOFs (K*u - F), the strain energy 0.5*u'*K*u and the
% external work 0.5*(F'*u + reactions'*u_fixed). Units: mm, N, MPa.
% Stiffness by the 3-point degree-2 rule, exact for straight-sided T6.
assert(size(X6,2)==2&&size(T6,2)==6,'G2T6:Shape','Expected N-by-2 coordinates and M-by-6 elements.');
N=size(X6,1);M=size(T6,1);nd=2*N;
D=g2_plane_D(mat);
[x,y]=deal(reshape(X6(T6(:),1),M,6),reshape(X6(T6(:),2),M,6));
J11=x(:,2)-x(:,1);J12=x(:,3)-x(:,1);J21=y(:,2)-y(:,1);J22=y(:,3)-y(:,1);
detJ=J11.*J22-J12.*J21;
assert(all(detJ>0),'G2T6:Jacobian','%d elements with nonpositive Jacobian.',nnz(detJ<=0));
qp=[1/6 1/6;2/3 1/6;1/6 2/3];w=[1/6;1/6;1/6];
Ke=zeros(M,12,12);
for g=1:3
 [dNr,dNs]=t6_dN(qp(g,1),qp(g,2));
 % dN/dx = (J22*dNr - J21*dNs)/det, dN/dy = (-J12*dNr + J11*dNs)/det  (J = [dx/dr dx/ds; dy/dr dy/ds])
 Nx=(J22*dNr-J21*dNs)./detJ;Ny=(-J12*dNr+J11*dNs)./detJ;
 c=w(g)*detJ;
 for a=1:6
  for b=1:6
   kuu=c.*(D(1,1)*Nx(:,a).*Nx(:,b)+D(3,3)*Ny(:,a).*Ny(:,b));
   kuv=c.*(D(1,2)*Nx(:,a).*Ny(:,b)+D(3,3)*Ny(:,a).*Nx(:,b));
   kvu=c.*(D(1,2)*Ny(:,a).*Nx(:,b)+D(3,3)*Nx(:,a).*Ny(:,b));
   kvv=c.*(D(2,2)*Ny(:,a).*Ny(:,b)+D(3,3)*Nx(:,a).*Nx(:,b));
   Ke(:,2*a-1,2*b-1)=Ke(:,2*a-1,2*b-1)+kuu;
   Ke(:,2*a-1,2*b)  =Ke(:,2*a-1,2*b)  +kuv;
   Ke(:,2*a,2*b-1)  =Ke(:,2*a,2*b-1)  +kvu;
   Ke(:,2*a,2*b)    =Ke(:,2*a,2*b)    +kvv;
  end
 end
end
dof=zeros(M,12);dof(:,1:2:end)=2*T6-1;dof(:,2:2:end)=2*T6;
I=repmat(dof,1,12);Jc=kron(dof,ones(1,12));
K=sparse(I(:),Jc(:),Ke(:),nd,nd);   % I(:,(j-1)*12+i)=dof(:,i), Jc(...)=dof(:,j), value Ke(:,i,j)
K=(K+K.')/2;
fixed=bc.fixedDofs(:);ufix=bc.fixedValues(:);
assert(numel(unique(fixed))==numel(fixed),'G2T6:DuplicateBC','Duplicate fixed DOFs.');
free=setdiff((1:nd)',fixed);
F=bc.F(:);assert(numel(F)==nd,'G2T6:F','F must have 2N entries.');
u=zeros(nd,1);u(fixed)=ufix;
rhs=F(free)-K(free,fixed)*ufix;
u(free)=K(free,free)\rhs;
r=K*u-F;
S=struct('u',u,'K',K,'D',D,'freeDofs',free, ...
 'relativeResidual',norm(r(free))/max(norm(rhs),eps), ...
 'reactions',r(fixed),'fixedDofs',fixed, ...
 'strainEnergy',.5*(u.'*K*u),'externalWork',.5*(F.'*u+r(fixed).'*ufix), ...
 'dofs',nd,'elements',M);
end

function [dNr,dNs]=t6_dN(r,s)
t=1-r-s;
dNr=[-(4*t-1),4*r-1,0,4*(t-r),4*s,-4*s];
dNs=[-(4*t-1),0,4*s-1,-4*r,4*r,4*(t-s)];
end
