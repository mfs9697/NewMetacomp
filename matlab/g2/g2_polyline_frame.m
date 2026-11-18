function F = g2_polyline_frame(P)
%G2_POLYLINE_FRAME  Segment tangents/normals and the last-segment tip frame of a crack polyline (mm).
% P: N-by-2, mouth first, tip last. n = R(+90 deg) t; the upper face is on +n.
% Shared by the kinked block and the kinked exterior so that both compute the
% analytic collar/rim coordinates with bit-identical arithmetic.
assert(isnumeric(P)&&size(P,2)==2&&size(P,1)>=2&&all(isfinite(P(:))),'G2Frame:Polyline','Polyline must be finite N-by-2, N>=2.');
ds=diff(P,1,1);L=sqrt(ds(:,1).^2+ds(:,2).^2);
assert(all(L>0),'G2Frame:ZeroSegment','Zero-length crack segment.');
tt=ds./L;nn=[-tt(:,2),tt(:,1)];
F=struct('P',P,'segmentLengths',L,'tt',tt,'nn',nn,'tip',P(end,:),'t',tt(end,:),'n',nn(end,:), ...
 'stations',[0;cumsum(L)]);
F.tangentDots=sum(tt(1:end-1,:).*tt(2:end,:),2);
F.turns_deg=atan2d(tt(1:end-1,1).*tt(2:end,2)-tt(1:end-1,2).*tt(2:end,1),F.tangentDots);
end
