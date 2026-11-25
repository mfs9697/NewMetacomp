function g2_prelim_figures_a(repo,outDir)
%G2_PRELIM_FIGURES_A  Geometry, architecture and S0-S8 trajectory figures of the G2 preliminary report.
% Plotting only, from committed evidence (docs/research/G2_LP2_evidence/campaign_20261125/LP2A_ANALYSIS.json:
% accepted states A0 S0-S4 and LP2-A1 S5-S8, and the geometry-only S9 candidates of the terminal records).
% No FEM, no MAT files, nothing is written outside outDir.
C = g2_prelim_fig_common();
A = jsondecode(fileread(fullfile(repo,'docs','research','G2_LP2_evidence','campaign_20261125','LP2A_ANALYSIS.json'),'Encoding','UTF-8'));
W = A.states; ids = C.ids; th = linspace(0,2*pi,361);
S9 = struct();
for i=1:4, P = W.(ids{i}).terminal.candidate.polyline_mm; S9.(ids{i}) = P(end,:); end

%% ------------------------------------------------------------ geometry of the model problem
f = C.newfig(16,8.8); ax = axes(f,'Position',[0.02 0.012 0.96 0.976]); hold(ax,'on');
rectangle(ax,'Position',[0 0 C.plate],'EdgeColor','k','LineWidth',1.1,'FaceColor',[.985 .985 .985]);
for h=1:3
    fill(ax,C.cen(h,1)+C.rRing*cos(th),C.cen(h,2)+C.rRing*sin(th),[.86 .86 .86],'EdgeColor',[.35 .35 .35],'LineWidth',.6);
    fill(ax,C.cen(h,1)+C.rHole*cos(th),C.cen(h,2)+C.rHole*sin(th),'w','EdgeColor','k','LineWidth',.8);
    text(ax,C.cen(h,1)+23,C.cen(h,2),sprintf('кільце %d',h),'FontSize',8.5,'VerticalAlignment','middle');
end
plot(ax,[C.mouth(1) C.tip0(1)],[C.mouth(2) C.tip0(2)],'-','Color',[.75 .1 .1],'LineWidth',2);
text(ax,C.tip0(1)-6,42,{'початкова','тріщина'},'FontSize',8.5,'HorizontalAlignment','right','VerticalAlignment','middle','Color',[.6 .1 .1]);
% load
quiver(ax,C.load(1),C.load(2)+34,0,-30,0,'k','LineWidth',1.3,'MaxHeadSize',0.9);
text(ax,C.load(1)+6,C.load(2)+24,'{\itP}','FontSize',11);
% supports (labels beside the supports, clear of the dimension lines below)
tri = @(x) fill(ax,x+[0 -9 9],[0 -15 -15],[.55 .55 .55],'EdgeColor','k');
tri(C.pin(1)); tri(C.roller(1));
plot(ax,C.pin(1)+[-13 13],[-15 -15],'k-','LineWidth',1.2);
for xx=-6:6:6, plot(ax,C.roller(1)+xx+2.2*cos(th),-17.6+2.2*sin(th),'k-','LineWidth',.6); end
plot(ax,C.roller(1)+[-13 13],[-20.2 -20.2],'k-','LineWidth',1.2);
text(ax,C.pin(1)+17,-9,'шарнір: {\itu_x} = {\itu_y} = 0','FontSize',8,'HorizontalAlignment','left','VerticalAlignment','middle');
text(ax,C.roller(1)-17,-10,'каток: {\itu_y} = 0','FontSize',8,'HorizontalAlignment','right','VerticalAlignment','middle');
% dimensions
dimh(ax,0,508,-52,'508'); dimh(ax,0,101.6,-35,'101,6'); dimh(ax,101.6,152.4,-35,'50,8');
dimh(ax,0,254,C.plate(2)+44,'254'); dimh(ax,0,25.4,C.plate(2)+14,'25,4'); dimh(ax,482.6,508,C.plate(2)+14,'25,4');
dimv(ax,0,203.2,C.plate(1)+16,'203,2'); dimv(ax,0,25.4,116,'25,4');
dimv(ax,0,69.85,242,'69,85'); dimv(ax,69.85,120.65,242,'50,8'); dimv(ax,120.65,171.45,242,'50,8');
text(ax,290,150,{'отвори: {\itR}_{о} = 6,35 мм','кільця: {\itR}_{к} = 19,05 мм','товщина 12,7 мм'},'FontSize',8.5,'VerticalAlignment','top');
% axes of the coordinate system
quiver(ax,0,0,34,0,0,'Color',[.1 .1 .6],'LineWidth',.9,'MaxHeadSize',.8); quiver(ax,0,0,0,34,0,'Color',[.1 .1 .6],'LineWidth',.9,'MaxHeadSize',.8);
text(ax,37,8,'{\itx}','Color',[.1 .1 .6]); text(ax,6,39,'{\ity}','Color',[.1 .1 .6]);
axis(ax,'equal'); xlim(ax,[-24 568]); ylim(ax,[-60 264]); axis(ax,'off');
C.save(f,outDir,'F02_geometriia_zadachi');

