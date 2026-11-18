function replay_compare(a,b)
% Compare two formal runs record by record (arrays, not MAT bytes).
f={'PHASE_MAP.mat','CASE_H1.mat','CASE_M0.mat','CASE_Msoft.mat','CASE_Mstiff.mat','BENCHMARK.mat'};
for k=1:numel(f)
 [ra,~,oka]=g2_trajectory_record('read',fullfile(a,f{k}));[rb,~,okb]=g2_trajectory_record('read',fullfile(b,f{k}));
 switch f{k}
  case 'PHASE_MAP.mat', same=isequal(ra.phase,rb.phase)&&isequal(ra.annulusOf,rb.annulusOf)&&isequal(ra.interfaces,rb.interfaces);
  case 'BENCHMARK.mat', same=isequal(ra.benchmark.values.dispRelErr,rb.benchmark.values.dispRelErr)&&isequal(ra.benchmark.values.interfaceMomentRelErr,rb.benchmark.values.interfaceMomentRelErr)&&isequal(ra.benchmark.checks,rb.benchmark.checks);
  otherwise, same=isequal(ra.u,rb.u)&&isequal(ra.EDI_all,rb.EDI_all)&&isequal(ra.EDI4x4,rb.EDI4x4)&&isequal([ra.KI_COD_raw ra.KII_COD_raw],[rb.KI_COD_raw rb.KII_COD_raw])&&isequal(ra.compliance_mm_per_N,rb.compliance_mm_per_N)&&isequal(ra.CMOD_mm,rb.CMOD_mm);
 end
 fprintf('REPLAY %-16s integrity %d/%d arrays bit-identical=%d\n',f{k},oka,okb,same);
end
La=jsondecode(fileread(fullfile(a,'LEDGER.json')));Lb=jsondecode(fileread(fullfile(b,'LEDGER.json')));
fprintf('REPLAY ratios table identical=%d, status %s/%s\n',isequal(La.results.ratios,Lb.results.ratios),La.status,Lb.status);
end
