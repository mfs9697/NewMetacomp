function C = g2_independent_t6_checker(data, geometryFile)
%G2_INDEPENDENT_T6_CHECKER Independent geometry/topology-only Cornell audit.
%
% IMPORTANT: This reads SAVED T3/T6 arrays, not PDE objects or the mesher.
% It is an independent 2D checker adapted in spirit from the trusted
% EdgeCrackHoleLEFM H0-H3 independent checker. NO source 2-hole anchors,
% p010 core, EDI q, material/loads or crack propagation are imported.
% Millimetres throughout. MATLAB R2023a. Does NOT change input arrays.
%
% C=g2_independent_t6_checker(load('GEOMETRY_ONLY_candidate.mat'),jsonPath);
%
% Candidate check PASS is NEVER an LEFM permit: original source's protected
% p010 tip patch/collar and experiment-specific physical BC are absent.
if nargin<2
 error('G2Independent:MissingGeometry', ...
     'Pass the original G2 nominal specimen JSON explicitly.');
end
required={'X3','T3','X6','T6','upperBankT6','lowerBankT6', ...
          'physicalTipNode','geometryOnly','approvedForLEFM'};
assert(isstruct(data)&&all(isfield(data,required)), ...
 'G2Independent:MissingData','Saved MAT file lacks required geometry-only fields.');
assert(isfile(geometryFile),'G2Independent:MissingJSON', ...
 'Pinned specimen JSON does not exist.');
J=jsondecode(fileread(geometryFile));
assert(strcmp(J.schema, ...
 'NewMetacomp.G2.IngraffeaGrigoriu1990.Specimen1.nominal.v1'), ...
 'G2Independent:WrongSource','Unexpected source JSON schema.');
G=J.nominal_geometry_mm;
X3=data.X3;T3=data.T3;X6=data.X6;T6=data.T6;
U=data.upperBankT6(:);L=data.lowerBankT6(:);
tipID=data.physicalTipNode;
n3=size(X3,1);n6=size(X6,1);ne=size(T6,1);
xmin=G.plate.x_range(1);xmax=G.plate.x_range(2);
ymin=G.plate.y_range(1);ymax=G.plate.y_range(2);
mouth=G.initial_crack.mouth(:).';
tip=G.initial_crack.tip(:).';
cx=tip(1);
holes=G.holes;nh=numel(holes);
centers=zeros(nh,2);radii=zeros(nh,1);
for k=1:nh
 centers(k,:)=holes(k).center(:).';
 radii(k)=holes(k).radius;
end
tol=1e-7; % mm topology/coordinate tolerance, far below Hmin=0.12 mm
g=struct();
g.originalThreeHoleSource=nh==3&&abs(cx-mouth(1))<tol&& ...
 abs(mouth(2)-ymin)<tol&&abs(tip(2)-25.4)<tol;
g.arraysHaveT3T6Shape=size(X3,2)==2&&size(T3,2)==3&& ...
 size(X6,2)==2&&size(T6,2)==6&& ...
 size(T3,1)==ne&&n6>=n3&&n3>0;
assert(g.arraysHaveT3T6Shape,'G2Independent:BadArrays', ...
 'Saved T3/T6 arrays have incompatible dimensions.');
g.allCoordinatesFinite=all(isfinite(X3(:)))&&all(isfinite(X6(:)));
g.indicesIntegralAndValid=all(T3(:)>=1)&&all(T3(:)<=n3)&& ...
 all(T6(:)>=1)&&all(T6(:)<=n6)&& ...
 all(T3(:)==round(T3(:)))&&all(T6(:)==round(T6(:)));
assert(g.indicesIntegralAndValid,'G2Independent:IndexRange', ...
 'Cannot audit arrays with invalid finite-element indices.');
cn=T6(:,1:3);mn=T6(:,4:6);
g.cornerArraysUnchanged=isequal(cn,T3)&& ...
 isequal(X6(1:n3,:),X3);
