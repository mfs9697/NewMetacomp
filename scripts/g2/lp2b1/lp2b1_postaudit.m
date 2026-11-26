function A=lp2b1_postaudit(ex,outDir)
%LP2B1_POSTAUDIT  Read-only re-audit of the SAVED LP2-B1 attempt arrays (zero FEM, no mesh generated).
%  A = lp2b1_postaudit(execRepo,outDir)      outDir must not exist
% For every saved attempt (attempt-1 0.40 target, attempt-2 target, repeat, two references):
%  - SHA-256 of ATTEMPT_ARRAYS.mat equals its record; canonical array digest recomputed;
%  - independent metrics (g2_lp2b1_metrics) recomputed and equal to the record;
%  - pairing audit P1-P10 recomputed on the saved arrays;
%  - protected block re-compared with the baseline by T3 rows, block node coordinates, coordinates of
%    all six nodes of every block T6 element, nodal q at those positions, 2443 q rows;
%  - location of the smallest angle and of the largest exterior neighbour ratio; exterior-only
%    minimum angle; X3/T3 exported for the numpy check.
% Target comparison 0.45 (stored failure) versus 0.40 (selected): the element of the 0.40 mesh that
% contains the old offending edge midpoint, all shared-edge ratios within 6 mm of it in both meshes,
% ratio threshold counts. Attempt-1 versus attempt-2 0.40 arrays (two sessions) compared field by field.
assert(~isfolder(outDir),'LP2B1PA:Out','Output folder exists.');mkdir(outDir);
g2=fullfile(ex,'matlab','g2');addpath(g2);addpath(fullfile(g2,'lp2a2'));addpath(fullfile(g2,'lp2b1'));addpath(fullfile(g2,'lp2a3'));addpath(fullfile(g2,'lp2'));
C=g2_lp2a3_context('Preflight',true);pol=C.policy;
pins=jsondecode(fileread(fullfile(g2,'lp2b1','G2_LP2B1_PINS_v1.json')));rr=fullfile(ex,strrep(pins.lp2a3.runRoot,'/',filesep));
root=fullfile(ex,'outputs','g2_lp2b1_geometry_v1');
S=load(fullfile(rr,'soft1','S10','FAILED_MESH.mat'));fm=S.failedMesh;
B1=load(fullfile(rr,'soft1','S9','MESH.mat'));B2=load(fullfile(rr,'H','S10','MESH.mat'));
bases=struct('target',fm,'soft1_S9',B1,'H_S10',B2);
list={'wp1/T_soft1_S10_h040','target','attempt1';'wp1_attempt2/T_soft1_S10_h040','target','attempt2';'wp1_attempt2/T_soft1_S10_h040_REPEAT','target','repeat'; ...
      'wp1_attempt2/R_soft1_S9_h040','soft1_S9','reference';'wp1_attempt2/R_H_S10_h040','H_S10','reference'};
