function kbp_figures(repo,outDir)
%KBP_FIGURES  Presentation figures P1-P3 for the KB Pivdenne 2026 H2 report (plotting only; no FEM).
% The only data source is the committed analysis record
%   docs/research/G2_LP2_evidence/campaign_20261125/LP2A_ANALYSIS.json
% (accepted states S0-S4 of A0/LP1 and S5-S8 of LP2-A1; field states.<id>.tip, .s, .G and <id>.F_G, .d_mm).
% Geometry-only S9 candidates of that record are NOT used. Nothing is written outside outDir.
%   kbp_figures(repoRoot, outDir)
S = kbp_style();
A = jsondecode(fileread(fullfile(repo,'docs','research','G2_LP2_evidence','campaign_20261125','LP2A_ANALYSIS.json'),'Encoding','UTF-8'));
W = A.states; ids = S.ids;
P = cell(1,4); for i=1:4, P{i} = [S.mouth; W.(ids{i}).tip]; end     % crack polyline: mouth, S0 ... S8 (straight 4-mm segments)
for i=1:4, assert(size(W.(ids{i}).tip,1)==9 && norm(W.(ids{i}).tip(1,:)-S.tip0)<1e-12,'unexpected record'); end

%% ================================================================ P1: four configurations
f = S.newfig(30,14);
xl = [72 198]; yl = [-3 206]; hp = 9.0; sc = hp/diff(yl); wp = diff(xl)*sc; gap = (30-4*wp)/5;
for i=1:4
    ax = S.ax(f,gap+(i-1)*(wp+gap),2.0,wp,hp);
    patch(ax,[xl(1) xl(2) xl(2) xl(1)],[0 0 S.plate(2) S.plate(2)],S.plateFill,'EdgeColor','none');
    plot(ax,xl,[0 0],'k-','LineWidth',2); plot(ax,xl,S.plate(2)*[1 1],'k-','LineWidth',2);
    S.rings(ax,S,i,1.6);
    for h=1:3, text(ax,S.cen(h,1)+23.5,S.cen(h,2),sprintf('%d',h),'FontSize',S.fsTick,'VerticalAlignment','middle','Color',[.25 .25 .25]); end
    plot(ax,[S.mouth(1) S.tip0(1)],[S.mouth(2) S.tip0(2)],'-','Color',S.crack0,'LineWidth',S.lw);
    q = P{i}(2:end,:); plot(ax,q(:,1),q(:,2),'-','Color',S.col{i},'LineWidth',S.lw+0.5);
    plot(ax,q(end,1),q(end,2),S.mk{i},'Color',S.col{i},'MarkerFaceColor',S.col{i},'MarkerSize',S.ms-1);
    set(ax,'XLim',xl,'YLim',yl,'DataAspectRatio',[1 1 1]); axis(ax,'off');
    t2 = S.ratio{i}; if i==1, t2 = '{\itE}_к = {\itE}_м'; end
    text(ax,0.5,1.01,[strcat('\bf',S.name2{i}),{['\rm' t2]}],'Units','normalized','HorizontalAlignment','center','VerticalAlignment','bottom', ...
        'FontSize',S.fsTitle-1,'Color',S.col{i});
end
lg = S.ax(f,0,0,30,1.7); axis(lg,'off'); set(lg,'XLim',[0 30],'YLim',[0 1.7]);
x0 = [0.5 6.3 12.9 22.3]; y0 = 0.85;
rectangle(lg,'Position',[x0(1) y0-0.35 0.9 0.7],'FaceColor',S.stiffFill,'EdgeColor',S.stiffEdge,'LineWidth',1.6);
text(lg,x0(1)+1.15,y0,'жорстке кільце','FontSize',S.fsSmall,'VerticalAlignment','middle');
rectangle(lg,'Position',[x0(2) y0-0.35 0.9 0.7],'FaceColor',S.softFill,'EdgeColor',S.softEdge,'LineWidth',1.6);
text(lg,x0(2)+1.15,y0,'податливе кільце','FontSize',S.fsSmall,'VerticalAlignment','middle');
rectangle(lg,'Position',[x0(3) y0-0.35 0.9 0.7],'FaceColor','w','EdgeColor',S.passEdge,'LineStyle',':','LineWidth',1.6);
text(lg,x0(3)+1.15,y0,'кільце з матеріалу матриці','FontSize',S.fsSmall,'VerticalAlignment','middle');
plot(lg,x0(4)+[0 1.1],[y0 y0],'-','Color',S.crack0,'LineWidth',S.lw);
text(lg,x0(4)+1.35,y0,'початкова тріщина','FontSize',S.fsSmall,'VerticalAlignment','middle');
S.save(f,outDir,'P1_materialni_konfihuratsii');

