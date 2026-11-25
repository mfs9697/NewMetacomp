function Q=g2_m5x6_configuration_check(C,cfg)
%G2_M5X6_CONFIGURATION_CHECK  Non-solving qualification of one crossed (or diagonal) configuration.
%
%  Q = g2_m5x6_configuration_check(C,cfg)
% C: g2_m5x6_context output (or a struct with fields repo, g2, a1.policy).
% cfg: struct with id, pathCase, meshKey, meshContentSHA256, materialCase, mask, ratio.
% Loads the PATH-case B9 mesh and its A0 S4 baseline, checks content SHA-256 against the A1
% policy and the plan pin, runs the unchanged g2_a1_mesh_validate, checks the crack polyline
% (bitwise equal to the A0 S4 baseline, arclength 41.4 mm), builds the unchanged phase map and the
% MATERIAL-case activation, and runs the independent M4.B activation verifier (owner oracle, phase
% from mask, area identities, chord jumps, q support and tip guide owner-free, q clearance,
% connectivity, twins, materials). Returns everything the solve needs. No FEM, no write.
pol=C.a1.policy;g2=C.g2;
lp=jsondecode(fileread(fullfile(g2,'G2_LP1_POLICY_v2.json')));
pm=jsondecode(fileread(fullfile(g2,'G2_MATERIAL_POLICY_v1.json')));
ids={pol.cases.id};im=find(strcmp(ids,cfg.materialCase));ip=find(strcmp(ids,cfg.pathCase));
assert(isscalar(im)&&isscalar(ip)&&strcmp(cfg.meshKey,[cfg.pathCase '_B9'])&& ...
 isequal(reshape(cfg.mask,1,3),reshape(pol.cases(im).mask,1,3))&&cfg.ratio==pol.cases(im).ratio, ...
 'G2M5X6:HOLD_INPUT','Configuration %s is not a policy path x material pair.',cfg.id);
mask=logical(reshape(cfg.mask,1,3));ratio=cfg.ratio;
% ---- mesh identity and quality (A1 checks, unchanged)
mf=fullfile(C.repo,strrep(pol.meshRoot,'/',filesep),cfg.pathCase,'B9','MESH.mat');
D=load(mf);sha=g2_a1_mesh_content_sha(D);
assert(strcmp(sha,pol.meshes.(cfg.meshKey).contentSHA256)&&strcmp(sha,cfg.meshContentSHA256), ...
 'G2M5X6:HOLD_SOURCE','Mesh content of %s differs from the preregistration.',cfg.meshKey);
D0=load(fullfile(C.repo,strrep(pol.baselineS4.(cfg.pathCase).path,'/',filesep)));
assert(strcmp(g2_a1_mesh_content_sha(D0),pol.baselineS4.(cfg.pathCase).contentSHA256), ...
 'G2M5X6:HOLD_SOURCE','A0 S4 baseline mesh of %s differs.',cfg.pathCase);
V=g2_a1_mesh_validate(D,D0);
assert(V.pass,'G2M5X6:HOLD_MESH_QUALITY','A1 mesh validation failed: %s',strjoin(V.failedGates,','));
P=D.crackPolyline;arc=sum(vecnorm(diff(P,1,1),2,2));tipGap=norm(P(end,:)-D.X3(D.physicalTipNode,:));
assert(isequal(P,D0.crackPolyline)&&abs(arc-41.4)<=1e-9&&tipGap<=1e-12, ...
 'G2M5X6:HOLD_SOURCE','Crack polyline of %s is not the frozen A0 S4 path (arclength %.12g mm).',cfg.meshKey,arc);
