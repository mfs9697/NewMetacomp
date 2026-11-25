function g2_lp2_figures(geomJson,scanJson,outDir)
%G2_LP2_FIGURES  Ukrainian figure: accepted S0-S4 paths, geometry-only S5 increments, guard zones,
% and the hypothetical frozen-MTS outlook (not a prediction) with the mesh-qualified range S5-S8.
assert(~isfolder(outDir),'LP2Fig:Out','Output folder exists.');mkdir(outDir);
set(groot,'defaultAxesFontName','Arial','defaultTextFontName','Arial','defaultAxesFontSize',8);
G=jsondecode(fileread(geomJson));S=jsondecode(fileread(scanJson));
cen=[152.4 69.85;152.4 120.65;152.4 171.45];th=linspace(0,2*pi,240);
nm={'H (однорідний)','жорсткі \{1,3\}','м’яке \{2\}','м’яке \{1\}'};ls={'-','--','-.',':'};mk={'o','^','s','d'};
col={[0 0 0],[.75 .2 .1],[.1 .35 .75],[.15 .55 .2]};
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 11]);
tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl);hold(ax,'on');
for i=1:3
 fill(ax,cen(i,1)+19.05*cos(th),cen(i,2)+19.05*sin(th),[.9 .9 .9],'EdgeColor',[.4 .4 .4],'HandleVisibility','off');
 fill(ax,cen(i,1)+6.35*cos(th),cen(i,2)+6.35*sin(th),'w','EdgeColor','k','HandleVisibility','off');
 plot(ax,cen(i,1)+34.05*cos(th),cen(i,2)+34.05*sin(th),':','Color',[.5 .5 .5],'HandleVisibility','off');
 text(ax,cen(i,1)+3,cen(i,2)+12,sprintf('%d',i),'FontWeight','bold','FontSize',8);
end
plot(ax,nan,nan,':','Color',[.5 .5 .5],'DisplayName','межа 15-мм напрямної вершини');
for i=1:4
 r=G.rows(i);P=r.S5_B0.polyline_mm;tp=r.outlook.frozenMTS.tips_mm;
 plot(ax,P(1:6,1),P(1:6,2),ls{i},'Color',col{i},'LineWidth',1.2,'HandleVisibility','off');
 plot(ax,P(6:7,1),P(6:7,2),'-','Color',col{i},'LineWidth',2.4,'HandleVisibility','off');
 plot(ax,tp(:,1),tp(:,2),'.','Color',col{i},'MarkerSize',5,'HandleVisibility','off');
 q=tp(min(5,size(tp,1)),:);plot(ax,q(1),q(2),mk{i},'Color',col{i},'MarkerFaceColor','w','MarkerSize',5,'HandleVisibility','off');
 plot(ax,nan,nan,ls{i},'Color',col{i},'LineWidth',1.2,'DisplayName',nm{i});
end
plot(ax,nan,nan,'.','Color',[.3 .3 .3],'MarkerSize',8,'DisplayName','гіпотетичне продовження (кут МКН S4 заморожено)');
plot(ax,nan,nan,'o','Color',[.3 .3 .3],'MarkerFaceColor','w','DisplayName','S8 — межа кваліфікованої сітки');
plot(ax,[25.4 254],[0 203.2],'k--','LineWidth',.6,'HandleVisibility','off');
axis(ax,'equal');xlim(ax,[60 210]);ylim(ax,[0 205]);box(ax,'on');xlabel(ax,'x, мм');ylabel(ax,'y, мм');dec(ax);
title(ax,'(а) S0–S4, S5 і гіпотетичне продовження','FontWeight','normal','FontSize',8);
legend(ax,'Location','southoutside','FontSize',6.5,'Box','off');
ax=nexttile(tl);hold(ax,'on');
for i=1:4
 r=G.rows(i);P=r.S5_B0.polyline_mm;
 plot(ax,P(4:6,1),P(4:6,2),[ls{i} mk{i}],'Color',col{i},'LineWidth',1.1,'MarkerSize',4,'MarkerFaceColor','w','DisplayName',[nm{i} ': S2–S4']);
 plot(ax,P(6:7,1),P(6:7,2),'-','Color',col{i},'LineWidth',2.4,'HandleVisibility','off');
 plot(ax,P(7,1),P(7,2),mk{i},'Color',col{i},'MarkerFaceColor',col{i},'MarkerSize',5,'HandleVisibility','off');
end
plot(ax,nan,nan,'-','Color',[.3 .3 .3],'LineWidth',2.4,'DisplayName','S5: лише геометричний прогноз');
axis(ax,'equal');xlim(ax,[102 109]);ylim(ax,[32 46]);grid(ax,'on');box(ax,'on');xlabel(ax,'x, мм');dec(ax);
title(ax,'(б) вершини S4 і прирости S5 (4 мм)','FontWeight','normal','FontSize',8);
legend(ax,'Location','southoutside','FontSize',6.5,'Box','off');
annotation(f,'textbox',[0 0 1 .04],'String',['Джерело: стани A0 S0–S4 (run\_a0\_lp1\_repro\_v1); S5 за МКН із підписаних КІН S4; ' ...
 'продовження — лише геометрична ілюстрація, не результат'],'FontSize',6,'Color',[.3 .3 .3],'EdgeColor','none','Interpreter','tex');
exportgraphics(f,fullfile(outDir,'LP2_1_S4_S5_UA.png'),'Resolution',300);exportgraphics(f,fullfile(outDir,'LP2_1_S4_S5_UA.pdf'),'ContentType','vector');close(f);
% mesh-qualification bar figure
rows=S.rows;if iscell(rows),rows=[rows{:}];end
k=unique([rows.state]);np=arrayfun(@(s)nnz([rows([rows.state]==s).pass]),k);nt=arrayfun(@(s)nnz([rows.state]==s),k);
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 12 6.5]);ax=axes(f);hold(ax,'on');
bar(ax,k,[np;nt-np].','stacked','BarWidth',.7);colormap(ax,[.35 .35 .35;.85 .85 .85]);
ax.Children(1).FaceColor=[.85 .85 .85];ax.Children(2).FaceColor=[.3 .3 .3];
xline(ax,8.5,'k--','HandleVisibility','off');text(ax,8.6,max(nt)+.3,'межа LP2-A1','FontSize',7);
legend(ax,{'сітку побудовано, аудит 34/34','HOLD\_LIP\_STATIONS'},'Location','northeast','FontSize',7);
xlabel(ax,'номер стану (синтетичні ламані, лише сітка)');ylabel(ax,'кількість сценаріїв');xticks(ax,k);ylim(ax,[0 max(nt)+1.5]);box(ax,'on');grid(ax,'on');
exportgraphics(f,fullfile(outDir,'LP2_2_sitka_UA.png'),'Resolution',300);exportgraphics(f,fullfile(outDir,'LP2_2_sitka_UA.pdf'),'ContentType','vector');close(f);
end
function dec(ax)
xt=round(ax.XTick,10);ax.XTick=xt;yt=round(ax.YTick,10);ax.YTick=yt;
ax.XTickLabel=strrep(compose('%g',xt),'.',',');ax.YTickLabel=strrep(compose('%g',yt),'.',',');
end
