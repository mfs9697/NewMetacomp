function T=check_g2_lp0_clearance()
% Small deterministic algebra tests only: no PDE, mesh, SIF or physical solve.
here=fileparts(mfilename('fullpath'));pol=jsondecode(fileread(fullfile(here,'G2_LP1_POLICY_v1.json')));
C=pol.geometry.centres_mm;geo=struct('centres',C,'ringPolygons',{{}},'holePolygons',{{}});
for h=1:3
 a=(0:75)'*2*pi/76;geo.ringPolygons{h}=C(h,:)+19.05*[cos(a),sin(a)];
 a=(0:119)'*2*pi/120;geo.holePolygons{h}=C(h,:)+6.35*[cos(a),sin(a)];
end
P=pol.startPolyline_mm;rows=struct('name',{},'pass',{},'status',{});
r=g2_lp0_clearance(P,P(end,:)+4*[sind(12),cosd(12)],geo,pol);add('admissible_increment',r.pass,r.status);
% Endpoint-only checking would miss both ring crossings and the intervening hole.
r=g2_lp0_clearance([P;110 69.85],[190 69.85],geo,pol);
add('ring_and_hole_tunnel',has(r,'HOLD_INTERFACE_APPROACH')&&r.metrics.segmentToRingPolygon_mm(1)==0&&r.metrics.segmentToHolePolygon_mm(1)==0,r.status);
r=g2_lp0_clearance([P;110 88.9],[190 88.9],geo,pol);add('nominal_ring_tangent',has(r,'HOLD_INTERFACE_APPROACH'),r.status);
r=g2_lp0_clearance([P;110 95],[125 69.85],geo,pol);add('guide_overlap_only',has(r,'HOLD_TIP_GUIDE')&&~has(r,'HOLD_Q_PHASE'),r.status);
r=g2_lp0_clearance([P;110 69.85],[130 69.85],geo,pol);add('q_buffer_overlap',has(r,'HOLD_Q_PHASE'),r.status);
r=g2_lp0_clearance([P;110 69.85],[134 69.85],geo,pol);add('endpoint_in_annulus',has(r,'HOLD_INTERFACE_APPROACH'),r.status);
r=g2_lp0_clearance([P;101.6 180],[101.6 205],geo,pol);add('top_boundary_cross',has(r,'HOLD_EXTERNAL_BOUNDARY'),r.status);
r=g2_lp0_clearance([P;101.6 180],[101.6 203.2],geo,pol);add('boundary_grazing',has(r,'HOLD_EXTERNAL_BOUNDARY'),r.status);
r=g2_lp0_clearance([P;101.6 180],[101.6 189],geo,pol);add('guide_before_boundary',has(r,'HOLD_TIP_GUIDE')&&~has(r,'HOLD_EXTERNAL_BOUNDARY'),r.status);
r=g2_lp0_clearance([P;110 35;90 35],[110 20],geo,pol);add('prior_segment_cross',has(r,'HOLD_CRACK_SELF_INTERSECTION'),r.status);
r=g2_lp0_clearance(P,[101.6 21.4],geo,pol);add('adjacent_retrace',has(r,'HOLD_CRACK_SELF_INTERSECTION'),r.status);
bad=geo;bad.centres=flipud(C);r=g2_lp0_clearance(P,[102 29.4],bad,pol);add('wrong_ring_id',strcmp(r.status,'HOLD_OWNER_MASK'),r.status);
bad=geo;bad.ringPolygons{1}(1,1)=bad.ringPolygons{1}(1,1)+.01;r=g2_lp0_clearance(P,[102 29.4],bad,pol);add('geometry_drift',strcmp(r.status,'HOLD_OWNER_MASK'),r.status);
bad=geo;bad.ringPolygons{1}=bad.ringPolygons{1}([2 1 3:end],:);r=g2_lp0_clearance(P,[102 29.4],bad,pol);add('unordered_polygon',strcmp(r.status,'HOLD_OWNER_MASK'),r.status);
bad=geo;bad.ringPolygons{1}=bad.ringPolygons{1}(1:end-1,:);r=g2_lp0_clearance(P,[102 29.4],bad,pol);add('missing_chord',strcmp(r.status,'HOLD_OWNER_MASK'),r.status);
for c=1:4
 % Activity is intentionally absent from the geometric oracle inputs.
 r=g2_lp0_clearance([P;110 69.85],[190 69.85],geo,pol);
 add(['passive_boundary_stays_obstacle_',pol.cases(c).id],has(r,'HOLD_INTERFACE_APPROACH'),r.status);
end
r=g2_lp0_clearance(P,[NaN 30],geo,pol);add('nan_rejected',strcmp(r.status,'HOLD_INPUT'),r.status);
r=g2_lp0_clearance(P,P(end,:),geo,pol);add('zero_length_rejected',strcmp(r.status,'HOLD_INPUT'),r.status);
% Translation/rotation of a synthetic diagnostic segment is not used as a path.
for n=[5 6]
 Q=P;for k=1:n-2,Q(end+1,:)=Q(end,:)+4*[sind(11+k),cosd(11+k)];end %#ok<AGROW>
 r=g2_lp0_clearance(Q(1:end-1,:),Q(end,:),geo,pol);add(sprintf('synthetic_N%d_geometric_only',n),r.pass,r.status);
end
T=struct('pass',all([rows.pass]),'passed',nnz([rows.pass]),'total',numel(rows),'tests',rows, ...
 'meshQualification',false,'physicalSolves',0);
fprintf('G2_LP0_CLEARANCE_TESTS=%d/%d; NO_MESH=1; NO_FEM=1\n',T.passed,T.total);
assert(T.pass,'G2LP0:ClearanceTests','A continuous-clearance test failed.');
 function add(name,pass,status)
  rows(end+1)=struct('name',name,'pass',logical(pass),'status',status);
  fprintf('%s %d %s\n',name,pass,status);
 end
end
function y=has(r,s),y=ismember(s,r.reasons);end
