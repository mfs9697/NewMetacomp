function A=g2_lp2_analyze(chains,outFile)
%G2_LP2_ANALYZE  Preregistered LP2-A1 comparisons from saved STATE records only (no FEM).
%
%  A = g2_lp2_analyze(chains,outFile)
% chains: struct with fields H, stiff13, soft2, soft1; each a cell array of STATE file paths in
% state order (A0 S0-S4 followed by LP2 S5-Sn); optional chains.terminal.<case> = TERMINAL file.
% LP2-A1 uses equal 4-mm increments: comparisons are made ONLY at arclengths accepted in BOTH
% chains. Chains whose common arclengths are not their full prefixes (unequal increments) are
% REJECTED (G2LP2:ANALYSIS_UNSUPPORTED); interpolation belongs to a later work package.
% Per architecture X at matching s:
%   F_G(s) = G_X(s)/G_H(s) - 1 (own-path contrast, NOT the M5-X6 direct material effect);
%   d(s) = (tip_X - tip_H) . n_H; heading difference; local MTS angles and
%   dMTS(s) = theta_X - theta_H (a DESCRIPTIVE proxy of local directional increments, not a
%   decomposition); K_II/K_I; tip distances to the three ring circles.
% Hypotheses over the LP2 part (s >= 41.4 mm), fixed rules:
%   H1 (stiff13) / H2 (soft2) apply only while F_G < 0 at every point: H1 SUPPORTED if F_G strictly
%   decreases (more negative), H2 SUPPORTED if F_G strictly increases towards zero; CONTRADICTED if
%   the last value moved against the hypothesis relative to the first; MIXED otherwise.
%   A change of sign of F_G is SIGN_TRANSITION (shielding-to-amplification or the reverse) and never
%   counts as continued strengthening/weakening; F_G > 0 throughout is NO_SHIELDING; fewer than two
%   points is INSUFFICIENT_EVIDENCE.
%   H3 is DESCRIPTIVE_PROXY_ONLY. H4 is NOT_TESTABLE_WITHIN_LP2_A1 with a descriptive terminal table.
cases={'H','stiff13','soft2','soft1'};cen=[152.4 69.85;152.4 120.65;152.4 171.45];
for i=1:4
 c=cases{i};L=chains.(c);n=numel(L);Z=struct('terminal',struct());
 for k=1:n
  [S,~,ok]=g2_trajectory_record('read',L{k});assert(ok,'G2LP2:HOLD_RECORD_INTEGRITY','Unverifiable state %s.',L{k});
  P=S.polyline_mm;t=S.tangent;Z.s(k)=sum(vecnorm(diff(P),2,2));Z.tip(k,:)=P(end,:);Z.t(k,:)=t;Z.G(k)=S.G;
  Z.KI(k)=S.KI;Z.KII(k)=S.KII;Z.MTS(k)=S.MTS_deg;Z.head(k)=atan2d(t(2),t(1));Z.state(k)=S.stateIndex;
  Z.ring(k,:)=vecnorm(cen-P(end,:),2,2).'-19.05;
 end
 if isfield(chains,'terminal')&&isfield(chains.terminal,c)
  [T,~,ok]=g2_trajectory_record('read',chains.terminal.(c));assert(ok,'G2LP2:HOLD_RECORD_INTEGRITY','Terminal record.');Z.terminal=T;
 end
 W.(c)=Z;
end
H=W.H;A=struct('schema','NewMetacomp.G2.LP2.Analysis.v2','definition', ...
 'own-path contrasts at matching accepted arclengths; not the M5-X6 direct material effect; dMTS is a descriptive proxy');
