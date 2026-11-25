function G=g2_m5x6_scientific_gate(C)
%G2_M5X6_SCIENTIFIC_GATE  Fail-closed GO_M5_X6 approval. Hard-coded GO path; no caller path.
% The GO bytes are read once and their SHA-256 is returned as G.goFileSHA256, so the campaign
% receipt binds exactly the GO that was validated. The A0 and A1 GO paths are never read.
% Absent GO -> G2M5X6:HOLD_UNAUTHORIZED_STATE. No folder, ledger, mesh or solve.
p=fullfile(C.x6,'G2_M5_X6_SCIENTIFIC_GO_v1.json');
assert(isfile(p),'G2M5X6:HOLD_UNAUTHORIZED_STATE','M5-X6 is on scientific HOLD: no GO_M5_X6 record.');
fid=fopen(p,'r');assert(fid>=0,'G2M5X6:HOLD_UNAUTHORIZED_STATE','GO_M5_X6 cannot be read.');
raw=fread(fid,inf,'*uint8');fclose(fid);
md=java.security.MessageDigest.getInstance('SHA-256');md.update(raw);
goSHA=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
G=jsondecode(native2unicode(raw.','UTF-8'));
G=g2_m5x6_go_validate(G,C,@(f)repositoryContract(C.repo,f));
G.goFileSHA256=goSHA;
end

function E=repositoryContract(repo,f)
cf=fullfile(repo,strrep(f,'/',filesep));
E=struct('exists',isfile(cf),'sha256','','text','');
if E.exists,E.sha256=lower(g2_sha256_file(cf));E.text=fileread(cf);end
end
