function R = g2_specimen1_pencil_mesh(varargin)
%G2_SPECIMEN1_PENCIL_MESH  Three-hole specimen: geometry-only pencil collapse.
%
% This is a GATED adaptation of the pencil-channel/collapse strategy in
% mfs9697/EdgeCrackHoleLEFM (H0-H3), NOT a claimed bitwise port of the
% source's protected p010 core. Unlike the verified H0-H3 method, this
% first transfer has no p010 tip patch/collar and MUST NOT be used to
% calculate KI, KII, G or to propagate a crack.
%
%  R = g2_specimen1_pencil_mesh('Plot',false);
%
% Output always starts as HOLD and becomes 'CANDIDATE_TOPOLOGY_PASS' only
% after independent bank/tip/area/T3/T6 geometric gates. Even with pass=true,
% R.approvedForLEFM remains false. No stiffness, BVP or solve is performed.
% Uses exact native PDE CAD circles via decsg; T3/T6 is straight-sided.
%
% Requires MATLAB R2023a and PDE Toolbox. Length unit is MILLIMETRES.
ip = inputParser;
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
source = fullfile(root,'docs','research','crack-growth-gaps-2026', ...
    'G2_SPECIMEN1_1990_GEOMETRY.json');
addParameter(ip,'JsonPath',source,@(s)ischar(s)||isstring(s));
addParameter(ip,'ChannelHalfWidth_mm',.020,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'TipShoulder_mm',.30,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'Hmin_mm',.12,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'Hmax_mm',7,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'Hgrad',1.12,@(v)isnumeric(v)&&isscalar(v)&&v>=1&&v<=1.3);
addParameter(ip,'Hedge_mm',.45,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'PairStationTolerance_mm',.15,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'MaxT3Elements',40000,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'Plot',false,@(v)islogical(v)&&isscalar(v));
parse(ip,varargin{:});o=ip.Results;

R=struct('pass',false,'stage','HOLD_NOT_STARTED','gates',struct(), ...
    'summary',struct(),'message','','approvedForLEFM',false, ...
    'p010TipCoreQualified',false,'geometryOnly',true, ...
    'physicalSolvePerformed',false,'bankPairing',struct());
assert(exist('createpde','file')==2&&exist('decsg','file')==2&& ...
       exist('generateMesh','file')==2,'G2:PDEToolboxMissing');
assert(isfile(char(o.JsonPath)),'G2:JSONMissing');
J=jsondecode(fileread(char(o.JsonPath)));
assert(strcmp(J.schema, ...
 'NewMetacomp.G2.IngraffeaGrigoriu1990.Specimen1.nominal.v1'), ...
 'G2:WrongSource');
G=J.nominal_geometry_mm;
assert(numel(G.holes)==3,'G2:RequireThreeHoles');
w=o.ChannelHalfWidth_mm;
assert(o.Hmin_mm<=o.Hedge_mm&&o.Hedge_mm<=o.Hmax_mm, ...
 'G2:MeshControls');
assert(w<.1*o.TipShoulder_mm, ...
 'G2:TooWideForShoulder');

xmin=G.plate.x_range(1);xmax=G.plate.x_range(2);
ymin=G.plate.y_range(1);ymax=G.plate.y_range(2);
mouth=G.initial_crack.mouth(:).';
tip=G.initial_crack.tip(:).';
assert(abs(mouth(2)-ymin)<1e-10&&abs(tip(1)-mouth(1))<1e-10, ...
 'G2:VerticalBottomEdgeCrackRequired');
cx=mouth(1);yt=tip(2);yshoulder=yt-o.TipShoulder_mm;
assert(yshoulder>0,'G2:ShoulderPastMouth');
assert(cx-w>xmin&&cx+w<xmax,'G2:ChannelPastSide');
holeX=zeros(3,1);holeY=holeX;radius=holeX;
for k=1:3
 holeX(k)=G.holes(k).center(1);
 holeY(k)=G.holes(k).center(2);
 radius(k)=G.holes(k).radius;
 assert(holeX(k)-radius(k)>xmin&&holeX(k)+radius(k)<xmax ...
  &&holeY(k)-radius(k)>ymin&&holeY(k)+radius(k)<ymax, ...
  'G2:HoleOutsidePlate');
 assert(norm([holeX(k)-cx,holeY(k)-yt])-radius(k)>3.3, ...
  'G2:HoleTooCloseToTipCore');
