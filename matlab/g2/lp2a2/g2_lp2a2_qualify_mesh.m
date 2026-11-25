function Q=g2_lp2a2_qualify_mesh(execRepo,testSetFile,outFile,rowFilter,mesher)
%G2_LP2A2_QUALIFY_MESH  Geometry-only qualification of the LP2-A2 paired-bank mesher (zero FEM).
% For every row of the PREDECLARED test set (g2_lp2a2_testset) and with the unchanged LP1 options
% (TipGuideRadius 15 mm, TipGuideHface 1.5 mm, plate-edge vertices, 40,000-T3 budget):
%  NEW  g2_lp2a2_join -> g2_lp1_audit (kink-aware auditor 34 gates, T3 budget, bank adapter,
%       four-mask phase audit, phase re-map) -> g2_lp2a2_pairing_audit (P1-P10);
%  OLD  g2_kinked_join (unchanged inherited mesher) for the reproduction of the original failure
%       and the WP1 diagnosis (per-segment counts, first failing segment, bank, offset-length
%       difference, kink angles, distance to the tip and to the tip-guide crossing).
% Group A rows are also compared with the archived accepted S8 MESH.mat (old-mesher determinism and
% mesh-family differences). Meshes are held in memory only; nothing is written except outFile.
% mesher: 'join' (attempt 1: g2_lp2a2_join, seed spacing 0.45 mm) or 'ladder' (attempt 2:
% g2_lp2a2_mesh, predeclared seed-spacing ladder 0.45/0.40/0.50/0.35 mm).
here=fileparts(mfilename('fullpath'));
g2=fullfile(execRepo,'matlab','g2');addpath(g2,'-begin');addpath(fullfile(g2,'vendor_p010_a14d8872'),'-begin');addpath(here,'-begin');
lp=jsondecode(fileread(fullfile(g2,'G2_LP1_POLICY_v2.json')));Ca=struct('repo',execRepo,'here',g2,'policy',lp);
opts={'BottomVertices_mm',[25.4 482.6],'TopVertices_mm',254,'TipGuideRadius_mm',15,'TipGuideHface_mm',1.5};
if nargin<5||isempty(mesher),mesher='join';end
TS=jsondecode(fileread(testSetFile));rowsIn=TS.rows;if ~iscell(rowsIn),rowsIn=num2cell(rowsIn);end
if nargin>3&&~isempty(rowFilter),rowsIn=rowsIn(cellfun(@(r)any(strcmp(r.id,rowFilter)),rowsIn));end
base=fullfile(execRepo,'outputs','g2_lp2a_paths_v1','run_lp2a_s5_s8_v1');
out=cell(numel(rowsIn),1);
for i=1:numel(rowsIn)
 r0=rowsIn{i};P=r0.polyline_mm;t=reshape(r0.tangent,1,2);N=size(P,1);
 r=struct('id',r0.id,'group',r0.group,'caseId',r0.caseId,'label',r0.label,'vertices',N,'state',N-2,'arc_mm',r0.arc_mm,'guardRow',r0.guardRow);
