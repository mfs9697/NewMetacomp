function A = g2_m4b_ring_activation(ownerRing,mask)
%G2_M4B_RING_ACTIVATION  Ring owner + binary activity mask -> assembly labels (Issue #47).
%
%  A = g2_m4b_ring_activation(ownerRing,mask)
% ownerRing: M-by-1 topological ring ID (0 matrix, 1..3 ring) from the qualified
% mapper (PM.annulusOf). mask: 1-by-3 logical/0-1 activity of rings 1, 2, 3.
%   active(e)          = ownerRing(e) > 0 && mask(ownerRing(e))
%   phaseForAssembly(e) = 1 + active(e)   (mats(1) matrix, mats(2) active material)
% ownerRing is returned unchanged as a separate field: the material phase and the
% topological band ownership are never merged.
ownerRing=ownerRing(:);
assert(all(ownerRing==round(ownerRing))&&all(ownerRing>=0&ownerRing<=3),'G2M4B:OwnerRing','ownerRing must be integers 0..3.');
assert(isequal(size(mask),[1 3])&&all(mask==0|mask==1),'G2M4B:Mask','mask must be a 1-by-3 binary vector.');
mask=logical(mask);
active=false(size(ownerRing));sel=ownerRing>0;
active(sel)=mask(ownerRing(sel));
A=struct('ownerRing',ownerRing,'mask',mask,'bits',char('0'+mask),'active',active, ...
 'phaseForAssembly',1+double(active),'activeRings',find(mask),'nActiveRings',nnz(mask), ...
 'activeElements',nnz(active));
end
