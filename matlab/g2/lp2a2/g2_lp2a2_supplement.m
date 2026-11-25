function S=g2_lp2a2_supplement(execRepo,testSetFile,attempt2File,outFile)
%G2_LP2A2_SUPPLEMENT  Supplementary geometry-only diagnostics requested before the final LP2-A2
% assessment (zero FEM, meshes in memory, writes only outFile):
%  (1) every non-guard test row is meshed again with the ladder (g2_lp2a2_mesh): determinism check
%      against attempt 2 (same rung, same T3, same node coordinates hash) and, for every accepted
%      mesh, the forced guide-crossing pair audit (g2_lp2a2_forced_pair_audit);
%  (2) every row whose attempt-2 outcome is not a pass: each ladder rung separately AND the
%      inherited mesher, with the failed gates and the location of the worst element (minimum angle,
%      maximum neighbour ratio) and its distances to the tip, the tip-guide circle, the ring
%      circles and the crack; for audit failures the ring-polygon diagnostics.
g2=fullfile(execRepo,'matlab','g2');addpath(g2,'-begin');addpath(fullfile(g2,'vendor_p010_a14d8872'),'-begin');addpath(fileparts(mfilename('fullpath')),'-begin');
lp=jsondecode(fileread(fullfile(g2,'G2_LP1_POLICY_v2.json')));Ca=struct('repo',execRepo,'here',g2,'policy',lp);cen=lp.geometry.centres_mm;
opts={'BottomVertices_mm',[25.4 482.6],'TopVertices_mm',254,'TipGuideRadius_mm',15,'TipGuideHface_mm',1.5};
TS=jsondecode(fileread(testSetFile));rows=TS.rows;if ~iscell(rows),rows=num2cell(rows);end
A2=jsondecode(fileread(attempt2File));a2=A2.rows;if ~iscell(a2),a2=num2cell(a2);end
out={};
for i=1:numel(rows)
 r0=rows{i};if r0.guardRow,continue,end
 q=a2{cellfun(@(x)strcmp(x.id,r0.id),a2)};P=r0.polyline_mm;t=reshape(r0.tangent,1,2);N=size(P,1);tip=P(end,:);
 r=struct('id',r0.id,'caseId',r0.caseId,'state',N-2,'attempt2Pass',logical(q.new.pass));
 [~,D]=evalc('g2_lp2a2_mesh(P,''ExpectedVertices'',N,''ExpectedTangent'',t,''ExteriorOptions'',opts,''MaxT3Elements'',40000)');
 r.rung=D.seedRung;r.stage=D.stage;
 if isfield(D,'T3'),r.T3=size(D.T3,1);r.coordHash=lower(g2_lp1_digest(sprintf('%.17g,',D.X3(:))));else,r.T3=NaN;r.coordHash='';end
 r.deterministic=isfield(q.new,'seedRung')&&isequal(r.rung,q.new.seedRung)&&(~isfield(q.new,'T3')||isequal(r.T3,q.new.T3));
 if D.pass||strcmp(D.stage,'KINKED_PROTECTED_MESH_JOIN_PASS'),r.forcedPairs=g2_lp2a2_forced_pair_audit(D);end
 if ~q.new.pass
  rr={};
  for hs=[0.45 0.40 0.50 0.35]
   [~,Dj]=evalc('g2_lp2a2_join(P,''ExpectedVertices'',N,''ExpectedTangent'',t,''ExteriorOptions'',[opts,{''SeedSpacing_mm'',hs}],''MaxT3Elements'',40000)');
   rr{end+1}=where(Dj,hs,P,tip,cen,Ca,N); %#ok<AGROW>
  end
  [~,Do]=evalc('g2_kinked_join(P,''ExpectedVertices'',N,''ExpectedTangent'',t,''ExteriorOptions'',opts,''MaxT3Elements'',40000)');
  r.rungs=rr;r.old=where(Do,NaN,P,tip,cen,Ca,N);
 end
 out{end+1}=r; %#ok<AGROW>
 fprintf('LP2A2_SUPP %-28s rung=%d det=%d forced=%s fail-diag=%d\n',r.id,r.rung,r.deterministic,num2str(isfield(r,'forcedPairs')&&r.forcedPairs.pass),~q.new.pass);
end
S=struct('schema','NewMetacomp.G2.LP2A2.Supplement.v1','physicalSolves',0,'testSetSHA256',lower(g2_sha256_file(testSetFile)),'attempt2SHA256',lower(g2_sha256_file(attempt2File)),'rows',{out});
if nargin>3&&~isempty(outFile),fid=fopen(outFile,'w');fwrite(fid,jsonencode(S,'PrettyPrint',true),'char');fclose(fid);end
end

function w=where(D,hs,P,tip,cen,Ca,N)
w=struct('seedSpacing_mm',hs,'stage',D.stage,'message',D.message);
s=D.summary;
if isfield(s,'minAngle_deg')
 w.minAngle_deg=s.minAngle_deg;w.maxNeighborRatio=s.maxNeighborRatio;
 w.minAngleAt=loc(s.minAngleAt_mm,P,tip,cen);w.maxRatioAt=loc(s.maxRatioAt_mm,P,tip,cen);
end
if D.pass
 D.tipTangent=reshape(P(end,:)-P(end-1,:),1,2)/norm(P(end,:)-P(end-1,:));
 try,[~,A,PM]=evalc('g2_lp1_audit(D,N-2,Ca)');w.auditPass=A.pass&&PM.pass&&A.meshAudit.gatesPassed==34;
 catch ME,w.auditPass=false;w.auditError=ME.message;w.ringPolygons=ringPolys(D.X6,cen);end
end
end
function L=loc(p,P,tip,cen)
d=inf;for s=1:size(P,1)-1,v=P(s+1,:)-P(s,:);l=max(0,min(1,(p-P(s,:))*v.'/(v*v.')));d=min(d,norm(P(s,:)+l*v-p));end
rc=vecnorm(cen-p,2,2).'-19.05;
L=struct('xy',p,'toTip_mm',norm(p-tip),'toTipGuideCircle_mm',norm(p-tip)-15,'toRingCircles_mm',rc,'toCrack_mm',d);
end
function R=ringPolys(X,cen)
R=struct('nodes',zeros(1,3),'vertexMeanOffset_mm',zeros(1,3),'chordMinMax_mm',zeros(3,2));
for k=1:3
 v=find(abs(vecnorm(X-cen(k,:),2,2)-19.05)<=1e-6);a=atan2(X(v,2)-cen(k,2),X(v,1)-cen(k,1));[~,o]=sort(a);v=v(o);
 R.nodes(k)=numel(v);R.vertexMeanOffset_mm(k)=norm(mean(X(v,:),1)-cen(k,:));c=vecnorm(X(v,:)-X(circshift(v,-1),:),2,2);R.chordMinMax_mm(k,:)=[min(c),max(c)];
end
end
