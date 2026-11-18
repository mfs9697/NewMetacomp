function A = g2_kink_admissibility(P, G, varargin)
%G2_KINK_ADMISSIBILITY  Cornell-specific geometric admissibility of a kinked crack polyline (gates K1-K10).
%
%  A = g2_kink_admissibility(P, G, ...)
% P : N-by-2 polyline in mm (mouth first, tip last). G : nominal_geometry_mm of the
% pinned Cornell JSON. Gates and thresholds: WP3_PREREGISTRATION.md section 3. Each
% gate guards one construction mechanism; the inherited upstream MinKinkTangentDot
% = 0.98 limit is reported (inheritedGuard*) but is NOT a gate here.
% Pure geometry: no PDE, no mesh, no FEM.
ip=inputParser;
addParameter(ip,'ExpectedVertices',3,@(v)isnumeric(v)&&isscalar(v));
addParameter(ip,'DeltaA_mm',4,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'ExpectedTangent',[],@(v)isempty(v)||(isnumeric(v)&&numel(v)==2));
addParameter(ip,'ChannelHalfWidth_mm',.020,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'CoreRadius_mm',3,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'RimRadius_mm',3.3,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'Hmin_mm',.12,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'GuideHface_mm',1.5,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'TipGuideRadius_mm',15,@(v)isempty(v)||(isnumeric(v)&&isscalar(v)&&v>0));
addParameter(ip,'HoleRule_mm',3,@(v)isnumeric(v)&&isscalar(v)&&v>0);
parse(ip,varargin{:});o=ip.Results;
w=o.ChannelHalfWidth_mm;rc=o.CoreRadius_mm;ro=o.RimRadius_mm;hRim=2*ro*sin(pi/64);
F=g2_polyline_frame(P);N=size(P,1);tip=F.tip;t=F.t;
xmin=G.plate.x_range(1);xmax=G.plate.x_range(2);ymin=G.plate.y_range(1);ymax=G.plate.y_range(2);
mouth=G.initial_crack.mouth(:).';tip0=G.initial_crack.tip(:).';
nh=numel(G.holes);C=zeros(nh,2);Rh=zeros(nh,1);
for k=1:nh,C(k,:)=G.holes(k).center(:).';Rh(k)=G.holes(k).radius;end
g=struct();
% K1 polyline identity
k1=N==o.ExpectedVertices&&N>=3&&norm(P(1,:)-mouth)<=1e-12&&norm(P(2,:)-tip0)<=1e-12&& ...
   abs(F.segmentLengths(end)-o.DeltaA_mm)<=1e-12;
if ~isempty(o.ExpectedTangent),k1=k1&&norm(t-o.ExpectedTangent(:).')<=1e-12;end
g.K1_polylineIdentity=k1;
% K2 non-singular miter (inherited geometric rule 1 + t.t' > 1.8)
den=1+F.tangentDots;g.K2_nonsingularMiter=all(den>1.8);
% K3 collar entry on the last segment, past the kink
entry=tip-ro*t;
g.K3_collarEntryOnLastSegment=F.segmentLengths(end)>ro&&dot(entry-P(end-1,:),t)>0;
% K4/K5 clearance of the tip from every earlier segment
dPrev=inf(max(N-2,0),1);
for j=1:N-2,dPrev(j)=pseg(tip,P(j,:),P(j+1,:));end
dmin=min([dPrev;inf]);
g.K4_rimBandClearOfEarlierCrack=dmin-ro-w>=hRim;
g.K5_coreAndQClearOfEarlierCrack=dmin>rc;
% K6/K7 every segment against the true holes and the 3R guides
segHole=inf(N-1,nh);
for j=1:N-1,for k=1:nh,segHole(j,k)=pseg(C(k,:),P(j,:),P(j+1,:));end,end
g.K6_segmentsClearOfHoleWalls=all(all(segHole-Rh.'>o.HoleRule_mm));
g.K7_segmentsClearOfGuideFaces=all(all(segHole-3*Rh.'>w+o.GuideHface_mm));
% K8 collar disk inside the material
dTip=vecnorm(C-tip,2,2);
plateSides=[tip(1)-xmin,xmax-tip(1),tip(2)-ymin,ymax-tip(2)];
g.K8_collarInsideMaterial=all(dTip-Rh>ro)&&all(dTip-3*Rh>ro)&&all(plateSides>ro);
% K9 tip guide
if isempty(o.TipGuideRadius_mm)
 g.K9_tipGuideAdmissible=true;tgMargin=[];
else
 Rg=o.TipGuideRadius_mm;tgMargin=[min(plateSides)-Rg,min(dTip-3*Rh-Rg)];
 g.K9_tipGuideAdmissible=Rg>ro+2&&all(plateSides>Rg)&&all(dTip>Rg+3*Rh);
end
% K10 vertices inside the plate, no self-intersection, nonadjacent separation
inside=all(P(2:end,1)>xmin&P(2:end,1)<xmax&P(2:end,2)>ymin&P(2:end,2)<ymax)&&abs(P(1,2)-ymin)<=1e-12;
sep=inf;
for i=1:N-1
 for j=i+2:N-1
  sep=min(sep,sseg(P(i,:),P(i+1,:),P(j,:),P(j+1,:)));
 end
end
g.K10_noSelfIntersectionInsidePlate=inside&&sep>=2*w+o.Hmin_mm&&all(F.tangentDots>-1+1e-12);
v=cell2mat(struct2cell(g));f=fieldnames(g);
A=struct('pass',all(v),'gates',g,'failedGates',{f(~v)},'summary',struct( ...
 'vertices',N,'segmentLengths_mm',F.segmentLengths.','turns_deg',F.turns_deg.','tangentDots',F.tangentDots.', ...
 'miterDenominators',den.','miterFactors',sqrt(2./den).','tip_mm',tip,'t',t,'n',F.n, ...
 'distTipToEarlierSegments_mm',dPrev.','rimBandMargin_mm',dmin-ro-w,'rimChord_mm',hRim, ...
 'minSegmentHoleWallClearance_mm',min(min(segHole-Rh.')), ...
 'minSegmentGuideClearance_mm',min(min(segHole-3*Rh.')), ...
 'collarMargins_mm',[min(dTip-Rh)-ro,min(dTip-3*Rh)-ro,min(plateSides)-ro], ...
 'tipGuideMargins_mm',tgMargin,'nonadjacentSeparation_mm',sep, ...
 'inheritedGuardMinKinkTangentDot',.98,'inheritedGuardWouldReject',any(F.tangentDots<=.98)));
end

function d=pseg(p,a,b)
v=b-a;l=max(0,min(1,dot(p-a,v)/dot(v,v)));d=norm(p-(a+l*v));
end

function d=sseg(a,b,c,e)
% distance between segments ab and ce (0 if they intersect)
o1=orient(a,b,c);o2=orient(a,b,e);o3=orient(c,e,a);o4=orient(c,e,b);
if o1*o2<0&&o3*o4<0,d=0;return,end
d=min([pseg(a,c,e),pseg(b,c,e),pseg(c,a,b),pseg(e,a,b)]);
end

function s=orient(a,b,c)
s=(b(1)-a(1))*(c(2)-a(2))-(b(2)-a(2))*(c(1)-a(1));
end
