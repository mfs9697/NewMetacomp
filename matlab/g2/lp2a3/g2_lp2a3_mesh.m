function D=g2_lp2a3_mesh(P,varargin)
%G2_LP2A3_MESH  LP2-A3 mesh: the LP2-A2 family at the DEFAULT 0.45 mm seed spacing ONLY.
%  D = g2_lp2a3_mesh(P,'ExpectedVertices',N,'ExpectedTangent',t,'ExteriorOptions',xo,'MaxT3Elements',40000)
% Exactly the first-rung call sequence of g2_lp2a2_mesh: g2_lp2a2_join(P,...,'ExteriorOptions',
% [xo,{'SeedSpacing_mm',0.45}]) followed, if the join passes, by g2_lp2a2_pairing_audit (P1-P10).
% There is NO ladder: a rung-1 failure (any join gate, including the global quality gates, or the
% pairing audit) returns pass=false and the caller stops the case. No other seed spacing is ever
% generated, also not to diagnose a live candidate. D.seedRung=1, D.seedSpacing_mm=0.45, D.ladder
% holds the single attempt (same layout as g2_lp2a2_mesh).
ip=inputParser;ip.KeepUnmatched=true;addParameter(ip,'ExteriorOptions',{},@iscell);parse(ip,varargin{:});
f=fieldnames(ip.Unmatched);rest=cell(1,2*numel(f));for k=1:numel(f),rest{2*k-1}=f{k};rest{2*k}=ip.Unmatched.(f{k});end
xo=ip.Results.ExteriorOptions;
assert(~any(strcmpi(xo(1:2:end),'SeedSpacing_mm')),'G2LP2A3:HOLD_INPUT','The seed spacing is fixed at 0.45 mm and may not be passed.');
D=g2_lp2a2_join(P,rest{:},'ExteriorOptions',[xo,{'SeedSpacing_mm',0.45}]);
pp=false;if D.pass,PA=g2_lp2a2_pairing_audit(D);pp=PA.pass;D.pairingAudit=PA;end
fg=D.failedGates;if isempty(fg),fg={};end
D.ladder=struct('rung',1,'seedSpacing_mm',0.45,'stage',D.stage,'message',D.message,'failedGates',{fg},'pairingPass',pp);
D.seedRung=1;D.seedSpacing_mm=0.45;
if D.pass&&~pp,D.pass=false;D.stage='HOLD_LP2A2_PAIRING';D.message=strjoin(PA.failedGates,', ');end
end
