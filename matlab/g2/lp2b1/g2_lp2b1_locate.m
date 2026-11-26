function L=g2_lp2b1_locate(M,X3,T3,ctx,pairIdx)
%G2_LP2B1_LOCATE  Geometric context of shared-edge element pairs (saved arrays only, zero FEM).
%  L = g2_lp2b1_locate(M,X3,T3,ctx,pairIdx)
% M      g2_lp2b1_metrics result of (X3,T3)
% ctx    struct: polyline_mm, tip_mm, rows (core/collar index ranges), centres_mm, ringR_mm, holeR_mm,
%        guideR_mm (15), collarR_mm (3.3), coreR_mm (3.0), plate_mm [W H], extraVertexXY (CAD point vertices)
% pairIdx  indices into M.pairElements (e.g. M.violationPairs or the top-k by ratio)
% For every pair: owners ordered small -> large, both h and areas, ratio, common edge (nodes,
% coordinates, length, orientation), centroids, region rows (core / collar / exterior), the face of
% the mesh family that contains the edge midpoint (tip-guide disc, ring annulus i, free exterior),
% signed distances of the edge midpoint to the tip, crack polyline, 3.0 mm core circle, 3.3 mm
% collar circle, 15 mm tip-guide circle, every ring circle, every hole circle and every plate edge,
% constraint flags of the involved vertices (on a guide/ring/hole circle, plate edge, crack bank,
% CAD point vertex), one-owner boundary edges of either element, and the 1-ring of the large owner.
X3=double(X3);T3=double(T3);P=ctx.polyline_mm;tip=ctx.tip_mm(:).';cen=ctx.centres_mm;W=ctx.plate_mm(1);H=ctx.plate_mm(2);
cent=(X3(T3(:,1),:)+X3(T3(:,2),:)+X3(T3(:,3),:))/3;
region=@(e)regionOf(e,ctx.rows);
tol=1e-6;
onCirc=@(x,c,R)abs(hypot(x(:,1)-c(1),x(:,2)-c(2))-R)<=tol;
bOwn=M.boundaryEdgeOwner;
L=struct('pair',{},'ratio',{},'small',{},'large',{},'hSmall_mm',{},'hLarge_mm',{},'areaSmall_mm2',{},'areaLarge_mm2',{}, ...
 'edgeNodes',{},'edgeXY_mm',{},'edgeLength_mm',{},'edgeOrientation_deg',{},'edgeIsLongestOfSmallLarge',{},'midpoint_mm',{}, ...
 'centroidSmall_mm',{},'centroidLarge_mm',{},'directionSmallToLarge_deg',{},'regionSmallLarge',{},'face',{}, ...
 'distTip_mm',{},'distPolyline_mm',{},'signedToCore_mm',{},'signedToCollar_mm',{},'signedToTipGuide_mm',{}, ...
 'signedToRing_mm',{},'signedToHole_mm',{},'toPlateEdges_mm',{},'vertexFlags',{},'boundaryEdgeInPair',{},'largeOneRing',{});
