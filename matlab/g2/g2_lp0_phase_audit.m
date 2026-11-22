function R=g2_lp0_phase_audit(D,P,pol)
% Re-map every mesh and independently verify all four activity masks, no FEM.
here=fileparts(mfilename('fullpath'));pm=jsondecode(fileread(fullfile(here,'G2_MATERIAL_POLICY_v1.json')));
[PM,V,NC,geometry]=g2_material_phase_stage(D,pm,P);
R=struct('pass',false,'map',PM.pass,'legacyVerifier',V.pass,'legacyNegatives',NC.pass,'geometry',geometry);
if ~(PM.pass&&V.pass&&NC.pass),return,end
C=pol.geometry.centres_mm;geo=struct('centres',C,'holeR',6.35*ones(3,1),'ringR',19.05*ones(3,1));
O=g2_m4b_ring_owner_oracle(D.X6,D.T6,C,geo.holeR,geo.ringR,struct('onCircleTol_mm',1e-9));
R.ownerOracle=O.pass&&isequal(O.ownerOracle,PM.annulusOf);if ~R.ownerOracle,return,end
opts=struct('onCircleTol_mm',1e-9,'midsideTol_mm',1e-9,'areaRelTol',1e-12,'domainAreaRelTol',1e-9, ...
 'outerArea_mm2',508*203.2,'expectedChords',76,'E_matrix',3268.115,'nu',.35,'thickness_mm',12.7, ...
 'tip',P(end,:),'tipGuideRadius_mm',15,'qOuterRadii_mm',pol.qAnnuli_mm(:,2),'minQClearance_mm',1, ...
 'twins',[D.upperBankT6(:),D.lowerBankT6(:)]);
mk=@(E)struct('E',E,'nu',.35,'plane','stress');R.cases=struct();
for k=1:4
 c=pol.cases(k);mask=reshape(c.mask,1,3);act=g2_m4b_ring_activation(PM.annulusOf,mask);
 mats=[mk(3268.115),mk(3268.115*c.ratio)];opts.contrast=c.ratio;
 if strcmp(c.id,'H'),opts.contrast='none';end
 A=g2_m4b_activation_verify(D.X6,D.T6,PM.annulusOf,act.phaseForAssembly,mask,mats,geo,opts);
 R.cases.(c.id)=rmfield(A,'ownerOracle');
end
R.activationNegatives=check_g2_m4b_activation_negatives(D,PM,geo,opts,mk);
R.pass=R.activationNegatives.pass&&all(arrayfun(@(c)R.cases.(c.id).pass,pol.cases));
R.clearanceGeometry=struct('centres',C,'ringPolygons',{{}},'holePolygons',{{}});
for h=1:3
 R.clearanceGeometry.ringPolygons{h}=D.X6(O.ringVertices{h},:);
 R.clearanceGeometry.holePolygons{h}=D.X6(O.holeVertices{h},:);
end
end
