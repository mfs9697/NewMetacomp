function M = g2_m4b_r1_matched_check(Dalt,Dorig)
%G2_M4B_R1_MATCHED_CHECK  Is an alternative-family mesh on EXACTLY the original S2 crack? (Issue #50)
%
%  M = g2_m4b_r1_matched_check(Dalt,Dorig)
% Bitwise rule of G2_M4B_R1_POLICY_v1 (no tolerance): crackPolyline, tipTangent and the
% physical tip coordinates of Dalt equal those of Dorig (isequal), and the shared p010 core,
% collar and q-active row counts are equal. Also reports, for information, the number of
% polyline vertices, the ring-independent tip-frame and the element counts. A failure is
% HOLD_MATCHED_S2ALT in the R1 controller; nothing is written.
c=struct();
c.polylineBitwise=isfield(Dalt,'crackPolyline')&&isfield(Dorig,'crackPolyline')&&isequal(Dalt.crackPolyline,Dorig.crackPolyline);
c.tipTangentBitwise=isfield(Dalt,'tipTangent')&&isfield(Dorig,'tipTangent')&&isequal(Dalt.tipTangent(:),Dorig.tipTangent(:));
c.tipCoordinatesBitwise=isequal(Dalt.X6(Dalt.physicalTipNode,:),Dorig.X6(Dorig.physicalTipNode,:));
cnt=@(D)[numel(D.elementRows.core),numel(D.elementRows.collar),numel(D.qActiveT6Rows)];
c.coreCollarQCountsEqual=isequal(cnt(Dalt),cnt(Dorig));
f=fieldnames(c);ok=cellfun(@(k)c.(k),f);
M=struct('pass',all(ok),'checks',c,'failed',{f(~ok)},'polylineVertices',size(Dalt.crackPolyline,1), ...
 'coreCollarQ_alt',cnt(Dalt),'coreCollarQ_orig',cnt(Dorig),'T3_alt',size(Dalt.T6,1),'T3_orig',size(Dorig.T6,1));
fprintf('M4B_R1_MATCHED pass=%d polyline=%d tangent=%d tip=%d core/collar/q=%d (T3 alt %d, orig %d)\n',M.pass, ...
 c.polylineBitwise,c.tipTangentBitwise,c.tipCoordinatesBitwise,c.coreCollarQCountsEqual,M.T3_alt,M.T3_orig);
end
