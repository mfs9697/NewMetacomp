function g2_lp2a_figures(analysisJson,execRepo,outDir)
%G2_LP2A_FIGURES  Ukrainian figures of the LP2-A1 campaign from saved records only (no FEM).
% Accepted states: A0 S0-S4 + LP2 S5-S8 (LP2A_ANALYSIS.json). Geometry-only S9 forecasts: candidate
% polylines of the TERMINAL records (run_lp2a_s5_s8_v1), drawn dashed and labelled as forecasts.
assert(~isfolder(outDir),'LP2AFig:Out','Output folder exists.');mkdir(outDir);
set(groot,'defaultAxesFontName','Arial','defaultTextFontName','Arial','defaultAxesFontSize',8);
A=jsondecode(fileread(analysisJson));W=A.states;ids={'H','stiff13','soft2','soft1'};
nm={'H (однорідний)','жорсткі \{1,3\}','м’яке \{2\}','м’яке \{1\}'};col={[0 0 0],[.75 .2 .1],[.1 .35 .75],[.15 .55 .2]};
ls={'-','--','-.',':'};mk={'o','^','s','d'};cen=[152.4 69.85;152.4 120.65;152.4 171.45];th=linspace(0,2*pi,240);
rd=fullfile(execRepo,'outputs','g2_lp2a_paths_v1','run_lp2a_s5_s8_v1');S9=struct();
for i=1:4
 T=load(fullfile(rd,ids{i},'TERMINAL.mat'));S9.(ids{i})=T.record.candidate.polyline_mm(end-1:end,:);
end
src='Джерело: прийняті стани A0 S0–S4 і LP2-A1 S5–S8 (G2-LP2A-001); штрихом — лише геометричний прогноз S9 (не розв’язок)';
% ---------------------------------------------------------------- 1 trajectories and lateral offset
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 10.5]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl);hold(ax,'on');
for h=1:2
 fill(ax,cen(h,1)+19.05*cos(th),cen(h,2)+19.05*sin(th),[.9 .9 .9],'EdgeColor',[.4 .4 .4],'HandleVisibility','off');
 fill(ax,cen(h,1)+6.35*cos(th),cen(h,2)+6.35*sin(th),'w','EdgeColor','k','HandleVisibility','off');
 plot(ax,cen(h,1)+34.05*cos(th),cen(h,2)+34.05*sin(th),':','Color',[.5 .5 .5],'HandleVisibility','off');
 text(ax,cen(h,1)-3,cen(h,2),sprintf('%d',h),'FontWeight','bold');
end
for i=1:4
 w=W.(ids{i});P=w.tip;plot(ax,[101.6;P(:,1)],[0;P(:,2)],ls{i},'Color',col{i},'LineWidth',1.2,'DisplayName',nm{i});
 plot(ax,P(6:9,1),P(6:9,2),mk{i},'Color',col{i},'MarkerSize',3.5,'MarkerFaceColor',col{i},'HandleVisibility','off');
 q=S9.(ids{i});plot(ax,q(:,1),q(:,2),'--','Color',col{i},'LineWidth',.8,'HandleVisibility','off');