%% ------------------------------------------------------------ four architectures
f = C.newfig(16,7.4); masks = [0 0 0;1 0 1;0 1 0;1 0 0]; kind = [0 2 1 1];   % 2 stiff, 1 soft
ttl = {{'H','однорідна','пластина'},{'stiff13','{\itE}_к/{\itE}_м = 2','у кільцях 1 і 3'},{'soft2','{\itE}_к/{\itE}_м = 0,5','у кільці 2'},{'soft1','{\itE}_к/{\itE}_м = 0,5','у кільці 1'}};
for i=1:4
    ax = axes(f,'Position',[0.03+(i-1)*0.245 0.135 0.215 0.665]); hold(ax,'on');
    rectangle(ax,'Position',[60 0 150 203.2],'EdgeColor','none','FaceColor',[.985 .985 .985]);
    plot(ax,[60 210],[0 0],'k-','LineWidth',1); plot(ax,[60 210],[203.2 203.2],'k-','LineWidth',1);
    for h=1:3
        if masks(i,h)==0, fc = C.passiveCol; ec=[.6 .6 .6]; lst=':';
        elseif kind(i)==2, fc = C.stiffCol; ec=[.55 .15 .1]; lst='-';
        else, fc = C.softCol; ec=[.1 .3 .6]; lst='-'; end
        fill(ax,C.cen(h,1)+C.rRing*cos(th),C.cen(h,2)+C.rRing*sin(th),fc,'EdgeColor',ec,'LineStyle',lst,'LineWidth',.8);
        fill(ax,C.cen(h,1)+C.rHole*cos(th),C.cen(h,2)+C.rHole*sin(th),'w','EdgeColor','k','LineWidth',.7);
        text(ax,C.cen(h,1)+24,C.cen(h,2),sprintf('%d',h),'FontSize',9);
    end
    P = W.(ids{i}).tip; plot(ax,[101.6;P(:,1)],[0;P(:,2)],'-','Color',C.col{i},'LineWidth',1.6);
    axis(ax,'equal'); xlim(ax,[60 210]); ylim(ax,[-4 207]); axis(ax,'off');
    text(ax,0.5,1.30,ttl{i},'Units','normalized','HorizontalAlignment','center','VerticalAlignment','top','FontSize',8.6);   % first lines aligned
end
ax = axes(f,'Position',[0.03 0.0 0.94 0.085]); hold(ax,'on'); axis(ax,'off'); xlim(ax,[0 1]); ylim(ax,[0 1]);
lg = {C.stiffCol,'жорстке кільце (активне)';C.softCol,'м’яке кільце (активне)';C.passiveCol,'пасивний контур (матеріал матриці)'};
x0 = [0.04 0.33 0.60];
for k=1:3
    rectangle(ax,'Position',[x0(k) 0.25 0.035 0.5],'FaceColor',lg{k,1},'EdgeColor',[.4 .4 .4]);
    text(ax,x0(k)+0.045,0.5,lg{k,2},'FontSize',8.5,'VerticalAlignment','middle');
end
C.save(f,outDir,'F05_chotyry_arkhitektury');

%% ------------------------------------------------------------ crack paths: full view, true-scale zoom, magnified offsets
f = C.newfig(16,11);
ax = axes(f,'Position',[0.065 0.22 0.285 0.66]); hold(ax,'on');           % (a) region of the three rings
for h=1:3
    fill(ax,C.cen(h,1)+C.rRing*cos(th),C.cen(h,2)+C.rRing*sin(th),[.88 .88 .88],'EdgeColor',[.4 .4 .4]);
    fill(ax,C.cen(h,1)+C.rHole*cos(th),C.cen(h,2)+C.rHole*sin(th),'w','EdgeColor','k');
    text(ax,C.cen(h,1)+22,C.cen(h,2),sprintf('%d',h),'FontSize',9);
