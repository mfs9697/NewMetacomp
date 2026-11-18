function W = run_g2_material_report_batch(runDir)
%RUN_G2_MATERIAL_REPORT_BATCH  Figures and tables from a SAVED Issue #33 run (read only, no solve).
%
%  W = run_g2_material_report_batch(runDir)  % runDir = <repo>/outputs/g2_material_contrast_v1/run_<time>
% Verifies every record manifest, then writes a NEW outputs/g2_material_report/run_<time>/ with
% material_summary.json, material_results.csv and figures: phase map (full + tip with q support),
% annulus zoom, R_mat / K / MTS / compliance small multiples, EDI contours versus COD,
% interface tractions from both sides, benchmark convergence.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));runDir=char(runDir);
L=jsondecode(fileread(fullfile(runDir,'LEDGER.json')));
assert(strcmp(L.status,'GO'),'G2MatReport:NotGO','Run status is %s.',L.status);
outRoot=fullfile(repo,'outputs','g2_material_report');if ~exist(outRoot,'dir'),mkdir(outRoot);end
folder=fullfile(outRoot,['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);assert(~exist(folder,'dir'));mkdir(folder);
diary(fullfile(folder,'material_report_console.log'));cl=onCleanup(@()diary('off')); %#ok<NASGU>
rd=@(f)read_rec(fullfile(runDir,f));
PMr=rd('PHASE_MAP.mat');Br=rd('BENCHMARK.mat');ids={'H1','M0','Msoft','Mstiff'};C=struct();
for k=1:4,C.(ids{k})=rd(['CASE_',ids{k},'.mat']);end
pol=jsondecode(fileread(fullfile(here,'G2_MATERIAL_POLICY_v1.json')));
D=load(fullfile(repo,'outputs','g2_trajectory_chain_v1_attempt2','STEP_002','KINKED_GEOMETRY_ONLY_candidate.mat'));
assert(strcmpi(g2_sha256_file(fullfile(repo,'outputs','g2_trajectory_chain_v1_attempt2','STEP_002','KINKED_GEOMETRY_ONLY_candidate.mat')),pol.base.meshSHA256),'G2MatReport:Mesh','Mesh hash.');
ph=PMr.phase;X3=D.X6;T3=D.T6(:,1:3);P=D.crackPolyline;tip=P(end,:);
cen=reshape(pol.frozenGeometry.holeCenters_mm,[],2);
ink=[.2 .2 .2];crackC=[.75 .12 .12];matC=[.93 .93 .93];reC=[.55 .75 .78];softC=[.16 .42 .72];stiffC=[.85 .45 .10];h1C=[.35 .35 .35];
% ---------- table
T=L.results.ratios;Hs=L.results.H1;
fid=fopen(fullfile(folder,'material_results.csv'),'w');
fprintf(fid,'case,E_r/E_m,KI_EDI_perkN,KII_EDI_perkN,KI_COD_perkN,KII_COD_perkN,G_1N_J_per_m2,R_EDI,R_COD,R_J,U_R,resolved,U_R_conservative,resolvedConservative,mixity_deg,MTS_deg,dMTS_deg,U_dMTS_deg,compliance_mm_per_N,C_ratio,CMOD_mm,CMOD_ratio,reinforcementEnergyFraction\n');
gH=(Hs.KI_raw^2+Hs.KII_raw^2)/Hs.Ep_matrix;
fprintf(fid,'H1,1,%.9f,%+.9f,%.9f,%+.9f,%.6e,1,1,1,0,NA,0,NA,%.6f,%.6f,0,0,%.9e,1,%.9e,1,NA\n',Hs.KI_perkN,Hs.KII_perkN,Hs.KI_COD_perkN,Hs.KII_COD_perkN,1000*gH, ...
 atand(Hs.KII_raw/Hs.KI_raw),g2_mts_direction(Hs.KI_perkN,Hs.KII_perkN).theta_deg,Hs.compliance_mm_per_N,Hs.CMOD_mm);
for k=1:numel(T)
 t=T(k);
 fprintf(fid,'%s,%g,%.9f,%+.9f,%.9f,%+.9f,%.6e,%.9f,%.9f,%.9f,%.3e,%d,%.4f,%d,%.6f,%.6f,%+.6f,%.2e,%.9e,%.9f,%.9e,%.9f,%.6f\n',t.id,t.ratio,t.KI_perkN,t.KII_perkN,t.KI_COD_perkN,t.KII_COD_perkN, ...
  t.G_1N_J_per_m2,t.R_EDI,t.R_COD,t.R_J,t.U_R,t.resolved,t.U_R_conservative,t.resolvedConservative,t.mixity_deg,t.MTS_deg,t.dMTS_deg,t.U_dMTS_deg, ...
  t.compliance_mm_per_N,t.complianceRatio,t.CMOD_mm,t.CMODratio,t.reinforcementEnergyFraction);
end
fclose(fid);type(fullfile(folder,'material_results.csv'));
% ---------- figure 1: phase map, full plate and tip (q support)
f=figure('Visible','off','Position',[0 0 1500 640],'Color','w');
ax=axes(f,'Units','pixels','Position',[60 70 1000 400]);hold(ax,'on');
patch(ax,'Faces',T3(ph==1,:),'Vertices',X3,'FaceColor',matC,'EdgeColor',[.78 .78 .78],'LineWidth',.15);
patch(ax,'Faces',T3(ph==2,:),'Vertices',X3,'FaceColor',reC,'EdgeColor',[.45 .62 .66],'LineWidth',.15);
for h=1:3
 v=PMr.interfaces(h).vertexNodes;plot(ax,X3([v;v(1)],1),X3([v;v(1)],2),'-','Color',ink,'LineWidth',.9);
end
plot(ax,P(:,1),P(:,2),'-','Color',crackC,'LineWidth',1.8);
plot(ax,[25.4 482.6],[0 0],'^','MarkerSize',8,'MarkerFaceColor',ink,'MarkerEdgeColor',ink);
plot(ax,254,203.2,'v','MarkerSize',8,'MarkerFaceColor',ink,'MarkerEdgeColor',ink);
axis(ax,'equal');xlim(ax,[0 508]);ylim(ax,[0 203.2]);box(ax,'on');xlabel(ax,'x (mm)');ylabel(ax,'y (mm)');
title(ax,sprintf('Frozen State 2 mesh: matrix %d T6, bonded bands %d T6 (6.35 < r < 19.05 mm, inscribed 76-gon)',sum(ph==1),sum(ph==2)),'FontWeight','normal');
ax2=axes(f,'Units','pixels','Position',[1110 70 360 400]);hold(ax2,'on');
w=4;sel=all(abs(X3(T3(:,1),:)-tip)<w+2,2);
patch(ax2,'Faces',T3(sel&ph==1,:),'Vertices',X3,'FaceColor',matC,'EdgeColor',[.7 .7 .7],'LineWidth',.15);
rE=min(reshape(vecnorm(D.X6(D.T6(:),:)-tip,2,2),[],6),[],2);
patch(ax2,'Faces',T3(rE<2.6,:),'Vertices',X3,'FaceColor',[.98 .88 .55],'EdgeColor',[.75 .62 .30],'LineWidth',.15);
plot(ax2,P(:,1),P(:,2),'-','Color',crackC,'LineWidth',1.6);
th=linspace(0,2*pi,200);plot(ax2,tip(1)+2.6*cos(th),tip(2)+2.6*sin(th),'--','Color',ink,'LineWidth',.8);
axis(ax2,'equal');xlim(ax2,tip(1)+[-w w]);ylim(ax2,tip(2)+[-w w]);box(ax2,'on');xlabel(ax2,'x (mm)');
title(ax2,sprintf('q support (r < 2.6 mm): matrix only; clearance to bands %.1f mm',PMr.verifier.values.qClearance_mm),'FontWeight','normal');
exportgraphics(f,fullfile(folder,'material_phase_map.png'),'Resolution',180);exportgraphics(f,fullfile(folder,'material_phase_map.pdf'),'ContentType','vector');close(f);
% ---------- figure 2: annulus zoom (hole 1)
f=figure('Visible','off','Position',[0 0 760 720],'Color','w');ax=axes(f);hold(ax,'on');
c1=cen(1,:);sel=all(abs(X3(T3(:,1),:)-c1)<24,2);
patch(ax,'Faces',T3(sel&ph==1,:),'Vertices',X3,'FaceColor',matC,'EdgeColor',[.65 .65 .65],'LineWidth',.2);
patch(ax,'Faces',T3(sel&ph==2,:),'Vertices',X3,'FaceColor',reC,'EdgeColor',[.40 .58 .62],'LineWidth',.2);
v=PMr.interfaces(1).vertexNodes;plot(ax,X3([v;v(1)],1),X3([v;v(1)],2),'-','Color',ink,'LineWidth',1.2);
plot(ax,c1(1)+6.35*cos(th),c1(2)+6.35*sin(th),':','Color',ink);
axis(ax,'equal');xlim(ax,c1(1)+[-23 23]);ylim(ax,c1(2)+[-23 23]);box(ax,'on');xlabel(ax,'x (mm)');ylabel(ax,'y (mm)');
title(ax,sprintf('Hole 1 band: %d T6, 76 conforming chords, area %.3f mm^2 (nominal %.3f)',sum(PMr.annulusOf==1), ...
 PMr.verifier.values.annulusArea_mm2(1),PMr.verifier.values.annulusNominalArea_mm2(1)),'FontWeight','normal');
exportgraphics(f,fullfile(folder,'material_annulus_zoom.png'),'Resolution',180);close(f);
% ---------- figure 3: small multiples vs modulus ratio
r=[T.ratio];[r,io]=sort(r);T=T(io);
f=figure('Visible','off','Position',[0 0 1200 860],'Color','w');
tl=tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');
a=nexttile(tl);hold(a,'on');
Uc=[T.U_R_conservative];
errorbar(a,r,[T.R_EDI],Uc,'LineStyle','none','Color',[.7 .7 .7],'LineWidth',1,'CapSize',6);
plot(a,r,[T.R_EDI],'-o','Color',h1C,'MarkerFaceColor',h1C,'MarkerSize',7,'LineWidth',1.2);
plot(a,r,[T.R_COD],'s','Color',softC,'MarkerSize',10,'LineWidth',1);plot(a,r,[T.R_J],'x','Color',stiffC,'MarkerSize',10,'LineWidth',1.2);
yline(a,1,':','Color',ink);set(a,'XScale','log','XTick',[.5 1 2]);xlim(a,[.4 2.5]);
xlabel(a,'E_r / E_m');ylabel(a,'R_{mat} = G_M / G_{H1}');legend(a,{'conservative bound','EDI (primary)','COD','J'},'Location','northeast','Box','off');
title(a,'Energy-release-rate ratio at the frozen tip','FontWeight','normal');
for k=1:numel(T),text(a,r(k)*1.06,T(k).R_EDI,sprintf('%.4f',T(k).R_EDI),'FontSize',9);end
a=nexttile(tl);hold(a,'on');
plot(a,r,[T.KI_ratio],'-o','Color',h1C,'MarkerFaceColor',h1C,'LineWidth',1.2);plot(a,r,[T.KII_ratio],'-s','Color',stiffC,'MarkerFaceColor',stiffC,'LineWidth',1.2);
yline(a,1,':','Color',ink);set(a,'XScale','log','XTick',[.5 1 2]);xlim(a,[.4 2.5]);
xlabel(a,'E_r / E_m');ylabel(a,'K / K_{H1} (EDI)');legend(a,{'K_I','K_{II}'},'Location','northwest','Box','off');
title(a,sprintf('Signed SIF ratios (|K_{II}/K_I| \\leq %.3f)',max(abs(tand([T.mixity_deg])))),'FontWeight','normal');
a=nexttile(tl);hold(a,'on');
errorbar(a,r,[T.MTS_deg],2*[T.U_dMTS_deg],'-o','Color',h1C,'MarkerFaceColor',h1C,'LineWidth',1.2);
set(a,'XScale','log','XTick',[.5 1 2]);xlim(a,[.4 2.5]);xlabel(a,'E_r / E_m');ylabel(a,'\theta_{MTS} (deg), forecast only');
title(a,'Prospective MTS kink angle (not executed)','FontWeight','normal');
for k=1:numel(T),text(a,r(k)*1.06,T(k).MTS_deg,sprintf('%+.3f',T(k).MTS_deg),'FontSize',9);end
a=nexttile(tl);hold(a,'on');
plot(a,r,[T.complianceRatio],'-o','Color',h1C,'MarkerFaceColor',h1C,'LineWidth',1.2);plot(a,r,[T.CMODratio],'-s','Color',softC,'MarkerFaceColor',softC,'LineWidth',1.2);
yline(a,1,':','Color',ink);set(a,'XScale','log','XTick',[.5 1 2]);xlim(a,[.4 2.5]);
xlabel(a,'E_r / E_m');ylabel(a,'ratio to H1');legend(a,{'load-point compliance','CMOD'},'Location','northeast','Box','off');
title(a,'Structural response','FontWeight','normal');
title(tl,'Bonded bands around the three voids, frozen State 2 crack, P = 1 N (idealized, illustrative moduli)','FontSize',12);
exportgraphics(f,fullfile(folder,'material_ratios.png'),'Resolution',180);exportgraphics(f,fullfile(folder,'material_ratios.pdf'),'ContentType','vector');close(f);
% ---------- figure 4: EDI contours versus COD for every case
f=figure('Visible','off','Position',[0 0 1200 480],'Color','w');tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
cols={h1C,[.6 .6 .6],softC,stiffC};s1k=sqrt(1000);
for m=1:2
 a=nexttile(tl);hold(a,'on');
 for k=1:4
  Ck=C.(ids{k});e=Ck.EDI_all(:,m)*s1k;cod=[Ck.KI_COD_perkN,Ck.KII_COD_perkN];
  plot(a,(1:5)+.08*(k-2.5),e,'o','Color',cols{k},'MarkerFaceColor',cols{k},'MarkerSize',6);
  plot(a,6.2+.08*(k-2.5),cod(m),'d','Color',cols{k},'MarkerSize',8,'LineWidth',1.2);
 end
 set(a,'XTick',[1:5,6.2],'XTickLabel',{'0.4-2.6','0.2-1.0','0.4-1.6','0.8-2.6','1.2-2.4','COD'});xlim(a,[.5 6.7]);
 xlabel(a,'q annulus (mm) / blind COD');
 if m==1,ylabel(a,'K_I (MPa\surdm per kN)');title(a,'K_I: five EDI contours and blind COD','FontWeight','normal');
 else,ylabel(a,'K_{II} (MPa\surdm per kN)');title(a,'K_{II}: five EDI contours and blind COD','FontWeight','normal');end
 if m==1,legend(a,flatten_legend(ids),'Location','westoutside','Box','off');end
end
exportgraphics(f,fullfile(folder,'material_EDI_vs_COD.png'),'Resolution',180);close(f);
% ---------- figure 5: interface tractions from both sides (hole 1), Msoft and Mstiff
f=figure('Visible','off','Position',[0 0 1200 760],'Color','w');tl=tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');
cs={'Msoft','Mstiff'};
for k=1:2
 ct=C.(cs{k}).chordTractions{1};[ang,io]=sort(ct.angle_rad*180/pi);Lc=ct.length_mm(io);
 for q=1:2
  a=nexttile(tl);hold(a,'on');
  if q==1,yi=ct.tn_inner(io);yo=ct.tn_outer(io);lab='normal';else,yi=ct.tt_inner(io);yo=ct.tt_outer(io);lab='shear';end
  plot(a,ang,1e6*yi./Lc,'-','Color',reC*0.8,'LineWidth',1.4);plot(a,ang,1e6*yo./Lc,'--','Color',ink,'LineWidth',1);
  xlim(a,[-180 180]);set(a,'XTick',-180:90:180);xlabel(a,'angle around hole 1 centre (deg)');ylabel(a,sprintf('mean %s traction (\\muPa per N)',lab));
  title(a,sprintf('%s (E_r/E_m = %g): %s traction, band side vs matrix side',cs{k},T(strcmp({T.id},cs{k})).ratio,lab),'FontWeight','normal');
  if k==1&&q==1,legend(a,{'band side','matrix side'},'Box','off','Location','best');end
 end
end
exportgraphics(f,fullfile(folder,'material_interface_tractions.png'),'Resolution',180);close(f);
% ---------- figure 6: benchmark convergence
B=Br.benchmark;Hh=B.values.Hmax;eu=B.values.dispRelErr;eT=B.values.interfaceMomentRelErr;rat=B.values.ratios;
f=figure('Visible','off','Position',[0 0 1100 460],'Color','w');tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
mk={'o','s','^'};cc={softC,stiffC,h1C};
a=nexttile(tl);hold(a,'on');
for k=1:numel(rat),loglog(a,Hh,eu(k,:),['-',mk{k}],'Color',cc{k},'MarkerFaceColor',cc{k},'LineWidth',1.2);end
loglog(a,Hh,eu(1,end)*(Hh/Hh(end)).^2,':','Color',ink);set(a,'XScale','log','YScale','log');yline(a,pol.benchmark.finestDisplacementRelErrorMax,'--','gate','Color',[.6 .1 .1]);
xlabel(a,'H_{max} (mm)');ylabel(a,'max nodal |u_h - u| / max |u|');legend(a,[arrayfun(@(x)sprintf('E_r/E_m = %g',x),rat,'UniformOutput',false),{'slope 2'}],'Location','southeast','Box','off');
title(a,'Coated hole: displacement error','FontWeight','normal');
a=nexttile(tl);hold(a,'on');
for k=1:numel(rat),loglog(a,Hh,eT(k,:),['-',mk{k}],'Color',cc{k},'MarkerFaceColor',cc{k},'LineWidth',1.2);end
set(a,'XScale','log','YScale','log');yline(a,pol.benchmark.finestInterfaceTractionMomentRelErrorMax,'--','gate','Color',[.6 .1 .1]);
xlabel(a,'H_{max} (mm)');ylabel(a,'interface traction moment rel. error (worst side)');title(a,'Coated hole: interface traction moments','FontWeight','normal');
exportgraphics(f,fullfile(folder,'material_benchmark_convergence.png'),'Resolution',180);close(f);
% ---------- summary
if iscell(L.stages),sn=cellfun(@(s)s.name,L.stages,'UniformOutput',false);ss=cellfun(@(s)s.status,L.stages,'UniformOutput',false);
else,sn={L.stages.name};ss={L.stages.status};end
W=struct('run',['<repo>/outputs/g2_material_contrast_v1/',fileparts_name(runDir)],'gitHeadOfRun',L.gitHead,'policySHA256',L.policySHA256, ...
 'stages',{sn},'statuses',{ss},'H1',Hs,'ratios',L.results.ratios,'physicalFractureGrowthProven',false);
W.H1=rmfield(W.H1,intersect(fieldnames(W.H1),{'chordTractions','EDI_all'}));
fid=fopen(fullfile(folder,'material_summary.json'),'w');fwrite(fid,jsonencode(W,'PrettyPrint',true),'char');fclose(fid);
fprintf('G2_MATERIAL_REPORT_DONE %s\n',strrep(folder,repo,'<repo>'));
end

function r=read_rec(f)
[r,~,ok]=g2_trajectory_record('read',f);assert(ok,'G2MatReport:Record','Record integrity failed: %s',f);
end
function c=flatten_legend(ids)
c=cell(1,8);for k=1:4,c{2*k-1}=[ids{k},' EDI'];c{2*k}=[ids{k},' COD'];end
end
function n=fileparts_name(p)
[~,n]=fileparts(p);
end