%% ================================================================ P2a: true scale + enlarged fragment
f = S.newfig(30,14);
xl = [86 178]; yl = [-2 92]; h1 = 11; s1 = h1/diff(yl); w1 = diff(xl)*s1; x1 = 2.2; y1 = 1.9;
ax = S.ax(f,x1,y1,w1,h1);
patch(ax,[xl(1) xl(2) xl(2) xl(1)],[0 0 yl(2) yl(2)],S.plateFill,'EdgeColor','none');
plot(ax,xl,[0 0],'k-','LineWidth',2);
S.rings(ax,S,0,1.4); text(ax,131,84,'кільце 1','FontSize',S.fsSmall,'Color',[.3 .3 .3],'HorizontalAlignment','right');
plot(ax,[S.mouth(1) S.tip0(1)],[S.mouth(2) S.tip0(2)],'-','Color',S.crack0,'LineWidth',S.lw);
for i=[4 3 2 1], q=P{i}(2:end,:); plot(ax,q(:,1),q(:,2),'-','Color',S.col{i},'LineWidth',3); end
zx = [107.0 112.6]; zy = [47.4 57.2];
rectangle(ax,'Position',[zx(1) zy(1) diff(zx) diff(zy)],'EdgeColor',[.25 .25 .25],'LineWidth',1.5,'LineStyle','--');
set(ax,'XLim',xl,'YLim',yl,'DataAspectRatio',[1 1 1],'XTick',90:20:170,'YTick',0:20:80,'Layer','top','Box','on');
xlabel(ax,'{\itx}, мм','FontSize',S.fs); ylabel(ax,'{\ity}, мм','FontSize',S.fs);
title(ax,'Справжній масштаб','FontSize',S.fsTitle,'FontWeight','bold');
% enlarged fragment (equal aspect, i.e. still true proportions)
h2 = 11; s2 = h2/diff(zy); w2 = diff(zx)*s2; x2 = x1+w1+1.7; y2 = y1;
bx = S.ax(f,x2,y2,w2,h2);
for i=[4 2 3 1]
    q=P{i}; k = q(:,1)>=zx(1)-1 & q(:,2)>=zy(1)-2;
    plot(bx,q(k,1),q(k,2),'-','Color',S.col{i},'LineWidth',S.lw);
    m = q(:,1)>=zx(1) & q(:,1)<=zx(2) & q(:,2)>=zy(1) & q(:,2)<=zy(2);
    plot(bx,q(m,1),q(m,2),S.mk{i},'Color',S.col{i},'MarkerFaceColor',S.col{i},'MarkerSize',S.ms);
end
lbl = {'S6','S7','S8'}; for k=1:3, xm = max(cellfun(@(c)c(k+7,1),P)); text(bx,xm+0.22,P{1}(k+7,2),lbl{k},'FontSize',S.fsSmall,'HorizontalAlignment','left','VerticalAlignment','middle'); end
plot(bx,zx(2)-[1.25 0.25],zy(1)+0.45*[1 1],'k-','LineWidth',3);
text(bx,zx(2)-0.75,zy(1)+0.6,'1 мм','FontSize',S.fsSmall,'HorizontalAlignment','center','VerticalAlignment','bottom');
set(bx,'XLim',zx,'YLim',zy,'DataAspectRatio',[1 1 1],'XTick',108:2:112,'YTick',48:2:56,'Box','on','LineWidth',1.5,'XColor',[.25 .25 .25],'YColor',[.25 .25 .25]);
xlabel(bx,'{\itx}, мм','FontSize',S.fs); ylabel(bx,'{\ity}, мм','FontSize',S.fs);
title(bx,'Збільшений фрагмент','FontSize',S.fsTitle,'FontWeight','bold');
% connectors from the frame to the enlarged view
fw = f.Position(3); fh = f.Position(4);
c1 = [x1+(zx(2)-xl(1))*s1, y1+(zy(2)-yl(1))*s1]; c2 = [x1+(zx(2)-xl(1))*s1, y1+(zy(1)-yl(1))*s1];
annotation(f,'line',[c1(1) x2]/fw,[c1(2) y2+h2]/fh,'Color',[.45 .45 .45],'LineWidth',1.2,'LineStyle','--');
annotation(f,'line',[c2(1) x2]/fw,[c2(2) y2]/fh,'Color',[.45 .45 .45],'LineWidth',1.2,'LineStyle','--');
legendRight(f,S,x2+w2+0.6,y1+h2-0.4);
S.save(f,outDir,'P2a_traiektorii_spravzhnii_masshtab');