A=struct('schema','NewMetacomp.G2.LP2B1.PostAudit.v1','physicalSolves',0,'meshesGenerated',0,'sourceCommit',C.preflight.sourceCommit,'attempts',{{}},'exports',{{}});
for i=1:size(list,1)
 d=fullfile(root,strrep(list{i,1},'/',filesep));J=jsondecode(fileread(fullfile(d,'ATTEMPT.json')));D=load(fullfile(d,'ATTEMPT_ARRAYS.mat'));Bs=bases.(list{i,2});
 r=struct('attempt',list{i,1},'role',list{i,3},'baseline',list{i,2},'recordPass',J.pass,'recordChecks',sprintf('%d/%d',J.checksPassed,J.checksTotal));
 r.arraysSHAEqualsRecord=strcmpi(g2_sha256_file(fullfile(d,'ATTEMPT_ARRAYS.mat')),J.arraysFileSHA256);
 r.canonicalEqualsRecord=strcmp(canon(D),J.canonicalSHA256);
 M=g2_lp2b1_metrics(D.X3,D.T3,1.8);
 r.metricsEqualRecord=M.T3==J.independent.T3&&M.maxNeighborRatio==J.independent.maxNeighborRatio&&M.minAngle_deg==J.independent.minAngle_deg&&M.violations==J.independent.violations;
 PA=g2_lp2a2_pairing_audit(D);r.pairingRecomputed=sprintf('%d/%d',PA.gatesPassed,PA.gatesTotal);r.pairingPass=PA.pass;r.bankPairsT6=PA.metrics.pairsT6;
 nBlk=2916;nB=J.blockCompare.blockNodes;T6b=D.T6(1:nBlk,:);T6r=Bs.T6(1:nBlk,:);
 r.blockT3Rows=isequal(D.T3(1:nBlk,:),Bs.T3(1:nBlk,:));r.blockNodes=isequal(D.X3(1:nB,:),Bs.X3(1:nB,:))&&max(max(D.T3(1:nBlk,:)))==nB&&max(max(Bs.T3(1:nBlk,:)))==nB;
 r.blockT6Coordinates=isequal(D.X6(T6b,:),Bs.X6(T6r,:));r.blockNodalQ=isequal(D.nodalQ(T6b),Bs.nodalQ(T6r));r.qRows2443=isequal(D.qActiveT6Rows,Bs.qActiveT6Rows)&&numel(D.qActiveT6Rows)==2443;
 P=D.crackPolyline;tip=P(end,:);rows=struct('coreLast',2788,'collarLast',2916);
 ctx=struct('polyline_mm',P,'tip_mm',tip,'rows',rows,'centres_mm',pol.geometry.centres_mm,'ringR_mm',pol.geometry.ringR_mm,'holeR_mm',pol.geometry.holeR_mm, ...
  'guideR_mm',15,'collarR_mm',3.3,'coreR_mm',3.0,'plate_mm',pol.geometry.plate_mm,'extraVertexXY',D.extraVertexXY);
 r.metrics=struct('T3',M.T3,'minAngle_deg',M.minAngle_deg,'maxNeighborRatio',M.maxNeighborRatio,'violations',M.violations,'ratioCounts',M.ratioCounts);
 r.minAngle=angleSite(M,D,ctx);Mb=g2_lp2b1_metrics(Bs.X3,Bs.T3,1.8);
 r.baselineMinAngle=angleSite(Mb,struct('X3',Bs.X3,'T3',Bs.T3),setfield(ctx,'extraVertexXY',Bs.extraVertexXY)); %#ok<SFLD>
 r.worstExteriorPair=worstExterior(M,D,ctx);r.baselineWorstExteriorPair=worstExterior(Mb,struct('X3',Bs.X3,'T3',Bs.T3),setfield(ctx,'extraVertexXY',Bs.extraVertexXY)); %#ok<SFLD>
 r.baselineMetrics=struct('T3',Mb.T3,'minAngle_deg',Mb.minAngle_deg,'maxNeighborRatio',Mb.maxNeighborRatio,'violations',Mb.violations,'ratioCounts',Mb.ratioCounts);
 nm=strrep(strrep(list{i,1},'/','__'),'wp1_attempt2__','a2_');
 fx=fullfile(outDir,[nm '_X3_f64le.bin']);ft=fullfile(outDir,[nm '_T3_i32le.bin']);wb(fx,double(D.X3),'double');wb(ft,int32(D.T3),'int32');
 A.exports{end+1}=struct('attempt',list{i,1},'X3',[nm '_X3_f64le.bin'],'T3',[nm '_T3_i32le.bin'],'rows',[size(D.X3,1),size(D.T3,1)], ...
  'X3sha256',lower(g2_sha256_file(fx)),'T3sha256',lower(g2_sha256_file(ft)),'maxNeighborRatio',M.maxNeighborRatio,'minAngle_deg',M.minAngle_deg,'violations',M.violations,'ratioCounts',M.ratioCounts);
 r.pass=r.recordPass&&r.arraysSHAEqualsRecord&&r.canonicalEqualsRecord&&r.metricsEqualRecord&&r.pairingPass&&r.blockT3Rows&&r.blockNodes&&r.blockT6Coordinates&&r.blockNodalQ&&r.qRows2443;
 if strcmp(list{i,3},'attempt1'),r.pass=r.arraysSHAEqualsRecord&&r.canonicalEqualsRecord&&r.metricsEqualRecord&&r.pairingPass&&r.blockT3Rows&&r.blockNodes&&r.blockT6Coordinates&&r.blockNodalQ&&r.qRows2443;r.note='record pass=false is the harness-defect HOLD of attempt 1 (amendment A1); the arrays are re-audited here';end
 A.attempts{end+1}=r;fprintf('LP2B1_POSTAUDIT %-40s pass=%d ratio=%.9f minAng=%.6f pairing=%s\n',list{i,1},r.pass,M.maxNeighborRatio,M.minAngle_deg,r.pairingRecomputed);
end
% ---- attempt 1 vs attempt 2 (two MATLAB sessions)
a1=load(fullfile(root,'wp1','T_soft1_S10_h040','ATTEMPT_ARRAYS.mat'));a2=load(fullfile(root,'wp1_attempt2','T_soft1_S10_h040','ATTEMPT_ARRAYS.mat'));
f=fieldnames(a1);eq=struct();for k=1:numel(f),eq.(f{k})=isequal(a1.(f{k}),a2.(f{k}));end;A.attempt1VsAttempt2=eq;A.attempt1VsAttempt2AllEqual=all(cell2mat(struct2cell(eq)));
% ---- target comparison: stored 0.45 failure versus selected 0.40
W=jsondecode(fileread(fullfile(root,'wp0_attempt1','LP2B1_WP0.json')));v=W.violations;old=reshape(v.midpoint_mm,1,2);
J40=jsondecode(fileread(fullfile(root,'wp1_attempt2','T_soft1_S10_h040','ATTEMPT.json')));M45=g2_lp2b1_metrics(fm.X3,fm.T3,1.8);M40=g2_lp2b1_metrics(a2.X3,a2.T3,1.8);
A.target=struct('oldOffendingMidpoint_mm',old,'oldRatio',v.ratio,'h45_mm',[v.hSmall_mm v.hLarge_mm], ...
 'near45',near(M45,fm.X3,fm.T3,old,6),'near40',near(M40,a2.X3,a2.T3,old,6),'containing40',contain(M40,a2.X3,a2.T3,old), ...
 'counts45',M45.ratioCounts,'counts40',M40.ratioCounts,'T3',[M45.T3 M40.T3],'exteriorT3',[M45.T3-2916 M40.T3-2916], ...
 'seedsPerSegment45',fm.summary.exterior.seedsPerSegment,'seedsPerSegment40',J40.exterior.seedsPerSegment);
