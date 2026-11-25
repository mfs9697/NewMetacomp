function R=g2_lp2_s5_geometry(execRepo,outFile)
%G2_LP2_S5_GEOMETRY  WP1 read-only audit of the accepted S4 states and geometry-only S5 candidates.
% No mesh generation, no FEM, no write except outFile. For H, stiff13, soft2, soft1:
%  1 A0 (run_a0_lp1_repro_v1) S0-S4 STATE records verify; A0 S4 equals the original LP1 S4
%    (polyline, tangent, signed K) bitwise;
%  2 the LP2 recurrence (g2_lp2_forecast) reproduces A0 S1-S4 polylines and tangents bitwise
%    from their A0 parents (validation of the continuation formula and sign conventions);
%  3 S5 candidates from the A0 S4 parent (mesh family of the propagation algorithm) and, for
%    comparison only, from the A1 B9 refinement of the same S4 geometry;
%  4 S5 geometry: lengths, arc, tip, heading, distances to rings / holes / plate, nonadjacent
%    clearance, g2_lp0_clearance guards (polygons of the saved S4 mesh), kink gates K1-K10 and
%    the LP2 terminal classification;
%  5 hypothetical outlook (NOT a prediction): repeated 4-mm steps with the S4 MTS increment
%    frozen, and straight steps, until the first guard fails.
g2=fullfile(execRepo,'matlab','g2');addpath(g2,'-begin');addpath(fileparts(mfilename('fullpath')),'-begin');
lp=jsondecode(fileread(fullfile(g2,'G2_LP1_POLICY_v2.json')));
J=jsondecode(fileread(fullfile(execRepo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json')));G=J.nominal_geometry_mm;
a1=jsondecode(fileread(fullfile(g2,'G2_A1_POLICY_v1.json')));
pol2=lp;pol2.caps=struct('firstStateIndex',1,'maxStateIndex',80,'initialArc_mm',25.4,'increment_mm',4,'maxArcLength_mm',25.4+4*80);
cases={'H','stiff13','soft2','soft1'};masks=[0 0 0;1 0 1;0 1 0;1 0 0];
A0=fullfile(execRepo,'outputs','g2_lp1_matrix_paths_v1','run_a0_lp1_repro_v1');
L1=fullfile(execRepo,'outputs','g2_lp1_matrix_paths_v1','run_20261122_lp1_v1');
C=lp.geometry.centres_mm;rows={};
for ci=1:4
 c=cases{ci};r=struct('caseId',c,'mask',masks(ci,:));
 S=cell(1,5);sh=cell(1,5);ok=true;
 for k=0:4
  [S{k+1},sh{k+1},okk]=g2_trajectory_record('read',fullfile(A0,c,sprintf('S%d',k),'STATE.mat'));ok=ok&&okk;
 end
 [So,sho,oko]=g2_trajectory_record('read',fullfile(L1,c,'S4','STATE.mat'));
 s4=S{5};
 r.a0StateSHA256=lower(sh{5});r.lp1StateSHA256=lower(sho);r.a0RecordsVerify=ok&&oko;
 r.a0EqualsLP1=isequal(s4.polyline_mm,So.polyline_mm)&&isequal(s4.tangent,So.tangent)&&isequal(s4.KI,So.KI)&&isequal(s4.KII,So.KII);
 % recurrence reproduction S1..S4
 rep=true;for k=1:4,F=g2_lp2_forecast(S{k},pol2);rep=rep&&isequal(F.polyline_mm,S{k+1}.polyline_mm)&&isequal(F.tangent,S{k+1}.tangent);end
 r.recurrenceReproducesA0=rep;
 % parents: A0 S4 (B0) and A1 B9
 D4=load(fullfile(A0,c,'S4','MESH.mat'));
 [B9,~,okb]=g2_trajectory_record('read',fullfile(execRepo,'outputs','g2_a1_fixed_path_v1','run_a1_family_b_s4_v1',[c '_B9'],'STATE.mat'));
 F0=g2_lp2_forecast(s4,pol2);pb=s4;pb.KI=B9.KI;pb.KII=B9.KII;F9=g2_lp2_forecast(pb,pol2);
 M0=g2_mts_direction(s4.KI,s4.KII);M9=g2_mts_direction(B9.KI,B9.KII);
 r.S4=struct('arc_mm',s4.arc_mm,'tip_mm',s4.polyline_mm(end,:),'heading_deg',atan2d(s4.tangent(2),s4.tangent(1)),'KI',s4.KI,'KII',s4.KII,'G',s4.G,'MTS_deg',M0.theta_deg);
 r.B9=struct('recordVerifies',okb,'KI',B9.KI,'KII',B9.KII,'MTS_deg',M9.theta_deg);
 r.S5_B0=struct('polyline_mm',F0.polyline_mm,'tip_mm',F0.polyline_mm(end,:),'tangent',F0.tangent,'heading_deg',F0.heading_deg,'arc_mm',F0.arc_mm,'parentMTS_deg',F0.parentMTS_deg);
 r.S5_B9=struct('tip_mm',F9.polyline_mm(end,:),'heading_deg',F9.heading_deg,'parentMTS_deg',F9.parentMTS_deg);
 r.B9minusB0=struct('MTS_deg',M9.theta_deg-M0.theta_deg,'tipDistance_mm',norm(F9.polyline_mm(end,:)-F0.polyline_mm(end,:)));
 % geometry of the B0 S5 candidate
 O=g2_m4b_ring_owner_oracle(D4.X6,D4.T6,C,6.35*ones(3,1),19.05*ones(3,1),struct('onCircleTol_mm',1e-9));
 geo=struct('centres',C,'ringPolygons',{cellfun(@(v)D4.X6(v,:),O.ringVertices,'UniformOutput',false)}, ...
  'holePolygons',{cellfun(@(v)D4.X6(v,:),O.holeVertices,'UniformOutput',false)});
 P5=F0.polyline_mm;Rc=g2_lp0_clearance(P5(1:end-1,:),P5(end,:),geo,pol2);
 Ka=g2_kink_admissibility(P5,G,'DeltaA_mm',4,'ExpectedVertices',7,'ExpectedTangent',F0.tangent,'TipGuideRadius_mm',15);
 Tc=g2_lp2_classify(Rc,masks(ci,:),pol2);
 tip=P5(end,:);
 r.S5_geometry=struct('segmentLengths_mm',vecnorm(diff(P5),2,2).','tipToRingCircle_mm',vecnorm(C-tip,2,2).'-19.05, ...
  'tipToHoleCircle_mm',vecnorm(C-tip,2,2).'-6.35,'plateMargins_mm',[tip(1),508-tip(1),tip(2),203.2-tip(2)], ...
  'clearancePass',Rc.pass,'clearanceStatus',Rc.status,'clearanceReasons',{Rc.reasons},'clearanceMetrics',Rc.metrics, ...
  'kinkGatesPass',Ka.pass,'kinkFailedGates',{Ka.failedGates},'kinkSummary',Ka.summary,'classification',Tc.classification, ...
  'activeInterfaceClearance_mm',Tc.activeInterfaceClearance_mm,'passiveContourClearance_mm',Tc.passiveContourClearance_mm);
 % hypothetical outlook
 for scen={'frozenMTS','straight'}
  st=s4;st.stateIndex=4;P=st.polyline_mm;t=st.tangent;th=M0.theta_rad;if strcmp(scen{1},'straight'),th=0;end
  n_ok=0;path=P(end,:);why='';cls='';
  for k=5:80
   nn=[-t(2),t(1)];t=cos(th)*t+sin(th)*nn;Q=[P;P(end,:)+4*t];
   Rk=g2_lp0_clearance(Q(1:end-1,:),Q(end,:),geo,pol2);
   Kk=g2_kink_admissibility(Q,G,'DeltaA_mm',4,'ExpectedVertices',size(Q,1),'ExpectedTangent',t,'TipGuideRadius_mm',15);
   if ~(Rk.pass&&Kk.pass)
    Tk=g2_lp2_classify(Rk,masks(ci,:),pol2);why=strjoin([Rk.reasons(:);Kk.failedGates(:)].',',');cls=Tk.classification;
    if Rk.pass,cls='NUMERICAL_HOLD';end
    obj=strjoin(unique({Tk.constraints.object}),',');break
   end
   P=Q;n_ok=n_ok+1;path(end+1,:)=P(end,:); %#ok<AGROW>
  end
  r.outlook.(scen{1})=struct('admissibleAdditionalStates',n_ok,'lastAdmissibleState',4+n_ok,'lastTip_mm',P(end,:), ...
   'lastArc_mm',sum(vecnorm(diff(P),2,2)),'firstFailure',why,'classification',cls,'objects',obj,'tips_mm',path, ...
   'lastTipToRingCircle_mm',vecnorm(C-P(end,:),2,2).'-19.05);
 end
 rows{end+1}=r; %#ok<AGROW>
 fprintf('LP2_S5 %-7s a0=lp1:%d rec=%d S5 tip=(%.4f,%.4f) head=%.3f clear=%s kink=%d class=%s | B9-B0 dTheta=%.2e deg dTip=%.2e mm | outlook frozen=%d (%s %s) straight=%d (%s %s)\n', ...
  c,r.a0EqualsLP1,r.recurrenceReproducesA0,tip,F0.heading_deg,Rc.status,Ka.pass,Tc.classification,r.B9minusB0.MTS_deg,r.B9minusB0.tipDistance_mm, ...
  r.outlook.frozenMTS.admissibleAdditionalStates,r.outlook.frozenMTS.classification,r.outlook.frozenMTS.objects, ...
  r.outlook.straight.admissibleAdditionalStates,r.outlook.straight.classification,r.outlook.straight.objects);
end
R=struct('schema','NewMetacomp.G2.LP2.S5Geometry.v1','physicalSolves',0,'meshesGenerated',0,'parentRun','run_a0_lp1_repro_v1', ...
 'a1PolicySHA256',lower(g2_sha256_file(fullfile(g2,'G2_A1_POLICY_v1.json'))),'rows',[rows{:}]);
R.a1MeshNote=a1.baselineS4.H.a0Run;
if nargin>1&&~isempty(outFile),fid=fopen(outFile,'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);end
end
