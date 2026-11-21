function W = run_g2_m4a_report_batch(analysisDir)
%RUN_G2_M4A_REPORT_BATCH  Ukrainian-labelled figures for the G2-M4.A review packet (Issue #44).
%
%  W = run_g2_m4a_report_batch(analysisDir)
% Reads FIGDATA.mat of a GO analysis run, the S0 meshes of both families (hash-checked) and the
% alternative soft STEP_002 mesh. All titles, axes and legends come from the UTF-8 file
% m4a_report_labels_uk.json. Writes a NEW outputs/g2_m4_report/run_<time>/ with PNG figures,
% the plotted data as CSV and SHA256SUMS.txt. No solve, no records changed.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
pol=jsondecode(fileread(fullfile(here,'G2_M4_POLICY_v1.json')));
polM=jsondecode(fileread(fullfile(here,'G2_MATERIAL_POLICY_v1.json')));
T=jsondecode(fileread(fullfile(here,'m4a_report_labels_uk.json'),'Encoding','UTF-8'));
F=load(fullfile(analysisDir,'FIGDATA.mat'));
out=fullfile(repo,'outputs','g2_m4_report',['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);assert(~exist(out,'dir'));mkdir(out);
diary(fullfile(out,'m4a_report_console.log'));cl=onCleanup(@()diary('off')); %#ok<NASGU>
set(groot,'defaultAxesFontName','Arial','defaultTextFontName','Arial','defaultAxesFontSize',9,'defaultLegendFontSize',8);
cS=[0.16 0.42 0.73];cT=[0.78 0.33 0.24];cH=[0.25 0.25 0.25];col=struct('soft',cS,'stiff',cT,'homogeneous',cH);
s=F.s;W=struct('figures',{{}});
% ---------------- Fig 1 paths
f=figure('Visible','off','Units','centimeters','Position',[0 0 24 9]);
ax=subplot(1,3,1);hold(ax,'on');axis(ax,'equal');
c=[152.4 69.85;152.4 120.65;152.4 171.45];th=linspace(0,2*pi,241);
for j=1:3
 fill(ax,c(j,1)+19.05*cos(th),c(j,2)+19.05*sin(th),[0.80 0.88 0.96],'EdgeColor',[0.3 0.45 0.7]);
 fill(ax,c(j,1)+6.35*cos(th),c(j,2)+6.35*sin(th),'w','EdgeColor','k');
end
P=F.Po.homogeneous{3};plot(ax,P(:,1),P(:,2),'-','Color',cH,'LineWidth',1.6);
plot(ax,[0 0 220 220 0],[0 203.2 203.2 0 0],'k-');
xlim(ax,[60 200]);ylim(ax,[0 200]);xlabel(ax,T.x);ylabel(ax,T.y);title(ax,T.f1a,'FontWeight','normal','FontSize',8);
text(ax,104,40,T.crack,'FontSize',8);text(ax,165,95,T.band,'FontSize',8);
ax=subplot(1,3,2);hold(ax,'on');grid(ax,'on');
csvP=fopen(fullfile(out,'fig1_lateral_offsets.csv'),'w');fprintf(csvP,'material,family,s_mm,delta_mm,U_sep_mm\n');
hl=[];lab={};
for m={'soft','stiff'}
 so=F.sepO.(m{1});sa=F.sepA.(m{1});
 dO=[0,so.lateral_mm];dA=[0,sa.lateral_mm];uO=[0,so.U_sep_mm];uA=[0,sa.U_sep_mm];
 tol=min(.25*abs(dO),0.010);
 fill(ax,[s,fliplr(s)],[dO-tol,fliplr(dO+tol)],col.(m{1}),'FaceAlpha',.12,'EdgeColor','none','HandleVisibility','off');
 h1=errorbar(ax,s-.12,dO,2*uO,'-o','Color',col.(m{1}),'MarkerFaceColor',col.(m{1}),'LineWidth',1.2);
 h2=errorbar(ax,s+.12,dA,2*uA,'--s','Color',col.(m{1}),'MarkerFaceColor','w','LineWidth',1.2);
 hl=[hl,h1,h2];lab=[lab,{[T.(m{1}),'; ',T.orig],[T.(m{1}),'; ',T.alt]}]; %#ok<AGROW>
 for k=1:3,fprintf(csvP,'%s,orig,%.1f,%+.8f,%.3e\n%s,alt,%.1f,%+.8f,%.3e\n',m{1},s(k),dO(k),uO(k),m{1},s(k),dA(k),uA(k));end
end
fclose(csvP);
yline(ax,0,'k-','HandleVisibility','off');xlabel(ax,T.s);ylabel(ax,T.delta);title(ax,T.f1b,'FontWeight','normal','FontSize',8);xlim(ax,[24.5 34.3]);
legend(ax,hl,lab,'Location','southwest','FontSize',6.5);text(ax,24.8,0.11,T.stable,'FontSize',6.5);ylim(ax,[-0.09 0.125]);
ax=subplot(1,3,3);hold(ax,'on');grid(ax,'on');set(ax,'YScale','log');
csvD=fopen(fullfile(out,'fig1_crossfamily_drift.csv'),'w');fprintf(csvD,'path,s_mm,tipDrift_mm\n');
for m={'homogeneous','soft','stiff'}
 x=F.cross.(m{1});d=[x.tipDrift_mm];
 plot(ax,s(2:3),d(2:3),'-o','Color',col.(m{1}),'MarkerFaceColor',col.(m{1}),'LineWidth',1.2,'DisplayName',T.(strrep(m{1},'homogeneous','homog')));
 for k=1:3,fprintf(csvD,'%s,%.1f,%.4e\n',m{1},s(k),d(k));end
end
fclose(csvD);
xlabel(ax,T.s);ylabel(ax,T.drift);title(ax,T.f1c,'FontWeight','normal','FontSize',8);xlim(ax,[28.5 34.3]);legend(ax,'Location','northwest','FontSize',7);
W.figures{end+1}=save_fig(f,out,'m4a_fig1_paths.png');
% ---------------- Fig 2 ratios
f=figure('Visible','off','Units','centimeters','Position',[0 0 24 8.5]);
nm={'R_direct','R_path','R_total'};tt={T.f2a,T.f2b,T.f2c};
csvR=fopen(fullfile(out,'fig2_ratios.csv'),'w');fprintf(csvR,'ratio,material,family,s_mm,R,U,U_cons\n');
for q=1:3
 ax=subplot(1,3,q);hold(ax,'on');grid(ax,'on');
 for m={'soft','stiff'}
  ro=F.rowsO.(m{1});ra=F.rowsA.(m{1});
  Ro=arrayfun(@(r)r.(nm{q}).R,ro);Ra=arrayfun(@(r)r.(nm{q}).R,ra);Uo=arrayfun(@(r)r.(nm{q}).U,ro);Ua=arrayfun(@(r)r.(nm{q}).U,ra);
  Uco=arrayfun(@(r)r.(nm{q}).U_cons,ro);Uca=arrayfun(@(r)r.(nm{q}).U_cons,ra);
  errorbar(ax,s-.12,Ro,2*Uo,'-o','Color',col.(m{1}),'MarkerFaceColor',col.(m{1}),'LineWidth',1.2,'DisplayName',[T.(m{1}),'; ',T.orig]);
  errorbar(ax,s+.12,Ra,2*Ua,'--s','Color',col.(m{1}),'MarkerFaceColor','w','LineWidth',1.2,'DisplayName',[T.(m{1}),'; ',T.alt]);
  for k=1:3,fprintf(csvR,'%s,%s,orig,%.1f,%.9f,%.3e,%.3e\n%s,%s,alt,%.1f,%.9f,%.3e,%.3e\n',nm{q},m{1},s(k),Ro(k),Uo(k),Uco(k),nm{q},m{1},s(k),Ra(k),Ua(k),Uca(k));end
 end
 yline(ax,1,'k-','HandleVisibility','off');xlabel(ax,T.s);ylabel(ax,T.ratio);title(ax,tt{q},'FontWeight','normal','FontSize',8.5);xlim(ax,[24.5 34.3]);
 if q==1,legend(ax,'Location','northwest','FontSize',6.5);end
 if q==2,text(ax,24.8,1.00055,T.errbar,'FontSize',7);end
end
fclose(csvR);
W.figures{end+1}=save_fig(f,out,'m4a_fig2_ratios.png');
% ---------------- Fig 3 S0 interface meshes
fa=fullfile(repo,pol.base.famA_S0Mesh);assert(strcmpi(g2_sha256_file(fa),pol.base.famA_S0MeshSHA256),'G2M4R:famA','famA hash.');
S0=g2_m4a_s0alt('Mode','verify','Reaudit',false);DA=load(fa);
P0=[101.6 0;101.6 25.4];[DmA,Ad]=g2_m2_state_adapter(DA,'S0',P0);assert(Ad.pass);
[PMA]=g2_material_phase_stage(DmA,polM,P0);assert(PMA.pass);
f=figure('Visible','off','Units','centimeters','Position',[0 0 22 10.5]);
win=[131 157 47 73];
plot_phase(subplot(1,2,1),DA,PMA.phase,win,T.f3a,T);
plot_phase(subplot(1,2,2),S0.D,S0.record.phase,win,T.f3b,T);
W.figures{end+1}=save_fig(f,out,'m4a_fig3_interface_meshes.png');
% ---------------- Fig 4 q support, alternative soft S2
mf=fullfile(repo,'outputs','g2_m4_alt_family_v1','chain_soft_alt_v1','STEP_002','KINKED_GEOMETRY_ONLY_candidate.mat');
[Rv,~,ok]=g2_trajectory_record('read',fullfile(fileparts(mf),'REVIEW.mat'));assert(ok&&strcmpi(g2_sha256_file(mf),Rv.meshSHA256),'G2M4R:Mesh','soft S2 alt mesh hash.');
D=load(mf);tip=D.crackPolyline(end,:);
f=figure('Visible','off','Units','centimeters','Position',[0 0 22 10.5]);
plot_tip(subplot(1,2,1),D,tip,3.2,T.f4a,T,true);
plot_tip(subplot(1,2,2),D,tip,16,T.f4b,T,false);
W.figures{end+1}=save_fig(f,out,'m4a_fig4_tip_q_support.png');
% ---------------- Fig 5 K
f=figure('Visible','off','Units','centimeters','Position',[0 0 24 8.5]);
csvK=fopen(fullfile(out,'fig5_K.csv'),'w');fprintf(csvK,'path,s_mm,KI_orig,KI_alt,KII_orig,KII_alt,KI_rel,KII_rel,G_rel\n');
for q=1:2
 ax=subplot(1,3,q);hold(ax,'on');grid(ax,'on');
 for m={'homogeneous','soft','stiff'}
  x=F.cross.(m{1});
  if q==1,yo=[x.KI_orig];ya=[x.KI_alt];else,yo=[x.KII_orig];ya=[x.KII_alt];end
  plot(ax,s-.1,yo,'-o','Color',col.(m{1}),'MarkerFaceColor',col.(m{1}),'LineWidth',1.1,'DisplayName',[T.(strrep(m{1},'homogeneous','homog')),'; ',T.orig]);
  plot(ax,s+.1,ya,'--s','Color',col.(m{1}),'MarkerFaceColor','w','LineWidth',1.1,'DisplayName',[T.(strrep(m{1},'homogeneous','homog')),'; ',T.alt]);
 end
 xlabel(ax,T.s);title(ax,T.(sprintf('f5%c','a'+q-1)),'FontWeight','normal','FontSize',8.5);xlim(ax,[24.5 34.3]);
 if q==2,legend(ax,'Location','northeast','FontSize',6);end
end
ax=subplot(1,3,3);hold(ax,'on');grid(ax,'on');
mk={'o','s','^'};pp={'homogeneous','soft','stiff'};
for i=1:3
 x=F.cross.(pp{i});
 plot(ax,s+(i-2)*.25,[x.KI_relDrift],['-',mk{i}],'Color',col.(pp{i}),'MarkerFaceColor',col.(pp{i}),'DisplayName',[T.KIrel,', ',T.(strrep(pp{i},'homogeneous','homog'))]);
 plot(ax,s+(i-2)*.25,[x.KII_relDrift],[':',mk{i}],'Color',col.(pp{i}),'MarkerFaceColor','w','DisplayName',[T.KIIrel,', ',T.(strrep(pp{i},'homogeneous','homog'))]);
 for k=1:3,fprintf(csvK,'%s,%.1f,%.9f,%.9f,%+.9f,%+.9f,%+.3e,%+.3e,%+.3e\n',pp{i},s(k),x(k).KI_orig,x(k).KI_alt,x(k).KII_orig,x(k).KII_alt,x(k).KI_relDrift,x(k).KII_relDrift,x(k).G_relDrift);end
end
fclose(csvK);
yline(ax,0,'k-','HandleVisibility','off');xlabel(ax,T.s);ylabel(ax,T.relchg);title(ax,T.f5c,'FontWeight','normal','FontSize',8.5);xlim(ax,[24.5 34.3]);
legend(ax,'Location','southwest','FontSize',5.5);
W.figures{end+1}=save_fig(f,out,'m4a_fig5_K.png');
diary('off');
fl=dir(out);fl=fl(~[fl.isdir]);fid=fopen(fullfile(out,'SHA256SUMS.txt'),'w');
for k=1:numel(fl),if ~strcmp(fl(k).name,'SHA256SUMS.txt'),fprintf(fid,'%s *%s\n',lower(g2_sha256_file(fullfile(out,fl(k).name))),fl(k).name);end,end
fclose(fid);W.folder=out;fprintf('G2_M4A_REPORT_DONE FOLDER=%s\n',out);
end

% =====================================================================
function p=save_fig(f,out,name)
p=fullfile(out,name);exportgraphics(f,p,'Resolution',220,'BackgroundColor','white');close(f);fprintf('FIGURE %s\n',name);
end

function plot_phase(ax,D,phase,win,ttl,T)
hold(ax,'on');axis(ax,'equal');
T3=D.T3;X=D.X3;cx=(X(T3(:,1),1)+X(T3(:,2),1)+X(T3(:,3),1))/3;cy=(X(T3(:,1),2)+X(T3(:,2),2)+X(T3(:,3),2))/3;
in=cx>win(1)-2&cx<win(2)+2&cy>win(3)-2&cy<win(4)+2;
ph=phase(:);
m1=in&ph==1;m2=in&ph==2;
patch(ax,'Faces',T3(m1,:),'Vertices',X,'FaceColor',[0.93 0.93 0.93],'EdgeColor',[0.45 0.45 0.45],'LineWidth',.25,'DisplayName',T.matrix);
patch(ax,'Faces',T3(m2,:),'Vertices',X,'FaceColor',[0.78 0.87 0.97],'EdgeColor',[0.35 0.45 0.65],'LineWidth',.25,'DisplayName',T.reinf);
th=linspace(0,2*pi,721);plot(ax,152.4+19.05*cos(th),69.85+19.05*sin(th),'r:','LineWidth',.8,'HandleVisibility','off');
xlim(ax,win(1:2));ylim(ax,win(3:4));xlabel(ax,T.x);ylabel(ax,T.y);title(ax,ttl,'FontWeight','normal','FontSize',8.5);
legend(ax,'Location','southwest','FontSize',7);box(ax,'on');
end

function plot_tip(ax,D,tip,R,ttl,T,showQ)
hold(ax,'on');axis(ax,'equal');
T3=D.T3;X=D.X3;cx=(X(T3(:,1),1)+X(T3(:,2),1)+X(T3(:,3),1))/3;cy=(X(T3(:,1),2)+X(T3(:,2),2)+X(T3(:,3),2))/3;
in=abs(cx-tip(1))<R*1.15&abs(cy-tip(2))<R*1.15;
core=false(size(T3,1),1);core(D.elementRows.core)=true;coll=false(size(T3,1),1);coll(D.elementRows.collar)=true;
patch(ax,'Faces',T3(in&~core&~coll,:),'Vertices',X,'FaceColor','w','EdgeColor',[0.6 0.6 0.6],'LineWidth',.2,'HandleVisibility','off');
patch(ax,'Faces',T3(in&core,:),'Vertices',X,'FaceColor',[0.95 0.95 0.85],'EdgeColor',[0.55 0.55 0.45],'LineWidth',.2,'DisplayName',T.core);
patch(ax,'Faces',T3(in&coll,:),'Vertices',X,'FaceColor',[0.86 0.93 0.86],'EdgeColor',[0.4 0.55 0.4],'LineWidth',.2,'DisplayName',T.collar);
if showQ
 qa=false(size(T3,1),1);qa(D.qActiveT6Rows)=true;
 patch(ax,'Faces',T3(qa,:),'Vertices',X,'FaceColor',[1 0.78 0.35],'EdgeColor',[0.7 0.5 0.15],'LineWidth',.2,'FaceAlpha',.85,'DisplayName',T.qact);
end
P=D.crackPolyline;plot(ax,P(:,1),P(:,2),'k-','LineWidth',1.4,'DisplayName',T.banks);
plot(ax,tip(1),tip(2),'kp','MarkerFaceColor','r','MarkerSize',8,'DisplayName',T.tip);
th=linspace(0,2*pi,361);
if ~showQ,plot(ax,tip(1)+15*cos(th),tip(2)+15*sin(th),'b:','HandleVisibility','off');end
xlim(ax,tip(1)+[-R R]);ylim(ax,tip(2)+[-R R]);xlabel(ax,T.x);ylabel(ax,T.y);title(ax,ttl,'FontWeight','normal','FontSize',8.5);
legend(ax,'Location','southoutside','FontSize',6.5,'NumColumns',2);box(ax,'on');
end