cen=lp.geometry.centres_mm;r.tip_mm=P(end,:);r.tipToRingCircle_mm=vecnorm(cen-P(end,:),2,2).'-19.05;r.polylineToRingCircle_mm=polyRing(P,cen)-19.05;
 % ---------------- NEW mesher
 n=struct('pass',false);tm=tic;
 try
  if strcmp(mesher,'ladder')
   [~,D]=evalc('g2_lp2a2_mesh(P,''ExpectedVertices'',N,''ExpectedTangent'',t,''ExteriorOptions'',opts,''MaxT3Elements'',40000)');
   n.seedRung=D.seedRung;n.seedSpacing_mm=D.seedSpacing_mm;n.ladder=D.ladder;
  else
   [~,D]=evalc('g2_lp2a2_join(P,''ExpectedVertices'',N,''ExpectedTangent'',t,''ExteriorOptions'',opts,''MaxT3Elements'',40000)');
  end
  n.joinSeconds=toc(tm);n.stage=D.stage;n.message=D.message;
  if isfield(D,'exterior')&&isfield(D.exterior,'summary'),n.exterior=pick(D.exterior.summary,{'seedsPerSegment','seedCount','guideCrossingPairs','guideCrossingSegments', ...
    'seedStationMismatchRegular_mm','seedStationMismatchForced_mm','minSeedSpacing_mm','seedMaxDeviation_mm','lipNodesPerBank','lipPairs', ...
    'lipStationMismatch_mm','pairStationResidual_mm','pairCollapseResidual_mm','nativeT3','nativeMeshingSeconds','lipMaxStationGap_mm'});end
  if D.pass
   D.tipTangent=t;n.T3=size(D.T3,1);n.T6nodes=size(D.X6,1);n.DOF=2*size(D.X6,1);
   n.minAngle_deg=D.summary.minAngle_deg;n.maxNeighborRatio=D.summary.maxNeighborRatio;n.joinGatesFailed=D.failedGates;
   ta=tic;
   try
    [~,A,PM]=evalc('g2_lp1_audit(D,N-2,Ca)');
    n.auditGates=sprintf('%d/%d',A.meshAudit.gatesPassed,A.meshAudit.gatesTotal);n.auditFailed=A.meshAudit.failedGates;
    n.auditSummary=pick(A.meshAudit.summary,{'Euler','boundaryComponents','crackEdgesPerSide','bankNodesPerSide','minAngle_deg','maxNeighborRatio', ...
     'minJacobian_mm2','maxMidsideError_mm','qActive','qSupportMaxRadius_mm','qSupportDistanceToKink_mm','materialArea_mm2','analyticArea_mm2'});
    g=A.meshAudit.gates;f=fieldnames(g);k=~cellfun(@isempty,regexpi(f,'q|collar|rim|core|kernel|seam'));
    n.qCollarGates=cell2struct(struct2cell(g),f,1);n.qCollarGates=rmfield(n.qCollarGates,f(~k));n.qCollarPass=all(cellfun(@(x)x,struct2cell(n.qCollarGates)));
    cs=fieldnames(A.cases);n.phaseMasks=struct();for q=1:numel(cs),n.phaseMasks.(cs{q})=A.cases.(cs{q}).pass;end
    n.phaseAuditPass=A.pass;n.phaseMapPass=PM.pass;n.auditPass=A.pass&&PM.pass&&A.meshAudit.gatesPassed==34;
   catch ME
    n.auditPass=false;n.auditError=[ME.identifier ': ' ME.message];n.ringPolygons=ringPolys(D.X6,cen);
   end
   n.auditSeconds=toc(ta);
   PA=g2_lp2a2_pairing_audit(D);n.pairing=PA;
   if strcmp(mesher,'ladder'),n.forcedPairs=g2_lp2a2_forced_pair_audit(D);end
   n.pass=n.auditPass&&PA.pass;
  end
 catch ME
  n.stage='ERROR';n.message=[ME.identifier ': ' ME.message];
 end
 n.totalSeconds=toc(tm);n.memUsedMATLAB_GiB=memGiB();r.new=n;
 clear D A PM
 % ---------------- OLD mesher (reproduction / diagnosis)
 o=struct();tm=tic;
 try
  [~,D]=evalc('g2_kinked_join(P,''ExpectedVertices'',N,''ExpectedTangent'',t,''ExteriorOptions'',opts,''MaxT3Elements'',40000)');
  o.pass=D.pass;o.stage=D.stage;o.message=D.message;o.seconds=toc(tm);
  if isfield(D,'exterior')&&isfield(D.exterior,'summary')
   es=D.exterior.summary;o.exterior=pick(es,{'lipInteriorNodesPerSegment','lipStationMismatch_mm','lipPairs','lipMaxStationGap_mm','nativeT3'});
   if isfield(es,'lipInteriorNodesPerSegment'),o.diagnosis=diagnose(P,es.lipInteriorNodesPerSegment);end
  end
  if D.pass,o.T3=size(D.T3,1);o.T6nodes=size(D.X6,1);o.minAngle_deg=D.summary.minAngle_deg;o.maxNeighborRatio=D.summary.maxNeighborRatio;
   o.bankNodesT6=[numel(D.upperBankT6),numel(D.lowerBankT6)];end
  if strcmp(r0.group,'A')
   M=load(fullfile(base,r0.caseId,'S8','MESH.mat'),'X3','T3','upperBankT6','lowerBankT6','exterior');
   o.archived=struct('T3',size(M.T3,1),'bankNodesT6',[numel(M.upperBankT6),numel(M.lowerBankT6)],'lipStationMismatch_mm',M.exterior.summary.lipStationMismatch_mm, ...
    'lipInteriorNodesPerSegment',M.exterior.summary.lipInteriorNodesPerSegment,'oldRerunIdenticalX3T3',D.pass&&isequal(D.X3,M.X3)&&isequal(D.T3,M.T3));
  end
 catch ME
  o.pass=false;o.stage='ERROR';o.message=[ME.identifier ': ' ME.message];
 end
 r.old=o;clear D M
 out{i}=r;
 fprintf('LP2A2_QUAL %-28s N=%-2d new=%d %-34s T3=%-6s pair=%s | old=%d %s\n',r.id,N,n.pass,n.stage,num2str(getf(n,'T3')),num2str(isfield(n,'pairing')&&n.pairing.pass),o.pass,o.stage);