end
plot(ax,nan,nan,'k--','LineWidth',.8,'DisplayName','прогноз S9 (лише геометрія)');plot(ax,nan,nan,':','Color',[.5 .5 .5],'DisplayName','межа 15-мм напрямної');
axis(ax,'equal');xlim(ax,[96 156]);ylim(ax,[20 80]);box(ax,'on');xlabel(ax,'x, мм');ylabel(ax,'y, мм');dec(ax);
title(ax,'(а) траєкторії S0–S8 і прогноз S9','FontWeight','normal','FontSize',8);legend(ax,'Location','southoutside','FontSize',6.5,'Box','off');
ax=nexttile(tl);hold(ax,'on');
for i=2:4,r=A.(ids{i});plot(ax,r.s_mm,r.d_mm,[ls{i} mk{i}],'Color',col{i},'MarkerFaceColor','w','MarkerSize',4,'LineWidth',1,'DisplayName',nm{i});end
xline(ax,41.4,'k:','HandleVisibility','off');text(ax,42,0.45,'LP2-A1','FontSize',7);yline(ax,0,'k-','HandleVisibility','off');
grid(ax,'on');box(ax,'on');xlim(ax,[24 59]);ax.XTick=25.4:8:57.4;xlabel(ax,'довжина тріщини s, мм');ylabel(ax,'бічне зміщення d відносно H, мм');dec(ax);
title(ax,'(б) бічне зміщення вершини','FontWeight','normal','FontSize',8);legend(ax,'Location','southoutside','FontSize',6.5,'Box','off');
note(f,src);save2(f,outDir,'LP2A_1_traiektorii_UA');
% ---------------------------------------------------------------- 2 G and F_G
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 9.6]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl);hold(ax,'on');
for i=1:4,w=W.(ids{i});plot(ax,w.s,1e8*w.G,[ls{i} mk{i}],'Color',col{i},'MarkerFaceColor','w','MarkerSize',4,'LineWidth',1,'DisplayName',nm{i});end
xline(ax,41.4,'k:','HandleVisibility','off');grid(ax,'on');box(ax,'on');xlim(ax,[24 59]);ax.XTick=25.4:8:57.4;
xlabel(ax,'довжина тріщини s, мм');ylabel(ax,'G, 10^{-8} Н/мм (P = 1 Н)');dec(ax);legend(ax,'Location','northwest','FontSize',6.5);
title(ax,'(а) швидкість вивільнення енергії на власних траєкторіях','FontWeight','normal','FontSize',8);
ax=nexttile(tl);hold(ax,'on');
for i=2:4,r=A.(ids{i});plot(ax,r.s_mm,100*r.F_G,[ls{i} mk{i}],'Color',col{i},'MarkerFaceColor','w','MarkerSize',4,'LineWidth',1,'DisplayName',nm{i});end
xline(ax,41.4,'k:','HandleVisibility','off');yline(ax,0,'k-','HandleVisibility','off');grid(ax,'on');box(ax,'on');xlim(ax,[24 59]);ax.XTick=25.4:8:57.4;
xlabel(ax,'довжина тріщини s, мм');ylabel(ax,'F_G = G_X/G_H − 1, %');dec(ax);legend(ax,'Location','west','FontSize',6.5);
title(ax,'(б) контраст на власних траєкторіях','FontWeight','normal','FontSize',8);
note(f,'Джерело: прийняті стани A0 S0–S4 і LP2-A1 S5–S8; однакові довжини дуги; не прямий матеріальний внесок M5-X6');save2(f,outDir,'LP2A_2_G_UA');
% ---------------------------------------------------------------- 3 steering
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 7.5]);tl=tiledlayout(f,1,3,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl);hold(ax,'on');
for i=1:4,w=W.(ids{i});plot(ax,w.s,w.MTS,[ls{i} mk{i}],'Color',col{i},'MarkerFaceColor','w','MarkerSize',3.5,'LineWidth',1,'DisplayName',nm{i});end
xline(ax,41.4,'k:','HandleVisibility','off');grid(ax,'on');box(ax,'on');xlim(ax,[24 59]);ylim(ax,[-2.2 -0.6]);ax.XTick=25.4:16:57.4;xlabel(ax,'s, мм');ylabel(ax,'локальний кут МКН, °');dec(ax);
text(ax,25.6,-2.1,'S0 поза шкалою (≈ −12,6°)','FontSize',6.5);
title(ax,'(а) θ_{МКН}','FontWeight','normal','FontSize',8);
ax=nexttile(tl);hold(ax,'on');
for i=2:4,r=A.(ids{i});plot(ax,r.s_mm,r.dHeading_deg,[ls{i} mk{i}],'Color',col{i},'MarkerFaceColor','w','MarkerSize',3.5,'LineWidth',1);end
xline(ax,41.4,'k:');yline(ax,0,'k-');grid(ax,'on');box(ax,'on');xlim(ax,[24 59]);ax.XTick=25.4:16:57.4;xlabel(ax,'s, мм');ylabel(ax,'різниця курсу відносно H, °');dec(ax);
title(ax,'(б) накопичений курс','FontWeight','normal','FontSize',8);
ax=nexttile(tl);hold(ax,'on');
for i=1:4,w=W.(ids{i});plot(ax,w.s,w.KII./w.KI,[ls{i} mk{i}],'Color',col{i},'MarkerFaceColor','w','MarkerSize',3.5,'LineWidth',1,'DisplayName',nm{i});end
xline(ax,41.4,'k:','HandleVisibility','off');grid(ax,'on');box(ax,'on');xlim(ax,[24 59]);ylim(ax,[0 0.02]);ax.XTick=25.4:16:57.4;xlabel(ax,'s, мм');ylabel(ax,'K_{II}/K_I');dec(ax);
text(ax,25.6,0.0012,'S0 поза шкалою (≈ 0,11)','FontSize',6.5);
legend(ax,'Location','southoutside','FontSize',6.5,'Box','off');title(ax,'(в) змішаність','FontWeight','normal','FontSize',8);
note(f,'Джерело: прийняті стани; різниці на власних траєкторіях — описові замінники, не розклад «матеріал – траєкторія»');save2(f,outDir,'LP2A_3_vidkhylennia_UA');
% ---------------------------------------------------------------- 4 ring clearance
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 12 9]);ax=axes(f);hold(ax,'on');
for i=1:4
 w=W.(ids{i});plot(ax,w.s,w.ring(:,1),[ls{i} mk{i}],'Color',col{i},'MarkerFaceColor','w','MarkerSize',4,'LineWidth',1,'DisplayName',nm{i});
 q=S9.(ids{i});plot(ax,61.4,norm(q(2,:)-cen(1,:))-19.05,mk{i},'Color',col{i},'MarkerSize',5,'HandleVisibility','off');
