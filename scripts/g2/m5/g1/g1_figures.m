function g1_figures(dataDir,outDir)
%G1_FIGURES  Ukrainian figures for the G1 field study from G1_FIGDATA.mat / G1_FIELD_EVIDENCE.json.
% Every field shown is RECONSTRUCTED from saved displacements (no solve); element-constant colouring,
% no interpolation across voids, cracks or interfaces; holes are voids (no element).
assert(~isfolder(outDir),'G1Fig:Out','Output folder exists.');mkdir(outDir);
set(groot,'defaultAxesFontName','Arial','defaultTextFontName','Arial','defaultAxesFontSize',8);
F=load(fullfile(dataDir,'G1_FIGDATA.mat'));R=jsondecode(fileread(fullfile(dataDir,'G1_FIELD_EVIDENCE.json')));
M=F.M4B;L=F.line;cen=F.cen;th=linspace(0,2*pi,200);
src='Джерело: M4.B CASE\_none (однорідне тіло, S2, сітка 9269be43…); поле відновлене зі збережених переміщень';
% ------------------------------------------------------------------ G1-1 directions and trajectories
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 10.5]);ax=axes(f);hold(ax,'on');
base(ax,M,L,cen,th,true);
g=M.glyph;ok=~isnan(g.th2);cd=ok&g.s2<0&abs(g.s2)>abs(g.s1);td=ok&~cd;h=3;
sels={cd,td};cols={[0 0 0],[.6 .6 .6]};lw=[.9 .6];
for j=1:2
 s=sels{j};x=g.P(s,1);y=g.P(s,2);dx=h*cos(g.th2(s));dy=h*sin(g.th2(s));
 X=[x-dx x+dx nan(size(x))].';Y=[y-dy y+dy nan(size(y))].';c=cols{j};w=lw(j);
 plot(ax,X(:),Y(:),'-','Color',c,'LineWidth',w,'HandleVisibility','off');
end
for k=1:numel(M.traj),p=M.traj{k};plot(ax,p(:,1),p(:,2),'-','Color',[.1 .3 .75],'LineWidth',1.3,'HandleVisibility','off');end
plot(ax,nan,nan,'k-','LineWidth',.9,'DisplayName','вісь стиску \sigma_2 (переважає стиск)');
plot(ax,nan,nan,'-','Color',[.6 .6 .6],'LineWidth',.6,'DisplayName','вісь стиску \sigma_2 (переважає розтяг)');
plot(ax,nan,nan,'-','Color',[.1 .3 .75],'LineWidth',1.3,'DisplayName','траєкторії \sigma_2 від прямої (\xi = 70, 150, 230 мм)');
plot(ax,nan,nan,'k--','LineWidth',1,'DisplayName','геометрична пряма «опора – сила»');
legend(ax,'Location','southoutside','NumColumns',2,'FontSize',7,'Box','off');
note(f,src);
save2(f,outDir,'G1_1_napriamy_stysku_UA');
% ------------------------------------------------------------------ G1-2 strain-energy density
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 8.2]);ax=axes(f);hold(ax,'on');
patch(ax,'Faces',M.T3,'Vertices',M.X3,'FaceVertexCData',log10(M.SED_H),'FaceColor','flat','EdgeColor','none');
colormap(ax,flipud(gray(256)));caxis(ax,pct(log10(M.SED_H),[2 99.5]));cb=colorbar(ax);
cb.Label.String='lg w  (w — густина енергії деформації, МПа; P = 1 Н)';
base(ax,M,L,cen,th,false);note(f,src);
save2(f,outDir,'G1_2_gustyna_energii_UA');
% ------------------------------------------------------------------ G1-3 change of w by one soft ring
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 7.4]);
tl=tiledlayout(f,1,3,'TileSpacing','compact','Padding','compact');ids={'c0p5_100','c0p5_010','c0p5_001'};
cm=divmap(256);lim=10;
for k=1:3
 ax=nexttile(tl);hold(ax,'on');d=100*M.(['dSEDrel_' ids{k}]);d(M.owner==k)=NaN;
 patch(ax,'Faces',M.T3,'Vertices',M.X3,'FaceVertexCData',max(-lim,min(lim,d)),'FaceColor','flat','EdgeColor','none');
 own=M.owner==k;patch(ax,'Faces',M.T3(own,:),'Vertices',M.X3,'FaceColor',[.75 .75 .75],'EdgeColor','none');
 colormap(ax,cm);caxis(ax,[-lim lim]);
 for i=1:3,plot(ax,cen(i,1)+19.05*cos(th),cen(i,2)+19.05*sin(th),'k-','LineWidth',.5);end
 plot(ax,[L.p0(1) L.p1(1)],[L.p0(2) L.p1(2)],'k--','LineWidth',.8);plot(ax,M.crack(:,1),M.crack(:,2),'k-','LineWidth',1.6);
 axis(ax,'equal');xlim(ax,[60 250]);ylim(ax,[0 203.2]);box(ax,'on');dec(ax);
 title(ax,sprintf('(%s) м’яке кільце %d (E_к = 0,5 E_м)',char(1072+k-1),k),'FontWeight','normal','FontSize',8);
 if k==1,ylabel(ax,'y, мм');end;xlabel(ax,'x, мм');
