function A=g2_lp2_analyze(chains,outFile)
%G2_LP2_ANALYZE  Preregistered LP2 comparisons from saved STATE records only (no FEM).
%
%  A = g2_lp2_analyze(chains,outFile)
% chains: struct with fields H, stiff13, soft2, soft1; each a cell array of STATE file paths in
% state order (A0 S0-S4 followed by LP2 S5-Sn), plus optional field terminal.<case> (TERMINAL file).
% For every architecture X and every arclength s present in BOTH chains (identical s_k = 25.4 + 4k
% in LP2-A; never matched by increment number when arclengths differ):
%   F_G(s) = G_X(s)/G_H(s) - 1 (own-path contrast, NOT the M5-X6 direct material effect);
%   d(s) = (tip_X - tip_H) . n_H (signed lateral offset; + towards the left normal of H);
%   heading difference, local MTS angles and their difference, K_II/K_I, tip distances to the
%   three ring circles. Arclengths that differ between chains are matched by piecewise-linear
%   interpolation of G, MTS and K_II/K_I in s over the overlapping interval (flagged).
% Hypotheses H1-H4 are evaluated by fixed rules over the LP2 part of each chain (s >= 41.4 mm).
cases={'H','stiff13','soft2','soft1'};cen=[152.4 69.85;152.4 120.65;152.4 171.45];
for i=1:4
 c=cases{i};L=chains.(c);n=numel(L);Z=struct();
 for k=1:n
  [S,~,ok]=g2_trajectory_record('read',L{k});assert(ok,'G2LP2:HOLD_RECORD_INTEGRITY','Unverifiable state %s.',L{k});
  P=S.polyline_mm;t=S.tangent;Z.s(k)=sum(vecnorm(diff(P),2,2));Z.tip(k,:)=P(end,:);Z.t(k,:)=t;Z.G(k)=S.G;
  Z.KI(k)=S.KI;Z.KII(k)=S.KII;Z.MTS(k)=S.MTS_deg;Z.head(k)=atan2d(t(2),t(1));Z.state(k)=S.stateIndex;
  Z.ring(k,:)=vecnorm(cen-P(end,:),2,2).'-19.05;
 end
 Z.terminal='';if isfield(chains,'terminal')&&isfield(chains.terminal,c)
  [T,~,ok]=g2_trajectory_record('read',chains.terminal.(c));assert(ok,'G2LP2:HOLD_RECORD_INTEGRITY','Terminal record.');Z.terminal=T.classification;
 end
 W.(c)=Z;
end
H=W.H;A=struct('schema','NewMetacomp.G2.LP2.Analysis.v1','definition','own-path contrasts at matching arclength; not the M5-X6 direct material effect');
for i=2:4
 c=cases{i};X=W.(c);[s,iX,iH]=intersect(round(X.s,9),round(H.s,9));
 r=struct('s_mm',s,'interpolated',false,'F_G',X.G(iX)./H.G(iH)-1, ...
  'd_mm',sum((X.tip(iX,:)-H.tip(iH,:)).*[-H.t(iH,2),H.t(iH,1)],2).','dHeading_deg',X.head(iX)-H.head(iH), ...
  'MTS_X_deg',X.MTS(iX),'MTS_H_deg',H.MTS(iH),'dMTS_deg',X.MTS(iX)-H.MTS(iH),'KIIoverKI_X',X.KII(iX)./X.KI(iX), ...
  'KIIoverKI_H',H.KII(iH)./H.KI(iH),'ringDistance_X_mm',X.ring(iX,:),'ringDistance_H_mm',H.ring(iH,:), ...
  'states',X.state(iX),'terminal_X',X.terminal,'terminal_H',H.terminal);
 if numel(s)<min(numel(X.s),numel(H.s))     % unequal arclengths: interpolate over the overlap
  lo=max(min(X.s),min(H.s));hi=min(max(X.s),max(H.s));sg=unique([X.s(X.s>=lo&X.s<=hi),H.s(H.s>=lo&H.s<=hi)]);
  r.s_mm=sg;r.interpolated=true;r.F_G=interp1(X.s,X.G,sg)./interp1(H.s,H.G,sg)-1;r.dMTS_deg=interp1(X.s,X.MTS,sg)-interp1(H.s,H.MTS,sg);
 end
 lp=r.s_mm>=41.4-1e-9;f=r.F_G(lp);
 switch c
  case 'stiff13',r.H1=monotone(f,-1);       % shielding magnitude increases: F_G strictly decreasing
  case 'soft2',r.H2=monotone(abs(f),-1);    % shielding weakens: |F_G| strictly decreasing
 end
 r.H3_ownPathProxy=struct('maxAbs_dMTS_deg_LP2',max(abs(r.dMTS_deg(lp))),'status', ...
  'NOT_TESTABLE_AS_DECOMPOSITION: the S4 compensation was a crossed-solve decomposition; LP2 own paths give only the proxy |MTS_X - MTS_H|');
 A.(c)=r;
end
term={W.H.terminal,W.stiff13.terminal,W.soft2.terminal,W.soft1.terminal};
if all(cellfun(@isempty,term))||all(strcmp(term,'CAMPAIGN_LIMIT_REACHED'))
 A.H4=struct('status','NOT_TESTABLE','reason','no case reached a terminal approach classification','terminals',{term});
else
 ia=strcmp(term,'INTERFACE_APPROACH');
 if any(ia)&&~all(ia),st='SUPPORTED_WITHIN_LP2A';else,st='NOT_SUPPORTED_WITHIN_LP2A';end
 A.H4=struct('status',st,'reason','terminal classifications differ between architectures only if some but not all reach INTERFACE_APPROACH','terminals',{term});
end
A.states=W;
if nargin>1&&~isempty(outFile),fid=fopen(outFile,'w');fwrite(fid,jsonencode(A,'PrettyPrint',true),'char');fclose(fid);end
end
function R=monotone(v,dir)
% Fixed rule over the LP2 part (S4 onward): SUPPORTED if every consecutive change has the sign dir;
% CONTRADICTED if the last value moved against dir relative to the first; otherwise MIXED;
% NOT_TESTABLE with fewer than two points.
if numel(v)<2,R=struct('status','NOT_TESTABLE','values',v);return,end
dv=diff(v);
if all(sign(dv)==dir),st='SUPPORTED';elseif sign(v(end)-v(1))==-dir,st='CONTRADICTED';else,st='MIXED';end
R=struct('status',st,'values',v);
end
