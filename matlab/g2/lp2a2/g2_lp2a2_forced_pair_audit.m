function R=g2_lp2a2_forced_pair_audit(D)
%G2_LP2A2_FORCED_PAIR_AUDIT  Geometry and topology of the FORCED guide-crossing pairs of an LP2-A2
% joined mesh (geometry only). For each forced seed pair (a guide circle crossing both banks):
%  origin   along-segment positions x_U, x_L of the two analytic crossings (offset lines at +/-w,
%           circle of radius Rg about the tip); dx = x_U - x_L is the pure circle-geometry part,
%           b the normal offset of the circle centre from the centre line of that segment
%           (dx ~ 2 w b / sqrt(Rg^2 - b^2)); the station mismatch ds = s_U - s_L adds the linear
%           map of the mitred offset segment onto the centre-line segment (parametrisation part)
%  before   station mismatch ds and native coordinate distance |X_U - X_L| (before collapse)
%  after    the two nodes found INDEPENDENTLY in the joined mesh at the collapsed point (mean
%           station on the centre line): exactly two nodes, one per bank list, distinct IDs (so
%           distinct DOFs 2i-1,2i), coordinate residual, interior of the same segment, same index
%           in the station-sorted bank lists, both neighbouring T6 midside pairs coincident,
%           incident T3 elements positive with their minimum angle, distance to the tip vs the
%           3.3-mm collar, collapse displacement of each node
P=D.crackPolyline;X=D.X3;T=D.T3;X6=D.X6;E=D.exterior;up=D.upperBankT6(:);lo=D.lowerBankT6(:);
tip=P(end,:);w=E.summary.channelHalfWidth_mm;Rg=E.summary.controls.tipGuideRadius_mm;
tt=diff(P);Ls=vecnorm(tt,2,2);tt=tt./Ls;nn=[-tt(:,2),tt(:,1)];Sv=[0;cumsum(Ls)];
f=find(E.seedForced(:));R=struct('nForced',numel(f),'pairs',struct([]),'pass',true);
[su,o]=sort(st(X6(up,:)));up=up(o);[~,o]=sort(st(X6(lo,:)));lo=lo(o);
for q=1:numel(f)
 i=f(q);k=E.seedSegment(i);sU=E.seedStationsUL(i,1);sL=E.seedStationsUL(i,2);XU=E.upperSeed(i,:);XL=E.lowerSeed(i,:);
 xU=(XU-P(k,:))*tt(k,:).';xL=(XL-P(k,:))*tt(k,:).';b=(tip-P(k,:))*nn(k,:).';
 sb=.5*(sU+sL);Xc=P(k,:)+(sb-Sv(k))*tt(k,:);
 ids=find(vecnorm(X-Xc,2,2)<=1e-9);iu=intersect(ids,up);il=intersect(ids,lo);
 r=struct('segment',k,'stationU_mm',sU,'stationL_mm',sL,'stationMismatch_mm',sU-sL,'circleDx_mm',xU-xL,'parametrisationPart_mm',(sU-sL)-(xU-xL), ...
  'tipNormalOffset_mm',b,'predictedDx_mm',2*w*b/sqrt(Rg^2-b^2),'nativeDistance_mm',norm(XU-XL),'nodesAtCollapsedPoint',numel(ids), ...
  'collapseDisplacementU_mm',norm(XU-Xc),'collapseDisplacementL_mm',norm(XL-Xc),'distanceToTip_mm',norm(Xc-tip), ...
  'interiorOfSegment',min(abs(sb-Sv))>1e-9&&sb>Sv(k)&&sb<Sv(k+1));
 ok=numel(ids)==2&&isscalar(iu)&&isscalar(il)&&iu~=il;
 if ok
  r.residualAfterCollapse_mm=norm(X(iu,:)-X(il,:));r.distinctIDs=iu~=il;r.ids=[iu il];r.dofs=[2*iu-1 2*iu 2*il-1 2*il];
  ju=find(up==iu);jl=find(lo==il);r.sameBankIndex=isequal(ju,jl);
  mid=[ju-1 ju+1];mid=mid(mid>=1&mid<=numel(up));r.midsideResidual_mm=max(vecnorm(X6(up(mid),:)-X6(lo(mid),:),2,2));
  r.midsideDistinct=all(up(mid)~=lo(mid));
  el=find(any(T==iu|T==il,2));[ang,a2]=quality(X,T(el,:));r.incidentElements=numel(el);r.incidentMinAngle_deg=min(ang);r.incidentMinArea_mm2=min(a2)/2;
  r.pass=r.residualAfterCollapse_mm<=1e-12&&r.sameBankIndex&&r.midsideResidual_mm<=1e-12&&r.midsideDistinct&&all(a2>0)&&r.interiorOfSegment&&r.distanceToTip_mm>3.3;
 else
  r.pass=false;
 end
 R.pass=R.pass&&r.pass;R.pairs=[R.pairs,r];
end
 function s=st(Q)
  M=size(Q,1);dk=inf(M,numel(Ls));lk=dk;
  for p=1:numel(Ls),l=max(0,min(Ls(p),(Q-P(p,:))*tt(p,:).'));dk(:,p)=vecnorm(Q-(P(p,:)+l*tt(p,:)),2,2);lk(:,p)=l;end
  [~,kk]=min(dk,[],2);s=Sv(kk)+lk(sub2ind(size(lk),(1:M)',kk));
 end
end
function [ang,a2]=quality(X,T)
a=X(T(:,2),:)-X(T(:,1),:);b=X(T(:,3),:)-X(T(:,1),:);c=X(T(:,3),:)-X(T(:,2),:);a2=a(:,1).*b(:,2)-a(:,2).*b(:,1);
L1=vecnorm(a,2,2);L2=vecnorm(b,2,2);L3=vecnorm(c,2,2);cl=@(z)max(-1,min(1,z));
ang=min([acosd(cl((L1.^2+L2.^2-L3.^2)./(2*L1.*L2))),acosd(cl((L1.^2+L3.^2-L2.^2)./(2*L1.*L3))),acosd(cl((L2.^2+L3.^2-L1.^2)./(2*L2.*L3)))],[],2);
end
