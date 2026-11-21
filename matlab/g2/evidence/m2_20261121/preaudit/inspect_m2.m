function inspect_m2(repo)
% Read-only pre-audit for Issue #36 (disclosed): schemas, interface circles, S0 crack twins,
% and a GEOMETRY-ONLY feasibility build of a candidate S2 alternative band mesh (no FEM, nothing saved).
files={'S0',fullfile(repo,'outputs','g2_protected_mesh','run_20261118_165922_343_famA','GEOMETRY_ONLY_candidate.mat');
       'S1',fullfile(repo,'outputs','g2_wp3_state','run_20261118_185808_963','step1_a','KINKED_GEOMETRY_ONLY_candidate.mat');
       'S2',fullfile(repo,'outputs','g2_trajectory_chain_v1_attempt2','STEP_002','KINKED_GEOMETRY_ONLY_candidate.mat')};
c=[152.4 69.85;152.4 120.65;152.4 171.45];
for i=1:3
 fprintf('==== %s  SHA %s\n',files{i,1},g2_sha256_file(files{i,2}));
 D=load(files{i,2});fn=fieldnames(D);fprintf('fields: %s\n',strjoin(fn.',' '));
 fprintf('T3 %d, X6 %d nodes\n',size(D.T6,1),size(D.X6,1));
 report_circles(D,c);
 if isfield(D,'crackPolyline'),disp(D.crackPolyline);end
 if isfield(D,'physicalTipNode'),fprintf('tip node at %s\n',mat2str(D.X3(D.physicalTipNode,:),12));end
 if isfield(D,'extraVertexXY'),disp(D.extraVertexXY);end
 for f={'upperBankT6','lowerBankT6','upperLipNodes','lowerLipNodes','kinkNodeIDs','familyTag','nodalQ','qActiveT6Rows','tipTangent'}
  if isfield(D,f{1}),v=D.(f{1});if isnumeric(v),fprintf('%s: %s\n',f{1},mat2str(size(v)));else,disp(v);end,end
 end
 if strcmp(files{i,1},'S0')
  on=find(abs(D.X6(:,1)-101.6)<1e-9&D.X6(:,2)>=-1e-9&D.X6(:,2)<=25.4+1e-9);
  [~,~,g]=uniquetol(D.X6(on,:),1e-9,'ByRows',true,'DataScale',1);cnt=accumarray(g,1);
  fprintf('S0 nodes on crack line: %d, coordinate groups %d, pairs %d, singles %d (y of singles: %s)\n',numel(on),max(g),nnz(cnt==2),nnz(cnt==1),mat2str(D.X6(on(ismember(g,find(cnt==1))),2).',6));
 end
end
% ---- geometry-only feasibility of candidate S2 alternative band meshes
S=load(files{3,2});P=S.crackPolyline;t=S.tipTangent(:).';
json=fullfile(repo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json');
p0=fullfile(repo,'outputs','g2_p010_isolated','run_20261118_163657_790','P010_ISOLATED_REGULAR_ONLY.mat');
cand={{'GuideHface_mm',1.0},{'GuideHface_mm',1.0,'Hmax_mm',5}};
for k=1:numel(cand)
 opts=[{'BottomVertices_mm',[25.4 482.6],'TopVertices_mm',254,'TipGuideRadius_mm',15,'TipGuideHface_mm',1.5},cand{k}];
 fprintf('==== candidate %d: %s\n',k,strjoin(cellfun(@num2str,cand{k},'UniformOutput',false),' '));
 try
  B=g2_kinked_join(P,'ExteriorOptions',opts,'ExpectedVertices',size(P,1),'MaxT3Elements',40000,'ExpectedTangent',t);
  fprintf('join pass=%d stage=%s %s\n',B.pass,B.stage,B.message);
  if B.pass
   D=struct('X3',B.X3,'T3',B.T3,'X6',B.X6,'T6',B.T6,'upperBankT6',B.upperBankT6,'lowerBankT6',B.lowerBankT6, ...
    'physicalTipNode',B.physicalTipNode,'nodalQ',B.nodalQ,'qActiveT6Rows',B.qActiveT6Rows,'elementRows',B.elementRows, ...
    'collarOuterIDs',B.collarOuterIDs,'extraVertexXY',B.extraVertexXY,'extraVertexNodes',B.extraVertexNodes, ...
    'crackPolyline',P,'tipTangent',t,'tipNormal',[-t(2),t(1)],'kinkNodeIDs',B.kinkNodeIDs,'geometryOnly',true, ...
    'approvedForLEFM',false,'plateXRange',B.plateXRange,'includeHoles',true,'mirrorControl',false);
   C=g2_kinked_mesh_auditor(D,json,p0,size(P,1));
   fprintf('audit %d/%d pass=%d T3=%d minAngle=%.4f ratio=%.4f qActive=%d\n',C.gatesPassed,C.gatesTotal,C.pass,C.summary.T3elements,C.summary.minAngle_deg,C.summary.maxNeighborRatio,C.summary.qActive);
   report_circles(D,c);
  end
 catch ME
  fprintf('candidate %d error: %s\n',k,ME.message);
 end
end
end

function report_circles(D,c)
v=unique(D.T6(:,1:3));
for k=1:3
 r=vecnorm(D.X6(v,:)-c(k,:),2,2);d=abs(r-19.05);on=d<1e-6;dh=abs(r-6.35);
 fprintf('  circle %d: %d T3 vertices on r=19.05 (max dev %.2g), next vertex %.4g mm; hole rim vertices %d\n',k,nnz(on),max(d(on)),min(d(~on)),nnz(dh<1e-6));
end
end
