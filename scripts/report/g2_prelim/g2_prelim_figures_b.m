function g2_prelim_figures_b(repo,outDir)
%G2_PRELIM_FIGURES_B  Near-tip zones, ring attribution and S4 decomposition figures of the G2 preliminary report.
% Plotting only, from committed evidence (no FEM, no new calculations beyond unit conversions):
%   F03  schematic of the near-tip zones (constants of the committed near-tip protocol, true scale)
%   F06_1 matlab/g2/evidence/m4b_20261121/analysis/cases_16_logical.csv
%   F06_2 docs/research/G2_G1_evidence/G1_FIELD_EVIDENCE.json
%   F07_1 docs/research/G2_M5_X6_evidence/campaign_20261125/M5X6_ANALYSIS.json
% Nothing is written outside outDir.
C = g2_prelim_fig_common();
fig_zones(C,outDir);
fig_rings_bars(C,repo,outDir);
fig_rings_energy(C,repo,outDir);
fig_decomposition(C,repo,outDir);
end

%% =================================================================== F03: near-tip zones
function fig_zones(C,outDir)
th = linspace(0,2*pi,721);
rGuide = 15; rCore = 3.0; rCollar = 3.3; qIn = 0.4; qOut = 2.6; codA = 0.1; codB = 1.5; rDisk = 0.833;
blue = [.05 .30 .70]; dark = [.25 .25 .25]; orng = [.80 .50 .05];
f = C.newfig(16,10.3);
% ---------------- (a) region +-18 mm
ax = axes(f,'Position',[0.075 0.27 0.385 0.598]); hold(ax,'on');
fill(ax,rGuide*cos(th),rGuide*sin(th),[.965 .975 1],'EdgeColor',[.15 .25 .60],'LineStyle','--','LineWidth',1);
fill(ax,rCollar*cos(th),rCollar*sin(th),[.62 .62 .62],'EdgeColor',dark,'LineWidth',.6);
fill(ax,rCore*cos(th),rCore*sin(th),[.93 .93 .93],'EdgeColor',dark,'LineWidth',.6);
plot(ax,[-18 0],[0 0],'k-','LineWidth',1.5);
plot(ax,0,0,'ko','MarkerSize',3,'MarkerFaceColor','k');
rectangle(ax,'Position',[-3.6 -3.6 7.2 7.2],'EdgeColor',blue,'LineStyle','--','LineWidth',.8);
text(ax,4.3,3.6,'(б)','Color',blue,'FontSize',9,'VerticalAlignment','middle');
text(ax,0,16.6,'допоміжна напрямна область 15 мм','FontSize',7.5,'HorizontalAlignment','center','VerticalAlignment','middle');
text(ax,-9,1.6,'тріщина S0','FontSize',8,'HorizontalAlignment','center','VerticalAlignment','bottom');
plot(ax,[rCollar*cosd(-45) 3.9],[rCollar*sind(-45) -7.0],'-','Color',dark,'LineWidth',.5);
text(ax,4.2,-7.0,{'комір,','{\itr} = 3,3 мм'},'FontSize',8,'VerticalAlignment','middle');
axis(ax,'equal'); xlim(ax,[-18 18]); ylim(ax,[-18 18]); box(ax,'on');
ax.XTick = -15:5:15; ax.YTick = -15:5:15;
xlabel(ax,'{\itx_t}, мм'); ylabel(ax,'{\itx_n}, мм'); C.dec(ax); C.panel(ax,'(а) область ±18 мм навколо вершини');
% ---------------- (b) zoom +-3.6 mm
ax = axes(f,'Position',[0.575 0.27 0.385 0.598]); hold(ax,'on');
tp = th(1:end-1);   % no repeated end vertex for polyshape
polyOut = [rCollar*cos(tp); rCollar*sin(tp)]; polyIn = [rCore*cos(fliplr(tp)); rCore*sin(fliplr(tp))];
fill(ax,rCore*cos(th),rCore*sin(th),[.93 .93 .93],'EdgeColor','none');
pg = polyshape({polyOut(1,:),polyIn(1,:)},{polyOut(2,:),polyIn(2,:)});
plot(ax,pg,'FaceColor',[.62 .62 .62],'FaceAlpha',1,'EdgeColor',dark,'LineWidth',.6);
plot(ax,rCore*cos(th),rCore*sin(th),'-','Color',dark,'LineWidth',.6);
qo = [qOut*cos(tp); qOut*sin(tp)]; qi = [qIn*cos(fliplr(tp)); qIn*sin(fliplr(tp))];
pq = polyshape({qo(1,:),qi(1,:)},{qo(2,:),qi(2,:)});
plot(ax,pq,'FaceColor',[1 .84 .50],'FaceAlpha',1,'EdgeColor',orng,'LineWidth',.7);
plot(ax,rDisk*cos(th),rDisk*sin(th),'k:','LineWidth',1);
plot(ax,[-3.6 0],[0 0],'k-','LineWidth',1.5);
plot(ax,[-codB -codA],[0 0],'-','Color',blue,'LineWidth',4.5);
plot(ax,[-codB -codB],[-.18 .18],'-','Color',blue,'LineWidth',.8); plot(ax,[-codA -codA],[-.18 .18],'-','Color',blue,'LineWidth',.8);
plot(ax,0,0,'ko','MarkerSize',3.5,'MarkerFaceColor','k');
quiver(ax,0,0,1.25,0,0,'k','LineWidth',1.1,'MaxHeadSize',.5,'AutoScale','off');
quiver(ax,0,0,0,1.25,0,'k','LineWidth',1.1,'MaxHeadSize',.5,'AutoScale','off');
text(ax,1.40,0.02,'{\itt}','FontSize',9.5,'VerticalAlignment','middle');
text(ax,0,1.43,'{\itn}','FontSize',9.5,'HorizontalAlignment','center','VerticalAlignment','bottom');
plot(ax,[0 0],[-0.08 -1.02],'-','Color',[.2 .2 .2],'LineWidth',.5);
text(ax,0,-1.2,'вершина','FontSize',8,'HorizontalAlignment','center','VerticalAlignment','middle');
axis(ax,'equal'); xlim(ax,[-3.6 3.6]); ylim(ax,[-3.6 3.6]); box(ax,'on');
ax.XTick = -3:1:3; ax.YTick = -3:1:3;
xlabel(ax,'{\itx_t}, мм'); ylabel(ax,'{\itx_n}, мм'); C.dec(ax); C.panel(ax,'(б) околиця вершини, ±3,6 мм');
% ---------------- key
lgax = axes(f,'Position',[0.075 0.0 0.89 0.16]); hold(lgax,'on'); axis(lgax,'off'); xlim(lgax,[0 1]); ylim(lgax,[0 1]);
xc = [0.0 0.52]; yr = [.82 .50 .18]; sw = 0.04; sh = 0.2;
swatch = @(x,y,fc,ec) rectangle(lgax,'Position',[x y-sh/2 sw sh],'FaceColor',fc,'EdgeColor',ec,'LineWidth',.6);
swatch(xc(1),yr(1),[.93 .93 .93],dark);   text(lgax,xc(1)+0.055,yr(1),'захищене ядро: {\itr} ≤ 3,0 мм','FontSize',8,'VerticalAlignment','middle');
swatch(xc(1),yr(2),[.62 .62 .62],dark);   text(lgax,xc(1)+0.055,yr(2),'комір: 3,0–3,3 мм','FontSize',8,'VerticalAlignment','middle');
swatch(xc(1),yr(3),[1 .84 .50],orng);     text(lgax,xc(1)+0.055,yr(3),'основна область інтегрування {\itq}: 0,4–2,6 мм','FontSize',8,'VerticalAlignment','middle');
plot(lgax,xc(2)+[0 sw],[yr(1) yr(1)],'-','Color',blue,'LineWidth',4.5); text(lgax,xc(2)+0.055,yr(1),'вікно COD: 0,1–1,5 мм за вершиною','FontSize',8,'VerticalAlignment','middle');
plot(lgax,xc(2)+[0 sw],[yr(2) yr(2)],'k:','LineWidth',1.2); text(lgax,xc(2)+0.055,yr(2),'внутрішній регулярний диск: {\itr} = 0,833 мм','FontSize',8,'VerticalAlignment','middle');
text(lgax,xc(2),yr(3),'схема в масштабі; перше кільце елементів — 0,0417 мм','FontSize',7.5,'VerticalAlignment','middle','Color',[.3 .3 .3]);
C.save(f,outDir,'F03_zony_bilia_vershyny');
end