end
for k=1:3
 for j=1:k-1
  assert(norm([holeX(k)-holeX(j),holeY(k)-holeY(j)])> ...
   radius(k)+radius(j),'G2:OverlappingCircles');
 end
end

% The channel is cut INTO the outer polygon from the bottom boundary.
% Left and right slopes meet at ONE real apex/tip in the native CAD.
% A protected p010 core is NOT yet grafted at this tip: conservative HOLD.
outer=[cx+w,ymin;xmax,ymin;xmax,ymax;xmin,ymax; ...
 xmin,ymin;cx-w,ymin;cx-w,yshoulder;cx,yt;cx+w,yshoulder];
Np=size(outer,1);
cols=cell(4,1);
cols{1}=[2;Np;outer(:,1);outer(:,2)];
for k=1:3,cols{k+1}=[1;holeX(k);holeY(k);radius(k)];end
gd=zeros(max(cellfun(@numel,cols)),4);
for k=1:4,gd(1:numel(cols{k}),k)=cols{k};end
ns=char('MAT','C1','C2','C3').';
[dl,~]=decsg(gd,'MAT-C1-C2-C3',ns);
model=createpde(1);
geometryFromEdges(model,dl);
geom=model.Geometry;

% Explicitly select left/right CAD lips including the tapered shoulder.
lseg=[cx-w,(ymin+yshoulder)/2; ...
      cx-w/2,(yshoulder+yt)/2];
rseg=[cx+w,(ymin+yshoulder)/2; ...
      cx+w/2,(yshoulder+yt)/2];
leftCAD=unique(nearestEdge(geom,lseg));
rightCAD=unique(nearestEdge(geom,rseg));
if ~isempty(intersect(leftCAD,rightCAD))
 R.stage='HOLD_LIP_CAD';
 R.message='Left/right channel lips map to the same CAD edge.';
 return
end
holeCAD=cell(3,1);
for k=1:3
 phi=(0:47)'*2*pi/48;
 sample=[holeX(k)+radius(k)*cos(phi), ...
         holeY(k)+radius(k)*sin(phi)];
 holeCAD{k}=unique(nearestEdge(geom,sample));
end
if any(cellfun(@isempty,holeCAD))
 R.stage='HOLD_HOLE_EDGE_LABELS';return
end
% Do not allow lip edges to be reinterpreted as edges of circles.
if any(cellfun(@(h)any(ismember(h,[leftCAD(:);rightCAD(:)])),holeCAD))
 R.stage='HOLD_CAD_EDGE_OVERLAP';return
end
hedge={leftCAD(:)',o.Hedge_mm,rightCAD(:)',o.Hedge_mm};
for k=1:3
 hedge=[hedge,{holeCAD{k}(:)', ...
    .70*2*radius(k)*sin(pi/120)}]; %#ok<AGROW>
end
ticMesh=tic;
m=generateMesh(model,'GeometricOrder','linear', ...
 'Hmin',o.Hmin_mm,'Hmax',o.Hmax_mm,'Hgrad',o.Hgrad, ...
 'Hedge',hedge);
dt=toc(ticMesh);
X0=m.Nodes.';T=m.Elements.';
R.summary.nativeT3Count=size(T,1);
R.summary.nativeNodeCount=size(X0,1);
R.summary.nativeMeshingSeconds=dt;
R.summary.channelHalfWidth_mm=w;
R.summary.channelApex_mm=tip;
R.summary.sourceJSON=char(o.JsonPath);
R.summary.sourceMethod='EdgeCrackHoleLEFM H0-H3 pencil collapse; isolated Cornell three-hole adaptation';
% A diagnostic figure exists even when the subsequent collapse is held.
% This allows review of the native 3-circle mesh and finite pencil lips.
if o.Plot
 nativeFig=figure('Visible','off','Color','w', ...
    'Name','Cornell #1 native pencil-channel pre-collapse mesh');
 triplot(T,X0(:,1),X0(:,2),'Color',[.60 .72 .80]);hold on;
 plot(outer([1:end 1],1),outer([1:end 1],2), ...
    'r-','LineWidth',1.2);
 axis equal;grid on;
 xlabel('x (mm)');ylabel('y (mm)');
 title('Native pencil channel before collapse — geometry only');
 R.figure=nativeFig;
end
if size(T,1)>o.MaxT3Elements
 R.stage='HOLD_WORK_BUDGET';
 R.message=sprintf('Native T3 count %d > cap %d.',size(T,1),o.MaxT3Elements);
 return
