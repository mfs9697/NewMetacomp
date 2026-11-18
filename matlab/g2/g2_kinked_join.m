function R = g2_kinked_join(P, varargin)
%G2_KINKED_JOIN  Full protected Cornell #1 mesh for a KINKED crack: rotated p010 + collar + kinked exterior.
%
%  R = g2_kinked_join(P, 'ExteriorOptions',{...}, 'MaxT3Elements',40000, 'ExpectedTangent',t1)
% WP3.1 (Issue #24), geometry only. As g2_join_protected_mesh (unchanged) but for a
% polyline: rows 1..2916 are the rotated kernel and collar of g2_kinked_regular_block;
% the 65 exterior rim identities are replaced by the collar outer identities
% (P(j) -> outer(j), upper entry -> outer(33), lower entry -> outer(65)).
% Crack banks come from one-owner edges lying on the polyline; the side of each
% edge is the sign of (owner centroid - P_k).n_k for the segment k containing the
% edge midpoint (upper = +n). All gates are recomputed on the joined arrays; the
% independent kink-aware audit (g2_kinked_mesh_auditor) re-checks the SAVED arrays.
% No PDE solve, no SIF, no crack growth.
ip=inputParser;
addParameter(ip,'ExteriorOptions',{},@iscell);
addParameter(ip,'MaxT3Elements',40000,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'ExpectedTangent',[],@(v)isempty(v)||(isnumeric(v)&&numel(v)==2));
addParameter(ip,'ExpectedVertices',3,@(v)isnumeric(v)&&isscalar(v)&&v>=3&&v==round(v));
parse(ip,varargin{:});o=ip.Results;
R=struct('pass',false,'stage','HOLD_NOT_STARTED','message','','geometryOnly',true,'approvedForLEFM',false, ...
 'gates',struct(),'failedGates',{{}},'summary',struct());
xo=o.ExteriorOptions;kg=find(strcmpi(xo(1:2:end),'TipGuideRadius_mm'));Rg=[];if ~isempty(kg),Rg=xo{2*kg(end)};end
B=g2_kinked_regular_block(P,'ExpectedTangent',o.ExpectedTangent,'ExpectedVertices',o.ExpectedVertices,'TipGuideRadius_mm',Rg);
R.block=rmfield(B,intersect(fieldnames(B),{'coord3','connect3','coord6','connect6','sourceP010','nodalQ'}));
if ~B.pass,R.stage='HOLD_KINKED_P010_BLOCK';R.message=[B.stage,' ',B.message];return,end
E=g2_kinked_exterior_mesh(P,'ExpectedTangent',o.ExpectedTangent,'ExpectedVertices',o.ExpectedVertices,xo{:});
R.exterior=rmfield(E,intersect(fieldnames(E),{'coord3','connect3'}));
if ~E.pass,R.stage='HOLD_KINKED_EXTERIOR';R.message=[E.stage,' ',E.message];return,end
XB=B.coord3;TB=B.connect3;nB=size(XB,1);nU=B.kernelNodes;outerIDs=B.collarOuterIDs;
assert(nB==nU+65&&size(TB,1)==2916&&isequal(outerIDs,(nU+(1:65))'),'G2KJ:BlockLayout','Unexpected block layout.');
XE=E.coord3;TE=E.connect3;nE=size(XE,1);
map=zeros(nE,1);
rimExt=[E.rimNodeAtP([1:32,34:64]);E.rimEntryUpper;E.rimEntryLower];
rimBlk=[outerIDs([1:32,34:64]);outerIDs(33);outerIDs(65)];
map(rimExt)=rimBlk;others=setdiff((1:nE)',rimExt);map(others)=nB+(1:numel(others))';
coordDiff=max(vecnorm(XE(rimExt,:)-XB(rimBlk,:),2,2));
X3=[XB;XE(others,:)];T3=[TB;map(TE)];
nCore=2788;nColl=128;nBlock=nCore+nColl;
rows=struct('core',(1:nCore)','collar',(nCore+1:nBlock)','exterior',(nBlock+1:size(T3,1))');
[X6,T6]=T3toT6_fast(X3,T3);
F=g2_polyline_frame(P);tip=F.tip;tipNode=B.tipNode;
% ---- quality
a=X3(T3(:,2),:)-X3(T3(:,1),:);b=X3(T3(:,3),:)-X3(T3(:,1),:);a2=a(:,1).*b(:,2)-a(:,2).*b(:,1);
L12=vecnorm(a,2,2);L31=vecnorm(b,2,2);L23=vecnorm(X3(T3(:,3),:)-X3(T3(:,2),:),2,2);
cl=@(z)max(-1,min(1,z));
ang=[acosd(cl((L12.^2+L31.^2-L23.^2)./(2*L12.*L31))),acosd(cl((L12.^2+L23.^2-L31.^2)./(2*L12.*L23))), ...
     acosd(cl((L23.^2+L31.^2-L12.^2)./(2*L23.*L31)))];
h=max([L12,L23,L31],[],2);
raw=sort([T3(:,[1 2]);T3(:,[2 3]);T3(:,[3 1])],2);[edges,~,ic]=unique(raw,'rows');
cnt=accumarray(ic,1);own=repmat((1:size(T3,1))',3,1);
lo=accumarray(ic,own,[],@min);hi=accumarray(ic,own,[],@max);in=cnt==2;
ratio=max(h(lo(in))./h(hi(in)),h(hi(in))./h(lo(in)));
[angMin,iAng]=min(min(ang,[],2));[ratMax,iRat]=max(ratio);inE=find(in);
% ---- seams about the new tip
r3=vecnorm(X3-tip,2,2);
rimEdge=find(all(abs(r3(edges)-3.3)<1e-9,2));
rimTwoOwner=numel(rimEdge)==64&&all(cnt(rimEdge)==2)&&all(ismember(lo(rimEdge),rows.collar))&&all(ismember(hi(rimEdge),rows.exterior));
coreEdge=find(all(abs(r3(edges)-3.0)<1e-9,2));
coreTwoOwner=numel(coreEdge)==64&&all(cnt(coreEdge)==2)&&all(ismember(lo(coreEdge),rows.core))&&all(ismember(hi(coreEdge),rows.collar));
% ---- banks from boundary edges on the polyline
bnd=find(cnt==1);e1=X3(edges(bnd,1),:);e2=X3(edges(bnd,2),:);em=.5*(e1+e2);
[d1,~]=polydist(e1,P);[d2,~]=polydist(e2,P);[dm,km]=polydist(em,P);
onCrack=d1<1e-9&d2<1e-9&dm<1e-9;
cen=(X3(T3(lo(bnd),1),:)+X3(T3(lo(bnd),2),:)+X3(T3(lo(bnd),3),:))/3;
side=sum((cen-P(km,:)).*F.nn(km,:),2);
bU=bnd(onCrack&side>0);bL=bnd(onCrack&side<0);
upT3=unique(edges(bU,:));loT3=unique(edges(bL,:));
upT6=unique([upT3;midsides(T3,T6,edges(bU,:))]);loT6=unique([loT3;midsides(T3,T6,edges(bL,:))]);
upT6=sortStation(upT6,X6,P);loT6=sortStation(loT6,X6,P);upT3=sortStation(upT3,X3,P);loT3=sortStation(loT3,X3,P);
kinkIDs=zeros(size(P,1)-2,2);
kinksOK=true;
for kp=2:size(P,1)-1
 ids=find(vecnorm(X3-P(kp,:),2,2)<1e-12);
 if numel(ids)~=2
  kinksOK=false;
 else
  kinkIDs(kp-1,:)=ids(:).';
  kinksOK=kinksOK && nnz(ismember(ids,upT3))==1 && ...
    nnz(ismember(ids,loT3))==1;
 end
end
banksOK=nnz(onCrack)==numel(bU)+numel(bL)&&numel(bU)==numel(bL)&&numel(bU)>3&&isequal(intersect(upT6,loT6),tipNode)&& ...
 ismember(outerIDs(33),upT3)&&ismember(outerIDs(65),loT3)&&upT3(end)==tipNode&&loT3(end)==tipNode&& ...
 norm(X3(upT3(1),:)-P(1,:))<1e-9&&norm(X3(loT3(1),:)-P(1,:))<1e-9&& ...
 kinksOK && size(kinkIDs,1)==size(P,1)-2;
% ---- FE-nodal q about the new tip
r6=vecnorm(X6-tip,2,2);q=ones(size(r6));q(r6>=2.6)=0;tr=r6>.4&r6<2.6;q(tr)=(2.6-r6(tr))/2.2;
qActive=find(max(q(T6),[],2)-min(q(T6),[],2)>1e-14);
qInside=all(ismember(qActive,rows.core))&&numel(qActive)==2443&&max(r6(unique(T6(qActive,:))))<3*cos(pi/64);
g=struct('kinkedP010BlockPass',B.pass,'kinkedExteriorPass',E.pass,'rimCoordinatesCoincide',coordDiff<1e-12, ...
 'blockRowsAndNodesUnchanged',isequal(T3(1:nBlock,:),TB)&&isequal(X3(1:nB,:),XB),'allT3AreasPositive',all(a2>0), ...
 'globalMinAngleAtLeast20',angMin>=20,'globalNeighborRatioAtMost1p8',ratMax<=1.8,'noNonmanifoldEdges',all(cnt<=2), ...
 'coreCollarSeam64TwoOwners',coreTwoOwner,'collarExteriorSeam64TwoOwners',rimTwoOwner, ...
 'distinctBanksOnPolylineMeetOnlyAtTip',banksOK,'qSupport2443InsideCore',qInside,'T3BudgetRespected',size(T3,1)<=o.MaxT3Elements);
v=cell2mat(struct2cell(g));fn=fieldnames(g);R.gates=g;R.failedGates=fn(~v);
cenT=(X3(T3(:,1),:)+X3(T3(:,2),:)+X3(T3(:,3),:))/3;
R.summary=struct('T3elements',size(T3,1),'T3nodes',size(X3,1),'T6nodes',size(X6,1),'coreT3',nCore,'collarT3',nColl, ...
 'exteriorT3',numel(rows.exterior),'minAngle_deg',angMin,'minAngleAt_mm',cenT(iAng,:),'maxNeighborRatio',ratMax, ...
 'maxRatioAt_mm',.5*(cenT(lo(inE(iRat)),:)+cenT(hi(inE(iRat)),:)),'rimSeamEdges',numel(rimEdge),'coreSeamEdges',numel(coreEdge), ...
 'crackBankEdgesPerSide',[numel(bU),numel(bL)],'bankT6NodesPerSide',[numel(upT6),numel(loT6)],'qActiveT6',numel(qActive), ...
 'tip_mm',tip,'tangent',F.t,'normal',F.n,'tipNode',tipNode,'kinkNodeIDs',reshape(kinkIDs.',1,[]),'rimCoordinateMismatch_mm',coordDiff, ...
 'polyline_mm',P,'turn_deg',F.turns_deg.','exterior',E.summary,'block',B.summary);
fprintf('G2_KJOIN_GATES=%d/%d\n',nnz(v),numel(v));
fprintf('G2_KJOIN_T3=%d T6_NODES=%d MIN_ANGLE=%.6f MAX_RATIO=%.6f\n',size(T3,1),size(X6,1),angMin,ratMax);
R.pass=all(v);
if R.pass,R.stage='KINKED_PROTECTED_MESH_JOIN_PASS';R.message='Joined; the independent kink-aware audit is still required.';
else,R.stage='HOLD_KINKED_PROTECTED_MESH_JOIN';R.message=strjoin(R.failedGates,', ');end
R.X3=X3;R.T3=T3;R.X6=X6;R.T6=T6;R.upperBankT6=upT6;R.lowerBankT6=loT6;R.physicalTipNode=tipNode;
R.nodalQ=q;R.qActiveT6Rows=qActive;R.elementRows=rows;R.collarOuterIDs=outerIDs;
R.extraVertexXY=E.extraVertexXY;R.extraVertexNodes=map(E.extraVertexNodes);R.includeHoles=true;R.plateXRange=E.plateXRange;
R.crackPolyline=P;R.tipTangent=F.t;R.tipNormal=F.n;
R.kinkNodeIDs=reshape(kinkIDs.',[],1);
end

function [d,k]=polydist(X,P)
M=size(X,1);nk=size(P,1)-1;D=inf(M,nk);
for j=1:nk
 v=P(j+1,:)-P(j,:);l=max(0,min(1,((X-P(j,:))*v.')/(v*v.')));D(:,j)=vecnorm(X-(P(j,:)+l*v),2,2);
end
[d,k]=min(D,[],2);
end

function ids=sortStation(ids,X,P)
F=g2_polyline_frame(P);nk=size(P,1)-1;M=numel(ids);D=inf(M,nk);S=zeros(M,nk);
for j=1:nk
 v=P(j+1,:)-P(j,:);l=max(0,min(1,((X(ids,:)-P(j,:))*v.')/(v*v.')));
 D(:,j)=vecnorm(X(ids,:)-(P(j,:)+l*v),2,2);S(:,j)=F.stations(j)+l*F.segmentLengths(j);
end
[~,k]=min(D,[],2);s=S(sub2ind([M,nk],(1:M)',k));[~,o]=sort(s);ids=ids(o);
end

function m=midsides(T3,T6,e)
K=[sort(T3(:,[1 2]),2);sort(T3(:,[2 3]),2);sort(T3(:,[3 1]),2)];M=[T6(:,4);T6(:,5);T6(:,6)];
[f,loc]=ismember(sort(e,2),K,'rows');assert(all(f),'G2KJ:MissingEdge','Bank edge not in T3.');m=M(loc);
end
