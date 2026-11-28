% LP2-B1-S10: Ukrainian figures from the INDEPENDENT audit (LP2B1S10_AUDIT_v2.json) and the raw history polylines.
% Read-only on the repository; writes only to the scratch figures folder. No FEM.
rd='<scratch>\lp2b1s10run';
fo=fullfile(rd,'figures');if ~isfolder(fo),mkdir(fo);end
A=jsondecode(fileread(fullfile(rd,'verify','LP2B1S10_AUDIT_v2.json')));E=A.science.evolution;S10=A.science.S10;
IX=jsondecode(fileread(fullfile(rd,'verify','raw_hist_v2','RAW_INDEX.json')));
cases={'H','stiff13','soft2','soft1'};lab={'H (однорідна матриця)','stiff13 (кільця 1,3; E_к/E_м = 2)','soft2 (кільце 2; E_к/E_м = 0.5)','soft1 (кільце 1; E_к/E_м = 0.5)'};
col=[0 0 0;0 0.447 0.741;0.466 0.674 0.188;0.85 0.325 0.098];mk={'o','s','^','d'};
set(groot,'defaultAxesFontName','Arial','defaultTextFontName','Arial','defaultAxesFontSize',10);
col_s=@(c)arrayfun(@(r)r.s_mm,E.(c));
% ---------------------------------------------------------------- 1 relative contrast F_G
f=figure('Units','centimeters','Position',[2 2 16 10],'Color','w');hold on;grid on;box on
for k=2:4,c=cases{k};s=col_s(c);F=arrayfun(@(r)r.F_G,E.(c));plot(s,100*F,['-' mk{k}],'Color',col(k,:),'MarkerFaceColor','w','LineWidth',1.2,'DisplayName',lab{k});end
s=col_s('soft1');F=arrayfun(@(r)r.F_G,E.soft1);plot(s(end),100*F(end),'d','MarkerSize',9,'MarkerFaceColor',col(4,:),'Color',col(4,:),'DisplayName','soft1 S10 (новий розв’язок, 0.40 мм)');
yline(0,'k:','HandleVisibility','off');xlabel('Довжина тріщини s, мм');ylabel('F_G = (G - G_H)/G_H, %');
ylim([-15 23]);legend('Location','northwest');title('Відносний контраст швидкості вивільнення енергії відносно H');
text(s(end)-1,100*F(end)+1.2,sprintf('%+.3f %%',100*F(end)),'HorizontalAlignment','right','Color',col(4,:));
exportgraphics(f,fullfile(fo,'LP2B1S10_F_G_ua.pdf'),'ContentType','vector');exportgraphics(f,fullfile(fo,'LP2B1S10_F_G_ua.png'),'Resolution',200);close(f)
% ---------------------------------------------------------------- 2 lateral offset from H and mixity
f=figure('Units','centimeters','Position',[2 2 16 13],'Color','w');
subplot(2,1,1);hold on;grid on;box on
for k=2:4,c=cases{k};plot(col_s(c),arrayfun(@(r)r.lateralOffsetFromH_mm,E.(c)),['-' mk{k}],'Color',col(k,:),'MarkerFaceColor','w','LineWidth',1.2,'DisplayName',lab{k});end
yline(0,'k:','HandleVisibility','off');ylim([-0.75 0.6]);ylabel('Бічне зміщення від H, мм');legend('Location','southwest','FontSize',8);title('Зміщення вершини по нормалі до траєкторії H');
subplot(2,1,2);hold on;grid on;box on
for k=1:4,c=cases{k};plot(col_s(c),1e3*arrayfun(@(r)r.KIIoverKI,E.(c)),['-' mk{k}],'Color',col(k,:),'MarkerFaceColor','w','LineWidth',1.2,'DisplayName',lab{k});end
ylim([0 26]);xlabel('Довжина тріщини s, мм');ylabel('10^3 K_{II}/K_I');legend('Location','northeast','FontSize',8,'NumColumns',2);title('Змішаність мод (S0, s = 25.4 мм: 103–119, поза шкалою)');
exportgraphics(f,fullfile(fo,'LP2B1S10_offset_mixity_ua.pdf'),'ContentType','vector');exportgraphics(f,fullfile(fo,'LP2B1S10_offset_mixity_ua.png'),'Resolution',200);close(f)
% ---------------------------------------------------------------- 3 trajectories near ring 1, S11 forecast (information only)
f=figure('Units','centimeters','Position',[2 2 16 12],'Color','w');hold on;grid on;box on;axis equal
cen=[152.4 69.85];th=linspace(0,2*pi,400);
plot(cen(1)+19.05*cos(th),cen(2)+19.05*sin(th),'Color',[0.5 0.5 0.5],'LineWidth',1.0,'DisplayName','кільце 1 (R = 19.05 мм)');
plot(cen(1)+6.35*cos(th),cen(2)+6.35*sin(th),'Color',[0.5 0.5 0.5],'LineStyle','--','DisplayName','отвір 1 (R = 6.35 мм)');
for k=1:4,c=cases{k};P=rdf(rd,IX,sprintf('hist_%s_S10_poly',c));plot(P(:,1),P(:,2),['-' mk{k}],'Color',col(k,:),'MarkerFaceColor','w','MarkerSize',4,'LineWidth',1.1,'DisplayName',lab{k});end
P11=S10.soft1.tip_mm(:).';t11=A.detail.S11forecastInformationOnly.S11tip_mm(:).';
plot([P11(1) t11(1)],[P11(2) t11(2)],':','Color',col(4,:),'LineWidth',1.5,'DisplayName','soft1 S11: лише прогноз (без сітки й розв’язку)');
plot(t11(1),t11(2),'x','Color',col(4,:),'MarkerSize',9,'LineWidth',1.5,'HandleVisibility','off');
xlim([96 176]);ylim([38 94]);xlabel('x, мм');ylabel('y, мм');legend('Location','northwest','FontSize',8);
title('Траєкторії до s = 65.4 мм і прогноз S11 для soft1');
exportgraphics(f,fullfile(fo,'LP2B1S10_trajectories_ua.pdf'),'ContentType','vector');exportgraphics(f,fullfile(fo,'LP2B1S10_trajectories_ua.png'),'Resolution',200);close(f)
fprintf('FIGURES done %s\n',fo);
function P=rdf(rd,IX,name)
k=find(strcmp({IX.file},[name '.f64']));assert(numel(k)==1,name);fid=fopen(fullfile(rd,'verify','raw_hist_v2',IX(k).file),'r','l');x=fread(fid,inf,'float64');fclose(fid);
P=reshape(x,IX(k).shape(:).');
end
