function lp2b1_figures(ex,outDir)
%LP2B1_FIGURES  Ukrainian figures of LP2-B1 from SAVED arrays and records only (zero FEM, no mesh generated).
%  LP2B1-1 soft1 S10 failed mesh (0.45 mm): specimen-scale location and local zoom of the offending pair
%  LP2B1-2 same window at 0.45 mm (stored failure) and 0.40 mm (selected); neighbour-ratio distributions
%  LP2B1-3 smallest exterior angle at 0.40 mm (near the crack banks) and max ratio / min angle summary
assert(~isfolder(outDir),'LP2B1F:Out','Output folder exists.');mkdir(outDir);
set(groot,'defaultAxesFontName','Arial','defaultTextFontName','Arial','defaultAxesFontSize',8);
g2=fullfile(ex,'matlab','g2');addpath(fullfile(g2,'lp2b1'));
root=fullfile(ex,'outputs','g2_lp2b1_geometry_v1');rr=fullfile(ex,'outputs','g2_lp2a3_paths_v1','run_lp2a3_s9_s11_v1');
S=load(fullfile(rr,'soft1','S10','FAILED_MESH.mat'));fm=S.failedMesh;N=load(fullfile(root,'wp1_attempt2','T_soft1_S10_h040','ATTEMPT_ARRAYS.mat'));
W=jsondecode(fileread(fullfile(root,'wp0_attempt1','LP2B1_WP0.json')));v=W.violations;
PA=jsondecode(fileread(fullfile(root,'postaudit_v1','LP2B1_POSTAUDIT.json')));
cen=[152.4 69.85;152.4 120.65;152.4 171.45];th=linspace(0,2*pi,361);P=fm.crackPolyline;tip=P(end,:);
blue=@(n)[linspace(.93,.03,n)',linspace(.95,.19,n)',linspace(.98,.42,n)'];red=[.80 .10 .10];orng=[.85 .45 .05];
M45=g2_lp2b1_metrics(fm.X3,fm.T3,1.8);M40=g2_lp2b1_metrics(N.X3,N.T3,1.8);
old=reshape(v.midpoint_mm,1,2);
% ================= LP2B1-1
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 15]);tl=tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl,[1 2]);hold(ax,'on');axis(ax,'equal');ctxDraw(ax,cen,th,P,tip,true);
plot(ax,old(1),old(2),'p','MarkerSize',11,'MarkerFaceColor',red,'MarkerEdgeColor','k');
text(ax,old(1)+14,old(2)+28,{'єдина пара з відношенням > 1,8',dc(sprintf('r = %.6f, %.2f мм від вершини',v.ratio,v.distTip_mm)), ...
 dc(sprintf('%.2f мм від осі тріщини; %.1f мм поза колом напрямної',v.distPolyline_mm,v.signedToTipGuide_mm))},'FontSize',7);
