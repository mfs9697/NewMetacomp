r='<repo>/outputs/';
a=load([r 'g2_material_evolution_v1/run_20261121_132226_301/CASE_S0_H1.mat'],'record');B=a.record;
s=load([r 'g2_lp1_matrix_paths_v1/run_20261122_lp1_v1/H/S0/SOLUTION.mat']);K=s.record.K;
fn=fieldnames(B);fprintf('M2_FIELDS %s\n',strjoin(fn(1:min(40,end)),','));
fprintf('DET KI m2=%.17g lp1=%.17g equal=%d\n',B.KI_raw,K.KI,isequal(B.KI_raw,K.KI));
fprintf('DET KII m2=%.17g lp1=%.17g equal=%d\n',B.KII_raw,K.KII,isequal(B.KII_raw,K.KII));
if isfield(B,'J'),fprintf('DET J equal=%d\n',isequal(B.J,K.J));end
if isfield(B,'EDI_all'),fprintf('DET EDI_all equal=%d\n',isequal(B.EDI_all,K.EDI_all));end
if isfield(B,'u'),fprintf('DET u equal=%d\n',isequal(B.u,K.u));end
d=dir([r 'g2_material_evolution_v1/run_20261121_132226_301/CASE_S0_H1.mat']);fprintf('M2_FILE_DATE %s\n',d.date);
