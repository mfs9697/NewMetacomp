function lp2a2_figures(execRepo,testSetJson,qualJson,outDir)
%LP2A2_FIGURES  Ukrainian figures of the LP2-A2 memorandum (geometry only, zero FEM, no records).
% 1 original pairing failure (inherited mesher, S9 predictor soft2); 2 paired seeds before collapse
% (LP2-A2 mesher, same geometry); 3 mesh after collapse at a kink; 4 collar connection at the tip;
% 5 full meshes of the accepted H S8 and of the soft2 S9 predictor; 6 qualification overview.
assert(~isfolder(outDir),'LP2A2Fig:Out','Output folder exists.');mkdir(outDir);
here=fileparts(mfilename('fullpath'));g2=fullfile(execRepo,'matlab','g2');
addpath(g2,'-begin');addpath(fullfile(g2,'vendor_p010_a14d8872'),'-begin');addpath(fullfile(g2,'lp2a2'),'-begin');addpath(here,'-begin');
set(groot,'defaultAxesFontName','Arial','defaultTextFontName','Arial','defaultAxesFontSize',8);
TS=jsondecode(fileread(testSetJson));rows=TS.rows;if ~iscell(rows),rows=num2cell(rows);end
get=@(id)rows{cellfun(@(r)strcmp(r.id,id),rows)};
opts={'BottomVertices_mm',[25.4 482.6],'TopVertices_mm',254,'TipGuideRadius_mm',15,'TipGuideHface_mm',1.5};
cU=[.80 .15 .10];cL=[.10 .35 .80];cen=[152.4 69.85;152.4 120.65;152.4 171.45];th=linspace(0,2*pi,240);
r9=get('B_soft2_S9');P9=r9.polyline_mm;t9=reshape(r9.tangent,1,2);N9=size(P9,1);
% ------------------------------------------------------------------ 1 original failure
Eo=lp2a2_fig_old_exterior(P9,'ExpectedVertices',N9,'ExpectedTangent',t9,opts{:});
assert(strcmp(Eo.stage,'HOLD_LIP_STATIONS'),'LP2A2Fig:Repro','Original failure not reproduced (%s).',Eo.stage);
F=Eo.figure;bad=find(F.cntU~=F.cntL,1);
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 7.5]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl);b=bar(ax,1:numel(F.cntU),[F.cntU,F.cntL],'grouped');b(1).FaceColor=cU;b(2).FaceColor=cL;
set(ax,'YScale','log');xlabel(ax,'відрізок осьової лінії k');ylabel(ax,'внутрішні вузли на березі');
legend(ax,{'верхній берег','нижній берег'},'Location','northeast');title(ax,sprintf('(а) успадкований генератор: %s / %s',mat2str(F.cntU.'),mat2str(F.cntL.')),'FontWeight','normal','FontSize',7);box(ax,'on');
ax=nexttile(tl);hold(ax,'on');k=bad;in=@(s)s>=F.Sc(k)-1e-9&s<=F.Sc(k+1)+1e-9;
su=F.sU(in(F.sU));sl=F.sL(in(F.sL));
plot(ax,su-F.Sc(k),+1+0*su,'o','Color',cU,'MarkerFaceColor',cU,'MarkerSize',4);plot(ax,sl-F.Sc(k),-1+0*sl,'s','Color',cL,'MarkerFaceColor',cL,'MarkerSize',4);
for i=1:numel(sl),[~,j]=min(abs(su-sl(i)));plot(ax,[sl(i) su(j)]-F.Sc(k),[-1 1],'-','Color',[.6 .6 .6]);end
ylim(ax,[-2 2]);yticks(ax,[-1 1]);yticklabels(ax,{'нижній','верхній'});xlabel(ax,sprintf('станція вздовж відрізка %d, мм',k));
title(ax,sprintf('(б) відрізок %d: %d і %d внутрішніх вузлів — пари не існують',k,F.cntU(k),F.cntL(k)),'FontWeight','normal','FontSize',7);box(ax,'on');
save1(f,outDir,'LP2A2_1_vidmova_parovannia_UA');
% ------------------------------------------------------------------ 2 paired seeds (LP2-A2)
D9=g2_lp2a2_join(P9,'ExpectedVertices',N9,'ExpectedTangent',t9,'ExteriorOptions',opts,'MaxT3Elements',40000);assert(D9.pass,'LP2A2Fig:New','%s',D9.stage);
E=D9.exterior;sUL=E.seedStationsUL;fr=E.seedForced;seg=E.seedSegment;kf=E.summary.guideCrossingSegments(1);
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 7.5]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl);ms=E.summary.seedsPerSegment(:)-1;b=bar(ax,1:numel(ms),[ms,ms],'grouped');b(1).FaceColor=cU;b(2).FaceColor=cL;set(ax,'YScale','log');
xlabel(ax,'відрізок осьової лінії k');ylabel(ax,'внутрішні зерна на березі');legend(ax,{'верхній берег','нижній берег'},'Location','northeast');
title(ax,sprintf('(а) LP2-A2: m_k = ⌈L_k/0,45⌉, однаково на обох берегах (%d пар)',E.summary.seedCount),'FontWeight','normal','FontSize',7);box(ax,'on');
ax=nexttile(tl);hold(ax,'on');sel=seg==kf|[false;seg(1:end-1)==kf];s0=min(sUL(sel,1));
for i=find(sel)'
 c=[.6 .6 .6];if fr(i),c=[.9 .55 0];end
 plot(ax,sUL(i,[2 1])-s0,[-1 1],'-','Color',c,'LineWidth',.8+fr(i));
