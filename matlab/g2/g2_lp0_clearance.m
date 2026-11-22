function R=g2_lp0_clearance(P,next,geo,pol)
% Continuous clearance of a proposed segment; no mesher, material labels or FEM.
% geo polygons are actual saved-mesh vertex coordinates, one cell per ring/hole.
% Nominal circular envelopes are also enforced conservatively. Passive rings
% remain obstacles. Distances are to closed boundaries, not sampled endpoints.
R=struct('pass',false,'status','HOLD_INPUT','reasons',{{}},'metrics',struct());
if ~isnumeric(P)||size(P,2)~=2||size(P,1)<2||~isreal(P)||any(~isfinite(P(:)))|| ...
 ~isnumeric(next)||~isequal(size(next),[1 2])||~isreal(next)||any(~isfinite(next)),return,end
if any(vecnorm(diff(P),2,2)<=1e-12)||norm(next-P(end,:))<=1e-12,return,end
g=pol.geometry;tol=g.distanceTolerance_mm;C=g.centres_mm;
if ~isstruct(geo)||~all(isfield(geo,{'centres','ringPolygons','holePolygons'}))|| ...
 ~isequal(geo.centres,C)||~iscell(geo.ringPolygons)||~iscell(geo.holePolygons)|| ...
 numel(geo.ringPolygons)~=3||numel(geo.holePolygons)~=3
 R.status='HOLD_OWNER_MASK';return
end
for h=1:3
 if ~validpoly(geo.ringPolygons{h},C(h,:),g.ringR_mm,tol,g.expectedChords)|| ...
    ~validpoly(geo.holePolygons{h},C(h,:),g.holeR_mm,tol,[])
  R.status='HOLD_OWNER_MASK';return
 end
end
a=P(end,:);b=next;ring=zeros(1,3);hole=ring;tipRing=ring;tipHole=ring;circleRing=ring;
hit=false;historyHit=false;
for h=1:3
 [ring(h),inside]=segpoly(a,b,geo.ringPolygons{h},tol);
 [hole(h),inHole]=segpoly(a,b,geo.holePolygons{h},tol);
 tipRing(h)=pointpoly(b,geo.ringPolygons{h});tipHole(h)=pointpoly(b,geo.holePolygons{h});
 circleRing(h)=pseg(C(h,:),a,b)-g.ringR_mm;
 hit=hit||inside||inHole||ring(h)<=tol||hole(h)<=tol;
 for k=1:size(P,1)-1
  [dd,ii]=segpoly(P(k,:),P(k+1,:),geo.ringPolygons{h},tol);
  historyHit=historyHit||ii||dd<=tol||pseg(C(h,:),P(k,:),P(k+1,:))-g.ringR_mm<=tol;
 end
end
tipCircle=vecnorm(C-b,2,2).'-g.ringR_mm;
guide=tipCircle-g.tipGuideRadius_mm;
qmargin=tipCircle-max(pol.qAnnuli_mm(:,2))-g.minQClearance_mm;
plate=[a(1),g.plate_mm(1)-a(1),a(2),g.plate_mm(2)-a(2); ...
 b(1),g.plate_mm(1)-b(1),b(2),g.plate_mm(2)-b(2)];
segmentPlate=min(plate,[],1);tipPlate=plate(2,:);
previous=inf;tipEarlier=inf;
for k=1:size(P,1)-2
 previous=min(previous,sseg(a,b,P(k,:),P(k+1,:),tol));
 tipEarlier=min(tipEarlier,pseg(b,P(k,:),P(k+1,:)));
end
u=(a-P(end-1,:))/norm(a-P(end-1,:));v=(b-a)/norm(b-a);
% Adjacent segments share only the parent tip; reversal and sharp miter fail.
miterDen=1+dot(u,v);rimMargin=tipEarlier-g.collarRadius_mm-g.channelHalfWidth_mm-2*g.collarRadius_mm*sin(pi/64);
histInside=all(P(2:end,1)>tol&P(2:end,1)<g.plate_mm(1)-tol&P(2:end,2)>tol&P(2:end,2)<g.plate_mm(2)-tol)&& ...
 isequal(P(1,:),pol.startPolyline_mm(1,:));
for i=1:size(P,1)-1
 for j=i+2:size(P,1)-1
  previous=min(previous,sseg(P(i,:),P(i+1,:),P(j,:),P(j+1,:),tol));
 end
