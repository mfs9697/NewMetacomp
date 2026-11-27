function S = kbp_style()
%KBP_STYLE  Presentation style of the KB Pivdenne 2026 H2 figures (plotting only; no FEM).
% One colour, marker and name per configuration in every figure. Colours are the Okabe-Ito
% colour-blind-safe set; markers give a second, colour-independent cue.
% Geometry constants: Cornell specimen no. 1 as idealized in the G2 policies
% (matlab/g2/G2_LP1_POLICY_v2.json, matlab/g2/G2_MATERIAL_POLICY_v1.json), identical to
% scripts/report/g2_prelim/g2_prelim_fig_common.m.
S.ids   = {'H','stiff13','soft2','soft1'};
S.name  = {'Однорідний матеріал','Жорсткі кільця 1 і 3','Податливе кільце 2','Податливе кільце 1'};
S.name2 = {{'Однорідний','матеріал'},{'Жорсткі','кільця 1 і 3'},{'Податливе','кільце 2'},{'Податливе','кільце 1'}};
S.ratio = {'','{\itE}_к/{\itE}_м = 2','{\itE}_к/{\itE}_м = 0,5','{\itE}_к/{\itE}_м = 0,5'};
S.col   = {[0 0 0],[213 94 0]/255,[0 114 178]/255,[0 158 115]/255};   % black, vermillion, blue, bluish green
S.mk    = {'o','^','s','d'};
S.mask  = [0 0 0;1 0 1;0 1 0;1 0 0];        % active rings per configuration
S.kind  = [0 2 1 1];                         % 2 stiff, 1 compliant
S.stiffFill = [248 203 173]/255; S.stiffEdge = [170 70 0]/255;     % light vermillion
S.softFill  = [176 216 240]/255; S.softEdge  = [0 90 150]/255;     % light sky blue
S.passEdge  = [.55 .55 .55];
S.plateFill = [.965 .965 .965]; S.crack0 = [.35 .35 .35];
S.cen = [152.4 69.85;152.4 120.65;152.4 171.45]; S.rHole = 6.35; S.rRing = 19.05;
S.plate = [508 203.2]; S.mouth = [101.6 0]; S.tip0 = [101.6 25.4];
S.font = 'Arial'; S.fs = 20; S.fsTick = 18; S.fsTitle = 22; S.fsSmall = 16;
S.lw = 3.5; S.ms = 11;
set(groot,'defaultAxesFontName',S.font,'defaultTextFontName',S.font,'defaultAxesFontSize',S.fsTick, ...
    'defaultLegendFontName',S.font,'defaultAxesTickLabelInterpreter','tex','defaultTextInterpreter','tex', ...
    'defaultAxesLineWidth',1.2,'defaultAxesTickDir','out','defaultAxesTickLength',[.008 .008]);
S.newfig = @newfig; S.save = @save3; S.dec = @dec; S.rings = @rings; S.ax = @axcm;
end

function f = newfig(wcm,hcm)
f = figure('Visible','off','Color','w','Units','centimeters','Position',[1 1 wcm hcm], ...
    'PaperUnits','centimeters','PaperPositionMode','manual','PaperPosition',[0 0 wcm hcm],'PaperSize',[wcm hcm], ...
    'InvertHardcopy','off');
end

function ax = axcm(f,x,y,w,h)
% axes placed in centimetres (exact plot box; with equal data aspect w/h must equal dx/dy)
p = f.Position; ax = axes(f,'Units','normalized','Position',[x/p(3) y/p(4) w/p(3) h/p(4)]); hold(ax,'on');
end

function dec(ax,which,nd)
% decimal comma and a true minus sign on the tick labels
if nargin<2, which='xy'; end
if nargin<3, nd=[]; end
drawnow;
if any(which=='x'), ax.XTickMode='manual'; ax.XTickLabel = lab(ax.XTick,nd); end
if any(which=='y'), ax.YTickMode='manual'; ax.YTickLabel = lab(ax.YTick,nd); end
end

function L = lab(v,nd)
if nargin<2 || isempty(nd)
    nd = 0; for k=1:6, if all(abs(v*10^nd-round(v*10^nd))<1e-9*max(1,max(abs(v))*10^nd)), break; end, nd=nd+1; end
end
L = cell(size(v));
for i=1:numel(v)
    s = sprintf(['%.' num2str(nd) 'f'],v(i)); if abs(v(i))<1e-12, s='0'; end
    s = strrep(s,'.',','); s = strrep(s,'-',char(8722)); L{i}=s;
end
end

function rings(ax,S,i,lw)
% rings and holes of configuration i (i = 0: neutral grey rings, no configuration)
th = linspace(0,2*pi,361);
for h=1:3
    if i==0 || S.mask(i,h)==0
        fill(ax,S.cen(h,1)+S.rRing*cos(th),S.cen(h,2)+S.rRing*sin(th),'w','FaceAlpha',0,'EdgeColor',S.passEdge,'LineStyle',':','LineWidth',lw);
    elseif S.kind(i)==2
        fill(ax,S.cen(h,1)+S.rRing*cos(th),S.cen(h,2)+S.rRing*sin(th),S.stiffFill,'EdgeColor',S.stiffEdge,'LineWidth',lw);
    else
        fill(ax,S.cen(h,1)+S.rRing*cos(th),S.cen(h,2)+S.rRing*sin(th),S.softFill,'EdgeColor',S.softEdge,'LineWidth',lw);
    end
    fill(ax,S.cen(h,1)+S.rHole*cos(th),S.cen(h,2)+S.rHole*sin(th),'w','EdgeColor','k','LineWidth',lw);
end
end

function save3(f,outDir,name)
% 600 dpi PNG, vector PDF (embedded TrueType fonts), editable FIG (opens visible)
if ~isfolder(outDir), mkdir(outDir); end
print(f,fullfile(outDir,[name '.png']),'-dpng','-r600');
exportgraphics(f,fullfile(outDir,[name '.pdf']),'ContentType','vector','BackgroundColor','white');
set(f,'CreateFcn','set(gcbo,''Visible'',''on'')');
savefig(f,fullfile(outDir,[name '.fig']),'compact');
close(f); fprintf('saved %s\n',name);
end