end
Q=struct('schema','NewMetacomp.G2.LP2A2.MeshQualification.v1','physicalSolves',0,'meshesSaved',0,'testSetSHA256',lower(g2_sha256_file(testSetFile)),'mesher',mesher, ...
 'options',struct('TipGuideRadius_mm',15,'TipGuideHface_mm',1.5,'MaxT3Elements',40000,'lipHedge_mm',.45),'rows',{out});
if nargin>2&&~isempty(outFile),fid=fopen(outFile,'w');fwrite(fid,jsonencode(Q,'PrettyPrint',true),'char');fclose(fid);end
end

function d=diagnose(P,cnt)
% per-segment facts for an old-mesher result: counts, offset lengths, kink angles, tip distance
w=.020;ro=3.3;N=size(P,1);tt=diff(P);L=vecnorm(tt,2,2);tt=tt./L;nn=[-tt(:,2),tt(:,1)];
m=zeros(N,2);m(1,:)=nn(1,:);for k=2:N-1,m(k,:)=(nn(k-1,:)+nn(k,:))/(1+dot(tt(k-1,:),tt(k,:)));end
Cend=P(end,:)-ro*tt(end,:);U=[P(1:N-1,:)+w*m(1:N-1,:);Cend+w*nn(end,:)];Lw=[P(1:N-1,:)-w*m(1:N-1,:);Cend-w*nn(end,:)];
LU=vecnorm(diff(U),2,2);LL=vecnorm(diff(Lw),2,2);Lc=L;Lc(end)=L(end)-ro;
turn=zeros(N,1);for k=2:N-1,turn(k)=atan2d(tt(k-1,1)*tt(k,2)-tt(k-1,2)*tt(k,1),dot(tt(k-1,:),tt(k,:)));end
Sv=[0;cumsum(L)];arc=Sv(end);
gtSeg=find(vecnorm(P(1:end-1,:)-P(end,:),2,2)>15&vecnorm(P(2:end,:)-P(end,:),2,2)<=15,1);
bad=find(cnt(:,1)~=cnt(:,2));
d=struct('segmentLength_mm',Lc(:).','upperMinusLowerLength_mm',(LU-LL).','kinkTurn_deg',turn(2:N-1).','countsU',cnt(:,1).','countsL',cnt(:,2).', ...
 'failingSegments',bad(:).','firstFailingSegment',min([bad;NaN]),'fewerOnUpper',all(cnt(bad,1)<cnt(bad,2)), ...
 'distanceSegmentEndToTip_mm',(arc-Sv(2:end)).','tipGuideCrossingSegment',gtSeg,'nSegments',N-1);
end

function d=polyRing(P,cen)
d=inf(1,3);for k=1:3,for s=1:size(P,1)-1,v=P(s+1,:)-P(s,:);l=max(0,min(1,(cen(k,:)-P(s,:))*v.'/(v*v.')));d(k)=min(d(k),norm(P(s,:)+l*v-cen(k,:)));end,end
end

function R=ringPolys(X,cen)
% diagnostic only: nodes on each ring circle (|r-19.05|<=1e-6), centroid offset, chord-length spread
R=struct('nodes',zeros(1,3),'vertexMeanOffset_mm',zeros(1,3),'chordMinMax_mm',zeros(3,2));
for k=1:3
 v=find(abs(vecnorm(X-cen(k,:),2,2)-19.05)<=1e-6);a=atan2(X(v,2)-cen(k,2),X(v,1)-cen(k,1));[~,o]=sort(a);v=v(o);
 R.nodes(k)=numel(v);R.vertexMeanOffset_mm(k)=norm(mean(X(v,:),1)-cen(k,:));c=vecnorm(X(v,:)-X(circshift(v,-1),:),2,2);R.chordMinMax_mm(k,:)=[min(c),max(c)];
end
end

function s=pick(S,f)
s=struct();for k=1:numel(f),if isfield(S,f{k}),s.(f{k})=S.(f{k});end,end
end
function v=getf(s,f)
if isfield(s,f),v=s.(f);else,v='';end
end
function g=memGiB()
try,[u,~]=memory;g=u.MemUsedMATLAB/2^30;catch,g=NaN;end
end
