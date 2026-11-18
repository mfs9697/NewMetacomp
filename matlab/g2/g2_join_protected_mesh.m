function R = g2_join_protected_mesh(varargin)
%G2_JOIN_PROTECTED_MESH  Full protected Cornell #1 mesh: frozen p010 + collar + exterior.
%
% WP1 of Issue #20 (geometry only). Joins, conformingly and without any new
% node in the protected region:
%  (1) the frozen 2,788-T3 p010 kernel and 128-T3 analytic collar produced by
%      g2_p010_cornell_regular_block (unchanged; rows 1..2916 of T3 and their
%      nodes keep the block numbering), and
%  (2) the new exterior of g2_protected_exterior_mesh, whose 65 rim node
%      identities are REPLACED by the collar's 65 outer node identities:
%      P(j) -> outer(j) (j ~= 33), left native entry -> outer(33), right native
%      entry -> outer(65). The two crack banks therefore stay distinct along the
%      whole crack and meet only at the physical tip of the p010 kernel.
% Every global gate is recomputed on the joined T3/T6 arrays here; the separate
% independent checkers (38-gate g2_independent_t6_checker and
% g2_protected_tip_checker) re-audit the SAVED arrays afterwards.
% No PDE solve, no SIF, no crack growth. approvedForLEFM is always false.
ip=inputParser;
addParameter(ip,'ExteriorOptions',{},@iscell);
addParameter(ip,'MaxT3Elements',40000,@(v)isnumeric(v)&&isscalar(v)&&v>0);
parse(ip,varargin{:});o=ip.Results;
R=struct('pass',false,'stage','HOLD_NOT_STARTED','message','','geometryOnly',true, ...
    'approvedForLEFM',false,'p010GlobalProtectedMeshQualified',false,'gates',struct(), ...
    'failedGates',{{}},'summary',struct());
B=g2_p010_cornell_regular_block('Plot',false);
if ~B.pass
 R.stage='HOLD_P010_BLOCK';R.message=['p010 block HOLD: ',B.stage];return
end
E=g2_protected_exterior_mesh(o.ExteriorOptions{:});
R.exterior=rmfield(E,intersect(fieldnames(E),{'coord3','connect3'}));
if ~E.pass
 R.stage='HOLD_EXTERIOR';R.message=['exterior HOLD: ',E.stage,' ',E.message];return