end
cb=colorbar(ax);cb.Layout.Tile='east';cb.Label.String='(w_X - w_H)/w_H, %  (обмежено ±10 %)';
annotation(f,'textbox',[0 0 1 .06],'String','Джерело: M4.B, ті самі сітка й траєкторія S2; сірим — активоване кільце; поле відновлене зі збережених переміщень', ...
 'FontSize',6,'Color',[.3 .3 .3],'EdgeColor','none','HorizontalAlignment','left','VerticalAlignment','bottom');
save2(f,outDir,'G1_3_pererozpodil_energii_UA');
% ------------------------------------------------------------------ G1-4 first-order influence map
I=F.influence;f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 8.4]);ax=axes(f);hold(ax,'on');
v=1e4*I.iota;lim=1;
im=imagesc(ax,I.cx(1,:),I.cy(:,1),max(-lim,min(lim,v)));im.AlphaData=~isnan(v);set(ax,'YDir','normal');
colormap(ax,divmap(256));caxis(ax,[-lim lim]);cb=colorbar(ax);
cb.Label.String='\iota = (\partialw/\partiala) / (dU/da),  10^{-4} мм^{-2}  (обмежено ±1)';
for i=1:3,plot(ax,cen(i,1)+19.05*cos(th),cen(i,2)+19.05*sin(th),'k-','LineWidth',.7);fill(ax,cen(i,1)+6.35*cos(th),cen(i,2)+6.35*sin(th),'w','EdgeColor','k');end
plot(ax,[L.p0(1) L.p1(1)],[L.p0(2) L.p1(2)],'k--','LineWidth',1);plot(ax,I.crackS3(:,1),I.crackS3(:,2),'k-','LineWidth',1.6);
rectangle(ax,'Position',[0 0 508 203.2],'EdgeColor','k');axis(ax,'equal');xlim(ax,[-5 513]);ylim(ax,[-5 208]);
xlabel(ax,'x, мм');ylabel(ax,'y, мм');dec(ax);
text(ax,300,165,{'\iota < 0: податливіший матеріал тут зменшує G','\iota > 0: податливіший матеріал тут збільшує G','(перше наближення за контрастом)'},'FontSize',7);
note(f,['Джерело: LP1 H S1 і S3 (центральна різниця при S2), точкове відновлення зі збережених переміщень; ' ...
 'комірки 4 × 4 мм; маски: тріщина ±6 мм, 10 мм біля сили та опор']);
