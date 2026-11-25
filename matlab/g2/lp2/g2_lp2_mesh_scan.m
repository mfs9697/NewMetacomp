function R=g2_lp2_mesh_scan(execRepo,geomJson,outFile)
%G2_LP2_MESH_SCAN  Non-solving vertex-count scan of the unchanged LP1 mesher (MESH_ONLY_SYNTHETIC).
% For each case and each hypothetical outlook (frozen S4 MTS increment; straight), the polyline
% truncated after S6 ... S(last admissible) is meshed with the unchanged g2_kinked_join call and,
% if joined, audited with g2_lp1_audit. Synthetic polylines are never trajectories. Meshes are
% held in memory only; no FEM; writes only outFile.
g2=fullfile(execRepo,'matlab','g2');addpath(g2,'-begin');addpath(fullfile(g2,'vendor_p010_a14d8872'),'-begin');
lp=jsondecode(fileread(fullfile(g2,'G2_LP1_POLICY_v2.json')));Gm=jsondecode(fileread(geomJson));
Ca=struct('repo',execRepo,'here',g2,'policy',lp);
opts={'BottomVertices_mm',[25.4 482.6],'TopVertices_mm',254,'TipGuideRadius_mm',15,'TipGuideHface_mm',1.5};
rows={};
for ci=1:numel(Gm.rows)
 g=Gm.rows(ci);s4=g.S5_B0.polyline_mm(1:end-1,:);
 for sc={'frozenMTS','straight'}
  tp=g.outlook.(sc{1}).tips_mm;
  for j=3:size(tp,1)        % j=2 is S5 (probed separately); j>=3 is S6 onwards
   P=[s4;tp(2:j,:)];N=size(P,1);t=(P(end,:)-P(end-1,:))/norm(P(end,:)-P(end-1,:));
   r=struct('caseId',g.caseId,'scenario',sc{1},'state',N-2,'vertices',N,'pass',false,'stage','','detail','','T3',NaN);
   try
    D=g2_kinked_join(P,'ExpectedVertices',N,'ExpectedTangent',t,'ExteriorOptions',opts,'MaxT3Elements',40000);
    r.stage=D.stage;r.detail=D.message;
    if D.pass
     D.tipTangent=t;[~,A]=evalc('auditOf(D,N,Ca)');r.T3=size(D.T3,1);r.pass=A;
     if ~A,r.stage='AUDIT_FAILED';end
    end
   catch ME
    r.stage='ERROR';r.detail=[ME.identifier ': ' ME.message];
   end
   rows{end+1}=r; %#ok<AGROW>
   fprintf('LP2_SCAN %-7s %-9s S%-2d N=%-2d pass=%d %s\n',g.caseId,sc{1},N-2,N,r.pass,r.stage);
   clear D
  end
 end
end
R=struct('schema','NewMetacomp.G2.LP2.MeshScan.v1','label','MESH_ONLY_SYNTHETIC','physicalSolves',0,'rows',{rows});
if nargin>2,fid=fopen(outFile,'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);end
end
function ok=auditOf(D,N,Ca)
try,[A,PM]=g2_lp1_audit(D,N-2,Ca);ok=A.pass&&PM.pass&&A.meshAudit.gatesPassed==34;catch,ok=false;end
end
