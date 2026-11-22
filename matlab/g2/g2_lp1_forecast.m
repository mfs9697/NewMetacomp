function F=g2_lp1_forecast(parent,pol)
% Deterministic signed-MTS forecast, with hard caps before any geometry or FEM.
k=parent.stateIndex+1;
assert(k>=1&&k<=4&&k<=pol.caps.maxStateIndex,'G2LP1:HOLD_UNAUTHORIZED_STATE','S5 and later states are forbidden.');
M=g2_mts_direction(parent.KI,parent.KII);
assert(M.admissibleForStep&&strcmp(M.status,'OK')&&M.stationarityResidual_rel<=1e-12,'G2LP1:HOLD_K_EXTRACTION','Invalid tensile MTS root.');
P=parent.polyline_mm;t=parent.tangent;n=[-t(2),t(1)];tn=cos(M.theta_rad)*t+sin(M.theta_rad)*n;
Q=[P;P(end,:)+4*tn];arc=sum(vecnorm(diff(Q),2,2));
assert(arc<=41.4+1e-9&&abs(arc-(25.4+4*k))<=1e-9,'G2LP1:HOLD_UNAUTHORIZED_STATE','Arc or increment cap.');
F=struct('stateIndex',k,'polyline_mm',Q,'tangent',tn,'arc_mm',arc,'parentMTS_deg',M.theta_deg);
end