end

ln=unique(findNodes(m,'region','Edge',leftCAD));
rn=unique(findNodes(m,'region','Edge',rightCAD));
tipIDs=find(vecnorm(X0-tip,2,2)<1e-8);
if numel(tipIDs)~=1
 R.stage='HOLD_NATIVE_TIP';
 R.message='Need precisely one native CAD tip vertex.';
 return
end
tipID=tipIDs(1);
if ~ismember(tipID,ln)||~ismember(tipID,rn)
 R.stage='HOLD_TIP_NOT_ON_BOTH_LIPS';
 return
end
ln(ln==tipID)=[];rn(rn==tipID)=[];
[ysL,ixL]=sort(X0(ln,2));ln=ln(ixL);
[ysR,ixR]=sort(X0(rn,2));rn=rn(ixR);
if numel(ln)~=numel(rn)||numel(ln)<3
 R.stage='HOLD_UNMATCHED_LIP_COUNTS';
 R.message=sprintf('Left lip=%d, right lip=%d; paired stations required.', ...
  numel(ln),numel(rn));
 return
end
mismatch=max(abs(ysL-ysR));
R.summary.preCollapseMaxStationMismatch_mm=mismatch;
R.summary.preCollapseLipPairs=numel(ln);
if mismatch>o.PairStationTolerance_mm
 R.stage='HOLD_STATION_MISMATCH';
 R.message=sprintf('Max station mismatch %.4g mm > %.4g mm.', ...
  mismatch,o.PairStationTolerance_mm);
 return
end
if any(diff(ysL)<=1e-9)||any(diff(ysR)<=1e-9)
 R.stage='HOLD_NONMONOTONIC_BANK_STATIONS';return
end
X=X0;
% Collapse WITHOUT WELDING. Left/right NODE IDs remain distinct.
pairedY=.5*(ysL+ysR);
X(ln,1)=cx;X(rn,1)=cx;
X(ln,2)=pairedY;X(rn,2)=pairedY;
% Apex is the only topologically SHARED crack-bank node.
assert(norm(X(tipID,:)-tip)<1e-8,'G2:TipMoved');

% Native T3 orientation check. A failure is a HARD HOLD; do not flip
% element IDs post hoc or discard degenerate cells to manufacture success.
aa=X(T(:,2),:)-X(T(:,1),:);
bb=X(T(:,3),:)-X(T(:,1),:);
twiceArea=aa(:,1).*bb(:,2)-aa(:,2).*bb(:,1);
if any(~isfinite(twiceArea))||any(twiceArea<=0)
 R.stage='HOLD_COLLAPSED_T3_DEGENERATE';
 R.message=sprintf('%d T3 elements have nonpositive area.', ...
     nnz(twiceArea<=0));
 return
