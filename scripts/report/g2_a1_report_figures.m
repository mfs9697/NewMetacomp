function F=g2_a1_report_figures(meshRoot,baselineFile,outDir,stateRoot)
%G2_A1_REPORT_FIGURES  Ukrainian greyscale figures for the A1 Word supplement (Issue #66).
%
%  F = g2_a1_report_figures(meshRoot,baselineFile,outDir)              % geometry-only figures
%  F = g2_a1_report_figures(meshRoot,baselineFile,outDir,stateRoot)    % + SIF/energy figures
% Without stateRoot only REAL geometry figures are drawn (no numbers are invented):
%  F1 fixed-scale crack-tip mesh close-ups, H path, m = 0, 3, 6, 9 (same axes);
%  F2 preservation overlay: baseline vs B9 edges in 2.6-4.2 mm about the tip;
%  F3 cost: measured T3/DOF of the Family B levels vs measured first edge, with a clearly
%     labelled PROJECTION of uniform global refinement (N0*(h0/h)^2), not a computation.
% With stateRoot (after a GO_A1 campaign) the sensitivity figures are drawn from the
% saved A1 STATE records only: signed K_I, K_II, MTS and F_G versus first edge.
% Plain LOAD of saved meshes/records; no FEM.
assert(~isfolder(outDir),'G2A1Fig:Out','Output folder exists.');mkdir(outDir);
set(groot,'defaultAxesFontName','Arial','defaultTextFontName','Arial','defaultAxesFontSize',9);
D0=load(baselineFile);tip=D0.crackPolyline(end,:);t=D0.tipTangent(:).';n=[-t(2),t(1)];
lv=[0 3 6 9];Ms=cell(1,4);Ms{1}=D0;
for k=2:4,Ms{k}=load(fullfile(meshRoot,'H',sprintf('B%d',lv(k)),'MESH.mat'));end
loc=@(X)[(X-tip)*t(:),(X-tip)*n(:)];
% ---- F1 close-ups at one fixed scale
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 15]);
tl=tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');
W=0.6;h1=zeros(1,4);
for k=1:4
 ax=nexttile(tl);M=Ms{k};X=loc(M.X3);T=M.T3;
 c=(X(T(:,1),:)+X(T(:,2),:)+X(T(:,3),:))/3;keep=all(abs(c)<W*1.05,2);
 triplot(T(keep,:),X(:,1),X(:,2),'Color',[.15 .15 .15],'LineWidth',.35);hold(ax,'on');
 plot(ax,[-W 0],[0 0],'k-','LineWidth',1.6);plot(ax,0,0,'ko','MarkerFaceColor','w','MarkerSize',4);
 axis(ax,'equal');xlim(ax,[-W W]);ylim(ax,[-W W]);box(ax,'on');ax.XTick=-W:.2:W;ax.YTick=-W:.2:W;
 fan=find(any(M.T3==M.physicalTipNode,2));E=unique(sort([M.T3(fan,[1 2]);M.T3(fan,[2 3]);M.T3(fan,[3 1])],2),'rows');
 e=E(any(E==M.physicalTipNode,2),:);h1(k)=min(vecnorm(M.X3(e(:,1),:)-M.X3(e(:,2),:),2,2));
 title(ax,sprintf('m = %d:  h_1 = %s мм,  T3 = %s',lv(k),strrep(sprintf('%.5f',h1(k)),'.',','),thou(size(M.T3,1))),'FontWeight','normal');
 xlabel(ax,'x_t, мм (уздовж дотичної)');ylabel(ax,'x_n, мм (по нормалі)');dec(ax);
end
title(tl,'Сітка біля вершини тріщини (шлях H, S4), однаковий масштаб ±0,6 мм','FontSize',10);
F.f1=save2(f,outDir,'A1_F1_tip_mesh_levels_UA');
% ---- F2 preservation overlay
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 16 8]);
tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
for k=[1 4]
 ax=nexttile(tl);M=Ms{k};X=loc(M.X3);T=M.T3;c=(X(T(:,1),:)+X(T(:,2),:)+X(T(:,3),:))/3;rr=vecnorm(c,2,2);
 keep=rr>2.2&rr<4.4;triplot(T(keep,:),X(:,1),X(:,2),'Color',[.2 .2 .2],'LineWidth',.3);hold(ax,'on');
 th=linspace(0,2*pi,400);plot(ax,3*cos(th),3*sin(th),'k--','LineWidth',1);plot(ax,3.3*cos(th),3.3*sin(th),'k-','LineWidth',1.2);
 axis(ax,'equal');xlim(ax,[-4.4 4.4]);ylim(ax,[-4.4 4.4]);box(ax,'on');ax.XTick=-4:2:4;ax.YTick=-4:2:4;xlabel(ax,'x_t, мм');ylabel(ax,'x_n, мм');dec(ax);
 title(ax,sprintf('m = %d',lv(k)),'FontWeight','normal');
