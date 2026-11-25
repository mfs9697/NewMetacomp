function lp2a3_campaign_figures(analysisJson,outDir)
%LP2A3_CAMPAIGN_FIGURES  Ukrainian figures of the LP2-A3 demonstration from LP2A3_ANALYSIS.json (read-only).
%  LP2A3-2 trajectories S0-S11 (actual prefixes) with rings, terminal candidates
%  LP2A3-3 absolute G and relative F_G = G_X/G_H - 1 at common accepted arclengths
%  LP2A3-4 local MTS angle, global heading, signed normal offset relative to H
%  LP2A3-5 guide-to-ring-1 gap with the 1-mm guard and the terminal classifications
assert(~isfolder(outDir),'LP2A3CF:Out','Output folder exists.');mkdir(outDir);
set(groot,'defaultAxesFontName','Arial','defaultTextFontName','Arial','defaultAxesFontSize',8);
A=jsondecode(fileread(analysisJson));ids={'H','stiff13','soft2','soft1'};mk={'o','s','d','^'};
col=[0.00 0.45 0.70;0.84 0.37 0.00;0.00 0.62 0.45;0.80 0.47 0.65];cen=[152.4 69.85;152.4 120.65;152.4 171.45];th=linspace(0,2*pi,361);
P=struct();for k=1:4,r=A.paths.(ids{k});if ~iscell(r),r=num2cell(r);end,P.(ids{k})=r;end
g=@(id,f)cellfun(@(r)r.(f),P.(id));tipm=@(id)cell2mat(cellfun(@(r)reshape(r.tip_mm,1,2),P.(id),'UniformOutput',false));
lab=@(id)sprintf('%s (до S%d)',id,P.(id){end}.state);
% ---- LP2A3-2 trajectories
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 11]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
for z=1:2
 ax=nexttile(tl);hold(ax,'on');axis(ax,'equal');
 for i=1:3,plot(ax,cen(i,1)+19.05*cos(th),cen(i,2)+19.05*sin(th),'-','Color',[.45 .45 .45]);fill(ax,cen(i,1)+6.35*cos(th),cen(i,2)+6.35*sin(th),[.88 .88 .88],'EdgeColor',[.6 .6 .6]);end
 plot(ax,cen(1,1)+35.05*cos(th),cen(1,2)+35.05*sin(th),':','Color',[.75 .1 .1]);h=gobjects(1,4);
 for k=1:4
  id=ids{k};T=tipm(id);T=[101.6 0;T]; %#ok<AGROW>
  h(k)=plot(ax,T(:,1),T(:,2),'-','Color',col(k,:),'LineWidth',1.2);s=g(id,'state');a3=s>=9;Tt=tipm(id);
  plot(ax,Tt(a3,1),Tt(a3,2),mk{k},'Color',col(k,:),'MarkerFaceColor',col(k,:),'MarkerSize',3.5);
  t=A.terminals.(id);if ~isempty(t.candidateTip_mm),c=reshape(t.candidateTip_mm,1,2);plot(ax,[Tt(end,1) c(1)],[Tt(end,2) c(2)],':','Color',col(k,:),'LineWidth',1);plot(ax,c(1),c(2),'x','Color',col(k,:),'MarkerSize',6);end
 end
 if z==1,xlim(ax,[90 180]);ylim(ax,[0 95]);title(ax,'а) S0–S11 (кружки/маркери: S9–S11)','FontWeight','normal');legend(ax,h,cellfun(lab,ids,'UniformOutput',false),'Location','southeast','Box','off');
 else,xlim(ax,[110 122]);ylim(ax,[56 72]);title(ax,'б) збільшено: S8–S11 і кандидати (×)','FontWeight','normal');end
 xlabel(ax,'x, мм');ylabel(ax,'y, мм');grid(ax,'on');box(ax,'off');