plot(ax,[old(1)+1.5 old(1)+13],[old(2)+1.5 old(2)+24],'-','Color',red,'LineWidth',.6);
rectangle(ax,'Position',[old(1)-6 old(2)-6 12 12],'EdgeColor',red,'LineStyle','--');
xlim(ax,[0 508]);ylim(ax,[0 203.2]);xlabel(ax,'x, мм');ylabel(ax,'y, мм');title(ax,'а) зразок: тріщина soft1 S10 (кандидат), отвори, кільця, 15-мм напрямна','FontWeight','normal');box(ax,'on');dcax(ax);
ax=nexttile(tl);hold(ax,'on');axis(ax,'equal');win=[70 175 0 100];
el=inwin(fm.X3,fm.T3,win);patch(ax,'Faces',fm.T3(el,:),'Vertices',fm.X3,'FaceColor','none','EdgeColor',[.7 .7 .7],'LineWidth',.15);
ctxDraw(ax,cen,th,P,tip,false);plot(ax,old(1),old(2),'p','MarkerSize',9,'MarkerFaceColor',red,'MarkerEdgeColor','k');
rectangle(ax,'Position',[old(1)-6 old(2)-6 12 12],'EdgeColor',red,'LineStyle','--');axis(ax,win);xlabel(ax,'x, мм');ylabel(ax,'y, мм');
title(ax,'б) сітка 0,45 мм (збережена), фрагмент','FontWeight','normal');box(ax,'on');dcax(ax);
ax=nexttile(tl);hold(ax,'on');axis(ax,'equal');w2=[old(1)-6 old(1)+6 old(2)-6 old(2)+6];el=inwin(fm.X3,fm.T3,w2);
patch(ax,'Faces',fm.T3(el,:),'Vertices',fm.X3,'FaceVertexCData',M45.h(el),'FaceColor','flat','EdgeColor',[.35 .35 .35],'LineWidth',.3);colormap(ax,blue(64));
for e=[v.small v.large],patch(ax,'Faces',fm.T3(e,:),'Vertices',fm.X3,'FaceColor','none','EdgeColor',red,'LineWidth',1.4);end
xy=v.edgeXY_mm;plot(ax,xy(:,1),xy(:,2),'-','Color','k','LineWidth',2.2);
cs=reshape(v.centroidSmall_mm,1,2);cl=reshape(v.centroidLarge_mm,1,2);
text(ax,cs(1)+.3,cs(2)-.9,dc(sprintf('h = %.3f мм',v.hSmall_mm)),'FontSize',7,'Color',red);text(ax,cl(1)-3.2,cl(2)+1.4,dc(sprintf('h = %.3f мм',v.hLarge_mm)),'FontSize',7,'Color',red);
cb=colorbar(ax);cb.Label.String='h елемента (найдовше ребро), мм';cb.TickLabels=dc(cb.TickLabels);axis(ax,w2);xlabel(ax,'x, мм');ylabel(ax,'y, мм');
title(ax,dc(sprintf('в) пара %d / %d: r = %.4f, спільне ребро %.3f мм',v.small,v.large,v.ratio,v.edgeLength_mm)),'FontWeight','normal');box(ax,'on');dcax(ax);
title(tl,{'Рис. LP2B1-1. Фактична відмова сітки soft1 S10 (0,45 мм): розташування єдиного порушення відношення сусідів',...
 'Вільна градуйована зовнішня область; жодна вершина пари не лежить на колі напрямної, кільці, отворі, краю, березі чи CAD-вершині'},'FontSize',8);
save2(f,fullfile(outDir,'LP2B1_1_vidmova_sitky'));
% ================= LP2B1-2
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 13]);tl=tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');
w3=[old(1)-9 old(1)+9 old(2)-9 old(2)+9];
for z=1:2
 if z==1,X=fm.X3;T=fm.T3;M=M45;tt='а) 0,45 мм (збережена відмова)';else,X=N.X3;T=N.T3;M=M40;tt='б) 0,40 мм (обраний крок)';end
 er=accumarray(M.pairElements(:),[M.pairRatio;M.pairRatio],[size(T,1) 1],@max,1);
 ax=nexttile(tl);hold(ax,'on');axis(ax,'equal');el=inwin(X,T,w3);
 patch(ax,'Faces',T(el,:),'Vertices',X,'FaceVertexCData',er(el),'FaceColor','flat','EdgeColor',[.4 .4 .4],'LineWidth',.25);colormap(ax,blue(64));caxis(ax,[1 1.85]);
 bad=el(er(el)>1.8);for e=bad(:).',patch(ax,'Faces',T(e,:),'Vertices',X,'FaceColor','none','EdgeColor',red,'LineWidth',1.4);end
 plot(ax,old(1),old(2),'+','Color',red,'MarkerSize',8,'LineWidth',1);axis(ax,w3);xlabel(ax,'x, мм');ylabel(ax,'y, мм');
 [mx,im]=max(er(el));title(ax,{tt,dc(sprintf('макс. у вікні %.4f; у всій сітці %.4f',mx,M.maxNeighborRatio))},'FontWeight','normal');box(ax,'on');dcax(ax);
 cb=colorbar(ax);cb.Label.String='макс. відношення до сусідів по ребру';cb.TickLabels=dc(cb.TickLabels);