end
yline(ax,15,'k--','HandleVisibility','off');text(ax,25,16.2,'15-мм напрямна (числова межа)','FontSize',7);xline(ax,41.4,'k:','HandleVisibility','off');
xline(ax,59.4,'-','Color',[.7 .7 .7],'HandleVisibility','off');text(ax,59.8,30,'S9: прогноз','FontSize',6.5,'Rotation',90);
grid(ax,'on');box(ax,'on');xlim(ax,[24 63]);ylim(ax,[10 52]);ax.XTick=25.4:8:57.4;xlabel(ax,'довжина тріщини s, мм');ylabel(ax,'відстань вершини до кола кільця 1, мм');dec(ax);
legend(ax,'Location','northeast','FontSize',6.5);
note(f,'Кільце 1 активне в жорстких \{1,3\} і м’якому \{1\}, пасивне в H і м’якому \{2\}; відстань — не зустріч і не зупинка');save2(f,outDir,'LP2A_4_vidstani_UA');
end
function note(f,s)
annotation(f,'textbox',[0 0 1 .05],'String',s,'FontSize',6,'Color',[.3 .3 .3],'EdgeColor','none','HorizontalAlignment','left','VerticalAlignment','bottom','Interpreter','tex');
end
function dec(ax)
xt=round(ax.XTick,10);ax.XTick=xt;yt=round(ax.YTick,10);ax.YTick=yt;
ax.XTickLabel=strrep(compose('%g',xt),'.',',');ax.YTickLabel=strrep(compose('%g',yt),'.',',');
end
function save2(f,o,n)
exportgraphics(f,fullfile(o,[n '.png']),'Resolution',300);exportgraphics(f,fullfile(o,[n '.pdf']),'ContentType','vector');close(f);
end
