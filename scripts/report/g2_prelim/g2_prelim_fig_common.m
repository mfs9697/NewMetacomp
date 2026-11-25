function C = g2_prelim_fig_common()
%G2_PRELIM_FIG_COMMON  Shared conventions of the G2 preliminary-report figures (no FEM, plotting only).
% One colour, line style and marker per architecture throughout the report; the convention is the one
% of the accepted LP2-A1 figures (scripts/g2/lp2/g2_lp2a_figures.m).
C.ids = {'H','stiff13','soft2','soft1'};
C.names = {'H (однорідна)','stiff13: жорсткі кільця \{1,3\}','soft2: м’яке кільце \{2\}','soft1: м’яке кільце \{1\}'};
C.short = {'H','stiff13','soft2','soft1'};
C.leg = {'H (однорідна)','stiff13: жорсткі \{1,3\}','soft2: м’яке \{2\}','soft1: м’яке \{1\}'};   % short legend names (one row on 16 cm)
C.col = {[0 0 0],[.75 .2 .1],[.1 .35 .75],[.15 .55 .2]};
C.ls = {'-','--','-.',':'};
C.mk = {'o','^','s','d'};
C.cen = [152.4 69.85;152.4 120.65;152.4 171.45];   % hole / ring centres, mm (ring 1 = lower hole)
C.rHole = 6.35; C.rRing = 19.05; C.rGuide = 15; C.rCore = 3; C.rCollar = 3.3;
C.plate = [508 203.2]; C.mouth = [101.6 0]; C.tip0 = [101.6 25.4];
C.load = [254 203.2]; C.pin = [25.4 0]; C.roller = [482.6 0];
C.font = 'Times New Roman'; C.fs = 9;
C.softCol = [.62 .78 .93]; C.stiffCol = [.93 .68 .60]; C.passiveCol = [.93 .93 .93];
set(groot,'defaultAxesFontName',C.font,'defaultTextFontName',C.font,'defaultAxesFontSize',C.fs, ...
    'defaultLegendFontName',C.font,'defaultAxesTickLabelInterpreter','tex','defaultTextInterpreter','tex');
C.dec = @dec; C.save = @save2; C.newfig = @newfig; C.panel = @panel;
end

function f = newfig(wcm,hcm)
f = figure('Visible','off','Color','w','Units','centimeters','Position',[0 0 wcm hcm], ...
    'PaperUnits','centimeters','PaperPositionMode','manual','PaperPosition',[0 0 wcm hcm],'PaperSize',[wcm hcm]);
end

function dec(ax,which)
% decimal comma and a true minus sign on the tick labels
if nargin<2, which='xy'; end
drawnow;
if any(which=='x'), ax.XTickMode='manual'; ax.XTickLabel = lab(ax.XTick); end
if any(which=='y'), ax.YTickMode='manual'; ax.YTickLabel = lab(ax.YTick); end
end

function L = lab(v)
L = cell(size(v));
d = 0; for k=1:6, if all(abs(v*10^d-round(v*10^d))<1e-9*max(1,max(abs(v))*10^d)), break; end, d=d+1; end
for i=1:numel(v)
    s = sprintf(['%.' num2str(d) 'f'],v(i));
    if abs(v(i))<1e-12, s='0'; end
    s = strrep(s,'.',','); s = strrep(s,'-',char(8722)); L{i}=s;
end
end

function panel(ax,str)
title(ax,str,'FontWeight','normal','FontSize',9.5,'FontName','Times New Roman');
end

function save2(f,outDir,name)
if ~isfolder(outDir), mkdir(outDir); end
print(f,fullfile(outDir,[name '.png']),'-dpng','-r300');
try   % vector PDF with embedded TrueType fonts (print -dpdf would use the base-14 fonts and lose the Cyrillic text)
    exportgraphics(f,fullfile(outDir,[name '.pdf']),'ContentType','vector','BackgroundColor','white');   % tightly cropped (R2023a has no Padding option)
catch me, warning('pdf not written for %s: %s',name,me.message); end
close(f);
fprintf('saved %s\n',name);
end
