function W = run_g2_m4b_report_batch(analysisDir,campaignDir)
%RUN_G2_M4B_REPORT_BATCH  Ukrainian-labelled figures for the G2-M4.B review package (Issue #47).
%
%  W = run_g2_m4b_report_batch(analysisDir,campaignDir)
% Reads LEDGER.json of a GO analysis run and, for the field maps, the hash-verified case records
% of the campaign run and the frozen S2 mesh. All titles, axes, legends and annotations come from
% the UTF-8 file m4b_report_labels_uk.json; tick labels use the Ukrainian decimal comma and a true
% minus sign. Figure 1 is labelled "Схематично" (geometry drawn from the policy and the saved S2
% polyline); figures 2-5 are MATLAB data. Writes a NEW outputs/g2_m4b_report/run_<time>/ with PNG
% figures, the plotted data as CSV and SHA256SUMS.txt. No solve, no record changed.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
pol=jsondecode(fileread(fullfile(here,'G2_M4B_POLICY_v2.json')));
T=jsondecode(fileread(fullfile(here,'m4b_report_labels_uk.json'),'Encoding','UTF-8'));
L=jsondecode(fileread(fullfile(analysisDir,'LEDGER.json')));
assert(strcmp(L.status,'GO'),'G2M4BR:Analysis','Analysis run is not GO.');
out=fullfile(repo,'outputs','g2_m4b_report',['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);assert(~exist(out,'dir'));mkdir(out);
diary(fullfile(out,'m4b_report_console.log'));cl=onCleanup(@()diary('off')); %#ok<NASGU>
set(groot,'defaultAxesFontName','Arial','defaultTextFontName','Arial','defaultAxesFontSize',9,'defaultLegendFontSize',8);
cS=[0.16 0.42 0.73];cT=[0.78 0.33 0.24];W=struct('figures',{{}});
bits={'000','100','010','001','110','101','011','111'};mlab=cellfun(@(b)T.(['m',b]),bits,'UniformOutput',false);
A=L.attribution;nm=A(1).termNames;ix=@(n)find(strcmp(nm,n));
cen=reshape(pol.rings.centres_mm,[],2);if ~isequal(cen(:,1),[152.4;152.4;152.4]),cen=reshape(pol.rings.centres_mm.',[],2);end
% ---------------- Fig 1 schematic
D=load(fullfile(repo,pol.reference.mesh),'crackPolyline','tipTangent');P=D.crackPolyline;t=D.tipTangent(:).';n=[-t(2),t(1)];tip=P(end,:);
f=figure('Visible','off','Units','centimeters','Position',[0 0 24 11]);
tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl);hold(ax,'on');axis(ax,'equal');th=linspace(0,2*pi,241);
rectangle(ax,'Position',[0 0 508 203.2],'EdgeColor',[0.3 0.3 0.3]);
for j=1:3
 fill(ax,cen(j,1)+19.05*cos(th),cen(j,2)+19.05*sin(th),[0.85 0.85 0.85],'EdgeColor',[0.35 0.35 0.35],'HandleVisibility','off');
 fill(ax,cen(j,1)+6.35*cos(th),cen(j,2)+6.35*sin(th),'w','EdgeColor','k','HandleVisibility','off');
 text(ax,cen(j,1)+24,cen(j,2),sprintf('%s %d',T.ring,j),'FontSize',8,'FontWeight','bold');
 rp=L.ringPositions(j);
 text(ax,cen(j,1)+24,cen(j,2)-9,sprintf('%s мм',strrep(sprintf('%.1f',rp.distance_mm),'.',',')),'FontSize',6.5,'Color',[0.3 0.3 0.3]);
 plot(ax,[tip(1) cen(j,1)],[tip(2) cen(j,2)],':','Color',[0.5 0.5 0.5],'HandleVisibility','off');
end
plot(ax,P(:,1),P(:,2),'k-','LineWidth',1.8,'HandleVisibility','off');
quiver(ax,tip(1),tip(2),18*t(1),18*t(2),0,'Color',[0.8 0.1 0.1],'LineWidth',1.1,'MaxHeadSize',.6,'HandleVisibility','off');
quiver(ax,tip(1),tip(2),18*n(1),18*n(2),0,'Color',[0.1 0.5 0.1],'LineWidth',1.1,'MaxHeadSize',.6,'HandleVisibility','off');
text(ax,tip(1)+18*t(1)+1,tip(2)+18*t(2)+2,'t','Color',[0.8 0.1 0.1],'FontSize',8);text(ax,tip(1)+18*n(1)-6,tip(2)+18*n(2),'n','Color',[0.1 0.5 0.1],'FontSize',8);
text(ax,104,12,T.crack,'FontSize',7);
quiver(ax,254,228,0,-22,0,'k','LineWidth',1.1,'MaxHeadSize',.8,'HandleVisibility','off');text(ax,258,226,T.load,'FontSize',7.5);
plot(ax,25.4,0,'k^','MarkerFaceColor','k','MarkerSize',6);plot(ax,482.6,0,'ko','MarkerFaceColor','w','MarkerSize',6);
xlim(ax,[60 280]);ylim(ax,[-8 235]);xlabel(ax,T.x);ylabel(ax,T.y);title(ax,T.f1a,'FontWeight','normal','FontSize',8.5);box(ax,'on');comma(ax);
ax=nexttile(tl);hold(ax,'on');axis(ax,'equal');axis(ax,'off');
for m=1:8
 col=mod(m-1,4);row=floor((m-1)/4);x0=col*30;y0=-row*62;
 for j=1:3
  on=bits{m}(j)=='1';fc=[1 1 1];if on,fc=[0.55 0.70 0.88];end
  fill(ax,x0+9*cos(th),y0+(j-2)*17+9*sin(th),fc,'EdgeColor',[0.3 0.3 0.3],'HandleVisibility','off');
  fill(ax,x0+3*cos(th),y0+(j-2)*17+3*sin(th),'w','EdgeColor','k','HandleVisibility','off');
 end
 text(ax,x0,y0-33,mlab{m},'HorizontalAlignment','center','FontSize',8);
end
fill(ax,-12+3*cos(th),-112+3*sin(th),[0.55 0.70 0.88],'EdgeColor',[0.3 0.3 0.3]);text(ax,-6,-112,T.active,'FontSize',7);
fill(ax,52+3*cos(th),-112+3*sin(th),'w','EdgeColor',[0.3 0.3 0.3]);text(ax,58,-112,T.passive,'FontSize',7);
title(ax,T.f1b,'FontWeight','normal','FontSize',8.5);xlim(ax,[-14 104]);ylim(ax,[-120 30]);
W.figures{end+1}=save_fig(f,out,'m4b_fig1_schematic.png');
% ---------------- Fig 2 F_G and F_theta across masks
f=figure('Visible','off','Units','centimeters','Position',[0 0 24 10]);
tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
csv=fopen(fullfile(out,'fig2_FG_Ftheta.csv'),'w');fprintf(csv,'contrast,mask,observable,value,U_primary,U_conservative\n');
subs={'F_1','F_2','F_3','F_12','F_13','F_23','F_123'};
for q=1:2
 ax=nexttile(tl);hold(ax,'on');grid(ax,'on');
 obs={'G','theta'};sc=[100 1];
 for ci=1:2
  At=A(ci);Q=At.(obs{q});v=[0;Q.Q(cellfun(ix,subs))]*sc(q);Up=[0;Q.U_primary(cellfun(ix,subs))]*sc(q);Uc=[0;Q.U_conservative(cellfun(ix,subs))]*sc(q);
  x=(1:8)+(ci-1.5)*0.22;c=cS;if ci==2,c=cT;end
  errorbar(ax,x,v,Uc,'o','Color',c,'MarkerFaceColor',c,'MarkerSize',5,'LineWidth',1,'CapSize',4,'DisplayName',T.(ternary(ci==1,'soft','stiff')));
  errorbar(ax,x,v,2*Up,'.','Color','k','LineWidth',1.2,'CapSize',0,'HandleVisibility','off');
  for m=1:8,fprintf(csv,'%s,%s,%s,%+.10g,%.4g,%.4g\n',At.contrast,bits{m},obs{q},v(m),Up(m),Uc(m));end
 end
 yline(ax,0,'k-','HandleVisibility','off');xlim(ax,[.5 8.5]);set(ax,'XTick',1:8,'XTickLabel',mlab);
 xlabel(ax,T.masks);ylabel(ax,T.(ternary(q==1,'FG','Fth')));title(ax,T.(ternary(q==1,'f2a','f2b')),'FontWeight','normal','FontSize',8.5);
 commaY(ax);
 if q==1,lg=legend(ax,'NumColumns',2,'FontSize',7.5);lg.Layout.Tile='south';lg.Title.String=T.consbar;lg.Title.FontWeight='normal';lg.Title.FontSize=7;end
end
fclose(csv);
W.figures{end+1}=save_fig(f,out,'m4b_fig2_FG_Ftheta.png');
% ---------------- Fig 3 decomposition f_i, I_ij, I_123
f=figure('Visible','off','Units','centimeters','Position',[0 0 24 15]);
tl=tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');
terms={'f_1','f_2','f_3','I_12','I_13','I_23','I_123'};tlab={'f_{1}','f_{2}','f_{3}','I_{12}','I_{13}','I_{23}','I_{123}'};
csv=fopen(fullfile(out,'fig3_decomposition.csv'),'w');fprintf(csv,'contrast,observable,term,value,U_primary,U_conservative,class\n');
tt={'f3a','f3b';'f3c','f3d'};obs={'G','theta'};sc=[100 1];
for q=1:2
 for ci=1:2
  ax=nexttile(tl);hold(ax,'on');grid(ax,'on');At=A(ci);Q=At.(obs{q});k=cellfun(ix,terms);
  v=Q.Q(k)*sc(q);Uc=Q.U_conservative(k)*sc(q);Up=Q.U_primary(k)*sc(q);cls=Q.class(k);c=cS;if ci==2,c=cT;end
  for j=1:7
   switch cls{j}
    case 'RESOLVED_BOTH',fc=c;ec=c;
    case 'RESOLVED_PRIMARY_ONLY',fc=0.55*c+0.45;ec=c;
    otherwise,fc=[1 1 1];ec=[0.4 0.4 0.4];
   end
   bar(ax,j,v(j),0.6,'FaceColor',fc,'EdgeColor',ec,'LineWidth',1,'HandleVisibility','off');
   fprintf(csv,'%s,%s,%s,%+.10g,%.4g,%.4g,%s\n',At.contrast,obs{q},terms{j},v(j),Up(j),Uc(j),cls{j});
  end
  errorbar(ax,1:7,v,Uc,'k.','LineWidth',.9,'CapSize',4,'HandleVisibility','off');
  yline(ax,0,'k-','HandleVisibility','off');xlim(ax,[.4 7.6]);set(ax,'XTick',1:7,'XTickLabel',tlab);
  ylabel(ax,T.(ternary(q==1,'FG','Fth')));title(ax,T.(tt{q,ci}),'FontWeight','normal','FontSize',8.5);commaY(ax);
  if q==1&&ci==1
   h1=bar(ax,nan,nan,'FaceColor',c,'EdgeColor',c);h2=bar(ax,nan,nan,'FaceColor',.55*c+.45,'EdgeColor',c);
   lg=legend(ax,[h1 h2],{T.both,T.primonly},'FontSize',7,'NumColumns',2);lg.Layout.Tile='south';lg.Title.String=T.consbar;lg.Title.FontWeight='normal';lg.Title.FontSize=7;
  end
 end
end
fclose(csv);
W.figures{end+1}=save_fig(f,out,'m4b_fig3_decomposition.png');
% ---------------- Fig 4 equal-area comparisons
f=figure('Visible','off','Units','centimeters','Position',[0 0 24 15]);
tl=tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');
csv=fopen(fullfile(out,'fig4_equal_area.csv'),'w');fprintf(csv,'contrast,observable,set,value,U_primary,U_conservative\n');
one={'F_1','F_2','F_3'};two={'F_12','F_13','F_23'};
rl=arrayfun(@(j)sprintf('%d (%s мм)',j,strrep(sprintf('%.1f',L.ringPositions(j).distance_mm),'.',',')),1:3,'UniformOutput',false);
pl={T.m110,T.m101,T.m011};
tt={'f4a','f4b';'f4c','f4d'};
for q=1:2
 for g=1:2
  ax=nexttile(tl);hold(ax,'on');grid(ax,'on');set_=one;xl=rl;if g==2,set_=two;xl=pl;end
  for ci=1:2
   At=A(ci);Q=At.(obs{q});k=cellfun(ix,set_);v=Q.Q(k)*sc(q);Uc=Q.U_conservative(k)*sc(q);Up=Q.U_primary(k)*sc(q);c=cS;if ci==2,c=cT;end
   errorbar(ax,(1:3)+(ci-1.5)*.18,v,Uc,'-o','Color',c,'MarkerFaceColor',c,'LineWidth',1.1,'CapSize',4,'DisplayName',T.(ternary(ci==1,'soft','stiff')));
   for j=1:3,fprintf(csv,'%s,%s,%s,%+.10g,%.4g,%.4g\n',At.contrast,obs{q},set_{j},v(j),Up(j),Uc(j));end
  end
  yline(ax,0,'k-','HandleVisibility','off');xlim(ax,[.6 3.4]);set(ax,'XTick',1:3,'XTickLabel',xl);
  xlabel(ax,ternary(g==1,T.ringid,T.pairid));ylabel(ax,T.(ternary(q==1,'FG','Fth')));
  title(ax,{T.(tt{q,g}),['(',T.(ternary(g==1,'area1','area2')),')']},'FontWeight','normal','FontSize',8.5);commaY(ax);
  if q==1&&g==1,lg=legend(ax,'NumColumns',2,'FontSize',7.5);lg.Layout.Tile='south';lg.Title.String=T.consbar;lg.Title.FontWeight='normal';lg.Title.FontSize=7;end
 end
end
fclose(csv);
W.figures{end+1}=save_fig(f,out,'m4b_fig4_equal_area.png');
% ---------------- Fig 5 strain-energy density change maps (MATLAB data)
Dm=load(fullfile(repo,pol.reference.mesh),'X6','T6');
assert(strcmpi(g2_sha256_file(fullfile(repo,pol.reference.mesh)),pol.reference.meshSHA256),'G2M4BR:Mesh','S2 mesh hash.');
X=Dm.X6;T3=Dm.T6(:,1:3);x=X(:,1);y=X(:,2);
Ael=.5*((x(T3(:,2))-x(T3(:,1))).*(y(T3(:,3))-y(T3(:,1)))-(x(T3(:,3))-x(T3(:,1))).*(y(T3(:,2))-y(T3(:,1))));
rec=@(id)read_case(campaignDir,id,L);
w0=rec('none').K.elementStrainEnergy_per_thickness./Ael;
ids={'c0p5_100','c0p5_010','c0p5_111'};tt={'f5a','f5b','f5c'};
f=figure('Visible','off','Units','centimeters','Position',[0 0 24 10.5]);
tl=tiledlayout(f,1,3,'TileSpacing','compact','Padding','compact');
cm=divmap(256);
csv=fopen(fullfile(out,'fig5_energy_density_summary.csv'),'w');fprintf(csv,'case,median_rel_change_ring1,median_rel_change_ring2,median_rel_change_ring3,median_rel_change_matrix\n');
for k=1:3
 r=rec(ids{k});w=r.K.elementStrainEnergy_per_thickness./Ael;rel=(w-w0)./w0;relc=max(min(rel,.5),-.5);
 ax=nexttile(tl);hold(ax,'on');axis(ax,'equal');
 patch(ax,'Faces',T3,'Vertices',X,'FaceVertexCData',relc,'FaceColor','flat','EdgeColor','none');
 colormap(ax,cm);clim(ax,[-.5 .5]);
 for j=1:3,plot(ax,cen(j,1)+19.05*cos(th),cen(j,2)+19.05*sin(th),'k-','LineWidth',.4);end
 plot(ax,P(:,1),P(:,2),'k-','LineWidth',1.4);
 xlim(ax,[70 240]);ylim(ax,[0 203.2]);xlabel(ax,T.x);ylabel(ax,T.y);title(ax,T.(tt{k}),'FontWeight','normal','FontSize',8.5);box(ax,'on');comma(ax);
 own=r.ownerRing;fprintf(csv,'%s,%.6g,%.6g,%.6g,%.6g\n',ids{k},median(rel(own==1)),median(rel(own==2)),median(rel(own==3)),median(rel(own==0)));
end
fclose(csv);
cb=colorbar(ax);cb.Layout.Tile='east';cb.Label.String=T.wrel;cb.Ticks=-.5:.25:.5;
cb.TickLabels=arrayfun(@(v)strrep(strrep(sprintf('%g',v),'.',','),'-',char(8722)),cb.Ticks,'UniformOutput',false);
annotation(f,'textbox',[0.01 0.0 0.98 0.05],'String',T.fieldnote,'EdgeColor','none','FontSize',7,'HorizontalAlignment','right');
W.figures{end+1}=save_fig(f,out,'m4b_fig5_energy_density.png');
diary('off');
fl=dir(out);fl=fl(~[fl.isdir]);fid=fopen(fullfile(out,'SHA256SUMS.txt'),'w');
for k=1:numel(fl),if ~strcmp(fl(k).name,'SHA256SUMS.txt'),fprintf(fid,'%s *%s\n',lower(g2_sha256_file(fullfile(out,fl(k).name))),fl(k).name);end,end
fclose(fid);W.folder=out;fprintf('G2_M4B_REPORT_DONE FOLDER=%s\n',strrep(out,repo,'<repo>'));
end

% =====================================================================
function r=read_case(rd,id,L)
[r,h,ok]=g2_trajectory_record('read',fullfile(rd,['CASE_',id,'.mat']));
lc=L.logicalCases;s=lc(strcmp({lc.physicalCase},id));
assert(ok&&strcmpi(h,s(1).recordSHA256),'G2M4BR:Record','Record %s does not match the analysis ledger.',id);
end

function cm=divmap(n)
a=[0.13 0.40 0.70];w=[1 1 1];b=[0.75 0.20 0.17];h=n/2;
cm=[interp1([0 1],[a;w],linspace(0,1,h));interp1([0 1],[w;b],linspace(0,1,h))];
end

function comma(ax)
drawnow;for a='XY',fmt(ax,a);end
end

function commaY(ax)
drawnow;fmt(ax,'Y');
end

function fmt(ax,a)
v=ax.([a,'Tick']);ax.([a,'TickMode'])='manual';
ax.([a,'TickLabel'])=arrayfun(@(t)strrep(strrep(sprintf('%g',t),'.',','),'-',char(8722)),v,'UniformOutput',false);
end

function p=save_fig(f,out,name)
p=fullfile(out,name);exportgraphics(f,p,'Resolution',220,'BackgroundColor','white');close(f);fprintf('FIGURE %s\n',name);
end

function r=ternary(c,a,b),if c,r=a;else,r=b;end,end
