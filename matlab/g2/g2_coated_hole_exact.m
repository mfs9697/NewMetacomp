function B = g2_coated_hole_exact(a,b,c,Er,Em,nu,S)
%G2_COATED_HOLE_EXACT  Exact plane-stress field of a coated circular hole in a finite disk (Issue #33 benchmark).
%
%  B = g2_coated_hole_exact(a,b,c,Er,Em,nu,S)
% Void r < a; perfectly bonded band a < r < b (Er, nu); matrix b < r < c (Em, nu).
% Loads: traction-free hole; continuity of u_r, u_theta, s_rr, s_rtheta at r = b;
% at r = c the traction of a remote uniaxial stress S along x:
%   s_rr = S/2 + S/2 cos(2 th),  s_rth = -S/2 sin(2 th).
% Fields per region (plane stress):
%   axisymmetric  u_r = A0 r + B0/r
%   cos(2 th)     Airy f(r) cos(2 th), f = A r^2 + B r^4 + C r^-2 + D
%     s_rr = -(2A + 6C/r^4 + 4D/r^2) cos2th, s_thth = (2A + 12B r^2 + 6C/r^4) cos2th,
%     s_rth = (2A + 6B r^2 - 6C/r^4 - 2D/r^2) sin2th,
%     u_r = g cos2th, u_th = h sin2th with
%     E g = -2A(1+nu) r - 4 nu B r^3 + 2C(1+nu)/r^3 + 4D/r
%     E h =  2A(1+nu) r + (6+2nu) B r^3 + 2C(1+nu)/r^3 - 2(1-nu) D/r
% (Kirsch is recovered for Er = Em, c -> inf.) The field is self-checked by the
% caller (finite-difference strains -> Hooke -> these stresses).
% B.field(X) returns u (N-by-2), sigma [sxx syy sxy] (N-by-3) at points X (mm),
% using the band constants for r < b and the matrix constants for r >= b.
E=[Er;Em];
% ---- axisymmetric: unknowns [A0r B0r A0m B0m]
sr0=@(Ei,r)Ei/(1-nu^2)*[(1+nu),-(1-nu)/r^2];
A=zeros(4);rhs=zeros(4,1);
A(1,1:2)=sr0(Er,a);
A(2,:)=[b,1/b,-b,-1/b];
A(3,:)=[sr0(Er,b),-sr0(Em,b)];
A(4,3:4)=sr0(Em,c);rhs(4)=S/2;
x0=A\rhs;
% ---- cos(2 th): unknowns [Ar Br Cr Dr Am Bm Cm Dm]
srr=@(r)[-2,0,-6/r^4,-4/r^2];
srt=@(r)[2,6*r^2,-6/r^4,-2/r^2];
gg=@(Ei,r)[-2*(1+nu)*r,-4*nu*r^3,2*(1+nu)/r^3,4/r]/Ei;
hh=@(Ei,r)[2*(1+nu)*r,(6+2*nu)*r^3,2*(1+nu)/r^3,-2*(1-nu)/r]/Ei;
Z=zeros(1,4);
A2=[srr(a),Z;srt(a),Z;gg(Er,b),-gg(Em,b);hh(Er,b),-hh(Em,b);srr(b),-srr(b);srt(b),-srt(b);Z,srr(c);Z,srt(c)];
rhs2=[0;0;0;0;0;0;S/2;-S/2];
x2=A2\rhs2;
B=struct('a',a,'b',b,'c',c,'Er',Er,'Em',Em,'nu',nu,'S',S,'axisym',x0,'cos2',x2, ...
 'conditionAxisym',cond(A),'conditionCos2',cond(A2));
B.field=@(X)field(X,x0,x2,b,E,nu);
B.polar=@(r)polar(r,x0,x2,b,E,nu);
% Exact strain energy (per unit thickness) by Clapeyron on r = c (hole free, interface internal)
th=linspace(0,2*pi,4097);th(end)=[];
P=B.polar(c);
B.energy=.5*c*mean((P.srr0+P.srr2*cos(2*th)).*(P.ur0+P.g*cos(2*th))+(P.srt2*sin(2*th)).*(P.h*sin(2*th)))*2*pi;
% Exact interface moments (closed circle r = b)
Pb=B.polar(b*(1-eps));
B.interfaceMoments=[2*pi*b*Pb.srr0, pi*b*Pb.srr2, pi*b*Pb.srt2];   % int s_rr, int s_rr cos2th, int s_rth sin2th
end

function P=polar(r,x0,x2,b,E,nu)
r=r(:);inR=r<b;Ei=E(2)*ones(size(r));Ei(inR)=E(1);
A0=x0(3)*ones(size(r));B0=x0(4)*ones(size(r));A0(inR)=x0(1);B0(inR)=x0(2);
c2=repmat(x2(5:8).',numel(r),1);c2(inR,:)=repmat(x2(1:4).',nnz(inR),1);
Ac=c2(:,1);Bc=c2(:,2);Cc=c2(:,3);Dc=c2(:,4);
P.ur0=A0.*r+B0./r;
P.srr0=Ei/(1-nu^2).*((1+nu)*A0-(1-nu)*B0./r.^2);
P.stt0=Ei/(1-nu^2).*((1+nu)*A0+(1-nu)*B0./r.^2);
P.srr2=-(2*Ac+6*Cc./r.^4+4*Dc./r.^2);
P.stt2=2*Ac+12*Bc.*r.^2+6*Cc./r.^4;
P.srt2=2*Ac+6*Bc.*r.^2-6*Cc./r.^4-2*Dc./r.^2;
P.g=(-2*Ac*(1+nu).*r-4*nu*Bc.*r.^3+2*Cc*(1+nu)./r.^3+4*Dc./r)./Ei;
P.h=(2*Ac*(1+nu).*r+(6+2*nu)*Bc.*r.^3+2*Cc*(1+nu)./r.^3-2*(1-nu)*Dc./r)./Ei;
end

function [u,s]=field(X,x0,x2,b,E,nu)
r=hypot(X(:,1),X(:,2));th=atan2(X(:,2),X(:,1));
P=polar(r,x0,x2,b,E,nu);
c2=cos(2*th);s2=sin(2*th);
ur=P.ur0+P.g.*c2;ut=P.h.*s2;
co=cos(th);si=sin(th);
u=[ur.*co-ut.*si,ur.*si+ut.*co];
srr=P.srr0+P.srr2.*c2;stt=P.stt0+P.stt2.*c2;srt=P.srt2.*s2;
s=[srr.*co.^2+stt.*si.^2-2*srt.*si.*co, srr.*si.^2+stt.*co.^2+2*srt.*si.*co, (srr-stt).*si.*co+srt.*(co.^2-si.^2)];
end
