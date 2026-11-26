function [h,meta]=g2_lp2b1eq_canon(D)
%G2_LP2B1EQ_CANON  Canonical array digest of a mesh, IDENTICAL serialization to canon() of g2_lp2b1_attempt.
%  [h,meta] = g2_lp2b1eq_canon(D)
% h: SHA-256 over X3,T3,X6,T6,upperBankT6,lowerBankT6,nodalQ,qActiveT6Rows,crackPolyline in this order; for each
%    array a: typecast(int64(size(a)),'uint8') then typecast(double(a(:)),'uint8') (column-major, little endian).
% meta: SHA-256 of the metadata NOT covered by h (reported only; admission compares these by isequal): elementRows
%    (sorted field names, each as above), extraVertexXY, physicalTipNode, gates (sorted names, logical -> double).
md=java.security.MessageDigest.getInstance('SHA-256');
for f={'X3','T3','X6','T6','upperBankT6','lowerBankT6','nodalQ','qActiveT6Rows','crackPolyline'},put(md,D.(f{1}));end
h=hex(md);meta='';
if nargout>1&&all(isfield(D,{'elementRows','extraVertexXY','physicalTipNode','gates'}))
 md=java.security.MessageDigest.getInstance('SHA-256');
 er=D.elementRows;fn=sort(fieldnames(er));for k=1:numel(fn),md.update(unicode2native(fn{k},'UTF-8'));put(md,er.(fn{k}));end
 put(md,D.extraVertexXY);put(md,D.physicalTipNode);
 g=D.gates;fn=sort(fieldnames(g));for k=1:numel(fn),md.update(unicode2native(fn{k},'UTF-8'));put(md,g.(fn{k}));end
 meta=hex(md);
end
end
function put(md,a),a=double(a);md.update(typecast(int64(size(a)),'uint8'));md.update(typecast(a(:),'uint8'));end
function s=hex(md),s=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));end
