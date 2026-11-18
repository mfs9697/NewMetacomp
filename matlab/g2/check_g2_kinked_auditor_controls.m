function K=check_g2_kinked_auditor_controls(meshRunDir,p0RunDir,straightMeshRunDir)
%CHECK_G2_KINKED_AUDITOR_CONTROLS  WP3.1 negative controls N1-N9 for g2_kinked_mesh_auditor (WP3_PREREGISTRATION s.5).
% Each control corrupts an in-memory COPY of the accepted kinked mesh (or of the JSON,
% written to a temporary copy inside the new run folder) and requires the auditor to
% return pass = false with a failing gate of the expected group. The baseline
% (uncorrupted) record must pass. Saved inputs are never modified.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
json=fullfile(repo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json');
p0MAT=fullfile(char(p0RunDir),'P010_ISOLATED_REGULAR_ONLY.mat');
outRoot=fullfile(repo,'outputs','g2_wp3_auditor_controls');if ~exist(outRoot,'dir'),mkdir(outRoot);end
folder=fullfile(outRoot,['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);assert(~exist(folder,'dir'));mkdir(folder);
diary(fullfile(folder,'controls_console.log'));c=onCleanup(@()diary('off')); %#ok<NASGU>
fprintf('STAGE=G2_WP3_1_AUDITOR_NEGATIVE_CONTROLS\nDATE=%s\nMESH=%s\nSTRAIGHT=%s\n',datestr(now,31),meshRunDir,straightMeshRunDir);
D0=load(fullfile(char(meshRunDir),'KINKED_GEOMETRY_ONLY_candidate.mat'));
K=struct('pass',false,'baseline',struct(),'controls',struct([]),'exception','');
try
 B=g2_kinked_mesh_auditor(D0,json,p0MAT);K.baseline=struct('pass',B.pass,'gatesPassed',B.gatesPassed,'gatesTotal',B.gatesTotal);
 assert(B.pass,'G2KC:Baseline','Baseline kinked record does not pass; controls are meaningless.');
 P=D0.crackPolyline;t=D0.tipTangent;n=[-t(2),t(1)];U=D0.upperBankT6;L=D0.lowerBankT6;tipID=D0.physicalTipNode;
 cases={};
 % N1 bad bend: saved kink vertex moved off the mesh
 D=D0;D.crackPolyline(2,:)=P(2,:)+[.05 0];cases(end+1,:)={'N1_badBend_kinkVertexMoved',D,json,{'G3','G5'}};
 % N2 bad miter: upper kink node displaced 0.01 mm along n of segment 1
 D=D0;ku=intersect(find(vecnorm(D.X3-P(2,:),2,2)<1e-12),U);D.X3(ku,:)=D.X3(ku,:)+.01*[-1 0];D.X6(ku,:)=D.X3(ku,:);
 cases(end+1,:)={'N2_badMiter_kinkNodeDisplaced',D,json,{'G5'}};
 % N3 welded banks on the final segment
 D=D0;sL=(D.X6(L,:)-P(2,:))*t.';Lf=L(sL>1e-9&L~=tipID);mapW=(1:size(D.X6,1))';
 for i=1:numel(Lf),j=U(vecnorm(D.X6(U,:)-D.X6(Lf(i),:),2,2)<1e-9);assert(isscalar(j));mapW(Lf(i))=j;end
 D.T6=mapW(D.T6);D.T3=D.T6(:,1:3);cases(end+1,:)={'N3_weldedBanks_finalSegment',D,json,{'G5'}};
 % N4 seam mismatch: one r = 3.3 seam node moved 1e-6 mm radially
 D=D0;s=D.collarOuterIDs(10);D.X3(s,:)=D.X3(s,:)+1e-6*(D.X3(s,:)-P(end,:))/norm(D.X3(s,:)-P(end,:));D.X6(s,:)=D.X3(s,:);
 cases(end+1,:)={'N4_seamNodeMovedRadially',D,json,{'G7'}};
 % N5 wrong hole: hole 2 centre shifted 0.5 mm in a JSON copy
 J=jsondecode(fileread(json));J.nominal_geometry_mm.holes(2).center(1)=J.nominal_geometry_mm.holes(2).center(1)+.5;
 bad=fullfile(folder,'N5_wrong_hole_geometry_copy.json');fj=fopen(bad,'w');fwrite(fj,jsonencode(J),'char');fclose(fj);
 cases(end+1,:)={'N5_wrongHoleCentre',D0,bad,{'G3'}};
 % N6 inverted exterior element (consistent T3/T6 corner swap)
 D=D0;e=D.elementRows.exterior(100);D.T3(e,:)=D.T3(e,[2 1 3]);D.T6(e,:)=D.T6(e,[2 1 3 4 6 5]);
 cases(end+1,:)={'N6_invertedElement',D,json,{'G2'}};
 % N7 clipped q
 D=D0;qn=find(D.nodalQ>0&D.nodalQ<1);D.nodalQ(qn(1:10))=0;cases(end+1,:)={'N7_clippedQ',D,json,{'G9'}};
 % N8 intersecting geometry: segment 2 into hole 1; 100 deg fold
 D=D0;D.crackPolyline(3,:)=[152.4-6.35+1,69.85];cases(end+1,:)={'N8a_segmentIntoHole1',D,json,{'G10'}};
 D=D0;tf=[cosd(100)*0-sind(100)*1,sind(100)*0+cosd(100)*1];D.crackPolyline(3,:)=P(2,:)+4*tf;
 cases(end+1,:)={'N8b_fold100deg',D,json,{'G10'}};
 % N9 straight WP2 family-A mesh presented with the kinked polyline
 Ds=load(fullfile(char(straightMeshRunDir),'GEOMETRY_ONLY_candidate.mat'));Ds.crackPolyline=P;Ds.tipTangent=t;
 cases(end+1,:)={'N9_straightMeshKinkedManifest',Ds,json,{'G5','G6','G8'}};
 allOK=true;
 for k=1:size(cases,1)
  try
   A=g2_kinked_mesh_auditor(cases{k,2},cases{k,3},p0MAT);fg=A.failedGates;ex='';
  catch ME2
   A=struct('pass',false);fg={};ex=ME2.message;
  end
  hit=any(cellfun(@(x)any(startsWith(fg,x)),cases{k,4}));
  detected=~A.pass&&(hit||~isempty(ex));
  allOK=allOK&&detected;
  r=struct('id',cases{k,1},'auditorPass',A.pass,'failedGates',{fg},'expectedGroups',{cases{k,4}},'exception',ex,'detected',detected);
  if isempty(K.controls),K.controls=r;else,K.controls(end+1)=r;end
  fprintf('%-34s pass=%d detected=%d failed=[%s] %s\n',cases{k,1},A.pass,detected,strjoin(fg,','),ex);
 end
 K.pass=allOK;
catch ME
 K.exception=getReport(ME,'extended','hyperlinks','off');fprintf(2,'G2_KC_EXCEPTION=%s\n',K.exception);
end
f=fopen(fullfile(folder,'auditor_controls_summary.json'),'w');fwrite(f,jsonencode(K,'PrettyPrint',true),'char');fclose(f);
fprintf('G2_WP3_AUDITOR_CONTROLS_PASS=%d\n',K.pass);
if ~K.pass,error('G2KC:HOLD','Negative controls HOLD (see %s).',folder);end
end
