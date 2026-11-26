function W=g2_lp2b1_wp0(outDir,varargin)
%G2_LP2B1_WP0  Read-only reconstruction of the actual soft1 S10 mesh failure (geometry only, zero FEM).
%  W = g2_lp2b1_wp0(outDir)                    normal preflight (5 GiB guard unchanged) via g2_lp2a3_context
%  W = g2_lp2b1_wp0(outDir,'Preflight',false)  read-only replay (tests)
% outDir must NOT exist (attempt-specific, never overwritten) and must lie outside every historical
% run/ledger root. Nothing under outputs/g2_lp2a3_* is written. No mesh is generated.
% Steps:
%  1 LP2-A3 context (source digests, policy, 20 S8 + 24 WP5 pins) and the LP2-B1 pins file;
%  2 SHA-256 of the target FAILED_MESH, HOLD, soft1 S9 STATE, TERMINAL, ADMIT and the S9 MESH/PHASE/
%    SOLUTION; record manifests; links (S9 STATE -> files, HOLD/TERMINAL -> S9, ADMIT identity);
%  3 signed-MTS 4-mm forecast from the full-precision S9 STATE under the LP2-A3 policy; bitwise
%    comparison with the saved failed-mesh polyline and the TERMINAL candidate; expected tip/arc;
%    clearance + 1-mm guard recomputed on the S9 clearance geometry (gap, MATRIX_ADVANCE);
%  4 saved summary/gates of the failed join; independent metrics (g2_lp2b1_metrics) on the saved
%    X3/T3 compared with the saved summary in full precision;
%  5 every violating pair and the top-ranked pairs located (g2_lp2b1_locate); distribution;
%  6 optional zero-FEM comparison: the same independent metrics on every accepted LP2-A3 MESH.mat
%    (saved arrays only; no mesh generated);
%  7 X3/T3 exported as raw little-endian binaries (+SHA-256) for the Python cross-check.
ip=inputParser;addParameter(ip,'Preflight',true,@islogical);parse(ip,varargin{:});
assert(~isfolder(outDir),'G2LP2B1:HOLD_OVERWRITE','Output folder exists (attempt outputs are never overwritten): %s',outDir);
here=fileparts(mfilename('fullpath'));g2=fileparts(here);addpath(g2);addpath(fullfile(g2,'lp2'));addpath(fullfile(g2,'lp2a2'));addpath(fullfile(g2,'lp2a3'));
C=g2_lp2a3_context('Preflight',ip.Results.Preflight);repo=C.repo;pol=C.policy;
od=char(java.io.File(outDir).getCanonicalPath());
for r={'g2_lp2a3_paths_v1','g2_lp2a3_campaign_ledger','g2_lp2a_paths_v1','g2_lp2a_campaign_ledger','g2_lp2a2_eq_v1','g2_lp1_matrix_paths_v1'}
 hr=char(java.io.File(fullfile(repo,'outputs',r{1})).getCanonicalPath());
 assert(~startsWith(lower(od),lower(hr)),'G2LP2B1:HOLD_HISTORICAL_ROOT','Refusing to write under a historical root: %s',r{1});
end
pinsFile=fullfile(here,'G2_LP2B1_PINS_v1.json');pins=jsondecode(fileread(pinsFile));
assert(strcmp(C.policySHA256,pins.lp2a3.policySHA256)&&strcmpi(C.lp2a3SourceSHA256,pins.lp2a3.lp2a3SourceSHA256)&&strcmpi(C.lp2a2SourceSHA256,pins.lp2a3.lp2a2SourceSHA256) ...
 &&strcmpi(C.lp2SourceSHA256,pins.lp2a3.lp2SourceSHA256)&&strcmpi(C.g2SourceSHA256,pins.lp2a3.g2SourceSHA256),'G2LP2B1:HOLD_SOURCE','LP2-A3 policy or source digests differ from the LP2-B1 pins.');
rr=fullfile(repo,strrep(pins.lp2a3.runRoot,'/',filesep));lr=fullfile(repo,strrep(pins.lp2a3.ledgerRoot,'/',filesep));
tg=pins.target;fh=@(rel,root)lower(g2_sha256_file(fullfile(root,strrep(rel,'/',filesep))));
W=struct('schema','NewMetacomp.G2.LP2B1.WP0.v1','physicalSolves',0,'meshesGenerated',0,'pinsSHA256',lower(g2_sha256_file(pinsFile)), ...
 'lp2a3Token',C.token,'preflight',C.preflight,'checks',struct());
