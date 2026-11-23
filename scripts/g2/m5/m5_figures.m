function m5_figures(repo,outDir)
%M5_FIGURES  Ukrainian greyscale figures for the G2-M5 memorandum from EXISTING records only (no FEM).
%  m5_figures(repo,outDir)
% Inputs: docs/research/G2_M5_evidence/M5_EXISTING_EVIDENCE.json (scripts/g2/m5/m5_existing_evidence.py)
%         docs/research/G2_LP1_SR1_independent_check/LP1_records_reduced.json (polylines)
%         matlab/g2/G2_LP1_POLICY_v2.json (plate, rings, supports, load)
% M5-1 specimen, rings, pin-load line and S0-S4 paths, with the lateral offset d(s);
% M5-2 F_G along the path: own path (total) vs fixed homogeneous geometry (direct: S0, frozen S2);
% M5-3 Irwin-Kies reading: relative compliance increment dC/C_H versus crack length.
assert(~isfolder(outDir),'M5Fig:Out','Output folder exists.');mkdir(outDir);
set(groot,'defaultAxesFontName','Arial','defaultTextFontName','Arial','defaultAxesFontSize',9);
A=jsondecode(fileread(fullfile(repo,'docs','research','G2_M5_evidence','M5_EXISTING_EVIDENCE.json')));
L=jsondecode(fileread(fullfile(repo,'docs','research','G2_LP1_SR1_independent_check','LP1_records_reduced.json')));
P=jsondecode(fileread(fullfile(repo,'matlab','g2','G2_LP1_POLICY_v2.json')));
g=P.geometry;b=P.bvp;cs={'stiff13','soft2','soft1'};nm={'жорсткі кільця \{1,3\}','м’яке кільце \{2\}','м’яке кільце \{1\}'};
mk={'^','o','d'};ls={'--','-.',':'};
st=A.ownPathStates;if iscell(st),st=[st{:}];end
pick=@(c,f)arrayfun(@(k)st(strcmp({st.case},c)&[st.state]==k).(f),0:4);
s=pick('H','arc_mm');
% ---------------- M5-1
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 13]);
tl=tiledlayout(f,2,1,'TileSpacing','compact','Padding','compact');ax=nexttile(tl,[1 1]);hold(ax,'on');
rectangle(ax,'Position',[0 0 g.plate_mm(1) g.plate_mm(2)],'EdgeColor','k','LineWidth',1);
th=linspace(0,2*pi,200);
for i=1:3
 c=g.centres_mm(i,:);
 fill(ax,c(1)+g.ringR_mm*cos(th),c(2)+g.ringR_mm*sin(th),[.85 .85 .85],'EdgeColor','k','LineWidth',.6);
 fill(ax,c(1)+g.holeR_mm*cos(th),c(2)+g.holeR_mm*sin(th),'w','EdgeColor','k','LineWidth',.6);
 if i==1,text(ax,c(1)+g.ringR_mm+3,c(2),'кільце 1','FontSize',8);
 else,text(ax,c(1)-g.ringR_mm-3,c(2),sprintf('кільце %d',i),'FontSize',8,'HorizontalAlignment','right');end
end
plot(ax,[b.pin_mm(1) b.load_mm(1)],[b.pin_mm(2) b.load_mm(2)],'k--','LineWidth',.8);
text(ax,290,150,{'геометрична пряма «опора – сила»','(перетинає отвір 2; не траєкторія','головних напружень)'},'FontSize',8);
plot(ax,b.pin_mm(1),b.pin_mm(2),'k^','MarkerFaceColor','k','MarkerSize',6);plot(ax,b.roller_mm(1),b.roller_mm(2),'k^','MarkerSize',6);
quiver(ax,b.load_mm(1),b.load_mm(2)+22,0,-18,0,'k','LineWidth',1.2,'MaxHeadSize',2);text(ax,b.load_mm(1)+4,b.load_mm(2)+14,'P','FontSize',9);
k4=find(strcmp({st.case},'H')&[st.state]==4);
% polyline of H at S4 from the reduced records
fn=fieldnames(L.states);
for j=1:numel(fn)
 S=L.states.(fn{j}).STATE;
 if strcmp(S.caseId,'H')&&S.stateIndex==4,pl=S.polyline_mm;end
