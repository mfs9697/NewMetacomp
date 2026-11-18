function R = g2_protected_exterior_mesh(varargin)
%G2_PROTECTED_EXTERIOR_MESH  Cornell #1 exterior mesh with a 64-chord rim cavity.
%
% WP1 of Issue #20 (geometry only). Builds a NEW native PDE Toolbox exterior
% for the Cornell three-hole specimen that excludes the protected tip region:
%  - the pencil channel (half-width .020 mm) runs from the crack mouth on the
%    bottom edge to the 3.3 mm collar rim instead of to an apex;
%  - the rim is a 64-gon whose vertices are EXACTLY the analytic outer nodes of
%    the frozen p010 collar (tip + 3.3*(cos(phi)*t + sin(phi)*n), phi = 0..63
%    times 2*pi/64, t = (0,1), n = (-1,0)); the crack-entry vertex at phi = pi
%    is split into two native vertices on x = cx -/+ w;
%  - three true CAD holes and three NONPHYSICAL 3R = 19.05 mm guide circles
%    (internal material faces with Hface 1.5 mm, as in the qualified three-hole
%    candidate); global controls Hmax 6, Hgrad 1.12, Hmin .12, lip Hedge .45 mm.
% Lips are collapsed onto x = cx WITHOUT welding; the two entry vertices become
% the two distinct crack-entry nodes at (cx, ytip - 3.3).
% The rim edges get Hedge = chord, and the run HOLDS unless every rim edge is a
% single mesh segment (65 rim node identities, 64 segments).
%
% No stiffness, no BVP, no SIF, no crack growth. approvedForLEFM is always false.
% Length unit: millimetres. MATLAB R2023a + PDE Toolbox.
ip=inputParser;
here=fileparts(mfilename('fullpath'));
root=fileparts(fileparts(here));
source=fullfile(root,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json');
addParameter(ip,'JsonPath',source,@(s)ischar(s)||isstring(s));
addParameter(ip,'ChannelHalfWidth_mm',.020,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'RimRadius_mm',3.3,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'RimSectors',64,@(v)isnumeric(v)&&isscalar(v)&&v==64);
addParameter(ip,'Hmin_mm',.12,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'Hmax_mm',6,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'Hgrad',1.12,@(v)isnumeric(v)&&isscalar(v)&&v>=1&&v<=1.3);
addParameter(ip,'Hedge_mm',.45,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'GuideHface_mm',1.5,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'PairStationTolerance_mm',.15,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'MaxT3Elements',40000,@(v)isnumeric(v)&&isscalar(v)&&v>0);
% WP2 options; the defaults reproduce the WP1 qualified construction exactly.
addParameter(ip,'IncludeHoles',true,@(v)islogical(v)&&isscalar(v));   % false: holeless benchmark only
addParameter(ip,'PlateXRange_mm',[],@(v)isempty(v)||(isnumeric(v)&&numel(v)==2));
addParameter(ip,'BottomVertices_mm',[],@(v)isempty(v)||isnumeric(v)); % extra CAD vertices on y = ymin (x values)
addParameter(ip,'TopVertices_mm',[],@(v)isempty(v)||isnumeric(v));    % extra CAD vertices on y = ymax (x values)
% nonphysical tip guide face (same CSG device as the 3R hole guides): an internal
% material face of radius TipGuideRadius_mm around the tip with its own Hface
addParameter(ip,'TipGuideRadius_mm',[],@(v)isempty(v)||(isnumeric(v)&&isscalar(v)&&v>0));
addParameter(ip,'TipGuideHface_mm',1.5,@(v)isnumeric(v)&&isscalar(v)&&v>0);
parse(ip,varargin{:});o=ip.Results;
R=struct('pass',false,'stage','HOLD_NOT_STARTED','message','', ...
    'geometryOnly',true,'approvedForLEFM',false,'summary',struct());
D=g2_pde_toolbox_preflight();
if ~D.pass
 error('G2Ext:PDEToolboxUnavailable','Required PDE capabilities missing: %s',strjoin(D.failedChecks,', '));
end
J=jsondecode(fileread(char(o.JsonPath)));
assert(strcmp(J.schema,'NewMetacomp.G2.IngraffeaGrigoriu1990.Specimen1.nominal.v1'), ...
 'G2Ext:WrongSource','Expected the Cornell specimen-1 nominal v1 JSON.');
G=J.nominal_geometry_mm;
assert(numel(G.holes)==3,'G2Ext:ThreeHoles','Cornell specimen #1 has exactly three holes.');
w=o.ChannelHalfWidth_mm;ro=o.RimRadius_mm;
xmin=G.plate.x_range(1);xmax=G.plate.x_range(2);
if ~isempty(o.PlateXRange_mm),xmin=o.PlateXRange_mm(1);xmax=o.PlateXRange_mm(2);end
ymin=G.plate.y_range(1);ymax=G.plate.y_range(2);
mouth=G.initial_crack.mouth(:).';tip=G.initial_crack.tip(:).';
assert(abs(mouth(2)-ymin)<1e-10&&abs(tip(1)-mouth(1))<1e-10, ...
 'G2Ext:VerticalBottomEdgeCrack','The source crack must start on the bottom edge and be vertical.');
cx=tip(1);yt=tip(2);
hx=zeros(3,1);hy=hx;hr=hx;
for k=1:3,hx(k)=G.holes(k).center(1);hy(k)=G.holes(k).center(2);hr(k)=G.holes(k).radius;end
gr=3*hr; % nonphysical guide radii (3R)
nH=3*o.IncludeHoles;
for k=1:nH
 assert(hx(k)-gr(k)>xmin&&hx(k)+gr(k)<xmax&&hy(k)-gr(k)>ymin&&hy(k)+gr(k)<ymax, ...
  'G2Ext:GuideOutsidePlate','Guide circle %d leaves the plate.',k);
 assert(hx(k)-gr(k)>cx+ro,'G2Ext:GuideCrossesTipRegion','Guide circle %d reaches the channel or rim.',k);
 for j=1:k-1
  assert(norm([hx(k)-hx(j),hy(k)-hy(j)])>gr(k)+gr(j),'G2Ext:GuidesOverlap','Guides %d and %d overlap.',j,k);
 end
end
% ---- analytic rim vertices (identical formula to the frozen collar)
t=[0 1];n=[-1 0];
phi=(0:63)'*2*pi/64;
P=tip+ro*(cos(phi)*t+sin(phi)*n);   % P(33,:) = entry (cx, yt-ro)
assert(norm(P(33,:)-[cx,yt-ro])<1e-12,'G2Ext:EntryVertex','Rim entry vertex is not at phi = pi.');
segX=@(A,B,x)A+(x-A(1))/(B(1)-A(1))*(B-A);
EL=segX(P(33,:),P(32,:),cx-w);      % left native entry on chord P33-P32
ER=segX(P(33,:),P(34,:),cx+w);      % right native entry on chord P33-P34
assert(EL(1)<cx&&ER(1)>cx&&abs(EL(2)-ER(2))<1e-12,'G2Ext:EntrySplit','Entry split is not symmetric.');
rimOrder=[32:-1:1,64:-1:34]';       % native polygon order after EL, before ER
bv=sort(o.BottomVertices_mm(:));tv=sort(o.TopVertices_mm(:),'descend');
assert(all(bv>xmin&bv<xmax&abs(bv-cx)>w+1)&&all(tv>xmin&tv<xmax),'G2Ext:ExtraVertex','Extra vertex outside its edge or on the channel.');
bR=bv(bv>cx);bL=bv(bv<cx);
outer=[cx+w,ymin;[bR,ymin+0*bR];xmax,ymin;xmax,ymax;[tv,ymax+0*tv];xmin,ymax;xmin,ymin;[bL,ymin+0*bL];cx-w,ymin;EL;P(rimOrder,:);ER];
Np=size(outer,1);
tg=~isempty(o.TipGuideRadius_mm);Rg=o.TipGuideRadius_mm;
if tg
 assert(Rg>ro+2&&yt-Rg>ymin&&cx-Rg>xmin,'G2Ext:TipGuide','Tip guide circle must lie inside the plate and well outside the rim.');
 for k=1:nH,assert(norm([hx(k)-cx,hy(k)-yt])>Rg+gr(k),'G2Ext:TipGuideOverlap','Tip guide overlaps hole guide %d.',k);end
end
cols={[2;Np;outer(:,1);outer(:,2)]};names={'MAT'};solid='MAT';guides={};
if o.IncludeHoles
 for k=1:3,cols{end+1}=[1;hx(k);hy(k);hr(k)];names{end+1}=sprintf('C%d',k);end %#ok<AGROW>
 solid='MAT-C1-C2-C3';
 for k=1:3,cols{end+1}=[1;hx(k);hy(k);gr(k)];names{end+1}=sprintf('G%d',k);guides{end+1}=sprintf('G%d',k);end %#ok<AGROW>
end
if tg,cols{end+1}=[1;cx;yt;Rg];names{end+1}='GT';guides{end+1}='GT';end
if isempty(guides)
 sf=solid;
else
 sf=['((',solid,')',sprintf('-%s',guides{:}),')'];
 for k=1:numel(guides),sf=[sf,'+((',solid,')*',guides{k},')'];end %#ok<AGROW>
end
nc=numel(cols);gd=zeros(max(cellfun(@numel,cols)),nc);
for k=1:nc,gd(1:numel(cols{k}),k)=cols{k};end
[dl,~]=decsg(gd,sf,char(names{:}).');
model=createpde(1);
geometryFromEdges(model,dl);
geom=model.Geometry;
R.summary.cadFaces=geom.NumFaces;
sample=zeros(0,2);
if o.IncludeHoles,sample=[hx+2*hr,hy];end
if tg,sample=[sample;cx+.5*(ro+Rg),yt+.5*(ro+Rg)];end   % inside the tip guide annulus, off the crack line
sample=[sample;xmax-25,(ymin+ymax)/2];
fIDs=nearestFace(geom,sample);
nExp=size(sample,1);
if geom.NumFaces~=nExp||numel(unique(fIDs))~=nExp
 R.stage='HOLD_CAD_FACES';
 R.message=sprintf('Expected %d material faces, got %d / probes %s.',nExp,geom.NumFaces,mat2str(fIDs));
 return
end
annulusFaces=fIDs(1:3*o.IncludeHoles);
tipFace=[];if tg,tipFace=fIDs(3*o.IncludeHoles+1);end
% ---- CAD edge identification by geometry
yEntry=EL(2);
lipL=unique(nearestEdge(geom,[cx-w,yEntry*.25;cx-w,yEntry*.75]));
lipR=unique(nearestEdge(geom,[cx+w,yEntry*.25;cx+w,yEntry*.75]));
rimPts=[EL;P(rimOrder,:);ER];
rimMid=.5*(rimPts(1:end-1,:)+rimPts(2:end,:));
rimCAD=nearestEdge(geom,rimMid);
if numel(unique(rimCAD))~=64||~isempty(intersect(rimCAD,[lipL(:);lipR(:)]))||~isempty(intersect(lipL,lipR))
 R.stage='HOLD_RIM_OR_LIP_CAD';
 R.message=sprintf('Rim CAD edges %d (need 64 distinct); lips L=%s R=%s.',numel(unique(rimCAD)),mat2str(lipL),mat2str(lipR));
 return
end
holeCAD=cell(nH,1);
for k=1:nH
 ps=(0:47)'*2*pi/48;
 holeCAD{k}=unique(nearestEdge(geom,[hx(k)+hr(k)*cos(ps),hy(k)+hr(k)*sin(ps)]));
end
chord=2*ro*sin(pi/64);
hedge={lipL(:)',o.Hedge_mm,lipR(:)',o.Hedge_mm,rimCAD(:)',chord};
for k=1:nH,hedge=[hedge,{holeCAD{k}(:)',.70*2*hr(k)*sin(pi/120)}];end %#ok<AGROW>
tm=tic;
hface={};
if o.IncludeHoles,hface=[hface,{annulusFaces(:)',o.GuideHface_mm}];end
if tg,hface=[hface,{tipFace,o.TipGuideHface_mm}];end
if isempty(hface)
m=generateMesh(model,'GeometricOrder','linear','Hmin',o.Hmin_mm,'Hmax',o.Hmax_mm,'Hgrad',o.Hgrad,'Hedge',hedge);
else
m=generateMesh(model,'GeometricOrder','linear','Hmin',o.Hmin_mm,'Hmax',o.Hmax_mm,'Hgrad',o.Hgrad,'Hedge',hedge,'Hface',hface);
end
R.summary.nativeMeshingSeconds=toc(tm);
X0=m.Nodes.';T=m.Elements.';
R.summary.nativeT3=size(T,1);R.summary.nativeNodes=size(X0,1);
fprintf('G2_EXT_NATIVE_T3=%d\n',size(T,1));
if size(T,1)>o.MaxT3Elements
 R.stage='HOLD_WORK_BUDGET';R.message=sprintf('Native T3 %d > %d.',size(T,1),o.MaxT3Elements);return
end
% ---- rim: exactly 65 node identities, one mesh segment per CAD rim edge
rimNodes=unique(findNodes(m,'region','Edge',rimCAD(:)'));
R.summary.rimNodeCount=numel(rimNodes);
fprintf('G2_EXT_RIM_NODES=%d\n',numel(rimNodes));
if numel(rimNodes)~=65
 R.stage='HOLD_RIM_SUBDIVIDED';
 R.message=sprintf('Rim carries %d nodes; 65 (64 single segments) required.',numel(rimNodes));
 return
end
Dr=hypot(X0(rimNodes,1)-rimPts(:,1).',X0(rimNodes,2)-rimPts(:,2).'); % nodes x vertices
[dmin,kk]=min(Dr,[],1);
R.summary.rimVertexMaxDeviation_mm=max(dmin);
if max(dmin)>1e-7||numel(unique(kk))~=65
 R.stage='HOLD_RIM_VERTEX_MISMATCH';
 R.message=sprintf('Rim nodes deviate from the analytic vertices by %.3g mm.',max(dmin));
 return
end
rimID=rimNodes(kk);           % rimID(i) is the node at rimPts(i,:)
idEL=rimID(1);idER=rimID(end);
idP=zeros(64,1);idP(rimOrder)=rimID(2:end-1);   % idP(j) node at P(j), j~=33
% ---- lips: paired stations, collapse without welding
ln=unique(findNodes(m,'region','Edge',lipL(:)'));
rn=unique(findNodes(m,'region','Edge',lipR(:)'));
[ysL,ia]=sort(X0(ln,2));ln=ln(ia);
[ysR,ib]=sort(X0(rn,2));rn=rn(ib);
if numel(ln)~=numel(rn)||numel(ln)<3||ln(end)~=idEL||rn(end)~=idER
 R.stage='HOLD_LIP_STATIONS';
 R.message=sprintf('Lip nodes L=%d R=%d; entries must close both lips.',numel(ln),numel(rn));
 return
end
mismatch=max(abs(ysL-ysR));
R.summary.lipPairs=numel(ln);R.summary.lipStationMismatch_mm=mismatch;
if mismatch>o.PairStationTolerance_mm||abs(ysL(1)-ymin)>1e-9||abs(ysR(1)-ymin)>1e-9
 R.stage='HOLD_LIP_PAIRING';R.message=sprintf('Lip station mismatch %.4g mm.',mismatch);return
end
X=X0;
yPair=.5*(ysL+ysR);yPair(1)=ymin;yPair(end)=yt-ro;
X(ln,1)=cx;X(rn,1)=cx;X(ln,2)=yPair;X(rn,2)=yPair;
X(idP(rimOrder),:)=P(rimOrder,:);  % snap to the exact analytic collar coordinates
aa=X(T(:,2),:)-X(T(:,1),:);bb=X(T(:,3),:)-X(T(:,1),:);
a2=aa(:,1).*bb(:,2)-aa(:,2).*bb(:,1);
if any(~isfinite(a2))||any(a2<=0)
 R.stage='HOLD_EXTERIOR_T3_DEGENERATE';R.message=sprintf('%d exterior T3 nonpositive after collapse.',nnz(a2<=0));return
end
R.pass=true;R.stage='EXTERIOR_RIM_CAVITY_READY';
R.message='Exterior with 64-chord rim cavity built and collapsed; NOT yet joined to p010.';
R.coord3=X;R.connect3=T;
R.rimNodeAtP=idP;R.rimEntryLeft=idEL;R.rimEntryRight=idER;
R.leftLipNodes=ln;R.rightLipNodes=rn;
R.holeCenters=[hx,hy];R.holeRadii=hr;R.guideRadii=gr;R.includeHoles=o.IncludeHoles;
% node IDs at the extra CAD vertices (exact coordinates), for supports and point loads
xv=[bv,ymin+0*bv;tv,ymax+0*tv];R.extraVertexXY=xv;R.extraVertexNodes=zeros(size(xv,1),1);
for k=1:size(xv,1)
 id=find(vecnorm(X-xv(k,:),2,2)<1e-9);
 assert(isscalar(id),'G2Ext:ExtraVertexNode','No unique mesh node at extra vertex %d.',k);R.extraVertexNodes(k)=id;
end
R.plateXRange=[xmin,xmax];
R.summary.channelHalfWidth_mm=w;R.summary.rimRadius_mm=ro;R.summary.rimChord_mm=chord;
R.summary.controls=struct('Hmin_mm',o.Hmin_mm,'Hmax_mm',o.Hmax_mm,'Hgrad',o.Hgrad, ...
    'lipHedge_mm',o.Hedge_mm,'guideHface_mm',o.GuideHface_mm,'rimHedge_mm',chord, ...
    'tipGuideRadius_mm',o.TipGuideRadius_mm,'tipGuideHface_mm',o.TipGuideHface_mm);
R.summary.annulusFaceIDs=annulusFaces(:).';
R.summary.PDEToolboxVersion=D.PDEToolboxVersion;
end
