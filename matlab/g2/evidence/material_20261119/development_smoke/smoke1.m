function smoke1(repo)
% Development smoke test (disclosed): phase map/verifier/negatives on State 2 and a coarse benchmark level only.
here=fullfile(repo,'matlab','g2');
pol=jsondecode(fileread(fullfile(here,'G2_MATERIAL_POLICY_v1.json')));
disp(size(pol.frozenGeometry.crackPolyline_mm));disp(size(pol.frozenGeometry.holeCenters_mm));disp(size(pol.sifGates.qAnnuli_mm));disp(size(pol.bvp.pin_mm));
D=load(fullfile(repo,'outputs','g2_trajectory_chain_v1_attempt2','STEP_002','KINKED_GEOMETRY_ONLY_candidate.mat'));
geo=struct('centers',pol.frozenGeometry.holeCenters_mm,'holeR',6.35*ones(3,1),'interfaceR',19.05*ones(3,1));
tic;PM=g2_material_phase_map(D.X6,D.T6,geo.centers,geo.holeR,geo.interfaceR,struct());toc
disp(PM.stage);disp(PM.message);
qa=pol.sifGates.qAnnuli_mm;
vopts=struct('onCircleTol_mm',1e-9,'minGap_mm',1e-3,'areaRelTol',1e-12,'domainAreaRelTol',1e-9,'outerArea_mm2',508*203.2, ...
 'twins',[D.upperBankT6(:),D.lowerBankT6(:)],'tip',D.crackPolyline(end,:),'tipGuideRadius_mm',15,'qOuterRadii_mm',qa(:,2),'minQClearance_mm',1,'voidTol_mm',1e-9);
tic;V=g2_material_phase_verify(D.X6,D.T6,PM.phase,geo.centers,geo.holeR,geo.interfaceR,vopts);toc
disp(V.pass);disp(V.failed);disp(V.checks);disp(V.values);
tic;NC=check_g2_material_phase_controls(D,PM,geo,vopts);toc
% exact field + coarse benchmark level only
p2=pol;p2.benchmark.Hmax_mm=[4.8;2.4];
tic;B=check_g2_material_benchmark(p2);toc
disp(B.checks);disp(B.failed);
end
