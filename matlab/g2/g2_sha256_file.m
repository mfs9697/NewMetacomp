function h = g2_sha256_file(f)
%G2_SHA256_FILE  Upper-case hex SHA-256 of a file (Java MessageDigest, no toolbox).
assert(isfile(f),'G2SHA:Missing','No such file: %s',f);
fid=fopen(f,'r');b=fread(fid,inf,'*uint8');fclose(fid);
md=java.security.MessageDigest.getInstance('SHA-256');
md.update(b);d=typecast(md.digest(),'uint8');
h=upper(reshape(dec2hex(d,2).',1,[]));
end
