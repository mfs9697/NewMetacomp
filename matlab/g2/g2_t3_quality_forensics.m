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
F.minDoubleArea_mm2=min(area2);
F.interiorEdges=numel(ii);
F.nonManifoldEdges=nnz(counts>2);
F.maxNeighborRatio=max(ordered);
F.ratioOver1p8Count=nnz(ratios>1.8);
F.ratioOver1p8Fraction=nnz(ratios>1.8)/max(1,numel(ii));
F.ratioQuantiles=struct('p50',prctile(ratios,50), ...
    'p90',prctile(ratios,90),'p95',prctile(ratios,95), ...
    'p99',prctile(ratios,99));
F.topPairs=repmat(struct('rank',0,'ratio',0,'edgeNodes',[], ...
    'elementIDs',[],'edgeMidpoint_mm',[],'centroidMidpoint_mm',[], ...
    'elementSizes_mm',[],'zone',''),0,1);
centroids=(X(T(:,1),:)+X(T(:,2),:)+X(T(:,3),:))/3;
for k=1:min(topN,numel(idx))
    kk=idx(k);
    e=edges(ii(kk),:);
    t1=u(kk);t2=v(kk);
    mid=.5*(X(e(1),:)+X(e(2),:));
    cm=.5*(centroids(t1,:)+centroids(t2,:));
    zone=local_zone(mid,crackTip,holeCenters,holeRadii);
    F.topPairs(k,1)=struct('rank',k,'ratio',ordered(k), ...
        'edgeNodes',e,'elementIDs',[t1,t2], ...
        'edgeMidpoint_mm',mid, ...
        'centroidMidpoint_mm',cm, ...
        'elementSizes_mm',[h(t1),h(t2)], ...
        'zone',zone);
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

function zone=local_zone(mid,tip,holes,radii)
dTip=norm(mid-tip(:).');
if dTip<3.4
    zone='within_3p4mm_of_crack_tip';
    return
end
% Channel extends from bottom edge to tip; distinguish long crack faces.
if abs(mid(1)-tip(1))<2 && mid(2)>=-1&&mid(2)<tip(2)+1
    zone='crack_channel_neighborhood';
    return
end
dHole=vecnorm(holes-mid,2,2)-radii(:);
[dmin,k]=min(abs(dHole));
if dmin<3
    zone=sprintf('hole_%d_boundary_neighborhood',k);
    return
end
zone='bulk_or_outer_boundary';
end
