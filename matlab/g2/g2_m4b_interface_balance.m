function B = g2_m4b_interface_balance(fP,PM,activeRings)
%G2_M4B_INTERFACE_BALANCE  Nodal force balance on ACTIVE ring interfaces only (Issue #47).
%
%  B = g2_m4b_interface_balance(fP,PM,activeRings)
% fP: 2N-by-2 per-label internal nodal forces of g2_t6_elasticity_phase (label 1 =
% matrix + inactive rings, label 2 = active rings). On an active interface the two
% labels meet and, with no external load there, fP(:,1) + fP(:,2) = 0 at its nodes.
% Same arithmetic as the legacy g2_material_sif_on_mesh balance and resultant, but
% restricted to the interfaces that carry a material jump. Passive interfaces are
% not tested here (both sides are label 1, no two-material balance exists there).
iNodes=[];res=zeros(1,numel(activeRings));
for k=1:numel(activeRings)
 I=PM.interfaces(activeRings(k));nodes=[I.vertexNodes;I.midsideNodes];iNodes=[iNodes;nodes]; %#ok<AGROW>
 f2=fP([2*nodes-1;2*nodes],2);scale=sum(abs(f2))+realmin;
 res(k)=max(abs([sum(fP(2*nodes-1,2)),sum(fP(2*nodes,2))]))/scale;
end
if isempty(activeRings)
 B=struct('balanceRel',0,'resultantRel',0,'perRingResultantRel',zeros(1,0),'nodes',0);return
end
iDof=[2*iNodes-1;2*iNodes];
bal=max(abs(fP(iDof,1)+fP(iDof,2)))/max(max(abs(fP(iDof,2))),realmin);
B=struct('balanceRel',bal,'resultantRel',max(res),'perRingResultantRel',res,'nodes',numel(iNodes));
end
