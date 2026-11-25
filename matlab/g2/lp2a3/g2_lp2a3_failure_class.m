function k=g2_lp2a3_failure_class(identifier,stateFolderExists)
%G2_LP2A3_FAILURE_CLASS  g2_lp2_failure_class (unchanged) plus the LP2-A3 local identifiers.
% LOCAL (this case ends with TERMINAL NUMERICAL_HOLD; other cases continue): rung-1 mesh failure,
% pairing audit, phase/owner/audit of this mesh, actual-polygon clearance, classification, SIF gates,
% MTS root of this candidate. Memory, campaign refusal and every other identifier keep the inherited
% classes (PREADMISSION_MEMORY, CAMPAIGN_REFUSAL, GLOBAL).
local={'G2LP2A3:HOLD_MESH_QUALITY','G2LP2A3:HOLD_PAIRING','G2LP2A3:HOLD_INTERFACE_APPROACH','G2LP2A3:HOLD_CLASSIFICATION', ...
 'G2LP2A3:HOLD_K_EXTRACTION','G2LP2A3:HOLD_PHASE'};
id=char(identifier);
if any(strcmp(id,local)),k='LOCAL';else,k=g2_lp2_failure_class(id,stateFolderExists);end
end