end
plot(ax,[60 200],[0 0],'k-','LineWidth',1);
P = W.H.tip; plot(ax,[101.6;P(:,1)],[0;P(:,2)],'k-','LineWidth',1.4);
plot(ax,S9.H(1),S9.H(2),'ko','MarkerSize',3.5,'MarkerFaceColor','w');
rectangle(ax,'Position',[99 22 16 40],'EdgeColor',[.2 .2 .8],'LineStyle','--');
text(ax,117,42,'(б)','Color',[.2 .2 .8],'FontSize',9);
axis(ax,'equal'); xlim(ax,[70 190]); ylim(ax,[-4 196]); box(ax,'on'); xlabel(ax,'{\itx}, мм'); ylabel(ax,'{\ity}, мм');
C.dec(ax); C.panel(ax,'(а) траєкторія H і кільця');
ax = axes(f,'Position',[0.44 0.22 0.22 0.66]); hold(ax,'on');            % (b) true scale
for i=1:4
    P = W.(ids{i}).tip;
    plot(ax,[101.6;P(:,1)],[0;P(:,2)],C.ls{i},'Color',C.col{i},'LineWidth',1.1);
    plot(ax,P(:,1),P(:,2),C.mk{i},'Color',C.col{i},'MarkerSize',3.2,'MarkerFaceColor',C.col{i});
    q = S9.(ids{i}); plot(ax,[P(end,1) q(1)],[P(end,2) q(2)],':','Color',C.col{i},'LineWidth',.7);
    plot(ax,q(1),q(2),C.mk{i},'Color',C.col{i},'MarkerSize',4,'MarkerFaceColor','w');
end
text(ax,102.2,24.6,'S0','FontSize',8,'VerticalAlignment','top'); text(ax,112.2,55.3,'S8','FontSize',8); text(ax,113.0,60.9,'S9*','FontSize',8,'HorizontalAlignment','center');
axis(ax,'equal'); xlim(ax,[99 115]); ylim(ax,[22 62]); box(ax,'on'); grid(ax,'on'); xlabel(ax,'{\itx}, мм'); ylabel(ax,'{\ity}, мм');
C.dec(ax); C.panel(ax,'(б) істинний масштаб');
ax = axes(f,'Position',[0.745 0.22 0.22 0.66]); hold(ax,'on');           % (c) offsets from the H path x 20
mag = 20; PH = W.H.tip;
for i=1:4
    P = W.(ids{i}).tip; Pm = PH + mag*(P-PH);
    plot(ax,Pm(:,1),Pm(:,2),[C.ls{i} C.mk{i}],'Color',C.col{i},'LineWidth',1.1,'MarkerSize',3.4,'MarkerFaceColor',C.col{i});
    q = S9.H + mag*(S9.(ids{i})-S9.H);
    plot(ax,[Pm(end,1) q(1)],[Pm(end,2) q(2)],':','Color',C.col{i},'LineWidth',.7);
    plot(ax,q(1),q(2),C.mk{i},'Color',C.col{i},'MarkerSize',4,'MarkerFaceColor','w');
end
axis(ax,'equal'); xlim(ax,[98.3 118.7]); ylim(ax,[22 64]); ax.XTick = 100:5:115; box(ax,'on'); grid(ax,'on'); xlabel(ax,'{\itx}, мм (умовно)'); ylabel(ax,'{\ity}, мм (умовно)');
C.dec(ax); C.panel(ax,{'(в) відхилення від H,','збільшені в 20 разів (×20)'});
lgax = axes(f,'Position',[0.06 0.0 0.9 0.105]); hold(lgax,'on'); axis(lgax,'off'); xlim(lgax,[0 1]); ylim(lgax,[0 1]);
xs = [0.02 0.45 0.02 0.45]; ys = [.70 .70 .27 .27];                       % 2 x 2 legend
for i=1:4
    plot(lgax,xs(i)+[0 0.06],[ys(i) ys(i)],[C.ls{i}],'Color',C.col{i},'LineWidth',1.2);
    plot(lgax,xs(i)+0.03,ys(i),C.mk{i},'Color',C.col{i},'MarkerSize',3.5,'MarkerFaceColor',C.col{i});
    text(lgax,xs(i)+0.075,ys(i),C.names{i},'FontSize',8.3,'VerticalAlignment','middle');
end
C.save(f,outDir,'F08_1_traiektorii');

