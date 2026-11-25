function R = g2_lp2a2_exterior_mesh(P, varargin)
%G2_LP2A2_EXTERIOR_MESH  LP2-A2 copy of g2_kinked_exterior_mesh with DETERMINISTIC PAIRED crack-bank seeding.
% The ONLY change to the inherited algorithm: every mitred offset segment k of the upper and the
% lower bank is split at the SAME parametric stations xi_j = j/m_k, m_k = ceil(L_k/Hedge), where L_k
% is the length of centre-line segment k (mouth ... kinks ... collar entry). The seeds are explicit
% CAD vertices of the channel polygon, so every bank sub-edge is no longer than the inherited lip
% Hedge. The NONPHYSICAL guide circles (tip guide GT and the hole guides G1-G3) cut both banks and
% decsg then creates a CAD vertex at each crossing; these crossings are computed analytically and
% enter as FORCED seeds (paired by circle and order, same segment required, each replacing the
% nearest regular seed of that segment). Because the banks are offset by +/-w, the two crossings of
% one circle lie at slightly different centre-line stations (geometric, of order w*tan(angle));
% this residual is reported and bounded by 2w; it is collapsed at the mean station exactly as the
% inherited routine collapses every pair. All regular seed pairs have identical stations.
% After meshing, each lip node must coincide (1e-7 mm, the inherited rim-vertex tolerance) with exactly one seed and each seed
% must carry exactly one node on its bank; upper and lower nodes are paired by SEED INDEX (never by
% count or Euclidean proximity). Any extra or missing lip node is HOLD_LIP_SEED_NOT_HONOURED; the
% inherited station/pairing checks are kept unchanged. Collapse, rim, holes, guides, tip guide,
% Hedge/Hface/Hgrad/Hmin/Hmax and all HOLDs are those of the inherited routine.
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
here=fileparts(mfilename('fullpath'));root=fileparts(fileparts(fileparts(here)));
source=fullfile(root,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json');
addParameter(ip,'JsonPath',source,@(s)ischar(s)||isstring(s));
addParameter(ip,'DeltaA_mm',4,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'ExpectedVertices',3,@(v)isnumeric(v)&&isscalar(v)&&v>=3&&v==round(v));
addParameter(ip,'ExpectedTangent',[],@(v)isempty(v)||(isnumeric(v)&&numel(v)==2));
addParameter(ip,'ChannelHalfWidth_mm',.020,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'RimRadius_mm',3.3,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'Hmin_mm',.12,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'Hmax_mm',6,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'Hgrad',1.12,@(v)isnumeric(v)&&isscalar(v)&&v>=1&&v<=1.3);
addParameter(ip,'Hedge_mm',.45,@(v)isnumeric(v)&&isscalar(v)&&v>0);
addParameter(ip,'SeedSpacing_mm',[],@(v)isempty(v)||(isnumeric(v)&&isscalar(v)&&v>0));   % LP2-A2: default = Hedge_mm
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
A=g2_kink_admissibility(P,G,'DeltaA_mm',o.DeltaA_mm,'ExpectedVertices',o.ExpectedVertices,'ExpectedTangent',o.ExpectedTangent,'ChannelHalfWidth_mm',w, ...
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
% ---- LP2-A2: common paired stations on every bank segment (explicit CAD seeds)
hs=o.SeedSpacing_mm;if isempty(hs),hs=o.Hedge_mm;end
mSeg=ceil(diff(Sc)/hs-1e-9);R.summary.seedSpacing_mm=hs;
circ=[hx,hy,3*hr];if tg,circ=[circ;tip,Rg];end
SP=seedPairs(upperPath,lowerPath,mSeg,circ);
R.summary.seedsPerSegment=mSeg(:).';R.summary.guideCrossingPairs=SP.nForced;R.summary.guideCrossingSegments=SP.forcedSeg(:).';
if ~SP.ok,R.stage='HOLD_GUIDE_CROSSING_UNPAIRED';R.message=SP.message;return,end
upperSeed=SP.QU;lowerSeed=SP.QL;seedSeg=SP.seg;seedXi=[SP.xiU,SP.xiL];
seedSU=Sc(seedSeg)+SP.xiU.*(Sc(seedSeg+1)-Sc(seedSeg));seedSL=Sc(seedSeg)+SP.xiL.*(Sc(seedSeg+1)-Sc(seedSeg));seedS=.5*(seedSU+seedSL);
R.summary.seedCount=size(upperSeed,1);R.summary.seedStationMismatchRegular_mm=max([0;abs(seedSU(~SP.forced)-seedSL(~SP.forced))]);
R.summary.seedStationMismatchForced_mm=max([0;abs(seedSU(SP.forced)-seedSL(SP.forced))]);
R.summary.minSeedSpacing_mm=min([vecnorm(diff(upperSeed),2,2);vecnorm(diff(lowerSeed),2,2)]);
if R.summary.seedStationMismatchForced_mm>2*w||R.summary.minSeedSpacing_mm<o.Hmin_mm
 R.stage='HOLD_GUIDE_CROSSING_UNPAIRED';R.message=sprintf('Forced-pair mismatch %.3g mm (limit 2w), min seed spacing %.3g mm (limit Hmin).',R.summary.seedStationMismatchForced_mm,R.summary.minSeedSpacing_mm);return
end
rimOrder=[32:-1:1,64:-1:34]';
bv=sort(o.BottomVertices_mm(:));tv=sort(o.TopVertices_mm(:),'descend');
assert(all(bv>xmin&bv<xmax&abs(bv-P(1,1))>w+1)&&all(tv>xmin&tv<xmax),'G2KExt:ExtraVertex','Extra vertex outside its edge or on the channel.');
bR=bv(bv>P(1,1));bL=bv(bv<P(1,1));
outer=[lowerSeed(1,:);[bR,ymin+0*bR];xmax,ymin;xmax,ymax;[tv,ymax+0*tv];xmin,ymax;xmin,ymin;[bL,ymin+0*bL]; ...
       upperSeed;Rv(rimOrder,:);flipud(lowerSeed(2:end,:))];
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
lipU=unique(nearestEdge(geom,samp(upperSeed)));lipL=unique(nearestEdge(geom,samp(lowerSeed)));
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
% ---- LP2-A2: every lip node is a seed, every seed carries one node; pairing by seed index
[okU,iU,dsU]=seedMatch(X0(un,:),upperSeed);[okL,iL,dsL]=seedMatch(X0(ln,:),lowerSeed);
R.summary.seedMaxDeviation_mm=max([dsU;dsL]);R.summary.lipNodesPerBank=[numel(un),numel(ln)];
if ~(okU&&okL)
 xU=X0(un(dsU>1e-7),:);xL=X0(ln(dsL>1e-7),:);
 R.unmatched=struct('upperXY',xU,'upperStation',stations(xU,upperPath,Sc),'lowerXY',xL,'lowerStation',stations(xL,lowerPath,Sc), ...
  'seedStations',seedS,'seedSegment',seedSeg,'stationsU',sU,'stationsL',sL);
 R.stage='HOLD_LIP_SEED_NOT_HONOURED';R.message=sprintf('Lip nodes %d/%d for %d seeds; max seed deviation %.3g mm.',numel(un),numel(ln),size(upperSeed,1),max([dsU;dsL]));return
end
un=un(iU);ln=ln(iL);sU=seedSU;sL=seedSL;   % node order = seed order on both banks
R.summary.pairStationResidual_mm=max(abs(stations(X0(un,:),upperPath,Sc)-stations(X0(ln,:),lowerPath,Sc)));
R.seedStations=seedS;R.seedStationsUL=[seedSU,seedSL];R.seedForced=SP.forced;R.seedSegment=seedSeg;R.seedXi=seedXi;R.upperSeed=upperSeed;R.lowerSeed=lowerSeed;
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
R.summary.pairCollapseResidual_mm=max(vecnorm(X(un,:)-X(ln,:),2,2));
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

function SP=seedPairs(PU,PL,mSeg,circ)
% common parametric stations xi = j/m_k on segment k of both banks; analytic guide-circle crossings
% replace the nearest interior regular seed (or are inserted if the nearest is a vertex)
ns=size(PU,1)-1;SP=struct('ok',true,'message','','nForced',0,'forcedSeg',[]);
cU=crossings(PU,circ);cL=crossings(PL,circ);   % rows [segment xi circle]
if size(cU,1)~=size(cL,1)||any(cU(:,1)~=cL(:,1))||any(cU(:,3)~=cL(:,3))
 SP.ok=false;SP.message=sprintf('Guide crossings upper %s / lower %s do not pair by circle and segment.',mat2str(cU,6),mat2str(cL,6));
 SP.QU=[];SP.QL=[];SP.seg=[];SP.xiU=[];SP.xiL=[];SP.forced=[];return
end
QU=PU(1,:);QL=PL(1,:);seg=1;xU=0;xL=0;fr=false;
for k=1:ns
 m=mSeg(k);a=(1:m-1)'/m;b=a;f=false(m-1,1);r=find(cU(:,1)==k);
 for q=r'
  j=round(.5*(cU(q,2)+cL(q,2))*m);
  if j>=1&&j<=m-1&&~f(j),a(j)=cU(q,2);b(j)=cL(q,2);f(j)=true;
  else,a=[a;cU(q,2)];b=[b;cL(q,2)];f=[f;true];end %#ok<AGROW>
 end
 [a,o]=sort(a);b=b(o);f=f(o);
 if ~issorted(b)||any(diff(b)<=0),SP.ok=false;SP.message=sprintf('Seed order differs between banks on segment %d.',k);end
 a=[a;1];b=[b;1];f=[f;false]; %#ok<AGROW>
 QU=[QU;PU(k,:)+a*(PU(k+1,:)-PU(k,:))];QL=[QL;PL(k,:)+b*(PL(k+1,:)-PL(k,:))]; %#ok<AGROW>
 sg=k*ones(numel(a),1);x1=a;x2=b;
 if k<ns,sg(end)=k+1;x1(end)=0;x2(end)=0;end   % segment end = start of the next segment
 seg=[seg;sg];xU=[xU;x1];xL=[xL;x2];fr=[fr;f]; %#ok<AGROW>
end
SP.QU=QU;SP.QL=QL;SP.seg=seg;SP.xiU=xU;SP.xiL=xL;SP.forced=fr;SP.nForced=nnz(fr);SP.forcedSeg=unique(cU(:,1));
end

function C=crossings(Pth,circ)
% analytic crossings (0<xi<1) of every path segment with every circle: rows [segment xi circle]
C=zeros(0,3);
for k=1:size(Pth,1)-1
 p=Pth(k,:);v=Pth(k+1,:)-p;
 for c=1:size(circ,1)
  d=p-circ(c,1:2);A=v*v.';B=2*(d*v.');Cq=d*d.'-circ(c,3)^2;D=B^2-4*A*Cq;
  if D>0
   x=sort([(-B-sqrt(D))/(2*A);(-B+sqrt(D))/(2*A)]);x=x(x>0&x<1);
   C=[C;[k+0*x,x,c+0*x]]; %#ok<AGROW>
  end
 end
end
C=sortrows(C,[1 2]);
end

function [ok,idx,dev]=seedMatch(X,S)
% each node within 1e-7 mm (inherited rim-vertex tolerance) of exactly one seed, each seed matched by exactly one node
D=hypot(X(:,1)-S(:,1).',X(:,2)-S(:,2).');[dev,j]=min(D,[],2);
ok=size(X,1)==size(S,1)&&all(dev<=1e-7)&&numel(unique(j))==size(S,1);idx=zeros(size(S,1),1);
if ok,idx(j)=(1:size(X,1))';end
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