end
title(tl,{'Рис. LP2A3-2. Прийняті траєкторії (фактичні префікси) і термінальні кандидати','× пунктиром: кандидат S12 (лише інформаційний) або невдалий S10 soft1','червоний пунктир: межа запобіжника 1 мм для кільця 1'},'FontSize',8);
save2(f,fullfile(outDir,'LP2A3_2_traiektorii'));
% ---- LP2A3-3 G and F_G
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 8]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl);hold(ax,'on');for k=1:4,plot(ax,g(ids{k},'s_mm'),g(ids{k},'G')*1e8,['-' mk{k}],'Color',col(k,:),'MarkerFaceColor',col(k,:),'MarkerSize',3);end
xline(ax,57.4,':','S8','Color',[.4 .4 .4],'HandleVisibility','off');xlabel(ax,'s, мм');ylabel(ax,'G, ×10^{-8} Н/мм (P = 1 Н)');title(ax,'а) абсолютне G','FontWeight','normal');grid(ax,'on');box(ax,'off');legend(ax,ids,'Location','northwest','Box','off');
ax=nexttile(tl);hold(ax,'on');yline(ax,0,'-','Color',[.6 .6 .6],'HandleVisibility','off');
for k=2:4,c=A.contrastsVsH.(ids{k});if ~iscell(c),c=num2cell(c);end,plot(ax,cellfun(@(x)x.s_mm,c),cellfun(@(x)x.F_G,c),['-' mk{k}],'Color',col(k,:),'MarkerFaceColor',col(k,:),'MarkerSize',3);end
xline(ax,57.4,':','S8','Color',[.4 .4 .4],'HandleVisibility','off');xlabel(ax,'s, мм');ylabel(ax,'F_G = G_X/G_H − 1');title(ax,'б) відносний контраст (лише спільні s)','FontWeight','normal');grid(ax,'on');box(ax,'off');legend(ax,ids(2:4),'Location','west','Box','off');
title(tl,'Рис. LP2A3-3. Рушійна сила G і архітектурний контраст F_G, S0–S11','FontSize',8);save2(f,fullfile(outDir,'LP2A3_3_G_FG'));
% ---- LP2A3-4 angles and offsets
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 13]);tl=tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl);hold(ax,'on');for k=1:4,s=g(ids{k},'s_mm');m=s>26;v=g(ids{k},'MTS_deg');plot(ax,s(m),v(m),['-' mk{k}],'Color',col(k,:),'MarkerFaceColor',col(k,:),'MarkerSize',3);end
ylabel(ax,'θ_{MTS}, °');title(ax,'а) локальний кут MTS (S1–S11; S0 ≈ −11…−13° поза шкалою)','FontWeight','normal');grid(ax,'on');box(ax,'off');legend(ax,ids,'Location','southeast','Box','off');
ax=nexttile(tl);hold(ax,'on');for k=1:4,s=g(ids{k},'s_mm');m=s>25.4+1e-9;hd=g(ids{k},'heading_deg');plot(ax,s(m),hd(m),['-' mk{k}],'Color',col(k,:),'MarkerFaceColor',col(k,:),'MarkerSize',3);end
ylabel(ax,'курс останнього сегмента, °');title(ax,'б) глобальний курс','FontWeight','normal');grid(ax,'on');box(ax,'off');
ax=nexttile(tl);hold(ax,'on');yline(ax,0,'-','Color',[.6 .6 .6],'HandleVisibility','off');
for k=2:4,c=A.contrastsVsH.(ids{k});if ~iscell(c),c=num2cell(c);end,plot(ax,cellfun(@(x)x.s_mm,c),cellfun(@(x)x.normalOffset_mm,c),['-' mk{k}],'Color',col(k,:),'MarkerFaceColor',col(k,:),'MarkerSize',3);end
xlabel(ax,'s, мм');ylabel(ax,'зміщення по нормалі H, мм');title(ax,'в) знакове бічне зміщення відносно H','FontWeight','normal');grid(ax,'on');box(ax,'off');legend(ax,ids(2:4),'Location','northwest','Box','off');
ax=nexttile(tl);hold(ax,'on');yline(ax,0,'-','Color',[.6 .6 .6],'HandleVisibility','off');
for k=2:4,c=A.contrastsVsH.(ids{k});if ~iscell(c),c=num2cell(c);end,plot(ax,cellfun(@(x)x.s_mm,c),cellfun(@(x)x.dHeading_deg,c),['-' mk{k}],'Color',col(k,:),'MarkerFaceColor',col(k,:),'MarkerSize',3);end
xlabel(ax,'s, мм');ylabel(ax,'курс_X − курс_H, °');title(ax,'г) різниця курсу відносно H','FontWeight','normal');grid(ax,'on');box(ax,'off');
title(tl,'Рис. LP2A3-4. Локальні кути, глобальний курс і накопичене бічне зміщення','FontSize',8);save2(f,fullfile(outDir,'LP2A3_4_kuty'));
% ---- LP2A3-5 ring 1 proximity
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 9]);ax=axes(f);hold(ax,'on');
yline(ax,1,'--','Color',[.75 .1 .1],'HandleVisibility','off');yline(ax,0,'-','Color',[.6 .6 .6],'HandleVisibility','off');
text(ax,41,1.35,'запобіжник 1 мм','Color',[.75 .1 .1],'FontSize',7);h=gobjects(1,4);
names=struct('PASSIVE_CONTOUR_APPROACH','пасивне кільце','INTERFACE_APPROACH','активне кільце','MATRIX_ADVANCE','MATRIX\_ADVANCE');
dy=[0.9 0 -0.75 0];
for k=1:4
 id=ids{k};s=g(id,'s_mm');gp=cellfun(@(r)r.guideRingGap_mm(1),P.(id));m=s>40;
 h(k)=plot(ax,s(m),gp(m),['-' mk{k}],'Color',col(k,:),'MarkerFaceColor',col(k,:),'MarkerSize',3.5);
 t=A.terminals.(id);
 if isfield(t,'candidateGuideRingGap_mm')&&~isempty(t.candidateGuideRingGap_mm)
  sc=s(end)+4;gc=t.candidateGuideRingGap_mm(1);plot(ax,[s(end) sc],[gp(end) gc],':','Color',col(k,:),'HandleVisibility','off');plot(ax,sc,gc,'x','Color',col(k,:),'MarkerSize',7,'HandleVisibility','off');
  if strcmp(t.classification,'NUMERICAL_HOLD'),lb=sprintf('%s S10: збій сітки (щабель 1), проміжок %.2f мм',id,gc);
  else,lb=sprintf('%s S12 (інф.): %s, %.2f мм',id,names.(t.candidateClassification),gc);end
  text(ax,sc+0.4,gc+dy(k),regexprep(lb,'(\d)\.(\d)','$1,$2'),'FontSize',6.5,'Color',col(k,:));
 end
end
xlabel(ax,'s, мм');ylabel(ax,{'проміжок «напрямне коло 15 мм —','кільце 1», мм'});grid(ax,'on');box(ax,'off');
legend(ax,h,cellfun(@(id)sprintf('%s: %s',id,strrep(A.terminals.(id).classification,'_','\_')),ids,'UniformOutput',false),'Location','northeast','Box','off');
xlim(ax,[40 92]);ylim(ax,[-2.2 22]);
title(ax,{'Рис. LP2A3-5. Наближення до кільця 1 і термінальні класифікації','× — кандидат після останнього прийнятого стану (не прийнятий, без сітки й розв’язку для S12)'},'FontWeight','normal','FontSize',8);
save2(f,fullfile(outDir,'LP2A3_5_kiltse1'));fprintf('LP2A3CF done\n');
end
function save2(f,b),exportgraphics(f,[b '.png'],'Resolution',300);exportgraphics(f,[b '.pdf'],'ContentType','vector');close(f);end
