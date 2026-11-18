function Cs=run_g2_wp3_kinked_sif_batch(meshDirA,auditDirA,meshDirB,auditDirB)
%RUN_G2_WP3_KINKED_SIF_BATCH  WP3.2 C1-C4, M2-M4, QK: idealized Cornell #1 BVP on the AUDITED kinked meshes.
% Same declared BVP as WP2 (pin (25.4,0), roller (482.6,0), P = 1 N down at (254,203.2)
% on t = 12.7 mm, E = 3268.115 MPa; plane stress nu .35 primary, plane strain nu .35 and
% plane stress nu .30 for C3). Signed K at the NEW tip in the t1/n1 frame by
% (1) g2_sif_interaction (FE-nodal q, tdir = t1) and (2) g2_sif_cod_banks (saved bank
% IDs, final segment only, 0.1-1.5 mm). Fail-closed: each mesh MAT must match the
% SHA-256 recorded by a PASSING kink-aware audit. NOT experimental values.
% Writes a NEW outputs/g2_wp3_kinked_sif/run_* folder.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
outRoot=fullfile(repo,'outputs','g2_wp3_kinked_sif');if ~exist(outRoot,'dir'),mkdir(outRoot);end
folder=fullfile(outRoot,['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);assert(~exist(folder,'dir'));mkdir(folder);
diary(fullfile(folder,'kinked_sif_console.log'));c=onCleanup(@()diary('off')); %#ok<NASGU>
fprintf('STAGE=G2_WP3_2_KINKED_TIP_IDEALIZED_SIF\nDATE=%s\nMATLAB_RELEASE=%s\nMESH_A=%s\nMESH_B=%s\n',datestr(now,31),version('-release'),meshDirA,meshDirB);
fprintf('MODEL=IDEALIZED_UNIT_LOAD_NOT_EXPERIMENTAL\n');
P=1;th=12.7;f=P/th;E=3268.115;
mats={struct('E',E,'nu',.35,'plane','stress'),struct('E',E,'nu',.35,'plane','strain'),struct('E',E,'nu',.30,'plane','stress')};
annuli=[.4 2.6;.2 1.0;.4 1.6;.8 2.6;1.2 2.4];
Cs=struct('pass',false,'model','idealized unit-load BVP (WP2 s.1), NOT experimental','families',struct(),'criteria',struct(),'exception','');
try
 dirs={meshDirA,meshDirB};auds={auditDirA,auditDirB};tags={'A','B'};
 for ff=1:2
  mf=fullfile(char(dirs{ff}),'KINKED_GEOMETRY_ONLY_candidate.mat');
  Au=jsondecode(fileread(fullfile(char(auds{ff}),'kinked_audit_summary.json')));
  h=g2_sha256_file(mf);
  assert(Au.pass&&strcmp(Au.meshSHA256,h),'G2KS:Audit','Mesh %s lacks a matching PASSING kink-aware audit.',tags{ff});
  D=load(mf);X6=D.X6;T6=D.T6;N=size(X6,1);Pl=D.crackPolyline;tip=Pl(end,:);t=D.tipTangent(:).';
  assert(norm(D.X3(D.physicalTipNode,:)-tip)<1e-9&&~D.mirrorControl,'G2KS:Tip','Tip/mirror mismatch.');
  nodeAt=@(xy)D.extraVertexNodes(vecnorm(D.extraVertexXY-xy,2,2)<1e-9);
  pin=nodeAt([25.4 0]);rol=nodeAt([482.6 0]);ld=nodeAt([254 203.2]);
  assert(isscalar(pin)&&isscalar(rol)&&isscalar(ld),'G2KS:BCNodes','Support/load nodes missing.');
  F=zeros(2*N,1);F(2*ld)=-f;
  bc=struct('fixedDofs',[2*pin-1;2*pin;2*rol],'fixedValues',[0;0;0],'F',F);
  fam=struct('meshDir',char(dirs{ff}),'meshSHA256',h,'T3',size(D.T3,1),'T6nodes',N,'tip',tip,'t',t,'cases',struct([]));
  for mm=1:3
   mat=mats{mm};S=g2_t6_elasticity(X6,T6,mat,bc);
   Rf=S.reactions;Fx=Rf(1);Fy=Rf(2)+Rf(3)-f;Mz=25.4*Rf(2)+482.6*Rf(3)-254*f;
   statics=[abs(Fx)/f,abs(Fy)/f,abs(Mz)/(f*457.2),abs(Rf(3)/f-(254-25.4)/457.2),abs(Rf(2)/f-(482.6-254)/457.2)];
   ed=zeros(5,3);qmax=0;
   for j=1:5
    Rj=g2_sif_interaction(X6,T6,S.u,mat,tip,t,annuli(j,1),annuli(j,2),6);ed(j,:)=[Rj.KI,Rj.KII,Rj.J];qmax=max(qmax,Rj.maxSupportRadius);
   end
   R4=g2_sif_interaction(X6,T6,S.u,mat,tip,t,.4,2.6,4);
   Cc=g2_sif_cod_banks(X6,S.u,mat,tip,t,D.upperBankT6,D.lowerBankT6,4,[.1 1.5]);
   [~,Ep]=g2_plane_D(mat);
   cs=struct('material',mat,'Ep',Ep,'relativeResidual',S.relativeResidual,'reactions_per_line_load',(Rf/f).', ...
    'staticsErrors',statics,'strainEnergy',S.strainEnergy,'KI_EDI',ed(1,1),'KII_EDI',ed(1,2),'J',ed(1,3),'EDI_all',ed, ...
    'KI_EDI_4x4',R4.KI,'KII_EDI_4x4',R4.KII,'KI_COD',Cc.KI,'KII_COD',Cc.KII,'CODpairsInWindow',Cc.pairsInWindow, ...
    'CODpairsOnFinalSegment',Cc.pairsOnFinalSegment,'qSupportMaxRadius',qmax);
   if isempty(fam.cases),fam.cases=cs;else,fam.cases(mm)=cs;end
   fprintf('%s %s nu=%.2f: res %.2e statics %.2e | EDI KI %.6f KII %.6f | COD KI %.6f KII %.6f | J %.4e | qmax %.4f\n', ...
     tags{ff},mat.plane,mat.nu,S.relativeResidual,max(statics),ed(1,1),ed(1,2),Cc.KI,Cc.KII,ed(1,3),qmax);
   if ff==1&&mm==1,Cod=Cc;save(fullfile(folder,'familyA_primary_fields.mat'),'ed','annuli','Cod','-v7.3');end
  end
  Cs.families.(tags{ff})=fam;
 end
 A=Cs.families.A.cases;B=Cs.families.B.cases;Kref=hypot(A(1).KI_EDI,A(1).KII_EDI);
 c1=all(arrayfun(@(s)s.relativeResidual<=1e-8&&max(s.staticsErrors)<=1e-8,[A,B]));
 c2v=arrayfun(@(s)max(abs([s.KI_EDI-s.KI_COD,s.KII_EDI-s.KII_COD]))/hypot(s.KI_EDI,s.KII_EDI),[A,B]);
 m2v=arrayfun(@(s)max(max(s.EDI_all(:,1:2))-min(s.EDI_all(:,1:2)))/hypot(s.KI_EDI,s.KII_EDI),[A,B]);
 m3v=arrayfun(@(s)abs(s.J/((s.KI_EDI^2+s.KII_EDI^2)/s.Ep)-1),[A,B]);
 m4v=arrayfun(@(s)max(abs([s.KI_EDI_4x4-s.KI_EDI,s.KII_EDI_4x4-s.KII_EDI]))/hypot(s.KI_EDI,s.KII_EDI),[A,B]);
 c3=max(max(abs([[A.KI_EDI]-A(1).KI_EDI,[A.KII_EDI]-A(1).KII_EDI])))/Kref;
 c3B=max(max(abs([[B.KI_EDI]-B(1).KI_EDI,[B.KII_EDI]-B(1).KII_EDI])))/hypot(B(1).KI_EDI,B(1).KII_EDI);
 c4=max(abs([B(1).KI_EDI-A(1).KI_EDI,B(1).KII_EDI-A(1).KII_EDI]))/Kref;
 qk=max([A.qSupportMaxRadius,B.qSupportMaxRadius]);
 Cs.criteria=struct('C1_equilibrium',c1,'C2_EDIvsCOD_max',max(c2v),'C2_pass',max(c2v)<=.03, ...
  'M2_pathSpread_max',max(m2v),'M2_pass',max(m2v)<=.005,'M3_energy_max',max(m3v),'M3_pass',max(m3v)<=.005, ...
  'M4_quadrature_max',max(m4v),'M4_pass',max(m4v)<=.001,'C3_invariance_A',c3,'C3_invariance_B',c3B,'C3_pass',max(c3,c3B)<=.005, ...
  'C4_refinement',c4,'C4_pass',c4<=.01,'QK_maxSupportRadius',qk,'QK_pass',qk<3*cos(pi/64));
 Cs.pass=c1&&Cs.criteria.C2_pass&&Cs.criteria.M2_pass&&Cs.criteria.M3_pass&&Cs.criteria.M4_pass&&Cs.criteria.C3_pass&&Cs.criteria.C4_pass&&Cs.criteria.QK_pass;
catch ME
 Cs.pass=false;Cs.exception=getReport(ME,'extended','hyperlinks','off');fprintf(2,'G2_WP3_KSIF_EXCEPTION=%s\n',Cs.exception);
end
if isempty(Cs.exception)&&isfield(Cs.criteria,'C1_equilibrium')
 A=Cs.families.A.cases;B=Cs.families.B.cases;s=sqrt(1000);
 MTS=g2_mts_direction(A(1).KI_EDI,A(1).KII_EDI);
 Cs.result_per_kN=struct('familyA_KI_MPa_sqrt_m',A(1).KI_EDI*s,'familyA_KII_MPa_sqrt_m',A(1).KII_EDI*s, ...
  'familyB_KI_MPa_sqrt_m',B(1).KI_EDI*s,'familyB_KII_MPa_sqrt_m',B(1).KII_EDI*s,'familyA_KI_COD',A(1).KI_COD*s,'familyA_KII_COD',A(1).KII_COD*s, ...
  'KIIoverKI_A',A(1).KII_EDI/A(1).KI_EDI,'nextMTS_forecast_deg_NOT_EXECUTED',MTS.theta_deg,'nextMTS_status',MTS.status, ...
  'note','P = 1 kN on t = 12.7 mm, plane stress nu .35, idealized supports, frame t1/n1 at tip1; numerical, NOT experimental');
 c=Cs.criteria;
 fprintf('C1 %d | C2 %.3e | M2 %.3e | M3 %.3e | M4 %.3e | C3 %.3e/%.3e | C4 %.3e | QK %.5f\n',c.C1_equilibrium,c.C2_EDIvsCOD_max, ...
  c.M2_pathSpread_max,c.M3_energy_max,c.M4_quadrature_max,c.C3_invariance_A,c.C3_invariance_B,c.C4_refinement,c.QK_maxSupportRadius);
 fprintf('K per kN at the kinked tip (A, plane stress nu .35): KI %.6f, KII %.6f MPa*sqrt(m); KII/KI %.5f\n',A(1).KI_EDI*s,A(1).KII_EDI*s,A(1).KII_EDI/A(1).KI_EDI);
 fprintf('NEXT_MTS_FORECAST_DEG=%.6f (recorded only, NOT executed)\n',MTS.theta_deg);
 try,local_figures(folder,Cs,annuli);catch EF,fprintf(2,'FIGURE_ERROR=%s\n',EF.message);end
end
fj=fopen(fullfile(folder,'kinked_sif_summary.json'),'w');fwrite(fj,jsonencode(Cs,'PrettyPrint',true),'char');fclose(fj);
fprintf('G2_WP3_2_KINKED_SIF_PASS=%d\nG2_WP3_MODEL=IDEALIZED_NOT_EXPERIMENTAL\n',Cs.pass);
if ~Cs.pass,error('G2KS:HOLD','Kinked-tip SIF HOLD (see %s).',folder);end
end

function local_figures(folder,Cs,annuli)
A=Cs.families.A.cases(1);B=Cs.families.B.cases(1);s=sqrt(1000);
f=figure('Visible','off','Color','w','PaperPositionMode','manual','PaperUnits','centimeters','PaperPosition',[0 0 26 10]);
lab=arrayfun(@(k)sprintf('%.1f-%.1f',annuli(k,1),annuli(k,2)),1:5,'UniformOutput',false);
for m=1:2
 subplot(1,2,m);hold on;box on;grid on;
 plot(1:5,A.EDI_all(:,m)*s,'o-',1:5,B.EDI_all(:,m)*s,'s--');
 if m==1,yline(A.KI_COD*s,'k:');yline(B.KI_COD*s,'r:');ylabel('K_I (MPa m^{1/2} per kN)');
 else,yline(A.KII_COD*s,'k:');yline(B.KII_COD*s,'r:');ylabel('K_{II} (MPa m^{1/2} per kN)');end
 set(gca,'XTick',1:5,'XTickLabel',lab);xlabel('q annulus about tip_1 (mm)');
 legend({'EDI family A','EDI family B','COD A','COD B'},'Location','best');
 nm={'K_I','K_{II}'};title(['kinked tip: ',nm{m},', frame t_1/n_1']);
end
print(f,fullfile(folder,'kinked_K_vs_annulus.png'),'-dpng','-r200');close(f);
F=load(fullfile(folder,'familyA_primary_fields.mat'));C=F.Cod;sel=C.r<=3.3;
f=figure('Visible','off','Color','w','PaperPositionMode','manual','PaperUnits','centimeters','PaperPosition',[0 0 26 10]);
subplot(1,2,1);plot(C.r(sel),C.KIapp(sel)*s,'.-');hold on;grid on;plot([0 1.5],(C.KI+C.slopeI*[0 1.5])*s,'r-');xline(.1,'k:');xline(1.5,'k:');
xlabel('r behind tip_1 (mm)');ylabel('apparent K_I (MPa m^{1/2} per kN)');title('COD extrapolation, final segment, family A');
subplot(1,2,2);plot(C.r(sel),C.KIIapp(sel)*s,'.-');hold on;grid on;plot([0 1.5],(C.KII+C.slopeII*[0 1.5])*s,'r-');xline(.1,'k:');xline(1.5,'k:');
xlabel('r behind tip_1 (mm)');ylabel('apparent K_{II} (MPa m^{1/2} per kN)');title('sliding extrapolation, final segment, family A');
print(f,fullfile(folder,'kinked_cod_extrapolation.png'),'-dpng','-r200');close(f);
end
