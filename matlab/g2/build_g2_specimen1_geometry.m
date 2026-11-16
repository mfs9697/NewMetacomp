function R = build_g2_specimen1_geometry(varargin)
%BUILD_G2_SPECIMEN1_GEOMETRY Cornell 1990 specimen #1: nominal geometry only.
%
% MATLAB R2023a + Partial Differential Equation Toolbox.
% Constructs a TRUE circular-hole 2D PDE domain and a separate crack overlay.
% NO mesh is generated, NO crack banks are split, and NO mechanics are solved.
%
% Usage:
%   addpath('matlab/g2');
%   R = build_g2_specimen1_geometry();
%   R = build_g2_specimen1_geometry('Visible','off','Export',true);
%
% From the JSON (all millimetres):
%   508 x 203.2 plate; thickness 12.7
%   3 x radius 6.35 holes at x=152.4, y=69.85,120.65,171.45
%   crack overlay from (101.6,0) to (101.6,25.4)
%   supports x=25.4 and x=482.6; load at (254,203.2).
%
% IMPORTANT: R.model is the UNCRACKED plate with three exact circular
% voids. Do NOT use R.model to extract K or G or propagate a crack: the
% visible crack is a graphical annotation, NOT a topological slit. A
% cracked-body mesh with separate banks must be developed/qualified later.
%
% Source of truth:
% docs/research/crack-growth-gaps-2026/G2_SPECIMEN1_1990_GEOMETRY.json
% The nominal geometry still awaits direct archival scan verification.

    here = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(fileparts(here));
    source = fullfile(repoRoot, 'docs', 'research', ...
        'crack-growth-gaps-2026', 'G2_SPECIMEN1_1990_GEOMETRY.json');

    p = inputParser;
    p.FunctionName = mfilename;
    addParameter(p, 'JsonPath', source, ...
        @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'OutputDir', fullfile(here, 'output'), ...
        @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'Export', true, @(x) islogical(x) && isscalar(x));
    addParameter(p, 'Visible', 'on', ...
        @(x) any(strcmp(char(x), {'on','off'})));
    parse(p,varargin{:});

    source = char(p.Results.JsonPath);
    outdir = char(p.Results.OutputDir);
    assert(isfile(source), 'G2:MissingSource', ...
        'Geometry JSON not found: %s', source);
    J = jsondecode(fileread(source));
    assert(strcmp(J.schema, ...
        'NewMetacomp.G2.IngraffeaGrigoriu1990.Specimen1.nominal.v1'), ...
        'G2:WrongSchema', 'Unexpected source JSON schema.');

    G = J.nominal_geometry_mm;
    audit = audit_nominal_geometry(G);
    assert(audit.pass,'G2:FailedGeometryAudit', ...
        'Geometry has failed preflight checks: %s', ...
        strjoin(audit.errors, '; '));

    % PDE Toolbox geometric set difference:
    % R1 - H1 - H2 - H3 (actual circles; no polygon approximation in CAD).
    % The geometry description matrix columns must have equal height.
    x0 = G.plate.x_range(1);  x1 = G.plate.x_range(2);
    y0 = G.plate.y_range(1);  y1 = G.plate.y_range(2);
    gd = zeros(10,4);
    gd(:,1) = [3;4;x0;x1;x1;x0;y0;y0;y1;y1];
    for i = 1:3
        gd(1:4,i+1) = [1;G.holes(i).center(:);G.holes(i).radius];
    end
    ns = char('R1','H1','H2','H3').';
    sf = 'R1-H1-H2-H3';
    dl = decsg(gd,sf,ns);
    model = createpde(1);
    geometryFromEdges(model,dl);

    % Publication-oriented *drawing*; circles sampled only to display.
    % The precise domain is held by the decomposed PDE geometry above.
    F = figure('Color','w','Name','Cornell 1990 specimen #1 — NOMINAL', ...
        'Visible', char(p.Results.Visible), ...
        'Units','pixels','Position',[90 100 1270 660]);
    ax = axes('Parent',F);
    hold(ax,'on');
    axis(ax,'equal');
    patch(ax, [x0 x1 x1 x0], [y0 y0 y1 y1], ...
        [0.90 0.94 0.97], 'EdgeColor',[0.14 0.18 0.24], ...
        'LineWidth',1.7);
    t = linspace(0,2*pi,721);
    for i = 1:3
        c = G.holes(i).center(:);
        r = G.holes(i).radius;
        patch(ax,c(1)+r*cos(t),c(2)+r*sin(t), ...
            'w', 'EdgeColor',[0.09 0.28 0.46], 'LineWidth',1.5);
        plot(ax,c(1),c(2),'+','Color',[0.09 0.28 0.46], ...
            'LineWidth',1.0,'MarkerSize',6);
        text(ax,c(1)+12,c(2), ...
            sprintf('H%d (%.2f, %.2f), R=%.2f mm', ...
            i,c(1),c(2),r), ...
            'FontSize',9,'Color',[0.14 0.24 0.34], ...
            'VerticalAlignment','middle');
    end

    mouth = G.initial_crack.mouth(:);
    tip = G.initial_crack.tip(:);
    plot(ax,[mouth(1),tip(1)],[mouth(2),tip(2)], ...
        '-','Color',[0.74 0.13 0.14], 'LineWidth',2.6);
    plot(ax,tip(1),tip(2),'o','MarkerFaceColor',[0.74 0.13 0.14], ...
        'MarkerEdgeColor','w','MarkerSize',7);
    text(ax,tip(1)+9,tip(2)-4, ...
        sprintf('Crack tip (%.1f, %.1f) mm',tip(1),tip(2)), ...
        'Color',[0.58 0.10 0.12], 'FontSize',10, ...
        'VerticalAlignment','bottom');

    % *Symbols* represent intended supports/load, not contact mechanics.
    xl = G.supports.left(1);
    xr = G.supports.right(1);
    patch(ax,[xl-9 xl+9 xl],[y0-10 y0-10 y0], ...
        [0.28 0.35 0.42],'EdgeColor',[0.15 0.17 0.20]);
    plot(ax,[xl-11,xl+11],[y0-12,y0-12], ...
        'k-','LineWidth',1);
    tt = linspace(0,2*pi,100);
    patch(ax,xr+3.8*cos(tt),y0-4.0+3.8*sin(tt), ...
        [0.32 0.40 0.48], 'EdgeColor','k','LineWidth',0.7);
    plot(ax,[xr-11,xr+11],[y0-9,y0-9], ...
        'k-','LineWidth',1);
    text(ax,xl-1,y0-17,'pin (idealized)', ...
        'FontSize',9,'HorizontalAlignment','center');
    text(ax,xr-1,y0-17,'roller (idealized)', ...
        'FontSize',9,'HorizontalAlignment','center');

    xp = G.load_position(1);
    yp = G.load_position(2);
    quiver(ax,xp,yp+26,0,-25,0,'Color',[0.73 0.12 0.13], ...
        'MaxHeadSize',1.9,'LineWidth',2.2);
    text(ax,xp+12,yp+21,'P \downarrow (magnitude unknown)', ...
        'FontSize',10,'Color',[0.67 0.10 0.11]);

    xlabel(ax,'x (mm)');
    ylabel(ax,'y (mm)');
    title(ax,'Ingraffea–Grigoriu (1990), specimen #1 — nominal geometry', ...
        'FontWeight','bold');
    subtitle(ax,['TRUE CAD circles; crack is a graphical overlay ', ...
        '(not a split-bank FEM geometry)']);
    set(ax,'FontSize',10,'LineWidth',0.9,'Box','off');
    grid(ax,'on');
    ax.GridAlpha=0.13;
    xlim(ax,[x0-22,x1+22]);
    ylim(ax,[y0-29,y1+38]);

    files = struct('pdf','','png','','fig','');
    if p.Results.Export
        if ~isfolder(outdir)
            mkdir(outdir);
        end
        prefix = fullfile(outdir,'G2_Specimen1_1990_nominal_geometry');
        files.pdf = [prefix,'.pdf'];
        files.png = [prefix,'.png'];
        files.fig = [prefix,'.fig'];
        exportgraphics(F,files.pdf,'ContentType','vector');
        exportgraphics(F,files.png,'Resolution',240);
        savefig(F,files.fig);
    end

    R = struct();
    R.source_json = source;
    R.specimen = '#1 (Cornell 1990), nominal';
    R.model = model;           % UNCRACKED body with 3 genuine circular voids
    R.decomposed_geometry = dl;
    R.crack_overlay_mm = [mouth.';tip.'];
    R.audit = audit;
    R.figure = F;
    R.files = files;
    R.is_FEM_ready = false;
    R.is_experiment_certified = false;

    fprintf(['G2 Cornell #1: geometry audit PASSED, 3 exact CAD holes; ', ...
        'minimum crack-tip/hole-wall clearance %.6f mm.\n'], ...
        audit.tip_clearance_mm);
    fprintf(['PDE geometry is UNCRACKED; visible crack is an overlay. ', ...
        'No mesh/solver was called.\n']);
    if p.Results.Export
        fprintf('Drawings saved to %s\n',outdir);
    end
