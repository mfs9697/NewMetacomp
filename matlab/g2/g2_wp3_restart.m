function Rs = g2_wp3_restart(stepDir)
%G2_WP3_RESTART  Restart check of an accepted one-step state (WP3_PREREGISTRATION s.7, R2).
%  Rs = g2_wp3_restart(stepDir)   % stepDir = the transaction folder (state/ + mesh MAT)
% Verifies the state hash and the mesh hash recorded in it, re-solves the saved mesh,
% compares K with the recorded values and computes the next MTS forecast, which is
% RECORDED ONLY and NOT executed. Writes nothing.
Rs=struct('status','HOLD_STATE_INTEGRITY','KI_relDiff',[],'KII_relDiff',[],'nextForecast',struct(),'stateHash','');
[S,h,ok,why]=g2_wp3_state_io('load',fullfile(stepDir,'state'));Rs.stateHash=h;
if ~ok,Rs.status=why;return,end
mf=fullfile(stepDir,S.meshFile);
if ~isfile(mf)||~strcmp(g2_sha256_file(mf),S.meshSHA256),Rs.status='HOLD_MESH_INTEGRITY';return,end
D=load(mf);
K=g2_wp3_sif_on_mesh(D,struct('E',S.bvp.E_MPa,'nu',S.bvp.nu,'plane',S.bvp.plane));
Kr=hypot(S.KI_raw,S.KII_raw);
Rs.KI_relDiff=abs(K.KI-S.KI_raw)/Kr;Rs.KII_relDiff=abs(K.KII-S.KII_raw)/Kr;
M=g2_mts_direction(S.KI_MPa_sqrt_m_per_kN,S.KII_MPa_sqrt_m_per_kN);
Rs.nextForecast=struct('theta_deg',M.theta_deg,'status',M.status,'executed',false);
if max(Rs.KI_relDiff,Rs.KII_relDiff)<=1e-12&&K.pass,Rs.status='RESTART_VERIFIED';else,Rs.status='HOLD_RESTART_MISMATCH';end
Rs.state=S;
end
