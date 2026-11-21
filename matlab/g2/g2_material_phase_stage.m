function [PM,V,NC,geom] = g2_material_phase_stage(Dm,polM,P)
%G2_MATERIAL_PHASE_STAGE  Phase map + independent verifier + state-aware negatives (Issue #39).
%
%  [PM,V,NC,geom] = g2_material_phase_stage(Dm,polM,P)
% Verbatim copy of the local function phase_stage() of run_g2_m2_evolution_batch.m (PR #38,
% unchanged there): Dm a saved mesh struct with banks/anchors, polM = G2_MATERIAL_POLICY_v1,
% P the crack polyline (tip = last row). Returns the PR #35 mapper result, the separate
% verifier, the state-aware negatives (check_g2_m2_phase_controls) and geometry metrics.
fg=polM.frozenGeometry;pm=polM.phaseMap;
c=reshape(fg.holeCenters_mm,[],2);if ~isequal(c(:,1),[152.4;152.4;152.4]),c=reshape(fg.holeCenters_mm.',[],2);end
geo=struct('centers',c,'holeR',fg.holeRadius_mm*ones(3,1),'interfaceR',fg.interfaceRadius_mm*ones(3,1));
PM=g2_material_phase_map(Dm.X6,Dm.T6,geo.centers,geo.holeR,geo.interfaceR, ...
 struct('onCircleTol_mm',pm.onCircleTolerance_mm,'minGap_mm',pm.minGapToNextT3Vertex_mm,'midsideTol_mm',pm.midsideOnChordTolerance_mm));
V=struct('pass',false,'failed',{{'not run'}});NC=struct('pass',false);geom=struct();
fprintf('PHASE_MAP pass=%d %s: %s\n',PM.pass,PM.stage,PM.message);
if ~PM.pass,return,end
qa=reshape(polM.sifGates.qAnnuli_mm,[],2);if size(qa,1)~=5,qa=reshape(polM.sifGates.qAnnuli_mm.',[],2);end
vopts=struct('onCircleTol_mm',pm.onCircleTolerance_mm,'minGap_mm',pm.minGapToNextT3Vertex_mm,'areaRelTol',pm.areaIdentityRelTol, ...
 'domainAreaRelTol',pm.plateAreaIdentityRelTol,'outerArea_mm2',prod(fg.plate_mm),'twins',[Dm.upperBankT6(:),Dm.lowerBankT6(:)], ...
 'tip',P(end,:),'tipGuideRadius_mm',fg.tipGuideRadius_mm,'qOuterRadii_mm',qa(:,2),'minQClearance_mm',polM.sifGates.minQSupportClearanceToReinforcement_mm, ...
 'voidTol_mm',pm.voidPenetrationTolerance_mm);
V=g2_material_phase_verify(Dm.X6,Dm.T6,PM.phase,geo.centers,geo.holeR,geo.interfaceR,vopts);
fprintf('PHASE_VERIFY pass=%d failed=[%s]\n',V.pass,strjoin(V.failed,','));
if ~V.pass,return,end
NC=check_g2_m2_phase_controls(Dm,PM,geo,vopts);
v=V.values;
x=Dm.X6(:,1);y=Dm.X6(:,2);T3=Dm.T6(:,1:3);
Ael=.5*((x(T3(:,2))-x(T3(:,1))).*(y(T3(:,3))-y(T3(:,1)))-(x(T3(:,3))-x(T3(:,1))).*(y(T3(:,2))-y(T3(:,1))));
geom=struct('counts',v.counts,'chordsPerCircle',v.chordsPerCircle,'holeVerticesPerCircle',v.holeVerticesPerCircle, ...
 'annulusArea_mm2',v.annulusArea_mm2,'annulusNominalArea_mm2',v.annulusNominalArea_mm2,'polygonVsNominalRel',v.polygonVsNominalRel, ...
 'bandVolumeFraction',sum(Ael(PM.phase==2))/sum(Ael),'tipToBand_mm',v.reinforcementNodeMinDistanceToTip_mm,'qClearance_mm',v.qClearance_mm, ...
 'mixedEdges',v.mixedEdges,'coincidentPairs',v.coincidentPairs,'domainAreaRelErr',v.domainAreaRelErr,'annulusAreaRelErr',v.annulusAreaRelErr);
end
