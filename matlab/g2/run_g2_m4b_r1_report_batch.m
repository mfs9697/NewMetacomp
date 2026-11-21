function W = run_g2_m4b_r1_report_batch(analysisDir,campaignDir)
%RUN_G2_M4B_R1_REPORT_BATCH  Greyscale, Ukrainian-labelled print figures for G2-M4.B-R1 (Issue #50).
%
%  W = run_g2_m4b_r1_report_batch(analysisDir,campaignDir)
% Uses ONLY accepted records: the R1 analysis LEDGER + R1 case records (hash-checked against the
% analysis ledger), the S2alt and original S2 meshes (hash-checked), the accepted M4.B
% original-family case records (hash-checked against the committed M4.B ledger) and the
% committed M4.B analysis ledger. Stresses are post-processed from saved displacements with the
% unchanged g2_t6_point_stress (element-centroid plane-stress von Mises). No solve.
% Colour: monotonic greyscale only. Unsigned field: lg(sigma_eq), dark = high. Signed fields:
% grey from dark (negative) to light (positive) on a compressed range [0.20, 0.97] so that black
% contours stay visible; contour lines at fixed levels, solid positive, dashed negative, bold zero.
% Common (global) limits for cross-case panels; a separately titled local-limit version for the
% stress-change maps. Every figure's plotted data -> CSV; choices -> FIGURE_NOTES.json.
% Writes a NEW outputs/g2_m4b_r1_report/run_<time>/.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
pol=jsondecode(fileread(fullfile(here,'G2_M4B_R1_POLICY_v1.json')));
T=jsondecode(fileread(fullfile(here,'m4b_r1_report_labels_uk.json'),'Encoding','UTF-8'));
L=jsondecode(fileread(fullfile(analysisDir,'LEDGER.json')));assert(strcmp(L.status,'GO'),'G2M4BR1R:Analysis','Analysis not GO.');
LB=jsondecode(fileread(fullfile(repo,'matlab','g2','evidence','m4b_20261121','analysis','LEDGER.json')));
out=fullfile(repo,'outputs','g2_m4b_r1_report',['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);assert(~exist(out,'dir'));mkdir(out);
diary(fullfile(out,'r1_report_console.log'));cl=onCleanup(@()diary('off')); %#ok<NASGU>
set(groot,'defaultAxesFontName','Arial','defaultTextFontName','Arial','defaultAxesFontSize',9,'defaultLegendFontSize',8);
W=struct('figures',{{}});N=struct();
cen=[152.4 69.85;152.4 120.65;152.4 171.45];th=linspace(0,2*pi,241);
rows=L.comparison;q=@(name,obs)rows(strcmp({rows.quantity},name)&strcmp({rows.observable},obs));
names={'F_c0p5_100','F_c0p5_010','F_c0p5_001','F_c2p0_100','F_c2p0_010','F_c2p0_001','F_c2p0_101','F_c0p5_111','F_c2p0_111'};
xp=[1:7,8.6,9.6];
% ================= G1 cross-family comparison
f=figure('Visible','off','Units','centimeters','Position',[0 0 24 10.5]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
csv=fopen(fullfile(out,'g1_crossfamily.csv'),'w');fprintf(csv,'quantity,observable,Q_orig,Ucons_orig,Q_alt,Ucons_alt,class\n');
obs={'G','theta'};sc=[100 1];
for k=1:2
 ax=nexttile(tl);hold(ax,'on');grid(ax,'on');
 Qo=zeros(1,9);Qa=Qo;Uo=Qo;Ua=Qo;
 for i=1:9,r=q(names{i},obs{k});Qo(i)=r.Q_orig*sc(k);Qa(i)=r.Q_alt*sc(k);Uo(i)=r.Ucons_orig*sc(k);Ua(i)=r.Ucons_alt*sc(k);
  fprintf(csv,'%s,%s,%+.10g,%.4g,%+.10g,%.4g,%s\n',names{i},obs{k},Qo(i),Uo(i),Qa(i),Ua(i),r.class);end
 errorbar(ax,xp-.14,Qo,Uo,'o','Color','k','MarkerFaceColor','k','MarkerSize',5,'LineWidth',1,'CapSize',4,'DisplayName',T.orig);
 errorbar(ax,xp+.14,Qa,Ua,'s','Color',[.45 .45 .45],'MarkerFaceColor','w','MarkerSize',6,'LineWidth',1,'CapSize',4,'LineStyle','none','DisplayName',T.alt);
 yline(ax,0,'k-','HandleVisibility','off');xline(ax,7.8,'k:','HandleVisibility','off');
 yl=ylim(ax);text(ax,9.1,yl(2)-0.05*diff(yl),T.anchorsep,'HorizontalAlignment','center','FontSize',7);
 set(ax,'XTick',xp,'XTickLabel',T.cases,'XTickLabelRotation',35);xlim(ax,[.4 10.2]);
 ylabel(ax,T.(ternary(k==1,'FG','Fth')));title(ax,T.(sprintf('g1%c','a'+k-1)),'FontWeight','normal','FontSize',8.5);commaY(ax);
 if k==1,lg=legend(ax,'NumColumns',2,'FontSize',7.5);lg.Layout.Tile='south';lg.Title.String=T.consbar;lg.Title.FontWeight='normal';lg.Title.FontSize=7;end
end
fclose(csv);W.figures{end+1}=save_fig(f,out,'r1_g1_crossfamily_grey.png');
N.g1=struct('data','R1 analysis LEDGER comparison (both families)','scale','linear; F_G in percent, F_theta in degrees','limits','automatic, same axis for both families', ...
 'greyscale','original = black filled circles; S2alt = open squares, grey; whiskers = each family''s own conservative U');
% ================= G2 three questions side by side (log)
f=figure('Visible','off','Units','centimeters','Position',[0 0 24 10.5]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
csv=fopen(fullfile(out,'g2_three_questions.csv'),'w');fprintf(csv,'quantity,observable,absQ_orig,abs_drift,U_primary_alt,U_cons_alt\n');
for k=1:2
 ax=nexttile(tl);hold(ax,'on');grid(ax,'on');set(ax,'YScale','log');
 A1=zeros(1,9);A2=A1;A3=A1;A4=A1;
 for i=1:9,r=q(names{i},obs{k});A1(i)=abs(r.Q_orig);A2(i)=abs(r.delta);A3(i)=r.U_alt;A4(i)=r.Ucons_alt;
  fprintf(csv,'%s,%s,%.6g,%.6g,%.6g,%.6g\n',names{i},obs{k},A1(i),A2(i),A3(i),A4(i));end
 plot(ax,xp,A1,'o','Color','k','MarkerFaceColor','k','MarkerSize',5,'DisplayName',T.absQ);
 plot(ax,xp,A4,'d','Color','k','MarkerFaceColor','w','MarkerSize',6,'DisplayName',T.ucons);
 plot(ax,xp,A2,'x','Color','k','MarkerSize',8,'LineWidth',1.3,'DisplayName',T.drift);
 plot(ax,xp,A3,'^','Color',[.5 .5 .5],'MarkerFaceColor',[.75 .75 .75],'MarkerSize',5,'DisplayName',T.uprim);
 xline(ax,7.8,'k:','HandleVisibility','off');
 set(ax,'XTick',xp,'XTickLabel',T.cases,'XTickLabelRotation',35);xlim(ax,[.4 10.2]);
 ylabel(ax,T.(ternary(k==1,'logFG','logFth')));title(ax,T.(sprintf('g2%c','a'+k-1)),'FontWeight','normal','FontSize',8.5);
 if k==1,lg=legend(ax,'NumColumns',2,'FontSize',7.5);lg.Layout.Tile='south';end
end
fclose(csv);W.figures{end+1}=save_fig(f,out,'r1_g2_three_questions_grey.png');
N.g2=struct('data','R1 analysis LEDGER','scale','logarithmic magnitudes (F_G as a fraction, F_theta in degrees)','limits','automatic', ...
 'greyscale','marker shapes distinguish |Q|, cross-family drift, primary U and conservative U');
% ================= G3 equal-area rankings
f=figure('Visible','off','Units','centimeters','Position',[0 0 24 15]);tl=tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');
rp=LB.ringPositions;rl=arrayfun(@(j)sprintf('%d (%s мм)',j,strrep(sprintf('%.1f',rp(j).distance_mm),'.',',')),1:3,'UniformOutput',false);
csv=fopen(fullfile(out,'g3_equal_area.csv'),'w');fprintf(csv,'contrast,observable,ring,Q_orig,Q_alt,Ucons_orig,Ucons_alt\n');
pan={'c0p5','G','g3a';'c2p0','G','g3b';'c0p5','theta','g3c';'c2p0','theta','g3d'};
for k=1:4
 ax=nexttile(tl);hold(ax,'on');grid(ax,'on');s=sc(1+strcmp(pan{k,2},'theta'));
 Qo=zeros(1,3);Qa=Qo;Uo=Qo;Ua=Qo;
 for j=1:3,b='000';b(j)='1';r=q(['F_',pan{k,1},'_',b],pan{k,2});Qo(j)=r.Q_orig*s;Qa(j)=r.Q_alt*s;Uo(j)=r.Ucons_orig*s;Ua(j)=r.Ucons_alt*s;
  fprintf(csv,'%s,%s,%d,%+.10g,%+.10g,%.4g,%.4g\n',pan{k,1},pan{k,2},j,Qo(j),Qa(j),Uo(j),Ua(j));end
 errorbar(ax,(1:3)-.08,Qo,Uo,'-o','Color','k','MarkerFaceColor','k','LineWidth',1.2,'CapSize',4,'DisplayName',T.orig);
 errorbar(ax,(1:3)+.08,Qa,Ua,'--s','Color',[.45 .45 .45],'MarkerFaceColor','w','LineWidth',1.2,'CapSize',4,'DisplayName',T.alt);
 yline(ax,0,'k-','HandleVisibility','off');set(ax,'XTick',1:3,'XTickLabel',rl);xlim(ax,[.6 3.4]);
 xlabel(ax,T.ringid);ylabel(ax,T.(ternary(strcmp(pan{k,2},'G'),'FG','Fth')));title(ax,T.(pan{k,3}),'FontWeight','normal','FontSize',8.5);commaY(ax);
 if k==1,lg=legend(ax,'NumColumns',2,'FontSize',7.5);lg.Layout.Tile='south';lg.Title.String=[T.consbar,'; ',T.area];lg.Title.FontWeight='normal';lg.Title.FontSize=7;end
end
fclose(csv);W.figures{end+1}=save_fig(f,out,'r1_g3_equal_area_grey.png');
N.g3=struct('data','R1 analysis LEDGER single-ring targets','scale','linear','limits','automatic per panel','greyscale','solid black (original) vs dashed grey with open squares (S2alt)');
% ================= stress fields on S2alt
mA=fullfile(repo,pol.reference.mesh);assert(strcmpi(g2_sha256_file(mA),pol.reference.meshSHA256),'G2M4BR1R:Mesh','S2alt hash.');
DA=load(mA,'X6','T6','crackPolyline');P=DA.crackPolyline;
lc=L.cases;rec=@(id)read_case(campaignDir,id,lc,'sha_alt');
r0=rec('none');sv0=vm_centroid(DA,r0);
ids={'c0p5_100','c0p5_010','c2p0_101'};rel=cell(1,3);
for k=1:3,r=rec(ids{k});sv=vm_centroid(DA,r);rel{k}=(sv-sv0)./sv0;end
lg0=log10(sv0);lgLim=[floor(prctile(lg0,1)*2)/2,ceil(prctile(lg0,99.5)*2)/2];
f=figure('Visible','off','Units','centimeters','Position',[0 0 24 21]);tl=tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl);unsigned_map(ax,DA,lg0,lgLim,cen,th,P,T.g4a,T);cb=colorbar(ax);cb.Label.String=T.cbLog;fmt_cb(cb);
tt={'g4b','g4c','g4d'};
for k=1:3
 ax=nexttile(tl);signed_map(ax,DA,rel{k},0.5,[0.1 0.25],cen,th,P,T.(tt{k}),T);
 if k==3,cb=colorbar(ax);cb.Layout.Tile='east';cb.Label.String=T.cbRel;cb.Ticks=-.5:.25:.5;fmt_cb(cb);end
end
xlabel(tl,T.globalNote,'FontSize',7.5);
W.figures{end+1}=save_fig(f,out,'r1_g4_stress_global_grey.png');
csv=fopen(fullfile(out,'g4_stress_summary.csv'),'w');fprintf(csv,'case,median_rel_ring1,median_rel_ring2,median_rel_ring3,median_rel_matrix,p99_abs_rel\n');
for k=1:3,r=rec(ids{k});o=r.ownerRing;fprintf(csv,'%s,%.5g,%.5g,%.5g,%.5g,%.5g\n',ids{k},median(rel{k}(o==1)),median(rel{k}(o==2)),median(rel{k}(o==3)),median(rel{k}(o==0)),prctile(abs(rel{k}),99));end
fclose(csv);
% local-limit version
f=figure('Visible','off','Units','centimeters','Position',[0 0 24 10.5]);tl=tiledlayout(f,1,3,'TileSpacing','compact','Padding','compact');
loc=zeros(1,3);
for k=1:3
 loc(k)=prctile(abs(rel{k}),99);ax=nexttile(tl);
 signed_map(ax,DA,rel{k},loc(k),loc(k)*[0.2 0.5],cen,th,P,{T.(tt{k}),sprintf('%s: ±%s',T.g4localTitle,strrep(sprintf('%.3f',loc(k)),'.',','))},T);
 cb=colorbar(ax,'southoutside');cb.Ticks=loc(k)*(-1:.5:1);fmt_cb(cb);
end
xlabel(tl,T.localNote,'FontSize',7.5);
W.figures{end+1}=save_fig(f,out,'r1_g4b_stress_local_grey.png');
N.g4=struct('data','R1 S2alt case records none, c0p5_100, c0p5_010, c2p0_101 (u, labels, materials); g2_t6_point_stress at element centroids; plane-stress von Mises', ...
 'scale',sprintf('panel a: lg(sigma_eq) in [%g, %g] (1st-99.5th percentile, rounded to 0.5); panels b-d: relative change clipped to +/-0.5',lgLim), ...
 'limits','GLOBAL common limits in r1_g4_stress_global_grey; LOCAL per-panel limits (99th percentile of |change|) in r1_g4b_stress_local_grey', ...
 'localLimits',loc,'greyscale','monotonic grey; signed maps on grey range 0.20-0.97; black contours (solid +, dashed -, bold zero) from a 0.5 mm grid interpolation of centroid values (holes masked)');
% ================= G5 energy density (original family, greyscale version of the M4.B figure)
mO=fullfile(repo,pol.reference.matchedOriginal.mesh);assert(strcmpi(g2_sha256_file(mO),pol.reference.matchedOriginal.meshSHA256),'G2M4BR1R:MeshO','S2 hash.');
DO=load(mO,'X6','T6','crackPolyline');
of=pol.reference.originalFamilyResults;led=fullfile(repo,of.ledger);
recO=@(id)read_orig(repo,of,led,id);
x=DO.X6(:,1);y=DO.X6(:,2);T3=DO.T6(:,1:3);Ael=.5*((x(T3(:,2))-x(T3(:,1))).*(y(T3(:,3))-y(T3(:,1)))-(x(T3(:,3))-x(T3(:,1))).*(y(T3(:,2))-y(T3(:,1))));
w0=recO('none').K.elementStrainEnergy_per_thickness./Ael;
ids5={'c0p5_100','c0p5_010','c0p5_111'};tt5={'g5a','g5b','g5c'};
f=figure('Visible','off','Units','centimeters','Position',[0 0 24 10.5]);tl=tiledlayout(f,1,3,'TileSpacing','compact','Padding','compact');
for k=1:3
 w=recO(ids5{k}).K.elementStrainEnergy_per_thickness./Ael;ax=nexttile(tl);
 signed_map(ax,DO,(w-w0)./w0,0.5,[0.1 0.25],cen,th,DO.crackPolyline,T.(tt5{k}),T);
 if k==3,cb=colorbar(ax);cb.Layout.Tile='east';cb.Label.String=T.cbW;cb.Ticks=-.5:.25:.5;fmt_cb(cb);end
end
xlabel(tl,strrep(T.globalNote,'панелей б–г','всіх панелей'),'FontSize',7.5);
W.figures{end+1}=save_fig(f,out,'r1_g5_energy_density_grey.png');
N.g5=struct('data','accepted M4.B original-family records none, c0p5_100, c0p5_010, c0p5_111 (element strain energy / element area)', ...
 'scale','relative change clipped to +/-0.5','limits','GLOBAL common','greyscale','as g4 signed maps; greyscale replacement of M4.B fig. Ж.5');
% ================= G6 / G7 greyscale versions of the accepted M4.B cross-case figures
At=LB.attribution;bitsN={'F_1','F_2','F_3','F_12','F_13','F_23','F_123'};
f=figure('Visible','off','Units','centimeters','Position',[0 0 24 10]);tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
mk={'o','^'};fc={'k','w'};
csv=fopen(fullfile(out,'g6_m4b_masks.csv'),'w');fprintf(csv,'contrast,observable,mask,value,U_cons\n');
for k=1:2
 ax=nexttile(tl);hold(ax,'on');grid(ax,'on');
 for ci=1:2
  Qs=At(ci).(obs{k});ii=cellfun(@(n)find(strcmp(At(ci).termNames,n)),bitsN);
  v=[0;Qs.Q(ii)]*sc(k);u=[0;Qs.U_conservative(ii)]*sc(k);
  errorbar(ax,(1:8)+(ci-1.5)*.22,v,u,mk{ci},'Color','k','MarkerFaceColor',fc{ci},'MarkerSize',5,'LineWidth',1,'CapSize',4,'DisplayName',T.(ternary(ci==1,'soft','stiff')));
  for m=1:8,fprintf(csv,'%s,%s,%d,%+.10g,%.4g\n',At(ci).contrast,obs{k},m,v(m),u(m));end
 end
 yline(ax,0,'k-','HandleVisibility','off');set(ax,'XTick',1:8,'XTickLabel',T.masks);xlim(ax,[.5 8.5]);
 xlabel(ax,T.masksLabel);ylabel(ax,T.(ternary(k==1,'FG','Fth')));title(ax,T.(sprintf('g6%c','a'+k-1)),'FontWeight','normal','FontSize',8.5);commaY(ax);
 if k==1,lg=legend(ax,'NumColumns',2,'FontSize',7.5);lg.Layout.Tile='south';lg.Title.String=strrep(T.consbar,' кожного сімейства','');lg.Title.FontWeight='normal';lg.Title.FontSize=7;end
end
fclose(csv);W.figures{end+1}=save_fig(f,out,'r1_g6_m4b_masks_grey.png');
f=figure('Visible','off','Units','centimeters','Position',[0 0 24 15]);tl=tiledlayout(f,2,2,'TileSpacing','compact','Padding','compact');
terms={'f_1','f_2','f_3','I_12','I_13','I_23','I_123'};pp={1,'G','g7a';2,'G','g7b';1,'theta','g7c';2,'theta','g7d'};
for k=1:4
 ax=nexttile(tl);hold(ax,'on');grid(ax,'on');Qs=At(pp{k,1}).(pp{k,2});s=sc(1+strcmp(pp{k,2},'theta'));
 ii=cellfun(@(n)find(strcmp(At(pp{k,1}).termNames,n)),terms);v=Qs.Q(ii)*s;u=Qs.U_conservative(ii)*s;cls=Qs.class(ii);
 for j=1:7
  if strcmp(cls{j},'RESOLVED_BOTH'),g=[.25 .25 .25];elseif strcmp(cls{j},'RESOLVED_PRIMARY_ONLY'),g=[.78 .78 .78];else,g=[1 1 1];end
  bar(ax,j,v(j),.6,'FaceColor',g,'EdgeColor','k','LineWidth',.8,'HandleVisibility','off');
 end
 errorbar(ax,1:7,v,u,'k.','CapSize',4,'HandleVisibility','off');yline(ax,0,'k-','HandleVisibility','off');
 set(ax,'XTick',1:7,'XTickLabel',T.terms);xlim(ax,[.4 7.6]);ylabel(ax,T.(ternary(strcmp(pp{k,2},'G'),'FG','Fth')));
 title(ax,T.(pp{k,3}),'FontWeight','normal','FontSize',8.5);commaY(ax);
 if k==1
  h1=bar(ax,nan,nan,'FaceColor',[.25 .25 .25],'EdgeColor','k');h2=bar(ax,nan,nan,'FaceColor',[.78 .78 .78],'EdgeColor','k');
  lg=legend(ax,[h1 h2],{T.both,T.primonly},'NumColumns',2,'FontSize',7.5);lg.Layout.Tile='south';lg.Title.String=strrep(T.consbar,' кожного сімейства','');lg.Title.FontWeight='normal';lg.Title.FontSize=7;
 end
end
W.figures{end+1}=save_fig(f,out,'r1_g7_m4b_decomposition_grey.png');
N.g6=struct('data','committed M4.B analysis LEDGER (original family)','scale','linear','limits','automatic','greyscale','filled circles = soft, open triangles = stiff; greyscale replacement of M4.B fig. Ж.2');
N.g7=struct('data','committed M4.B analysis LEDGER (original family)','scale','linear','limits','automatic per panel','greyscale','dark grey = resolved by both rules, light grey = primary only; greyscale replacement of M4.B fig. Ж.3');
N.colormap='monotonic greyscale (MATLAB gray), unsigned: dark = high; signed: dark = negative, light = positive, range 0.20-0.97';
N.font='Arial (all text Ukrainian; decimal comma; true minus sign)';
fid=fopen(fullfile(out,'FIGURE_NOTES.json'),'w');fwrite(fid,jsonencode(N,'PrettyPrint',true),'char');fclose(fid);
diary('off');
fl=dir(out);fl=fl(~[fl.isdir]);fid=fopen(fullfile(out,'SHA256SUMS.txt'),'w');
for k=1:numel(fl),if ~strcmp(fl(k).name,'SHA256SUMS.txt'),fprintf(fid,'%s *%s\n',lower(g2_sha256_file(fullfile(out,fl(k).name))),fl(k).name);end,end
fclose(fid);W.folder=out;fprintf('G2_M4B_R1_REPORT_DONE FOLDER=%s\n',strrep(out,repo,'<repo>'));
end

% =====================================================================
function r=read_case(rd,id,lc,field)
[r,h,ok]=g2_trajectory_record('read',fullfile(rd,['CASE_',id,'.mat']));
s=lc(strcmp({lc.case},id));assert(ok&&strcmpi(h,s(1).(field)),'G2M4BR1R:Record','R1 record %s does not match the analysis ledger.',id);
end

function r=read_orig(repo,of,led,id)
p=fullfile(repo,of.run,['CASE_',id,'.mat']);[r,h,ok]=g2_trajectory_record('read',p);
txt=lower(fileread(led));assert(ok&&contains(txt,[lower(h),' *',lower(regexprep([of.run,'/CASE_',id,'.mat'],'^outputs/',''))]),'G2M4BR1R:Orig','Original record %s not in the M4.B ledger.',id);
end

function sv=vm_centroid(D,r)
X=D.X6;T6=D.T6;M=size(T6,1);ph=r.phaseForAssembly;mats=r.mats;
Dp=zeros(3,3,2);for p=1:2,Dp(:,:,p)=g2_plane_D(mats(p));end
Dk=Dp(:,:,ph);c=(X(T6(:,1),:)+X(T6(:,2),:)+X(T6(:,3),:))/3;
s=g2_t6_point_stress(X,T6,r.K.u,Dk,(1:M).',c);
sv=sqrt(s(:,1).^2-s(:,1).*s(:,2)+s(:,2).^2+3*s(:,3).^2);
end

function unsigned_map(ax,D,v,lim,cen,th,P,ttl,T)
hold(ax,'on');axis(ax,'equal');T3=D.T6(:,1:3);
patch(ax,'Faces',T3,'Vertices',D.X6,'FaceVertexCData',min(max(v,lim(1)),lim(2)),'FaceColor','flat','EdgeColor','none');
colormap(ax,flipud(gray(256)*0.9+0.1));clim(ax,lim);
[xg,yg,Vg]=grid_of(D,v,cen,P);contour(ax,xg,yg,Vg,lim(1):0.5:lim(2),'k:','LineWidth',.5);
deco(ax,cen,th,P,ttl,T);
end

function signed_map(ax,D,v,lim,lev,cen,th,P,ttl,T)
hold(ax,'on');axis(ax,'equal');T3=D.T6(:,1:3);
patch(ax,'Faces',T3,'Vertices',D.X6,'FaceVertexCData',min(max(v,-lim),lim),'FaceColor','flat','EdgeColor','none');
colormap(ax,gray(256)*0.77+0.20);clim(ax,[-lim lim]);
[xg,yg,Vg]=grid_of(D,v,cen,P);
contour(ax,xg,yg,Vg,sort(lev(:)).','k-','LineWidth',.55);
contour(ax,xg,yg,Vg,-sort(lev(:),'descend').','k--','LineWidth',.55);
contour(ax,xg,yg,Vg,[0 0],'k-','LineWidth',1.3);
deco(ax,cen,th,P,ttl,T);
end

function [xg,yg,Vg]=grid_of(D,v,cen,P)
X=D.X6;T6=D.T6;c=(X(T6(:,1),:)+X(T6(:,2),:)+X(T6(:,3),:))/3;sel=c(:,1)>60&c(:,1)<250;
F=scatteredInterpolant(c(sel,1),c(sel,2),v(sel),'linear','none');
xg=70:0.5:240;yg=0:0.5:203.2;[XX,YY]=meshgrid(xg,yg);Vg=F(XX,YY);
for h=1:3,Vg(hypot(XX-cen(h,1),YY-cen(h,2))<6.35)=NaN;end
% mask a 0.75 mm band around the crack: no interpolation across the slit
Q=[XX(:),YY(:)];dmin=inf(size(Q,1),1);
for j=1:size(P,1)-1,a=P(j,:);b=P(j+1,:);ab=b-a;tt=max(0,min(1,((Q-a)*ab.')/(ab*ab.')));dmin=min(dmin,vecnorm(Q-(a+tt.*ab),2,2));end
Vg(reshape(dmin,size(XX))<0.75)=NaN;
end

function deco(ax,cen,th,P,ttl,T)
for j=1:3,plot(ax,cen(j,1)+19.05*cos(th),cen(j,2)+19.05*sin(th),'k-','LineWidth',.6);fill(ax,cen(j,1)+6.35*cos(th),cen(j,2)+6.35*sin(th),'w','EdgeColor','k');end
plot(ax,P(:,1),P(:,2),'k-','LineWidth',1.6);
xlim(ax,[70 240]);ylim(ax,[0 203.2]);xlabel(ax,T.x);ylabel(ax,T.y);title(ax,ttl,'FontWeight','normal','FontSize',8.5);box(ax,'on');comma(ax);
end

function fmt_cb(cb)
cb.TickLabels=arrayfun(@(v)strrep(strrep(sprintf('%.3g',v),'.',','),'-',char(8722)),cb.Ticks,'UniformOutput',false);
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