%% ------------------------------------------------------------ signed SIFs and mode mixity
f = C.newfig(16,6.6); tl = tiledlayout(f,1,3,'TileSpacing','compact','Padding','compact');
ax = nexttile(tl); hold(ax,'on');
for i=1:4, w=W.(ids{i}); plot(ax,w.s,1e3*w.KI,[C.ls{i} C.mk{i}],'Color',C.col{i},'MarkerFaceColor','w','MarkerSize',3.6,'LineWidth',1); end
fin(ax,C); ylabel(ax,'{\itK}_I·10^3, Н·мм^{−3/2}'); C.dec(ax); C.panel(ax,'(а) {\itK}_I');
ax = nexttile(tl); hold(ax,'on');
for i=1:4, w=W.(ids{i}); plot(ax,w.s(2:end),1e5*w.KII(2:end),[C.ls{i} C.mk{i}],'Color',C.col{i},'MarkerFaceColor','w','MarkerSize',3.6,'LineWidth',1); end
fin(ax,C); ylabel(ax,'{\itK}_{II}·10^5, Н·мм^{−3/2}'); ylim(ax,[0 15]); C.dec(ax); C.panel(ax,'(б) {\itK}_{II} (S1–S8)');
text(ax,25.2,0.7,'S0: 54,9…61,6 (поза шкалою)','FontSize',7.5);
ax = nexttile(tl); hold(ax,'on');
for i=1:4, w=W.(ids{i}); plot(ax,w.s(2:end),w.KII(2:end)./w.KI(2:end),[C.ls{i} C.mk{i}],'Color',C.col{i},'MarkerFaceColor','w','MarkerSize',3.6,'LineWidth',1); end
fin(ax,C); ylabel(ax,'{\itK}_{II}/{\itK}_I'); ylim(ax,[0 0.02]); C.dec(ax); C.panel(ax,'(в) змішаність (S1–S8)');
text(ax,25.2,0.0012,'S0: 0,103…0,119 (поза шкалою)','FontSize',7.5);
lg = legend(nexttile(tl,1),C.leg,'Orientation','horizontal','FontSize',8,'Box','off','NumColumns',4); lg.Layout.Tile = 'south';
C.save(f,outDir,'F08_2_KI_KII');

%% ------------------------------------------------------------ absolute G and own-path contrast
f = C.newfig(16,7.4); tl = tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
ax = nexttile(tl); hold(ax,'on');
for i=1:4, w=W.(ids{i}); plot(ax,w.s,1e8*w.G,[C.ls{i} C.mk{i}],'Color',C.col{i},'MarkerFaceColor','w','MarkerSize',4,'LineWidth',1.1); end
fin(ax,C); ylabel(ax,'{\itG}·10^8, Н/мм  ({\itP} = 1 Н)'); C.dec(ax); C.panel(ax,'(а) абсолютна рушійна сила');
ax = nexttile(tl); hold(ax,'on');
for i=2:4, r=A.(ids{i}); plot(ax,r.s_mm,100*r.F_G,[C.ls{i} C.mk{i}],'Color',C.col{i},'MarkerFaceColor','w','MarkerSize',4,'LineWidth',1.1); end
yline(ax,0,'k-'); fin(ax,C); ylabel(ax,'{\itF_G} = {\itG_X}/{\itG}_H − 1, %'); ylim(ax,[-12 12]); C.dec(ax); C.panel(ax,'(б) відносний контраст на власних траєкторіях');
text(ax,26,10.6,'підсилення','FontSize',8,'Color',[.3 .3 .3]); text(ax,26,-11,'екранування','FontSize',8,'Color',[.3 .3 .3]);
lg = legend(nexttile(tl,1),C.leg,'Orientation','horizontal','FontSize',8,'Box','off','NumColumns',4); lg.Layout.Tile = 'south';
C.save(f,outDir,'F08_3_G_FG');

