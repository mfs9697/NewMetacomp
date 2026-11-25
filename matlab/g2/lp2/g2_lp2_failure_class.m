function k=g2_lp2_failure_class(identifier,stateFolderExists)
%G2_LP2_FAILURE_CLASS  Pure classification of an exception raised while advancing one LP2 case.
%
%  k = g2_lp2_failure_class(identifier, stateFolderExists)
%  'LOCAL'                 trajectory-attributable numerical failure: mesh generation or audit,
%                          kink geometry, phase/owner map of THIS mesh, solver, SIF gates, MTS root,
%                          actual-polygon clearance or classification of THIS candidate. The case
%                          ends with TERMINAL(NUMERICAL_HOLD); other cases may continue.
%  'PREADMISSION_MEMORY'   G2LP1:HOLD_MEMORY before the state folder exists (global; ledger HOLD).
%  'CAMPAIGN_REFUSAL'      G2LP1:HOLD_CAMPAIGN_* before the state folder exists (global; nothing written).
%  'GLOBAL'                everything else: source, policy, authorization, record or ledger integrity,
%                          memory after admission, any unexpected error. The campaign stops; no
%                          terminal record, no closure, no resumption.
local={'G2LP2:HOLD_MESH_QUALITY','G2LP2:HOLD_K_EXTRACTION','G2LP2:HOLD_INTERFACE_APPROACH','G2LP2:HOLD_CLASSIFICATION', ...
 'G2LP1:HOLD_MESH_QUALITY','G2LP1:HOLD_OWNER_MASK'};
localPrefix={'G2KJ:','G2KA:','G2KB:','G2KExt:','G2KExterior:','G2M4B:','G2M4BV:','G2T6P:','G2MPM:','PRH:','pde:'};
id=char(identifier);
if any(strcmp(id,local))||any(cellfun(@(p)startsWith(id,p),localPrefix)),k='LOCAL';
elseif strcmp(id,'G2LP1:HOLD_MEMORY')&&~stateFolderExists,k='PREADMISSION_MEMORY';
elseif startsWith(id,'G2LP1:HOLD_CAMPAIGN_')&&~stateFolderExists,k='CAMPAIGN_REFUSAL';
else,k='GLOBAL';
end
end
