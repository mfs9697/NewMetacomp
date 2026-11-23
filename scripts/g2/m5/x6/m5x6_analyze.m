function A=m5x6_analyze(execRepo,runName,campaignId,outFile)
%M5X6_ANALYZE  Preregistered post-calculation analysis of M5-X6 from saved records only. No FEM.
%
%  A = m5x6_analyze(execRepo,'run_m5x6_crossed_s4_b9_v1','G2-M5-X6-001',outFile)
% Refuses (G2M5X6:HOLD_NOT_EXECUTED) unless the campaign ledger is CLOSED and all six STATE
% records verify. Diagonal entries: the four A1 B9 states (file SHA-256 pinned in the plan).
% Per architecture X: 2x2 decomposition (m5x6_decompose) of G, J, K_I (relative to H on
% Gamma_H), K_II/|K_HH| and the MTS angle (absolute). Predictions P1-P3, the exploratory 2 U_m
% reference and informational numerical scales exactly as frozen in G2_M5_X6_PLAN_v1.json.
x6=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(fileparts(fileparts(x6))));
addpath(fullfile(execRepo,'matlab','g2'),'-begin');
plan=jsondecode(fileread(fullfile(x6,'G2_M5_X6_PLAN_v1.json')));
lroot=fullfile(execRepo,'outputs','g2_m5x6_campaign_ledger',campaignId);
rd=fullfile(execRepo,'outputs','g2_m5x6_crossed_v1',runName);
L=g2_lp1_campaign_ledger('snapshot',lroot);
assert(isequal(L.integrityOK,true)&&L.closed&&numel(L.admits)==6,'G2M5X6:HOLD_NOT_EXECUTED', ...
 'M5-X6 has not been executed and closed: no analysis without six verified states.');
cfg=plan.configurations;X=struct();
for k=1:6
 [St,sh,ok]=g2_trajectory_record('read',fullfile(rd,cfg(k).key,'STATE.mat'));
 assert(ok&&strcmp(St.config,cfg(k).id)&&strcmp(St.meshContentSHA256,cfg(k).meshContentSHA256)&& ...
  isequal(St.swappedMaterialAudit.pass,true),'G2M5X6:HOLD_RECORD_INTEGRITY','State %s fails verification.',cfg(k).id);
 St.fileSHA256=lower(sh);X.(cfg(k).key)=St;
end
dg=plan.diagonal;Dg=struct();
for k=1:4
 f=fullfile(execRepo,'outputs','g2_a1_fixed_path_v1',plan.a1.runName,dg(k).key,'STATE.mat');
 [St,sh,ok]=g2_trajectory_record('read',f);
 assert(ok&&strcmpi(sh,dg(k).stateFileSHA256),'G2M5X6:HOLD_RECORD_INTEGRITY','A1 diagonal %s differs from its pin.',dg(k).key);
 Dg.(dg(k).caseId)=St;
end
a1=jsondecode(fileread(fullfile(repo,'matlab','g2','evidence','a1_campaign_20261122','campaign','A1_ANALYSIS.json')));
Um=3.1e-5;Uth=8e-4;arch={'stiff13','soft2','soft1'};
A=struct('schema','NewMetacomp.G2.M5X6.Analysis.v1','runName',runName,'campaignId',campaignId, ...
 'reference','H on Gamma_H (A1 H_B9)','explorationReference',struct('U_m',Um,'U_theta_deg',Uth, ...
 'meaning','exploratory S2 mesh-family sensitivity (R1); not a certified S4 error bound'),'soft2','INCONCLUSIVE (unchanged)');
HH=Dg.H;KHH=hypot(HH.KI,HH.KII);
for a=1:3
 x=arch{a};XX=Dg.(x);
 XH=X.(cfg(strcmp({cfg.pathCase},'H')&strcmp({cfg.materialCase},x)).key);
 HX=X.(cfg(strcmp({cfg.pathCase},x)&strcmp({cfg.materialCase},'H')).key);
 r=struct();
 r.G=m5x6_decompose(HH.G,XH.G,HX.G,XX.G,'relative');
 r.J=m5x6_decompose(HH.J,XH.J,HX.J,XX.J,'relative');
 r.KI=m5x6_decompose(HH.KI,XH.KI,HX.KI,XX.KI,'relative');
 r.KIIoverK=m5x6_decompose(HH.KII/KHH,XH.KII/KHH,HX.KII/KHH,XX.KII/KHH,'absolute');
 r.MTS_deg=m5x6_decompose(HH.MTS_deg,XH.MTS_deg,HX.MTS_deg,XX.MTS_deg,'absolute');
 g=r.G;
 r.P1_directShare=abs(g.F_mat)/abs(g.F_tot);r.P1_pass=abs(g.F_mat)>=0.9*abs(g.F_tot);
 r.P2_pass=sign(g.F_pathPlusInt)==-sign(g.F_mat)&&g.F_pathPlusInt~=0;
 r.P3_signs=struct('F_path',sign(g.F_path),'F_int',sign(g.F_int));
 r.exceeds2Um=struct('F_mat',abs(g.F_mat)>2*Um,'F_path',abs(g.F_path)>2*Um,'F_int',abs(g.F_int)>2*Um, ...
  'F_pathPlusInt',abs(g.F_pathPlusInt)>2*Um);
 t=r.MTS_deg;r.exceeds2Utheta=struct('F_mat',abs(t.F_mat)>2*Uth,'F_path',abs(t.F_path)>2*Uth,'F_int',abs(t.F_int)>2*Uth);
 r.informational=struct('A1_absF_G_B9minusB6',abs(a1.F_G_B9minusB6.(x)), ...
  'CODminusEDI_rel_XH',max(abs([XH.KI_COD-XH.KI,XH.KII_COD-XH.KII]))/hypot(XH.KI,XH.KII), ...
  'CODminusEDI_rel_HX',max(abs([HX.KI_COD-HX.KI,HX.KII_COD-HX.KII]))/hypot(HX.KI,HX.KII));
 r.records=struct('XH',XH.config,'HX',HX.config,'XH_stateSHA256',XH.fileSHA256,'HX_stateSHA256',HX.fileSHA256);
 A.(x)=r;
 fprintf('M5X6 %-7s F_G %+.6e = mat %+.6e + path %+.6e + int %+.6e (res %.1e) P1=%d P2=%d\n', ...
  x,g.F_tot,g.F_mat,g.F_path,g.F_int,g.identityResidual,r.P1_pass,r.P2_pass);
end
fid=fopen(outFile,'w');fwrite(fid,jsonencode(A,'PrettyPrint',true),'char');fclose(fid);
end
