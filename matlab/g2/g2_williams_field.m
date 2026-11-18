function W = g2_williams_field(x1,x2,KI,KII,T,mu,kappa)
%G2_WILLIAMS_FIELD  Williams near-tip field (K_I, K_II leading terms + T-stress), local crack frame.
% x1 along the crack (ahead of the tip), x2 normal; theta in (-pi, pi], crack faces at theta = +-pi.
% Units consistent with the inputs (here mm, MPa, K in MPa*sqrt(mm)).
% Returns local displacements u1,u2, displacement gradients du_i/dx_j (analytic,
% via d/dr and d/dtheta) and stresses s11,s22,s12 from the classical formulas.
% g2 tests compare the stresses with Hooke's law applied to the gradients (S2).
x1=x1(:);x2=x2(:);
r=hypot(x1,x2);th=atan2(x2,x1);
c=cos(th/2);s=sin(th/2);c3=cos(3*th/2);s3=sin(3*th/2);
A=1/(2*mu*sqrt(2*pi));sr=sqrt(r);
% mode I: u = KI*A*sqrt(r)*[f1 g1]
f1=c.*(kappa-1+2*s.^2);         f1p=-.5*s.*(kappa-1+2*s.^2)+c.*sin(th);
g1=s.*(kappa+1-2*c.^2);         g1p= .5*c.*(kappa+1-2*c.^2)+s.*sin(th);
% mode II: u = KII*A*sqrt(r)*[f2 g2]
f2=s.*(kappa+1+2*c.^2);         f2p= .5*c.*(kappa+1+2*c.^2)-s.*sin(th);
g2=-c.*(kappa-1-2*s.^2);        g2p= .5*s.*(kappa-1-2*s.^2)+c.*sin(th);
u1=A*sr.*(KI*f1+KII*f2);u2=A*sr.*(KI*g1+KII*g2);
du1dr=A./(2*sr).*(KI*f1+KII*f2);du1dt=A*sr.*(KI*f1p+KII*f2p);
du2dr=A./(2*sr).*(KI*g1+KII*g2);du2dt=A*sr.*(KI*g1p+KII*g2p);
ct=cos(th);st=sin(th);
G11=ct.*du1dr-st./r.*du1dt;G12=st.*du1dr+ct./r.*du1dt;
G21=ct.*du2dr-st./r.*du2dt;G22=st.*du2dr+ct./r.*du2dt;
% T-stress term: u1 = T(kappa+1)/(8mu) x1, u2 = T(kappa-3)/(8mu) x2
bT=T*(kappa+1)/(8*mu);cT=T*(kappa-3)/(8*mu);
u1=u1+bT*x1;u2=u2+cT*x2;G11=G11+bT;G22=G22+cT;
k=1./sqrt(2*pi*r);
s11=k.*(KI*c.*(1-s.*s3)-KII*s.*(2+c.*c3))+T;
s22=k.*(KI*c.*(1+s.*s3)+KII*s.*c.*c3);
s12=k.*(KI*c.*s.*c3+KII*c.*(1-s.*s3));
W=struct('r',r,'theta',th,'u1',u1,'u2',u2,'G11',G11,'G12',G12,'G21',G21,'G22',G22, ...
 's11',s11,'s22',s22,'s12',s12);
end