%% ================================================================ P2b: differences from H, magnified x20, and lateral offset
f = S.newfig(30,14);
mag = 20; PH = P{1};
xl = [95 123]; yl = [21 61]; h1 = 10.4; s1 = h1/diff(yl); w1 = diff(xl)*s1; x1 = 1.6; y1 = 1.9;
ax = S.ax(f,x1,y1,w1,h1);
for i=[4 3 2 1]
    q = PH + mag*(P{i}-PH); q = q(2:end,:);
    plot(ax,q(:,1),q(:,2),'-','Color',S.col{i},'LineWidth',S.lw);
    plot(ax,q(:,1),q(:,2),S.mk{i},'Color',S.col{i},'MarkerFaceColor',S.col{i},'MarkerSize',S.ms-1);
end
text(ax,122.4,60.4,'×20','FontSize',34,'FontWeight','bold','VerticalAlignment','top','HorizontalAlignment','right','Color',[.2 .2 .2]);
bx1 = 122; by0 = 29;                                      % scale bars: 5 mm of the drawing = 0.25 mm of deviation
plot(ax,bx1-[5 0],[by0 by0],'k-','LineWidth',3); text(ax,bx1,by0+0.5,'5 мм','FontSize',S.fsSmall,'HorizontalAlignment','right','VerticalAlignment','bottom');
plot(ax,bx1-[5 0],(by0-5)*[1 1],'-','Color',[.45 .45 .45],'LineWidth',3); text(ax,bx1,by0-4.5,'відхилення 0,25 мм','FontSize',S.fsSmall-1,'HorizontalAlignment','right','VerticalAlignment','bottom','Color',[.3 .3 .3]);
set(ax,'XLim',xl,'YLim',yl,'DataAspectRatio',[1 1 1],'XTick',[],'YTick',[],'Box','on','LineWidth',1.2);
title(ax,{'Відхилення від H,','збільшені в 20 разів'},'FontSize',S.fsTitle-2,'FontWeight','bold');
% lateral offset, true values
x2 = x1+w1+3.3; w2 = 8.8; bx = S.ax(f,x2,y1+0.5,w2,h1-0.5);
yline(bx,0,'-','Color',S.col{1},'LineWidth',S.lw,'HandleVisibility','off');
for i=2:4, r = A.(ids{i}); plot(bx,r.s_mm,r.d_mm,'-','Color',S.col{i},'LineWidth',S.lw); plot(bx,r.s_mm,r.d_mm,S.mk{i},'Color',S.col{i},'MarkerFaceColor',S.col{i},'MarkerSize',S.ms-1); end
set(bx,'XLim',[24 59],'XTick',25.4:8:57.4,'YLim',[-0.4 0.6],'YTick',-0.4:0.2:0.6,'Box','on');
S.dec(bx,'x',1); S.dec(bx,'y',1);
xlabel(bx,'довжина тріщини {\its}, мм','FontSize',S.fs); ylabel(bx,'бічне зміщення {\itd}, мм','FontSize',S.fs);
text(bx,25,0.55,'{\itd} > 0: ліворуч від H','FontSize',S.fsSmall-1,'Color',[.35 .35 .35],'VerticalAlignment','top');
title(bx,{'Бічне зміщення вершини','(справжні значення)'},'FontSize',S.fsTitle-2,'FontWeight','bold');
legendRight(f,S,x2+w2+0.6,y1+h1-0.4);
S.save(f,outDir,'P2b_vidkhylennia_vid_H');

