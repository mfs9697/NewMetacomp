function V=g2_a1_mesh_validate(M,D0)
%G2_A1_MESH_VALIDATE  Count-dependent physical invariants of an A1 Family B mesh (Issue #66).
%
%  V = g2_a1_mesh_validate(M,D0)   M: g2_a1_patch_swap output; D0: the saved A0 S4 mesh
% Replaces only the baseline COUNT literals (2788/2916/2443) of g2_kinked_join and
% g2_kinked_mesh_auditor, which stay unchanged and authoritative for A0. Every quality
% floor is kept: positive areas, min angle >= 20 deg, neighbour longest-edge ratio <= 1.8,
% patch disk floors (min angle >= 30 deg, shape quality > 0.85, as in the vendor ring gate),
% manifold edges, no orphan or hanging nodes, exact T6 midsides, 64-edge two-owner seams at
% r = 3 and 3.3 mm, two matched banks meeting only at one tip, six-cell tip fan, q support
% inside the core and zero on the rim, the 40,000-T3 budget, and bit-identical collar and
% exterior outside the core. Geometry only.
X3=M.X3;T3=M.T3;X6=M.X6;T6=M.T6;P=M.crackPolyline;F=g2_polyline_frame(P);tip=F.tip;
rows=M.elementRows;nCore=numel(rows.core);nP=M.a1.patchNodes;nU=M.a1.kernelNodesBaseline;
a=X3(T3(:,2),:)-X3(T3(:,1),:);b=X3(T3(:,3),:)-X3(T3(:,1),:);a2=a(:,1).*b(:,2)-a(:,2).*b(:,1);
L12=vecnorm(a,2,2);L31=vecnorm(b,2,2);L23=vecnorm(X3(T3(:,3),:)-X3(T3(:,2),:),2,2);
cl=@(z)max(-1,min(1,z));
ang=[acosd(cl((L12.^2+L31.^2-L23.^2)./(2*L12.*L31))),acosd(cl((L12.^2+L23.^2-L31.^2)./(2*L12.*L23))), ...
     acosd(cl((L23.^2+L31.^2-L12.^2)./(2*L23.*L31)))];
h=max([L12,L23,L31],[],2);Q=2*sqrt(3)*a2./(L12.^2+L23.^2+L31.^2);
raw=sort([T3(:,[1 2]);T3(:,[2 3]);T3(:,[3 1])],2);[edges,~,ic]=unique(raw,'rows');
cnt=accumarray(ic,1);own=repmat((1:size(T3,1))',3,1);lo=accumarray(ic,own,[],@min);hi=accumarray(ic,own,[],@max);in=cnt==2;
ratio=max(h(lo(in))./h(hi(in)),h(hi(in))./h(lo(in)));
r3=vecnorm(X3-tip,2,2);
rim=find(all(abs(r3(edges)-3.3)<1e-9,2));core=find(all(abs(r3(edges)-3.0)<1e-9,2));
g.allT3AreasPositive=all(a2>0);
g.globalMinAngleAtLeast20=min(ang(:))>=20;
g.globalNeighborRatioAtMost1p8=max(ratio)<=1.8;
dc=M.a1.diskCells;
g.patchDiskMinAngle30AndQualityAbove0p85=min(min(ang(dc,:)))>=30&&min(Q(dc))>.85;
g.patchWholeMinAngle20AndQualityAtLeast0p75=min(min(ang(rows.core,:)))>=20&&min(Q(rows.core))>=.75;
g.noNonmanifoldEdges=all(cnt<=2);
g.noOrphanNodes=isequal(unique(T3(:)),(1:size(X3,1))');
% boundary edges only on plate sides, hole circles or the crack polyline (no hanging nodes)
bnd=find(cnt==1);em=.5*(X3(edges(bnd,1),:)+X3(edges(bnd,2),:));
onPlate=abs(em(:,2))<1e-9|abs(em(:,2)-203.2)<1e-9|abs(em(:,1))<1e-9|abs(em(:,1)-508)<1e-9;
C=[152.4 69.85;152.4 120.65;152.4 171.45];onHole=false(size(bnd));
for k=1:3
 rr=vecnorm(X3(edges(bnd,:),:)-C(k,:),2,2);rr=reshape(rr,[],2);onHole=onHole|all(abs(rr-6.35)<1e-6,2);
end
dcr=polydist(em,P);g.boundaryEdgesOnlyPlateHolesOrCrack=all(onPlate|onHole|dcr<1e-9);
g.T6MidsidesExactAndUnique=size(X6,1)==size(X3,1)+size(edges,1)&& ...
 max(vecnorm(X6(T6(:,4),:)-.5*(X6(T6(:,1),:)+X6(T6(:,2),:)),2,2))<1e-12&& ...
 max(vecnorm(X6(T6(:,5),:)-.5*(X6(T6(:,2),:)+X6(T6(:,3),:)),2,2))<1e-12&& ...
 max(vecnorm(X6(T6(:,6),:)-.5*(X6(T6(:,3),:)+X6(T6(:,1),:)),2,2))<1e-12&&isequal(T6(:,1:3),T3);
g.coreCollarSeam64TwoOwners=numel(core)==64&&all(cnt(core)==2)&&all(ismember(lo(core),rows.core))&&all(ismember(hi(core),rows.collar));
g.collarExteriorSeam64TwoOwners=numel(rim)==64&&all(cnt(rim)==2)&&all(ismember(lo(rim),rows.collar))&&all(ismember(hi(rim),rows.exterior));
cenT=(X3(T3(:,1),:)+X3(T3(:,2),:)+X3(T3(:,3),:))/3;rc=vecnorm(cenT-tip,2,2);
g.coreRowsExactlyInsideCoreRadius=all(rc(rows.core)<3)&&all(rc([rows.collar;rows.exterior])>3);
U=M.upperBankT6(:);Lb=M.lowerBankT6(:);tipNode=M.physicalTipNode;
g.singleTipAtPolylineEnd=isscalar(tipNode)&&norm(X3(tipNode,:)-tip)<1e-12&&isequal(intersect(U,Lb),tipNode);
g.distinctMatchedBanks=numel(U)==numel(Lb)&&numel(U)>3&&max(vecnorm(X6(U,:)-X6(Lb,:),2,2))<1e-9&&nnz(U==Lb)==1;
fan=find(any(T3==tipNode,2));g.sixCellTipFan=numel(fan)==6&&all(ismember(fan,rows.core));
r6=vecnorm(X6-tip,2,2);act=M.qActiveT6Rows(:);
g.qSupportInsideCoreAndZeroOnRim=all(ismember(act,rows.core))&&max(r6(unique(T6(act,:))))<3*cos(pi/64)&& ...
 all(M.nodalQ(r6>=2.6)==0);
g.T3BudgetRespected=size(T3,1)<=40000;
% bit-identical collar + exterior relative to the saved A0 S4 mesh
sh=M.a1.nodeShift;rest0=D0.T3(2789:end,:);rest=T3(nCore+1:end,:);
rimOld=unique(rest0(rest0<=nU));map=zeros(nU,1);
for k=1:numel(rimOld)
 hit=find(all(X3(1:nP,:)==D0.X3(rimOld(k),:),2));   % saved rim coordinates are kept bit for bit
 if numel(hit)==2
  % the upper rim node and the lower bank entry coincide on the crack: choose by bank side
  if ismember(rimOld(k),D0.upperBankT6),hit=hit(ismember(hit,M.upperBankT6));
  elseif ismember(rimOld(k),D0.lowerBankT6),hit=hit(ismember(hit,M.lowerBankT6));end
 end
 if isscalar(hit),map(rimOld(k))=hit;end
end
expect=rest0;near=rest0<=nU;
g.exteriorNodesBitIdentical=isequal(X3(nP+1:end,:),D0.X3(nU+1:end,:));
if numel(rimOld)==65&&all(map(rimOld)>0)
 expect(near)=map(rest0(near));expect(~near)=rest0(~near)+sh;
 g.collarExteriorConnectivityPreserved=isequal(rest,expect);
else
 g.collarExteriorConnectivityPreserved=false;
end
v=cell2mat(struct2cell(g));fn=fieldnames(g);
% metrics
fanE=unique(sort([T3(fan,[1 2]);T3(fan,[2 3]);T3(fan,[3 1])],2),'rows');
fe=vecnorm(X3(fanE(:,1),:)-X3(fanE(:,2),:),2,2);isRad=any(fanE==tipNode,2);
an=[.4 2.6;.2 1.0;.4 1.6;.8 2.6;1.2 2.4];qa=zeros(5,1);
for k=1:5
 qq=ones(size(r6));qq(r6>=an(k,2))=0;tr=r6>an(k,1)&r6<an(k,2);qq(tr)=(an(k,2)-r6(tr))/(an(k,2)-an(k,1));
 qa(k)=nnz(max(qq(T6),[],2)-min(qq(T6),[],2)>1e-14);
end
bands=[0 .05;.05 .1;.1 .2;.2 .4;.4 .6;.6 .833;.833 1;1 1.5;1.5 2;2 2.6;2.6 3];hr=nan(size(bands,1),3);
for k=1:size(bands,1)
 s=rows.core(rc(rows.core)>=bands(k,1)&rc(rows.core)<bands(k,2));
 hr(k,:)=[numel(s),median(h(s)),median(h(s)./max(rc(s),eps))];
end
V=struct('pass',all(v),'gates',g,'failedGates',{fn(~v)},'gatesPassed',nnz(v),'gatesTotal',numel(v), ...
 'summary',struct('T3',size(T3,1),'T3nodes',size(X3,1),'T6nodes',size(X6,1),'DOF',2*size(X6,1), ...
 'coreT3',nCore,'collarT3',numel(rows.collar),'exteriorT3',numel(rows.exterior), ...
 'tipFirstEdgeRadial_mm',min(fe(isRad)),'tipFanEdges_mm',fe(:).','firstPitchSpec_mm',M.a1.firstPitch_mm, ...
 'diskRadius_mm',M.a1.diskRadius_mm,'minAngle_deg',min(ang(:)),'maxNeighborRatio',max(ratio), ...
 'minShapeQualityCore',min(Q(rows.core)),'minAngleDisk_deg',min(min(ang(dc,:))),'minShapeQualityDisk',min(Q(dc)), ...
 'qActivePrimary',numel(act),'qActivePerAnnulus',qa(:).','qAnnuli_mm',an,'qSupportMaxRadius_mm',max(r6(unique(T6(act,:)))), ...
 'radialBands_mm',bands,'bandCellsMedianHMedianHoverR',hr,'bankT6NodesPerSide',numel(U)));
end

function d=polydist(X,P)
M=size(X,1);nk=size(P,1)-1;Dd=inf(M,nk);
for j=1:nk
 v=P(j+1,:)-P(j,:);l=max(0,min(1,((X-P(j,:))*v.')/(v*v.')));Dd(:,j)=vecnorm(X-(P(j,:)+l*v),2,2);
end
d=min(Dd,[],2);
end
