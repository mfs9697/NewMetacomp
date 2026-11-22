function package=run_g2_lp1_report_batch(out)
% Read accepted records only. No mesher, assembly, solve, SIF recomputation or growth.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
root=fullfile(repo,'outputs/g2_lp1_matrix_paths_v1/run_20261122_lp1_v1');
if nargin==0,out=fullfile(repo,'reports/G2/LP1_20261122_v3');end
assert(~isfolder(out),'G2LP1Report:Exists','Never overwrite a review package.');mkdir(out);
ids={'H','stiff13','soft2','soft1'};labels={'Однорідний матеріал','Жорсткі кільця 1, 3','М’яке кільце 2','М’яке кільце 1'};
states=cell(4,5);solutions=cell(4,5);items={};q=0;
C=[152.4 69.85;152.4 120.65;152.4 171.45];
for c=1:4
 for k=0:4
  sd=fullfile(root,ids{c},sprintf('S%d',k));sf=fullfile(sd,'STATE.mat');if ~isfile(sf),continue,end
  [St,stsha,ok]=g2_trajectory_record('read',sf);assert(ok);
  [Sol,sha,ok]=g2_trajectory_record('read',fullfile(sd,'SOLUTION.mat'));assert(ok&&strcmpi(sha,St.solutionSHA256));
  [Ph,sha,ok]=g2_trajectory_record('read',fullfile(sd,'PHASE.mat'));assert(ok&&strcmpi(sha,St.phaseSHA256));
  assert(strcmpi(g2_sha256_file(fullfile(sd,'MESH.mat')),St.meshSHA256));
  K=Sol.K;states{c,k+1}=St;solutions{c,k+1}=K;tip=St.polyline_mm(end,:);
  ring=vecnorm(C-tip,2,2).'-19.05;hole=ring+12.7;plate=[tip(1),508-tip(1),tip(2),203.2-tip(2)];
  p=St.polyline_mm;seg=inf(1,3);
  a=p(end-1,:);b=p(end,:);for h=1:3,v=b-a;u=max(0,min(1,dot(C(h,:)-a,v)/dot(v,v)));seg(h)=norm(C(h,:)-(a+u*v))-19.05;end
  if k==0,previous=NaN;else,previous=St.clearance.metrics.nonadjacentSegment_mm;end
  q=q+1;V=variants(K);Kv=hypot(K.KI,K.KII);
  item=struct('caseId',ids{c},'state',k,'arc_mm',St.arc_mm,'tip_x_mm',tip(1),'tip_y_mm',tip(2), ...
   'KI_MPa_sqrt_m_per_kN',K.KI_MPa_sqrt_m_per_kN,'KII_MPa_sqrt_m_per_kN',K.KII_MPa_sqrt_m_per_kN, ...
   'G_N_per_mm_at_1N',St.G,'J_N_per_mm_at_1N',K.J,'MTS_local_deg',St.MTS_deg,'heading_deg',atan2d(St.tangent(2),St.tangent(1)), ...
   'mode_mix_deg',atan2d(K.KII,K.KI),'COD_EDI_fraction_Kref',max(abs([K.KI-K.KI_COD,K.KII-K.KII_COD]))/Kv, ...
   'quadrature_fraction_Kref',max(abs(K.EDI4x4-[K.KI,K.KII]))/Kv,'contour_fraction_Kref',max(max(K.EDI_all(:,1:2))-min(K.EDI_all(:,1:2)))/Kv, ...
   'J_identity_relative',abs(K.J/St.G-1),'residual',K.relativeResidual,'energy_identity_relative',K.energyIdentityRel, ...
   'strain_energy_Nmm_at_1N',K.strainEnergy_per_thickness*12.7,'active_area_mm2',K.activeArea_mm2, ...
   'compliance_mm_per_N_point_load_sensitive',K.compliance_mm_per_N,'CMOD_mm',K.CMOD_mm, ...
   'tip_ring1_mm',ring(1),'tip_ring2_mm',ring(2),'tip_ring3_mm',ring(3),'tip_hole_min_mm',min(hole), ...
   'segment_ring_min_mm',min(seg),'guide_ring_min_margin_mm',min(ring)-15,'guide_plate_min_margin_mm',min(plate)-15, ...
   'q_ring_min_margin_mm',min(ring)-2.6-1,'tip_plate_min_mm',min(plate),'nonadjacent_segment_mm',previous, ...
   'ring1_energy_Nmm',K.ringStrainEnergy_per_thickness(2)*12.7,'ring2_energy_Nmm',K.ringStrainEnergy_per_thickness(3)*12.7, ...
   'ring3_energy_Nmm',K.ringStrainEnergy_per_thickness(4)*12.7,'matrix_elements',nnz(Ph.owner==0),'ring1_elements',nnz(Ph.owner==1), ...
   'ring2_elements',nnz(Ph.owner==2),'ring3_elements',nnz(Ph.owner==3),'mesh_T3',numel(Ph.owner),'stateSHA256',lower(stsha), ...
   'KI_estimator_spread_per_kN',max(abs(V.K(:,1)-K.KI))*sqrt(1000),'KII_estimator_spread_per_kN',max(abs(V.K(:,2)-K.KII))*sqrt(1000));
  items{q}=item; %#ok<AGROW>
 end