% ---- phase map, activation and independent verification
addpath(fullfile(g2,'vendor_p010_a14d8872'),'-begin');
g=lp.geometry;cen=reshape(g.centres_mm,[],2);if ~isequal(cen(:,1),[152.4;152.4;152.4]),cen=reshape(g.centres_mm.',[],2);end
PM=g2_material_phase_map(D.X6,D.T6,g.centres_mm,6.35*ones(3,1),19.05*ones(3,1),struct('onCircleTol_mm', ...
 pm.phaseMap.onCircleTolerance_mm,'minGap_mm',pm.phaseMap.minGapToNextT3Vertex_mm,'midsideTol_mm',pm.phaseMap.midsideOnChordTolerance_mm));
assert(PM.pass,'G2M5X6:HOLD_OWNER_MASK','Phase map failed on %s: %s',cfg.meshKey,PM.stage);
act=g2_m4b_ring_activation(PM.annulusOf,double(mask));
Em=lp.bvp.E_MPa;mk=@(E)struct('E',E,'nu',lp.bvp.nu,'plane','stress');mats=[mk(Em),mk(Em*ratio)];
qa=reshape(pm.sifGates.qAnnuli_mm,[],2);if size(qa,1)~=5,qa=reshape(pm.sifGates.qAnnuli_mm.',[],2);end
fg=pm.frozenGeometry;geo=struct('centres',cen,'holeR',6.35*ones(3,1),'ringR',19.05*ones(3,1));
if any(mask),ct=ratio;else,ct='none';end
vo=struct('onCircleTol_mm',pm.phaseMap.onCircleTolerance_mm,'midsideTol_mm',pm.phaseMap.midsideOnChordTolerance_mm, ...
 'areaRelTol',pm.phaseMap.areaIdentityRelTol,'domainAreaRelTol',pm.phaseMap.plateAreaIdentityRelTol,'outerArea_mm2',prod(fg.plate_mm), ...
 'expectedChords',76,'E_matrix',Em,'nu',lp.bvp.nu,'thickness_mm',lp.bvp.thickness_mm,'tip',P(end,:), ...
 'tipGuideRadius_mm',fg.tipGuideRadius_mm,'qOuterRadii_mm',qa(:,2),'minQClearance_mm',pm.sifGates.minQSupportClearanceToReinforcement_mm, ...
 'twins',[D.upperBankT6(:),D.lowerBankT6(:)],'contrast',ct);
A=g2_m4b_activation_verify(D.X6,D.T6,PM.annulusOf,act.phaseForAssembly,double(mask),mats,geo,vo);
expActive=nnz(ismember(PM.annulusOf,find(mask)));
ext=struct('activeCountEqualsOwnerCount',act.activeElements==expActive, ...
 'phaseOnlyOnActiveRings',all(act.phaseForAssembly(~ismember(PM.annulusOf,find(mask)))==1)&&all(act.phaseForAssembly(ismember(PM.annulusOf,find(mask)))==2), ...
 'ringMaterialRatio',mats(2).E==Em*ratio&&mats(1).E==Em&&mats(1).nu==mats(2).nu);
pass=A.pass&&all(cell2mat(struct2cell(ext)));
assert(pass,'G2M5X6:HOLD_OWNER_MASK','Activation verification of %s failed: %s',cfg.id,strjoin([A.failed(:);fieldnames(ext)].',','));
Q=struct('pass',true,'id',cfg.id,'pathCase',cfg.pathCase,'materialCase',cfg.materialCase,'meshKey',cfg.meshKey, ...
 'meshContentSHA256',sha,'baselineContentSHA256',pol.baselineS4.(cfg.pathCase).contentSHA256, ...
 'meshGates',sprintf('%d/%d',V.gatesPassed,V.gatesTotal),'T3',size(D.T6,1),'DOF',2*size(D.X6,1), ...
 'crackArclength_mm',arc,'tip_mm',P(end,:),'tipNodeGap_mm',tipGap,'polylineBitwiseEqualA0S4',true,'mask',char('0'+mask),'ratio',ratio, ...
 'ringElements',A.values.ringElements,'ringArea_mm2',A.values.ringArea_mm2,'activeElements',act.activeElements, ...
 'activeArea_mm2',A.values.activeArea_mm2,'jumpEdges',A.values.jumpEdges,'qClearance_mm',A.values.qClearance_mm, ...
 'oracleMismatches',A.values.oracleMismatches,'verifierChecks',A.checks,'extraChecks',ext);
Q.D=D;Q.PM=PM;Q.act=act;Q.mats=mats;Q.meshValidation=V;Q.Em=Em;Q.lp=lp;
end