for i=2:4
 c=cases{i};X=W.(c);[s,iX,iH]=intersect(round(X.s,9),round(H.s,9),'stable');
 nmin=min(numel(X.s),numel(H.s));
 assert(numel(s)==nmin&&isequal(round(X.s(1:nmin),9),round(H.s(1:nmin),9)),'G2LP2:ANALYSIS_UNSUPPORTED', ...
  '%s and H do not share their accepted arclengths (unequal increments): interpolation is not supported in LP2-A1.',c);
 r=struct('s_mm',s,'F_G',X.G(iX)./H.G(iH)-1, ...
  'd_mm',sum((X.tip(iX,:)-H.tip(iH,:)).*[-H.t(iH,2),H.t(iH,1)],2).','dHeading_deg',X.head(iX)-H.head(iH), ...
  'MTS_X_deg',X.MTS(iX),'MTS_H_deg',H.MTS(iH),'dMTS_deg',X.MTS(iX)-H.MTS(iH),'KIIoverKI_X',X.KII(iX)./X.KI(iX), ...
  'KIIoverKI_H',H.KII(iH)./H.KI(iH),'ringDistance_X_mm',X.ring(iX,:),'ringDistance_H_mm',H.ring(iH,:),'states',X.state(iX));
 lp=r.s_mm>=41.4-1e-9;f=r.F_G(lp);
 switch c
  case 'stiff13',r.H1=shielding(f,'strengthen');
  case 'soft2',r.H2=shielding(f,'weaken');r.soft2Classification='INCONCLUSIVE (unchanged)';
 end
 r.H3=struct('status','DESCRIPTIVE_PROXY_ONLY','dMTS_deg_LP2',r.dMTS_deg(lp),'dHeading_deg_LP2',r.dHeading_deg(lp),'d_mm_LP2',r.d_mm(lp), ...
  'note','own-path differences of local MTS increments, headings and lateral offsets; no material/path/interaction decomposition');
 A.(c)=r;
end
rows={};
for i=1:4
 c=cases{i};T=W.(c).terminal;
 if isempty(fieldnames(T)),rows{end+1}=struct('caseId',c,'available',false);continue,end %#ok<AGROW>
 g={};if ~isempty(T.candidate.constraints),g=unique({T.candidate.constraints.guard});end
 ob={};if ~isempty(T.candidate.constraints),ob=unique({T.candidate.constraints.object});end
 rows{end+1}=struct('caseId',c,'available',true,'classification',T.classification,'lastAcceptedState',T.lastAcceptedState, ...
  'lastTip_mm',T.lastTip_mm,'approachedObjects',{ob},'ringMask',T.mask,'nearestRing',T.nearestRing,'nearestRingActive',T.nearestRingActive, ...
  'clearanceToRingCircles_mm',T.lastTipToRingCircle_mm,'terminatingGuards',{g},'truncatedByCeiling',T.truncatedByCeiling); %#ok<AGROW>
end
A.H4=struct('status','NOT_TESTABLE_WITHIN_LP2_A1','reason', ['LP2-A1 cannot reach an interface: a numerical approach is not an encounter, ' ...
 'a passive ring contour is not a material discontinuity, and labels differ by mask for the same geometric approach'],'terminals',{rows});
A.states=W;
if nargin>1&&~isempty(outFile),fid=fopen(outFile,'w');fwrite(fid,jsonencode(A,'PrettyPrint',true),'char');fclose(fid);end
end
function R=shielding(v,mode)
if numel(v)<2,R=struct('status','INSUFFICIENT_EVIDENCE','values',v);return,end
sg=sign(v);
if all(sg>0),R=struct('status','NO_SHIELDING','values',v);return,end
if ~all(sg<0)
 if v(1)<0&&v(end)>0,tr='SHIELDING_TO_AMPLIFICATION';elseif v(1)>0&&v(end)<0,tr='AMPLIFICATION_TO_SHIELDING';else,tr='SIGN_CHANGES';end
 R=struct('status','SIGN_TRANSITION','transition',tr,'values',v);return
end
dv=diff(v);if strcmp(mode,'strengthen'),dir=-1;else,dir=+1;end
if all(sign(dv)==dir),st='SUPPORTED';elseif sign(v(end)-v(1))==-dir,st='CONTRADICTED';else,st='MIXED';end
R=struct('status',st,'values',v);
end
