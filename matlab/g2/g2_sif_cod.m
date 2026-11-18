function R = g2_sif_cod(X6,T6,u,mat,tip,tdir,window)
%G2_SIF_COD  Signed K_I, K_II by crack-face displacement extrapolation (independent of EDI).
%
%  R = g2_sif_cod(X6,T6,u,mat,tip,tdir,window)
% Uses only nodal displacements of the T6 crack-face twin nodes. The crack faces
% are found geometrically from the mesh (one-owner T3 edges on the crack line
% behind the tip); each face node is assigned to the upper (theta = +pi, +n side)
% or lower face by the side of its owning element. No auxiliary field, no
% q function and no stress is used.
%   delta = u(upper) - u(lower);  K_app(r) = (E'/8)*sqrt(2*pi/r)*[delta.n, delta.t]
%   K(r) = K0 + K1*r fitted by least squares on window(1) <= r <= window(2) mm.
t=tdir(:).'/norm(tdir);n=[-t(2),t(1)];
[~,Ep]=g2_plane_D(mat);
tol=1e-9;M=size(T6,1);
loc=@(P)[(P(:,1)-tip(1))*t(1)+(P(:,2)-tip(2))*t(2),(P(:,1)-tip(1))*n(1)+(P(:,2)-tip(2))*n(2)];
L=loc(X6);
E3=[T6(:,[1 2 4]);T6(:,[2 3 5]);T6(:,[3 1 6])];   % [cornerA cornerB midside]
own=repmat((1:M)',3,1);
key=sort(E3(:,1:2),2);
[~,~,ic]=unique(key,'rows');cnt=accumarray(ic,1);
onCrack=cnt(ic)==1&abs(L(E3(:,1),2))<tol&abs(L(E3(:,2),2))<tol&L(E3(:,1),1)<tol&L(E3(:,2),1)<tol;
ce=(X6(T6(own,1),:)+X6(T6(own,2),:)+X6(T6(own,3),:))/3;
side=sign(loc(ce)*[0;1]);           % +1 upper (+n side), -1 lower
up=unique(reshape(E3(onCrack&side>0,:),[],1));lo=unique(reshape(E3(onCrack&side<0,:),[],1));
tipID=find(vecnorm(X6-tip(:).',2,2)<tol);
up(up==tipID)=[];lo(lo==tipID)=[];
assert(numel(up)==numel(lo)&&~isempty(up),'G2COD:Banks','Unequal or empty crack-face node sets.');
[~,iu]=sort(-L(up,1));up=up(iu);[~,il]=sort(-L(lo,1));lo=lo(il);
assert(max(vecnorm(X6(up,:)-X6(lo,:),2,2))<tol,'G2COD:Pairing','Crack-face twins do not coincide.');
r=-L(up,1);
d=[u(2*up-1)-u(2*lo-1),u(2*up)-u(2*lo)];
dn=d*n.';dt=d*t.';
c=Ep/8*sqrt(2*pi./r);
KIapp=c.*dn;KIIapp=c.*dt;
sel=r>=window(1)-1e-12&r<=window(2)+1e-12;
assert(nnz(sel)>=3,'G2COD:Window','Fewer than three node pairs in the fit window.');
A=[ones(nnz(sel),1),r(sel)];
pI=A\KIapp(sel);pII=A\KIIapp(sel);
R=struct('KI',pI(1),'KII',pII(1),'slopeI',pI(2),'slopeII',pII(2),'window',window, ...
 'pairsInWindow',nnz(sel),'r',r,'KIapp',KIapp,'KIIapp',KIIapp,'upperNodes',up,'lowerNodes',lo,'Ep',Ep);
end
