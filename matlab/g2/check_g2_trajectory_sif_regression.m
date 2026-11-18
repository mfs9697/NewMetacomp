function T=check_g2_trajectory_sif_regression(seedStepDir)
%CHECK_G2_TRAJECTORY_SIF_REGRESSION  Regression test for WP3.4 HOLD-1 (policy anchor shape).
%  T = check_g2_trajectory_sif_regression()   % original WP3 step1_a (read only)
% The first State 2 attempt stopped in g2_trajectory_sif_on_mesh before the solve:
% jsondecode returns the policy pin/roller/load coordinates as 2x1 columns and the
% anchor lookup subtracted them from the 3x2 extra-vertex array. This test runs the
% FIXED routine, with the policy decoded exactly as the controller decodes it, on the
% ACCEPTED, hash-checked WP3 State 1 mesh and requires it to reproduce the recorded
% State 1 K (same solver and EDI as WP3.2). One elasticity solve on an existing mesh;
% no new geometry, no new State, nothing written.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
if nargin<1||isempty(seedStepDir)
 seedStepDir=fullfile(repo,'outputs','g2_wp3_state','run_20261118_185808_963','step1_a');
end
policy=jsondecode(fileread(fullfile(here,'G2_TRAJECTORY_POLICY_v1.json')));
assert(isequal(size(policy.bvp.pin_mm),[2 1]),'G2SifReg:Shape','Expected jsondecode column (the HOLD-1 trigger).');
[S1,h1,ok,why]=g2_wp3_state_io('load',fullfile(seedStepDir,'state'));
assert(ok,'G2SifReg:State','State 1: %s',why);
mf=fullfile(seedStepDir,S1.meshFile);
assert(strcmpi(g2_sha256_file(mf),S1.meshSHA256),'G2SifReg:Mesh','State 1 mesh hash.');
D=load(mf);
mat=struct('E',S1.bvp.E_MPa,'nu',S1.bvp.nu,'plane',S1.bvp.plane);
K=g2_trajectory_sif_on_mesh(D,mat,policy);
Kr=hypot(S1.KI_raw,S1.KII_raw);
dEDI=max(abs([K.KI-S1.KI_raw,K.KII-S1.KII_raw]))/Kr;
dCOD=max(abs([K.KI_COD*sqrt(1000)-S1.KI_COD_MPa_sqrt_m_per_kN,K.KII_COD*sqrt(1000)-S1.KII_COD_MPa_sqrt_m_per_kN]))/(Kr*sqrt(1000));
T=struct('state1SHA256',h1,'KI',K.KI_MPa_sqrt_m_per_kN,'KII',K.KII_MPa_sqrt_m_per_kN, ...
 'KI_recorded',S1.KI_MPa_sqrt_m_per_kN,'KII_recorded',S1.KII_MPa_sqrt_m_per_kN, ...
 'relDiffEDI',dEDI,'relDiffCOD',dCOD,'criteria',K.criteria,'sifPass',K.pass, ...
 'wholeCrackOpeningMin_mm',K.fullPolyOpeningMin_mm,'statics',K.statics,'EDI4x4',K.EDI4x4);
T.pass=dEDI<=1e-12&&dCOD<=1e-12&&K.pass;
fprintf('SIFREG State 1: KI %.9f (recorded %.9f) KII %+.9f (recorded %+.9f); dEDI %.3e dCOD %.3e; criteria pass %d; min opening %.4g mm\n', ...
 T.KI,T.KI_recorded,T.KII,T.KII_recorded,dEDI,dCOD,K.pass,K.fullPolyOpeningMin_mm);
fprintf('G2_TRAJECTORY_SIF_REGRESSION_PASS=%d\n',T.pass);
end
