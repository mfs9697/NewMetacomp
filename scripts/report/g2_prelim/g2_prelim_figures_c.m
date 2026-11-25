function g2_prelim_figures_c(repo,outDir) %#ok<INUSL>
%G2_PRELIM_FIGURES_C  Redrawn pairing-failure figure of the legacy mesher (no FEM, no evidence files read).
% Inputs are the interior-node counts per centre-line segment of the legacy generator for the geometry-only
% S9 candidate of soft2, as quoted in docs/research/G2_LP2A2_MESH_QUALIFICATION_MEMO_UA.md (section 2):
%   upper bank [50 7 8 8 8 8 8 8 8 1], lower bank [50 8 8 8 8 8 8 8 8 1].
% Panel (b) is a SCHEMATIC of segment 2 (4 mm): with 7 and 8 interior nodes the uniform station spacings are
% 4/8 = 0.5 mm and 4/9 = 0.444 mm, so no station of the upper bank coincides with a station of the lower bank
% except the two ends.
C = g2_prelim_fig_common();
up = [50 7 8 8 8 8 8 8 8 1]; lo = [50 8 8 8 8 8 8 8 8 1];
f = C.newfig(16,7.6);
ax = axes(f,'Position',[0.085 0.16 0.40 0.66]); hold(ax,'on');
b = bar(ax,1:10,[up(:) lo(:)],0.8,'EdgeColor','k','LineWidth',.6);
b(1).FaceColor = [.80 .25 .20]; b(2).FaceColor = [.20 .40 .80];
ylim(ax,[0 60]); xlim(ax,[0.4 10.6]); box(ax,'on'); grid(ax,'on');
xlabel(ax,'відрізок осьової лінії {\itk}'); ylabel(ax,'внутрішні вузли на березі');
ax.XTick = 1:10; ax.YTick = 0:10:60; C.dec(ax);
text(ax,2.3,15,{'{\itk} = 2:','7 проти 8'},'FontSize',8.5,'HorizontalAlignment','left');
legend(ax,{'верхній берег','нижній берег'},'Location','northeast','FontSize',8.5,'Box','off');
C.panel(ax,'(а) кількості вузлів за успадкованого генератора');
ax = axes(f,'Position',[0.575 0.16 0.40 0.66]); hold(ax,'on');
xu = linspace(0,4,9); xl = linspace(0,4,10);
for i = 1:numel(xu)
    [~,j] = min(abs(xl-xu(i)));
    if i>1 && i<numel(xu)
        plot(ax,[xu(i) xl(j)],[1 0],'-','Color',[.6 .6 .6],'LineWidth',.7);
    end
end
plot(ax,xu,ones(size(xu)),'o','MarkerFaceColor',[.80 .25 .20],'MarkerEdgeColor','k','MarkerSize',6);
plot(ax,xl,zeros(size(xl)),'s','MarkerFaceColor',[.20 .40 .80],'MarkerEdgeColor','k','MarkerSize',6);
xlim(ax,[-0.15 4.15]); ylim(ax,[-0.6 1.6]); box(ax,'on'); yticks(ax,[0 1]);
ax.YTickLabel = {'нижній берег','верхній берег'}; xlabel(ax,'станція вздовж відрізка 2, мм');
ax.XTick = 0:0.5:4; C.dec(ax,'x');
text(ax,2,-0.35,{'верхній берег — 8 інтервалів, нижній — 9;','станції всередині відрізка не збігаються'},'FontSize',8.5,'HorizontalAlignment','center');
C.panel(ax,'(б) відрізок 2, схематично (рівномірні станції)');
C.save(f,outDir,'F09_vidmova_parovannia');
end