g.allT6NodesUsed=isequal(unique(T6(:)),(1:n6)');
g.sixDifferentNodeIDsPerT6=all( ...
 T6(:,1)~=T6(:,2)&T6(:,1)~=T6(:,3)& ...
 T6(:,2)~=T6(:,3)& ...
 T6(:,4)~=T6(:,5)&T6(:,4)~=T6(:,6)&T6(:,5)~=T6(:,6)) && ...
 all(all(~ismember(mn,unique(cn(:)))));
g.cornerAndMidsideNodeSetsDisjoint=isempty(intersect(cn(:),mn(:)));

% Rebuild ALL unique T3 edges and T6 midside owners independently.
raw=sort([cn(:,[1 2]);cn(:,[2 3]);cn(:,[3 1])],2);
midsRaw=[mn(:,1);mn(:,2);mn(:,3)];
owners=repmat((1:ne)',3,1);
[edges,~,ic]=unique(raw,'rows');
nUniqueEdges=size(edges,1);
nOwners=accumarray(ic,1,[nUniqueEdges,1]);
midLo=accumarray(ic,midsRaw,[],@min);
midHi=accumarray(ic,midsRaw,[],@max);
ownLo=accumarray(ic,owners,[],@min);
ownHi=accumarray(ic,owners,[],@max);
g.noNonmanifoldT3Edges=all(nOwners>=1&nOwners<=2);
g.uniqueMatchingT6EdgeMidsides=all(midLo==midHi)&& ...
 numel(unique(midLo))==nUniqueEdges;
g.T6CountEqualsCornersPlusEdges=n6==n3+nUniqueEdges;
g.allMidsidesAreGeometricMidpoints= ...
 max(vecnorm(X6(midLo,:)- ...
 .5*(X6(edges(:,1),:)+X6(edges(:,2),:)),2,2))<1e-10;

% Independent 13-position quadratic T6 Jacobians. The first audit
% mistakenly indexed x=X6(T6,1): it did not guarantee an M-by-6
% matrix. Shape-safe gathering is covered by an explicit synthetic test.
a=X6(cn(:,2),:)-X6(cn(:,1),:);
b=X6(cn(:,3),:)-X6(cn(:,1),:);
a2=a(:,1).*b(:,2)-a(:,2).*b(:,1);
J6=g2_independent_t6_jacobian(X6,T6);
detMin=J6.minDet_mm2;
detErr=J6.maxRelativeVariation;
g.everyT3AreaAndT6JacobianPositive=J6.allPositive;
g.straightT6JacobianConstantTo1e8=J6.constantTo1e8;

% Independent T3 element corner-angle and adjacent size gate.
L12=vecnorm(X6(cn(:,2),:)-X6(cn(:,1),:),2,2);
L23=vecnorm(X6(cn(:,3),:)-X6(cn(:,2),:),2,2);
L31=vecnorm(X6(cn(:,1),:)-X6(cn(:,3),:),2,2);
cl=@(z)max(-1,min(1,z));
ang=[acosd(cl((L12.^2+L31.^2-L23.^2)./(2*L12.*L31))), ...
     acosd(cl((L12.^2+L23.^2-L31.^2)./(2*L12.*L23))), ...
     acosd(cl((L23.^2+L31.^2-L12.^2)./(2*L23.*L31)))];
minAng=min(ang(:));
h=max([L12,L23,L31],[],2);
interior=nOwners==2;
ratio=max(h(ownLo(interior))./h(ownHi(interior)), ...
          h(ownHi(interior))./h(ownLo(interior)));
maxRatio=max(ratio);
g.minimumT3AngleAtLeast20Deg=minAng>=20;
g.adjacentLongestEdgeRatioAtMost1p8=maxRatio<=1.8;

% Reconstruct all boundary T6 edges and classify them using ONLY physical
% plate/crack/three-hole geometry, not native PDE CAD labels or face IDs.
bIdx=find(nOwners==1);be=edges(bIdx,:);bm=midLo(bIdx);
p1=X6(be(:,1),:);p2=X6(be(:,2),:);pm=X6(bm,:);
onPlate=@(p)[abs(p(:,1)-xmin)<tol,abs(p(:,1)-xmax)<tol, ...
             abs(p(:,2)-ymin)<tol,abs(p(:,2)-ymax)<tol];
plateE=any(onPlate(p1)&onPlate(p2)&onPlate(pm),2);
holeE=false(numel(bIdx),nh);
for k=1:nh
 d1=abs(vecnorm(p1-centers(k,:),2,2)-radii(k));
 d2=abs(vecnorm(p2-centers(k,:),2,2)-radii(k));
 holeE(:,k)=d1<1e-5&d2<1e-5; % T3 endpoints on exact CAD circle
end
crackCoord=@(p)abs(p(:,1)-cx)<tol & ...
    p(:,2)>=ymin-tol & p(:,2)<=tip(2)+tol;
crackE=crackCoord(p1)&crackCoord(p2)&crackCoord(pm);
classCount=double(plateE)+double(crackE)+sum(double(holeE),2);
g.everyBoundaryEdgeExactlyOnePhysicalClass=all(classCount==1);
g.everyHoleHasTwelveOrMoreBoundaryChords= ...
    all(sum(holeE,1)>=12);

% Boundary loops: outer(+opened crack), and three pure, disjoint holes.
boundaryNodeIDs=unique(be(:));
[~,bmap]=ismember(be,boundaryNodeIDs);
comp=conncomp(graph(bmap(:,1),bmap(:,2),[],numel(boundaryNodeIDs)));
edgeComps=comp(bmap(:,1));
g.fourPhysicalBoundaryComponents=max(comp)==4;
holeComps=zeros(nh,1);pure=true;
for k=1:nh
 ids=unique(edgeComps(holeE(:,k)));
 if numel(ids)~=1
     pure=false;
 else
     holeComps(k)=ids;
     pure=pure && nnz(edgeComps==ids)==nnz(holeE(:,k));
 end
end
g.threeSeparatePureHoleComponents=pure&& ...
 nh==3&&numel(unique(holeComps))==3&&all(holeComps>0);

plateLen=sum(vecnorm(p1(plateE,:)-p2(plateE,:),2,2));
crackLen=sum(vecnorm(p1(crackE,:)-p2(crackE,:),2,2));
expectedPerimeter=2*((xmax-xmin)+(ymax-ymin));
expectedCrackLen=2*norm(tip-mouth);
g.outerPlatePerimeter=abs(plateLen-expectedPerimeter)<1e-5;
g.doubleCrackBoundaryLength= ...
    abs(crackLen-expectedCrackLen)<1e-5;
if any(crackE)
 g.physicalCrackMouthAndTipCoordinates= ...
    abs(min([p1(crackE,2);p2(crackE,2)])-ymin)<tol&& ...
    abs(max([p1(crackE,2);p2(crackE,2)])-tip(2))<tol;
else
 g.physicalCrackMouthAndTipCoordinates=false;
end

% Element area vs analytically exact rectangle less three true circles.
% T3 boundary has *chords*, not curved isoparametric T6 arcs, so a small
% and explicit 0.5% relative tolerance is needed for analytic comparison.
materialArea=sum(a2)*.5;
analyticArea=(xmax-xmin)*(ymax-ymin)-pi*sum(radii.^2);
g.materialAreaMatchesAnalyticThreeHoleSolid= ...
    abs(materialArea/analyticArea-1)<.005;

% Connected material triangulation, including the internal guide contours.
dual=conncomp(graph(ownLo(interior),ownHi(interior),[],ne));
g.singleConnectedTriangulatedMaterial=max(dual)==1;
g.eulerCharacteristicEqualsMinusTwo= ...
    n3-nUniqueEdges+ne==-2;
g.edgeCountsConsistentWithReportedInterior= ...
    nUniqueEdges-nnz(nOwners==1)==nnz(interior);

% Authoritative saved arrays label the two separate banks and ONE tip.
g.bankIDsHaveValidNonemptySets=all(U>=1&U<=n6)&& ...
    all(L>=1&L<=n6)&&numel(U)>3&&numel(L)>3&& ...
    numel(unique(U))==numel(U)&&numel(unique(L))==numel(L);
g.bankSameNumberOfT6Nodes=numel(U)==numel(L);
common=intersect(U,L);
g.bankIDsShareExactlyDeclaredTip=isscalar(common)&& ...
    isequal(common,tipID);
tipSpatialIDs=find(vecnorm(X6-tip,2,2)<tol);
g.onePhysicalTipNodeAtSourceCoordinate= ...
    isscalar(tipSpatialIDs)&&isequal(tipSpatialIDs,tipID)&& ...
    tipID>=1&&tipID<=n3;
if g.bankSameNumberOfT6Nodes && g.bankIDsHaveValidNonemptySets
    [~,jU]=sort(X6(U,2));[~,jL]=sort(X6(L,2));
    uSorted=U(jU);lSorted=L(jL);
    dPair=vecnorm(X6(uSorted,:)-X6(lSorted,:),2,2);
    g.bankCoordinatesCoincideWithDistinctIDs= ...
        max(dPair)<tol && ...
        all(uSorted(1:end-1)~=lSorted(1:end-1)) && ...
        uSorted(end)==tipID && lSorted(end)==tipID;
    g.bankReachesCrackMouthAndTip= ...
        abs(X6(uSorted(1),2)-ymin)<tol && ...
        abs(X6(lSorted(1),2)-ymin)<tol && ...
        abs(X6(uSorted(end),2)-tip(2))<tol && ...
        abs(X6(lSorted(end),2)-tip(2))<tol;
else
    g.bankCoordinatesCoincideWithDistinctIDs=false;
    g.bankReachesCrackMouthAndTip=false;
end
crackBoundaryT6=unique([be(crackE,1);be(crackE,2);bm(crackE)]);
g.savedBanksExactlyCoverCrackBoundaryT6Nodes= ...
    isequal(union(U,L),crackBoundaryT6);
% One real crack boundary edge on each side for every geometric segment.
coordsY=sort([p1(crackE,2),p2(crackE,2)],2);
[~,~,edgeGeomGroup]=unique(round(coordsY/tol),'rows');
g.everyGeometricCrackEdgeHasTwoTopologicalTwins= ...
    any(crackE)&&all(accumarray(edgeGeomGroup,1)==2);

% Coincident T6 node pairs are permitted ONLY on the crack, not on the
% hole boundaries or internal guide circles.
[~,~,sameCoordinateGroup]=unique(round(X6/tol),'rows');
multiplicity=accumarray(sameCoordinateGroup,1);
duplicates=find(multiplicity(sameCoordinateGroup)>1);
dupOnCrack=all(crackCoord(X6(duplicates,:)));
g.noUnexpectedCoincidentNodeMultiplicities=all(multiplicity<=2);
g.allCoincidentDistinctNodesAreCrackBankTwins= ...
    dupOnCrack && ...
    isequal(sort(duplicates),sort(setdiff(union(U,L),tipID)));

% No LEFM permit even if all separate geometric gates pass.
g.noPhysicsOrLEFMApprovalInSource= ...
    logical(data.geometryOnly)&&~logical(data.approvedForLEFM);

v=cell2mat(struct2cell(g));
failed=fieldnames(g);
failed=failed(~v);
C=struct('pass',all(v),'stage','HOLD_INDEPENDENT_T6', ...
 'geometryOnly',true,'approvedForLEFM',false, ...
 'p010TipCoreQualified',false, ...
 'gates',g,'gatesPassed',nnz(v),'gatesTotal',numel(v), ...
 'failedGates',{failed}, ...
 'summary',struct('sourceJSON',geometryFile, ...
 'T3nodes',n3,'T3elements',ne,'T6nodes',n6, ...
 'uniqueEdges',nUniqueEdges,'interiorEdges',nnz(interior), ...
 'boundaryEdges',numel(bIdx),'EulerCharacteristic', ...
 n3-nUniqueEdges+ne,'boundaryComponents',max(comp), ...
 'holeBoundaryEdges',sum(holeE,1), ...
 'crackBoundaryEdges',nnz(crackE), ...
 'bankNodesPerSide',[numel(U),numel(L)], ...
 'tipNodeID',tipID,'minCornerAngle_deg',minAng, ...
 'maxNeighborLongestEdgeRatio',maxRatio, ...
 'minJacobian_mm2',detMin,'maxJacobianRelativeVariation',detErr, ...
 'maxMidsideError_mm', ...
 max(vecnorm(X6(midLo,:)-.5*(X6(edges(:,1),:)+ ...
 X6(edges(:,2),:)),2,2)), ...
 'materialArea_mm2',materialArea, ...
 'analyticSolidArea_mm2',analyticArea));
if C.pass,C.stage='INDEPENDENT_T6_GEOMETRY_PASS';end
fprintf('G2_INDEPENDENT_T6_GATES=%d/%d\n',C.gatesPassed,C.gatesTotal);
fprintf('G2_INDEPENDENT_T6_PASS=%d\n',C.pass);
fprintf('G2_INDEPENDENT_T6_BOUNDARY_LOOPS=%d\n',C.summary.boundaryComponents);
fprintf('G2_INDEPENDENT_T6_EULER=%d\n',C.summary.EulerCharacteristic);
fprintf('G2_INDEPENDENT_T6_TIP=%d\n',C.summary.tipNodeID);
fprintf('G2_INDEPENDENT_T6_MAX_RATIO=%.8f\n',maxRatio);
fprintf('G2_INDEPENDENT_T6_MIN_ANGLE_DEG=%.8f\n',minAng);
if ~C.pass,fprintf(2,'G2_INDEPENDENT_T6_HOLD=%s\n',strjoin(failed,','));end
fprintf('G2_INDEPENDENT_T6_NO_LEFM=1\n');
end
