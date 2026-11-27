function lp2b1eq_campaign_figures(auditJson,outDir)
%LP2B1EQ_CAMPAIGN_FIGURES  Ukrainian figure of campaign G2-LP2B1-EQ-001: utilization of the prescribed tolerances
% (|metric| / tolerance, log scale) for the two fixed-geometry 0.40 mm solutions, from the INDEPENDENT audit JSON
% (scripts/g2/lp2b1eq/lp2b1eq_audit.py). Reads one JSON, writes LP2B1EQ_1_vykorystannia_dopuskiv.{png,pdf}; no FEM.
A=jsondecode(fileread(auditJson));ids={'EQB_soft1_S9','EQB_H_S10'};lab={'EQB-soft1-S9 (s = 61,4 мм, маска 100)','EQB-H-S10 (s = 65,4 мм, маска 000)'};
keys={'C1_KI','C2_KII','C3_KIIoverKI','C4_G','C4_J','C4_JoverG','C5_MTS','C6_newCOD','C6_dCOD','C7_spread','C7_quad','C8_nearTip','C8_wholeCrack','C9_activeArea','C10_nextTip','C11_compliance'};
names={'C1  |ΔK_I| / K_{eq}','C2  |ΔK_{II}| / K_{eq}','C3  |Δ(K_{II}/K_I)|','C4  |ΔG| / G','C4  |ΔJ| / J','C4  |J/G − 1| (нове)*','C5  |Δθ_{MTS}|', ...
 'C6  COD−EDI (нове)*','C6  |Δ(COD−EDI)|','C7  розкид шляхів EDI (нове)*','C7  дрейф квадратури 4×4 (нове)*','C8  розкриття біля вершини','C8  розкриття всієї тріщини', ...
 'C9  |ΔA_{акт}| / max(A, 1 мм²)','C10  зміщення наступної вершини','C11  |ΔC| / C'};
col=[0.165 0.471 0.839;0.922 0.408 0.204];mk={'o','s'};floorv=1e-9;n=numel(keys);
U=zeros(n,2);for j=1:2,u=A.results.(ids{j}).utilization;for k=1:n,U(k,j)=u.(keys{k});end,end
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 13]);ax=axes(f);hold(ax,'on');
y=n:-1:1;off=[0.14 -0.14];
for k=1:n,plot(ax,[floorv 1],[y(k) y(k)],'-','Color',[.92 .92 .92],'HandleVisibility','off');end
xline(ax,1,'-','Color',[.15 .15 .15],'LineWidth',1,'HandleVisibility','off');
text(ax,0.8,n+0.85,'допуск (= 1)','HorizontalAlignment','right','FontSize',7,'Color',[.15 .15 .15]);
h=gobjects(1,2);
for j=1:2
 v=U(:,j);z=v==0;vv=max(v,floorv);
 h(j)=plot(ax,vv(~z),y(~z)'+off(j),mk{j},'MarkerSize',5,'MarkerFaceColor',col(j,:),'MarkerEdgeColor','w','LineWidth',0.5);
 if any(z),plot(ax,vv(z),y(z)'+off(j),mk{j},'MarkerSize',5,'MarkerFaceColor','w','MarkerEdgeColor',col(j,:),'LineWidth',1,'HandleVisibility','off');end
end
k9=find(strcmp(keys,'C9_activeArea'));text(ax,floorv*2.2,y(k9),'= 0 точно (обидва розв’язки)','FontSize',7,'Color',[.32 .32 .30],'VerticalAlignment','middle');
set(ax,'XScale','log','XLim',[floorv/4 2],'YLim',[0.4 n+1.2],'YTick',fliplr(y),'YTickLabel',fliplr(names),'FontSize',7,'TickLength',[0 0],'XColor',[.32 .32 .30],'YColor',[.32 .32 .30]);
ax.XAxis.TickValues=10.^(-9:0);ax.XGrid='on';ax.GridColor=[.85 .85 .85];ax.GridAlpha=1;box(ax,'off');
xlabel(ax,'використання допуску = |метрика| / допуск (логарифмічна шкала)','FontSize',7.5);
legend(ax,h,lab,'Location','southoutside','Orientation','horizontal','Box','off','FontSize',7);
title(ax,{'Рис. LP2B1EQ-1. Використання допусків C1–C11 у двох розв’язках 0,40 мм (кампанія G2-LP2B1-EQ-001)', ...
 '* абсолютні ворота якості нового розв’язку (не різниця з архівом); решта — різниці нове − архівне'},'FontSize',8,'FontWeight','normal');
exportgraphics(f,fullfile(outDir,'LP2B1EQ_1_vykorystannia_dopuskiv.png'),'Resolution',220);
exportgraphics(f,fullfile(outDir,'LP2B1EQ_1_vykorystannia_dopuskiv.pdf'),'ContentType','vector');close(f);
end