for q=1:numel(pairIdx)
 p=pairIdx(q);e=M.pairElements(p,:);[~,s]=min(M.h(e));es=e(s);elg=e(3-s);nd=M.pairNodes(p,:);xy=X3(nd,:);
 mid=mean(xy,1);v=xy(2,:)-xy(1,:);lst=M.pairEdgeIsLongestOf(p,:);if s==2,lst=fliplr(lst);end
 vs=unique(T3([es elg],:));xv=X3(vs,:);
 fl=struct('nodes',vs(:).','onTipGuide',onCirc(xv,tip,ctx.guideR_mm).','onCollar',onCirc(xv,tip,ctx.collarR_mm).', ...
  'onRing',[onCirc(xv,cen(1,:),ctx.ringR_mm),onCirc(xv,cen(2,:),ctx.ringR_mm),onCirc(xv,cen(3,:),ctx.ringR_mm)].', ...
  'onHole',[onCirc(xv,cen(1,:),ctx.holeR_mm),onCirc(xv,cen(2,:),ctx.holeR_mm),onCirc(xv,cen(3,:),ctx.holeR_mm)].', ...
  'onPlateEdge',(abs(xv(:,1))<=tol|abs(xv(:,1)-W)<=tol|abs(xv(:,2))<=tol|abs(xv(:,2)-H)<=tol).', ...
  'onCrack',(polyDist(xv,P)<=1e-9).','cadPointVertex',cadHit(xv,ctx.extraVertexXY).');
 nbr=oneRing(T3,elg);
 L(q)=struct('pair',p,'ratio',M.pairRatio(p),'small',es,'large',elg,'hSmall_mm',M.h(es),'hLarge_mm',M.h(elg), ...
  'areaSmall_mm2',M.twoArea(es)/2,'areaLarge_mm2',M.twoArea(elg)/2,'edgeNodes',nd,'edgeXY_mm',xy,'edgeLength_mm',hypot(v(1),v(2)), ...
  'edgeOrientation_deg',mod(atan2d(v(2),v(1)),180),'edgeIsLongestOfSmallLarge',lst,'midpoint_mm',mid, ...
  'centroidSmall_mm',cent(es,:),'centroidLarge_mm',cent(elg,:),'directionSmallToLarge_deg',atan2d(cent(elg,2)-cent(es,2),cent(elg,1)-cent(es,1)), ...
  'regionSmallLarge',{{region(es),region(elg)}},'face',faceOf(mid,tip,cen,ctx), ...
  'distTip_mm',norm(mid-tip),'distPolyline_mm',polyDist(mid,P),'signedToCore_mm',norm(mid-tip)-ctx.coreR_mm, ...
  'signedToCollar_mm',norm(mid-tip)-ctx.collarR_mm,'signedToTipGuide_mm',norm(mid-tip)-ctx.guideR_mm, ...
  'signedToRing_mm',vecnorm(cen-mid,2,2).'-ctx.ringR_mm,'signedToHole_mm',vecnorm(cen-mid,2,2).'-ctx.holeR_mm, ...
  'toPlateEdges_mm',[mid(1),W-mid(1),mid(2),H-mid(2)],'vertexFlags',fl,'boundaryEdgeInPair',any(ismember([es elg],bOwn)), ...
  'largeOneRing',struct('elements',nbr(:).','h_mm',M.h(nbr).','ratioToLarge',(M.h(elg)./M.h(nbr)).'));
end
end

function r=regionOf(e,rows)
if e<=rows.coreLast,r='core';elseif e<=rows.collarLast,r='collar';else,r='exterior';end
end
function f=faceOf(x,tip,cen,ctx)
if norm(x-tip)<ctx.collarR_mm,f='protected core/collar';return,end
if norm(x-tip)<ctx.guideR_mm,f='tip-guide disc (15 mm, Hface 1.5 mm)';return,end
d=vecnorm(cen-x,2,2);
for i=1:3,if d(i)<ctx.ringR_mm&&d(i)>ctx.holeR_mm,f=sprintf('ring annulus %d (guide face, Hface 1.5 mm)',i);return,end,end
f='free exterior (graded, Hgrad 1.12, Hmax 6 mm)';
end
function d=polyDist(X,P)
d=inf(size(X,1),1);
for j=1:size(P,1)-1
 v=P(j+1,:)-P(j,:);l=max(0,min(1,((X-P(j,:))*v.')/(v*v.')));d=min(d,vecnorm(X-(P(j,:)+l*v),2,2));
end
end
function c=cadHit(X,V)
c=false(size(X,1),1);if isempty(V),return,end
for i=1:size(X,1),c(i)=any(vecnorm(V-X(i,:),2,2)<=1e-9);end
end
function nb=oneRing(T3,e)
nb=find(any(ismember(T3,T3(e,:)),2));nb(nb==e)=[];
end
