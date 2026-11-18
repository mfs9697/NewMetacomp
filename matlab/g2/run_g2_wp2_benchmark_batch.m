function Bm=run_g2_wp2_benchmark_batch(p0RunDir)
%RUN_G2_WP2_BENCHMARK_BATCH  WP2 test B1: edge crack in pure bending vs Tada-Paris-Irwin.
% Holeless beam of the Cornell depth W = 203.2 mm, crack a = 25.4 mm at the Cornell
% tip with the same frozen p010 kernel + collar, plate x from 101.6-2.5W to
% 101.6+2.5W. Linear end tractions s_xx = s0*(1-2y/W), s0 = 1 MPa (pure bending,
% bottom fibre in tension); statically determinate point constraints remove the
% rigid modes. Reference: K = s0*sqrt(pi*a)*F(a/W),
% F = 1.122 - 1.40a + 7.33a^2 - 13.08a^3 + 14.0a^4 (stated accuracy 0.2 %).
% Preregistered B1: EDI within 1.0 %, COD within 3.0 %, abs(K_II)/K_I <= 0.5 %.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
vendor=fullfile(here,'vendor_p010_a14d8872');addpath(vendor,'-begin');
outRoot=fullfile(repo,'outputs','g2_wp2_benchmark');if ~exist(outRoot,'dir'),mkdir(outRoot);end
folder=fullfile(outRoot,['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);assert(~exist(folder,'dir'));mkdir(folder);
diary(fullfile(folder,'benchmark_console.log'));c=onCleanup(@()diary('off')); %#ok<NASGU>
json=fullfile(repo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json');
W=203.2;a=25.4;s0=1;xr=101.6+2.5*W*[-1 1];
fprintf('STAGE=G2_WP2_B1_EDGE_CRACK_PURE_BENDING\nDATE=%s\nPLATE_X=[%.1f %.1f]\n',datestr(now,31),xr);
Bm=struct('pass',false,'exception','');
try
 R=g2_join_protected_mesh('ExteriorOptions',{'IncludeHoles',false,'PlateXRange_mm',xr});
 assert(R.pass,'G2B1:Mesh','Benchmark mesh join HOLD: %s',R.stage);
 X6=R.X6;T6=R.T6;tip=R.summary.tip_mm;N=size(X6,1);
 D=struct('X3',R.X3,'T3',R.T3,'X6',X6,'T6',T6,'upperBankT6',R.upperBankT6,'lowerBankT6',R.lowerBankT6, ...
    'physicalTipNode',R.physicalTipNode,'nodalQ',R.nodalQ);
 CP=g2_protected_tip_checker(D,json,fullfile(char(p0RunDir),'P010_ISOLATED_REGULAR_ONLY.mat'));
 assert(CP.pass,'G2B1:Protected','Protected-tip audit of the benchmark mesh HOLD.');
 % consistent end tractions on quadratic boundary edges
 F=zeros(2*N,1);E3=[T6(:,[1 2 4]);T6(:,[2 3 5]);T6(:,[3 1 6])];
 [~,~,ic]=unique(sort(E3(:,1:2),2),'rows');cnt=accumarray(ic,1);bE=E3(cnt(ic)==1,:);
 gp=[-sqrt(3/5) 0 sqrt(3/5)];gw=[5 8 5]/9;
 for side=[-1 1]
  xe=xr((side+3)/2);
  e=bE(abs(X6(bE(:,1),1)-xe)<1e-9&abs(X6(bE(:,2),1)-xe)<1e-9&abs(X6(bE(:,3),1)-xe)<1e-9,:);
  assert(abs(sum(abs(X6(e(:,2),2)-X6(e(:,1),2)))-W)<1e-6,'G2B1:EndEdges','End edges do not cover the depth W.');
  for k=1:size(e,1)
   ya=X6(e(k,1),2);yb=X6(e(k,2),2);Lk=abs(yb-ya);
   for g=1:3
    xi=gp(g);Na=xi*(xi-1)/2;Nb=xi*(xi+1)/2;Nm=1-xi^2;y=Na*ya+Nb*yb+Nm*(ya+yb)/2;
    tx=side*s0*(1-2*y/W);
    F(2*e(k,[1 2 3])-1)=F(2*e(k,[1 2 3])-1)+gw(g)*Lk/2*tx*[Na;Nb;Nm];
   end
  end
 end
 [~,iL]=min(vecnorm(X6-[xr(1),W/2],2,2));[~,iR]=min(vecnorm(X6-[xr(2),W/2],2,2));
 bc=struct('fixedDofs',[2*iL-1;2*iL;2*iR],'fixedValues',[0;0;0],'F',F);
 mat=struct('E',3268.115,'nu',.35,'plane','stress');
 S=g2_t6_elasticity(X6,T6,mat,bc);
 Fx=sum(F(1:2:end));Mz=sum(X6(:,1).*F(2:2:end)-X6(:,2).*F(1:2:end));
 annuli=[.4 2.6;.2 1.0;.4 1.6;.8 2.6;1.2 2.4];ed=zeros(5,3);
 for j=1:5,Rj=g2_sif_interaction(X6,T6,S.u,mat,tip,[0 1],annuli(j,1),annuli(j,2),6);ed(j,:)=[Rj.KI,Rj.KII,Rj.J];end
 C=g2_sif_cod(X6,T6,S.u,mat,tip,[0 1],[.1 1.5]);
 al=a/W;Fa=1.122-1.40*al+7.33*al^2-13.08*al^3+14.0*al^4;Kt=s0*sqrt(pi*a)*Fa;
 eE=abs(ed(1,1)/Kt-1);eC=abs(C.KI/Kt-1);eII=abs(ed(1,2))/ed(1,1);
 spread=max(max(ed(:,1:2))-min(ed(:,1:2)))/Kt;eJ=abs(ed(1,3)/((ed(1,1)^2+ed(1,2)^2)/mat.E)-1);
 Bm=struct('pass',eE<=.010&&eC<=.030&&eII<=.005,'plateXRange',xr,'T3',size(R.T3,1),'T6nodes',N, ...
  'protectedTipGates',sprintf('%d/%d',CP.gatesPassed,CP.gatesTotal),'joinGates',sprintf('%d/%d',nnz(cell2mat(struct2cell(R.gates))),numel(fieldnames(R.gates))), ...
  'relativeResidual',S.relativeResidual,'reactions',S.reactions.','appliedNetFx',Fx,'appliedNetMoment',Mz, ...
  'K_Tada',Kt,'F_aW',Fa,'KI_EDI',ed(1,1),'KII_EDI',ed(1,2),'KI_COD',C.KI,'KII_COD',C.KII, ...
  'errEDI',eE,'errCOD',eC,'KIIoverKI',eII,'pathSpread',spread,'energyErr',eJ,'annuli',annuli,'EDI_all',ed, ...
  'units','K in MPa*sqrt(mm) for s0 = 1 MPa','exception','');
 fprintf('B1: K_Tada %.6f | EDI %.6f (%.3e) | COD %.6f (%.3e) | KII/KI %.2e | spread %.2e | J %.2e | residual %.2e\n', ...
  Kt,ed(1,1),eE,C.KI,eC,eII,spread,eJ,S.relativeResidual);
catch ME
 Bm.exception=getReport(ME,'extended','hyperlinks','off');fprintf(2,'G2_B1_EXCEPTION=%s\n',Bm.exception);
end
f=fopen(fullfile(folder,'b1_benchmark_summary.json'),'w');fwrite(f,jsonencode(Bm,'PrettyPrint',true),'char');fclose(f);
fprintf('G2_WP2_B1_PASS=%d\n',Bm.pass);
if ~Bm.pass,error('G2B1:HOLD','B1 benchmark HOLD (see %s).',folder);end
end
