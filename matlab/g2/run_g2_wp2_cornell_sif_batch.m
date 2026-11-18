function Cs=run_g2_wp2_cornell_sif_batch(meshDirA,meshDirB)
%RUN_G2_WP2_CORNELL_SIF_BATCH  WP2 tests C1-C4: idealized unit-load Cornell #1 BVP (NOT the experiment).
% meshDirA / meshDirB: outputs/g2_protected_mesh/run_* folders of two protected
% mesh families with nodes at the pin (25.4,0), roller (482.6,0) and load point
% (254,203.2), each audited beforehand (38-gate + protected-tip checkers).
% BVP (WP2_PREREGISTRATION.md section 1): point pin u_x=u_y=0, point roller u_y=0,
% point load P = 1 N downward on t = 12.7 mm (2D line load P/t), traction-free
% holes and crack faces; E = 3268.115 MPa; plane stress nu 0.35 (primary), plane
% strain nu 0.35 and plane stress nu 0.30 (invariance check C3).
% Writes a NEW outputs/g2_wp2_cornell/run_* folder.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
outRoot=fullfile(repo,'outputs','g2_wp2_cornell');if ~exist(outRoot,'dir'),mkdir(outRoot);end
folder=fullfile(outRoot,['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);assert(~exist(folder,'dir'));mkdir(folder);
diary(fullfile(folder,'cornell_sif_console.log'));c=onCleanup(@()diary('off')); %#ok<NASGU>
fprintf('STAGE=G2_WP2_CORNELL_IDEALIZED_SIF\nDATE=%s\nMATLAB_RELEASE=%s\nMESH_A=%s\nMESH_B=%s\n',datestr(now,31),version('-release'),meshDirA,meshDirB);
fprintf('MODEL=IDEALIZED_UNIT_LOAD_NOT_EXPERIMENTAL\n');
P=1;t=12.7;f=P/t;E=3268.115;
mats={struct('E',E,'nu',.35,'plane','stress'),struct('E',E,'nu',.35,'plane','strain'),struct('E',E,'nu',.30,'plane','stress')};
annuli=[.4 2.6;.2 1.0;.4 1.6;.8 2.6;1.2 2.4];
Cs=struct('pass',false,'model','idealized unit-load BVP (WP2_PREREGISTRATION.md s.1), NOT experimental','families',struct(), ...
 'criteria',struct(),'exception','');
try
 dirs={meshDirA,meshDirB};tags={'A','B'};
 for ff=1:2
  D=load(fullfile(char(dirs{ff}),'GEOMETRY_ONLY_candidate.mat'));
  X6=D.X6;T6=D.T6;N=size(X6,1);tip=D.X3(D.physicalTipNode,:);
  assert(norm(tip-[101.6 25.4])<1e-12,'G2C:Tip','Unexpected tip.');
  nodeAt=@(xy)D.extraVertexNodes(vecnorm(D.extraVertexXY-xy,2,2)<1e-9);
  pin=nodeAt([25.4 0]);rol=nodeAt([482.6 0]);ld=nodeAt([254 203.2]);
  assert(isscalar(pin)&&isscalar(rol)&&isscalar(ld),'G2C:BCNodes','Support/load nodes missing.');
  F=zeros(2*N,1);F(2*ld)=-f;
  bc=struct('fixedDofs',[2*pin-1;2*pin;2*rol],'fixedValues',[0;0;0],'F',F);
  fam=struct('meshDir',char(dirs{ff}),'T3',size(D.T3,1),'T6nodes',N,'family',D.familyTag,'cases',struct([]));
  for mm=1:3
   mat=mats{mm};S=g2_t6_elasticity(X6,T6,mat,bc);
   Rf=S.reactions;                       % [pin x; pin y; roller y]
   Fx=Rf(1);Fy=Rf(2)+Rf(3)-f;
   Mz=(25.4*Rf(2))+(482.6*Rf(3))-254*f;  % moment about the origin (forces on the body)
   statics=[abs(Fx)/f,abs(Fy)/f,abs(Mz)/(f*457.2),abs(Rf(3)/f-(254-25.4)/457.2),abs(Rf(2)/f-(482.6-254)/457.2)];
   ed=zeros(5,3);
   for j=1:5,Rj=g2_sif_interaction(X6,T6,S.u,mat,tip,[0 1],annuli(j,1),annuli(j,2),6);ed(j,:)=[Rj.KI,Rj.KII,Rj.J];end
   R4=g2_sif_interaction(X6,T6,S.u,mat,tip,[0 1],.4,2.6,4);
   Cc=g2_sif_cod(X6,T6,S.u,mat,tip,[0 1],[.1 1.5]);
   [~,Ep]=g2_plane_D(mat);
   cs=struct('material',mat,'Ep',Ep,'relativeResidual',S.relativeResidual,'reactions_per_line_load',(Rf/f).', ...
    'staticsErrors',statics,'strainEnergy',S.strainEnergy,'externalWork',S.externalWork, ...
    'loadPointDisplacement_uy',S.u(2*ld),'KI_EDI',ed(1,1),'KII_EDI',ed(1,2),'J',ed(1,3),'EDI_all',ed, ...
    'KI_EDI_4x4',R4.KI,'KII_EDI_4x4',R4.KII,'KI_COD',Cc.KI,'KII_COD',Cc.KII,'CODpairsInWindow',Cc.pairsInWindow);
   if isempty(fam.cases),fam.cases=cs;else,fam.cases(mm)=cs;end
   fprintf('%s %s nu=%.2f: res %.2e statics %.2e | EDI KI %.6f KII %.6f | COD KI %.6f KII %.6f | J %.4e\n', ...
     tags{ff},mat.plane,mat.nu,S.relativeResidual,max(statics),ed(1,1),ed(1,2),Cc.KI,Cc.KII,ed(1,3));
   if ff==1&&mm==1
    Cod=Cc;save(fullfile(folder,'familyA_primary_fields.mat'),'ed','annuli','Cod','-v7.3');
   end
  end
  Cs.families.(tags{ff})=fam;
 end
 A=Cs.families.A.cases;B=Cs.families.B.cases;
 Kref=hypot(A(1).KI_EDI,A(1).KII_EDI);
 c1=all(arrayfun(@(s)s.relativeResidual<=1e-8&&max(s.staticsErrors)<=1e-8,[A,B]));
 c2v=arrayfun(@(s)max(abs([s.KI_EDI-s.KI_COD,s.KII_EDI-s.KII_COD]))/hypot(s.KI_EDI,s.KII_EDI),[A,B]);
 m2v=arrayfun(@(s)max(max(s.EDI_all(:,1:2))-min(s.EDI_all(:,1:2)))/hypot(s.KI_EDI,s.KII_EDI),[A,B]);
 m3v=arrayfun(@(s)abs(s.J/((s.KI_EDI^2+s.KII_EDI^2)/s.Ep)-1),[A,B]);
 m4v=arrayfun(@(s)max(abs([s.KI_EDI_4x4-s.KI_EDI,s.KII_EDI_4x4-s.KII_EDI]))/hypot(s.KI_EDI,s.KII_EDI),[A,B]);
 c3=max(max(abs([[A.KI_EDI]-A(1).KI_EDI,[A.KII_EDI]-A(1).KII_EDI])))/Kref;
 c3B=max(max(abs([[B.KI_EDI]-B(1).KI_EDI,[B.KII_EDI]-B(1).KII_EDI])))/hypot(B(1).KI_EDI,B(1).KII_EDI);
 c4=max(abs([B(1).KI_EDI-A(1).KI_EDI,B(1).KII_EDI-A(1).KII_EDI]))/Kref;
 Cs.criteria=struct('C1_equilibrium',c1,'C2_EDIvsCOD_max',max(c2v),'C2_pass',max(c2v)<=.03, ...
  'M2_pathSpread_max',max(m2v),'M2_pass',max(m2v)<=.005,'M3_energy_max',max(m3v),'M3_pass',max(m3v)<=.005, ...
  'M4_quadrature_max',max(m4v),'M4_pass',max(m4v)<=.001,'C3_invariance_A',c3,'C3_invariance_B',c3B, ...
  'C3_pass',max(c3,c3B)<=.005,'C4_refinement',c4,'C4_pass',c4<=.01);
 Cs.pass=c1&&Cs.criteria.C2_pass&&Cs.criteria.M2_pass&&Cs.criteria.M3_pass&&Cs.criteria.M4_pass&&Cs.criteria.C3_pass&&Cs.criteria.C4_pass;
 s=1/sqrt(1000)*1000;   % MPa*sqrt(mm) per N  ->  MPa*sqrt(m) per kN
 Cs.result_per_kN=struct('familyA_KI_MPa_sqrt_m',A(1).KI_EDI*s,'familyA_KII_MPa_sqrt_m',A(1).KII_EDI*s, ...
  'familyB_KI_MPa_sqrt_m',B(1).KI_EDI*s,'familyB_KII_MPa_sqrt_m',B(1).KII_EDI*s, ...
  'KIIoverKI_A',A(1).KII_EDI/A(1).KI_EDI,'note','P = 1 kN total on t = 12.7 mm, plane stress nu 0.35; idealized supports');
 fprintf('C1 %d | C2 %.3e | M2 %.3e | M3 %.3e | M4 %.3e | C3 %.3e/%.3e | C4 %.3e\n',c1,max(c2v),max(m2v),max(m3v),max(m4v),c3,c3B,c4);
 fprintf('K per kN (A, plane stress nu .35): KI %.6f, KII %.6f MPa*sqrt(m); KII/KI %.5f\n',A(1).KI_EDI*s,A(1).KII_EDI*s,A(1).KII_EDI/A(1).KI_EDI);
 local_figures(folder,Cs,annuli);
catch ME
 Cs.exception=getReport(ME,'extended','hyperlinks','off');fprintf(2,'G2_WP2_CORNELL_EXCEPTION=%s\n',Cs.exception);
end
fj=fopen(fullfile(folder,'cornell_sif_summary.json'),'w');fwrite(fj,jsonencode(Cs,'PrettyPrint',true),'char');fclose(fj);
fprintf('G2_WP2_CORNELL_SIF_PASS=%d\nG2_WP2_MODEL=IDEALIZED_NOT_EXPERIMENTAL\n',Cs.pass);
if ~Cs.pass,error('G2C:HOLD','Cornell idealized SIF HOLD (see %s).',folder);end
end

function local_figures(folder,Cs,annuli)
A=Cs.families.A.cases(1);B=Cs.families.B.cases(1);
s=sqrt(1000);
f=figure('Visible','off','Color','w','PaperPositionMode','manual','PaperUnits','centimeters','PaperPosition',[0 0 26 10]);
subplot(1,2,1);hold on;box on;grid on;
lab=arrayfun(@(k)sprintf('%.1f-%.1f',annuli(k,1),annuli(k,2)),1:5,'UniformOutput',false);
plot(1:5,A.EDI_all(:,1)*s,'o-',1:5,B.EDI_all(:,1)*s,'s--');
yline(A.KI_COD*s,'k:');yline(B.KI_COD*s,'r:');
set(gca,'XTick',1:5,'XTickLabel',lab);xlabel('q annulus (mm)');ylabel('K_I (MPa m^{1/2} per kN)');
legend({'EDI family A','EDI family B','COD A','COD B'},'Location','best');title('K_I: path independence and estimators');
subplot(1,2,2);hold on;box on;grid on;
plot(1:5,A.EDI_all(:,2)*s,'o-',1:5,B.EDI_all(:,2)*s,'s--');
yline(A.KII_COD*s,'k:');yline(B.KII_COD*s,'r:');
set(gca,'XTick',1:5,'XTickLabel',lab);xlabel('q annulus (mm)');ylabel('K_{II} (MPa m^{1/2} per kN)');
title('K_{II} (sign convention: WP2\_PREREGISTRATION s.2)');
print(f,fullfile(folder,'cornell_K_vs_annulus.png'),'-dpng','-r200');close(f);
F=load(fullfile(folder,'familyA_primary_fields.mat'));C=F.Cod;
f=figure('Visible','off','Color','w','PaperPositionMode','manual','PaperUnits','centimeters','PaperPosition',[0 0 26 10]);
sel=C.r<=3.3;
subplot(1,2,1);plot(C.r(sel),C.KIapp(sel)*s,'.-');hold on;grid on;
plot([0 1.5],(C.KI+C.slopeI*[0 1.5])*s,'r-');xline(.1,'k:');xline(1.5,'k:');
xlabel('r (mm)');ylabel('apparent K_I (MPa m^{1/2} per kN)');title('COD extrapolation, family A');
subplot(1,2,2);plot(C.r(sel),C.KIIapp(sel)*s,'.-');hold on;grid on;
plot([0 1.5],(C.KII+C.slopeII*[0 1.5])*s,'r-');xline(.1,'k:');xline(1.5,'k:');
xlabel('r (mm)');ylabel('apparent K_{II} (MPa m^{1/2} per kN)');title('sliding-displacement extrapolation, family A');
print(f,fullfile(folder,'cornell_cod_extrapolation.png'),'-dpng','-r200');close(f);
end
