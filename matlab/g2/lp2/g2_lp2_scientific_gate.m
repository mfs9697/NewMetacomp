function G=g2_lp2_scientific_gate(C)
%G2_LP2_SCIENTIFIC_GATE  Fail-closed GO_LP2A approval. Hard-coded GO path; no caller path.
% Absent GO -> G2LP2:HOLD_UNAUTHORIZED_STATE. The bytes read are hashed into G.goFileSHA256.
p=fullfile(C.lp2,'G2_LP2A_SCIENTIFIC_GO_v1.json');
assert(isfile(p),'G2LP2:HOLD_UNAUTHORIZED_STATE','LP2-A is on scientific HOLD: no GO_LP2A record.');
fid=fopen(p,'r');assert(fid>=0,'G2LP2:HOLD_UNAUTHORIZED_STATE','GO_LP2A cannot be read.');
raw=fread(fid,inf,'*uint8');fclose(fid);
md=java.security.MessageDigest.getInstance('SHA-256');md.update(raw);
goSHA=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
G=g2_lp2_go_validate(jsondecode(native2unicode(raw.','UTF-8')),C,@(f)contract(C.repo,f));
G.goFileSHA256=goSHA;
end
function E=contract(repo,f)
cf=fullfile(repo,strrep(f,'/',filesep));E=struct('exists',isfile(cf),'sha256','','text','');
if E.exists,E.sha256=lower(g2_sha256_file(cf));E.text=fileread(cf);end
end
