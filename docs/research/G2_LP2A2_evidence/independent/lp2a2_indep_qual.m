% LP2-A2 independent set: unchanged ladder + every audit (geometry only, zero FEM)
ex='<repo>';
addpath(fullfile(ex,'matlab','g2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a2'),'-begin');
[~,c]=system(['git -C "',ex,'" rev-parse HEAD']);fprintf('SOURCE_COMMIT=%s\n',strtrim(c));
ts=fullfile(ex,'docs','research','G2_LP2A2_evidence','independent','LP2A2_INDEPENDENT_SET.json');fprintf('SET_SHA256=%s\n',lower(g2_sha256_file(ts)));
Q=g2_lp2a2_qualify_mesh(ex,ts,fullfile(ex,'outputs','LP2A2_INDEPENDENT_QUALIFICATION.json'),[],'ladder');
for i=1:numel(Q.rows)
 n=Q.rows{i}.new;fp=isfield(n,'forcedPairs')&&n.forcedPairs.pass;
 fprintf('INDEP_QUAL %-24s pass=%d rung=%d T3=%s audit=%s pairing=%d forced=%d minAng=%.2f ratio=%.3f\n',Q.rows{i}.id,n.pass,n.seedRung,num2str(gf(n,'T3')),char(gf(n,'auditGates')),isfield(n,'pairing')&&n.pairing.pass,fp,gf(n,'minAngle_deg'),gf(n,'maxNeighborRatio'));
end
function v=gf(s,f),if isfield(s,f),v=s.(f);else,v=NaN;end,end