save(fullfile(outDir,'LP2B1_POSTAUDIT_ARRAYS.mat'),'M45','M40','-v7.3');
A.pass=all(cellfun(@(r)r.pass,A.attempts))&&A.attempt1VsAttempt2AllEqual;
fid=fopen(fullfile(outDir,'LP2B1_POSTAUDIT.json'),'w');fwrite(fid,jsonencode(A,'PrettyPrint',true),'char');fclose(fid);
fprintf('LP2B1_POSTAUDIT_PASS=%d attempt1VsAttempt2=%d\n',A.pass,A.attempt1VsAttempt2AllEqual);
end

function s=angleSite(M,D,ctx)
[a,e]=min(M.minAngleEl);ext=M.minAngleEl;ext(1:2916)=inf;[ae,ee]=min(ext);
c=mean(D.X3(D.T3(e,:),:),1);ce=mean(D.X3(D.T3(ee,:),:),1);
s=struct('minAngle_deg',a,'element',e,'region',reg(e),'centroid_mm',c,'distTip_mm',norm(c-ctx.tip_mm),'distPolyline_mm',pd(c,ctx.polyline_mm), ...
 'exteriorMinAngle_deg',ae,'exteriorElement',ee,'exteriorCentroid_mm',ce,'exteriorDistTip_mm',norm(ce-ctx.tip_mm),'exteriorDistPolyline_mm',pd(ce,ctx.polyline_mm), ...
 'exteriorTouchesCrack',any(pdv(D.X3(D.T3(ee,:),:),ctx.polyline_mm)<=1e-9),'exteriorH_mm',M.h(ee));
end
function w=worstExterior(M,D,ctx)
ex=all(M.pairElements>2916,2);idx=find(ex);[~,o]=max(M.pairRatio(idx));L=g2_lp2b1_locate(M,D.X3,D.T3,ctx,idx(o));
w=struct('ratio',L.ratio,'midpoint_mm',L.midpoint_mm,'h_mm',[L.hSmall_mm L.hLarge_mm],'distTip_mm',L.distTip_mm,'distPolyline_mm',L.distPolyline_mm,'face',L.face);
end
function n=near(M,X,T,p,R)
mid=(X(M.pairNodes(:,1),:)+X(M.pairNodes(:,2),:))/2;in=vecnorm(mid-p,2,2)<=R;r=M.pairRatio(in);
n=struct('radius_mm',R,'sharedEdges',nnz(in),'maxRatio',max(r),'above1p5',nnz(r>1.5),'above1p4',nnz(r>1.4),'quantiles50_90_99',qt(r,[.5 .9 .99]));
end
function c=contain(M,X,T,p)
c=struct('element',NaN,'h_mm',NaN,'maxRatioToEdgeNeighbours',NaN);
for e=1:size(T,1)
 a=X(T(e,1),:);b=X(T(e,2),:);q=X(T(e,3),:);dd=(b(1)-a(1))*(q(2)-a(2))-(b(2)-a(2))*(q(1)-a(1));
 l1=((b(1)-p(1))*(q(2)-p(2))-(b(2)-p(2))*(q(1)-p(1)))/dd;l2=((q(1)-p(1))*(a(2)-p(2))-(q(2)-p(2))*(a(1)-p(1)))/dd;
 if l1>=-1e-12&&l2>=-1e-12&&1-l1-l2>=-1e-12
  pr=any(M.pairElements==e,2);c=struct('element',e,'h_mm',M.h(e),'maxRatioToEdgeNeighbours',max(M.pairRatio(pr)));return
 end
end
end
function q=qt(r,p),r=sort(r(:));q=r(max(1,ceil(p*numel(r))));q=q(:).';end
function r=reg(e),if e<=2788,r='core';elseif e<=2916,r='collar';else,r='exterior';end,end
function d=pd(x,P),d=min(pdv(x,P));end
function d=pdv(X,P)
d=inf(size(X,1),1);for j=1:size(P,1)-1,v=P(j+1,:)-P(j,:);l=max(0,min(1,((X-P(j,:))*v.')/(v*v.')));d=min(d,vecnorm(X-(P(j,:)+l*v),2,2));end
end
function h=canon(D)
md=java.security.MessageDigest.getInstance('SHA-256');
f={'X3','T3','X6','T6','upperBankT6','lowerBankT6','nodalQ','qActiveT6Rows','crackPolyline'};
for i=1:numel(f),a=double(D.(f{i}));md.update(typecast(int64(size(a)),'uint8'));md.update(typecast(a(:),'uint8'));end
h=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
end
function wb(f,A,cls),fid=fopen(f,'w','ieee-le');fwrite(fid,A.',cls);fclose(fid);end
