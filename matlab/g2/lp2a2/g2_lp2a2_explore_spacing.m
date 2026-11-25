function X=g2_lp2a2_explore_spacing(execRepo,spacings,outFile)
%G2_LP2A2_EXPLORE_SPACING  Seed-spacing exploration on an EXPLORATION set disjoint from the
% predeclared test set (geometry only, zero FEM, meshes in memory). After attempt 1 (seed spacing =
% lip Hedge 0.45 mm) failed the inherited neighbour-ratio gate on far-field elements of some
% continuations, the spacing rule is chosen here, NOT on the test set, and the frozen test set is
% then re-run once with the chosen rule.
% Exploration polylines (MESH_ONLY_SYNTHETIC): from each accepted LP2-A1 S8 polyline (a) straight
% steps along the S8 tangent, (b) steps repeating the S8 local MTS angle, (c) H only: alternating
% +/-3 deg and a constant +1 deg curve; 4-mm steps until kink admissibility fails (max 12).
% For each spacing: join (all join gates), pairing audit; max neighbour ratio and min angle.
g2=fullfile(execRepo,'matlab','g2');addpath(g2,'-begin');addpath(fullfile(g2,'vendor_p010_a14d8872'),'-begin');addpath(fileparts(mfilename('fullpath')),'-begin');
J=jsondecode(fileread(fullfile(execRepo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json')));Gn=J.nominal_geometry_mm;
opts={'BottomVertices_mm',[25.4 482.6],'TopVertices_mm',254,'TipGuideRadius_mm',15,'TipGuideHface_mm',1.5};
base=fullfile(execRepo,'outputs','g2_lp2a_paths_v1','run_lp2a_s5_s8_v1');cases={'H','stiff13','soft2','soft1'};geo={};
for i=1:4
 S=load(fullfile(base,cases{i},'S8','STATE.mat'));S=S.record;
 geo=[geo,ext(sprintf('E_%s_straight',cases{i}),S.polyline_mm,S.tangent,@(k)0)]; %#ok<AGROW>
 geo=[geo,ext(sprintf('E_%s_mts',cases{i}),S.polyline_mm,S.tangent,@(k)S.MTS_deg)]; %#ok<AGROW>
 if i==1
  geo=[geo,ext('E_H_zigzag3',S.polyline_mm,S.tangent,@(k)3*(-1)^(k+1))]; %#ok<AGROW>
  geo=[geo,ext('E_H_curve1',S.polyline_mm,S.tangent,@(k)1)]; %#ok<AGROW>
 end
end
rows={};
for g=1:numel(geo)
 P=geo{g}.P;t=geo{g}.t;N=size(P,1);
 for hs=spacings(:).'
  r=struct('id',geo{g}.id,'vertices',N,'seedSpacing_mm',hs,'pass',false);
  try
   [~,D]=evalc('g2_lp2a2_join(P,''ExpectedVertices'',N,''ExpectedTangent'',t,''ExteriorOptions'',[opts,{''SeedSpacing_mm'',hs}],''MaxT3Elements'',40000)');
   r.stage=D.stage;r.message=D.message;
   if isfield(D.summary,'maxNeighborRatio'),r.maxNeighborRatio=D.summary.maxNeighborRatio;r.minAngle_deg=D.summary.minAngle_deg;r.T3=size(D.T3,1);end
   if D.pass,PA=g2_lp2a2_pairing_audit(D);r.pairingPass=PA.pass;r.pass=PA.pass;end
  catch ME
   r.stage='ERROR';r.message=[ME.identifier ': ' ME.message];
  end
  rows{end+1}=r; %#ok<AGROW>
  fprintf('LP2A2_EXPLORE %-18s N=%-2d hs=%.3f pass=%d ratio=%s minAng=%s %s\n',r.id,N,hs,r.pass,num2str(gf(r,'maxNeighborRatio'),5),num2str(gf(r,'minAngle_deg'),4),r.message);
 end
end
X=struct('schema','NewMetacomp.G2.LP2A2.SpacingExploration.v1','label','MESH_ONLY_SYNTHETIC exploration set (disjoint from the test set)','physicalSolves',0,'spacings',spacings,'rows',{rows});
if nargin>2&&~isempty(outFile),fid=fopen(outFile,'w');fwrite(fid,jsonencode(X,'PrettyPrint',true),'char');fclose(fid);end

 function R=ext(id,P0,t0,kinkDeg)
  R={};P=P0;t=reshape(t0,1,2);
  for k=1:12
   th=kinkDeg(k);n=[-t(2),t(1)];t=cosd(th)*t+sind(th)*n;P=[P;P(end,:)+4*t]; %#ok<AGROW>
   A=g2_kink_admissibility(P,Gn,'DeltaA_mm',4,'ExpectedVertices',size(P,1),'ExpectedTangent',t,'TipGuideRadius_mm',15);
   if ~A.pass,break,end
   R{end+1}=struct('id',sprintf('%s_S%d',id,size(P,1)-2),'P',P,'t',t); %#ok<AGROW>
  end
 end
end
function v=gf(s,f),if isfield(s,f),v=s.(f);else,v=NaN;end,end
