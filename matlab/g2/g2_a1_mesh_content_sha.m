function h=g2_a1_mesh_content_sha(M)
%G2_A1_MESH_CONTENT_SHA  Deterministic SHA-256 of the numerical content of an A1 mesh (Issue #66).
% Independent of the MAT container (v7.3 files carry a creation timestamp): hashes size and
% IEEE bytes of X3, T3, X6, T6, banks, tip node, nodal q, q-active rows, BVP anchor nodes and
% collar outer IDs, in this fixed order. Used to pin the 12 preregistered A1 meshes.
md=java.security.MessageDigest.getInstance('SHA-256');
for f={'X3','T3','X6','T6','upperBankT6','lowerBankT6','physicalTipNode','nodalQ','qActiveT6Rows','extraVertexNodes','collarOuterIDs'}
 v=double(M.(f{1}));md.update(typecast(int64(size(v)),'uint8'));md.update(typecast(v(:),'uint8'));
end
h=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
end
