function G=g2_lp2a3_guard(tip,mask,pol)
%G2_LP2A3_GUARD  Conservative nominal ring-proximity guard of LP2-A3 (pure; full precision).
%  G = g2_lp2a3_guard(tip,mask,pol)
% gap_i = ||tip - c_i|| - R_ring - R_guide for EVERY ring i (activity does not matter);
% pass iff min_i gap_i >= minGap (1 mm). Exactly 1 mm passes; anything below fails; no rounding,
% no tolerance. Each failing ring is attributed: active -> PHYSICAL_INTERFACE, passive -> NUMERICAL_RING.
% A failure is a proximity stop of a candidate; it is not an interface encounter or crack arrest.
g=pol.ringProximityGuard;cen=pol.geometry.centres_mm;mask=logical(reshape(mask,1,3));
assert(isnumeric(tip)&&numel(tip)==2&&all(isfinite(tip)),'G2LP2A3:HOLD_INPUT','Tip must be a finite 1x2 point.');
gap=vecnorm(cen-reshape(tip,1,2),2,2).'-g.ringR_mm-g.guideRadius_mm;
fails=gap<g.minGap_mm;
G=struct('pass',~any(fails),'gap_mm',gap,'minGap_mm',min(gap),'threshold_mm',g.minGap_mm,'margin_mm',gap-g.minGap_mm, ...
 'constraints',struct('object',{},'type',{},'guard',{},'margin_mm',{}));
for i=find(fails)
 if mask(i),ty='PHYSICAL_INTERFACE';else,ty='NUMERICAL_RING';end
 G.constraints(end+1)=struct('object',sprintf('ring%d',i),'type',ty,'guard','guideRingGap1mm','margin_mm',gap(i)-g.minGap_mm);
end
end