end
title(tl,'Межі ядра 3 мм (штрих) і коміра 3,3 мм (суцільна): зовнішня сітка без змін','FontSize',10);
F.f2=save2(f,outDir,'A1_F2_preservation_UA');
% ---- F3 measured cost vs projection
N=cellfun(@(M)size(M.T3,1),Ms);dof=cellfun(@(M)2*size(M.X6,1),Ms);
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 15 9]);ax=axes(f);
loglog(ax,h1,N,'ks-','LineWidth',1.4,'MarkerFaceColor','k');hold(ax,'on');
proj=N(1)*(h1(1)./h1).^2;loglog(ax,h1,proj,'k:','LineWidth',1.4,'Marker','o','MarkerFaceColor','w');
set(ax,'XDir','reverse');grid(ax,'on');xlabel(ax,'перше ребро біля вершини h_1, мм');ylabel(ax,'кількість елементів T3');
legend(ax,{'родина B, виміряно (побудовані сітки)','рівномірне подрібнення, оцінка N_0(h_0/h_1)^2'},'Location','northwest');
for k=1:4,text(ax,h1(k),N(k)/1.22,sprintf('%s СС',thou(dof(k))),'HorizontalAlignment','center','FontSize',8);end
ylim(ax,[1.5e4 1e6]);xlim(ax,[0.009 0.046]);
ax.XTick=[0.01 0.015 0.02 0.03 0.04];ax.XTickLabel=strrep(compose('%g',ax.XTick),'.',',');
ax.YTick=[3e4 1e5 3e5 1e6];ax.YTickLabel=arrayfun(@thou,ax.YTick,'UniformOutput',false);
F.f3=save2(f,outDir,'A1_F3_cost_UA');F.h1=h1;F.T3=N;F.DOF=dof;F.projectedUniformT3=proj;
% ---- sensitivity figures only from saved A1 STATE records
if nargin>=4&&~isempty(stateRoot)
 F.sensitivity=sensitivity(stateRoot,outDir,h1);
end
fid=fopen(fullfile(outDir,'FIGURES.json'),'w');fwrite(fid,jsonencode(F,'PrettyPrint',true),'char');fclose(fid);
end

function S=sensitivity(stateRoot,outDir,h1)
cases={'H','stiff13','soft2','soft1'};names={'H','жорсткі {1,3}','м’яке {2}','м’яке {1}'};mk={'s','^','o','d'};
for c=1:4
 for m=[3 6 9]
  St=load(fullfile(stateRoot,sprintf('%s_B%d',cases{c},m),'STATE.mat'));R.(sprintf('%s_B%d',cases{c},m))=St.record;
 end
end
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 12]);tl=tiledlayout(f,2,2,'TileSpacing','compact');
lab={'K_I, Н·мм^{-3/2} при 1 Н','K_{II}, Н·мм^{-3/2} при 1 Н','кут МКН, °','F_G = G/G_H - 1, %'};
for p=1:4
 ax=nexttile(tl);hold(ax,'on');
 for c=1:4
  v=arrayfun(@(m)val(R.(sprintf('%s_B%d',cases{c},m)),R.(sprintf('H_B%d',m)),p),[3 6 9]);
  plot(ax,h1(2:4),v,['k-',mk{c}],'MarkerFaceColor','w','DisplayName',names{c});
 end
 set(ax,'XDir','reverse','XScale','log');grid(ax,'on');xlabel(ax,'h_1, мм');ylabel(ax,lab{p});dec(ax);
 if p==1,legend(ax,'Location','best');end
end
S=save2(f,outDir,'A1_F4_sensitivity_UA');
end
function v=val(r,rH,p)
switch p
 case 1,v=r.KI;case 2,v=r.KII;case 3,v=r.MTS_deg;case 4,v=100*(r.G/rH.G-1);
end
end
function dec(ax)
% decimal-comma tick labels; ticks rounded so floating-point noise never reaches a label
if strcmp(ax.XScale,'linear'),xt=round(ax.XTick,10);ax.XTick=xt;else,xt=ax.XTick;end
if strcmp(ax.YScale,'linear'),yt=round(ax.YTick,10);ax.YTick=yt;else,yt=ax.YTick;end
ax.XTickLabel=strrep(compose('%g',xt),'.',',');ax.YTickLabel=strrep(compose('%g',yt),'.',',');
end
function s=thou(v)
% integer with a thin-space thousands separator (Ukrainian convention)
d=sprintf('%d',round(v));k=mod(numel(d),3);parts={};if k>0,parts{end+1}=d(1:k);end
for i=k+1:3:numel(d),parts{end+1}=d(i:i+2);end %#ok<AGROW>
s=strjoin(parts,char(8201));
end
function s=save2(f,outDir,name)
png=fullfile(outDir,[name '.png']);exportgraphics(f,png,'Resolution',300);
pdf=fullfile(outDir,[name '.pdf']);exportgraphics(f,pdf,'ContentType','vector');close(f);s=struct('png',png,'pdf',pdf);
end
