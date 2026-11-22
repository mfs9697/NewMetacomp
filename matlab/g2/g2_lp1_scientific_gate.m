function G=g2_lp1_scientific_gate(C)
%G2_LP1_SCIENTIFIC_GATE Fail-closed, SHA-bound independent LP1 approval.
% LP0 geometry qualification and the self-generated AuthToken do NOT grant GO.
% Invoked before the run directory is created and before any mesh/FEM solve.
% VG1 (Issue #58): the GO path stays hard-coded below and no caller can supply
% another one. All content checks, unchanged in order and identifiers, are
% factored into the pure function g2_lp1_go_validate so that every mismatch
% branch can be tested on in-memory fixtures without ever writing a GO file.
p=fullfile(C.here,'G2_LP1_SCIENTIFIC_GO_v1.json');
assert(isfile(p),'G2LP1:HOLD_UNAUTHORIZED_STATE', ...
 'LP1 is on scientific HOLD: no separate GO record (PR #55 review).');
G=jsondecode(fileread(p));
G=g2_lp1_go_validate(G,C,@(f)repositoryContract(C.repo,f));
end

function E=repositoryContract(repo,f)
% Fixed reader of the pinned contract evidence. Its path has already been confined
% to matlab/g2/evidence/lp1_preflight/ by g2_lp1_go_validate.
cf=fullfile(repo,strrep(f,'/',filesep));
E=struct('exists',isfile(cf),'sha256','','text','');
if E.exists
 E.sha256=lower(g2_sha256_file(cf));
 E.text=fileread(cf);
end
end