end
XB=B.coord3;TB=B.connect3;nB=size(XB,1);
nU=size(B.sourceP010.coord3,1);          % frozen kernel nodes
outerIDs=(nU+(1:65))';                    % collar outer nodes (block numbering)
assert(nB==nU+65&&size(TB,1)==2916,'G2Join:BlockLayout','Unexpected p010 block layout.');
XE=E.coord3;TE=E.connect3;nE=size(XE,1);
% exterior -> joined node map
map=zeros(nE,1);
rimExt=[E.rimNodeAtP([1:32,34:64]);E.rimEntryLeft;E.rimEntryRight];
rimBlk=[outerIDs([1:32,34:64]);outerIDs(33);outerIDs(65)];
map(rimExt)=rimBlk;
others=setdiff((1:nE)',rimExt);
map(others)=nB+(1:numel(others))';
coordDiff=max(vecnorm(XE(rimExt,:)-XB(rimBlk,:),2,2));
X3=[XB;XE(others,:)];
T3=[TB;map(TE)];
nCore=2788;nColl=128;nBlock=nCore+nColl;
rows=struct('core',(1:nCore)','collar',(nCore+1:nBlock)','exterior',(nBlock+1:size(T3,1))');
[X6,T6]=T3toT6_fast(X3,T3);
tip=B.summary.tip_mm;tipNode=B.tipNode;
% ---- recomputed global quality
a=X3(T3(:,2),:)-X3(T3(:,1),:);b=X3(T3(:,3),:)-X3(T3(:,1),:);
a2=a(:,1).*b(:,2)-a(:,2).*b(:,1);
L12=vecnorm(a,2,2);L31=vecnorm(b,2,2);L23=vecnorm(X3(T3(:,3),:)-X3(T3(:,2),:),2,2);
cl=@(z)max(-1,min(1,z));
ang=[acosd(cl((L12.^2+L31.^2-L23.^2)./(2*L12.*L31))),acosd(cl((L12.^2+L23.^2-L31.^2)./(2*L12.*L23))), ...
     acosd(cl((L23.^2+L31.^2-L12.^2)./(2*L23.*L31)))];
h=max([L12,L23,L31],[],2);
raw=sort([T3(:,[1 2]);T3(:,[2 3]);T3(:,[3 1])],2);
[edges,~,ic]=unique(raw,'rows');
cnt=accumarray(ic,1);
own=repmat((1:size(T3,1))',3,1);
lo=accumarray(ic,own,[],@min);hi=accumarray(ic,own,[],@max);
in=cnt==2;
ratio=max(h(lo(in))./h(hi(in)),h(hi(in))./h(lo(in)));
% seam bookkeeping: r = 3.3 edges must have one collar and one exterior owner
r3=vecnorm(X3-tip,2,2);
onRim=all(abs(r3(edges)-3.3)<1e-9,2);
rimEdge=find(onRim);
rimTwoOwner=numel(rimEdge)==64&&all(cnt(rimEdge)==2)&& ...
    all(ismember(lo(rimEdge),rows.collar))&&all(ismember(hi(rimEdge),rows.exterior));
onCore=all(abs(r3(edges)-3.0)<1e-9,2);
coreEdge=find(onCore);
coreTwoOwner=numel(coreEdge)==64&&all(cnt(coreEdge)==2)&& ...
    all(ismember(lo(coreEdge),rows.core))&&all(ismember(hi(coreEdge),rows.collar));
% crack banks from boundary edges on x = cx (owner side by centroid)
cx=tip(1);ymin=0;
e1=X3(edges(:,1),:);e2=X3(edges(:,2),:);
onCrack=cnt==1&abs(e1(:,1)-cx)<1e-9&abs(e2(:,1)-cx)<1e-9&min(e1(:,2),e2(:,2))>=ymin-1e-9& ...
    max(e1(:,2),e2(:,2))<=tip(2)+1e-9;
cen=(X3(T3(lo,1),1)+X3(T3(lo,2),1)+X3(T3(lo,3),1))/3;
bL=find(onCrack&cen<cx);bR=find(onCrack&cen>cx);
leftT3=unique(edges(bL,:));rightT3=unique(edges(bR,:));
[~,iL]=sort(X3(leftT3,2));leftT3=leftT3(iL);
[~,iR]=sort(X3(rightT3,2));rightT3=rightT3(iR);
% T6 bank sets: corner nodes plus the midside nodes of the bank edges
midOf=@(ids)T6midsides(T3,T6,edges(ids,:));
leftT6=unique([leftT3;midOf(bL)]);rightT6=unique([rightT3;midOf(bR)]);
[~,jL]=sort(X6(leftT6,2));leftT6=leftT6(jL);
[~,jR]=sort(X6(rightT6,2));rightT6=rightT6(jR);
banksOK=numel(bL)==numel(bR)&&numel(bL)>3&&isequal(intersect(leftT6,rightT6),tipNode)&& ...
    ismember(outerIDs(33),leftT3)&&ismember(outerIDs(65),rightT3)&& ...
    leftT3(end)==tipNode&&rightT3(end)==tipNode&& ...
    abs(X3(leftT3(1),2)-ymin)<1e-9&&abs(X3(rightT3(1),2)-ymin)<1e-9;
% FE-nodal q (original source definition, r in mm, 0.4 .. 2.6)
r6=vecnorm(X6-tip,2,2);
q=ones(size(r6));q(r6>=2.6)=0;tr=r6>.4&r6<2.6;q(tr)=(2.6-r6(tr))/2.2;
qActive=find(max(q(T6),[],2)-min(q(T6),[],2)>1e-14);
qInside=all(ismember(qActive,rows.core))&&numel(qActive)==2443&& ...
    max(r6(unique(T6(qActive,:))))<3*cos(pi/64);
g=struct( ...
 'p010BlockPass',B.pass, ...
 'exteriorRimCavityPass',E.pass, ...
 'rimCoordinatesCoincide',coordDiff<1e-12, ...
 'blockRowsAndNodesUnchanged',isequal(T3(1:nBlock,:),TB)&&isequal(X3(1:nB,:),XB), ...
 'allT3AreasPositive',all(a2>0), ...
 'globalMinAngleAtLeast20',min(ang(:))>=20, ...
 'globalNeighborRatioAtMost1p8',max(ratio)<=1.8, ...
 'noNonmanifoldEdges',all(cnt<=2), ...
 'coreCollarSeam64TwoOwners',coreTwoOwner, ...
 'collarExteriorSeam64TwoOwners',rimTwoOwner, ...
 'distinctBanksMeetOnlyAtTip',banksOK, ...
 'qSupport2443InsideCore',qInside, ...
 'T3BudgetRespected',size(T3,1)<=o.MaxT3Elements);
v=cell2mat(struct2cell(g));
R.gates=g;R.failedGates=fieldnames(g);R.failedGates=R.failedGates(~v);
R.summary=struct('T3elements',size(T3,1),'T3nodes',size(X3,1),'T6nodes',size(X6,1), ...
 'coreT3',nCore,'collarT3',nColl,'exteriorT3',numel(rows.exterior), ...
 'minAngle_deg',min(ang(:)),'maxNeighborRatio',max(ratio), ...
 'rimSeamEdges',numel(rimEdge),'coreSeamEdges',numel(coreEdge), ...
 'rimSeamMaxRatio',max(max(h(lo(rimEdge))./h(hi(rimEdge)),h(hi(rimEdge))./h(lo(rimEdge)))), ...
 'crackBankEdgesPerSide',[numel(bL),numel(bR)],'bankT6NodesPerSide',[numel(leftT6),numel(rightT6)], ...
 'qActiveT6',numel(qActive),'tip_mm',tip,'tipNode',tipNode, ...
 'rimCoordinateMismatch_mm',coordDiff,'exterior',E.summary);
fprintf('G2_JOIN_GATES=%d/%d\n',nnz(v),numel(v));
fprintf('G2_JOIN_T3=%d T6_NODES=%d MIN_ANGLE=%.6f MAX_RATIO=%.6f\n',size(T3,1),size(X6,1),min(ang(:)),max(ratio));
R.pass=all(v);
if R.pass
 R.stage='FULL_PROTECTED_MESH_JOIN_PASS';
 R.message='Joined; still requires the independent 38-gate and protected-tip audits.';
else
 R.stage='HOLD_FULL_PROTECTED_MESH_JOIN';R.message=strjoin(R.failedGates,', ');
end
R.X3=X3;R.T3=T3;R.X6=X6;R.T6=T6;
R.upperBankT6=leftT6;R.lowerBankT6=rightT6;   % convention as the candidate: upper = left of the upward slit
R.physicalTipNode=tipNode;R.nodalQ=q;R.qActiveT6Rows=qActive;
R.elementRows=rows;R.collarOuterIDs=outerIDs;
R.p010BlockSummary=B.summary;R.p010BlockGates=B.gates;
R.extraVertexXY=E.extraVertexXY;R.extraVertexNodes=map(E.extraVertexNodes);R.includeHoles=E.includeHoles;R.plateXRange=E.plateXRange;
end

function m=T6midsides(T3,T6,e)
% midside node of each listed T3 edge, from the T6 table ([v1 v2 v3 m12 m23 m31])
k12=sort(T3(:,[1 2]),2);k23=sort(T3(:,[2 3]),2);k31=sort(T3(:,[3 1]),2);
K=[k12;k23;k31];M=[T6(:,4);T6(:,5);T6(:,6)];
[f,loc]=ismember(sort(e,2),K,'rows');
assert(all(f),'G2Join:MissingEdge','Bank edge not found in T3.');
m=M(loc);
end