save2(f,outDir,'G1_4_karta_vplyvu_UA');
% ------------------------------------------------------------------ G1-5 ring energies and first-order test
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 10.2]);
tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');ax=nexttile(tl);hold(ax,'on');
hp=F.homPath;s=hp.arc_mm(:);Ur=hp.U_ring;mk={'s','o','d'};ls={'-','--',':'};
for k=1:3,plot(ax,s,100*(Ur(:,k)/Ur(1,k)-1),['k' ls{k} mk{k}],'MarkerFaceColor','w','LineWidth',1,'DisplayName',sprintf('U кільця %d',k));end
plot(ax,s,100*(hp.U_total(:)/hp.U_total(1)-1),'-','Color',[.5 .5 .5],'LineWidth',1.6,'DisplayName','U повна');
yline(ax,0,'k-','HandleVisibility','off');grid(ax,'on');box(ax,'on');xlim(ax,[24 43]);ax.XTick=25.4:4:41.4;
xlabel(ax,'довжина тріщини s, мм');ylabel(ax,'зміна енергії відносно S0, %');legend(ax,'Location','southwest','FontSize',7);
title(ax,'(а) однорідне тіло на власній траєкторії (LP1 H)','FontWeight','normal','FontSize',8);dec(ax);
ax=nexttile(tl);hold(ax,'on');
sr=R.firstOrderSingleRing;sr=sr(strcmp({sr.family},'M4B'));fa=R.firstOrderArchitecture;
x1=100*[sr.firstOrder];y1=100*[sr.observed_F_G];soft=[sr.contrast]<1;
plot(ax,x1(soft),y1(soft),'ko','MarkerFaceColor','w','MarkerSize',6,'DisplayName','одне кільце, E_к = 0,5 E_м (M4.B, S2)');
plot(ax,x1(~soft),y1(~soft),'ks','MarkerFaceColor','k','MarkerSize',5,'DisplayName','одне кільце, E_к = 2 E_м (M4.B, S2)');
pk={'^','v','d'};an={'stiff13','soft2','soft1'};nm={'жорсткі \{1,3\}','м’яке \{2\}','м’яке \{1\}'};
for a=1:3
 q=fa(strcmp({fa.architecture},an{a}));
 plot(ax,100*[q.firstOrder_dUda],100*[q.observed_F_G],['k' pk{a}],'MarkerFaceColor',[.6 .6 .6],'MarkerSize',5,'DisplayName',[nm{a} ': S0, S2, S4']);
end
lims=[-9 9];plot(ax,lims,lims,'k:','HandleVisibility','off');xline(ax,0,'k-','HandleVisibility','off');yline(ax,0,'k-','HandleVisibility','off');
xlim(ax,lims);ylim(ax,lims);axis(ax,'square');grid(ax,'on');box(ax,'on');
xlabel(ax,'перше наближення (1/\lambda - 1) \Sigma \DeltaU_k / \DeltaU, %');ylabel(ax,'спостережене F_G, %');
legend(ax,'Location','southoutside','FontSize',6,'Box','off');title(ax,'(б) перше наближення і розрахунок','FontWeight','normal','FontSize',8);dec(ax);
save2(f,outDir,'G1_5_energii_kilets_UA');
end

function base(ax,M,L,cen,th,showPlate)
if showPlate,rectangle(ax,'Position',[0 0 508 203.2],'EdgeColor','k','LineWidth',.8);end
for i=1:3
 plot(ax,cen(i,1)+19.05*cos(th),cen(i,2)+19.05*sin(th),'k-','LineWidth',.6,'HandleVisibility','off');
 fill(ax,cen(i,1)+6.35*cos(th),cen(i,2)+6.35*sin(th),'w','EdgeColor','k','LineWidth',.6,'HandleVisibility','off');
 text(ax,cen(i,1)-27,cen(i,2)+12,sprintf('%d',i),'FontSize',8,'FontWeight','bold','BackgroundColor','w','Margin',.5);
end
plot(ax,[L.p0(1) L.p1(1)],[L.p0(2) L.p1(2)],'k--','LineWidth',1,'HandleVisibility','off');
plot(ax,M.crack(:,1),M.crack(:,2),'k-','LineWidth',1.8,'HandleVisibility','off');
plot(ax,25.4,0,'k^','MarkerFaceColor','k','MarkerSize',6,'HandleVisibility','off');plot(ax,482.6,0,'k^','MarkerSize',6,'HandleVisibility','off');
quiver(ax,254,225,0,-18,0,'k','LineWidth',1.2,'MaxHeadSize',2,'HandleVisibility','off');text(ax,258,218,'P','FontSize',9);
axis(ax,'equal');xlim(ax,[-5 513]);ylim(ax,[-10 232]);xlabel(ax,'x, мм');ylabel(ax,'y, мм');dec(ax);
end
function note(f,s)
annotation(f,'textbox',[0 0 1 .05],'String',s,'FontSize',6,'Color',[.3 .3 .3],'EdgeColor','none', ...
 'HorizontalAlignment','left','VerticalAlignment','bottom','Interpreter','tex');
end
function q=pct(v,p)
v=sort(v(isfinite(v)));q=v(max(1,min(numel(v),round(p/100*numel(v)))));q=q(:).';
end
function c=divmap(n)
a=linspace(-1,1,n).';b=[.13 .35 .70];r=[.75 .22 .13];w=[.97 .97 .97];c=zeros(n,3);
for i=1:n,if a(i)<0,c(i,:)=w+(b-w)*(-a(i));else,c(i,:)=w+(r-w)*a(i);end,end
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
