% LP2-A2 independent set: freeze eight polylines before any meshing (no mesh, no FEM)
ex='<repo>';
addpath(fullfile(ex,'matlab','g2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a2'),'-begin');
[~,c]=system(['git -C "',ex,'" rev-parse HEAD']);fprintf('SOURCE_COMMIT=%s\n',strtrim(c));
out=fullfile(ex,'outputs','LP2A2_INDEPENDENT_SET.json');
T=g2_lp2a2_independent_set(ex,out);
for i=1:numel(T.rows)
 r=T.rows{i};p=r.preCheck;
 fprintf('INDEP %-24s tip=(%.4f, %.4f) S10 adm=%d gap=%s | S11 adm=%d gap=%s inRegime=%d\n',r.id,r.polyline_mm(end,1),r.polyline_mm(end,2), ...
  p(1).admissible,mat2str(p(1).guideToRingClearance_mm,4),p(2).admissible,mat2str(p(2).guideToRingClearance_mm,4),r.inRegime);
end
fprintf('INDEP_SET_SHA256=%s\n',lower(g2_sha256_file(out)));