end

function A = audit_nominal_geometry(G)
% Explicit numerical checks; only checks *nominal geometry*.
    err = {};
    tol = 1e-8; % mm; arithmetic/coordinate integrity, NOT machining tolerance
    W = diff(G.plate.x_range);
    H = diff(G.plate.y_range);
    if ~(abs(W-508)<tol && abs(H-203.2)<tol ...
            && abs(G.plate.thickness-12.7)<tol)
        err{end+1}='plate size/thickness mismatch'; %#ok<AGROW>
    end
    if numel(G.holes) ~= 3
        err{end+1}='expected three holes'; %#ok<AGROW>
    end
    centers = [152.4 69.85; 152.4 120.65; 152.4 171.45];
    for i=1:min(numel(G.holes),3)
        c=G.holes(i).center(:).';
        r=G.holes(i).radius;
        if any(abs(c-centers(i,:))>tol) || abs(r-6.35)>tol
            err{end+1}=sprintf('hole %d nominal coordinate mismatch',i); %#ok<AGROW>
        end
        if c(1)-r <= G.plate.x_range(1) || ...
           c(1)+r >= G.plate.x_range(2) || ...
           c(2)-r <= G.plate.y_range(1) || ...
           c(2)+r >= G.plate.y_range(2)
            err{end+1}=sprintf('hole %d is not interior',i); %#ok<AGROW>
        end
        for j=1:i-1
            cj=G.holes(j).center(:);
            if norm(c(:)-cj) <= r+G.holes(j).radius
                err{end+1}=sprintf('holes %d and %d overlap',i,j); %#ok<AGROW>
            end
        end
    end
    mouth=G.initial_crack.mouth(:);
    tip=G.initial_crack.tip(:);
    if any(abs(mouth-[101.6;0])>tol) || ...
       any(abs(tip-[101.6;25.4])>tol) || ...
       abs(norm(tip-mouth)-25.4)>tol
        err{end+1}='initial crack mismatch'; %#ok<AGROW>
    end
    if any(abs(G.supports.left(:)-[25.4;0])>tol) || ...
       any(abs(G.supports.right(:)-[482.6;0])>tol) || ...
       abs(G.supports.span-457.2)>tol
        err{end+1}='support position/span mismatch'; %#ok<AGROW>
    end
    if any(abs(G.load_position(:)-[254;203.2])>tol)
        err{end+1}='loading point mismatch'; %#ok<AGROW>
    end
    tipClearance=inf;
    for i=1:numel(G.holes)
        c=G.holes(i).center(:);
        r=G.holes(i).radius;
        d=tip-mouth;
        alpha=max(0,min(1, dot(c-mouth,d)/dot(d,d)));
        closest=mouth+alpha*d;
        if norm(c-closest)<=r
            err{end+1}=sprintf('crack line intersects hole %d',i); %#ok<AGROW>
        end
        tipClearance=min(tipClearance,norm(c-tip)-r);
    end
    if ~(tipClearance>0)
        err{end+1}='crack tip is on/in a hole'; %#ok<AGROW>
    end
    A=struct('pass',isempty(err),'errors',{err}, ...
        'hole_count',numel(G.holes),...
        'tip_clearance_mm',tipClearance, ...
        'tolerance_mm',tol, ...
        'qualification','nominal CAD geometry only');
end
