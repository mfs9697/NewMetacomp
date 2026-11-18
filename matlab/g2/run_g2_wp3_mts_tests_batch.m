function V=run_g2_wp3_mts_tests_batch()
%RUN_G2_WP3_MTS_TESTS_BATCH  WP3.0 analytic MTS tests A1-A9 and the reference manifest (Issue #24).
% Pure algebra (WP3_PREREGISTRATION.md s.2). No mesh, no FEM. Writes a NEW
% outputs/g2_wp3_mts/run_* folder with the console log, the test summary JSON
% and WP3_REFERENCE_MANIFEST.json (analytical trial geometry, NOT propagation).
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
outRoot=fullfile(repo,'outputs','g2_wp3_mts');if ~exist(outRoot,'dir'),mkdir(outRoot);end
folder=fullfile(outRoot,['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);assert(~exist(folder,'dir'));mkdir(folder);
diary(fullfile(folder,'mts_tests_console.log'));c=onCleanup(@()diary('off')); %#ok<NASGU>
fprintf('STAGE=G2_WP3_0_MTS_ANALYTIC\nDATE=%s\nMATLAB_RELEASE=%s\nOUTDIR=%s\n',datestr(now,31),version('-release'),folder);
V=struct('pass',false,'tests',struct(),'exception','');
try
 % A1 pure mode I
 a1=[g2_mts_direction(1,0),g2_mts_direction(.37,0)];
 V.tests.A1=struct('theta',[a1.theta_rad],'pass',all([a1.theta_rad]==0)&&all(strcmp({a1.status},'OK')));
 % A2 pure mode II
 a2p=g2_mts_direction(0,1);a2m=g2_mts_direction(0,-1);ex=2*atand(1/sqrt(2));
 V.tests.A2=struct('theta_deg',[a2p.theta_deg,a2m.theta_deg],'exact_deg',[-ex,ex], ...
  'pass',abs(a2p.theta_deg+ex)<=1e-9&&abs(a2m.theta_deg-ex)<=1e-9&& ...
  strcmp(a2p.status,'DOCUMENTED_PURE_MODE_II')&&strcmp(a2m.status,'DOCUMENTED_PURE_MODE_II')&&~a2p.admissibleForStep);
 % A3/A4 antisymmetry and residual on 2001 ratios
 rho=linspace(-50,50,2001);th=zeros(size(rho));thm=th;res=th;ok=true;
 for k=1:numel(rho)
  P=g2_mts_direction(1,rho(k));Q=g2_mts_direction(1,-rho(k));
  ok=ok&&strcmp(P.status,'OK')&&strcmp(Q.status,'OK');
  th(k)=P.theta_rad;thm(k)=Q.theta_rad;res(k)=P.stationarityResidual_rel;
 end
 anti=max(abs(th+thm));sgn=all(sign(th)==-sign(rho));
 V.tests.A3=struct('maxAntisymmetry_rad',anti,'signRule',sgn,'allOK',ok,'pass',ok&&anti<=1e-12&&sgn);
 Kc=[.166436,.018827];Pc=g2_mts_direction(Kc(1),Kc(2));
 V.tests.A4=struct('maxResidualGrid',max(res),'residualCornell',Pc.stationarityResidual_rel, ...
  'pass',max(res)<=1e-12&&Pc.stationarityResidual_rel<=1e-12);
 % A5 tensile global maximum on a 2,000,001-point grid
 sub=[rho(1:50:end),Kc(2)/Kc(1)];xg=linspace(-pi,pi,2000001);xg=xg(2:end-1);dx=2*pi/2e6;
 a5=zeros(numel(sub),3);ok5=true;
 for k=1:numel(sub)
  P=g2_mts_direction(1,sub(k));f=cos(xg/2).*(cos(xg/2).^2-1.5*sub(k)*sin(xg));
  [fm,im]=max(f);a5(k,:)=[abs(P.theta_rad-xg(im)),P.hoop-fm,P.hoopSecondDerivative];
  ok5=ok5&&P.hoop>0&&P.hoopSecondDerivative<0&&a5(k,1)<=dx+1e-9&&P.hoop>=fm-1e-12;
 end
 P2=g2_mts_direction(0,1);f=cos(xg/2).*(-1.5*sin(xg));[fm,im]=max(f);
 ok5=ok5&&abs(P2.theta_rad-xg(im))<=dx+1e-9&&P2.hoop>=fm-1e-12&&P2.hoopSecondDerivative<0;
 V.tests.A5=struct('ratiosTested',numel(sub)+1,'maxArgmaxError_rad',max(a5(:,1)),'gridSpacing_rad',dx, ...
  'minHoopMinusGridMax',min(a5(:,2)),'maxSecondDerivative',max(a5(:,3)),'pass',ok5);
 % A6 small-KII cancellation
 sm=[1e-6,1e-10,1e-14];e6=zeros(size(sm));
 for k=1:3,P=g2_mts_direction(1,sm(k));e6(k)=abs(P.theta_rad/(-2*sm(k))-1);end
 V.tests.A6=struct('relErr',e6,'pass',all(e6<=1e-6));
 % A7 scale invariance
 e7=0;for cc=[1e-6,1e3],for k=1:numel(rho),P=g2_mts_direction(cc,cc*rho(k));e7=max(e7,abs(P.theta_rad-th(k)));end,end
 V.tests.A7=struct('maxDiff_rad',e7,'pass',e7<=1e-14);
 % A8 HOLD regimes
 cases={[0 0],'HOLD_ZERO_K';[-1 .2],'HOLD_NEGATIVE_KI_CONTACT_OR_COMPRESSION';[-1 0],'HOLD_NEGATIVE_KI_CONTACT_OR_COMPRESSION'; ...
        [NaN 1],'HOLD_NONFINITE_K';[1 Inf],'HOLD_NONFINITE_K'};
 ok8=true;st=cell(size(cases,1),1);
 for k=1:size(cases,1)
  P=g2_mts_direction(cases{k,1}(1),cases{k,1}(2));st{k}=P.status;
  ok8=ok8&&strcmp(P.status,cases{k,2})&&isempty(P.theta_rad)&&~P.admissibleForStep;
 end
 V.tests.A8=struct('statuses',{st},'pass',ok8);
 % A9 Cornell state 0
 t0=[0 1];n0=[-1 0];tip0=[101.6 25.4];da=4;
 t1=cos(Pc.theta_rad)*t0+sin(Pc.theta_rad)*n0;n1=[-t1(2),t1(1)];tip1=tip0+da*t1;
 a9=[abs(Pc.theta_deg+12.5956937),abs(cos(Pc.theta_rad)-.97593315),max(abs(t1-[.21806989,.97593315])),max(abs(tip1-[102.47227957,29.30373262]))];
 V.tests.A9=struct('theta_deg',Pc.theta_deg,'cos',cos(Pc.theta_rad),'t1',t1,'n1',n1,'tip1',tip1,'errors',a9, ...
  'inheritedGuardMinKinkTangentDot',.98,'inheritedGuardWouldReject',cos(Pc.theta_rad)<=.98, ...
  'inheritedGuardBound_deg',acosd(.98),'status',Pc.status, ...
  'pass',strcmp(Pc.status,'OK')&&a9(1)<=1e-6&&a9(2)<=1e-8&&a9(3)<=1e-8&&a9(4)<=1e-8);
 names=fieldnames(V.tests);pv=cellfun(@(n)V.tests.(n).pass,names);
 for k=1:numel(names),fprintf('%s %d\n',names{k},pv(k));end
 fprintf('A9 theta %.10f deg, cos %.10f, tip1 (%.10f, %.10f), t1 (%.10f, %.10f)\n',Pc.theta_deg,cos(Pc.theta_rad),tip1,t1);
 fprintf('INHERITED_GUARD_0p98_WOULD_REJECT=%d (bound %.6f deg)\n',V.tests.A9.inheritedGuardWouldReject,acosd(.98));
 V.pass=all(pv);
 % ---- reference manifest
 json=fullfile(repo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json');
 vend=dir(fullfile(here,'vendor_p010_a14d8872','*.m'));vh=struct();
 for k=1:numel(vend),vh.(matlab.lang.makeValidName(vend(k).name))=g2_sha256_file(fullfile(vend(k).folder,vend(k).name));end
 [~,head]=system(sprintf('git -C "%s" rev-parse HEAD',repo));
 Mf=struct('schema','NewMetacomp.G2.WP3.FirstKink.ReferenceManifest.v1', ...
  'analytical_trial_geometry',true,'physical_propagation',false,'idealized_propagation_demo',true,'physical_onset',false, ...
  'state0',struct('crackPolyline_mm',[101.6 0;tip0],'tip_mm',tip0,'t',t0,'n',n0, ...
    'KI_MPa_sqrt_m_per_kN',Kc(1),'KII_MPa_sqrt_m_per_kN',Kc(2),'source','SIF_WP2_RESULTS.md family A plane stress (PR #23 513044cc)'), ...
  'mts',struct('formula','theta = 2*atan2(-2*KII, KI + hypot(KI, sqrt(8)*KII))','theta_rad',Pc.theta_rad,'theta_deg',Pc.theta_deg, ...
    'status',Pc.status,'stationarityResidual_rel',Pc.stationarityResidual_rel), ...
  'trial',struct('DeltaA_mm',da,'tip_mm',tip1,'t',t1,'n',n1,'crackPolyline_mm',[101.6 0;tip0;tip1], ...
    'inheritedGuardMinKinkTangentDot',.98,'inheritedGuardWouldReject',true,'note','4 mm is a provisional numerical increment, not a physical step'), ...
  'bvp',struct('pin_mm',[25.4 0],'roller_mm',[482.6 0],'load_mm',[254 203.2],'P_N',1,'thickness_mm',12.7, ...
    'E_MPa',3268.115,'nu',.35,'plane','stress','note','idealized WP2 BVP, NOT the experiment'), ...
  'sources',struct('geometryJSON_SHA256',g2_sha256_file(json),'vendor_SHA256',vh,'gitHEAD',strtrim(head), ...
    'PR23_head','513044cc2c5e2db68fc6630c3fe356769abd5e83','MATLAB',version('-release')));
 assert(strcmp(Mf.sources.geometryJSON_SHA256,'45A88FA0926472DDBE5E70E4C80A97B88196DD45D8A266FA04273F89790B47BF'),'G2WP3:JSON','Geometry JSON changed.');
 fm=fopen(fullfile(folder,'WP3_REFERENCE_MANIFEST.json'),'w');fwrite(fm,jsonencode(Mf,'PrettyPrint',true),'char');fclose(fm);
 save(fullfile(folder,'WP3_REFERENCE_MANIFEST.mat'),'Mf');
catch ME
 V.exception=getReport(ME,'extended','hyperlinks','off');fprintf(2,'G2_WP3_MTS_EXCEPTION=%s\n',V.exception);
end
f=fopen(fullfile(folder,'mts_tests_summary.json'),'w');fwrite(f,jsonencode(V,'PrettyPrint',true),'char');fclose(f);
fprintf('G2_WP3_0_MTS_PASS=%d\n',V.pass);
if ~V.pass,error('G2WP3:MTSHOLD','WP3.0 analytic MTS HOLD (see %s).',folder);end
end
