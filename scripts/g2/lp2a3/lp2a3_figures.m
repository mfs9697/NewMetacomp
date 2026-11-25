function lp2a3_figures(s9DryJson,outDir)
%LP2A3_FIGURES  Ukrainian figure of the LP2-A3 readiness memorandum (geometry only; no FEM, no records).
% LP2A3-1: accepted S0-S8 path and the actual S9 candidate of each case near ring 1, with the 15-mm
% tip guide at the S9 tip, ring and hole circles, and the 1-mm guard boundary
% (||tip - c_1|| = R_ring + 15 + 1 mm: a candidate tip must stay outside it).
assert(~isfolder(outDir),'LP2A3Fig:Out','Output folder exists.');mkdir(outDir);
set(groot,'defaultAxesFontName','Arial','defaultTextFontName','Arial','defaultAxesFontSize',8);
D=jsondecode(fileread(s9DryJson));cs=D.cases;if ~iscell(cs),cs=num2cell(cs);end
cen=[152.4 69.85;152.4 120.65;152.4 171.45];Rr=19.05;Rh=6.35;Rg=15;th=linspace(0,2*pi,361);
col=[0.00 0.45 0.70;0.84 0.37 0.00;0.00 0.62 0.45;0.80 0.47 0.65];act=[0 0 0;1 0 1;0 1 0;1 0 0];
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 15]);tl=tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');
for k=1:4
 O=cs{k};P=O.S9.polyline_mm;tip=P(end,:);ax=nexttile(tl);hold(ax,'on');axis(ax,'equal');
 for i=1:3
  if act(k,i),ls='-';cr=[.25 .25 .25];else,ls='--';cr=[.55 .55 .55];end
  plot(ax,cen(i,1)+Rr*cos(th),cen(i,2)+Rr*sin(th),ls,'Color',cr,'LineWidth',1);
  fill(ax,cen(i,1)+Rh*cos(th),cen(i,2)+Rh*sin(th),[.85 .85 .85],'EdgeColor',[.5 .5 .5]);
 end
 plot(ax,cen(1,1)+(Rr+Rg+1)*cos(th),cen(1,2)+(Rr+Rg+1)*sin(th),':','Color',[.75 .1 .1],'LineWidth',1);
 plot(ax,tip(1)+Rg*cos(th),tip(2)+Rg*sin(th),'-','Color',[col(k,:) .5],'LineWidth',.8);
 plot(ax,P(1:end-1,1),P(1:end-1,2),'-','Color',[.1 .1 .1],'LineWidth',1.2);
 plot(ax,P(end-1:end,1),P(end-1:end,2),'-','Color',col(k,:),'LineWidth',2);
 plot(ax,tip(1),tip(2),'o','Color',col(k,:),'MarkerFaceColor',col(k,:),'MarkerSize',4);
 xlim(ax,[95 175]);ylim(ax,[0 75]);box(ax,'off');grid(ax,'on');
 title(ax,strrep(sprintf('%s (маска %d%d%d): проміжок до кільця 1 = %.3f мм',O.caseId,act(k,:),O.S9.guard.gap_mm(1)),'.',','),'FontWeight','normal','FontSize',8);
 if k>2,xlabel(ax,'x, мм');end;if mod(k,2)==1,ylabel(ax,'y, мм');end
end
title(tl,{'Рис. LP2A3-1. Справжні кандидати S9 біля кільця 1 (лише геометрія)', ...
 'чорне: прийнятий шлях S0–S8; кольорове: крок S9 і напрямне коло 15 мм', ...
 'червоний пунктир: межа запобіжника 1 мм для кільця 1; суцільне / штрихове кільце: активне / пасивне'},'FontSize',8);
exportgraphics(f,fullfile(outDir,'LP2A3_1_S9_kandydaty.png'),'Resolution',300);exportgraphics(f,fullfile(outDir,'LP2A3_1_S9_kandydaty.pdf'),'ContentType','vector');close(f);
fprintf('LP2A3FIG done\n');
end
