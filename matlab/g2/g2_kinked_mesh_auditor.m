function C = g2_kinked_mesh_auditor(data, geometryFile, p0File, expectedVertices)
%G2_KINKED_MESH_AUDITOR  Independent kink-aware audit of a SAVED kinked protected Cornell #1 mesh.
%
%  C = g2_kinked_mesh_auditor(load(kinkedMAT), jsonPath, p0MAT)
% WP3.1 (Issue #24), WP3_PREREGISTRATION.md section 5, gate groups 1-11. Reads only
% the saved arrays, the saved crack polyline, the pinned Cornell JSON and the
% immutable isolated-P0 evidence MAT. It never calls the mesher, the join, the
% p010/vendor builders or g2_kinked_*; it does not modify its input. All crack, bank,
% seam and q tests use the saved polyline and the dynamic last-segment frame, not
% x = 101.6 or y-sorting. Geometry only: a PASS is not an LEFM permit.
if nargin<4,expectedVertices=3;end
assert(isscalar(expectedVertices)&&expectedVertices>=3&&expectedVertices==round(expectedVertices), ...
 'G2KA:ExpectedVertices','Expected crack vertex count must be an integer >=3.');
req={'X3','T3','X6','T6','upperBankT6','lowerBankT6','physicalTipNode','nodalQ','crackPolyline', ...
     'tipTangent','geometryOnly','approvedForLEFM'};
assert(isstruct(data)&&all(isfield(data,req)),'G2KA:MissingData','Saved MAT lacks required fields.');
J=jsondecode(fileread(geometryFile));
assert(strcmp(J.schema,'NewMetacomp.G2.IngraffeaGrigoriu1990.Specimen1.nominal.v1'),'G2KA:Schema','Wrong JSON.');
Gm=J.nominal_geometry_mm;
P0=load(p0File,'X3','T3','qActiveT6Rows');
X3=data.X3;T3=data.T3;X6=data.X6;T6=data.T6;U=data.upperBankT6(:);L=data.lowerBankT6(:);tipID=data.physicalTipNode;
P=data.crackPolyline;Nv=size(P,1);
n3=size(X3,1);n6=size(X6,1);ne=size(T6,1);
xmin=Gm.plate.x_range(1);xmax=Gm.plate.x_range(2);ymin=Gm.plate.y_range(1);ymax=Gm.plate.y_range(2);
nh=numel(Gm.holes);cen=zeros(nh,2);rad=zeros(nh,1);
for k=1:nh,cen(k,:)=Gm.holes(k).center(:).';rad(k)=Gm.holes(k).radius;end
% independent polyline frame (no shared helper)
ds=diff(P,1,1);sl=sqrt(sum(ds.^2,2));tt=ds./sl;nn=[-tt(:,2),tt(:,1)];
tip=P(end,:);t=tt(end,:);n=nn(end,:);S=[0;cumsum(sl)];
tip0=Gm.initial_crack.tip(:).';t0=[0 1];n0=[-1 0];
rc=3;ro=3.3;tolT=1e-7;g=struct();
% ---- 1. arrays and T6
g.G1_arrayShapesAndIndices=size(X3,2)==2&&size(T3,2)==3&&size(X6,2)==2&&size(T6,2)==6&&size(T3,1)==ne&& ...
 all(T3(:)>=1&T3(:)<=n3&T3(:)==round(T3(:)))&&all(T6(:)>=1&T6(:)<=n6&T6(:)==round(T6(:)))&& ...
 all(isfinite(X3(:)))&&all(isfinite(X6(:)));
assert(g.G1_arrayShapesAndIndices,'G2KA:Arrays','Cannot audit invalid arrays.');
cn=T6(:,1:3);mn=T6(:,4:6);
raw=sort([cn(:,[1 2]);cn(:,[2 3]);cn(:,[3 1])],2);mids=[mn(:,1);mn(:,2);mn(:,3)];own=repmat((1:ne)',3,1);
[E,~,ic]=unique(raw,'rows');nE=size(E,1);cnt=accumarray(ic,1,[nE 1]);
mLo=accumarray(ic,mids,[],@min);mHi=accumarray(ic,mids,[],@max);oLo=accumarray(ic,own,[],@min);oHi=accumarray(ic,own,[],@max);
midErr=max(vecnorm(X6(mLo,:)-.5*(X6(E(:,1),:)+X6(E(:,2),:)),2,2));
g.G1_T6CornersEqualT3AndAllNodesUsed=isequal(cn,T3)&&isequal(X6(1:n3,:),X3)&&isequal(unique(T6(:)),(1:n6)')&& ...
 isempty(intersect(cn(:),mn(:)));
g.G1_uniqueMidsidesAtGeometricMidpoints=all(mLo==mHi)&&numel(unique(mLo))==nE&&n6==n3+nE&&midErr<1e-10;
g.G1_noNonmanifoldEdges=all(cnt>=1&cnt<=2);
% ---- 2. quality
Jc=g2_independent_t6_jacobian(X6,T6);
L12=vecnorm(X3(T3(:,2),:)-X3(T3(:,1),:),2,2);L23=vecnorm(X3(T3(:,3),:)-X3(T3(:,2),:),2,2);L31=vecnorm(X3(T3(:,1),:)-X3(T3(:,3),:),2,2);
cl=@(z)max(-1,min(1,z));
ang=[acosd(cl((L12.^2+L31.^2-L23.^2)./(2*L12.*L31))),acosd(cl((L12.^2+L23.^2-L31.^2)./(2*L12.*L23))),acosd(cl((L23.^2+L31.^2-L12.^2)./(2*L23.*L31)))];
minAng=min(ang(:));h=max([L12,L23,L31],[],2);in=cnt==2;
ratio=max(h(oLo(in))./h(oHi(in)),h(oHi(in))./h(oLo(in)));maxRatio=max(ratio);
a=X3(T3(:,2),:)-X3(T3(:,1),:);b=X3(T3(:,3),:)-X3(T3(:,1),:);a2=a(:,1).*b(:,2)-a(:,2).*b(:,1);
g.G2_allT3AreasAndT6JacobiansPositive=all(a2>0)&&Jc.allPositive;
g.G2_minAngleAtLeast20=minAng>=20;
g.G2_neighborRatioAtMost1p8=maxRatio<=1.8;
% ---- 3. boundary classification by physical geometry only
bI=find(cnt==1);be=E(bI,:);bm=mLo(bI);p1=X6(be(:,1),:);p2=X6(be(:,2),:);pm=X6(bm,:);
onPl=@(p)[abs(p(:,1)-xmin)<tolT,abs(p(:,1)-xmax)<tolT,abs(p(:,2)-ymin)<tolT,abs(p(:,2)-ymax)<tolT];
plateE=any(onPl(p1)&onPl(p2)&onPl(pm),2);
holeE=false(numel(bI),nh);
for k=1:nh,holeE(:,k)=abs(vecnorm(p1-cen(k,:),2,2)-rad(k))<1e-5&abs(vecnorm(p2-cen(k,:),2,2)-rad(k))<1e-5;end
[dp1,~]=pdist_poly(p1,P);[dp2,~]=pdist_poly(p2,P);[dpm,kpm]=pdist_poly(pm,P);
crackE=dp1<tolT&dp2<tolT&dpm<tolT;
cls=double(plateE)+double(crackE)+sum(holeE,2);
g.G3_everyBoundaryEdgeExactlyOneClass=all(cls==1);
bn=unique(be(:));[~,bmap]=ismember(be,bn);comp=conncomp(graph(bmap(:,1),bmap(:,2),[],numel(bn)));ec=comp(bmap(:,1));
pure=true;hc=zeros(nh,1);
for k=1:nh
 ids=unique(ec(holeE(:,k)));
 if numel(ids)~=1,pure=false;else,hc(k)=ids;pure=pure&&nnz(ec==ids)==nnz(holeE(:,k));end
end
g.G3_fourComponentsThreePureHoleLoops=max(comp)==4&&pure&&numel(unique(hc))==nh&&all(hc>0)&&all(sum(holeE,1)>=12);
% ---- 4. topology and lengths
plateLen=sum(vecnorm(p1(plateE,:)-p2(plateE,:),2,2));crackLen=sum(vecnorm(p1(crackE,:)-p2(crackE,:),2,2));
g.G4_platePerimeterAndDoubleCrackLength=abs(plateLen-2*((xmax-xmin)+(ymax-ymin)))<1e-5&&abs(crackLen-2*S(end))<1e-5;
dual=conncomp(graph(oLo(in),oHi(in),[],ne));
g.G4_connectedEulerMinusTwo=max(dual)==1&&n3-nE+ne==-2;
area=.5*sum(a2);aRef=(xmax-xmin)*(ymax-ymin)-pi*sum(rad.^2);
g.G4_materialAreaMatchesAnalytic=abs(area/aRef-1)<.005;
% ---- 5. banks on the polyline
g.G5_bankSetsValidEqualSizeShareOnlyTip=numel(U)==numel(L)&&numel(U)>3&&numel(unique(U))==numel(U)&&numel(unique(L))==numel(L)&& ...
 isequal(intersect(U,L),tipID)&&isscalar(find(vecnorm(X6-tip,2,2)<1e-9))&&norm(X6(tipID,:)-tip)<1e-9;
[dU,kU]=pdist_poly(X6(U,:),P);[dL,kL]=pdist_poly(X6(L,:),P);
g.G5_allBankNodesOnPolyline=max([dU;dL])<1e-9;
% owner side of each crack boundary edge vs saved bank membership
ce=(X3(T3(oLo(bI),1),:)+X3(T3(oLo(bI),2),:)+X3(T3(oLo(bI),3),:))/3;
sd=sum((ce-P(kpm,:)).*nn(kpm,:),2);
crU=crackE&sd>0;crL=crackE&sd<0;
nodesU=unique([be(crU,1);be(crU,2);bm(crU)]);nodesL=unique([be(crL,1);be(crL,2);bm(crL)]);
g.G5_upperOnPlusNLowerOnMinusN=nnz(crackE)==nnz(crU)+nnz(crL)&&isequal(nodesU,sort(U))&&isequal(nodesL,sort(L));
sU=station(X6(U,:),P,kU,S);sL=station(X6(L,:),P,kL,S);[sU,iu]=sort(sU);Us=U(iu);[sL,il]=sort(sL);Ls=L(il);
twin=numel(Us)==numel(Ls)&&max(vecnorm(X6(Us,:)-X6(Ls,:),2,2))<1e-9&&all(Us(1:end-1)~=Ls(1:end-1));
g.G5_twinsCoincideWithDistinctIDs=twin;
g.G5_banksReachMouthAndTip=twin&&norm(X6(Us(1),:)-P(1,:))<1e-9&&norm(X6(Ls(1),:)-P(1,:))<1e-9&&Us(end)==tipID&&Ls(end)==tipID&& ...
 abs(sU(end)-S(end))<1e-9;
perSeg=true;
for k=1:Nv-1
 eU=crU&kpm==k;eL=crL&kpm==k;perSeg=perSeg&&nnz(eU)==nnz(eL)&&nnz(eU)>0;
end
g.G5_everySegmentHasTwinEdgesOnBothBanks=perSeg;
kinkOK=true;
for k=2:Nv-1
 ids=find(vecnorm(X6-P(k,:),2,2)<1e-9);kinkOK=kinkOK&&numel(ids)==2&&numel(intersect(ids,U))==1&&numel(intersect(ids,L))==1;
end
g.G5_eachKinkVertexHasOneNodePerBank=kinkOK&&Nv>=3;
[~,~,grp]=unique(round(X6/1e-7),'rows');mult=accumarray(grp,1);dup=find(mult(grp)>1);
g.G5_coincidentNodesOnlyBankTwins=all(mult<=2)&&isequal(sort(dup),sort(setdiff(union(U,L),tipID)));
% ---- 6. kernel identity against the P0 evidence (local frames)
nb=size(P0.X3,1);mb=size(P0.T3,1);
locK=[(X3(1:min(nb,n3),:)-tip)*t.',(X3(1:min(nb,n3),:)-tip)*n.'];
loc0=[(P0.X3-tip0)*t0.',(P0.X3-tip0)*n0.'];
kernErr=inf;if n3>=nb,kernErr=max(vecnorm(locK-loc0,2,2));end
g.G6_rotatedKernelAndCollarMatchP0LocalCoordinates=mb==2916&&kernErr<1e-9;
g.G6_kernelAndCollarConnectivityIdenticalToP0=ne>=mb&&isequal(T3(1:mb,:),P0.T3);
r3=vecnorm(X3-tip,2,2);cT=(X3(T3(:,1),:)+X3(T3(:,2),:)+X3(T3(:,3),:))/3;rcen=vecnorm(cT-tip,2,2);
g.G6_exactly2916ElementsInsideRimNoExteriorNodeInside=isequal(find(rcen<ro),(1:mb)')&&all(r3(nb+1:end)>ro-1e-9);
% ---- 7. seams about the new tip
seam=@(R)find(all(abs(r3(E)-R)<1e-9,2));s3=seam(rc);s33=seam(ro);
two=@(s,R)all(cnt(s)==2)&&all(min(rcen(oLo(s)),rcen(oHi(s)))<R)&&all(max(rcen(oLo(s)),rcen(oHi(s)))>R);
g.G7_seams64Plus64TwoOwnersOppositeSides=numel(s3)==64&&numel(s33)==64&&two(s3,rc)&&two(s33,ro);
g.G7_65IdentitiesOnEachSeamCircle=nnz(abs(r3-rc)<1e-9)==65&&nnz(abs(r3-ro)<1e-9)==65;
th=@(p)atan2(p(:,2)-tip(2),p(:,1)-tip(1));
dth=abs(angle(exp(1i*(th(X3(E(s33,1),:))-th(X3(E(s33,2),:))))));
g.G7_rimSeamEdgesSingleChords=numel(s33)==64&&max(abs(dth-2*pi/64))<1e-9;
% ---- 8. tip
fan=find(any(T3==tipID,2));nbr=unique(T3(fan,:));nbr(nbr==tipID)=[];
g.G8_tipFanSixTrianglesSevenNeighboursPitch=numel(fan)==6&&numel(nbr)==7&&all(fan<=2788)&& ...
 abs(min(vecnorm(X3(nbr,:)-tip,2,2))-.1*3/7.2)<1e-9;
g.G8_lastSegmentLengthAndSavedTangent=abs(sl(end)-4)<1e-9&&norm(t-data.tipTangent(:).')<1e-12;
% ---- 9. q support about the new tip
r6=vecnorm(X6-tip,2,2);q=ones(n6,1);q(r6>=2.6)=0;tr=r6>.4&r6<2.6;q(tr)=(2.6-r6(tr))/2.2;
act=find(max(q(T6),[],2)-min(q(T6),[],2)>1e-14);qn=unique(T6(act,:));
dKink=inf;for k=2:Nv-1,dKink=min(dKink,min(vecnorm(X6(qn,:)-P(k,:),2,2)));end
g.G9_nodalQEqualsRecomputation=numel(data.nodalQ)==n6&&max(abs(q-data.nodalQ(:)))<1e-14;
g.G9_qActive2443EqualsP0AllInKernel=numel(act)==2443&&all(act<=2788)&&isequal(act,P0.qActiveT6Rows(:));
g.G9_qSupportInsideInradiusZeroOutsideClearOfKink=max(r6(qn))<rc*cos(pi/64)&&all(q(unique(T6(2789:end,:)))==0)&&dKink>0;
% ---- 10. geometry K-gates recomputed from the saved polyline (independent arithmetic)
mouth=Gm.initial_crack.mouth(:).';w=.020;
dPrev=inf;for j=1:Nv-2,dPrev=min(dPrev,pseg(tip,P(j,:),P(j+1,:)));end
den=1+sum(tt(1:end-1,:).*tt(2:end,:),2);
segH=inf(Nv-1,nh);for j=1:Nv-1,for k=1:nh,segH(j,k)=pseg(cen(k,:),P(j,:),P(j+1,:));end,end
dT=vecnorm(cen-tip,2,2);side=[tip(1)-xmin,xmax-tip(1),tip(2)-ymin,ymax-tip(2)];
selfOK=true;for i=1:Nv-1,for j=i+2:Nv-1,selfOK=selfOK&&sdist(P(i,:),P(i+1,:),P(j,:),P(j+1,:))>=2*w+.12;end,end
K=struct('K1',Nv==expectedVertices&&norm(P(1,:)-mouth)<=1e-12&&norm(P(2,:)-tip0)<=1e-12&& ...
 all(abs(sl(2:end)-4)<=1e-12), ...
 'K2',all(den>1.8),'K3',sl(end)>ro&&dot(tip-ro*t-P(end-1,:),t)>0,'K4',dPrev-ro-w>=2*ro*sin(pi/64),'K5',dPrev>rc, ...
 'K6',all(all(segH-rad.'>3)),'K7',all(all(segH-3*rad.'>w+1.5)),'K8',all(dT-rad>ro)&&all(dT-3*rad>ro)&&all(side>ro), ...
 'K9',all(side>15)&&all(dT>15+3*rad), ...
 'K10',all(P(2:end,1)>xmin&P(2:end,1)<xmax&P(2:end,2)>ymin&P(2:end,2)<ymax)&&abs(P(1,2)-ymin)<=1e-12&&selfOK);
kv=cell2mat(struct2cell(K));
g.G10_kinkAdmissibilityK1toK10=all(kv);
blk=unique(T3(1:mb,:));dHole=min(min(vecnorm(permute(X3(blk,:),[1 3 2])-permute(cen,[3 1 2]),2,3)-rad.'));
g.G10_protectedRegionClearOfHolesGuidesPlate=dHole>3*max(rad)&&all(min(X3(blk,:))>[xmin ymin])&&all(max(X3(blk,:))<[xmax ymax]);
% ---- 11. source flags
g.G11_geometryOnlyNoLEFMApproval=logical(data.geometryOnly)&&~logical(data.approvedForLEFM);
v=cell2mat(struct2cell(g));f=fieldnames(g);
C=struct('pass',all(v),'stage','HOLD_KINKED_AUDIT','gates',g,'gatesPassed',nnz(v),'gatesTotal',numel(v), ...
 'failedGates',{f(~v)},'kGates',K,'approvedForLEFM',false,'summary',struct('T3nodes',n3,'T3elements',ne,'T6nodes',n6, ...
 'uniqueEdges',nE,'Euler',n3-nE+ne,'boundaryComponents',max(comp),'holeBoundaryEdges',sum(holeE,1), ...
 'crackBoundaryEdges',nnz(crackE),'crackEdgesPerSide',[nnz(crU),nnz(crL)],'bankNodesPerSide',[numel(U),numel(L)], ...
 'minAngle_deg',minAng,'maxNeighborRatio',maxRatio,'minJacobian_mm2',Jc.minDet_mm2,'maxMidsideError_mm',midErr, ...
 'materialArea_mm2',area,'analyticArea_mm2',aRef,'kernelLocalCoordinateError_mm',kernErr,'qActive',numel(act), ...
 'qSupportMaxRadius_mm',max(r6(qn)),'qSupportDistanceToKink_mm',dKink,'tip_mm',tip,'tangent',t, ...
 'turn_deg',atan2d(tt(1,1)*tt(end,2)-tt(1,2)*tt(end,1),dot(tt(1,:),tt(end,:))),'minDistanceProtectedNodeToHoleWall_mm',dHole));
if C.pass,C.stage='KINKED_MESH_INDEPENDENT_AUDIT_PASS';end
fprintf('G2_KINKED_AUDIT_GATES=%d/%d\nG2_KINKED_AUDIT_PASS=%d\n',C.gatesPassed,C.gatesTotal,C.pass);
if ~C.pass,fprintf(2,'G2_KINKED_AUDIT_HOLD=%s\n',strjoin(C.failedGates,','));end
end

function [d,k]=pdist_poly(X,P)
M=size(X,1);nk=size(P,1)-1;D=inf(M,nk);
for j=1:nk
 v=P(j+1,:)-P(j,:);l=max(0,min(1,((X-P(j,:))*v.')/(v*v.')));D(:,j)=sqrt(sum((X-(P(j,:)+l*v)).^2,2));
end
[d,k]=min(D,[],2);
end

function s=station(X,P,k,S)
s=zeros(size(X,1),1);
for i=1:size(X,1),v=P(k(i)+1,:)-P(k(i),:);s(i)=S(k(i))+dot(X(i,:)-P(k(i),:),v)/norm(v);end
end

function d=pseg(p,a,b)
v=b-a;l=max(0,min(1,dot(p-a,v)/dot(v,v)));d=norm(p-(a+l*v));
end

function d=sdist(a,b,c,e)
o=@(p,q,r)(q(1)-p(1))*(r(2)-p(2))-(q(2)-p(2))*(r(1)-p(1));
if o(a,b,c)*o(a,b,e)<0&&o(c,e,a)*o(c,e,b)<0,d=0;return,end
d=min([pseg(a,c,e),pseg(b,c,e),pseg(c,a,b),pseg(e,a,b)]);
end
