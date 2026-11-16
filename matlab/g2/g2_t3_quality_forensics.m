function F = g2_t3_quality_forensics(X,T,crackTip,holeCenters,holeRadii,topN)
%G2_T3_QUALITY_FORENSICS  Read-only localization of adjacent T3 size jumps.
% Geometry ONLY, mm. Independent of MATLAB PDE objects and material data.
%
% F = g2_t3_quality_forensics(X,T,tip,centers,radii,12)
%
% Reports maximum and quantiles of adjacent longest-edge ratios, worst
% two actual elements, the shared edge and location; no thresholds changed,
% no nodes moved, no T3 altered. Suitable for PRE- and POST-collapse arrays.
if nargin<6||isempty(topN),topN=12;end
assert(size(X,2)==2&&size(T,2)==3, ...
    'G2:QualityShape','X must be Nx2 and T must be Mx3.');
assert(all(isfinite(X(:)))&&all(T(:)>=1)&& ...
    all(T(:)==round(T(:)))&&max(T(:))<=size(X,1), ...
    'G2:QualityInput','Coordinates/connectivity are not finite or valid.');
assert(numel(crackTip)==2 && size(holeCenters,2)==2 && ...
    numel(holeRadii)==size(holeCenters,1), ...
    'G2:QualityContext','Invalid crack tip/hole geometry.');
n=size(T,1);
a=X(T(:,2),:)-X(T(:,1),:);
b=X(T(:,3),:)-X(T(:,1),:);
area2=a(:,1).*b(:,2)-a(:,2).*b(:,1);
len12=vecnorm(a,2,2);
len23=vecnorm(X(T(:,3),:)-X(T(:,2),:),2,2);
len31=vecnorm(b,2,2);
h=max([len12,len23,len31],[],2);
clip=@(z)max(-1,min(1,z));
ang1=acosd(clip((len12.^2+len31.^2-len23.^2)./(2*len12.*len31)));
ang2=acosd(clip((len12.^2+len23.^2-len31.^2)./(2*len12.*len23)));
ang3=acosd(clip((len23.^2+len31.^2-len12.^2)./(2*len23.*len31)));
edgesRaw=sort([T(:,[1 2]);T(:,[2 3]);T(:,[3 1])],2);
[edges,~,ic]=unique(edgesRaw,'rows');
parents=repmat((1:n)',3,1);
counts=accumarray(ic,1,[size(edges,1),1]);
elo=accumarray(ic,parents,[],@min);
ehi=accumarray(ic,parents,[],@max);
ii=find(counts==2);
u=elo(ii);v=ehi(ii);
ratios=max(h(u)./h(v),h(v)./h(u));
[ordered,idx]=sort(ratios,'descend');
F=struct();
F.t3Elements=n;
F.t3Nodes=size(X,1);
F.positiveAreaAll=all(area2>0);
F.minimumT3Angle_deg=min([ang1;ang2;ang3]);
F.minDoubleArea_mm2=min(area2);
F.interiorEdges=numel(ii);
F.nonManifoldEdges=nnz(counts>2);
F.maxNeighborRatio=max(ordered);
F.ratioOver1p8Count=nnz(ratios>1.8);
F.ratioOver1p8Fraction=nnz(ratios>1.8)/max(1,numel(ii));
% Full connectivity fingerprint of quality-HOLD edges; distinguishes
% an unchanged count from the same *actual* edge IDs before/after collapse.
failedInteriorEdges=ii(ratios>1.8);
F.overLimitEdgeNodeIDs=edges(failedInteriorEdges,:);
F.overLimitOwnerElementIDs=[elo(failedInteriorEdges),ehi(failedInteriorEdges)];
F.overLimitEdgeMidpoints_mm=.5*(X(edges(failedInteriorEdges,1),:)+ ...
    X(edges(failedInteriorEdges,2),:));
F.ratioQuantiles=struct('p50',local_quantile(ordered,.50), ...
    'p90',local_quantile(ordered,.90),'p95',local_quantile(ordered,.95), ...
    'p99',local_quantile(ordered,.99));
F.topPairs=repmat(struct('rank',0,'ratio',0,'edgeNodes',[], ...
    'elementIDs',[],'edgeMidpoint_mm',[],'centroidMidpoint_mm',[], ...
    'elementSizes_mm',[],'zone','', ...
    'nearestHoleIndex',0,'nearestHoleWallDistance_mm',NaN, ...
    'nearestHoleCenterDistance_mm',NaN, ...
    'crackTipDistance_mm',NaN),0,1);
centroids=(X(T(:,1),:)+X(T(:,2),:)+X(T(:,3),:))/3;
for k=1:min(topN,numel(idx))
    kk=idx(k);
    e=edges(ii(kk),:);
    t1=u(kk);t2=v(kk);
    mid=.5*(X(e(1),:)+X(e(2),:));
    cm=.5*(centroids(t1,:)+centroids(t2,:));
    [zone,holeIndex,holeWallDistance,holeCenterDistance,dTip]= ...
        local_zone(mid,crackTip,holeCenters,holeRadii);
    F.topPairs(k,1)=struct('rank',k,'ratio',ordered(k), ...
        'edgeNodes',e,'elementIDs',[t1,t2], ...
        'edgeMidpoint_mm',mid, ...
        'centroidMidpoint_mm',cm, ...
        'elementSizes_mm',[h(t1),h(t2)], ...
        'zone',zone, ...
        'nearestHoleIndex',holeIndex, ...
        'nearestHoleWallDistance_mm',holeWallDistance, ...
        'nearestHoleCenterDistance_mm',holeCenterDistance, ...
        'crackTipDistance_mm',dTip);
end
if isempty(F.topPairs)
    F.worst=struct();
else
    F.worst=F.topPairs(1);
end
F.thresholdReference=1.8;
F.hasQualityHOLD=F.maxNeighborRatio>1.8;
F.examinedOnly=true;
end

function [zone,k,dWall,dCenter,dTip]=local_zone(mid,tip,holes,radii)
% Always return ACTUAL signed distance to nearest circular surface.
% The category is just a visualization label; the metric is authoritative.
dTip=norm(mid-tip(:).');
dCenters=vecnorm(holes-mid,2,2);
dWalls=dCenters-radii(:);
[~,k]=min(abs(dWalls));
dWall=dWalls(k);
dCenter=dCenters(k);
if dTip<3.4
    zone='within_3p4mm_of_crack_tip';
elseif abs(mid(1)-tip(1))<2 && mid(2)>=-1 && mid(2)<tip(2)+1
    zone='crack_channel_neighborhood';
elseif abs(dWall)<=radii(k)
    % One local radius from the surface is an explicit scale-based zone;
    % the former fixed 3-mm cutoff misclassified 3.09 mm near upper hole.
    zone=sprintf('hole_%d_within_one_radius_of_wall',k);
else
    zone='bulk_or_outer_boundary';
end
end

function val=local_quantile(sortedDesc,p)
% Linear-interpolated percentile without Statistics Toolbox dependency.
S=flipud(sortedDesc(:));
n=numel(S);
if n==0,val=NaN;return,end
pos=1+(n-1)*p;
lo=floor(pos);hi=ceil(pos);
val=(hi-pos)*S(lo)+(pos-lo)*S(hi);
if lo==hi,val=S(lo);end
end
