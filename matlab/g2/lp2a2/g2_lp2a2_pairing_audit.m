function R=g2_lp2a2_pairing_audit(D)
%G2_LP2A2_PAIRING_AUDIT  Independent crack-face pairing audit of a JOINED mesh (geometry only).
% Works on the saved arrays only (X3,T3,X6,T6,upperBankT6,lowerBankT6,crackPolyline,
% physicalTipNode); it does not reuse the mesher's seeds or stations. Every bank node gets its own
% centre-line station by orthogonal projection onto the polyline; each bank is sorted by station
% and the i-th upper node is then REQUIRED (not assumed) to coincide with the i-th lower node.
% Gates:
%  P1 bank node counts equal (T6) and vertex/midside class counts equal (T3 and T6 separately)
%  P2 stations strictly increasing on each bank (no duplicates, no reordering)
%  P3 every pair coincident after collapse (<= 1e-12 mm) and identical station (<= 1e-12 mm)
%  P4 distinct node identities/DOFs in every pair (only the physical tip is shared)
%  P5 same segment membership in every pair (kink vertices treated as the shared segment end)
%  P6 same class in every pair (T3 vertex with T3 vertex, T6 midside with T6 midside); each
%     midside at the midpoint of its two neighbouring bank vertices (<= 1e-12 mm)
%  P7 no unmatched node on the crack: every T6 node within 1e-9 mm of the polyline is a bank node
%  P8 one-owner bank edges with the owner on the correct side (+n upper, -n lower)
%  P9 mouth pair at the mouth vertex; kink pairs at the kink vertices; banks end at the tip
%  P10 single connected T3 mesh; strictly positive T3 areas
% Metrics: pairs (T3/T6), minimum edge length (all / bank), minimum angle, maximum neighbour ratio.
P=D.crackPolyline;X3=D.X3;T3=D.T3;X6=D.X6;T6=D.T6;up=D.upperBankT6(:);lo=D.lowerBankT6(:);tipN=D.physicalTipNode;
nseg=size(P,1)-1;tt=diff(P);Ls=vecnorm(tt,2,2);tt=tt./Ls;nn=[-tt(:,2),tt(:,1)];Sv=[0;cumsum(Ls)];
g=struct();m=struct();
[sU,kU]=station(X6(up,:));[sL,kL]=station(X6(lo,:));
[sU,o]=sort(sU);up=up(o);kU=kU(o);[sL,o]=sort(sL);lo=lo(o);kL=kL(o);
isV=false(size(X6,1),1);isV(unique(T3(:)))=true;
g.P1_countsEqual=numel(up)==numel(lo)&&nnz(isV(up))==nnz(isV(lo))&&nnz(~isV(up))==nnz(~isV(lo));
m.pairsT6=min(numel(up),numel(lo));m.pairsT3=min(nnz(isV(up)),nnz(isV(lo)));m.bankNodesUL=[numel(up),numel(lo)];
g.P2_strictOrder=all(diff(sU)>0)&&all(diff(sL)>0);
if g.P1_countsEqual
 dX=vecnorm(X6(up,:)-X6(lo,:),2,2);dS=abs(sU-sL);
 m.maxPairDistance_mm=max(dX);m.maxPairStationDifference_mm=max(dS);
 g.P3_coincidentIdenticalStation=max(dX)<=1e-12&&max(dS)<=1e-12;
 sh=up==lo;g.P4_distinctIDs=all(~sh|up==tipN)&&nnz(sh)<=1&&numel(intersect(up(~sh),lo(~sh)))==0;
 vtx=min(abs(sU-Sv.'),[],2)<=1e-9;   % pair at a polyline vertex
 g.P5_sameSegment=all(kU(~vtx)==kL(~vtx));
 g.P6_sameClassMidsides=all(isV(up)==isV(lo))&&midOK(up)&&midOK(lo);
else
 m.maxPairDistance_mm=NaN;m.maxPairStationDifference_mm=NaN;
 g.P3_coincidentIdenticalStation=false;g.P4_distinctIDs=false;g.P5_sameSegment=false;g.P6_sameClassMidsides=false;
end
dAll=polydist(X6);onC=find(dAll<=1e-9);
m.nodesOnCrack=numel(onC);m.unmatchedOnCrack=numel(setdiff(onC,[up;lo]));
g.P7_noUnmatchedNodeOnCrack=m.unmatchedOnCrack==0;
% bank T3 edges: consecutive T3 vertices of each bank must form one-owner edges with correct side
raw=sort([T3(:,[1 2]);T3(:,[2 3]);T3(:,[3 1])],2);[E,~,ic]=unique(raw,'rows');cnt=accumarray(ic,1);own=repmat((1:size(T3,1))',3,1);
lo1=accumarray(ic,own,[],@min);
sideOK=@(b,sg)sideCheck(b(isV(b)),sg);
g.P8_oneOwnerCorrectSide=sideOK(up,+1)&&sideOK(lo,-1);
mouthOK=norm(X6(up(1),:)-P(1,:))<=1e-12&&norm(X6(lo(1),:)-P(1,:))<=1e-12;
kinkOK=true;for k=2:nseg,kinkOK=kinkOK&&any(vecnorm(X6(up,:)-P(k,:),2,2)<=1e-12)&&any(vecnorm(X6(lo,:)-P(k,:),2,2)<=1e-12);end
g.P9_mouthKinksTip=mouthOK&&kinkOK&&norm(X6(up(end),:)-P(end,:))<=1e-12&&norm(X6(lo(end),:)-P(end,:))<=1e-12;
a=X3(T3(:,2),:)-X3(T3(:,1),:);b=X3(T3(:,3),:)-X3(T3(:,1),:);a2=a(:,1).*b(:,2)-a(:,2).*b(:,1);
Gr=graph(E(:,1),E(:,2));comp=conncomp(Gr);used=unique(T3(:));
g.P10_connectedPositive=numel(unique(comp(used)))==1&&all(a2>0);
L=vecnorm(X3(E(:,1),:)-X3(E(:,2),:),2,2);m.minEdge_mm=min(L);
bk=all(ismember(E,[up;lo]),2)&cnt==1;m.minBankEdge_mm=min(L(bk));m.bankEdgesT3=nnz(bk);
m.T3=size(T3,1);m.T6nodes=size(X6,1);m.T3nodes=numel(used);m.minArea_mm2=min(a2)/2;
v=cell2mat(struct2cell(g));f=fieldnames(g);
R=struct('schema','NewMetacomp.G2.LP2A2.PairingAudit.v1','pass',all(v),'gates',g,'gatesPassed',nnz(v),'gatesTotal',numel(v), ...
 'failedGates',{f(~v)},'metrics',m);

 function [s,kk]=station(X)
  M=size(X,1);dk=inf(M,nseg);lk=zeros(M,nseg);
  for q=1:nseg
   l=max(0,min(Ls(q),(X-P(q,:))*tt(q,:).'));dk(:,q)=vecnorm(X-(P(q,:)+l*tt(q,:)),2,2);lk(:,q)=l;
  end
  [~,kk]=min(dk,[],2);s=Sv(kk)+lk(sub2ind(size(lk),(1:M)',kk));
 end
 function d=polydist(X)
  d=inf(size(X,1),1);
  for q=1:nseg
   l=max(0,min(Ls(q),(X-P(q,:))*tt(q,:).'));d=min(d,vecnorm(X-(P(q,:)+l*tt(q,:)),2,2));
  end
 end
 function ok=midOK(b)
  % alternating vertex / midside along the bank; each midside at the midpoint of its neighbours
  c=isV(b);ok=c(1)&&c(end)&&all(c(1:2:end))&&~any(c(2:2:end));
  if ok,mid=b(2:2:end);ok=max(vecnorm(X6(mid,:)-.5*(X6(b(1:2:end-2),:)+X6(b(3:2:end),:)),2,2))<=1e-12;end
 end
 function ok=sideCheck(bv,sg)
  ok=true;
  for i=1:numel(bv)-1
   e=sort([bv(i),bv(i+1)]);[tf,j]=ismember(e,E,'rows');
   if ~tf||cnt(j)~=1,ok=false;return,end
   el=lo1(j);c=mean(X3(T3(el,:),:),1);mp=.5*(X3(bv(i),:)+X3(bv(i+1),:));
   [~,q]=station(mp);if sg*((c-mp)*nn(q,:).')<=0,ok=false;return,end
  end
 end
end
