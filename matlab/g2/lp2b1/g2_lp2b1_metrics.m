function M=g2_lp2b1_metrics(X3,T3,limit)
%G2_LP2B1_METRICS  Independent T3 quality reconstruction from SAVED arrays only (geometry, zero FEM).
%  M = g2_lp2b1_metrics(X3,T3)          limit = 1.8 (inherited neighbour-ratio gate, unchanged)
% Deliberately a different algorithm from the gate code in g2_lp2a2_join:
%  - shared edges from integer edge keys a*(N+1)+b (a<b) sorted once; equal consecutive keys = one
%    interior edge with its two owners (no unique/accumarray), multiplicity counted from runs;
%  - edge lengths with hypot, element size h = largest of its three edge lengths;
%  - interior angles with atan2(|cross|,dot) at each vertex (not the law of cosines);
%  - signed doubled area from the cross product (orientation and positivity).
% Ratio of a shared edge = max(h1/h2,h2/h1). Every pair above the limit is returned (not only the
% maximum), with both owners, the common edge, both h, which local edge is longest, and the
% ordering by ratio. No gate is evaluated here beyond reporting; the caller compares.
if nargin<3,limit=1.8;end
X3=double(X3);T3=double(T3);N=size(X3,1);Me=size(T3,1);
A=X3(T3(:,1),:);B=X3(T3(:,2),:);C=X3(T3(:,3),:);
lAB=hypot(B(:,1)-A(:,1),B(:,2)-A(:,2));lBC=hypot(C(:,1)-B(:,1),C(:,2)-B(:,2));lCA=hypot(A(:,1)-C(:,1),A(:,2)-C(:,2));
Lall=[lAB,lBC,lCA];[h,iLong]=max(Lall,[],2);
cr=@(u,v)u(:,1).*v(:,2)-u(:,2).*v(:,1);dt=@(u,v)u(:,1).*v(:,1)+u(:,2).*v(:,2);
twoA=cr(B-A,C-A);
angA=atan2d(abs(cr(B-A,C-A)),dt(B-A,C-A));angB=atan2d(abs(cr(C-B,A-B)),dt(C-B,A-B));angC=atan2d(abs(cr(A-C,B-C)),dt(A-C,B-C));
ang=[angA,angB,angC];minAng=min(ang,[],2);
% local edges: 1 = (1,2) AB, 2 = (2,3) BC, 3 = (3,1) CA
ea=[T3(:,1);T3(:,2);T3(:,3)];eb=[T3(:,2);T3(:,3);T3(:,1)];el=[(1:Me)';(1:Me)';(1:Me)'];ej=[ones(Me,1);2*ones(Me,1);3*ones(Me,1)];
lo=min(ea,eb);hi=max(ea,eb);key=lo*(N+1)+hi;
assert(max(key)<2^52,'G2LP2B1:Key','Edge keys exceed exact double range.');
[ks,o]=sort(key);el=el(o);ej=ej(o);lo=lo(o);hi=hi(o);
st=[true;diff(ks)~=0];runId=cumsum(st);mult=accumarray(runId,1);
nEdges=numel(mult);nInterior=nnz(mult==2);nBoundary=nnz(mult==1);nNonmanifold=nnz(mult>2);
firstOf=find(st);
pairRuns=find(mult==2);i1=firstOf(pairRuns);i2=i1+1;
e1=el(i1);e2=el(i2);na=lo(i1);nb=hi(i1);
r=max(h(e1)./h(e2),h(e2)./h(e1));
[rs,ord]=sort(r,'descend');
viol=find(r>limit);[~,vo]=sort(r(viol),'descend');viol=viol(vo);
% boundary edge list (one owner)
bRuns=find(mult==1);ib=firstOf(bRuns);
M=struct('schema','NewMetacomp.G2.LP2B1.IndependentMetrics.v1','T3',Me,'T3nodes',N,'usedNodes',numel(unique(T3(:))), ...
 'edges',nEdges,'interiorEdges',nInterior,'boundaryEdges',nBoundary,'nonmanifoldEdges',nNonmanifold, ...
 'euler',numel(unique(T3(:)))-nEdges+Me,'minAngle_deg',min(minAng),'minAngleElement',find(minAng==min(minAng),1), ...
 'allAreasPositive',all(twoA>0),'minArea_mm2',min(twoA)/2,'maxNeighborRatio',rs(1),'limit',limit, ...
 'violations',numel(viol),'ratioCounts',struct('above1p8',nnz(r>1.8),'above1p75',nnz(r>1.75),'above1p7',nnz(r>1.7), ...
  'above1p6',nnz(r>1.6),'above1p5',nnz(r>1.5),'above1p4',nnz(r>1.4),'above1p3',nnz(r>1.3)));
M.h=h;M.longestLocalEdge=iLong;M.minAngleEl=minAng;M.twoArea=twoA;
M.pairElements=[e1,e2];M.pairNodes=[na,nb];M.pairRatio=r;M.pairOrderDesc=ord;M.violationPairs=viol;
M.boundaryEdgeNodes=[lo(ib),hi(ib)];M.boundaryEdgeOwner=el(ib);
% which owner holds the common edge as its longest edge
M.pairEdgeIsLongestOf=[iLong(e1)==ej(i1),iLong(e2)==ej(i2)];
end