%% =================================================================== F06_1: single rings, M4B
function fig_rings_bars(C,repo,outDir)
file = fullfile(repo,'matlab','g2','evidence','m4b_20261121','analysis','cases_16_logical.csv');
opts = detectImportOptions(file); opts = setvartype(opts,{'mask','bits','physical_case'},'string');
T = readtable(file,opts);
bits = {'100','010','001','111'}; lam = [0.5 2];
FG = zeros(4,2); FT = zeros(4,2);
for k=1:4
    for j=1:2
        r = T(abs(T.contrast-lam(j))<1e-12 & T.bits==bits{k},:);
        assert(height(r)==1,'case %s lambda %g not unique',bits{k},lam(j));
        FG(k,j) = 100*r.F_G; FT(k,j) = r.F_theta_deg;
    end
end
f = C.newfig(16,7.2); tl = tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
lab = {'кільце 1','кільце 2','кільце 3','усі три'};
ax = nexttile(tl); hold(ax,'on');
b = bar(ax,1:4,FG,'grouped','BarWidth',.82); styleBars(b,C);
valueLabels(ax,b,FG,7.5,0);
yline(ax,0,'k-'); ax.XTick = 1:4; ax.XTickLabel = lab; ax.FontSize = 8.5; xlim(ax,[.4 4.6]); ylim(ax,[-5.6 6.1]); box(ax,'on'); grid(ax,'on'); ax.XGrid = 'off';
ylabel(ax,'{\itF_G}, %'); C.dec(ax,'y'); C.panel(ax,'(а) рушійна сила {\itF_G}');
ax1 = ax; b1 = b;
ax = nexttile(tl); hold(ax,'on');
b = bar(ax,1:4,FT,'grouped','BarWidth',.82); styleBars(b,C);
valueLabels(ax,b,FT,7.5,0);
yline(ax,0,'k-'); ax.XTick = 1:4; ax.XTickLabel = lab; ax.FontSize = 8.5; xlim(ax,[.4 4.6]); ylim(ax,[-1.75 1.9]); box(ax,'on'); grid(ax,'on'); ax.XGrid = 'off';
ylabel(ax,'{\itF}_θ, °'); C.dec(ax,'y'); C.panel(ax,'(б) кут МКН {\itF}_θ');
lg = legend(ax1,b1,{'м’які кільця ({\itλ} = 0,5)','жорсткі кільця ({\itλ} = 2)'},'Orientation','horizontal','FontSize',8.5,'Box','off'); lg.Layout.Tile = 'south';
C.save(f,outDir,'F06_1_vnesky_kilets');
end

