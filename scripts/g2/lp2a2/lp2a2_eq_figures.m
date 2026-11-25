function lp2a2_eq_figures(execRepo,auditJson,csvDir,outDir)
%LP2A2_EQ_FIGURES  Ukrainian figures of the LP2-A2 SIF-equivalence demonstration (activation A2).
% READ-ONLY: reads COMPARISON.json of the four records, the independent audit (contrast) and the
% opening profiles exported by lp2a2_eq_opening_export. No solve.
%  EQ-1  use of every preregistered tolerance, |quantity| / tolerance, per criterion and solve
%  EQ-2  difference of the crack-face jump and of the signed normal opening along the crack
assert(~isfolder(outDir),'LP2A2EqFig:Out','Output folder exists.');mkdir(outDir);
set(groot,'defaultAxesFontName','Arial','defaultTextFontName','Arial','defaultAxesFontSize',8);
pol=jsondecode(fileread(fullfile(execRepo,'matlab','g2','lp2a2','G2_LP2A2_EQ_POLICY_v1.json')));tol=pol.tolerances;
A=jsondecode(fileread(auditJson));ct=A.contrast;
ids={'EQ-H','EQ-stiff13','EQ-soft2','EQ-soft1'};cs={'H','stiff13','soft2','soft1'};
col=[0.00 0.45 0.70;0.84 0.37 0.00;0.00 0.62 0.45;0.80 0.47 0.65];mk={'o','s','d','^'};
M=cell(1,4);for k=1:4,Cm=jsondecode(fileread(fullfile(execRepo,pol.outputRoot,ids{k},'COMPARISON.json')));M{k}=Cm.metrics;end
% ------------------------------------------------------------------ EQ-1 tolerance use
rows={'C1  \DeltaK_I / K_{eq}',@(m)abs(m.dKI_overKeq)/tol.KI_overKeq; ...
 'C2  \DeltaK_{II} / K_{eq}',@(m)abs(m.dKII_overKeq)/tol.KII_overKeq; ...
 'C3  \Delta(K_{II}/K_I)',@(m)abs(m.dKIIoverKI)/tol.KIIoverKI_abs; ...
 'C4  \DeltaG/G, \DeltaJ/J',@(m)max(abs([m.dG_rel m.dJ_rel]))/tol.G_rel; ...
 'C4  |J/G-1| нової (абс.)',@(m)abs(m.newJoverGminus1)/tol.newJoverGminus1; ...
 'C5  \Delta\theta_{MTS}',@(m)abs(m.dMTS_deg)/tol.MTS_deg; ...
 'C6  \Delta(COD-EDI)',@(m)abs(m.dCODminusEDI)/tol.dCODminusEDI; ...
 'C6  COD-EDI нової (абс.)',@(m)m.newCODminusEDI_rel/tol.newCODminusEDI_gate; ...
 'C7  розкид EDI нової (абс.)',@(m)m.newPathSpread_rel/max(tol.spreadFloor,tol.spreadFactor*m.archivedPathSpread_rel); ...
 'C7  квадратура 4×4 нової (абс.)',@(m)m.newQuad4x4_rel/max(tol.quadFloor,tol.quadFactor*m.archivedQuad4x4_rel); ...
 'C8  розкриття біля вершини',@(m)m.openingNearTipRel/tol.openingNearTipRel; ...
 'C8  розкриття всієї тріщини',@(m)m.openingWholeCrackRel/tol.openingWholeCrackRel; ...
 'C9  \Delta активної площі',@(m)abs(m.dActiveArea_rel)/tol.activeArea_rel; ...
 'C10 зсув вершини S9',@(m)m.S9tipDisplacement_mm/tol.S9tipDisplacement_mm; ...
 'C11 \Delta податливості',@(m)abs(m.dCompliance_rel)/tol.compliance_rel};
