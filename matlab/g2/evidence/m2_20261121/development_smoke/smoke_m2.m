function smoke_m2(repo)
% Development smoke (disclosed): code analyzer, adapters, S0 homogeneous regression, ratio-table copy vs PR #35. No contrast solve.
here=fullfile(repo,'matlab','g2');
for f={'run_g2_m2_evolution_batch.m','g2_m2_state_adapter.m','g2_material_case_summary.m','g2_material_ratio_table.m'}
 m=checkcode(fullfile(here,f{1}),'-struct');fprintf('checkcode %s: %d messages\n',f{1},numel(m));for k=1:numel(m),fprintf('   L%d %s\n',m(k).line,m(k).message);end
end
pol=jsondecode(fileread(fullfile(here,'G2_M2_POLICY_v1.json')));polT=jsondecode(fileread(fullfile(here,'G2_TRAJECTORY_POLICY_v1.json')));
polM=jsondecode(fileread(fullfile(here,'G2_MATERIAL_POLICY_v1.json')));
disp(class(pol.states));
st=pol.states;if ~iscell(st),st=num2cell(st);end
mat=struct('E',3268.115,'nu',.35,'plane','stress');
for i=1:3
 S=st{i};D=load(fullfile(repo,S.mesh));[Dm,A]=g2_m2_state_adapter(D,S.id,S.polyline_mm);disp(A.checks);
 if i==1
  K=g2_trajectory_sif_on_mesh(Dm,mat,polT);rec=load(fullfile(repo,S.recordedK));
  fprintf('S0 pipeline: pass %d KI %.9f KII %+.9f (WP2 EDI %.9f %+.9f) COD %.9f %+.9f (WP2 COD %.9f %+.9f)\n',K.pass,K.KI*sqrt(1000),K.KII*sqrt(1000), ...
   rec.ed(1,1)*sqrt(1000),rec.ed(1,2)*sqrt(1000),K.KI_COD*sqrt(1000),K.KII_COD*sqrt(1000),rec.Cod.KI*sqrt(1000),rec.Cod.KII*sqrt(1000));
  disp(K.criteria);
 end
end
runC=fullfile(repo,'outputs','g2_material_contrast_v1','run_20261119_003430_660');ids={'H1','M0','Msoft','Mstiff'};
for k=1:4,[r,~,ok]=g2_trajectory_record('read',fullfile(runC,['CASE_',ids{k},'.mat']));assert(ok);r=rmfield(r,{'schema','u'});C.(ids{k})=r;end
D2=load(fullfile(repo,st{3}.mesh));
T=g2_material_ratio_table(C.H1,[C.M0,C.Msoft,C.Mstiff],polM,D2.tipTangent(:).');
Lc=jsondecode(fileread(fullfile(runC,'LEDGER.json')));Tc=Lc.results.ratios;
f={'R_EDI','R_COD','R_J','U_R','U_R_conservative','MTS_deg','dMTS_deg','complianceRatio','CMODratio'};dev=0;
for k=1:3,for q=1:numel(f),dev=max(dev,abs(T(k).(f{q})-Tc(k).(f{q}))/max(abs(Tc(k).(f{q})),1e-9));end,end
fprintf('ratio-table copy vs PR35 ledger: max rel dev %.3g; MTS root checks %s rad; tangent %.6f deg\n',dev,mat2str([T.MTSrootCheck_rad],3),T(1).tangentGlobal_deg);
end