%% ------------------------------------------------------------ local MTS increments, relative heading, lateral offset
f = C.newfig(16,11.6); tl = tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');
ax = nexttile(tl); hold(ax,'on');
for i=1:4, w=W.(ids{i}); plot(ax,w.s(2:end),w.MTS(2:end),[C.ls{i} C.mk{i}],'Color',C.col{i},'MarkerFaceColor','w','MarkerSize',3.8,'LineWidth',1); end
fin(ax,C); ylabel(ax,'\theta_{\itn}, °'); ylim(ax,[-2.1 -0.8]); ax.YTick = -2.0:0.2:-0.8; C.dec(ax); C.panel(ax,'(а) локальний приріст кута МКН (S1–S8)');
text(ax,58.6,-2.04,'S0: −11,51…−13,26° (поза шкалою)','FontSize',7.5,'HorizontalAlignment','right');
ax = nexttile(tl); hold(ax,'on');
for i=2:4, r=A.(ids{i}); plot(ax,r.s_mm(2:end),r.dMTS_deg(2:end),[C.ls{i} C.mk{i}],'Color',C.col{i},'MarkerFaceColor','w','MarkerSize',3.8,'LineWidth',1); end
yline(ax,0,'k-'); fin(ax,C); ylabel(ax,'\Delta\theta_{\itn} = \theta_{\itn}^{\itX} − \theta_{\itn}^{H}, °'); ylim(ax,[-0.5 0.5]); C.dec(ax); C.panel(ax,'(б) різниця локальних приростів (S1–S8)');
text(ax,25.2,0.44,'S0: −0,663°; −0,243°; +1,084°','FontSize',7.5);
ax = nexttile(tl); hold(ax,'on');
for i=2:4
    r=A.(ids{i}); plot(ax,r.s_mm,r.dHeading_deg,[C.ls{i} C.mk{i}],'Color',C.col{i},'MarkerFaceColor',C.col{i},'MarkerSize',3.8,'LineWidth',1);
    h9 = r.dHeading_deg(end)+r.dMTS_deg(end);
    plot(ax,[57.4 61.4],[r.dHeading_deg(end) h9],':','Color',C.col{i},'LineWidth',.8);
    plot(ax,61.4,h9,C.mk{i},'Color',C.col{i},'MarkerFaceColor','w','MarkerSize',4.6);
end
yline(ax,0,'k-'); fin(ax,C); xlim(ax,[24 63]); ax.XTick=[25.4:8:57.4 61.4]; ylabel(ax,'\Delta\phi_{\itn} = \phi_{\itn}^{\itX} − \phi_{\itn}^{H}, °'); ylim(ax,[-0.9 1.3]); C.dec(ax);
C.panel(ax,{'(в) відносний курс;','порожні маркери — прогноз S9*'});
ax = nexttile(tl); hold(ax,'on');
for i=2:4, r=A.(ids{i}); plot(ax,r.s_mm,r.d_mm,[C.ls{i} C.mk{i}],'Color',C.col{i},'MarkerFaceColor',C.col{i},'MarkerSize',3.8,'LineWidth',1); end
yline(ax,0,'k-'); fin(ax,C); ylabel(ax,'{\itd}, мм'); ylim(ax,[-0.4 0.6]); C.dec(ax); C.panel(ax,{'(г) знакове бічне зміщення','вершини відносно H'});
lg = legend(nexttile(tl,1),C.leg,'Orientation','horizontal','FontSize',8,'Box','off','NumColumns',4); lg.Layout.Tile = 'south';
C.save(f,outDir,'F08_4_kurs_i_zmishchennia');
end

function fin(ax,C) %#ok<INUSD>
xline(ax,41.4,':','Color',[.45 .45 .45],'HandleVisibility','off');
grid(ax,'on'); box(ax,'on'); xlim(ax,[24 59]); ax.XTick = 25.4:8:57.4; xlabel(ax,'довжина тріщини {\its}, мм');
end

function dimh(ax,x1,x2,y,str)
plot(ax,[x1 x2],[y y],'-','Color',[.3 .3 .3],'LineWidth',.5);
plot(ax,[x1 x1],[y-3 y+3],'-','Color',[.3 .3 .3],'LineWidth',.5); plot(ax,[x2 x2],[y-3 y+3],'-','Color',[.3 .3 .3],'LineWidth',.5);
text(ax,(x1+x2)/2,y+1,str,'FontSize',7.5,'HorizontalAlignment','center','VerticalAlignment','bottom','Color',[.2 .2 .2]);
end

function dimv(ax,y1,y2,x,str)
plot(ax,[x x],[y1 y2],'-','Color',[.3 .3 .3],'LineWidth',.5);
plot(ax,[x-3 x+3],[y1 y1],'-','Color',[.3 .3 .3],'LineWidth',.5); plot(ax,[x-3 x+3],[y2 y2],'-','Color',[.3 .3 .3],'LineWidth',.5);
text(ax,x+2,(y1+y2)/2,str,'FontSize',7.5,'HorizontalAlignment','left','VerticalAlignment','middle','Color',[.2 .2 .2]);
end
