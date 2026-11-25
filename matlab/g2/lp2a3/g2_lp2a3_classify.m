function T=g2_lp2a3_classify(R,mask,pol,tip)
%G2_LP2A3_CLASSIFY  LP2-A3 candidate classification: the unchanged g2_lp2_classify plus the 1-mm
% ring-proximity guard (g2_lp2a3_guard) on the full-precision candidate tip.
%  T = g2_lp2a3_classify(R,mask,pol,tip)    R = g2_lp0_clearance of the candidate segment
% Constraints of both are kept (object, type, guard, margin). Classification precedence:
% INTERFACE_APPROACH > HOLE_BOUNDARY_APPROACH > EXTERNAL_BOUNDARY_APPROACH > PASSIVE_CONTOUR_APPROACH
% > NUMERICAL_HOLD; MATRIX_ADVANCE only if the inherited clearance AND the guard pass.
% PASSIVE_CONTOUR_APPROACH: every failing constraint is NUMERICAL_RING (a passive ring contour).
% A candidate classification is never INTERFACE_ENCOUNTER and never implies arrest.
T=g2_lp2_classify(R,mask,pol);G=g2_lp2a3_guard(tip,mask,pol);
T.ringProximity=G;
T.constraints=[T.constraints,G.constraints];
types={T.constraints.type};
if isempty(types),T.classification='MATRIX_ADVANCE';
elseif any(strcmp(types,'PHYSICAL_INTERFACE')),T.classification='INTERFACE_APPROACH';
elseif any(strcmp(types,'HOLE_BOUNDARY')),T.classification='HOLE_BOUNDARY_APPROACH';
elseif any(strcmp(types,'EXTERNAL_BOUNDARY')),T.classification='EXTERNAL_BOUNDARY_APPROACH';
elseif all(strcmp(types,'NUMERICAL_RING')),T.classification='PASSIVE_CONTOUR_APPROACH';
else,T.classification='NUMERICAL_HOLD';
end
assert(strcmp(T.classification,'MATRIX_ADVANCE')==(R.pass&&G.pass),'G2LP2A3:HOLD_CLASSIFICATION','Classification %s inconsistent with clearance %d / guard %d.',T.classification,R.pass,G.pass);
end
