function W = run_g2_m2_report_batch(runDir)
%RUN_G2_M2_REPORT_BATCH  Figures and tables from a SAVED Issue #36 run (read only, no solve).
%
%  W = run_g2_m2_report_batch(runDir)  % runDir = <repo>/outputs/g2_material_evolution_v1/run_<time>
% Verifies every phase/case record manifest, then writes a NEW outputs/g2_m2_report/run_<time>/
% with m2_results.csv, m2_summary.json and figures: R_mat(s) with both uncertainty verdicts and
% the S2alt check; steering, mixity, G and compliance versus s; K_I/K_II by state; geometry of
% the three frozen cracks, bands and q clearances; S2 versus S2alt interface polygons.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));runDir=char(runDir);
L=jsondecode(fileread(fullfile(runDir,'LEDGER.json')));
assert(strcmp(L.status,'GO'),'G2M2Report:NotGO','Run status is %s.',L.status);
outRoot=fullfile(repo,'outputs','g2_m2_report');if ~exist(outRoot,'dir'),mkdir(outRoot);end
folder=fullfile(outRoot,['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);assert(~exist(folder,'dir'));mkdir(folder);
diary(fullfile(folder,'m2_report_console.log'));cl=onCleanup(@()diary('off')); %#ok<NASGU>
st={'S0','S1','S2','S2alt'};cs={'H1','M0','Msoft','Mstiff'};
for i=1:4
 [~,~,ok]=g2_trajectory_record('read',fullfile(runDir,['PHASE_MAP_',st{i},'.mat']));assert(ok,'G2M2Report:Record','PHASE_MAP_%s',st{i});
 for k=1:4,[~,~,ok]=g2_trajectory_record('read',fullfile(runDir,['CASE_',st{i},'_',cs{k},'.mat']));assert(ok,'G2M2Report:Record','CASE_%s_%s',st{i},cs{k});end
end
R=L.results;s=[25.4 29.4 33.4];ids=st(1:3);
ink=[.2 .2 .2];softC=[.16 .42 .72];stiffC=[.85 .45 .10];h1C=[.35 .35 .35];reC=[.55 .75 .78];matC=[.94 .94 .94];crackC=[.75 .12 .12];
get=@(id,m,f)R.(id).table(strcmp({R.(id).table.id},m)).(f);
% ---------- CSV
fid=fopen(fullfile(folder,'m2_results.csv'),'w');
fprintf(fid,['state,s_mm,case,E_r/E_m,KI_EDI_perkN,KII_EDI_perkN,KI_COD_perkN,KII_COD_perkN,G_1N_J_per_m2,R_EDI,R_COD,R_J,U_R,resolvedPrimary,', ...
 'U_R_conservative,resolvedConservative,KII_signResolved,mixity_deg,theta_MTS_local_deg,dTheta_deg,U_dTheta_deg,dThetaResolved,', ...
 'tangentGlobal_deg,theta_MTS_global_deg,complianceRatio,CMODratio,bandEnergyFraction,tipToBand_mm,qClearance_mm,bandArea_mm2,chords\n']);
sAll=[s 33.4];
for i=1:4
 T=R.(st{i}).table;g=R.(st{i}).geometry;
 for k=1:numel(T)
  t=T(k);
  fprintf(fid,'%s,%.1f,%s,%g,%.9f,%+.9f,%.9f,%+.9f,%.6e,%.9f,%.9f,%.9f,%.3e,%d,%.4f,%d,%d,%.6f,%.6f,%+.6f,%.2e,%d,%.6f,%.6f,%.9f,%.9f,%.6f,%.4f,%.4f,%.6f,%d\n', ...
   st{i},sAll(i),t.id,t.ratio,t.KI_perkN,t.KII_perkN,t.KI_COD_perkN,t.KII_COD_perkN,t.G_1N_J_per_m2,t.R_EDI,t.R_COD,t.R_J,t.U_R,t.resolved, ...
   t.U_R_conservative,t.resolvedConservative,t.KII_signResolved,t.mixity_deg,t.MTS_deg,t.dMTS_deg,t.U_dMTS_deg,t.dMTSresolved,t.tangentGlobal_deg, ...
   t.MTSglobal_deg,t.complianceRatio,t.CMODratio,t.reinforcementEnergyFraction,g.tipToBand_mm,g.qClearance_mm,g.annulusArea_mm2(1),g.chordsPerCircle(1));
 end
end
fclose(fid);type(fullfile(folder,'m2_results.csv'));
% ---------- figure 1: R_mat(s)
f=figure('Visible','off','Position',[0 0 1000 620],'Color','w');ax=axes(f);hold(ax,'on');
for m={'Msoft','Mstiff'}
 c=softC;if strcmp(m{1},'Mstiff'),c=stiffC;end
 Rv=arrayfun(@(i)get(ids{i},m{1},'R_EDI'),1:3);Uc=arrayfun(@(i)get(ids{i},m{1},'U_R_conservative'),1:3);
 Up=arrayfun(@(i)get(ids{i},m{1},'U_R'),1:3);Rc=arrayfun(@(i)get(ids{i},m{1},'R_COD'),1:3);
 fill(ax,[s fliplr(s)],[Rv-Uc fliplr(Rv+Uc)],c,'FaceAlpha',.10,'EdgeColor','none','HandleVisibility','off');
 errorbar(ax,s,Rv,2*Up,'-o','Color',c,'MarkerFaceColor',c,'MarkerSize',7,'LineWidth',1.5,'CapSize',8);
 plot(ax,s,Rc,'s','Color',c,'MarkerSize',11,'LineWidth',1,'HandleVisibility','off');
 plot(ax,33.4+.6,get('S2alt',m{1},'R_EDI'),'d','Color',c,'MarkerFaceColor','w','MarkerSize',9,'LineWidth',1.5,'HandleVisibility','off');
 for i=1:3,text(ax,s(i)-.3,Rv(i),sprintf('%.4f',Rv(i)),'Color',c,'FontSize',9,'HorizontalAlignment','right','VerticalAlignment','middle');end
end
yline(ax,1,':','Color',ink,'HandleVisibility','off');
set(ax,'XTick',s,'XTickLabel',{'S0  25.4','S1  29.4','S2  33.4'});xlim(ax,[24 35]);
xlabel(ax,'frozen homogeneous-reference crack: state and arclength s (mm)');ylabel(ax,'R_{mat} = G_M / G_{H1} (same mesh)');
legend(ax,{'E_r/E_m = 0.5 (soft)','E_r/E_m = 2 (stiff)'},'Location','northwest','Box','off');
title(ax,{'Direct bonded-band effect on G along the reference crack','dots: EDI (bars 2U_R, primary rule); squares: COD; shading: conservative bound; diamonds: S2alt mesh'},'FontWeight','normal');
exportgraphics(f,fullfile(folder,'m2_R_vs_s.png'),'Resolution',180);exportgraphics(f,fullfile(folder,'m2_R_vs_s.pdf'),'ContentType','vector');close(f);
% ---------- figure 2: steering, mixity, G, compliance
f=figure('Visible','off','Position',[0 0 1200 860],'Color','w');tl=tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');
a=nexttile(tl);hold(a,'on');
for m={'Msoft','Mstiff'}
 c=softC;if strcmp(m{1},'Mstiff'),c=stiffC;end
 errorbar(a,s,arrayfun(@(i)get(ids{i},m{1},'dMTS_deg'),1:3),2*arrayfun(@(i)get(ids{i},m{1},'U_dMTS_deg'),1:3),'-o','Color',c,'MarkerFaceColor',c,'LineWidth',1.4);
end
yline(a,0,':','Color',ink);set(a,'XTick',s);xlim(a,[24 35]);xlabel(a,'s (mm)');ylabel(a,'\Delta\theta_{MTS} = \theta_M - \theta_{H1} (deg), local frame');
legend(a,{'soft','stiff'},'Box','off','Location','east');title(a,'Material steering difference (forecast only)','FontWeight','normal');
a=nexttile(tl);hold(a,'on');
plot(a,s,arrayfun(@(i)get(ids{i},'M0','mixity_deg'),1:3),'-o','Color',h1C,'MarkerFaceColor',h1C,'LineWidth',1.4);
for m={'Msoft','Mstiff'}
 c=softC;if strcmp(m{1},'Mstiff'),c=stiffC;end
 plot(a,s,arrayfun(@(i)get(ids{i},m{1},'mixity_deg'),1:3),'-o','Color',c,'MarkerFaceColor',c,'LineWidth',1.4);
end
set(a,'XTick',s);xlim(a,[24 35]);xlabel(a,'s (mm)');ylabel(a,'\psi = atan(K_{II}/K_I) (deg)');legend(a,{'H1','soft','stiff'},'Box','off');
title(a,'Signed mode mixity (all K_{II} signs resolved)','FontWeight','normal');
a=nexttile(tl);hold(a,'on');
plot(a,s,1e9*arrayfun(@(i)get(ids{i},'M0','G_H1_1N_N_per_mm'),1:3),'-o','Color',h1C,'MarkerFaceColor',h1C,'LineWidth',1.4);
for m={'Msoft','Mstiff'}
 c=softC;if strcmp(m{1},'Mstiff'),c=stiffC;end
 plot(a,s,1e9*arrayfun(@(i)get(ids{i},m{1},'G_1N_N_per_mm'),1:3),'-o','Color',c,'MarkerFaceColor',c,'LineWidth',1.4);
end
set(a,'XTick',s);xlim(a,[24 35]);xlabel(a,'s (mm)');ylabel(a,'G at P = 1 N (10^{-9} N/mm)');legend(a,{'H1','soft','stiff'},'Box','off','Location','northwest');
title(a,'Absolute G: baseline growth is a geometry effect','FontWeight','normal');
a=nexttile(tl);hold(a,'on');
for m={'Msoft','Mstiff'}
 c=softC;if strcmp(m{1},'Mstiff'),c=stiffC;end
 plot(a,s,arrayfun(@(i)get(ids{i},m{1},'complianceRatio'),1:3),'-o','Color',c,'MarkerFaceColor',c,'LineWidth',1.4);
 plot(a,s,arrayfun(@(i)get(ids{i},m{1},'CMODratio'),1:3),'--s','Color',c,'LineWidth',1.1);
end
yline(a,1,':','Color',ink);set(a,'XTick',s);xlim(a,[24 35]);xlabel(a,'s (mm)');ylabel(a,'ratio to H1');
legend(a,{'soft compliance','soft CMOD','stiff compliance','stiff CMOD'},'Box','off','Location','eastoutside');
title(a,'Structural response','FontWeight','normal');
title(tl,'Bonded bands around the voids along the frozen reference crack (idealized 1 N BVP, illustrative moduli)','FontSize',12);
exportgraphics(f,fullfile(folder,'m2_steering_mixity_G_compliance.png'),'Resolution',180);exportgraphics(f,fullfile(folder,'m2_steering_mixity_G_compliance.pdf'),'ContentType','vector');close(f);
% ---------- figure 3: K by state
f=figure('Visible','off','Position',[0 0 1200 460],'Color','w');tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
cc={h1C,softC,stiffC};mm={'M0','Msoft','Mstiff'};lab={'H1 (= M0)','soft','stiff'};
for q=1:2
 a=nexttile(tl);hold(a,'on');fe={'KI_perkN','KII_perkN'};fc={'KI_COD_perkN','KII_COD_perkN'};
 for k=1:3
  plot(a,s+.12*(k-2),arrayfun(@(i)get(ids{i},mm{k},fe{q}),1:3),'o','Color',cc{k},'MarkerFaceColor',cc{k},'MarkerSize',7);
  plot(a,s+.12*(k-2),arrayfun(@(i)get(ids{i},mm{k},fc{q}),1:3),'d','Color',cc{k},'MarkerSize',8,'LineWidth',1.1);
 end
 set(a,'XTick',s);xlim(a,[24.5 34.3]);xlabel(a,'s (mm)');
 if q==1,ylabel(a,'K_I (MPa\surdm per kN)');title(a,'K_I: EDI (dots) and blind COD (diamonds)','FontWeight','normal');
 else,ylabel(a,'K_{II} (MPa\surdm per kN)');title(a,'K_{II}: EDI (dots) and blind COD (diamonds)','FontWeight','normal');
  legend(a,reshape([lab;strcat(lab,' COD')],1,[]),'Box','off','Location','northeast');end
end
exportgraphics(f,fullfile(folder,'m2_K_by_state.png'),'Resolution',180);close(f);
% ---------- figure 4: geometry of the three frozen cracks and bands
pol=jsondecode(fileread(fullfile(here,'G2_M2_POLICY_v1.json')));stp=pol.states;if ~iscell(stp),stp=num2cell(stp);end
D2=load(fullfile(repo,stp{3}.mesh));[P2,~,~]=g2_trajectory_record('read',fullfile(runDir,'PHASE_MAP_S2.mat'));
[PA,~,~]=g2_trajectory_record('read',fullfile(runDir,'PHASE_MAP_S2alt.mat'));DA=load(fullfile(runDir,'S2ALT_KINKED_GEOMETRY_ONLY_candidate.mat'));
f=figure('Visible','off','Position',[0 0 1400 620],'Color','w');
ax=axes(f,'Units','pixels','Position',[60 70 760 480]);hold(ax,'on');
T3=D2.T6(:,1:3);patch(ax,'Faces',T3(P2.phase==1,:),'Vertices',D2.X6,'FaceColor',matC,'EdgeColor','none');
patch(ax,'Faces',T3(P2.phase==2,:),'Vertices',D2.X6,'FaceColor',reC,'EdgeColor','none');
th=linspace(0,2*pi,240);cen=[152.4 69.85;152.4 120.65;152.4 171.45];
for h=1:3,plot(ax,cen(h,1)+6.35*cos(th),cen(h,2)+6.35*sin(th),'Color',ink);plot(ax,cen(h,1)+19.05*cos(th),cen(h,2)+19.05*sin(th),'Color',ink,'LineWidth',.8);end
mk={'o','s','^'};
for i=1:3
 Pp=stp{i}.polyline_mm;plot(ax,Pp(:,1),Pp(:,2),'-','Color',crackC,'LineWidth',1.4);
 plot(ax,Pp(end,1),Pp(end,2),mk{i},'Color',crackC,'MarkerFaceColor','w','MarkerSize',7,'LineWidth',1.2);
 d=R.(ids{i}).geometry.tipToBand_mm;plot(ax,Pp(end,1)+d*cos(th),Pp(end,2)+d*sin(th),':','Color',[.5 .5 .5]);
end
axis(ax,'equal');xlim(ax,[60 200]);ylim(ax,[0 120]);box(ax,'on');xlabel(ax,'x (mm)');ylabel(ax,'y (mm)');
title(ax,sprintf('Frozen tips S0/S1/S2 (circle/square/triangle); dotted: distance to nearest band node %.1f / %.1f / %.1f mm', ...
 R.S0.geometry.tipToBand_mm,R.S1.geometry.tipToBand_mm,R.S2.geometry.tipToBand_mm),'FontWeight','normal');
ax2=axes(f,'Units','pixels','Position',[880 70 480 480]);hold(ax2,'on');
v=P2.interfaces(1).vertexNodes;va=PA.interfaces(1).vertexNodes;c1=cen(1,:);
plot(ax2,c1(1)+19.05*cos(th),c1(2)+19.05*sin(th),':','Color',ink);
plot(ax2,D2.X6([v;v(1)],1),D2.X6([v;v(1)],2),'-o','Color',stiffC,'MarkerSize',4,'LineWidth',1.1);
plot(ax2,DA.X6([va;va(1)],1),DA.X6([va;va(1)],2),'-s','Color',softC,'MarkerSize',3,'LineWidth',1.0);
axis(ax2,'equal');xlim(ax2,c1(1)+[12 20]);ylim(ax2,c1(2)+[-4 4]);box(ax2,'on');xlabel(ax2,'x (mm)');
legend(ax2,{'nominal r = 19.05 mm','S2 mesh: 76-gon','S2alt mesh: 112-gon'},'Box','off','Location','southwest');
title(ax2,sprintf('Band interface, hole 1: area %.3f vs %.3f mm^2',R.S2.geometry.annulusArea_mm2(1),R.S2alt.geometry.annulusArea_mm2(1)),'FontWeight','normal');
exportgraphics(f,fullfile(folder,'m2_geometry_tips_bands.png'),'Resolution',180);close(f);
W=struct('run',['<repo>/outputs/g2_material_evolution_v1/',fname(runDir)],'gitHeadOfRun',L.gitHead,'policySHA256',L.policySHA256, ...
 'summary',L.summary,'s_mm',s,'physicalFractureGrowthProven',false);
fid=fopen(fullfile(folder,'m2_summary.json'),'w');fwrite(fid,jsonencode(W,'PrettyPrint',true),'char');fclose(fid);
fprintf('G2_M2_REPORT_DONE %s\n',strrep(folder,repo,'<repo>'));
end
function n=fname(p),[~,n]=fileparts(p);end
