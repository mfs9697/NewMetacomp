function M=g2_a1_patch_swap(D,spec)
%G2_A1_PATCH_SWAP  A1 (Issue #66): Family B near-tip patch swapped into a saved A0 S4 mesh.
%
%  M = g2_a1_patch_swap(D,spec)   D: saved A0 S4 MESH struct (unchanged); spec.family 'BASE'|'B'
% Method transferred from EdgeCrackHoleLEFM edge_prh_patch_swap_mesh (PR-H): the saved
% 128-T3 collar and the exterior touch the 2,788-T3 p010 kernel only through its 64 rim
% nodes and one lower-bank entry, so the kernel can be replaced without generateMesh.
% Steps: (1) rebuild the kernel+collar of D.crackPolyline with the unchanged
% g2_kinked_regular_block and require it to equal D's rows/nodes bit for bit; (2) build the
% Family B patch from that block's own vendor ring (g2_a1_family_b_patch); (3) keep the
% saved rim coordinates, renumber collar/exterior, rebuild T6 with the vendor T3toT6_fast;
% (4) recompute banks, kink identities and FE-nodal q exactly as g2_kinked_join does.
% Node order [patch; 65 collar outer; exterior]; cell order [patch; 128 collar; exterior].
% Geometry only: no PDE mesh generation, loads, stiffness, solve, COD, EDI or SIF.
need={'X3','T3','X6','T6','upperBankT6','lowerBankT6','physicalTipNode','nodalQ','qActiveT6Rows', ...
 'elementRows','collarOuterIDs','extraVertexXY','extraVertexNodes','crackPolyline','tipTangent','tipNormal','kinkNodeIDs'};
assert(isstruct(D)&&all(isfield(D,need)),'G2A1:BaselineSchema','Saved S4 mesh lacks required fields.');
P=D.crackPolyline;
B=g2_kinked_regular_block(P,'ExpectedTangent',D.tipTangent,'ExpectedVertices',size(P,1),'TipGuideRadius_mm',15);
assert(B.pass,'G2A1:BaselineBlock','Rebuilt p010 block failed: %s',B.stage);
nB=size(B.coord3,1);nU=B.kernelNodes;
assert(nB==nU+65&&size(B.connect3,1)==2916&&isequal(D.T3(1:2916,:),B.connect3)&&isequal(D.X3(1:nB,:),B.coord3)&& ...
 isequal(D.collarOuterIDs(:),B.collarOuterIDs(:)),'G2A1:BaselineIdentity', ...
 'Rebuilt kernel and collar differ from the saved A0 S4 mesh.');
L=B.sourceP010;
Pn=g2_a1_family_b_patch(spec,L);
Xp=1000*Pn.coord3;
Xu=B.coord3(1:nU,:);
ringOld=L.sourcePatch.originalAnnulus.rings{end}(:);
dn=L.sourcePatch.lowerFaceNodes(:);
F=g2_polyline_frame(P);tip=F.tip;t=F.t;
[~,kD]=min(vecnorm(Xu(dn,:)-(tip-3*t),2,2));lowerOld=dn(kD);
rimOld=[ringOld;lowerOld];rimNew=[Pn.outerRing(:);Pn.lowerEntry];
rimShift=max(vecnorm(Xp(rimNew,:)-Xu(rimOld,:),2,2));
assert(numel(rimOld)==65&&numel(unique(rimNew))==65&&rimShift<1e-10,'G2A1:SwapRim', ...
 'New patch rim differs from the saved rim (%.3g mm).',rimShift);
Xp(rimNew,:)=Xu(rimOld,:);                 % saved rim coordinates kept bit for bit
rest=D.T3(2789:end,:);
lowIDs=unique(rest(rest<=nU));
assert(all(ismember(lowIDs,rimOld)),'G2A1:SwapTouch','Collar/exterior touch kernel nodes off the rim.');
map=zeros(nU,1);map(rimOld)=rimNew;
shift=size(Xp,1)-nU;
near=rest<=nU;rest(near)=map(rest(near));rest(~near)=rest(~near)+shift;
X3=[Xp;D.X3(nU+1:end,:)];T3=[Pn.connect3;rest];
nCore=size(Pn.connect3,1);nColl=128;nBlock=nCore+nColl;
rows=struct('core',(1:nCore)','collar',(nCore+1:nBlock)','exterior',(nBlock+1:size(T3,1))');
[X6,T6]=T3toT6_fast(X3,T3);
tipNode=Pn.tipNode;
% ---- banks, exactly as g2_kinked_join
raw=sort([T3(:,[1 2]);T3(:,[2 3]);T3(:,[3 1])],2);[edges,~,ic]=unique(raw,'rows');
cnt=accumarray(ic,1);own=repmat((1:size(T3,1))',3,1);lo=accumarray(ic,own,[],@min);
bnd=find(cnt==1);e1=X3(edges(bnd,1),:);e2=X3(edges(bnd,2),:);em=.5*(e1+e2);
[d1,~]=polydist(e1,P);[d2,~]=polydist(e2,P);[dm,km]=polydist(em,P);
onCrack=d1<1e-9&d2<1e-9&dm<1e-9;
cen=(X3(T3(lo(bnd),1),:)+X3(T3(lo(bnd),2),:)+X3(T3(lo(bnd),3),:))/3;
side=sum((cen-P(km,:)).*F.nn(km,:),2);
bU=bnd(onCrack&side>0);bL=bnd(onCrack&side<0);
upT3=unique(edges(bU,:));loT3=unique(edges(bL,:));
upT6=unique([upT3;midsides(T3,T6,edges(bU,:))]);loT6=unique([loT3;midsides(T3,T6,edges(bL,:))]);
upT6=sortStation(upT6,X6,P);loT6=sortStation(loT6,X6,P);
kinkIDs=zeros(size(P,1)-2,2);
for kp=2:size(P,1)-1
 ids=find(vecnorm(X3-P(kp,:),2,2)<1e-12);
 assert(numel(ids)==2,'G2A1:KinkIdentity','Kink vertex %d must be duplicated once.',kp);
 kinkIDs(kp-1,:)=ids(:).';
end
% ---- FE-nodal q, exactly as g2_kinked_join
r6=vecnorm(X6-tip,2,2);q=ones(size(r6));q(r6>=2.6)=0;tr=r6>.4&r6<2.6;q(tr)=(2.6-r6(tr))/2.2;
qActive=find(max(q(T6),[],2)-min(q(T6),[],2)>1e-14);
ev=D.extraVertexNodes(:);
assert(all(ev>nU),'G2A1:AnchorNodes','BVP anchor vertices must lie outside the kernel.');
M=struct('X3',X3,'T3',T3,'X6',X6,'T6',T6,'upperBankT6',upT6,'lowerBankT6',loT6,'physicalTipNode',tipNode, ...
 'nodalQ',q,'qActiveT6Rows',qActive,'elementRows',rows,'collarOuterIDs',(size(Xp,1)+(1:65))', ...
 'extraVertexXY',D.extraVertexXY,'extraVertexNodes',reshape(ev+shift,size(D.extraVertexNodes)), ...
 'includeHoles',true,'plateXRange',D.plateXRange,'crackPolyline',P,'tipTangent',D.tipTangent,'tipNormal',D.tipNormal, ...
 'kinkNodeIDs',reshape(kinkIDs.',[],1),'geometryOnly',true,'approvedForLEFM',false);
M.a1=struct('spec',spec,'patchT3',nCore,'patchNodes',size(Xp,1),'kernelNodesBaseline',nU,'nodeShift',shift, ...
 'rimCoordinateShift_mm',rimShift,'firstPitch_mm',1000*Pn.firstPitch_m,'diskRadius_mm',1000*Pn.diskRadius_m, ...
 'lambda',Pn.lambda,'diskCells',Pn.diskCells,'baselineKernelIdentity',true,'generateMeshCalled',false, ...
 'transfer','EdgeCrackHoleLEFM PR-H Family B (build_prh_near_tip_patch.m @ c69b234)');
end

function [d,k]=polydist(X,P)
M=size(X,1);nk=size(P,1)-1;Dd=inf(M,nk);
for j=1:nk
 v=P(j+1,:)-P(j,:);l=max(0,min(1,((X-P(j,:))*v.')/(v*v.')));Dd(:,j)=vecnorm(X-(P(j,:)+l*v),2,2);
end
[d,k]=min(Dd,[],2);
end

function ids=sortStation(ids,X,P)
F=g2_polyline_frame(P);nk=size(P,1)-1;M=numel(ids);Dd=inf(M,nk);S=zeros(M,nk);
for j=1:nk
 v=P(j+1,:)-P(j,:);l=max(0,min(1,((X(ids,:)-P(j,:))*v.')/(v*v.')));
 Dd(:,j)=vecnorm(X(ids,:)-(P(j,:)+l*v),2,2);S(:,j)=F.stations(j)+l*F.segmentLengths(j);
end
[~,k]=min(Dd,[],2);s=S(sub2ind([M,nk],(1:M)',k));[~,o]=sort(s);ids=ids(o);
end

function m=midsides(T3,T6,e)
K=[sort(T3(:,[1 2]),2);sort(T3(:,[2 3]),2);sort(T3(:,[3 1]),2)];Mm=[T6(:,4);T6(:,5);T6(:,6)];
[f,loc]=ismember(sort(e,2),K,'rows');assert(all(f),'G2A1:MissingEdge','Bank edge not in T3.');m=Mm(loc);
end