%% ================================================================ P3: shielding and amplification of the driving force
f = S.newfig(30,14);
xa = 3.6; ya = 3.0; wa = 17.6; ha = 9.5; ax = S.ax(f,xa,ya,wa,ha);
xl = [24 59]; yl = [-14 14];
patch(ax,[xl(1) xl(2) xl(2) xl(1)],[0 0 yl(2) yl(2)],[253 236 224]/255,'EdgeColor','none');
patch(ax,[xl(1) xl(2) xl(2) xl(1)],[yl(1) yl(1) 0 0],[226 238 248]/255,'EdgeColor','none');
text(ax,25.0,13.3,'ПІДСИЛЕННЯ','FontSize',S.fsTitle,'FontWeight','bold','Color',[.55 .35 .25],'VerticalAlignment','top');
text(ax,25.0,-13.3,'ЕКРАНУВАННЯ','FontSize',S.fsTitle,'FontWeight','bold','Color',[.2 .35 .55],'VerticalAlignment','bottom');
yline(ax,0,'-','Color',S.col{1},'LineWidth',S.lw-0.5);
text(ax,58.6,0.6,'H — однорідний матеріал','FontSize',S.fsSmall,'HorizontalAlignment','right','VerticalAlignment','bottom');
for i=[2 3 4]
    r = A.(ids{i}); y = 100*r.F_G;
    plot(ax,r.s_mm,y,'-','Color',S.col{i},'LineWidth',S.lw);
    plot(ax,r.s_mm(1:end-1),y(1:end-1),S.mk{i},'Color',S.col{i},'MarkerFaceColor','w','MarkerSize',S.ms-1,'LineWidth',2);
    plot(ax,r.s_mm(end),y(end),S.mk{i},'Color',S.col{i},'MarkerFaceColor',S.col{i},'MarkerSize',S.ms+3);
end
set(ax,'XLim',xl,'YLim',yl,'XTick',25.4:8:57.4,'YTick',-12:4:12,'Box','on','Layer','top');
ax.XAxis.MinorTickValues = 29.4:8:53.4; ax.XMinorTick = 'on';
S.dec(ax,'x',1); S.dec(ax,'y',0);
xlabel(ax,'довжина тріщини {\its}, мм','FontSize',S.fs);
ylabel(ax,'{\itF_G} = 100·({\itG}/{\itG}_H − 1), %','FontSize',S.fs);
title(ax,'Відносний контраст рушійної сили тріщини','FontSize',S.fsTitle,'FontWeight','bold');
% terminal S8 values in the right margin
xr = xa+wa+0.6; fh = f.Position(4); fw = f.Position(3);
lab = {'','Жорсткі кільця 1 і 3','Податливе кільце 2','Податливе кільце 1'};
yv = zeros(1,4); for i=2:4, yv(i) = 100*A.(ids{i}).F_G(end); end
for i=2:4
    ycm = ya+(yv(i)-yl(1))/diff(yl)*ha;
    v = strrep(strrep(sprintf('%+.2f %%',yv(i)),'.',','),'-',char(8722));
    annotation(f,'textbox',[xr/fw (ycm-0.05)/fh 8.5/fw 1.2/fh],'String',['\bf' v],'FontSize',30,'Color',S.col{i}, ...
        'EdgeColor','none','VerticalAlignment','bottom','HorizontalAlignment','left','FitBoxToText','off','Margin',0,'Interpreter','tex');
    annotation(f,'textbox',[xr/fw (ycm-1.0)/fh 8.5/fw 0.9/fh],'String',lab{i},'FontSize',S.fsSmall+1,'Color',S.col{i}, ...
        'EdgeColor','none','VerticalAlignment','top','HorizontalAlignment','left','FitBoxToText','off','Margin',0);
end
annotation(f,'textbox',[xr/fw (ya+ha+0.15)/fh 8.5/fw 0.8/fh],'String','S8 (кінцевий стан)','FontSize',S.fsSmall,'Color',[.3 .3 .3], ...
    'EdgeColor','none','VerticalAlignment','bottom','HorizontalAlignment','left','Margin',0);
annotation(f,'textbox',[xa/fw 0.15/fh 26/fw 0.8/fh],'String', ...
    'Відносна величина: абсолютна {\itG} зростає з довжиною тріщини в усіх чотирьох конфігураціях.', ...
    'FontSize',S.fsSmall-1,'Color',[.35 .35 .35],'EdgeColor','none','VerticalAlignment','bottom','HorizontalAlignment','left','Margin',0,'Interpreter','tex');
S.save(f,outDir,'P3_ekranuvannia_i_pidsylennia');
end

function legendRight(f,S,xcm,ytop)
% vertical legend (line + marker + name) placed in centimetres to the right of the plots
lg = S.ax(f,xcm,ytop-4*1.25,8.3,4*1.25); axis(lg,'off'); set(lg,'XLim',[0 8.3],'YLim',[0 5]);
for i=1:4
    y = 5-(i-0.5)*1.25;
    plot(lg,[0 1.2],[y y],'-','Color',S.col{i},'LineWidth',S.lw);
    plot(lg,0.6,y,S.mk{i},'Color',S.col{i},'MarkerFaceColor',S.col{i},'MarkerSize',S.ms-1);
    text(lg,1.5,y,S.name{i},'FontSize',S.fsSmall+1,'VerticalAlignment','middle');
end
end