end
plot(ax,sUL(sel,1)-s0,+1+0*sUL(sel,1),'o','Color',cU,'MarkerFaceColor',cU,'MarkerSize',4);plot(ax,sUL(sel,2)-s0,-1+0*sUL(sel,2),'s','Color',cL,'MarkerFaceColor',cL,'MarkerSize',4);
ylim(ax,[-2 2]);yticks(ax,[-1 1]);yticklabels(ax,{'нижній','верхній'});xlabel(ax,sprintf('станція вздовж відрізка %d, мм',kf));
title(ax,sprintf('(б) пари за індексом зерна; помаранчевим — перетин напрямної (Δs = %.4f мм)',E.summary.seedStationMismatchForced_mm),'FontWeight','normal','FontSize',7);box(ax,'on');
save1(f,outDir,'LP2A2_2_stantsii_UA');
% ------------------------------------------------------------------ 3 after collapse at a kink
X=D9.X3;T=D9.T3;up=D9.upperBankT6;lo=D9.lowerBankT6;kp=P9(4,:);
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 8]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
for q=1:2
 ax=nexttile(tl);hold(ax,'on');wd=[1.6 .5];w=wd(q);
 e=all(abs(X(T(:,1),:)-kp)<4*w,2);triplot(T(e,:),X(:,1),X(:,2),'Color',[.55 .55 .55],'LineWidth',.3);
 bu=up(ismember(up,unique(T(:))));bl=lo(ismember(lo,unique(T(:))));
 plot(ax,X(bu,1),X(bu,2),'o','Color',cU,'MarkerSize',3.5,'LineWidth',.8);plot(ax,X(bl,1),X(bl,2),'x','Color',cL,'MarkerSize',4.5,'LineWidth',.8);
 plot(ax,P9(:,1),P9(:,2),'-','Color',[0 0 0 .35]);axis(ax,'equal');xlim(ax,kp(1)+[-w w]);ylim(ax,kp(2)+[-w w]);box(ax,'on');xlabel(ax,'x, мм');ylabel(ax,'y, мм');
 if q==1,title(ax,'(а) після колапсу: вершина злому 3 (S9-прогноз м’яке \{2\})','FontWeight','normal','FontSize',7);
 else,title(ax,'(б) збільшено: кожна пара — два різні вузли в одній точці','FontWeight','normal','FontSize',7);legend(ax,{'','верхній берег','нижній берег'},'Location','southeast');end
end
save1(f,outDir,'LP2A2_3_pislia_kolapsu_UA');
% ------------------------------------------------------------------ 4 collar connection
tip=P9(end,:);rw=D9.elementRows;
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 8.5]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
for q=1:2
 ax=nexttile(tl);hold(ax,'on');wd=[6 1.2];w=wd(q);
 sel=@(r)r(all(abs(X(T(r,1),:)-tip)<w+1,2));
 patch(ax,'Faces',T(sel(rw.core),:),'Vertices',X,'FaceColor',[.88 .88 .88],'EdgeColor',[.5 .5 .5],'LineWidth',.2);
 patch(ax,'Faces',T(sel(rw.collar),:),'Vertices',X,'FaceColor',[.80 .90 1],'EdgeColor',[.3 .45 .7],'LineWidth',.3);
 patch(ax,'Faces',T(sel(rw.exterior),:),'Vertices',X,'FaceColor','w','EdgeColor',[.6 .6 .6],'LineWidth',.2);
 plot(ax,tip(1)+3.3*cos(th),tip(2)+3.3*sin(th),'-','Color',[.2 .3 .7],'LineWidth',.6);plot(ax,tip(1)+3.0*cos(th),tip(2)+3.0*sin(th),':','Color',[.3 .3 .3]);
 plot(ax,X(up,1),X(up,2),'.','Color',cU,'MarkerSize',6);plot(ax,X(lo,1),X(lo,2),'.','Color',cL,'MarkerSize',4);
 axis(ax,'equal');xlim(ax,tip(1)+[-w w]);ylim(ax,tip(2)+[-w w]);box(ax,'on');xlabel(ax,'x, мм');ylabel(ax,'y, мм');
 if q==1,title(ax,'(а) ядро p010 3,0 мм (сіре), комір 3,3 мм (блакитне), зовнішня сітка','FontWeight','normal','FontSize',7);
 else,title(ax,'(б) вхід берегів у комір: 65 ідентичностей обода незмінні','FontWeight','normal','FontSize',7);end
