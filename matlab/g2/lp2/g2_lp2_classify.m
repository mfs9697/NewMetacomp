function T=g2_lp2_classify(R,mask,pol2)
%G2_LP2_CLASSIFY  Pure terminal classification of a candidate LP2 step from g2_lp0_clearance output.
%
%  T = g2_lp2_classify(R,mask,pol2)
% R: g2_lp0_clearance result for the candidate segment (metrics per ring/hole, reasons).
% mask: 1x3 activity of the architecture (1 = active material interface, 0 = passive contour).
% Every failing guard is attributed to an object and a constraint type:
%   PHYSICAL_INTERFACE   guard tied to an ACTIVE ring (material discontinuity)
%   NUMERICAL_RING       guard tied to a PASSIVE ring contour (ownership/mesh guard only)
%   HOLE_BOUNDARY        hole-wall clearance (only reachable through a ring region here)
%   EXTERNAL_BOUNDARY    plate-edge clearance of the segment, tip guide or q domain
%   NUMERICAL_OTHER      self-intersection, invalid input or polygons
% Primary classification (precedence): INTERFACE_APPROACH > HOLE_BOUNDARY_APPROACH >
% EXTERNAL_BOUNDARY_APPROACH > NUMERICAL_HOLD. MATRIX_ADVANCE only if no guard fails.
% INTERFACE_ENCOUNTER is never produced from a candidate: an extrapolated intersection of a
% candidate segment is an approach, not an encounter (an encounter would require an accepted
% state whose crack actually reaches the interface, which LP2-A cannot construct).
g=pol2.geometry;tol=g.distanceTolerance_mm;mask=logical(reshape(mask,1,3));
T=struct('classification','MATRIX_ADVANCE','constraints',struct('object',{},'type',{},'guard',{},'margin_mm',{}), ...
 'activeInterfaceClearance_mm',NaN,'passiveContourClearance_mm',NaN);
if ~R.pass&&(strcmp(R.status,'HOLD_INPUT')||strcmp(R.status,'HOLD_OWNER_MASK'))
 T.classification='NUMERICAL_HOLD';T.constraints(end+1)=struct('object','input','type','NUMERICAL_OTHER','guard',R.status,'margin_mm',NaN);return
end
m=R.metrics;
tipRing=m.tipToNominalRing_mm;if ~isempty(tipRing)
 if any(mask),T.activeInterfaceClearance_mm=min(tipRing(mask));end
 if any(~mask),T.passiveContourClearance_mm=min(tipRing(~mask));end
end
for h=1:3
 if mask(h),ty='PHYSICAL_INTERFACE';else,ty='NUMERICAL_RING';end
 ob=sprintf('ring%d',h);
 add(ob,ty,'tipGuideRadius',m.guideRingMargin_mm(h),m.guideRingMargin_mm(h)<=tol);
 add(ob,ty,'qSupportClearance',m.qRingMargin_mm(h),m.qRingMargin_mm(h)<=tol);
 add(ob,ty,'segmentRingClearance',m.segmentToNominalRing_mm(h)-g.minSegmentRingClearance_mm, ...
  m.segmentToNominalRing_mm(h)<=g.minSegmentRingClearance_mm+tol||m.segmentToRingPolygon_mm(h)<=tol);
 add(sprintf('hole%d',h),'HOLE_BOUNDARY','segmentHoleClearance',m.segmentToHolePolygon_mm(h),m.segmentToHolePolygon_mm(h)<=tol);
end
names={'left','right','bottom','top'};
for s=1:4
 add(['plate_' names{s}],'EXTERNAL_BOUNDARY','tipGuideRadius',m.guidePlateMargin_mm(s),m.guidePlateMargin_mm(s)<=tol);
 add(['plate_' names{s}],'EXTERNAL_BOUNDARY','qSupportClearance',m.qPlateMargin_mm(s),m.qPlateMargin_mm(s)<=tol);
 add(['plate_' names{s}],'EXTERNAL_BOUNDARY','segmentChannel',m.segmentPlate_mm(s)-g.channelHalfWidth_mm,m.segmentPlate_mm(s)<=g.channelHalfWidth_mm+tol);
end
if any(strcmp(R.reasons,'HOLD_CRACK_SELF_INTERSECTION'))
 T.constraints(end+1)=struct('object','crack','type','NUMERICAL_OTHER','guard','selfIntersectionOrMiter','margin_mm',m.nonadjacentSegment_mm);
end
if ~R.pass&&isempty(T.constraints)
 T.constraints(end+1)=struct('object','unattributed','type','NUMERICAL_OTHER','guard',strjoin(R.reasons,','),'margin_mm',NaN);
end
types={T.constraints.type};
if isempty(types),T.classification='MATRIX_ADVANCE';
elseif any(strcmp(types,'PHYSICAL_INTERFACE')),T.classification='INTERFACE_APPROACH';
elseif any(strcmp(types,'HOLE_BOUNDARY')),T.classification='HOLE_BOUNDARY_APPROACH';
elseif any(strcmp(types,'EXTERNAL_BOUNDARY')),T.classification='EXTERNAL_BOUNDARY_APPROACH';
else,T.classification='NUMERICAL_HOLD';
end
assert(strcmp(T.classification,'MATRIX_ADVANCE')==R.pass,'G2LP2:HOLD_CLASSIFICATION', ...
 'Classification %s inconsistent with clearance pass=%d (%s).',T.classification,R.pass,strjoin(R.reasons,','));
 function add(ob,ty,gd,mg,fails)
  if fails,T.constraints(end+1)=struct('object',ob,'type',ty,'guard',gd,'margin_mm',mg);end
 end
end
