function R = g2_sif_interaction(X6,T6,u,mat,tip,tdir,rin,rout,nGauss)
%G2_SIF_INTERACTION  Signed K_I, K_II and J by the domain interaction integral (FE-nodal q).
%
%  R = g2_sif_interaction(X6,T6,u,mat,tip,tdir,rin,rout,nGauss)
% q = 1 for r <= rin, linear to 0 at r = rout, interpolated with the T6 shape
% functions from its nodal values (the source p010 definition). Only elements in
% which q varies contribute. Auxiliary fields: Williams leading terms with
% K_aux = 1 (g2_williams_field). Collapsed nGauss x nGauss Gauss rule per element.
%   I = int [ s_ij du^a_i/dx1 + s^a_ij du_i/dx1 - s_kl e^a_kl d_1j ] dq/dx_j dA
%   K = E'/2 * I ;  J = int [ s_ij du_i/dx1 - W d_1j ] dq/dx_j dA
% Local frame: x1 along tdir (crack growth direction), x2 along n = rot(+90 deg) tdir.
% Units: mm, MPa -> K in MPa*sqrt(mm), J in N/mm.
if nargin<9,nGauss=6;end
t=tdir(:).'/norm(tdir);n=[-t(2),t(1)];Rm=[t;n];
[D,Ep,kappa,mu]=g2_plane_D(mat);
N=size(X6,1);ux=u(1:2:end);uy=u(2:2:end);
assert(numel(ux)==N,'G2EDI:Size','u must have 2N entries.');
r6=vecnorm(X6-tip(:).',2,2);
q=ones(N,1);q(r6>=rout)=0;tr=r6>rin&r6<rout;q(tr)=(rout-r6(tr))/(rout-rin);
act=find(max(q(T6),[],2)-min(q(T6),[],2)>1e-14);
E=T6(act,:);Me=numel(act);
x=reshape(X6(E(:),1),Me,6);y=reshape(X6(E(:),2),Me,6);
Ue=reshape(ux(E(:)),Me,6);Ve=reshape(uy(E(:)),Me,6);Qe=reshape(q(E(:)),Me,6);
J11=x(:,2)-x(:,1);J12=x(:,3)-x(:,1);J21=y(:,2)-y(:,1);J22=y(:,3)-y(:,1);
detJ=J11.*J22-J12.*J21;
[gx,gw]=gauss_legendre(nGauss);
II=0;III=0;JJ=0;
for a=1:nGauss
 for b=1:nGauss
  rr=gx(a);ss=gx(b)*(1-gx(a));wq=gw(a)*gw(b)*(1-gx(a));
  [Nv,dNr,dNs]=t6(rr,ss);
  Nx=(J22*dNr-J21*dNs)./detJ;Ny=(-J12*dNr+J11*dNs)./detJ;
  px=x*Nv.';py=y*Nv.';
  % displacement gradient (global) and q gradient
  g11=sum(Nx.*Ue,2);g12=sum(Ny.*Ue,2);g21=sum(Nx.*Ve,2);g22=sum(Ny.*Ve,2);
  qx=sum(Nx.*Qe,2);qy=sum(Ny.*Qe,2);
  % rotate to the local frame: G' = R G R^T, grad q' = R grad q
  [G11,G12,G21,G22]=rot2(Rm,g11,g12,g21,g22);
  q1=Rm(1,1)*qx+Rm(1,2)*qy;q2=Rm(2,1)*qx+Rm(2,2)*qy;
  e11=G11;e22=G22;e12=.5*(G12+G21);
  s11=D(1,1)*e11+D(1,2)*e22;s22=D(1,2)*e11+D(2,2)*e22;s12=D(3,3)*2*e12;
  lx=(px-tip(1))*t(1)+(py-tip(2))*t(2);lyy=(px-tip(1))*n(1)+(py-tip(2))*n(2);
  w=wq*detJ;
  for m=1:2
   A=g2_williams_field(lx,lyy,double(m==1),double(m==2),0,mu,kappa);
   ea12=.5*(A.G12+A.G21);
   t1=(s11.*A.G11+s12.*A.G21).*q1+(s12.*A.G11+s22.*A.G21).*q2;
   t2=(A.s11.*G11+A.s12.*G21).*q1+(A.s12.*G11+A.s22.*G21).*q2;
   wi=s11.*A.G11+s22.*A.G22+2*s12.*ea12;
   val=sum(w.*(t1+t2-wi.*q1));
   if m==1,II=II+val;else,III=III+val;end
  end
  Wd=.5*(s11.*e11+s22.*e22+2*s12.*e12);
  JJ=JJ+sum(w.*((s11.*G11+s12.*G21).*q1+(s12.*G11+s22.*G21).*q2-Wd.*q1));
 end
end
R=struct('KI',Ep/2*II,'KII',Ep/2*III,'J',JJ,'Ep',Ep,'rin',rin,'rout',rout,'nGauss',nGauss, ...
 'activeElements',Me,'activeRows',act,'maxSupportRadius',max(r6(unique(E(:)))), ...
 'JfromK',(Ep/2*II)^2/Ep+(Ep/2*III)^2/Ep);
end

function [x,w]=gauss_legendre(n)
% Gauss-Legendre on [0,1] (Golub-Welsch)
b=(1:n-1)./sqrt(4*(1:n-1).^2-1);
[V,Dd]=eig(diag(b,1)+diag(b,-1));
[x,i]=sort(diag(Dd));w=2*V(1,i).^2;x=(x+1)/2;w=w(:)/2;
end

function [N,dNr,dNs]=t6(r,s)
t=1-r-s;
N=[t*(2*t-1),r*(2*r-1),s*(2*s-1),4*r*t,4*r*s,4*s*t];
dNr=[-(4*t-1),4*r-1,0,4*(t-r),4*s,-4*s];
dNs=[-(4*t-1),0,4*s-1,-4*r,4*r,4*(t-s)];
end

function [H11,H12,H21,H22]=rot2(R,g11,g12,g21,g22)
% H = R*G*R'
a11=R(1,1);a12=R(1,2);a21=R(2,1);a22=R(2,2);
P11=a11*g11+a12*g21;P12=a11*g12+a12*g22;P21=a21*g11+a22*g21;P22=a21*g12+a22*g22;
H11=P11*a11+P12*a12;H12=P11*a21+P12*a22;H21=P21*a11+P22*a12;H22=P21*a21+P22*a22;
end
