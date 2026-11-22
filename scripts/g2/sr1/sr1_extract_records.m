function sr1_extract_records(runRoot, outFile)
%SR1_EXTRACT_RECORDS Read-only JSON extract of the 20 saved LP1 states (Issue #56).
%   sr1_extract_records(runRoot, outFile)
%   runRoot : <repo>/outputs/g2_lp1_matrix_paths_v1/run_20261122_lp1_v1 (restored, hash-verified)
%   outFile : new JSON file outside the repository source tree.
% Uses plain LOAD only. No project function, mesher, solver or record writer is
% called and nothing under runRoot is modified. Arrays with more than 400
% elements are summarised by class and size. The output contains fields that
% may hold local absolute paths; commit only the reduced file produced by
% sr1_independent_check.py --reduce.
assert(isfolder(runRoot), 'SR1:Input', 'runRoot not found.');
assert(~isfile(outFile), 'SR1:Output', 'Refusing to overwrite an existing extract.');
[~, sys] = memory;
fprintf('SR1_EXTRACT free physical RAM inside MATLAB: %.3f GiB\n', sys.PhysicalMemory.Available/2^30);
cases = {'H','stiff13','soft2','soft1'};
R = struct();
for c = 1:4
    for k = 0:4
        d = fullfile(runRoot, cases{c}, sprintf('S%d', k));
        e = struct();
        for f = {'STATE','REVIEW','SOLUTION','PHASE'}
            s = load(fullfile(d, [f{1} '.mat']));
            e.(f{1}) = prune(s.record, 0);
        end
        R.(sprintf('%s_S%d', cases{c}, k)) = e;
    end
end
s = load(fullfile(runRoot, 'RUN.mat'));
R.RUN = prune(s.record, 0);
fid = fopen(outFile, 'w');
fwrite(fid, jsonencode(R), 'char');
fclose(fid);
fprintf('SR1_EXTRACT_OK states=20 NO_FEM=1 NO_MESH=1\n');
end

function y = prune(x, d)
if d > 6, y = '<depth>'; return, end
if isstruct(x)
    if ~isscalar(x), y = sprintf('<struct %s>', mat2str(size(x))); return, end
    y = struct(); fn = fieldnames(x);
    for k = 1:numel(fn), y.(fn{k}) = prune(x.(fn{k}), d+1); end
elseif iscell(x)
    if numel(x) <= 12
        y = cell(size(x));
        for k = 1:numel(x), y{k} = prune(x{k}, d+1); end
    else
        y = sprintf('<cell %s>', mat2str(size(x)));
    end
elseif isnumeric(x) || islogical(x)
    if numel(x) <= 400, y = double(x); else, y = sprintf('<%s %s>', class(x), mat2str(size(x))); end
elseif ischar(x) || isstring(x)
    y = char(x);
else
    y = sprintf('<%s>', class(x));
end
end
