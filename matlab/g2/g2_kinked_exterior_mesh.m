function R = g2_kinked_exterior_mesh(P, varargin)
%G2_KINKED_EXTERIOR_MESH  Cornell #1 native PDE exterior for a KINKED crack polyline with a 64-chord rim cavity.
%
%  R = g2_kinked_exterior_mesh(P, ...)    % P: N-by-2 mm, mouth on y = ymin first, tip last
% WP3.1 (Issue #24), geometry only. Generalises g2_protected_exterior_mesh (unchanged,
% straight vertical channel only) to a polyline:
%  - mitred channel of half-width w: offsets P_k +/- w*m_k with the miter vector
%    m_k = (n_{k-1} + n_k)/(1 + t_{k-1}.t_k); the upper (+n) offset ends at EL, the
%    lower at ER, the two native entry vertices on the rim chords P33-P32 and P33-P34
%    at local eta = +/- w of the LAST segment frame;
%  - 64-gon rim cavity at the exact analytic collar coordinates
%    tip + ro (cos(phi) t + sin(phi) n) of the last-segment frame (g2_polyline_frame);
%  - three true CAD holes, three NONPHYSICAL 3R guide faces, optional tip guide face
%    centred at the new tip, optional point vertices on the bottom/top edges;
%  - lips found on every offset segment by dense geometric sampling, paired by
%    centre-line station (offset segment k maps linearly onto centre-line segment k;
%    the last centre-line segment ends at the collar entry tip - ro t), collapsed
%    without welding; mouth, miter and entry pairs go to the exact vertices.
% HOLDs (no fallback): admissibility K1-K10, CAD faces/edges, budget, 65 rim nodes,
% lip station pairing per segment, nonpositive T3 after collapse.
% No stiffness, no BVP, no SIF, no crack growth. Millimetres.
ip=inputParser;
here=fileparts(mfilename('fullpath'));root=fileparts(fileparts(here));
source=fullfile(root,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json');
addParameter(ip,'JsonPath',source,@(s)ischar(s)||isstring(s));
addParameter(ip,'DeltaA_mm',4,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'ExpectedTangent',[],@(v)isempty(v)||(isnumeric(v)&&numel(v)==2));
addParameter(ip,'ChannelHalfWidth_mm',.020,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'RimRadius_mm',3.3,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'Hmin_mm',.12,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'Hmax_mm',6,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'Hgrad',1.12,@(v)isnumeric(v)&&isscalar(v)&&v>=1&&v<=1.3);
addParameter(ip,'Hedge_mm',.45,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'GuideHface_mm',1.5,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'PairStationTolerance_mm',.15,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'MaxT3Elements',40000,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'BottomVertices_mm',[],@(v)isempty(v)||isnumeric(v));
addParameter(ip,'TopVertices_mm',[],@(v)isempty(v)||isnumeric(v));
addParameter(ip,'TipGuideRadius_mm',[],@(v)isempty(v)||(isnumeric(v)&&isscalar(v)&&v>0));
addParameter(ip,'TipGuideHface_mm',1.5,@(v)isnumeric(v)&&isscalar(v)&&v>0);
parse(ip,varargin{:});o=ip.Results;
R=struct('pass',false,'stage','HOLD_NOT_STARTED','message','','geometryOnly',true,'approvedForLEFM',false,'summary',struct());
D=g2_pde_toolbox_preflight();
if ~D.pass,error('G2KExt:PDE','Required PDE capabilities missing: %s',strjoin(D.failedChecks,', '));end
J=jsondecode(fileread(char(o.JsonPath)));
assert(strcmp(J.schema,'NewMetacomp.G2.IngraffeaGrigoriu1990.Specimen1.nominal.v1'),'G2KExt:Schema','Wrong JSON.');
G=J.nominal_geometry_mm;assert(numel(G.holes)==3,'G2KExt:ThreeHoles','Three holes expected.');
w=o.ChannelHalfWidth_mm;ro=o.RimRadius_mm;Rg=o.TipGuideRadius_mm;tg=~isempty(Rg);
A=g2_kink_admissibility(P,G,'DeltaA_mm',o.DeltaA_mm,'ExpectedTangent',o.ExpectedTangent,'ChannelHalfWidth_mm',w, ...
 'RimRadius_mm',ro,'Hmin_mm',o.Hmin_mm,'GuideHface_mm',o.GuideHface_mm,'TipGuideRadius_mm',Rg);
R.admissibility=A;
if ~A.pass,R.stage='HOLD_KINK_ADMISSIBILITY';R.message=strjoin(A.failedGates,', ');return,end
xmin=G.plate.x_range(1);xmax=G.plate.x_range(2);ymin=G.plate.y_range(1);ymax=G.plate.y_range(2);
F=g2_polyline_frame(P);N=size(P,1);tip=F.tip;t=F.t;n=F.n;tt=F.tt;nn=F.nn;
assert(abs(P(1,2)-ymin)<1e-12&&abs(tt(1,1))<1e-15&&tt(1,2)>0,'G2KExt:Mouth','First segment must be the vertical bottom-edge starter crack.');
hx=zeros(3,1);hy=hx;hr=hx;
for k=1:3,hx(k)=G.holes(k).center(1);hy(k)=G.holes(k).center(2);hr(k)=G.holes(k).radius;end
gr=3*hr;
for k=1:3
 assert(hx(k)-gr(k)>xmin&&hx(k)+gr(k)<xmax&&hy(k)-gr(k)>ymin&&hy(k)+gr(k)<ymax,'G2KExt:GuideOutsidePlate','Guide %d leaves the plate.',k);
 for j=1:k-1,assert(norm([hx(k)-hx(j),hy(k)-hy(j)])>gr(k)+gr(j),'G2KExt:GuidesOverlap','Guides overlap.');end
end
% ---- analytic rim (last-segment frame) and split entry on the chords
phi=(0:63)'*2*pi/64;
Rv=tip+ro*(cos(phi)*t+sin(phi)*n);
entry=Rv(33,:);
EL=Rv(33,:)+w/(ro*sin(phi(32)))*(Rv(32,:)-Rv(33,:));       % upper (+n) native entry, eta = +w
ER=Rv(33,:)+w/(ro*abs(sin(phi(34))))*(Rv(34,:)-Rv(33,:));  % lower native entry, eta = -w
etaL=(EL-tip)*n.';etaR=(ER-tip)*n.';
assert(abs(etaL-w)<1e-12&&abs(etaR+w)<1e-12,'G2KExt:EntrySplit','Entry split not at eta = +/- w.');
% ---- mitred offsets and centre-line control points
m=zeros(max(N-2,0),2);
for k=2:N-1,m(k-1,:)=(nn(k-1,:)+nn(k,:))/(1+dot(tt(k-1,:),tt(k,:)));end
upperPath=[P(1,:)+w*nn(1,:);P(2:N-1,:)+w*m;EL];
lowerPath=[P(1,:)-w*nn(1,:);P(2:N-1,:)-w*m;ER];
Cc=[P(1:N-1,:);entry];Sc=[0;cumsum(vecnorm(diff(Cc),2,2))];
rimOrder=[32:-1:1,64:-1:34]';
bv=sort(o.BottomVertices_mm(:));tv=sort(o.TopVertices_mm(:),'descend');
assert(all(bv>xmin&bv<xmax&abs(bv-P(1,1))>w+1)&&all(tv>xmin&tv<xmax),'G2KExt:ExtraVertex','Extra vertex outside its edge or on the channel.');
bR=bv(bv>P(1,1));bL=bv(bv<P(1,1));
outer=[lowerPath(1,:);[bR,ymin+0*bR];xmax,ymin;xmax,ymax;[tv,ymax+0*tv];xmin,ymax;xmin,ymin;[bL,ymin+0*bL]; ...
       upperPath;Rv(rimOrder,:);ER;flipud(lowerPath(2:N-1,:))];
[simple,areaSigned]=simple_polygon(outer);
R.summary.cadPolygonSimple=simple;R.summary.cadPolygonSignedArea=areaSigned;
if ~simple||areaSigned<=0
 R.stage='HOLD_CAD_POLYGON';R.message=sprintf('CAD polygon simple=%d area=%.6g.',simple,areaSigned);return
end
Np=size(outer,1);
cols={[2;Np;outer(:,1);outer(:,2)]};names={'MAT'};solid='MAT-C1-C2-C3';guides={};
for k=1:3,cols{end+1}=[1;hx(k);hy(k);hr(k)];names{end+1}=sprintf('C%d',k);end %#ok<AGROW>
for k=1:3,cols{end+1}=[1;hx(k);hy(k);gr(k)];names{end+1}=sprintf('G%d',k);guides{end+1}=sprintf('G%d',k);end %#ok<AGROW>
if tg,cols{end+1}=[1;tip(1);tip(2);Rg];names{end+1}='GT';guides{end+1}='GT';end
sf=['((',solid,')',sprintf('-%s',guides{:}),')'];
for k=1:numel(guides),sf=[sf,'+((',solid,')*',guides{k},')'];end %#ok<AGROW>
nc=numel(cols);gd=zeros(max(cellfun(@numel,cols)),nc);
for k=1:nc,gd(1:numel(cols{k}),k)=cols{k};end
[dl,~]=decsg(gd,sf,char(names{:}).');
model=createpde(1);geometryFromEdges(model,dl);geom=model.Geometry;
R.summary.cadFaces=geom.NumFaces;
sample=[hx+2*hr,hy];
if tg,sample=[sample;tip+.5*(ro+Rg)*t];end
sample=[sample;xmax-25,(ymin+ymax)/2];
fIDs=nearestFace(geom,sample);nExp=size(sample,1);
if geom.NumFaces~=nExp||numel(unique(fIDs))~=nExp
 R.stage='HOLD_CAD_FACES';R.message=sprintf('Expected %d faces, got %d / probes %s.',nExp,geom.NumFaces,mat2str(fIDs));return
end
annulusFaces=fIDs(1:3);tipFace=[];if tg,tipFace=fIDs(4);end
% ---- CAD edges: lips by dense sampling of every offset segment, rim by chord midpoints
lam=linspace(.01,.99,200)';
samp=@(Q)cell2mat(arrayfun(@(k)Q(k,:)+lam*(Q(k+1,:)-Q(k,:)),(1:size(Q,1)-1)','UniformOutput',false));
lipU=unique(nearestEdge(geom,samp(upperPath)));lipL=unique(nearestEdge(geom,samp(lowerPath)));
rimPts=[EL;Rv(rimOrder,:);ER];rimMid=.5*(rimPts(1:end-1,:)+rimPts(2:end,:));
rimCAD=nearestEdge(geom,rimMid);
if numel(unique(rimCAD))~=64||~isempty(intersect(rimCAD,[lipU(:);lipL(:)]))||~isempty(intersect(lipU,lipL))
 R.stage='HOLD_RIM_OR_LIP_CAD';
 R.message=sprintf('Rim CAD %d (need 64); lips U=%s L=%s.',numel(unique(rimCAD)),mat2str(lipU),mat2str(lipL));return
end
holeCAD=cell(3,1);
for k=1:3,ps=(0:47)'*2*pi/48;holeCAD{k}=unique(nearestEdge(geom,[hx(k)+hr(k)*cos(ps),hy(k)+hr(k)*sin(ps)]));end
chord=2*ro*sin(pi/64);
hedge={lipU(:)',o.Hedge_mm,lipL(:)',o.Hedge_mm,rimCAD(:)',chord};
for k=1:3,hedge=[hedge,{holeCAD{k}(:)',.70*2*hr(k)*sin(pi/120)}];end %#ok<AGROW>
hface={annulusFaces(:)',o.GuideHface_mm};if tg,hface=[hface,{tipFace,o.TipGuideHface_mm}];end
tm=tic;
msh=generateMesh(model,'GeometricOrder','linear','Hmin',o.Hmin_mm,'Hmax',o.Hmax_mm,'Hgrad',o.Hgrad,'Hedge',hedge,'Hface',hface);
R.summary.nativeMeshingSeconds=toc(tm);
X0=msh.Nodes.';T=msh.Elements.';
R.summary.nativeT3=size(T,1);R.summary.nativeNodes=size(X0,1);
fprintf('G2_KEXT_NATIVE_T3=%d\n',size(T,1));
if size(T,1)>o.MaxT3Elements,R.stage='HOLD_WORK_BUDGET';R.message=sprintf('Native T3 %d > %d.',size(T,1),o.MaxT3Elements);return,end
% ---- rim: 65 node identities at the analytic vertices
rimNodes=unique(findNodes(msh,'region','Edge',rimCAD(:)'));
R.summary.rimNodeCount=numel(rimNodes);fprintf('G2_KEXT_RIM_NODES=%d\n',numel(rimNodes));
if numel(rimNodes)~=65,R.stage='HOLD_RIM_SUBDIVIDED';R.message=sprintf('Rim carries %d nodes; 65 required.',numel(rimNodes));return,end
Dr=hypot(X0(rimNodes,1)-rimPts(:,1).',X0(rimNodes,2)-rimPts(:,2).');[dmin,kk]=min(Dr,[],1);
R.summary.rimVertexMaxDeviation_mm=max(dmin);
if max(dmin)>1e-7||numel(unique(kk))~=65,R.stage='HOLD_RIM_VERTEX_MISMATCH';R.message=sprintf('Rim deviation %.3g mm.',max(dmin));return,end
rimID=rimNodes(kk);idEU=rimID(1);idEL=rimID(end);
idP=zeros(64,1);idP(rimOrder)=rimID(2:end-1);
% ---- lips: stations along the centre line, pairing per segment
un=unique(findNodes(msh,'region','Edge',lipU(:)'));ln=unique(findNodes(msh,'region','Edge',lipL(:)'));
[sU,dU]=stations(X0(un,:),upperPath,Sc);[sL,dL]=stations(X0(ln,:),lowerPath,Sc);
[sU,iu]=sort(sU);un=un(iu);[sL,il]=sort(sL);ln=ln(il);
R.summary.lipOffsetMaxDistance_mm=max([dU;dL]);
nseg=N-1;cntU=zeros(nseg,1);cntL=cntU;vU=false(N,1);vL=vU;
for k=1:nseg
 cntU(k)=nnz(sU>Sc(k)+1e-9&sU<Sc(k+1)-1e-9);cntL(k)=nnz(sL>Sc(k)+1e-9&sL<Sc(k+1)-1e-9);
end
for k=1:N,vU(k)=nnz(abs(sU-Sc(k))<=1e-9)==1;vL(k)=nnz(abs(sL-Sc(k))<=1e-9)==1;end
R.summary.lipInteriorNodesPerSegment=[cntU,cntL];
gapU=max(diff(sU));gapL=max(diff(sL));R.summary.lipMaxStationGap_mm=[gapU,gapL];
okStations=max([dU;dL])<1e-7&&numel(un)==numel(ln)&&isequal(cntU,cntL)&&all(vU)&&all(vL)&& ...
 un(end)==idEU&&ln(end)==idEL&&max(gapU,gapL)<=4*o.Hedge_mm;
if ~okStations
 R.stage='HOLD_LIP_STATIONS';
 R.message=sprintf('Lip nodes U=%d L=%d, per-segment %s / %s, vertices %d/%d, gaps %.3g/%.3g mm.', ...
  numel(un),numel(ln),mat2str(cntU.'),mat2str(cntL.'),nnz(vU),nnz(vL),gapU,gapL);return
end
mismatch=max(abs(sU-sL));R.summary.lipPairs=numel(un);R.summary.lipStationMismatch_mm=mismatch;
if mismatch>o.PairStationTolerance_mm,R.stage='HOLD_LIP_PAIRING';R.message=sprintf('Station mismatch %.4g mm.',mismatch);return,end
sBar=.5*(sU+sL);
vertexPair=false(size(sBar));
for k=1:N,j=abs(sU-Sc(k))<=1e-9;sBar(j)=Sc(k);vertexPair=vertexPair|j;end
Xc=centre_point(sBar,Cc,Sc);
for k=1:N,j=abs(sBar-Sc(k))==0;Xc(j,:)=repmat(Cc(k,:),nnz(j),1);end
X=X0;X(un,:)=Xc;X(ln,:)=Xc;
X(idP(rimOrder),:)=Rv(rimOrder,:);
aa=X(T(:,2),:)-X(T(:,1),:);bb=X(T(:,3),:)-X(T(:,1),:);a2=aa(:,1).*bb(:,2)-aa(:,2).*bb(:,1);
if any(~isfinite(a2))||any(a2<=0),R.stage='HOLD_EXTERIOR_T3_DEGENERATE';R.message=sprintf('%d T3 nonpositive after collapse.',nnz(a2<=0));return,end
kinkU=zeros(N-2,1);kinkL=kinkU;
for k=2:N-1,kinkU(k-1)=un(abs(sU-Sc(k))<=1e-9);kinkL(k-1)=ln(abs(sL-Sc(k))<=1e-9);end
R.pass=true;R.stage='KINKED_EXTERIOR_RIM_CAVITY_READY';
R.message='Kinked exterior built and collapsed; NOT yet joined to the p010 block.';
R.coord3=X;R.connect3=T;R.rimNodeAtP=idP;R.rimEntryUpper=idEU;R.rimEntryLower=idEL;
R.upperLipNodes=un;R.lowerLipNodes=ln;R.lipStations=sBar;R.kinkNodesUpper=kinkU;R.kinkNodesLower=kinkL;
R.polyline=P;R.frame=F;R.centreControl=Cc;R.centreStations=Sc;R.upperPath=upperPath;R.lowerPath=lowerPath;
R.holeCenters=[hx,hy];R.holeRadii=hr;R.guideRadii=gr;R.includeHoles=true;
xv=[bv,ymin+0*bv;tv,ymax+0*tv];R.extraVertexXY=xv;R.extraVertexNodes=zeros(size(xv,1),1);
for k=1:size(xv,1),id=find(vecnorm(X-xv(k,:),2,2)<1e-9);assert(isscalar(id),'G2KExt:ExtraVertexNode','No unique node at vertex %d.',k);R.extraVertexNodes(k)=id;end
R.plateXRange=[xmin,xmax];
R.summary.channelHalfWidth_mm=w;R.summary.rimRadius_mm=ro;R.summary.rimChord_mm=chord;
R.summary.lipCADEdges=[numel(lipU),numel(lipL)];
R.summary.controls=struct('Hmin_mm',o.Hmin_mm,'Hmax_mm',o.Hmax_mm,'Hgrad',o.Hgrad,'lipHedge_mm',o.Hedge_mm, ...
 'guideHface_mm',o.GuideHface_mm,'rimHedge_mm',chord,'tipGuideRadius_mm',Rg,'tipGuideHface_mm',o.TipGuideHface_mm);
R.summary.PDEToolboxVersion=D.PDEToolboxVersion;
end

function [s,dist]=stations(X,path,Sc)
% centre-line station of points lying on an offset path (segment k -> centre segment k)
nk=size(path,1)-1;M=size(X,1);dk=inf(M,nk);lk=zeros(M,nk);
for k=1:nk
 v=path(k+1,:)-path(k,:);l=max(0,min(1,((X-path(k,:))*v.')/(v*v.')));
 dk(:,k)=vecnorm(X-(path(k,:)+l*v),2,2);lk(:,k)=l;
end
[dist,kk]=min(dk,[],2);
s=zeros(M,1);
for i=1:M,k=kk(i);s(i)=Sc(k)+lk(i,k)*(Sc(k+1)-Sc(k));end
end

function Xc=centre_point(s,C,Sc)
Xc=zeros(numel(s),2);
for i=1:numel(s)
 k=find(s(i)>=Sc(1:end-1),1,'last');k=min(max(k,1),numel(Sc)-1);
 Xc(i,:)=C(k,:)+(s(i)-Sc(k))/(Sc(k+1)-Sc(k))*(C(k+1,:)-C(k,:));
end
end

function [ok,A]=simple_polygon(V)
n=size(V,1);A=.5*sum(V(:,1).*V([2:n,1],2)-V([2:n,1],1).*V(:,2));ok=true;
for i=1:n
 a=V(i,:);b=V(mod(i,n)+1,:);
 for j=i+2:n
  if i==1&&j==n,continue,end
  c=V(j,:);e=V(mod(j,n)+1,:);
  if segx(a,b,c,e),ok=false;return,end
 end
end
end

function x=segx(a,b,c,e)
o=@(p,q,r)(q(1)-p(1))*(r(2)-p(2))-(q(2)-p(2))*(r(1)-p(1));
x=o(a,b,c)*o(a,b,e)<0&&o(c,e,a)*o(c,e,b)<0;
end
