function O = g2_m4b_ring_owner_oracle(X6,T6,centres,holeR,ringR,opts)
%G2_M4B_RING_OWNER_ORACLE  Independent geometric ring ownership of every element (Issue #47).
%
%  O = g2_m4b_ring_owner_oracle(X6,T6,centres,holeR,ringR,opts)
% Written for G2-M4.B without any code of g2_material_phase_map (flood fill) or
% g2_material_phase_verify (inpolygon). For each ring h the polygon is the closed
% chain of saved T3 vertices on |x - c_h| = ringR(h) (tolerance opts.onCircleTol_mm),
% in angular order; the hole polygon likewise at holeR(h). Both polygons are convex
% and star-shaped from c_h, so a node is classified by the ONE chord whose angular
% sector contains it: signed distance s = n_in . (x - v_j) with the inward chord
% normal; inside s > tol, on |s| <= tol, outside s < -tol.
% Element e is owned by ring h iff all six T6 nodes are inside-or-on polygon h and
% at least one is strictly inside; an element with nodes strictly on both sides
% straddles (failure). Owner 0 = matrix. Any node strictly inside a hole polygon is
% a void violation. Returns O.ownerOracle (M-by-1, 0..3), O.pass, O.checks, and the
% polygon vertex chains O.ringVertices / O.holeVertices (row h = ring ID h).
if nargin<6,opts=struct();end
tol=getf(opts,'onCircleTol_mm',1e-9);
nH=numel(holeR);centres=reshape(centres,nH,2);holeR=holeR(:);ringR=ringR(:);
M=size(T6,1);T3=T6(:,1:3);vtx=unique(T3(:));
O=struct('pass',false,'checks',struct(),'ownerOracle',zeros(M,1),'ringVertices',{cell(nH,1)},'holeVertices',{cell(nH,1)});
inside=zeros(size(X6,1),nH);            % +1 inside, 0 on, -1 outside (ring polygons)
holeIn=false(size(X6,1),1);
for h=1:nH
 [vr,okR]=chain(X6,vtx,centres(h,:),ringR(h),tol);
 [vh,okH]=chain(X6,vtx,centres(h,:),holeR(h),tol);
 O.ringVertices{h}=vr;O.holeVertices{h}=vh;
 if ~okR||~okH,O.checks.polygonsResolved=false;return,end
 inside(:,h)=classify(X6,X6(vr,:),centres(h,:),ringR(h),tol);
 holeIn=holeIn|classify(X6,X6(vh,:),centres(h,:),holeR(h),tol)>0;
end
O.checks.polygonsResolved=true;
own=zeros(M,1);straddle=false(M,1);multi=false(M,1);
for h=1:nH
 c=reshape(inside(T6(:),h),M,6);
 straddle=straddle|(any(c>0,2)&any(c<0,2));
 in=all(c>=0,2)&any(c>0,2);
 multi=multi|(in&own>0);
 own(in)=h;
end
O.ownerOracle=own;
O.checks.noStraddle=~any(straddle);
O.checks.uniqueOwner=~any(multi);
O.checks.noNodeInsideHole=~any(holeIn);
O.values=struct('straddling',nnz(straddle),'multiOwned',nnz(multi),'nodesInsideHoles',nnz(holeIn), ...
 'elementsPerRing',accumarray(own(own>0),1,[nH 1]).','matrixElements',nnz(own==0), ...
 'chordsPerRing',cellfun(@numel,O.ringVertices).','holeVerticesPerRing',cellfun(@numel,O.holeVertices).');
f=fieldnames(O.checks);O.pass=all(cellfun(@(k)O.checks.(k),f));
O.failed=f(~cellfun(@(k)O.checks.(k),f));
end

function [v,ok]=chain(X,vtx,c0,R,tol)
r=hypot(X(vtx,1)-c0(1),X(vtx,2)-c0(2));v=vtx(abs(r-R)<=tol);
a=atan2(X(v,2)-c0(2),X(v,1)-c0(1));[a,i]=sort(a);v=v(i);
ok=numel(v)>=3&&all(diff(a)>0);
end

function s=classify(X,P,c0,R,tol)
% P: polygon vertices in increasing angle about c0 (closed implicitly)
n=size(P,1);s=-ones(size(X,1),1);
r=hypot(X(:,1)-c0(1),X(:,2)-c0(2));
apo=R*cos(pi/n)*0.5;                     % safe inner radius: every polygon edge is farther
s(r<apo)=1;
cand=find(r>=apo&r<=R+10*tol+1e-6);
if isempty(cand),return,end
aV=atan2(P(:,2)-c0(2),P(:,1)-c0(1));
aX=atan2(X(cand,2)-c0(2),X(cand,1)-c0(1));
j=discretize(aX,[-inf;aV;inf]);           % sector index: 1 and n+1 both mean the wrap chord n
j(j==1|j==n+1)=n+1;j=j-1;                 % chord j joins vertex j and j+1 (mod n)
A=P(j,:);B=P(mod(j,n)+1,:);
t=B-A;L=hypot(t(:,1),t(:,2));nin=[-t(:,2),t(:,1)]./L;   % left normal; CCW order -> points inward
sd=sum(nin.*(X(cand,:)-A),2);
cls=-ones(numel(cand),1);cls(sd>tol)=1;cls(abs(sd)<=tol)=0;
s(cand)=cls;
end

function v=getf(s,f,d)
if isfield(s,f)&&~isempty(s.(f)),v=s.(f);else,v=d;end
end