ck=struct();
% ---- 2 hashes, manifests, links
ck.failedMeshSHA=strcmp(fh(tg.failedMesh.path,rr),tg.failedMesh.sha256);
ck.holdSHA=strcmp(fh(tg.hold.path,rr),tg.hold.sha256);ck.parentStateSHA=strcmp(fh(tg.parentState.path,rr),tg.parentState.sha256);
ck.terminalSHA=strcmp(fh(tg.terminal.path,rr),tg.terminal.sha256);ck.admitSHA=strcmp(fh(tg.admit.path,lr),tg.admit.sha256);
ref1=pins.references(1);for f={'MESH','PHASE','SOLUTION'},ck.(['s9' f{1} 'SHA'])=strcmp(fh(ref1.(f{1}).path,rr),ref1.(f{1}).sha256);end
[S9,s9h,okS9]=g2_trajectory_record('read',fullfile(rr,'soft1','S9','STATE.mat'));
[Ho,~,okH]=g2_trajectory_record('read',fullfile(rr,'soft1','S10','HOLD.mat'));
[Tm,~,okT]=g2_trajectory_record('read',fullfile(rr,'soft1','TERMINAL.mat'));
[Ad,~,okA]=g2_trajectory_record('read',fullfile(lr,'ADMIT_soft1_S10.mat'));
ck.manifestsOK=okS9&&okH&&okT&&okA;
ck.s9Identity=S9.stateIndex==9&&strcmp(S9.caseId,'soft1')&&isequal(S9.mask(:).',[1 0 0])&&strcmp(S9.numericalStatus,'ACCEPTED');
ck.s9Links=strcmpi(S9.meshSHA256,ref1.MESH.sha256)&&strcmpi(S9.phaseSHA256,ref1.PHASE.sha256)&&strcmpi(S9.solutionSHA256,ref1.SOLUTION.sha256);
ck.s9ParentIsPinnedS8=strcmpi(S9.parentSHA256,pol.parents.S8.soft1.STATE);
ck.holdLinks=strcmpi(Ho.parentSHA256,s9h)&&Ho.stateIndex==10&&strcmp(Ho.identifier,'G2LP2A3:HOLD_MESH_QUALITY')&&~Ho.physicalArrest;
ck.terminalLinks=strcmpi(Tm.parentSHA256,s9h)&&strcmp(Tm.classification,'NUMERICAL_HOLD')&&Tm.lastAcceptedState==9&&~Tm.physicalArrest&&~Tm.interfaceEncounter;
adm=Ad;ck.admitIdentity=isfield(adm,'caseId')&&strcmp(adm.caseId,'soft1')&&adm.stateIndex==10;
% ---- 3 forecast, bitwise comparisons, clearance and guard
F=g2_lp2_forecast(S9,pol);P=F.polyline_mm;tip=P(end,:);
S=load(fullfile(rr,'soft1','S10','FAILED_MESH.mat'));fm=S.failedMesh;
ck.forecastEqualsFailedMeshPolyline=isequal(P,fm.crackPolyline);
ck.forecastEqualsTerminalCandidate=isequal(P,Tm.candidate.polyline_mm);
ck.tipEqualsExpected=isequal(tip,reshape(tg.expectedTip_mm,1,2));
ck.arcEqualsExpected=abs(F.arc_mm-tg.expectedArc_mm)<=1e-12;
Rc=g2_lp0_clearance(P(1:end-1,:),tip,S9.clearanceGeometry,pol);Tc=g2_lp2a3_classify(Rc,[1 0 0],pol,tip);
ck.classificationMatrixAdvance=strcmp(Tc.classification,tg.expectedClassification)&&strcmp(Tm.candidate.classification,'MATRIX_ADVANCE');
ck.ring1GapEqualsExpected=abs(Tc.ringProximity.gap_mm(1)-tg.expectedRing1GuideGap_mm)<=1e-12;
ck.ring1GapEqualsTerminalMetric=abs(Tc.ringProximity.gap_mm(1)-Tm.candidate.clearance.guideRingMargin_mm(1))<=1e-12;
W.target=struct('polyline_mm',P,'tip_mm',tip,'tangent',F.tangent,'arc_mm',F.arc_mm,'heading_deg',F.heading_deg,'parentMTS_deg',F.parentMTS_deg, ...
 'classification',Tc.classification,'guideRingGap_mm',Tc.ringProximity.gap_mm,'tipToRingCircle_mm',vecnorm(pol.geometry.centres_mm-tip,2,2).'-pol.geometry.ringR_mm, ...
 'clearanceMetrics',Rc.metrics,'seedSpacing_mm',fm.seedSpacing_mm,'seedRung',fm.seedRung);
% ---- 4 saved summary and independent metrics
g=fm.gates;gv=cell2mat(struct2cell(g));
Mi=g2_lp2b1_metrics(fm.X3,fm.T3,1.8);s=fm.summary;
ck.savedStage=strcmp(fm.stage,'HOLD_KINKED_PROTECTED_MESH_JOIN')&&~fm.pass&&isequal(fm.failedGates(:).',{'globalNeighborRatioAtMost1p8'});
ck.savedGates12of13=nnz(gv)==12&&numel(gv)==13;
ck.T3Equals=Mi.T3==tg.expectedSavedSummary.T3&&s.T3elements==Mi.T3;
ck.minAngleMatches=abs(Mi.minAngle_deg-s.minAngle_deg)<=1e-10&&abs(round(Mi.minAngle_deg,6)-tg.expectedSavedSummary.minAngle_deg)<1e-12;
ck.maxRatioMatches=abs(Mi.maxNeighborRatio-s.maxNeighborRatio)<=1e-12&&abs(round(Mi.maxNeighborRatio,6)-tg.expectedSavedSummary.maxNeighborRatio)<1e-12;
ck.areasPositive=Mi.allAreasPositive;ck.manifold=Mi.nonmanifoldEdges==0;
W.saved=struct('stage',fm.stage,'message',fm.message,'gates',g,'gatesPassed',nnz(gv),'gatesTotal',numel(gv),'summary',rmfield(s,intersect(fieldnames(s),{'exterior','block','polyline_mm'})), ...
 'exteriorControls',s.exterior.controls,'seedsPerSegment',s.exterior.seedsPerSegment,'guideCrossingPairs',s.exterior.guideCrossingPairs,'nativeT3',s.exterior.nativeT3);
W.independent=rmfield(Mi,{'h','longestLocalEdge','minAngleEl','twoArea','pairElements','pairNodes','pairRatio','pairOrderDesc','violationPairs','boundaryEdgeNodes','boundaryEdgeOwner','pairEdgeIsLongestOf'});
W.independent.minAngleDifferenceToSaved_deg=Mi.minAngle_deg-s.minAngle_deg;W.independent.maxRatioDifferenceToSaved=Mi.maxNeighborRatio-s.maxNeighborRatio;
W.independent.savedMaxRatioAt_mm=s.maxRatioAt_mm;
% ---- 5 location of every violation and of the top pairs
rows=struct('coreLast',fm.elementRows.core(end),'collarLast',fm.elementRows.collar(end));
ctx=struct('polyline_mm',P,'tip_mm',tip,'rows',rows,'centres_mm',pol.geometry.centres_mm,'ringR_mm',pol.geometry.ringR_mm,'holeR_mm',pol.geometry.holeR_mm, ...
 'guideR_mm',15,'collarR_mm',3.3,'coreR_mm',3.0,'plate_mm',pol.geometry.plate_mm,'extraVertexXY',fm.extraVertexXY);
W.violations=g2_lp2b1_locate(Mi,fm.X3,fm.T3,ctx,Mi.violationPairs);
top=Mi.pairOrderDesc(1:min(40,end));W.topPairs=g2_lp2b1_locate(Mi,fm.X3,fm.T3,ctx,top);
W.distribution=distribution(Mi,fm.X3,fm.T3,ctx);
% ---- 6 optional zero-FEM comparison with every accepted LP2-A3 mesh (saved arrays only)
cases={'H','stiff13','soft2','soft1'};A=struct('caseId',{},'state',{},'T3',{},'maxRatio',{},'maxRatioFace',{},'maxRatioDistTip_mm',{},'minAngle_deg',{},'above1p7',{},'above1p6',{},'savedMaxRatio',{});
for c=1:4
 for k=9:11
  mf=fullfile(rr,cases{c},sprintf('S%d',k),'MESH.mat');if ~isfile(mf),continue,end
  Dm=load(mf,'X3','T3','summary','elementRows','crackPolyline','extraVertexXY');Mm=g2_lp2b1_metrics(Dm.X3,Dm.T3,1.8);
  cx=ctx;cx.polyline_mm=Dm.crackPolyline;cx.tip_mm=Dm.crackPolyline(end,:);cx.extraVertexXY=Dm.extraVertexXY;
  Lm=g2_lp2b1_locate(Mm,Dm.X3,Dm.T3,cx,Mm.pairOrderDesc(1));
  A(end+1)=struct('caseId',cases{c},'state',k,'T3',Mm.T3,'maxRatio',Mm.maxNeighborRatio,'maxRatioFace',Lm.face,'maxRatioDistTip_mm',Lm.distTip_mm, ...
   'minAngle_deg',Mm.minAngle_deg,'above1p7',Mm.ratioCounts.above1p7,'above1p6',Mm.ratioCounts.above1p6,'savedMaxRatio',Dm.summary.maxNeighborRatio); %#ok<AGROW>
 end
end
W.acceptedMeshes=A;
% ---- 7 exports for the Python cross-check
mkdir(od);
writeBin(fullfile(od,'soft1_S10_failed_X3_f64le.bin'),double(fm.X3),'double');
writeBin(fullfile(od,'soft1_S10_failed_T3_i32le.bin'),int32(fm.T3),'int32');
W.exports=struct('X3',struct('file','soft1_S10_failed_X3_f64le.bin','rows',size(fm.X3,1),'cols',2,'sha256',lower(g2_sha256_file(fullfile(od,'soft1_S10_failed_X3_f64le.bin')))), ...
 'T3',struct('file','soft1_S10_failed_T3_i32le.bin','rows',size(fm.T3,1),'cols',3,'oneBased',true,'sha256',lower(g2_sha256_file(fullfile(od,'soft1_S10_failed_T3_i32le.bin')))), ...
 'rows',rows,'tip_mm',tip,'polyline_mm',P,'centres_mm',pol.geometry.centres_mm,'extraVertexXY',fm.extraVertexXY);
save(fullfile(od,'LP2B1_WP0_ARRAYS.mat'),'Mi','ctx','-v7.3');
v=cell2mat(struct2cell(ck));W.checks=ck;W.checksPassed=nnz(v);W.checksTotal=numel(v);W.pass=all(v);
fid=fopen(fullfile(od,'LP2B1_WP0.json'),'w');fwrite(fid,jsonencode(W,'PrettyPrint',true),'char');fclose(fid);
fprintf('G2_LP2B1_WP0 checks=%d/%d violations=%d maxRatio=%.15g minAngle=%.15g T3=%d\n',W.checksPassed,W.checksTotal,Mi.violations,Mi.maxNeighborRatio,Mi.minAngle_deg,Mi.T3);
end

function D=distribution(M,X3,T3,ctx)
% where do the high-ratio pairs sit: counts by face and region for several thresholds, distance-to-tip quantiles
th=[1.8 1.7 1.6 1.5];D=struct('threshold',{},'pairs',{},'byFace',{},'distTipMinMedMax_mm',{});
for t=th
 idx=find(M.pairRatio>t);if isempty(idx),D(end+1)=struct('threshold',t,'pairs',0,'byFace',struct(),'distTipMinMedMax_mm',[NaN NaN NaN]);continue,end %#ok<AGROW>
 L=g2_lp2b1_locate(M,X3,T3,ctx,idx);f={L.face};u=unique(f);bf=struct();
 for i=1:numel(u),bf.(matlab.lang.makeValidName(u{i}))=nnz(strcmp(f,u{i}));end
 dt=[L.distTip_mm];D(end+1)=struct('threshold',t,'pairs',numel(idx),'byFace',bf,'distTipMinMedMax_mm',[min(dt) median(dt) max(dt)]); %#ok<AGROW>
end
end

function writeBin(f,A,cls)
fid=fopen(f,'w','ieee-le');fwrite(fid,A.',cls);fclose(fid);   % row-major
end
