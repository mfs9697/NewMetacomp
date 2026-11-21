function replay_compare_m2(a,b)
% Compare two M2 formal runs record by record (arrays, not MAT bytes).
st={'S0','S1','S2','S2alt'};cs={'H1','M0','Msoft','Mstiff'};all_ok=true;
for i=1:4
 [ra,~,oa]=g2_trajectory_record('read',fullfile(a,['PHASE_MAP_',st{i},'.mat']));[rb,~,ob]=g2_trajectory_record('read',fullfile(b,['PHASE_MAP_',st{i},'.mat']));
 s=oa&&ob&&isequal(ra.phase,rb.phase)&&isequal(ra.interfaces,rb.interfaces);all_ok=all_ok&&s;
 fprintf('REPLAY PHASE_MAP_%-6s %d\n',st{i},s);
 for k=1:4
  f=['CASE_',st{i},'_',cs{k},'.mat'];
  [ra,~,oa]=g2_trajectory_record('read',fullfile(a,f));[rb,~,ob]=g2_trajectory_record('read',fullfile(b,f));
  s=oa&&ob&&isequal(ra.u,rb.u)&&isequal(ra.EDI_all,rb.EDI_all)&&isequal(ra.EDI4x4,rb.EDI4x4)&&isequal([ra.KI_COD_raw ra.KII_COD_raw],[rb.KI_COD_raw rb.KII_COD_raw])&& ...
   isequal(ra.compliance_mm_per_N,rb.compliance_mm_per_N)&&isequal(ra.CMOD_mm,rb.CMOD_mm);all_ok=all_ok&&s;
  fprintf('REPLAY %-22s %d\n',f,s);
 end
end
Ma=load(fullfile(a,'S2ALT_KINKED_GEOMETRY_ONLY_candidate.mat'));Mb=load(fullfile(b,'S2ALT_KINKED_GEOMETRY_ONLY_candidate.mat'));
s=isequal(Ma,Mb);all_ok=all_ok&&s;fprintf('REPLAY S2ALT mesh arrays %d\n',s);
La=jsondecode(fileread(fullfile(a,'LEDGER.json')));Lb=jsondecode(fileread(fullfile(b,'LEDGER.json')));
s=isequal(La.summary,Lb.summary);all_ok=all_ok&&s;fprintf('REPLAY summary identical %d, status %s/%s\n',s,La.status,Lb.status);
fprintf('REPLAY_ALL_IDENTICAL=%d\n',all_ok);
end