function styleBars(b,C)
cols = {C.softCol,C.stiffCol};
for k=1:numel(b), b(k).FaceColor = cols{k}; b(k).EdgeColor = [.25 .25 .25]; b(k).LineWidth = .6; end
end

function valueLabels(ax,b,V,fs,rot)
for k=1:numel(b)
    xe = b(k).XEndPoints;
    for i=1:size(V,1)
        v = V(i,k); s = dcm(v,2);
        if rot==0
            if v>=0, text(ax,xe(i),v,s,'FontSize',fs,'HorizontalAlignment','center','VerticalAlignment','bottom');
            else,    text(ax,xe(i),v,s,'FontSize',fs,'HorizontalAlignment','center','VerticalAlignment','top'); end
        else
            if v>=0, text(ax,xe(i),v,[' ' s],'FontSize',fs,'Rotation',90,'HorizontalAlignment','left','VerticalAlignment','middle');
            else,    text(ax,xe(i),v,[s ' '],'FontSize',fs,'Rotation',90,'HorizontalAlignment','right','VerticalAlignment','middle'); end
        end
    end
end
end

function s = dcm(v,nd)
% decimal comma, true minus sign; a value that rounds to zero is written without a sign
s = sprintf(['%.' num2str(nd) 'f'],v);
if all(s(~ismember(s,'-.'))=='0'), s = strrep(s,'-',''); end
s = strrep(s,'.',','); s = strrep(s,'-',char(8722));
end