end
ax=nexttile(tl,[1 2]);hold(ax,'on');xs=linspace(1,1.9,361);
cc=@(M)arrayfun(@(x)nnz(M.pairRatio>x),xs);
semilogy(ax,xs,max(cc(M45),.5),'-','Color',[.03 .19 .42],'LineWidth',1.3);semilogy(ax,xs,max(cc(M40),.5),'--','Color',orng,'LineWidth',1.3);
set(ax,'YScale','log');xline(ax,1.8,'-','поріг 1,8','Color',red,'LabelVerticalAlignment','bottom','HandleVisibility','off');
xline(ax,1.591829,':','ядро p010: 1,5918','Color',[.4 .4 .4],'LabelVerticalAlignment','top','HandleVisibility','off');ylim(ax,[.5 5e4]);
legend(ax,{dc(sprintf('0,45 мм: %d ребер > 1,8; T3 = %d',M45.violations,M45.T3)),dc(sprintf('0,40 мм: %d ребер > 1,8; T3 = %d',M40.violations,M40.T3))},'Location','northeast','Box','off');
xlabel(ax,'відношення r = max(h_1/h_2, h_2/h_1)');ylabel(ax,'кількість спільних ребер з r > x');title(ax,'в) розподіл відношень сусідів, ціль soft1 S10','FontWeight','normal');grid(ax,'on');box(ax,'off');dcax(ax);
title(tl,{'Рис. LP2B1-2. Те саме вікно (±9 мм навколо старої пари, +) для збереженої сітки 0,45 мм і обраної 0,40 мм',...
 'Ядро 3 мм і комір 3,3 мм ідентичні; змінюється лише засів берегів і зовнішня PDE-сітка'},'FontSize',8);
save2(f,fullfile(outDir,'LP2B1_2_porivniannia'));
% ================= LP2B1-3
at=PA.attempts;if ~iscell(at),at=num2cell(at);end
a40=at{2};site=reshape(a40.minAngle.exteriorCentroid_mm,1,2);w4=[site(1)-4 site(1)+4 site(2)-4 site(2)+4];
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 13]);tl=tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');
for z=1:2
 if z==1,X=fm.X3;T=fm.T3;M=M45;tt='а) 0,45 мм';else,X=N.X3;T=N.T3;M=M40;tt='б) 0,40 мм';end
 ax=nexttile(tl);hold(ax,'on');axis(ax,'equal');el=inwin(X,T,w4);
 patch(ax,'Faces',T(el,:),'Vertices',X,'FaceVertexCData',M.minAngleEl(el),'FaceColor','flat','EdgeColor',[.4 .4 .4],'LineWidth',.25);colormap(ax,flipud(blue(64)));caxis(ax,[20 60]);
 plot(ax,P(:,1),P(:,2),'-','Color','k','LineWidth',1.2);ext=M.minAngleEl;ext(1:2916)=inf;[am,ie]=min(ext);
 patch(ax,'Faces',T(ie,:),'Vertices',X,'FaceColor','none','EdgeColor',red,'LineWidth',1.4);axis(ax,w4);xlabel(ax,'x, мм');ylabel(ax,'y, мм');
 title(ax,{tt,dc(sprintf('мін. кут зовнішньої області %.3f° (виділено)',am))},'FontWeight','normal');box(ax,'on');dcax(ax);
 cb=colorbar(ax);cb.Label.String='мінімальний кут елемента, °';cb.TickLabels=dc(cb.TickLabels);