end
R.metrics=struct('segmentToRingPolygon_mm',ring,'segmentToHolePolygon_mm',hole, ...
 'tipToRingPolygon_mm',tipRing,'tipToHolePolygon_mm',tipHole,'segmentToNominalRing_mm',circleRing, ...
 'tipToNominalRing_mm',tipCircle,'guideRingMargin_mm',guide,'qRingMargin_mm',qmargin, ...
 'segmentPlate_mm',segmentPlate,'tipPlate_mm',tipPlate,'guidePlateMargin_mm',tipPlate-g.tipGuideRadius_mm, ...
 'qPlateMargin_mm',tipPlate-max(pol.qAnnuli_mm(:,2))-g.minQClearance_mm, ...
 'nonadjacentSegment_mm',previous,'tipEarlierSegment_mm',tipEarlier,'rimEarlierMargin_mm',rimMargin,'miterDenominator',miterDen);
reasons={};
if ~histInside||any(segmentPlate<=g.channelHalfWidth_mm+tol),reasons{end+1}='HOLD_EXTERNAL_BOUNDARY';end
if previous<g.minNonadjacentClearance_mm+tol||miterDen<=1.8||rimMargin<=tol,reasons{end+1}='HOLD_CRACK_SELF_INTERSECTION';end
if hit||historyHit||any(circleRing<=g.minSegmentRingClearance_mm+tol),reasons{end+1}='HOLD_INTERFACE_APPROACH';end
if any(qmargin<=tol)||any(R.metrics.qPlateMargin_mm<=tol),reasons{end+1}='HOLD_Q_PHASE';end
if any(guide<=tol)||any(R.metrics.guidePlateMargin_mm<=tol),reasons{end+1}='HOLD_TIP_GUIDE';end
R.reasons=reasons;R.pass=isempty(reasons);
if R.pass,R.status='MATRIX_ADVANCE';else,R.status=reasons{1};end
end

function ok=validpoly(Q,c,r,tol,n)
ok=isnumeric(Q)&&isreal(Q)&&size(Q,2)==2&&size(Q,1)>=3&&all(isfinite(Q(:)));
if ~ok,return,end
ok=all(abs(vecnorm(Q-c,2,2)-r)<=tol)&&size(unique(Q,'rows'),1)==size(Q,1);
if ~isempty(n),ok=ok&&size(Q,1)==n;end
if ~ok,return,end
% Strictly convex cyclic order and complete circle coverage (no missing sector).
a=atan2(Q(:,2)-c(2),Q(:,1)-c(1));da=mod(diff([a;a(1)]),2*pi);
ok=all(da>0&da<pi)&&abs(sum(da)-2*pi)<1e-10;
end
function [d,inside]=segpoly(a,b,Q,tol)
[ia,oa]=inpolygon(a(1),a(2),Q(:,1),Q(:,2));[ib,ob]=inpolygon(b(1),b(2),Q(:,1),Q(:,2));
inside=ia||ib||oa||ob;d=inf;
for k=1:size(Q,1),d=min(d,sseg(a,b,Q(k,:),Q(mod(k,size(Q,1))+1,:),tol));end
end
function d=pointpoly(p,Q)
d=inf;for k=1:size(Q,1),d=min(d,pseg(p,Q(k,:),Q(mod(k,size(Q,1))+1,:)));end
[i,o]=inpolygon(p(1),p(2),Q(:,1),Q(:,2));if i&&~o,d=-d;end
end
function d=pseg(p,a,b)
v=b-a;den=dot(v,v);if den==0,d=norm(p-a);return,end
t=max(0,min(1,dot(p-a,v)/den));d=norm(p-(a+t*v));
end
function d=sseg(a,b,c,e,tol)
cross=@(v,w)v(1)*w(2)-v(2)*w(1);
v=b-a;w=e-c;den=cross(v,w);
if abs(den)>eps*max(1,norm(v)*norm(w))*8
 t=cross(c-a,w)/den;s=cross(c-a,v)/den;
 if t>=0&&t<=1&&s>=0&&s<=1,d=0;return,end
end
d=min([pseg(a,c,e),pseg(b,c,e),pseg(c,a,b),pseg(e,a,b)]);
if d<=tol,d=0;end
end
