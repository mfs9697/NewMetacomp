function T=g2_lp2a2_testset(execRepo,outFile)
%G2_LP2A2_TESTSET  Predeclared LP2-A2 geometry-only qualification set (written BEFORE any evaluation).
% No mesh, no FEM. Builds every polyline from committed or archived sources by fixed rules:
%  Group A  four accepted LP2-A1 S8 polylines; STATE.mat SHA-256 verified against the committed
%           LP2-A1 run manifest (LP2A_RUN_LEDGER_SHA256.json).
%  Group B  four S9 PREDICTORS from the full-precision S8 SIFs (g2_lp2_forecast recurrence with a
%           local policy copy whose only change is maxStateIndex 9 / maxArc 61.4 mm); cross-checked
%           bit-for-bit against the archived TERMINAL.mat candidate. GEOMETRY_ONLY_FORECAST, never
%           an accepted state.
%  Group C  MESH_ONLY_SYNTHETIC polylines (never trajectories), all rows of each rule, no selection:
%   C1  every row of the committed LP2 mesh scan (LP2_MESH_SCAN.json; 82 rows, frozen-S4-MTS and
%       straight outlooks from S4, S6 ... last admissible), regenerated with the scan's own rule,
%       which contains every earlier failure (earliest at S9) and the longest polylines (S19/S20);
%   C2  continuations of each Group B predictor in 4-mm steps: (a) straight (S9 heading kept);
%       (b) frozen S8 MTS increment repeated; every intermediate polyline up to and including the
%       first that fails g2_kink_admissibility (that last row is a GUARD row: expected HOLD by
%       admissibility, recorded as a geometric limit, not as a meshing result); at most 12 steps;
%   C3  H predictor continued with alternating kinks +2/-2 deg and +5/-5 deg (positive AND negative
%       kinks), same stepping and guard rule.
g2=fullfile(execRepo,'matlab','g2');lp2=fullfile(g2,'lp2');addpath(g2,'-begin');addpath(lp2,'-begin');
ev=fullfile(execRepo,'docs','research','G2_LP2_evidence');
manTxt=fileread(fullfile(ev,'campaign_20261125','LP2A_RUN_LEDGER_SHA256.json'));   % flat {path: sha256}; read as text (long keys)
pol=jsondecode(fileread(fullfile(lp2,'G2_LP2A_POLICY_v1.json')));pol9=pol;pol9.caps.maxStateIndex=9;pol9.caps.maxArcLength_mm=61.4;
J=jsondecode(fileread(fullfile(execRepo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json')));Gn=J.nominal_geometry_mm;
c1=[152.4,69.85];ringR=19.05;
base='outputs/g2_lp2a_paths_v1/run_lp2a_s5_s8_v1';cases={'H','stiff13','soft2','soft1'};
expB=struct('H',[113.0090,59.4552,21.6894],'stiff13',[113.2510,59.3870,21.4730],'soft2',[113.2393,59.3732,21.4879],'soft1',[112.5349,59.5939,22.1132]);
rows={};B=struct();
for i=1:4
 c=cases{i};rel=[base,'/',c,'/S8/STATE.mat'];f=fullfile(execRepo,rel);h=lower(g2_sha256_file(f));
 tok=regexp(manTxt,['"',regexptranslate('escape',rel),'"\s*:\s*"([0-9a-f]{64})"'],'tokens','once');ok=~isempty(tok)&&strcmp(tok{1},h);
 S=load(f);S=S.record;assert(ok&&S.stateIndex==8&&strcmp(S.caseId,c),'G2LP2A2:TestSetSource','S8 STATE %s fails the LP2-A1 manifest.',c);
 rows{end+1}=row(sprintf('A_%s_S8',c),'A',c,'ACCEPTED_LP2A1_S8',S.polyline_mm,S.tangent,'accepted S8 polyline (LP2-A1)',struct('stateSHA256',h,'manifestVerified',ok)); %#ok<AGROW>
 F=g2_lp2_forecast(S,pol9);
 Tm=load(fullfile(execRepo,base,c,'TERMINAL.mat'));Pc=Tm.record.candidate.polyline_mm;
 same=isequal(F.polyline_mm,Pc);tip=F.polyline_mm(end,:);cl=norm(tip-c1)-ringR;e=expB.(c);
 dev=max(abs([tip,cl]-e));
 assert(same&&dev<=5e-5,'G2LP2A2:TestSetForecast','S9 predictor %s: terminal equality %d, deviation from the assignment %.3g.',c,same,dev);
 rows{end+1}=row(sprintf('B_%s_S9',c),'B',c,'GEOMETRY_ONLY_FORECAST',F.polyline_mm,F.tangent,'S9 predictor from full-precision S8 SIFs (not an accepted state)', ...
  struct('equalsTerminalCandidate',same,'ring1Clearance_mm',cl,'parentMTS_deg',F.parentMTS_deg,'heading_deg',F.heading_deg,'deviationFromAssignment',dev)); %#ok<AGROW>
 B.(c)=F;
end
% ---- C1: the full committed LP2 mesh scan, regenerated with its own rule
Gm=jsondecode(fileread(fullfile(ev,'LP2_S5_GEOMETRY.json')));Sc=jsondecode(fileread(fullfile(ev,'LP2_MESH_SCAN.json')));
q=0;
for ci=1:numel(Gm.rows)
 g=Gm.rows(ci);s4=g.S5_B0.polyline_mm(1:end-1,:);
 for sc={'frozenMTS','straight'}
  tp=g.outlook.(sc{1}).tips_mm;
  for j=3:size(tp,1)
   P=[s4;tp(2:j,:)];N=size(P,1);t=(P(end,:)-P(end-1,:))/norm(P(end,:)-P(end-1,:));q=q+1;r0=Sc.rows(q);
   assert(strcmp(r0.caseId,g.caseId)&&strcmp(r0.scenario,sc{1})&&r0.vertices==N,'G2LP2A2:TestSetScan','Scan row %d does not regenerate.',q);
   rows{end+1}=row(sprintf('C1_%s_%s_S%d',g.caseId,sc{1},N-2),'C1',g.caseId,'MESH_ONLY_SYNTHETIC',P,t,sprintf('LP2 mesh scan row %d (%s outlook from S4)',q,sc{1}), ...
    struct('scanRow',q,'scanPass',r0.pass,'scanStage',r0.stage,'scanDetail',r0.detail)); %#ok<AGROW>
  end
 end
end
assert(q==numel(Sc.rows),'G2LP2A2:TestSetScan','Scan rows %d regenerated of %d.',q,numel(Sc.rows));
% ---- C2/C3: continuations of the S9 predictors
for i=1:4
 c=cases{i};F=B.(c);
 rows=[rows,extend(sprintf('C2_%s_straight',c),'C2',c,F.polyline_mm,F.tangent,@(k)0)]; %#ok<AGROW>
 rows=[rows,extend(sprintf('C2_%s_frozen',c),'C2',c,F.polyline_mm,F.tangent,@(k)F.parentMTS_deg)]; %#ok<AGROW>
end
rows=[rows,extend('C3_H_zigzag2','C3','H',B.H.polyline_mm,B.H.tangent,@(k)2*(-1)^(k+1))];
rows=[rows,extend('C3_H_zigzag5','C3','H',B.H.polyline_mm,B.H.tangent,@(k)5*(-1)^(k+1))];
T=struct('schema','NewMetacomp.G2.LP2A2.TestSet.v1','predeclared',true,'physicalSolves',0,'meshesBuilt',0, ...
 'rules',{{'A: accepted LP2-A1 S8, manifest-verified','B: S9 predictors, equal to TERMINAL candidates','C1: all 82 LP2 mesh-scan rows','C2: straight and frozen-increment continuations of each predictor to the first admissibility failure (max 12)','C3: H predictor with alternating +/-2 and +/-5 deg kinks, same rule'}}, ...
 'counts',struct('A',nnz(cellfun(@(r)strcmp(r.group,'A'),rows)),'B',nnz(cellfun(@(r)strcmp(r.group,'B'),rows)),'C1',nnz(cellfun(@(r)strcmp(r.group,'C1'),rows)), ...
  'C2',nnz(cellfun(@(r)strcmp(r.group,'C2'),rows)),'C3',nnz(cellfun(@(r)strcmp(r.group,'C3'),rows)),'guardRows',nnz(cellfun(@(r)r.guardRow,rows))),'rows',{rows});
if nargin>1&&~isempty(outFile),fid=fopen(outFile,'w');fwrite(fid,jsonencode(T,'PrettyPrint',true),'char');fclose(fid);end

 function R=extend(id,grp,c,P0,t0,kinkDeg)
  R={};P=P0;t=reshape(t0,1,2);
  for k=1:12
   th=kinkDeg(k);n=[-t(2),t(1)];t=cosd(th)*t+sind(th)*n;P=[P;P(end,:)+4*t]; %#ok<AGROW>
   A=g2_kink_admissibility(P,Gn,'DeltaA_mm',4,'ExpectedVertices',size(P,1),'ExpectedTangent',t,'TipGuideRadius_mm',15);
   r=row(sprintf('%s_S%d',id,size(P,1)-2),grp,c,'MESH_ONLY_SYNTHETIC',P,t,sprintf('%s step %d (kink %+g deg)',id,k,th), ...
    struct('admissible',A.pass,'failedGates',{A.failedGates},'ring1Clearance_mm',norm(P(end,:)-c1)-ringR));
   r.guardRow=~A.pass;R{end+1}=r; %#ok<AGROW>
   if ~A.pass,break,end
  end
 end
end

function r=row(id,grp,c,label,P,t,desc,extra)
r=struct('id',id,'group',grp,'caseId',c,'label',label,'description',desc,'vertices',size(P,1),'state',size(P,1)-2, ...
 'arc_mm',sum(vecnorm(diff(P),2,2)),'polyline_mm',P,'tangent',reshape(t,1,2),'guardRow',false,'source',extra);
end