nr=size(rows,1)+2;U=nan(nr,4);
for i=1:size(rows,1),for k=1:4,U(i,k)=rows{i,2}(M{k});end,end
lab=[rows(:,1);{'Контраст \DeltaF_G';'Контраст \Delta(\theta_X-\theta_H)'}];
for k=2:4,U(nr-1,k)=abs(ct.dFG(k-1))/tol.contrast_FG_abs;U(nr,k)=abs(ct.ddTheta_deg(k-1))/tol.contrast_MTS_deg;end
floorU=1e-9;xlo=2e-10;Z=U<floorU&~isnan(U);U(Z)=floorU;
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 12]);ax=axes(f);hold(ax,'on');
y=nr:-1:1;off=[-0.24 -0.08 0.08 0.24];
for i=1:nr,plot(ax,[floorU 1],[y(i) y(i)],'-','Color',[.9 .9 .9],'LineWidth',.5,'HandleVisibility','off');end
h=gobjects(1,4);
for k=1:4
 ok=~isnan(U(:,k));h(k)=plot(ax,U(ok,k),y(ok)+off(k),mk{k},'Color',col(k,:),'MarkerFaceColor',col(k,:),'MarkerSize',4.5,'LineStyle','none');
 zz=Z(:,k);if any(zz),plot(ax,U(zz,k),y(zz)+off(k),mk{k},'Color',col(k,:),'MarkerFaceColor','w','MarkerSize',4.5,'LineStyle','none','HandleVisibility','off');end
end
xline(ax,1,'-','допуск','Color',[.35 .35 .35],'LineWidth',1,'LabelVerticalAlignment','bottom','FontSize',7,'HandleVisibility','off');
set(ax,'XScale','log','YTick',1:nr,'YTickLabel',flip(lab),'XLim',[xlo 2],'YLim',[0.4 nr+0.6],'TickLabelInterpreter','tex','Box','off','XGrid','on','XMinorGrid','off','GridColor',[.85 .85 .85]);
xlabel(ax,{'використання допуску  |величина| / допуск   (1 = межа приймання)','порожній маркер: різниця дорівнює 0 (показано при 10^{-9})'});
legend(ax,h,cs,'Location','southoutside','Orientation','horizontal','Box','off');
title(ax,'Рис. LP2A2-EQ-1. Використання допусків C1–C11 і контрасту (S8, щабель 1)','FontWeight','normal','FontSize',9);
save2(f,fullfile(outDir,'LP2A2_EQ_1_tolerance_use'));
% ------------------------------------------------------------------ EQ-2 opening differences
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 10]);tl=tiledlayout(f,2,1,'TileSpacing','compact','Padding','compact');
a1=nexttile(tl);hold(a1,'on');a2=nexttile(tl);hold(a2,'on');h=gobjects(1,4);
for k=1:4
 T=readtable(fullfile(csvDir,sprintf('LP2A2_EQ_A2_OPENING_%s.csv',ids{k})));[d,o]=sort(T.distToTip_mm);
 dj=(T.jumpNew_mm-T.jumpArchivedInterp_mm)/max(T.jumpNew_mm)*1e6;dg=(T.signedNew_mm-T.signedArchivedInterp_mm)/max(abs(T.signedNew_mm))*1e6;
 h(k)=plot(a1,d,dj(o),'-','Color',col(k,:),'LineWidth',1);plot(a2,d,dg(o),'-','Color',col(k,:),'LineWidth',1);
end
for a=[a1 a2],yline(a,0,'-','Color',[.6 .6 .6],'HandleVisibility','off');xline(a,3.3,':','Color',[.4 .4 .4],'HandleVisibility','off');set(a,'Box','off','XGrid','on','YGrid','on','GridColor',[.88 .88 .88]);end
ylabel(a1,{'\Delta|u_U-u_L| / max','(\times10^{-6})'});ylabel(a2,{'\Delta(u_U-u_L)\cdotn / max','(\times10^{-6})'});
xlabel(a2,'відстань від вершини тріщини, мм   (пунктир: межа коміра 3,3 мм)');
title(a1,'а) стрибок переміщень (критерій C8; допуск 1000 біля вершини, 2000 для всієї тріщини, \times10^{-6})','FontWeight','normal','FontSize',8);
title(a2,'б) знакове нормальне розкриття (лише звітується)','FontWeight','normal','FontSize',8);
legend(a1,h,cs,'Location','northeast','Box','off','Orientation','horizontal');
title(tl,'Рис. LP2A2-EQ-2. Різниця розкриття тріщини: нове сімейство мінус архівне S8','FontSize',9);
save2(f,fullfile(outDir,'LP2A2_EQ_2_opening_difference'));
fprintf('EQFIG done %s\n',outDir);
end

function save2(f,base)
exportgraphics(f,[base '.png'],'Resolution',300);exportgraphics(f,[base '.pdf'],'ContentType','vector');close(f);
end
