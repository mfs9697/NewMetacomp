function R=g2_lp2_mesh_probe(execRepo,geomJson,outFile)
%G2_LP2_MESH_PROBE  Non-solving mesh qualification beyond the LP0-qualified six vertices.
% For each case: (a) the actual geometry-only S5 candidate (7 vertices); (b) the last admissible
% polyline of the hypothetical frozen-MTS outlook (label MESH_ONLY_SYNTHETIC, never a trajectory).
% Each polyline is meshed with the UNCHANGED LP1 call (g2_kinked_join, ExpectedVertices = N,
% TipGuideRadius 15 mm, TipGuideHface 1.5 mm, 40,000 T3) and audited with the UNCHANGED
% g2_lp1_audit (kink-aware auditor 34 gates, T3 budget, bank adapter, four-mask phase audit,
% phase re-map). Meshes are held in memory only. No FEM, no SIF, no write except outFile.
g2=fullfile(execRepo,'matlab','g2');addpath(g2,'-begin');addpath(fullfile(g2,'vendor_p010_a14d8872'),'-begin');
lp=jsondecode(fileread(fullfile(g2,'G2_LP1_POLICY_v2.json')));Gm=jsondecode(fileread(geomJson));
Ca=struct('repo',execRepo,'here',g2,'policy',lp);
opts={'BottomVertices_mm',[25.4 482.6],'TopVertices_mm',254,'TipGuideRadius_mm',15,'TipGuideHface_mm',1.5};
rows={};
for ci=1:numel(Gm.rows)
 g=Gm.rows(ci);
 probes={'S5_candidate',g.S5_B0.polyline_mm,g.S5_B0.tangent};
 tp=g.outlook.frozenMTS.tips_mm;s4=g.S5_B0.polyline_mm(1:end-1,:);
 Psyn=[s4;tp(2:end,:)];tsyn=(Psyn(end,:)-Psyn(end-1,:))/norm(Psyn(end,:)-Psyn(end-1,:));
 probes(end+1,:)={sprintf('SYNTHETIC_frozen_S%d',size(Psyn,1)-2),Psyn,tsyn};
 for p=1:size(probes,1)
  P=probes{p,2};t=reshape(probes{p,3},1,2);N=size(P,1);t0=tic;r=struct('caseId',g.caseId,'probe',probes{p,1},'vertices',N,'arc_mm',sum(vecnorm(diff(P),2,2)));
  try
   D=g2_kinked_join(P,'ExpectedVertices',N,'ExpectedTangent',t,'ExteriorOptions',opts,'MaxT3Elements',40000);
   r.meshPass=D.pass;r.stage=D.stage;r.message=D.message;
   if D.pass
    D.tipTangent=t;[A,PM]=g2_lp1_audit(D,N-2,Ca);
    r.T3=size(D.T3,1);r.DOF=2*size(D.X6,1);r.auditGates=sprintf('%d/%d',A.meshAudit.gatesPassed,A.meshAudit.gatesTotal);
    r.phaseAuditPass=A.pass;r.phaseMapPass=PM.pass;r.minAngle_deg=D.summary.minAngle_deg;r.maxNeighborRatio=D.summary.maxNeighborRatio;
    r.pass=A.pass&&PM.pass&&A.meshAudit.gatesPassed==34;
   else,r.pass=false;end
  catch ME
   r.pass=false;r.error=[ME.identifier ': ' ME.message];
  end
  r.seconds=toc(t0);rows{end+1}=r; %#ok<AGROW>
  fprintf('LP2_MESH_PROBE %-7s %-22s N=%d pass=%d T3=%s gates=%s t=%.1fs %s\n',g.caseId,r.probe,N,r.pass,num2str(getf(r,'T3')),char(getf(r,'auditGates')),r.seconds,char(getf(r,'error')));
  clear D A PM
 end
end
R=struct('schema','NewMetacomp.G2.LP2.MeshProbe.v1','physicalSolves',0,'meshesSaved',0,'rows',{rows});
if nargin>2&&~isempty(outFile),fid=fopen(outFile,'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);end
end
function v=getf(s,f)
if isfield(s,f),v=s.(f);else,v='';end
end
