function R=g2_lp2b1_attempt(name,P,t,k,hs,mask,nominalGeom,base,outRoot,C)
%G2_LP2B1_ATTEMPT  One geometry-only mesh attempt of LP2-B1 at a FIXED polyline (zero FEM).
%  R = g2_lp2b1_attempt(name,P,t,k,hs,mask,nominalGeom,base,outRoot,C)
% name         attempt identity (folder outRoot/name must not exist; never overwritten)
% P,t,k        fixed polyline, tip tangent, state index (ExpectedVertices = k+2)
% hs           bank seed spacing (mm) passed to the UNCHANGED g2_lp2a2_join exactly as rung k of
%              g2_lp2a2_mesh does: ExteriorOptions = [LP2-A3 options, {'SeedSpacing_mm',hs}]
% mask         ring mask of the case (phase/owner/guard attribution)
% nominalGeom  clearance geometry of the parent state (inherited nominal clearance)
% base         struct with the baseline arrays (saved failed mesh or original accepted MESH) for the
%              protected core / collar / q comparison
% C            g2_lp2a3_context (policy, digests, repo)
% Gates (none relaxed): join 13/13; independent metrics (g2_lp2b1_metrics) agree with the join;
% pairing P1-P10; g2_lp1_audit (kinked auditor 34/34, T3 budget, bank adapter, four-mask phase
% audit, owner re-map); 76 chords per ring circle; actual-polygon clearance and the 1-mm guide-to-
% every-ring guard (g2_lp2a3_classify) = MATRIX_ADVANCE; nominal clearance on the parent geometry;
% exact polyline/tangent; protected block (core 2788 + collar 128 T3 rows, block nodes), T6 core rows,
% q field and 2443 active q parents identical to the baseline; every inherited q annulus inside
% the core. Saves the canonical arrays and a JSON summary; no solve, no record in a historical root.
assert(isvarname(strrep(name,'-','_')),'G2LP2B1:HOLD_INPUT','Bad attempt name.');
od=fullfile(outRoot,name);assert(~isfolder(od),'G2LP2B1:HOLD_OVERWRITE','Attempt folder exists: %s',od);
pol=C.policy;op=pol.meshFamily.ExteriorOptions;
xo={'BottomVertices_mm',op.BottomVertices_mm(:).','TopVertices_mm',op.TopVertices_mm,'TipGuideRadius_mm',op.TipGuideRadius_mm,'TipGuideHface_mm',op.TipGuideHface_mm};
R=struct('schema','NewMetacomp.G2.LP2B1.Attempt.v1','name',name,'stateIndex',k,'mask',reshape(mask,1,3),'seedSpacing_mm',hs, ...
 'physicalSolves',0,'polyline_mm',P,'tangent',t,'stage','','message','','joinPass',false,'joinGatesPassed',0,'joinGatesTotal',13, ...
 'failedGates',{{}},'qualityOnlyFailure',false,'pass',false,'checks',struct(),'startedUTC',utc());
tm=tic;
[~,D]=evalc('g2_lp2a2_join(P,''ExpectedVertices'',k+2,''ExpectedTangent'',t,''ExteriorOptions'',[xo,{''SeedSpacing_mm'',hs}],''MaxT3Elements'',op.MaxT3Elements)');
R.joinSeconds=toc(tm);R.stage=D.stage;R.message=D.message;fg=D.failedGates;if isempty(fg),fg={};end;R.failedGates=fg(:).';
if isfield(D,'gates')&&~isempty(fieldnames(D.gates)),gv=cell2mat(struct2cell(D.gates));R.joinGates=D.gates;R.joinGatesPassed=nnz(gv);R.joinGatesTotal=numel(gv);end
R.qualityOnlyFailure=strcmp(D.stage,'HOLD_KINKED_PROTECTED_MESH_JOIN')&&~isempty(fg)&&all(ismember(fg,{'globalMinAngleAtLeast20','globalNeighborRatioAtMost1p8'}));
if isfield(D,'exterior')&&isfield(D.exterior,'summary'),es=D.exterior.summary;R.exterior=pickf(es,{'seedSpacing_mm','seedsPerSegment','seedCount','guideCrossingPairs', ...
  'seedStationMismatchForced_mm','minSeedSpacing_mm','lipPairs','pairCollapseResidual_mm','nativeT3','nativeMeshingSeconds','controls'});end
mkdir(od);
if ~isfield(D,'X3')
 R.pass=false;R.endedUTC=utc();writeJ(od,R);return
end
R.joinPass=D.pass;R.T3=size(D.T3,1);R.T6nodes=size(D.X6,1);R.summary=pickf(D.summary,{'T3elements','T3nodes','T6nodes','minAngle_deg','minAngleAt_mm','maxNeighborRatio','maxRatioAt_mm', ...
 'crackBankEdgesPerSide','bankT6NodesPerSide','qActiveT6','tip_mm','tangent','kinkNodeIDs'});
% ---- independent metrics and location of the worst pairs (also for failed joins)
Mi=g2_lp2b1_metrics(D.X3,D.T3,1.8);rows=struct('coreLast',D.elementRows.core(end),'collarLast',D.elementRows.collar(end));
ctx=struct('polyline_mm',P,'tip_mm',P(end,:),'rows',rows,'centres_mm',pol.geometry.centres_mm,'ringR_mm',pol.geometry.ringR_mm,'holeR_mm',pol.geometry.holeR_mm, ...
 'guideR_mm',15,'collarR_mm',3.3,'coreR_mm',3.0,'plate_mm',pol.geometry.plate_mm,'extraVertexXY',D.extraVertexXY);
R.independent=struct('T3',Mi.T3,'minAngle_deg',Mi.minAngle_deg,'maxNeighborRatio',Mi.maxNeighborRatio,'violations',Mi.violations,'ratioCounts',Mi.ratioCounts, ...
 'allAreasPositive',Mi.allAreasPositive,'nonmanifoldEdges',Mi.nonmanifoldEdges,'euler',Mi.euler);
R.worstPairs=g2_lp2b1_locate(Mi,D.X3,D.T3,ctx,Mi.pairOrderDesc(1:min(5,end)));
if Mi.violations>0,R.violations=g2_lp2b1_locate(Mi,D.X3,D.T3,ctx,Mi.violationPairs);end
ck=struct();
ck.independentAgreesWithJoin=Mi.T3==D.summary.T3elements&&abs(Mi.maxNeighborRatio-D.summary.maxNeighborRatio)<=1e-12&&abs(Mi.minAngle_deg-D.summary.minAngle_deg)<=1e-10;
ck.join13=D.pass&&R.joinGatesPassed==13&&R.joinGatesTotal==13;
% ---- protected block, q field and q annuli versus the baseline (meaningful for any joined mesh)
nB=D.block.kernelNodes+65;nBlk=D.elementRows.collar(end);
ck.blockT3RowsIdentical=isequal(D.T3(1:nBlk,:),base.T3(1:nBlk,:))&&nBlk==2916&&D.elementRows.core(end)==2788;
ck.blockNodesIdentical=isequal(D.X3(1:nB,:),base.X3(1:nB,:));
% Amendment A1: T6 midside IDs are numbered over the whole mesh (T3toT6_fast), so block T6 rows are
% compared by vertex IDs (columns 1-3, = T3 IDs) and by the COORDINATES of all six nodes of every
% block element; nodal q is compared at those positions (the ID-based v1 checks were ill-posed).
T6b=D.T6(1:nBlk,:);T6r=base.T6(1:nBlk,:);cn=unique(T6b);
ck.coreT6VertexRowsIdentical=isequal(T6b(:,1:3),T6r(:,1:3));
ck.coreT6NodeCoordinatesIdentical=isequal(D.X6(T6b,:),base.X6(T6r,:));
ck.qActive2443Identical=numel(D.qActiveT6Rows)==2443&&isequal(D.qActiveT6Rows,base.qActiveT6Rows);
ck.nodalQOnBlockIdentical=isequal(D.nodalQ(T6b),base.nodalQ(T6r))&&all(D.nodalQ(setdiff(1:numel(D.nodalQ),cn))==0);
R.T6blockMidsideIDsIdentical_informative=isequal(T6b,T6r);
qa=pol.qAnnuli_mm;tip=P(end,:);r6=vecnorm(D.X6-tip,2,2);qOK=true;qn=zeros(size(qa,1),1);
for j=1:size(qa,1)
 a=qa(j,1);b=qa(j,2);q=ones(size(r6));q(r6>=b)=0;tr=r6>a&r6<b;q(tr)=(b-r6(tr))/(b-a);
 act=find(max(q(D.T6),[],2)-min(q(D.T6),[],2)>1e-14);qn(j)=numel(act);
 qOK=qOK&&all(act<=D.elementRows.core(end))&&max(r6(unique(D.T6(act,:))))<3*cos(pi/64);
end
ck.allQAnnuliInsideCore=qOK;R.qAnnuliActiveRows=qn.';
R.tangentFrameMinusInput=norm(D.tipTangent(:).'-t(:).');ck.exactPolylineTangent=isequal(D.crackPolyline,P)&&R.tangentFrameMinusInput<=1e-12;
R.blockCompare=struct('blockNodes',nB,'blockT3',nBlk,'coreT6Nodes',numel(cn));
% ---- exterior differences versus the baseline (informative)
R.exteriorVsBaseline=struct('T3',[size(base.T3,1),size(D.T3,1)],'exteriorT3',[size(base.T3,1)-nBlk,size(D.T3,1)-nBlk], ...
 'maxRatio',[base.maxRatio,Mi.maxNeighborRatio],'minAngle_deg',[base.minAngle,Mi.minAngle_deg]);
% ---- pairing and inherited audits (joined meshes that pass the join only)
if D.pass
 PA=g2_lp2a2_pairing_audit(D);R.pairing=struct('pass',PA.pass,'gatesPassed',PA.gatesPassed,'gatesTotal',PA.gatesTotal,'failedGates',{PA.failedGates},'metrics',PA.metrics);
 ck.pairingP1toP10=PA.pass&&PA.gatesPassed==10;
 D.tipTangent=t;Caud=struct('repo',C.repo,'here',C.here,'policy',C.lp2Policy);
 auditOK=false;
 try   % only the inherited audits and clearance calls (which assert) are inside the try
  [~,A,PM]=evalc('g2_lp1_audit(D,k,Caud)');
  Ra=g2_lp0_clearance(P(1:end-1,:),P(end,:),A.clearanceGeometry,pol);Ta=g2_lp2a3_classify(Ra,mask,pol,P(end,:));
  Rn=g2_lp0_clearance(P(1:end-1,:),P(end,:),nominalGeom,pol);Tn=g2_lp2a3_classify(Rn,mask,pol,P(end,:));
  auditOK=true;
 catch ME
  R.auditError=[ME.identifier ': ' ME.message];
  for f={'kinkedAudit34','phaseAuditFourMasks','ownerReMap','chords76','T3Budget','actualClearanceMatrixAdvance','nominalClearanceMatrixAdvance','guide1mmEveryRing'},ck.(f{1})=false;end
 end
 if auditOK   % bookkeeping outside the try: a defect here raises instead of being recorded as an audit failure
  ck.kinkedAudit34=A.meshAudit.gatesPassed==34&&A.meshAudit.gatesTotal==34&&A.meshAudit.pass;
  cs=fieldnames(A.cases);pm=struct();for q=1:numel(cs),pm.(cs{q})=A.cases.(cs{q}).pass;end
  ck.phaseAuditFourMasks=A.pass&&numel(cs)==4&&all(cellfun(@(x)x,struct2cell(pm)));ck.ownerReMap=PM.pass;
  chords=arrayfun(@(q)size(q.chords,1),PM.interfaces);ck.chords76=isequal(chords(:).',[76 76 76]);
  ck.T3Budget=size(D.T3,1)<=op.MaxT3Elements;
  ck.actualClearanceMatrixAdvance=Ra.pass&&strcmp(Ta.classification,'MATRIX_ADVANCE');
  ck.nominalClearanceMatrixAdvance=Rn.pass&&strcmp(Tn.classification,'MATRIX_ADVANCE');
  ck.guide1mmEveryRing=Ta.ringProximity.pass&&Ta.ringProximity.minGap_mm>=1;
  rn=ringNodes(D.X6,pol);rb=ringNodes(base.X6,pol);
  R.audit=struct('meshAudit',sprintf('%d/%d',A.meshAudit.gatesPassed,A.meshAudit.gatesTotal),'failed',{A.meshAudit.failedGates},'phaseMasks',pm, ...
   'chordsPerCircle',chords(:).','actualClassification',Ta.classification,'nominalClassification',Tn.classification,'guideRingGap_mm',Ta.ringProximity.gap_mm, ...
   'actualClearance',Ra.metrics,'ringNodeCounts',cellfun(@(x)size(x,1),rn),'ringPolygonsIdenticalToBaseline',isequal(rn,rb));
 end
end
R.checks=ck;v=cell2mat(struct2cell(ck));R.checksPassed=nnz(v);R.checksTotal=numel(v);
R.pass=D.pass&&all(v)&&R.checksTotal==19;
R.canonicalSHA256=canon(D);R.endedUTC=utc();
X3=D.X3;T3=D.T3;X6=D.X6;T6=D.T6;upperBankT6=D.upperBankT6;lowerBankT6=D.lowerBankT6;nodalQ=D.nodalQ;qActiveT6Rows=D.qActiveT6Rows; %#ok<NASGU>
elementRows=D.elementRows;crackPolyline=D.crackPolyline;summary=D.summary;gates=D.gates;extraVertexXY=D.extraVertexXY;physicalTipNode=D.physicalTipNode; %#ok<NASGU>
save(fullfile(od,'ATTEMPT_ARRAYS.mat'),'X3','T3','X6','T6','upperBankT6','lowerBankT6','nodalQ','qActiveT6Rows','elementRows','crackPolyline','summary','gates','extraVertexXY','physicalTipNode','-v7.3');
R.arraysFileSHA256=lower(g2_sha256_file(fullfile(od,'ATTEMPT_ARRAYS.mat')));
writeJ(od,R);
fprintf('G2_LP2B1_ATTEMPT %s hs=%.2f stage=%s join=%d/%d T3=%d minAng=%.6f ratio=%.6f checks=%d/%d pass=%d\n',name,hs,R.stage,R.joinGatesPassed,R.joinGatesTotal,R.T3,Mi.minAngle_deg,Mi.maxNeighborRatio,R.checksPassed,R.checksTotal,R.pass);
end

function h=canon(D)
% SHA-256 over the canonical numeric arrays (not MAT bytes, which carry timestamps)
md=java.security.MessageDigest.getInstance('SHA-256');
f={'X3','T3','X6','T6','upperBankT6','lowerBankT6','nodalQ','qActiveT6Rows','crackPolyline'};
for i=1:numel(f),a=double(D.(f{i}));md.update(typecast(int64(size(a)),'uint8'));md.update(typecast(a(:),'uint8'));end
h=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
end
function N=ringNodes(X,pol)
c=pol.geometry.centres_mm;N=cell(1,3);
for i=1:3,d=abs(vecnorm(X-c(i,:),2,2)-pol.geometry.ringR_mm);v=find(d<=1e-6);a=atan2(X(v,2)-c(i,2),X(v,1)-c(i,1));[~,o]=sort(a);N{i}=X(v(o),:);end
end
function s=pickf(S,f)
s=struct();for k=1:numel(f),if isfield(S,f{k}),s.(f{k})=S.(f{k});end,end
end
function writeJ(od,R)
fid=fopen(fullfile(od,'ATTEMPT.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
end
function s=utc()
s=char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss.SSS''Z'''));
end