%% =================================================================== F06_2: ring energies and first-order estimates
function fig_rings_energy(C,repo,outDir)
txt = fileread(fullfile(repo,'docs','research','G2_G1_evidence','G1_FIELD_EVIDENCE.json'),'Encoding','UTF-8');
if ~isempty(txt) && double(txt(1))==65279, txt = txt(2:end); end
E = jsondecode(txt);
s = E.homogeneousPath.arc_mm(:); Ur = E.homogeneousPath.U_ring; Ut = E.homogeneousPath.U_total(:);
assert(isequal(size(Ur),[numel(s) 3]),'U_ring size');
rel = @(u) 100*(u./u(1)-1);
rc = {[.85 .45 .00],[.00 .50 .50],[.50 .25 .60]}; rm = {'o','s','d'};
f = C.newfig(16,7.4); tl = tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
ax = nexttile(tl); hold(ax,'on');
h = gobjects(1,4);
for r=1:3
    h(r) = plot(ax,s,rel(Ur(:,r)),['-' rm{r}],'Color',rc{r},'MarkerFaceColor',rc{r},'MarkerSize',4.5,'LineWidth',1.2);
end
h(4) = plot(ax,s,rel(Ut),'-','Color',[0 0 0],'LineWidth',2);
yline(ax,0,'-','Color',[.5 .5 .5],'HandleVisibility','off');
grid(ax,'on'); box(ax,'on'); xlim(ax,[24.4 42.4]); ax.XTick = s'; ylim(ax,[-24 66]); ax.YTick = -20:20:60;
xlabel(ax,'довжина тріщини {\its}, мм'); ylabel(ax,'({\itU}/{\itU}_{S0} − 1)·100, %'); C.dec(ax); C.panel(ax,{'(а) енергія деформації','вздовж траєкторії H'});
legend(ax,h,{'область кільця 1','область кільця 2','область кільця 3','уся пластина'},'Location','northwest','FontSize',8,'Box','off');
% ---- (b) observed against first-order estimate
ax = nexttile(tl); hold(ax,'on');
SR = E.firstOrderSingleRing; SR = SR(strcmp({SR.family},'M4B'));
AR = E.firstOrderArchitecture;
xs = 100*[SR.firstOrder]; ys = 100*[SR.observed_F_G]; ct = [SR.contrast];
lim = [-8 9];
plot(ax,lim,lim,'--','Color',[.35 .35 .35],'LineWidth',.9,'HandleVisibility','off');
hs = plot(ax,xs(ct<1),ys(ct<1),'o','Color',[.1 .35 .75],'MarkerFaceColor','w','MarkerSize',8.5,'LineWidth',1.2);
hk = plot(ax,xs(ct>1),ys(ct>1),'^','Color',[.75 .2 .1],'MarkerFaceColor','w','MarkerSize',8.5,'LineWidth',1.2);
ha = gobjects(1,3);
for i=2:4
    m = strcmp({AR.architecture},C.ids{i});
    ha(i-1) = plot(ax,100*[AR(m).firstOrder_dUda],100*[AR(m).observed_F_G],C.mk{i},'Color',C.col{i},'MarkerFaceColor',C.col{i},'MarkerSize',4.5,'LineStyle','none');
