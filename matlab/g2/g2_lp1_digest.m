function h=g2_lp1_digest(s)
md=java.security.MessageDigest.getInstance('SHA-256');md.update(unicode2native(char(s),'UTF-8'));
h=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
end