end
data=[items{:}];
% Matched-arclength comparisons, with primary and conservative indicators separate.
for i=1:numel(data)
 c=find(strcmp(ids,data(i).caseId));k=data(i).state;
 H=states{1,k+1};St=states{c,k+1};KH=solutions{1,k+1};K=solutions{c,k+1};
 assert(~isempty(H),'G2LP1Report:H','Matched H state is required.');
 d=St.polyline_mm(end,:)-H.polyline_mm(end,:);data(i).lateral_offset_mm=dot(d,H.normal);data(i).tip_separation_mm=norm(d);
 A=variants(K);B=variants(KH);rat=A.G./B.G;theta=A.theta-B.theta;
 data(i).F_G=rat(1)-1;data(i).U_primary_FG_raw=max(abs(rat-rat(1)));
 % Preserve M3's registered 1e-5 cross-mesh reference floor. It is not a
 % newly demonstrated bound for these remeshed trajectories.
 data(i).U_primary_FG=max(data(i).U_primary_FG_raw,1e-5*(k>0&&c>1));
 data(i).U_cons_FG=rat(1)*(abs(A.G(end)-A.G(1))/A.G(1)+abs(B.G(end)-B.G(1))/B.G(1));
 data(i).F_theta_local_deg=theta(1);data(i).U_primary_theta_deg=max(abs(theta-theta(1)));
 data(i).U_cons_theta_deg=abs(A.theta(end)-A.theta(1))+abs(B.theta(end)-B.theta(1));
 up=0;uc=0;
 for j=0:k-1
  aa=variants(solutions{c,j+1});bb=variants(solutions{1,j+1});dt=aa.theta-bb.theta;
  up=up+4*(k-j)*deg2rad(max(abs(dt-dt(1))));
  uc=uc+4*(k-j)*deg2rad(abs(aa.theta(end)-aa.theta(1))+abs(bb.theta(end)-bb.theta(1)));
 end
 data(i).U_primary_separation_mm=up;data(i).U_cons_separation_mm=uc;
 data(i).FG_primary_resolved=abs(data(i).F_G)>2*data(i).U_primary_FG&&sign(rat(end)-1)==sign(data(i).F_G);
 data(i).FG_conservative_resolved=abs(data(i).F_G)>data(i).U_cons_FG&&sign(rat(end)-1)==sign(data(i).F_G);
 if c==1
  data(i).U_cons_FG=0;data(i).U_cons_theta_deg=0;data(i).U_cons_separation_mm=0;
 end
end
package=struct('terminal','REVIEW_STOP_LP1','conditionalOnly',true,'data',data,'states',{states},'sourceRoot',strrep(root,repo,'<repo>'));
fid=fopen(fullfile(out,'LP1_COMPARISON.json'),'w','n','UTF-8');fprintf(fid,'%s',jsonencode(package,'PrettyPrint',true));fclose(fid);
T=struct2table(data);writetable(T,fullfile(out,'LP1_COMPARISON.csv'));
% Export detailed SIF variants, phase/energy/gate diagnostics without displacement arrays.
detail=cell(4,5);for c=1:4,for k=1:5
 if isempty(solutions{c,k}),continue,end
 z=solutions{c,k};z=rmfield(z,intersect(fieldnames(z),{'u','elementStrainEnergy_per_thickness','chordTractions','fullPolyOpening_mm','wholeCrackArclength_mm'}));detail{c,k}=z;
end,end
fid=fopen(fullfile(out,'LP1_SIF_ENERGY_DIAGNOSTICS.json'),'w','n','UTF-8');fprintf(fid,'%s',jsonencode(detail,'PrettyPrint',true));fclose(fid);
set(groot,'defaultAxesFontName','Arial','defaultTextFontName','Arial','defaultAxesFontSize',11,'defaultTextInterpreter','none','defaultLegendInterpreter','none');
styles={'-o','--s','-.^',':d'};grey=[0 .25 .5 .1];
% Geometry is never inferred from a frozen reference: use only accepted polylines.
f=figure('Visible','off','Color','w','Position',[50 50 1200 540]);tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
for panel=1:2
 nexttile;hold on;rectangle('Position',[0 0 508 203.2],'EdgeColor','k');
 for h=1:3,rectangle('Position',[C(h,:)-19.05 38.1 38.1],'Curvature',[1 1],'FaceColor',[.91 .91 .91],'EdgeColor',[.3 .3 .3]);rectangle('Position',[C(h,:)-6.35 12.7 12.7],'Curvature',[1 1],'FaceColor','w','EdgeColor','k');end
 hh=gobjects(4,1);for c=1:4,last=find(~cellfun(@isempty,states(c,:)),1,'last');p=states{c,last}.polyline_mm;hh(c)=plot(p(:,1),p(:,2),styles{c},'Color',grey(c)*[1 1 1],'LineWidth',1.5,'MarkerSize',5,'MarkerFaceColor','w');end
 axis equal;box on;xlabel('Координата x, мм');ylabel('Координата y, мм');
 if panel==1,xlim([0 508]);ylim([0 203.2]);title('Пластина, отвори та номінальні кільця');legend(hh,labels,'Location','southoutside');
 else,xlim([99.5 110]);ylim([24 43]);title('Умовні траєкторії: завершено на S4');end
