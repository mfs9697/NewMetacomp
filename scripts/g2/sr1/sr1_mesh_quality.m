function sr1_mesh_quality(runRoot, outFile)
%SR1_MESH_QUALITY Independent read-only T3 quality of the 20 saved LP1 meshes (Issue #56).
%   Own implementation: interior angles, signed areas, and the maximum ratio of
%   longest edges over all edge-adjacent T3 pairs. Loads T3, X3, crackPolyline
%   and tipTangent from MESH.mat with plain LOAD; calls no project function.
assert(isfolder(runRoot), 'SR1:Input', 'runRoot not found.');
assert(~isfile(outFile), 'SR1:Output', 'Refusing to overwrite an existing output.');
cases = {'H','stiff13','soft2','soft1'};
Q = struct();
for c = 1:4
    for k = 0:4
        m = load(fullfile(runRoot, cases{c}, sprintf('S%d', k), 'MESH.mat'), ...
            'T3', 'X3', 'crackPolyline', 'tipTangent');
        T = double(m.T3); X = double(m.X3);
        if size(X,1) == 2 && size(X,2) ~= 2, X = X.'; end
        if size(T,1) == 3 && size(T,2) ~= 3, T = T.'; end
        A = X(T(:,1),:); B = X(T(:,2),:); C = X(T(:,3),:);
        e1 = vecnorm(B-C,2,2); e2 = vecnorm(C-A,2,2); e3 = vecnorm(A-B,2,2);
        ang = @(u,v) acosd(max(-1, min(1, sum(u.*v,2) ./ (vecnorm(u,2,2).*vecnorm(v,2,2)))));
        a1 = ang(B-A, C-A); a2 = ang(A-B, C-B); a3 = 180 - a1 - a2;
        ar = 0.5*((B(:,1)-A(:,1)).*(C(:,2)-A(:,2)) - (C(:,1)-A(:,1)).*(B(:,2)-A(:,2)));
        L = max([e1 e2 e3], [], 2);
        E = sort([T(:,[1 2]); T(:,[2 3]); T(:,[3 1])], 2);
        id = repmat((1:size(T,1)).', 3, 1);
        [~, ~, g] = unique(E, 'rows');
        cnt = accumarray(g, 1);
        [gs, ord] = sort(g); ids = id(ord);
        same = find(gs(1:end-1) == gs(2:end));
        a = ids(same); b = ids(same+1);
        ratio = max(L(a), L(b)) ./ min(L(a), L(b));
        Q.(sprintf('%s_S%d', cases{c}, k)) = struct('nT3', size(T,1), 'nNodes', size(X,1), ...
            'minAngle_deg', min([a1;a2;a3]), 'maxAngle_deg', max([a1;a2;a3]), ...
            'minAbsArea_mm2', min(abs(ar)), 'nNegativeArea', nnz(ar <= 0), 'nPositiveArea', nnz(ar > 0), ...
            'totalArea_mm2', sum(abs(ar)), 'maxNeighbourLongestEdgeRatio', max(ratio), ...
            'boundaryEdges', nnz(cnt == 1), 'crackPolyline', m.crackPolyline, 'tipTangent', m.tipTangent);
    end
end
fid = fopen(outFile, 'w');
fwrite(fid, jsonencode(Q), 'char');
fclose(fid);
fprintf('SR1_MESH_QUALITY_OK states=20 NO_FEM=1 NO_MESH=1\n');
end
