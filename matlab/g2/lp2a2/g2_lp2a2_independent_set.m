function T=g2_lp2a2_independent_set(execRepo,outFile)
%G2_LP2A2_INDEPENDENT_SET  Eight previously untested admissible polylines (memorandum section 10),
% frozen BEFORE any meshing (no mesh, no FEM). Rule, fixed by the review of PR #71:
%  for each full-precision S9 predictor (g2_lp2_forecast from the archived S8 STATE, required to
%  equal the archived TERMINAL candidate bitwise) extend to S11 with a constant local turn of +1 deg
%  and of -1 deg per 4-mm step (S10 and S11): 4 cases x 2 signs = 8 S11 polylines.
% Recorded first, for every row: polyline, tangent, source SHA-256 (S8 STATE, TERMINAL, manifest
% entries), selection rule, and an independent admissibility check (g2_kink_admissibility with
% the unchanged 15-mm tip guide) and the guide-to-every-ring clearance (tip-to-ring-circle - 15 mm,
% required >= 1.0 mm) at S10 AND at S11. Rows are never replaced or tuned; a row failing the
% pre-check stays in the set and is reported as outside the regime.
g2=fullfile(execRepo,'matlab','g2');addpath(g2,'-begin');addpath(fullfile(g2,'lp2'),'-begin');
ev=fullfile(execRepo,'docs','research','G2_LP2_evidence');
manTxt=fileread(fullfile(ev,'campaign_20261125','LP2A_RUN_LEDGER_SHA256.json'));
pol=jsondecode(fileread(fullfile(g2,'lp2','G2_LP2A_POLICY_v1.json')));pol9=pol;pol9.caps.maxStateIndex=9;pol9.caps.maxArcLength_mm=61.4;
J=jsondecode(fileread(fullfile(execRepo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json')));Gn=J.nominal_geometry_mm;
cen=pol.geometry.centres_mm;ringR=19.05;guide=15;margin=1.0;
base='outputs/g2_lp2a_paths_v1/run_lp2a_s5_s8_v1';cases={'H','stiff13','soft2','soft1'};rows={};
for i=1:4
 c=cases{i};
 rs=[base,'/',c,'/S8/STATE.mat'];rt=[base,'/',c,'/TERMINAL.mat'];hs=lower(g2_sha256_file(fullfile(execRepo,rs)));ht=lower(g2_sha256_file(fullfile(execRepo,rt)));
 okS=manOK(manTxt,rs,hs);okT=manOK(manTxt,rt,ht);
 S=load(fullfile(execRepo,rs));S=S.record;Tm=load(fullfile(execRepo,rt));Tm=Tm.record;
 F=g2_lp2_forecast(S,pol9);same=isequal(F.polyline_mm,Tm.candidate.polyline_mm);
 assert(okS&&okT&&same,'G2LP2A2:IndependentSource','Source of %s fails the manifest or the TERMINAL equality.',c);
 for sg=[1 -1]
  P=F.polyline_mm;t=reshape(F.tangent,1,2);chk=struct('state',{},'admissible',{},'failedGates',{},'guideToRingClearance_mm',{},'clearanceOK',{});
  for k=1:2
   n=[-t(2),t(1)];t=cosd(sg)*t+sind(sg)*n;P=[P;P(end,:)+4*t]; %#ok<AGROW>
   A=g2_kink_admissibility(P,Gn,'DeltaA_mm',4,'ExpectedVertices',size(P,1),'ExpectedTangent',t,'TipGuideRadius_mm',15);
   cl=vecnorm(cen-P(end,:),2,2).'-ringR-guide;
   chk(end+1)=struct('state',size(P,1)-2,'admissible',A.pass,'failedGates',{A.failedGates},'guideToRingClearance_mm',cl,'clearanceOK',all(cl>=margin)); %#ok<AGROW>
  end
  id=sprintf('I_%s_%s1deg_S11',c,char('p'*(sg>0)+'m'*(sg<0)));
  rows{end+1}=struct('id',id,'group','I','caseId',c,'label','MESH_ONLY_SYNTHETIC_INDEPENDENT','vertices',size(P,1),'state',size(P,1)-2, ...
   'arc_mm',sum(vecnorm(diff(P),2,2)),'polyline_mm',P,'tangent',t,'guardRow',false,'turn_deg',sg, ...
   'inRegime',all([chk.admissible])&&all([chk.clearanceOK]),'preCheck',chk, ...
   'source',struct('S8StateSHA256',hs,'terminalSHA256',ht,'manifestVerified',okS&&okT,'predictorEqualsTerminal',same,'S9tip_mm',F.polyline_mm(end,:))); %#ok<AGROW>
 end
end
T=struct('schema','NewMetacomp.G2.LP2A2.IndependentSet.v1','predeclared',true,'physicalSolves',0,'meshesBuilt',0, ...
 'rule','each full-precision S9 predictor extended to S11 with a constant local turn of +1 deg and -1 deg per 4-mm step', ...
 'regime',struct('states','S9-S11','tipGuideRadius_mm',15,'minGuideToRingClearance_mm',margin,'ladder_mm',[0.45 0.40 0.50 0.35]), ...
 'stopRule','any failure of an in-regime row: stop for review; no replacement, no tuning, no margin change','rows',{rows});
if nargin>1&&~isempty(outFile),fid=fopen(outFile,'w');fwrite(fid,jsonencode(T,'PrettyPrint',true),'char');fclose(fid);end
end

function ok=manOK(txt,rel,h)
tok=regexp(txt,['"',regexptranslate('escape',rel),'"\s*:\s*"([0-9a-f]{64})"'],'tokens','once');ok=~isempty(tok)&&strcmp(tok{1},h);
end
