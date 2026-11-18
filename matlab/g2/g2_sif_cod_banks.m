function R = g2_sif_cod_banks(X6,u,mat,tip,tdir,upperBank,lowerBank,lastSegment_mm,window)
%G2_SIF_COD_BANKS  Signed K_I, K_II from crack-face displacement jumps of SAVED bank twins (kink-aware).
%
%  R = g2_sif_cod_banks(X6,u,mat,tip,tdir,upperBank,lowerBank,lastSegment_mm,window)
% WP3.2 (Issue #24). Independent of the EDI (no auxiliary field, no q, no stress).
% Unlike g2_sif_cod (unchanged, geometric face classifier), the faces are the SAVED
% upper (+n) and lower bank T6 node IDs. Only twins on the final segment are used:
% local eta = 0 (1e-9 mm) and 0 < r <= lastSegment_mm; nothing is combined across a
% kink. Twins are paired by coordinate (1e-9 mm) and must have distinct IDs.
%   delta = u(upper) - u(lower);  K_app(r) = (E'/8) sqrt(2 pi / r) [delta.n, delta.t]
%   K(r) = K0 + K1 r, least squares on window(1) <= r <= window(2) (preregistered 0.1-1.5 mm).
t=tdir(:).'/norm(tdir);n=[-t(2),t(1)];
[~,Ep]=g2_plane_D(mat);tol=1e-9;tip=tip(:).';
U=upperBank(:);L=lowerBank(:);
loc=@(ids)[(X6(ids,:)-tip)*t.',(X6(ids,:)-tip)*n.'];
lu=loc(U);ll=loc(L);
su=abs(lu(:,2))<tol&lu(:,1)<-tol&lu(:,1)>=-lastSegment_mm-tol;
sl=abs(ll(:,2))<tol&ll(:,1)<-tol&ll(:,1)>=-lastSegment_mm-tol;
U=U(su);L=L(sl);
assert(numel(U)==numel(L)&&numel(U)>=3,'G2CODB:Banks','Unequal or too few final-segment bank nodes (%d/%d).',numel(U),numel(L));
[~,iu]=sort(-lu(su,1));U=U(iu);[~,il]=sort(-ll(sl,1));L=L(il);
assert(max(vecnorm(X6(U,:)-X6(L,:),2,2))<tol&&all(U~=L),'G2CODB:Twins','Final-segment twins do not coincide or are welded.');
r=-loc(U)*[1;0];
d=[u(2*U-1)-u(2*L-1),u(2*U)-u(2*L)];
c=Ep/8*sqrt(2*pi./r);KIapp=c.*(d*n.');KIIapp=c.*(d*t.');
sel=r>=window(1)-1e-12&r<=window(2)+1e-12;
assert(nnz(sel)>=3,'G2CODB:Window','Fewer than three twin pairs in the fit window.');
A=[ones(nnz(sel),1),r(sel)];pI=A\KIapp(sel);pII=A\KIIapp(sel);
R=struct('KI',pI(1),'KII',pII(1),'slopeI',pI(2),'slopeII',pII(2),'window',window,'pairsInWindow',nnz(sel), ...
 'pairsOnFinalSegment',numel(U),'maxR',max(r),'r',r,'KIapp',KIapp,'KIIapp',KIIapp,'upperNodes',U,'lowerNodes',L,'Ep',Ep);
end