end
axis(ax,'equal'); xlim(ax,lim); ylim(ax,lim); ax.XTick = -8:4:8; ax.YTick = -8:4:8; grid(ax,'on'); box(ax,'on');
xlabel(ax,'оцінка першого порядку, %'); ylabel(ax,'спостережено, %'); C.dec(ax); C.panel(ax,{'(б) спостережене проти','оцінки першого порядку'});
lgb = legend(ax,[hs hk ha],{'окреме кільце, {\itλ} = 0,5','окреме кільце, {\itλ} = 2','stiff13: S0, S2, S4','soft2: S0, S2, S4','soft1: S0, S2, S4'}, ...
    'Location','southeast','FontSize',7.5,'Box','off'); lgb.ItemTokenSize = [16 8];
C.save(f,outDir,'F06_2_enerhii_kilets');
end

%% =================================================================== F07_1: decomposition at S4
function fig_decomposition(C,repo,outDir)
txt = fileread(fullfile(repo,'docs','research','G2_M5_X6_evidence','campaign_20261125','M5X6_ANALYSIS.json'),'Encoding','UTF-8');
if ~isempty(txt) && double(txt(1))==65279, txt = txt(2:end); end
M = jsondecode(txt);
arch = {'stiff13','soft2','soft1'}; fld = {'F_mat','F_path','F_int','F_tot'};
G = zeros(3,4); T = zeros(3,4);
for a=1:3
    for c=1:4
        G(a,c) = 100*M.(arch{a}).G.(fld{c});          % fraction -> %
        T(a,c) = M.(arch{a}).MTS_deg.(fld{c});        % degrees
    end
end
cols = {[.30 .30 .30],[.68 .68 .68],[.93 .93 .93],[0 0 0]};
f = C.newfig(16,7.6); tl = tiledlayout(f,1,2,'TileSpacing','compact','Padding','compact');
ax = nexttile(tl); hold(ax,'on');
b = bar(ax,1:3,G,'grouped','BarWidth',.86); colorComp(b,cols); valueLabels(ax,b,G,7,90);
yline(ax,0,'k-'); ax.XTick = 1:3; ax.XTickLabel = arch; xlim(ax,[.4 3.6]); ylim(ax,[-11 10.5]); box(ax,'on'); grid(ax,'on'); ax.XGrid = 'off';
ylabel(ax,'{\itF}, %'); C.dec(ax,'y'); C.panel(ax,'(а) розклад {\itF_G} у стані S4');
b1 = b;
ax = nexttile(tl); hold(ax,'on');
b = bar(ax,1:3,T,'grouped','BarWidth',.86); colorComp(b,cols); valueLabels(ax,b,T,7,90);
yline(ax,0,'k-'); ax.XTick = 1:3; ax.XTickLabel = arch; xlim(ax,[.4 3.6]); ylim(ax,[-2.1 2.0]); box(ax,'on'); grid(ax,'on'); ax.XGrid = 'off';
ylabel(ax,'{\itF}, °'); C.dec(ax,'y'); C.panel(ax,'(б) розклад кута МКН {\itF}_θ у стані S4');
lg = legend(nexttile(tl,1),b1,{'матеріальний {\itF_m}','траєкторний {\itF_p}','взаємодійний {\itF_i}','повний ({\itF_G}, {\itF}_θ)'}, ...
    'Orientation','horizontal','FontSize',8,'Box','off','NumColumns',4); lg.Layout.Tile = 'south';
C.save(f,outDir,'F07_1_rozklad_S4');
end

function colorComp(b,cols)
for k=1:numel(b), b(k).FaceColor = cols{k}; b(k).EdgeColor = [.2 .2 .2]; b(k).LineWidth = .6; end
end