end
el12=vecnorm(X(T(:,2),:)-X(T(:,1),:),2,2);
el23=vecnorm(X(T(:,3),:)-X(T(:,2),:),2,2);
el31=vecnorm(X(T(:,1),:)-X(T(:,3),:),2,2);
hh=max([el12 el23 el31],[],2);
clip=@(z)max(-1,min(1,z));
ag1=acosd(clip((el12.^2+el31.^2-el23.^2)./(2*el12.*el31)));
ag2=acosd(clip((el12.^2+el23.^2-el31.^2)./(2*el12.*el23)));
ag3=acosd(clip((el23.^2+el31.^2-el12.^2)./(2*el23.*el31)));
minAng=min([ag1;ag2;ag3]);
edgesRaw=sort([T(:,[1 2]);T(:,[2 3]);T(:,[3 1])],2);
[E,~,ic]=unique(edgesRaw,'rows');
owner=accumarray(ic,repmat((1:size(T,1))',3,1),[],@min);
cnt=accumarray(ic,1);
edgeMax=accumarray(ic,repmat(hh,3,1),[],@max);
edgeMin=accumarray(ic,repmat(hh,3,1),[],@min);
rmax=max(edgeMax(cnt==2)./edgeMin(cnt==2));
R.summary.minimumAngle_deg=minAng;
R.summary.maxAdjacentLongestEdgeRatio=rmax;
if minAng<20||rmax>1.8
 R.stage='HOLD_T3_QUALITY';
 R.message=sprintf('Min angle %.4f deg, neighbor ratio %.4f.',minAng,rmax);
 return
end
if any(cnt>2)
 R.stage='HOLD_NONMANIFOLD_T3';return
end
% A single plate with a mouth-connected slit and three holes has
% precisely FOUR boundary loops: outer/slit + three distinct circles.
boundaryEdges=E(cnt==1,:);
[~,~,remap]=unique(boundaryEdges(:));
reb=reshape(remap,size(boundaryEdges));
parts=conncomp(graph(reb(:,1),reb(:,2)));
R.summary.boundaryComponents=max(parts);
if R.summary.boundaryComponents~=4
 R.stage='HOLD_BOUNDARY_COMPONENTS';
 R.message=sprintf('Expected four boundary components; found %d.', ...
    R.summary.boundaryComponents);
 return
end
% CAD circles remain circles in the native geometry. Linear T3 elements
% represent each circle by chords; do not mistake this for exact curved T6.
boundaryEndpoints1=X(boundaryEdges(:,1),:);
boundaryEndpoints2=X(boundaryEdges(:,2),:);
R.summary.circleBoundaryChordCounts=zeros(1,3);
for k=1:3
 c=[holeX(k),holeY(k)];
 r=radius(k);
 onCircle=abs(vecnorm(boundaryEndpoints1-c,2,2)-r)<1e-5 & ...
          abs(vecnorm(boundaryEndpoints2-c,2,2)-r)<1e-5;
 R.summary.circleBoundaryChordCounts(k)=nnz(onCircle);
end
if any(R.summary.circleBoundaryChordCounts<12)
 R.stage='HOLD_CIRCLE_BOUNDARY_FIDELITY';
 R.message='Each of the three true CAD circles requires at least 12 native boundary chords.';
 return
end

% Identify the real crack-bank boundary EDGES by connectivity (one owner)
% and geometry (both ends lie on vertical midline, y in [0,yt]).
e1=X(E(:,1),:);e2=X(E(:,2),:);
onCrack=cnt==1&abs(e1(:,1)-cx)<1e-8& ...
 abs(e2(:,1)-cx)<1e-8&min(e1(:,2),e2(:,2))>=ymin-1e-8& ...
 max(e1(:,2),e2(:,2))<=yt+1e-8;
% Use centroid X of triangles, NOT a hard-coded physical bank sign.
ce=(X(T(owner,1),1)+X(T(owner,2),1)+X(T(owner,3),1))/3;
bLeft=find(onCrack&ce<cx-1e-9);
bRight=find(onCrack&ce>cx+1e-9);
if numel(bLeft)==0||numel(bRight)==0|| ...
   numel(bLeft)~=numel(bRight)
 R.stage='HOLD_NO_TWO_CRACK_BANK_EDGE_CHAINS';
 R.message='Cannot classify two equal crack-face boundary chains.';
 return
end
leftBank=unique(E(bLeft,:));rightBank=unique(E(bRight,:));
common=intersect(leftBank,rightBank);
if ~isequal(common(:),tipID)
 R.stage='HOLD_TIP_OR_BANK_WELDING';
 R.message='Expected exactly one common topological node, the tip.';
 return
end
[syL,sl]=sort(X(leftBank,2));leftBank=leftBank(sl);
[syR,sr]=sort(X(rightBank,2));rightBank=rightBank(sr);
if numel(leftBank)~=numel(rightBank)|| ...
 max(abs(syL-syR))>1e-8|| ...
 max(abs(X(leftBank,1)-X(rightBank,1)))>1e-8
 R.stage='HOLD_BANK_COORDINATE_PAIRING';return
end
if abs(syL(1)-ymin)>1e-8||abs(syL(end)-yt)>1e-8
 R.stage='HOLD_CRACK_MOUTH_OR_TIP';return
end
% Ensure EACH bank comprises consecutive edge segments, no missing edges.
canon=@(v)sortrows(sort([v(1:end-1),v(2:end)],2));
leftEdges=sort(E(bLeft,:),2);rightEdges=sort(E(bRight,:),2);
if ~isequal(sortrows(leftEdges),sortrows(canon(leftBank)))|| ...
   ~isequal(sortrows(rightEdges),sortrows(canon(rightBank)))
 R.stage='HOLD_NONCHAINED_BANK';return
end
% Distinct T3 corner IDs and midpoint IDs; single tip remains shared.
n3=size(X,1);
Xm=.5*(X(E(:,1),:)+X(E(:,2),:));
X6=[X;Xm];
T6=[T,n3+ic(1:size(T,1)), ...
 n3+ic(size(T,1)+(1:size(T,1))), ...
 n3+ic(2*size(T,1)+(1:size(T,1)))];
[~,lAll]=ismember(sortrows(leftEdges),E,'rows');
[~,rAll]=ismember(sortrows(rightEdges),E,'rows');
leftBankT6=sort([leftBank;n3+lAll]);
rightBankT6=sort([rightBank;n3+rAll]);
if ~isequal(intersect(leftBankT6,rightBankT6),tipID)
 R.stage='HOLD_T6_BANK_WELDING';return
end
% Geometric area = analytic rectangle minus three disks, up to native
% straight T3 circle facets. The collapsed channel has zero physical area.
materialArea=sum(twiceArea)/2;
analyticArea=(xmax-xmin)*(ymax-ymin)-pi*sum(radius.^2);
relativeArea=abs(materialArea/analyticArea-1);
R.summary.analyticArea_mm2=analyticArea;
R.summary.meshArea_mm2=materialArea;
R.summary.relativeAreaError=relativeArea;
R.summary.crackFaceT3NodesPerSide=numel(leftBank);
R.summary.crackFaceT6NodesPerSide=numel(leftBankT6);
R.summary.sharedCrackTipNode=tipID;
R.summary.globalT3Elements=size(T,1);
R.summary.globalT3Nodes=size(X,1);
R.summary.globalT6Nodes=size(X6,1);
if relativeArea>0.005
 R.stage='HOLD_AREA_VS_THREE_TRUE_CIRCLES';
 R.message=sprintf('Relative area discrepancy %.4g > .005.',relativeArea);
 return
end

R.gates=struct( ...
 'sourceNominalSpecimen1',true, ...
 'nativeThreeTrueCADCircles',true, ...
 'nativeCADUniquePhysicalTip',true, ...
 'twoDistinctNativePencilFaces',true, ...
 'equalFaceStationCount',numel(ln)==numel(rn), ...
 'pairingMismatchUnderLimit',mismatch<=o.PairStationTolerance_mm, ...
 'collapsedT3AllPositive',all(twiceArea>0), ...
 'collapsedMinCornerAngle20deg',minAng>=20, ...
 'collapsedNeighborRatio1p8',rmax<=1.8, ...
 'twoIndependentCrackBankBoundaryChains',true, ...
 'exactlyOneSharedTipTopologicalNode',isequal(common(:),tipID), ...
 'T6MidSideIdsRemainDistinctOnBanks', ...
    isequal(intersect(leftBankT6,rightBankT6),tipID), ...
 'fourBoundaryLoopsThreeHolesAndOuterSlit', ...
    R.summary.boundaryComponents==4, ...
 'allThreeCircleBoundaryChains', ...
    all(R.summary.circleBoundaryChordCounts>=12), ...
 'areaMatchesSolidMinusThreeDisks',relativeArea<=0.005);
R.pass=all(cell2mat(struct2cell(R.gates)));
R.stage='CANDIDATE_TOPOLOGY_PASS';
R.message=['All candidate geometry checks passed; this mesh still lacks ', ...
 'the accepted protected p010 tip/collar, independent full-mesh T6 ', ...
 'checker and true experimental BVP qualification.'];
R.model=model;
R.nativePDEMesh=m;
R.coord3=X;
R.connect3=T;
R.coord6=X6;
R.connect6=T6;
R.bankUpperT6=leftBankT6; % left side of the upward vertical slit
R.bankLowerT6=rightBankT6;
R.physicalTipNode=tipID;
R.bankPairing=struct('leftSourceNodes',ln,'rightSourceNodes',rn, ...
 'station_mm',pairedY,'sourceStationMismatch_mm',ysL-ysR);
if o.Plot
 if isfield(R,'figure')&&ishandle(R.figure),close(R.figure);end
 fig=figure('Color','w','Visible','off', ...
    'Name','Cornell #1 experimental pencil-collapsed T3 (NOT LEFM)');
 triplot(T,X(:,1),X(:,2),'Color',[.5 .67 .78]);hold on;
 plot(cx+[0 0],[ymin yt],'r-','LineWidth',2);
 axis equal;grid on;xlabel('x (mm)');ylabel('y (mm)');
 title('Three CAD holes + two collapsed banks (candidate; no p010)');
 R.figure=fig;
end
end
