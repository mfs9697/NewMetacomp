function smoke3(repo)
% Development crash test (disclosed): material SIF pipeline at ratio 1 only (no contrast case).
here=fullfile(repo,'matlab','g2');
polT=jsondecode(fileread(fullfile(here,'G2_TRAJECTORY_POLICY_v1.json')));
D=load(fullfile(repo,'outputs','g2_trajectory_chain_v1_attempt2','STEP_002','KINKED_GEOMETRY_ONLY_candidate.mat'));
c=[152.4 69.85;152.4 120.65;152.4 171.45];
PM=g2_material_phase_map(D.X6,D.T6,c,6.35*ones(3,1),19.05*ones(3,1),struct());
m=struct('E',3268.115,'nu',.35,'plane','stress');
tic;K0=g2_material_sif_on_mesh(D,PM.phase,[m,m],polT,PM);toc
disp(K0.criteria);fprintf('balance %.3g resultant %.3g sideL2 %s energyId %.3g PD %d\n',K0.interfaceBalanceRel,K0.annulusResultantRel,mat2str(K0.interfaceSideL2Rel',3),K0.energyIdentityRel,K0.KffPositiveDefinite);
tip=D.crackPolyline(end,:);E0=g2_sif_interaction(D.X6,D.T6,zeros(2*size(D.X6,1),1),m,tip,D.tipTangent(:).',.4,2.6,4);
pq=ones(size(PM.phase));pq(E0.activeRows(1))=2;
Kq=g2_material_sif_on_mesh(D,pq,[m,struct('E',2*3268.115,'nu',.35,'plane','stress')],polT,PM);
fprintf('q-negative: qSupportMatrixPhaseOnly=%d pass=%d\n',Kq.criteria.qSupportMatrixPhaseOnly,Kq.pass);
end
