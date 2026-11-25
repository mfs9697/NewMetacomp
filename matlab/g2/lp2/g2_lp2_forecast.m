function F=g2_lp2_forecast(parent,pol2)
%G2_LP2_FORECAST  Deterministic signed-MTS forecast of the next LP2 state (geometry only, no FEM).
% Identical recurrence to the accepted g2_lp1_forecast (same g2_mts_direction root, same frame
% and sign conventions, same 4-mm increment); only the hard caps come from the LP2 policy:
%   theta_n = theta_MTS(K_I,n, K_II,n),  t_(n+1) = cos(theta_n) t_n + sin(theta_n) n_n,
%   x_(n+1) = x_n + 4 t_(n+1),  n_n = R(+90 deg) t_n.
% The parent is an accepted STATE record (stateIndex, polyline_mm, tangent, KI, KII).
k=parent.stateIndex+1;c=pol2.caps;
assert(k>=c.firstStateIndex&&k<=c.maxStateIndex,'G2LP2:HOLD_UNAUTHORIZED_STATE', ...
 'State S%d is outside the LP2 policy (S%d-S%d).',k,c.firstStateIndex,c.maxStateIndex);
M=g2_mts_direction(parent.KI,parent.KII);
assert(M.admissibleForStep&&strcmp(M.status,'OK')&&M.stationarityResidual_rel<=1e-12,'G2LP2:HOLD_K_EXTRACTION','Invalid tensile MTS root.');
P=parent.polyline_mm;t=parent.tangent;n=[-t(2),t(1)];tn=cos(M.theta_rad)*t+sin(M.theta_rad)*n;
Q=[P;P(end,:)+c.increment_mm*tn];arc=sum(vecnorm(diff(Q),2,2));
assert(abs(arc-(c.initialArc_mm+c.increment_mm*k))<=1e-9&&arc<=c.maxArcLength_mm+1e-9,'G2LP2:HOLD_UNAUTHORIZED_STATE','Arc or increment cap.');
F=struct('stateIndex',k,'polyline_mm',Q,'tangent',tn,'arc_mm',arc,'parentMTS_deg',M.theta_deg, ...
 'heading_deg',atan2d(tn(2),tn(1)));
end
