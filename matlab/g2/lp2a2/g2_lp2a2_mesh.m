function [D,L]=g2_lp2a2_mesh(P,varargin)
%G2_LP2A2_MESH  LP2-A2 mesh family: g2_lp2a2_join with a PREDECLARED deterministic seed-spacing ladder.
%  [D,L] = g2_lp2a2_mesh(P,'ExpectedVertices',N,'ExpectedTangent',t,'ExteriorOptions',xo,'MaxT3Elements',40000)
% Rungs (bank seed spacing, mm): 0.45 (= lip Hedge), 0.40, 0.50, 0.35. The first rung whose joined
% mesh passes EVERY inherited join gate and the independent pairing audit is returned. Only a
% failure of the global quality gates (globalMinAngleAtLeast20, globalNeighborRatioAtMost1p8)
% moves to the next rung: the exterior PDE mesh reacts chaotically to the CAD vertex set, so a
% far-field ratio exceedance at one spacing is not systematic (attempt 1 and the spacing
% exploration, LP2-A2 evidence). Any other HOLD (admissibility, CAD, seeds not honoured, budget,
% pairing) stops immediately. No gate is relaxed; every rung is paired exactly; all attempts are
% returned in L. Deterministic: the same polyline always yields the same rung and mesh.
ip=inputParser;ip.KeepUnmatched=true;addParameter(ip,'ExteriorOptions',{},@iscell);parse(ip,varargin{:});
rest=struct2pv(ip.Unmatched);xo=ip.Results.ExteriorOptions;
rungs=[0.45 0.40 0.50 0.35];quality={'globalMinAngleAtLeast20','globalNeighborRatioAtMost1p8'};
L=struct('rung',{},'seedSpacing_mm',{},'stage',{},'message',{},'failedGates',{},'pairingPass',{});
for k=1:numel(rungs)
 D=g2_lp2a2_join(P,rest{:},'ExteriorOptions',[xo,{'SeedSpacing_mm',rungs(k)}]);
 pp=false;if D.pass,PA=g2_lp2a2_pairing_audit(D);pp=PA.pass;D.pairingAudit=PA;end
 fg=D.failedGates;if isempty(fg),fg={};end
 L(end+1)=struct('rung',k,'seedSpacing_mm',rungs(k),'stage',D.stage,'message',D.message,'failedGates',{fg},'pairingPass',pp); %#ok<AGROW>
 D.ladder=L;D.seedRung=k;D.seedSpacing_mm=rungs(k);
 if D.pass&&pp,return,end
 if D.pass&&~pp,D.pass=false;D.stage='HOLD_LP2A2_PAIRING';D.message=strjoin(PA.failedGates,', ');return,end
 if ~strcmp(D.stage,'HOLD_KINKED_PROTECTED_MESH_JOIN')||isempty(fg)||~all(ismember(fg,quality)),return,end
end
D.stage='HOLD_LP2A2_LADDER_EXHAUSTED';D.message=sprintf('All %d seed-spacing rungs fail the global quality gates.',numel(rungs));
end

function c=struct2pv(s)
f=fieldnames(s);c=cell(1,2*numel(f));for k=1:numel(f),c{2*k-1}=f{k};c{2*k}=s.(f{k});end
end