end
finish(f,'LP1_paths_UA');
f=figure('Visible','off','Color','w','Position',[50 50 1100 480]);tiledlayout(1,2,'Padding','compact');
panelplot('KI_MPa_sqrt_m_per_kN','КІН першої моди, МПа·√м/кН','Знаковий коефіцієнт першої моди');
panelplot('KII_MPa_sqrt_m_per_kN','КІН другої моди, МПа·√м/кН','Знаковий коефіцієнт другої моди');finish(f,'LP1_signed_SIF_UA');
f=figure('Visible','off','Color','w','Position',[50 50 1100 480]);tiledlayout(1,2,'Padding','compact');
panelplot('G_N_per_mm_at_1N','Швидкість вивільнення енергії, Н/мм','Енергія за навантаження 1 Н');
panelplot('F_G','Відносна зміна щодо однорідного матеріалу','Порівняння за однакової довжини');finish(f,'LP1_energy_UA');
f=figure('Visible','off','Color','w','Position',[50 50 1100 480]);tiledlayout(1,2,'Padding','compact');
panelplot('MTS_local_deg','Місцевий кут повороту, градуси','Умовний напрям за критерієм МТС');
panelplot('lateral_offset_mm','Поперечне відхилення, мм','Додатний напрям — нормаль до еталонного шляху');finish(f,'LP1_turn_offset_UA');
f=figure('Visible','off','Color','w','Position',[50 50 1200 700]);tiledlayout(2,2,'Padding','compact');
panelplot('tip_ring1_mm','Відстань від вершини, мм','Вершина до найближчого кільця');
panelplot('segment_ring_min_mm','Відстань від сегмента, мм','Повний останній сегмент до кілець');
panelplot('guide_ring_min_margin_mm','Запас відстані, мм','Напрямна радіуса 15 мм');
panelplot('q_ring_min_margin_mm','Запас відстані, мм','Область інтегрування та буфер 1 мм');finish(f,'LP1_clearances_UA');
f=figure('Visible','off','Color','w','Position',[50 50 1100 480]);tiledlayout(1,2,'Padding','compact');
nexttile;hold on;
for c=2:4
 idx=strcmp({data.caseId},ids{c});d=data(idx);x=[d.arc_mm];y=100*[d.F_G];
 errorbar(x,y,100*[d.U_cons_FG],styles{c},'Color',grey(c)*[1 1 1],'LineWidth',1,'MarkerSize',5);
end
yline(0,'k-');xlabel('Довжина тріщини, мм');ylabel('Зміна енергії, %');title('Консервативна оцінка невизначеності');box on;legend(labels(2:4),'Location','best');
nexttile;hold on;
for c=2:4,idx=strcmp({data.caseId},ids{c});d=data(idx);plot([d.arc_mm],100*[d.U_primary_FG],styles{c},'Color',grey(c)*[1 1 1],'LineWidth',1.4);end
xlabel('Довжина тріщини, мм');ylabel('Оцінка невизначеності, відсоткові пункти');title('Первинна узгодженість оцінювачів');box on;finish(f,'LP1_uncertainty_UA');
fprintf('G2_LP1_REPORT states=%d output=%s\n',numel(data),out);
 function panelplot(field,yl,ttl)
  nexttile;hold on;hh=gobjects(4,1);
  for cc=1:4,idx=strcmp({data.caseId},ids{cc});d=data(idx);hh(cc)=plot([d.arc_mm],[d.(field)],styles{cc},'Color',grey(cc)*[1 1 1],'LineWidth',1.4,'MarkerSize',5,'MarkerFaceColor','w');end
  yline(0,'k-','HandleVisibility','off');xline(41.4,':','Межа пілота','HandleVisibility','off');xlabel('Довжина тріщини, мм');ylabel(yl);title(ttl);box on;legend(hh,labels,'Location','best');
 end
 function finish(fig,name)
  exportgraphics(fig,fullfile(out,[name,'.pdf']),'ContentType','vector');
  exportgraphics(fig,fullfile(out,[name,'.png']),'Resolution',450);close(fig);
 end
end
function V=variants(K)
v=[K.EDI_all(:,1:2);K.EDI4x4;K.KI_COD,K.KII_COD];th=zeros(size(v,1),1);
for k=1:size(v,1),m=g2_mts_direction(v(k,1),v(k,2));th(k)=m.theta_deg;end
V=struct('K',v,'G',sum(v.^2,2)/K.Ep_matrix,'theta',th);
end