end
plot(ax,pl(:,1),pl(:,2),'k-','LineWidth',2);
axis(ax,'equal');xlim(ax,[-5 513]);ylim(ax,[-12 232]);box(ax,'off');xlabel(ax,'x, мм');ylabel(ax,'y, мм');
title(ax,'(a)','FontWeight','normal');dec(ax);
ax=nexttile(tl);hold(ax,'on');
for c=1:3
 d=A.lateralOffset_d_mm.(cs{c});plot(ax,s,d,['k',ls{c},mk{c}],'MarkerFaceColor','w','LineWidth',1,'DisplayName',nm{c});
end
yline(ax,0,'k-','HandleVisibility','off');grid(ax,'on');box(ax,'on');xlim(ax,[24 43]);ax.XTick=25.4:4:41.4;
xlabel(ax,'довжина тріщини s, мм');ylabel(ax,'зміщення вершини d, мм');legend(ax,'Location','northwest','FontSize',7);
text(ax,33.8,0.355,{'d > 0 — від колони кілець','d < 0 — до колони кілець'},'FontSize',7,'HorizontalAlignment','left');
title(ax,'(b)','FontWeight','normal');dec(ax);
save2(f,outDir,'M5_1_geometriia_UA');
% ---------------- M5-2
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 15 9]);ax=axes(f);hold(ax,'on');
for c=1:3
 x=A.decompositionExisting.(cs{c});
 plot(ax,s,100*x.trend_F_G_S0toS4,['k',ls{c},mk{c}],'MarkerFaceColor','w','LineWidth',1.1,'DisplayName',[nm{c} ': власна траєкторія']);
 plot(ax,[25.4 33.4],100*[x.S0_direct_equals_total.F_G x.S2_direct_M4B.F_G],['k',mk{c}],'MarkerFaceColor','k','MarkerSize',7, ...
  'LineStyle','none','DisplayName',[nm{c} ': однорідна геометрія']);
end
xline(ax,41.4,'k:','HandleVisibility','off');text(ax,40.9,-8.3,'S4: прямий ефект не обчислено','HorizontalAlignment','right','FontSize',7);
yline(ax,0,'k-','HandleVisibility','off');grid(ax,'on');box(ax,'on');xlim(ax,[24 43]);ylim(ax,[-9 9]);ax.XTick=25.4:4:41.4;
xlabel(ax,'довжина тріщини s, мм');ylabel(ax,'F_G = G/G_H - 1, %');legend(ax,'Location','eastoutside','FontSize',7);dec(ax);
save2(f,outDir,'M5_2_FG_priamyi_i_povnyi_UA');
% ---------------- M5-3
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 15 8]);ax=axes(f);hold(ax,'on');
for c=1:3
 v=A.irwinKies.(cs{c}).deltaC_rel_S0toS4;plot(ax,s,100*v,['k',ls{c},mk{c}],'MarkerFaceColor','w','LineWidth',1.1,'DisplayName',nm{c});
end
yline(ax,0,'k-','HandleVisibility','off');grid(ax,'on');box(ax,'on');xlim(ax,[24 43]);ax.XTick=25.4:4:41.4;
xlabel(ax,'довжина тріщини s, мм');ylabel(ax,'(C - C_H)/C_H, %');legend(ax,'Location','eastoutside','FontSize',7);dec(ax);
save2(f,outDir,'M5_3_podatlyvist_UA');
end
function dec(ax)
if strcmp(ax.XScale,'linear'),xt=round(ax.XTick,10);ax.XTick=xt;else,xt=ax.XTick;end
if strcmp(ax.YScale,'linear'),yt=round(ax.YTick,10);ax.YTick=yt;else,yt=ax.YTick;end
ax.XTickLabel=strrep(compose('%g',xt),'.',',');ax.YTickLabel=strrep(compose('%g',yt),'.',',');
end
function save2(f,outDir,name)
exportgraphics(f,fullfile(outDir,[name '.png']),'Resolution',300);
exportgraphics(f,fullfile(outDir,[name '.pdf']),'ContentType','vector');close(f);
end