end
lab={'ціль soft1 S10','еталон soft1 S9','еталон H S10'};idx=[2 4 5];r45=zeros(1,3);r40=r45;a45=r45;a40v=r45;
for k=1:3,a=at{idx(k)};r45(k)=a.baselineMetrics.maxNeighborRatio;r40(k)=a.metrics.maxNeighborRatio;a45(k)=a.baselineMetrics.minAngle_deg;a40v(k)=a.metrics.minAngle_deg;end
ax=nexttile(tl);b=bar(ax,[r45;r40].','grouped');b(1).FaceColor=[.03 .19 .42];b(2).FaceColor=orng;hold(ax,'on');yline(ax,1.8,'-','поріг 1,8','Color',red,'HandleVisibility','off');
ylim(ax,[1 1.9]);set(ax,'XTickLabel',lab);ylabel(ax,'макс. відношення сусідів');legend(ax,{'0,45 мм (вихідна)','0,40 мм'},'Location','southoutside','Orientation','horizontal','Box','off');
title(ax,'в) максимальне відношення','FontWeight','normal');grid(ax,'on');box(ax,'off');dcax(ax);
for k=1:3,text(ax,k-.15,r45(k)+.02,dc(sprintf('%.3f',r45(k))),'FontSize',6,'HorizontalAlignment','center');text(ax,k+.15,r40(k)+.02,dc(sprintf('%.3f',r40(k))),'FontSize',6,'HorizontalAlignment','center');end
ax=nexttile(tl);b=bar(ax,[a45;a40v].','grouped');b(1).FaceColor=[.03 .19 .42];b(2).FaceColor=orng;hold(ax,'on');yline(ax,20,'-','поріг 20°','Color',red,'HandleVisibility','off');
ylim(ax,[0 35]);set(ax,'XTickLabel',lab);ylabel(ax,'мінімальний кут, °');legend(ax,{'0,45 мм (вихідна)','0,40 мм'},'Location','southoutside','Orientation','horizontal','Box','off');
title(ax,'г) мінімальний кут усієї сітки','FontWeight','normal');grid(ax,'on');box(ax,'off');dcax(ax);
for k=1:3,text(ax,k-.15,a45(k)+1,dc(sprintf('%.2f',a45(k))),'FontSize',6,'HorizontalAlignment','center');text(ax,k+.15,a40v(k)+1,dc(sprintf('%.2f',a40v(k))),'FontSize',6,'HorizontalAlignment','center');end
title(tl,{'Рис. LP2B1-3. Ціна кроку 0,40 мм: найменший кут зовнішньої області біля берегів тріщини (вікно ±4 мм) і зведення за трьома геометріями',...
 'Усі сітки 0,40 мм проходять пороги 20° і 1,8 без зміни порогів; запас за кутом менший, ніж у 0,45 мм'},'FontSize',8);
save2(f,fullfile(outDir,'LP2B1_3_kut_i_zvedennia'));
fprintf('LP2B1_FIGURES_DONE\n');
end

function ctxDraw(ax,cen,th,P,tip,full)
for i=1:3,fill(ax,cen(i,1)+6.35*cos(th),cen(i,2)+6.35*sin(th),[.88 .88 .88],'EdgeColor',[.5 .5 .5]);plot(ax,cen(i,1)+19.05*cos(th),cen(i,2)+19.05*sin(th),'-','Color',[.45 .45 .45]);end
plot(ax,tip(1)+15*cos(th),tip(2)+15*sin(th),'--','Color',[.85 .45 .05]);plot(ax,tip(1)+3.3*cos(th),tip(2)+3.3*sin(th),'-','Color',[.03 .19 .42]);
plot(ax,P(:,1),P(:,2),'-','Color','k','LineWidth',1.3);
if full,plot(ax,[0 508 508 0 0],[0 0 203.2 203.2 0],'-k');text(ax,tip(1)+16,tip(2)+3,'15-мм напрямна','FontSize',6,'Color',[.85 .45 .05]);text(ax,cen(1,1)+20,cen(1,2)-6,'кільце 1','FontSize',6,'Color',[.35 .35 .35]);end
end
function el=inwin(X,T,w)
c=(X(T(:,1),:)+X(T(:,2),:)+X(T(:,3),:))/3;el=find(c(:,1)>=w(1)-3&c(:,1)<=w(2)+3&c(:,2)>=w(3)-3&c(:,2)<=w(4)+3);
end
function s=dc(s)
s=regexprep(s,'(\d)\.(\d)','$1,$2');
end
function dcax(ax)
ax.XTickLabel=dc(ax.XTickLabel);ax.YTickLabel=dc(ax.YTickLabel);
end
function save2(f,b),exportgraphics(f,[b '.png'],'Resolution',300);exportgraphics(f,[b '.pdf'],'ContentType','vector');close(f);end
