function W = run_g2_m3_report_batch(analysisDir)
%RUN_G2_M3_REPORT_BATCH  Figures from a SAVED Issue #39 analysis run and the two chains (read only).
%
%  W = run_g2_m3_report_batch(analysisDir)
% Writes a NEW outputs/g2_m3_report/run_<time>/: three crack paths and lateral offsets with
% U_sep; R_direct / R_path / R_total versus s with both uncertainty verdicts; G and local MTS
% versus s; a band / q-support snapshot of a new material mesh. No solve.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));analysisDir=char(analysisDir);
L=jsondecode(fileread(fullfile(analysisDir,'LEDGER.json')));assert(strcmp(L.status,'GO'),'G2M3R:NotGO','Analysis status %s.',L.status);
outRoot=fullfile(repo,'outputs','g2_m3_report');if ~exist(outRoot,'dir'),mkdir(outRoot);end
folder=fullfile(outRoot,['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);assert(~exist(folder,'dir'));mkdir(folder);
diary(fullfile(folder,'m3_report_console.log'));cl=onCleanup(@()diary('off')); %#ok<NASGU>
softC=[.16 .42 .72];stiffC=[.85 .45 .10];hC=[.30 .30 .30];ink=[.2 .2 .2];reC=[.55 .75 .78];matC=[.94 .94 .94];
mats={'soft','stiff'};cc={softC,stiffC};s=[25.4 29.4 33.4];
PH=L.homogeneousPolylines;if ~iscell(PH),PH=num2cell(PH,[2 3]);end
% ---------- figure 1: paths and lateral offsets
f=figure('Visible','off','Position',[0 0 1300 620],'Color','w');
ax=axes(f,'Units','pixels','Position',[70 70 520 500]);hold(ax,'on');
plot(ax,PH{3}(:,1),PH{3}(:,2),'-o','Color',hC,'LineWidth',1.6,'MarkerSize',5,'MarkerFaceColor',hC);
for i=1:2
 P=L.results.(mats{i}).polylines;P3=P{3};if iscell(P3),P3=P3{1};end
 plot(ax,P3(:,1),P3(:,2),'-s','Color',cc{i},'LineWidth',1.3,'MarkerSize',5);
end
axis(ax,'equal');xlim(ax,[100.6 104.4]);ylim(ax,[24 34.2]);box(ax,'on');xlabel(ax,'x (mm)');ylabel(ax,'y (mm)');
legend(ax,{'homogeneous \Gamma_H','soft \Gamma_{soft}','stiff \Gamma_{stiff}'},'Location','northwest','Box','off');
title(ax,'Three numerical paths, two 4-mm increments (conditional on assumed advance)','FontWeight','normal');
ax2=axes(f,'Units','pixels','Position',[700 70 560 500]);hold(ax2,'on');
for i=1:2
 sp=L.results.(mats{i}).separation;
 lat=[0,[sp.lateral_mm]];U=[0,[sp.U_sep_mm]];Uc=[0,[sp.U_sep_cons_mm]];
 fill(ax2,[s fliplr(s)],[lat-Uc fliplr(lat+Uc)],cc{i},'FaceAlpha',.10,'EdgeColor','none','HandleVisibility','off');
 errorbar(ax2,s,lat,2*U,'-o','Color',cc{i},'MarkerFaceColor',cc{i},'LineWidth',1.4,'CapSize',8);
 for k=2:3,text(ax2,s(k)+.2,lat(k),sprintf('%+.4f mm',lat(k)),'Color',cc{i},'FontSize',9);end
end
yline(ax2,0,':','Color',ink);set(ax2,'XTick',s);xlim(ax2,[24.5 35.5]);
xlabel(ax2,'arclength s (mm)');ylabel(ax2,'signed lateral offset from \Gamma_H tip (mm), + = left of \Gamma_H');
legend(ax2,{'soft','stiff'},'Box','off','Location','northwest');
title(ax2,'Tip offset from the homogeneous path (bars 2U_{sep}; shading conservative)','FontWeight','normal');
exportgraphics(f,fullfile(folder,'m3_paths_offsets.png'),'Resolution',180);exportgraphics(f,fullfile(folder,'m3_paths_offsets.pdf'),'ContentType','vector');close(f);
% ---------- figure 2: R_direct, R_path, R_total
f=figure('Visible','off','Position',[0 0 1300 560],'Color','w');tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
for i=1:2
 a=nexttile(tl);hold(a,'on');rows=L.results.(mats{i}).rows;
 Rd=arrayfun(@(r)r.R_direct.R,rows);Rp=arrayfun(@(r)r.R_path.R,rows);Rt=arrayfun(@(r)r.R_total.R,rows);
 Ud=arrayfun(@(r)r.R_direct.U,rows);Up=arrayfun(@(r)r.R_path.U,rows);Ut=arrayfun(@(r)r.R_total.U,rows);Utc=arrayfun(@(r)r.R_total.U_cons,rows);
 Rd=Rd(:).';Rp=Rp(:).';Rt=Rt(:).';Ud=Ud(:).';Up=Up(:).';Ut=Ut(:).';Utc=Utc(:).';   % jsondecode returns column struct arrays
 fill(a,[s fliplr(s)],[Rt-Utc fliplr(Rt+Utc)],cc{i},'FaceAlpha',.08,'EdgeColor','none','HandleVisibility','off');
 errorbar(a,s,Rd,2*Ud,'--o','Color',hC,'MarkerFaceColor','w','LineWidth',1.2);
 errorbar(a,s,Rp,2*Up,':d','Color',cc{i},'MarkerFaceColor','w','LineWidth',1.4);
 errorbar(a,s,Rt,2*Ut,'-s','Color',cc{i},'MarkerFaceColor',cc{i},'LineWidth',1.6);
 for k=1:3,text(a,s(k)+.25,Rt(k),sprintf('%.5f',Rt(k)),'Color',cc{i},'FontSize',8.5);text(a,s(k)+.25,Rp(k),sprintf('%.5f',Rp(k)),'Color',cc{i},'FontSize',8.5);end
 yline(a,1,':','Color',ink);set(a,'XTick',s);xlim(a,[24.5 35]);xlabel(a,'arclength s (mm)');ylabel(a,'ratio');
 legend(a,{'R_{direct} = G_M[\Gamma_H]/G_H[\Gamma_H]','R_{path} = G_M[\Gamma_M]/G_M[\Gamma_H]','R_{total} = G_M[\Gamma_M]/G_H[\Gamma_H]'},'Box','off','Location','best');
 title(a,sprintf('%s bands (E_r/E_m = %g): bars 2U primary, shading conservative on R_{total}',mats{i},2^(2*i-3)),'FontWeight','normal');
end
exportgraphics(f,fullfile(folder,'m3_ratios.png'),'Resolution',180);exportgraphics(f,fullfile(folder,'m3_ratios.pdf'),'ContentType','vector');close(f);
% ---------- figure 3: G and local MTS
f=figure('Visible','off','Position',[0 0 1300 560],'Color','w');tl=tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
a=nexttile(tl);hold(a,'on');r0=L.results.soft.rows;
plot(a,s,1e9*[r0.G_H],'-o','Color',hC,'MarkerFaceColor',hC,'LineWidth',1.5);
for i=1:2
 rows=L.results.(mats{i}).rows;
 plot(a,s,1e9*[rows.G_MH],'--o','Color',cc{i},'LineWidth',1.1);plot(a,s,1e9*[rows.G_MM],'-s','Color',cc{i},'MarkerFaceColor',cc{i},'LineWidth',1.5);
end
set(a,'XTick',s);xlim(a,[24.5 34.3]);xlabel(a,'arclength s (mm)');ylabel(a,'G at P = 1 N (10^{-9} N/mm)');
legend(a,{'G_H[\Gamma_H]','soft on \Gamma_H','soft own path','stiff on \Gamma_H','stiff own path'},'Box','off','Location','northwest');
title(a,'Energy-release rate (EDI)','FontWeight','normal');
a=nexttile(tl);hold(a,'on');
plot(a,s,[r0.theta_H_deg],'-o','Color',hC,'MarkerFaceColor',hC,'LineWidth',1.5);
for i=1:2
 rows=L.results.(mats{i}).rows;
 plot(a,s,[rows.theta_MH_deg],'--o','Color',cc{i},'LineWidth',1.1);plot(a,s,[rows.theta_MM_deg],'-s','Color',cc{i},'MarkerFaceColor',cc{i},'LineWidth',1.5);
end
set(a,'XTick',s);xlim(a,[24.5 34.3]);xlabel(a,'arclength s (mm)');ylabel(a,'\theta_{MTS} in each state''s own terminal frame (deg)');
legend(a,{'H','soft on \Gamma_H','soft own path','stiff on \Gamma_H','stiff own path'},'Box','off','Location','southeast');
title(a,'Local MTS forecast at each tip (next turn, not executed beyond M2)','FontWeight','normal');
exportgraphics(f,fullfile(folder,'m3_G_theta.png'),'Resolution',180);close(f);
% ---------- figure 4: band / q snapshot of the soft M2 mesh
sd=fullfile(repo,'outputs','g2_material_trajectories_v1','chain_soft_v1','STEP_002');
[Ph,~,ok]=g2_trajectory_record('read',fullfile(sd,'PHASE_MAP.mat'));assert(ok,'G2M3R:Phase','phase record');
D=load(fullfile(sd,'KINKED_GEOMETRY_ONLY_candidate.mat'));T3=D.T6(:,1:3);tip=D.crackPolyline(end,:);
f=figure('Visible','off','Position',[0 0 1300 560],'Color','w');
ax=axes(f,'Units','pixels','Position',[60 60 700 460]);hold(ax,'on');
patch(ax,'Faces',T3(Ph.phase==1,:),'Vertices',D.X6,'FaceColor',matC,'EdgeColor',[.8 .8 .8],'LineWidth',.1);
patch(ax,'Faces',T3(Ph.phase==2,:),'Vertices',D.X6,'FaceColor',reC,'EdgeColor',[.5 .66 .7],'LineWidth',.1);
plot(ax,D.crackPolyline(:,1),D.crackPolyline(:,2),'-','Color',[.75 .12 .12],'LineWidth',1.6);
axis(ax,'equal');xlim(ax,[60 200]);ylim(ax,[0 110]);box(ax,'on');xlabel(ax,'x (mm)');ylabel(ax,'y (mm)');
title(ax,sprintf('Soft M2 mesh: new phase map, chords %s, tip-to-band %.2f mm',mat2str(Ph.verifierValues.chordsPerCircle(:).'),Ph.verifierValues.reinforcementNodeMinDistanceToTip_mm),'FontWeight','normal');
ax2=axes(f,'Units','pixels','Position',[820 60 440 460]);hold(ax2,'on');
rE=min(reshape(vecnorm(D.X6(D.T6(:),:)-tip,2,2),[],6),[],2);sel=all(abs(D.X6(T3(:,1),:)-tip)<5,2);
patch(ax2,'Faces',T3(sel&Ph.phase==1,:),'Vertices',D.X6,'FaceColor',matC,'EdgeColor',[.7 .7 .7],'LineWidth',.1);
patch(ax2,'Faces',T3(rE<2.6,:),'Vertices',D.X6,'FaceColor',[.98 .88 .55],'EdgeColor',[.75 .62 .3],'LineWidth',.1);
plot(ax2,D.crackPolyline(:,1),D.crackPolyline(:,2),'-','Color',[.75 .12 .12],'LineWidth',1.4);
axis(ax2,'equal');xlim(ax2,tip(1)+[-4 4]);ylim(ax2,tip(2)+[-4 4]);box(ax2,'on');xlabel(ax2,'x (mm)');
title(ax2,'q support (r < 2.6 mm): matrix only','FontWeight','normal');
exportgraphics(f,fullfile(folder,'m3_phase_snapshot.png'),'Resolution',180);close(f);
W=struct('analysis',strrep(analysisDir,repo,'<repo>'),'figures',{{'m3_paths_offsets','m3_ratios','m3_G_theta','m3_phase_snapshot'}});
fprintf('G2_M3_REPORT_DONE %s\n',strrep(folder,repo,'<repo>'));
end
