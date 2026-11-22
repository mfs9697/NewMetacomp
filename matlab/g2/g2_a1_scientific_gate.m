function G=g2_a1_scientific_gate(C)
%G2_A1_SCIENTIFIC_GATE  Fail-closed A1 approval (Issue #66). Hard-coded GO path; no caller path.
% The GO bytes are read once and their SHA-256 is returned as G.goFileSHA256, so the campaign
% receipt binds exactly the GO that was validated. The A0 GO path is never read here.
p=fullfile(C.here,'G2_A1_SCIENTIFIC_GO_v1.json');
assert(isfile(p),'G2A1:HOLD_UNAUTHORIZED_STATE','A1 is on scientific HOLD: no separate A1 GO record.');
fid=fopen(p,'r');assert(fid>=0,'G2A1:HOLD_UNAUTHORIZED_STATE','A1 GO cannot be read.');
raw=fread(fid,inf,'*uint8');fclose(fid);
md=java.security.MessageDigest.getInstance('SHA-256');md.update(raw);
goSHA=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
G=jsondecode(native2unicode(raw.','UTF-8'));
G=g2_a1_go_validate(G,C,@(f)repositoryContract(C.repo,f));
G.goFileSHA256=goSHA;
end

function E=repositoryContract(repo,f)
cf=fullfile(repo,strrep(f,'/',filesep));
E=struct('exists',isfile(cf),'sha256','','text','');
if E.exists,E.sha256=lower(g2_sha256_file(cf));E.text=fileread(cf);end
end