end
save1(f,outDir,'LP2A2_4_komir_UA');
% ------------------------------------------------------------------ 5 full meshes
r8=get('A_H_S8');P8=r8.polyline_mm;D8=g2_lp2a2_join(P8,'ExpectedVertices',size(P8,1),'ExpectedTangent',reshape(r8.tangent,1,2),'ExteriorOptions',opts,'MaxT3Elements',40000);
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 11]);tl=tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');
Ds={D8,D9};nm={sprintf('(а) H, прийнятий S8: %d T3',size(D8.T3,1)),sprintf('(б) м’яке \\{2\\}, прогноз S9 (не стан): %d T3',size(D9.T3,1))};Ps={P8,P9};
for q=1:2
 ax=nexttile(tl,q);triplot(Ds{q}.T3,Ds{q}.X3(:,1),Ds{q}.X3(:,2),'Color',[.45 .45 .45],'LineWidth',.15);hold(ax,'on');
 for h=1:3,plot(ax,cen(h,1)+19.05*cos(th),cen(h,2)+19.05*sin(th),'-','Color',[.1 .5 .2],'LineWidth',.5);end
 plot(ax,Ps{q}(:,1),Ps{q}(:,2),'r-','LineWidth',.8);axis(ax,'equal');xlim(ax,[0 508]);ylim(ax,[0 254]);box(ax,'on');title(ax,nm{q},'FontWeight','normal','FontSize',7);
 ax=nexttile(tl,q+2);triplot(Ds{q}.T3,Ds{q}.X3(:,1),Ds{q}.X3(:,2),'Color',[.45 .45 .45],'LineWidth',.2);hold(ax,'on');
 for h=1:2,plot(ax,cen(h,1)+19.05*cos(th),cen(h,2)+19.05*sin(th),'-','Color',[.1 .5 .2],'LineWidth',.6);plot(ax,cen(h,1)+6.35*cos(th),cen(h,2)+6.35*sin(th),'k-','LineWidth',.6);end
 tp=Ps{q}(end,:);plot(ax,tp(1)+15*cos(th),tp(2)+15*sin(th),':','Color',[.5 .5 .5]);plot(ax,Ps{q}(:,1),Ps{q}(:,2),'r-','LineWidth',.8);
 axis(ax,'equal');xlim(ax,[90 175]);ylim(ax,[20 100]);box(ax,'on');xlabel(ax,'x, мм');ylabel(ax,'y, мм');
end
save1(f,outDir,'LP2A2_5_povni_sitky_UA');
% ------------------------------------------------------------------ 6 qualification overview
Q=jsondecode(fileread(qualJson));qr=Q.rows;if ~iscell(qr),qr=num2cell(qr);end
ng=~cellfun(@(r)r.guardRow,qr);V=cellfun(@(r)r.state,qr);on=cellfun(@(r)logical(r.old.pass),qr);nw=cellfun(@(r)logical(r.new.pass),qr);
sv=unique(V(ng));tot=arrayfun(@(s)nnz(ng&V==s),sv);po=arrayfun(@(s)nnz(ng&V==s&on),sv);pn=arrayfun(@(s)nnz(ng&V==s&nw),sv);
f=figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 17 7]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl);b=bar(ax,sv,[po(:)./tot(:),pn(:)./tot(:)]*100,'grouped');b(1).FaceColor=[.6 .6 .6];b(2).FaceColor=[.15 .45 .2];
xlabel(ax,'стан (кількість 4-мм кроків після S0)');ylabel(ax,'пройшли, %');legend(ax,{'успадкований генератор','LP2-A2'},'Location','southwest');ylim(ax,[0 105]);box(ax,'on');
title(ax,sprintf('(а) %d геометрій без рядків-обмежувачів',nnz(ng)),'FontWeight','normal','FontSize',7);
ax=nexttile(tl);hold(ax,'on');t3=cellfun(@(r)gf(r.new,'T3'),qr);
plot(ax,V(ng&nw),t3(ng&nw),'o','Color',[.15 .45 .2],'MarkerSize',3.5);plot(ax,V(ng&~nw&~isnan(t3)),t3(ng&~nw&~isnan(t3)),'x','Color',[.8 .2 .1],'MarkerSize',5);
yline(ax,40000,'--','бюджет 40 000 T3','FontSize',7);xlabel(ax,'стан');ylabel(ax,'T3 (LP2-A2)');box(ax,'on');ylim(ax,[25000 42000]);
title(ax,'(б) розмір сітки; хрестики — з’єднано, але не пройдено аудит','FontWeight','normal','FontSize',7);
save1(f,outDir,'LP2A2_6_kvalifikatsiia_UA');
end

function v=gf(s,f),if isfield(s,f)&&~isempty(s.(f)),v=double(s.(f));else,v=NaN;end,end
function save1(f,o,n)
exportgraphics(f,fullfile(o,[n '.png']),'Resolution',300);exportgraphics(f,fullfile(o,[n '.pdf']),'ContentType','vector');close(f);
end
