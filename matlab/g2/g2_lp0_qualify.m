function R=g2_lp0_qualify(varargin)
% Default dry is read-only preflight. Explicit mesh mode is geometry-only.
% A failed test terminates the suite; no alternative mesh or automatic retry.
% No call from this module or its phase wrapper solves elasticity.
ip=inputParser;addParameter(ip,'Mode','dry',@(x)ismember(x,{'dry','mesh'}));
addParameter(ip,'AuthToken','',@(x)ischar(x)||isstring(x));parse(ip,varargin{:});o=ip.Results;
R=g2_lp0_preflight();R.probes=struct();
if ~R.pass||strcmp(o.Mode,'dry'),return,end
assert(strcmp(char(o.AuthToken),R.token),'G2LP0:Token','Token must bind committed source, policy, geometry, all four cases and cap.');
R.pass=false;R.status='HOLD_LP0_FEASIBILITY';
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));addpath(fullfile(here,'vendor_p010_a14d8872'),'-begin');
pol=jsondecode(fileread(fullfile(here,'G2_LP1_POLICY_v1.json')));
json=fullfile(repo,'docs/research/crack-growth-gaps-2026/G2_SPECIMEN1_1990_GEOMETRY.json');
p0=fullfile(repo,'outputs/g2_p010_isolated/run_20261118_163657_790/P010_ISOLATED_REGULAR_ONLY.mat');
opts={'BottomVertices_mm',[25.4 482.6],'TopVertices_mm',254,'TipGuideRadius_mm',15,'TipGuideHface_mm',1.5};
try
 R.algebra=check_g2_lp0_clearance();
 B=g2_join_protected_mesh('ExteriorOptions',opts,'MaxT3Elements',40000);R.meshBuilds=R.meshBuilds+1;
 assert(B.pass,'G2LP0:Mesh','S0 join: %s',B.stage);
 C=g2_independent_t6_checker(B,json);T=g2_protected_tip_checker(B,json,p0);
 assert(C.pass&&C.gatesPassed==38&&T.pass&&T.gatesPassed==24,'G2LP0:Audit','S0 independent audit failed.');
 D=load(fullfile(repo,'outputs/g2_protected_mesh/run_20261118_165922_343_famA/GEOMETRY_ONLY_candidate.mat'));
 fields={'X3','T3','X6','T6','upperBankT6','lowerBankT6','nodalQ'};
 assert(all(cellfun(@(f)isequal(B.(f),D.(f)),fields)),'G2LP0:S0Identity','Rebuilt S0 differs from accepted famA arrays.');
 P=pol.startPolyline_mm;B.crackPolyline=P;B.tipTangent=[0 1];
 A=g2_lp0_phase_audit(B,P,pol);assert(A.pass,'G2LP0:Phase','S0 map/activation verification failed.');
 R.probes.S0=struct('pass',true,'audit',[38 24],'phase',A);clear D B
 for n=reshape(pol.syntheticProbes.vertexCounts,1,[])
  % The complete polyline is registered before any result; never a trajectory.
  Q=P;
  for k=1:n-2
   theta=pol.syntheticProbes.anglesFromVertical_deg(k);
   Q(end+1,:)=Q(end,:)+4*[sind(theta),cosd(theta)]; %#ok<AGROW>
  end
  G=g2_lp0_clearance(Q(1:end-1,:),Q(end,:),A.clearanceGeometry,pol);
  assert(G.pass,'G2LP0:Clearance','Synthetic N%d: %s',n,G.status);
  [~,sys]=memory;assert(sys.PhysicalMemory.Available/2^30>=5,'G2LP0:Memory','HOLD_MEMORY before mesh.');
  B=g2_kinked_join(Q,'ExpectedVertices',n,'ExteriorOptions',opts,'MaxT3Elements',40000);
  R.meshBuilds=R.meshBuilds+1;R.probes.(sprintf('N%d',n))=struct('label','MESH_ONLY_SYNTHETIC','polyline_mm',Q,'join',B.stage,'summary',B.summary);
  assert(B.pass,'G2LP0:Mesh','N%d join: %s; %s',n,B.stage,B.message);
  C=g2_kinked_mesh_auditor(B,json,p0,n);
  assert(C.pass&&C.gatesPassed==34&&C.gatesTotal==34,'G2LP0:Audit','N%d audit not 34/34.',n);
  A=g2_lp0_phase_audit(B,Q,pol);assert(A.pass,'G2LP0:Phase','N%d phase/activation failed.',n);
  G=g2_lp0_clearance(Q(1:end-1,:),Q(end,:),A.clearanceGeometry,pol);assert(G.pass,'G2LP0:Clearance','Actual polygons fail.');
  R.probes.(sprintf('N%d',n)).audit=C;R.probes.(sprintf('N%d',n)).phase=A;
  R.probes.(sprintf('N%d',n)).clearance=G;clear B
 end
 R.pass=true;R.status='LP0_GEOMETRY_QUALIFIED_REVIEW_REQUIRED';R.cause='';
catch ME
 R.cause=ME.identifier;R.message=ME.message;
end
% This stage never launches LP1. Physical trajectory controller is unavailable
% until LP0 is actually qualified, including the prospective restart controls.
R.physicalSolves=0;
end
