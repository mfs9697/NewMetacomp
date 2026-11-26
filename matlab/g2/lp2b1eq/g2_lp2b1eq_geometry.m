function G=g2_lp2b1eq_geometry(C,s,Ref,outFolder)
%G2_LP2B1EQ_GEOMETRY  Geometry-only admission of the FIXED 0.40 mm mesh of one reference (zero FEM).
%  G = g2_lp2b1eq_geometry(C, s, Ref, outFolder)     outFolder must exist; GEOMETRY_h040 inside it must not
% 1. The accepted LP2-B1 harness g2_lp2b1_attempt (amendment A1, unchanged) on the fixed reference polyline,
%    0.40 mm, case mask, the nominal parent geometry and the ARCHIVED MESH as protected baseline (exactly as the
%    LP2-B1 WP1 references): 19/19 checks (join 13/13, independent metrics, P1-P10, 34 kink gates, four-mask
%    phase audit, owner map, 76 chords, T3 <= 40000, actual and nominal clearance, 1 mm guide-to-every-ring,
%    protected T3 block, block T6 vertex rows and coordinates, 2443 q parents, nodal q, every q annulus in the
%    core, exact polyline/tangent). Writes outFolder/GEOMETRY_h040/{ATTEMPT.json, ATTEMPT_ARRAYS.mat}.
% 2. The solve mesh: the SAME g2_lp2a2_join call (no ladder), pairing audit, g2_lp1_audit (phase owner map PM),
%    g2_m4b_ring_activation with the case mask.
% 3. Admission (all required; nothing relaxed; the mesh is never altered to force a match):
%    canonical digest of the solve mesh == pinned qualification digest == attempt digest; the qualification
%    ATTEMPT_ARRAYS.mat (pinned file) and the new attempt arrays equal the solve mesh in all 14 saved arrays
%    (summary except the timing field nativeMeshingSeconds); protected topology (g2_lp2b1eq_topology) versus the
%    archived MESH; ring polygons identical to the archived MESH; 76 chords; C8 station coverage and near-tip node
%    identity versus the archived banks. Reported: geometric active area with the case labels (solver formula).
INT='G2LP2B1EQ:HOLD_GEOMETRY';pol=C.policy;q=s.qualification;Ma=Ref.mesh;St=Ref.state;P=St.polyline_mm;t=St.tangent;k=s.stateIndex;
assert(isfolder(outFolder)&&~isfolder(fullfile(outFolder,'GEOMETRY_h040')),INT,'Geometry folder must be fresh.');
base=struct('X3',Ma.X3,'T3',Ma.T3,'X6',Ma.X6,'T6',Ma.T6,'qActiveT6Rows',Ma.qActiveT6Rows,'nodalQ',Ma.nodalQ, ...
 'maxRatio',Ma.summary.maxNeighborRatio,'minAngle',Ma.summary.minAngle_deg);
addpath(fullfile(C.here,'vendor_p010_a14d8872'),'-begin');
Ra=g2_lp2b1_attempt('GEOMETRY_h040',P,t,k,pol.meshFamily.seedSpacing_mm,reshape(s.mask,1,3),Ref.nominalGeometry,base,outFolder,C.a3);
ck=struct();ck.attempt19=Ra.pass&&Ra.checksPassed==19&&Ra.checksTotal==19;
ck.attemptCanonicalEqualsPin=strcmpi(Ra.canonicalSHA256,q.canonicalSHA256);
% ---- solve mesh (identical call)
op=pol.meshFamily.ExteriorOptions;
xo={'BottomVertices_mm',op.BottomVertices_mm(:).','TopVertices_mm',op.TopVertices_mm,'TipGuideRadius_mm',op.TipGuideRadius_mm,'TipGuideHface_mm',op.TipGuideHface_mm};
[~,D]=evalc('g2_lp2a2_join(P,''ExpectedVertices'',k+2,''ExpectedTangent'',t,''ExteriorOptions'',[xo,{''SeedSpacing_mm'',pol.meshFamily.seedSpacing_mm}],''MaxT3Elements'',op.MaxT3Elements)');
G=struct('pass',false,'checks',ck,'attempt',Ra,'D',[],'PM',[],'A',[],'PA',[],'act',[],'canonicalSHA256','','metadataSHA256','','topology',[], ...
 'stations',[],'activeAreaGeometric_mm2',NaN,'chordsPerCircle',[]);
ck.joinPass=D.pass;
if ~D.pass,G.checks=ck;return,end
PA=g2_lp2a2_pairing_audit(D);ck.pairing=PA.pass&&PA.gatesPassed==10;
D.tipTangent=t;
[~,A,PM]=evalc('g2_lp1_audit(D,k,struct(''repo'',C.repo,''here'',C.here,''policy'',C.lp2Policy))');D.seedSpacing_mm=pol.meshFamily.seedSpacing_mm;
ck.kinkedAudit34=A.meshAudit.pass&&A.meshAudit.gatesPassed==34&&A.meshAudit.gatesTotal==34;ck.phaseAudit=A.pass&&PM.pass;
chords=arrayfun(@(x)size(x.chords,1),PM.interfaces);ck.chords76=isequal(chords(:).',[76 76 76]);
act=g2_m4b_ring_activation(PM.annulusOf,logical(reshape(s.mask,1,3)));
[h,meta]=g2_lp2b1eq_canon(D);ck.canonicalEqualsPin=strcmpi(h,q.canonicalSHA256);ck.canonicalEqualsAttempt=strcmpi(h,Ra.canonicalSHA256);
% ---- remaining saved arrays versus the pinned qualification file and the new attempt file
qf=fullfile(C.repo,strrep(q.arrays.path,'/',filesep));
ck.qualificationFilePin=strcmpi(g2_sha256_file(qf),q.arrays.sha256);
Qa=load(qf);Na=load(fullfile(outFolder,'GEOMETRY_h040','ATTEMPT_ARRAYS.mat'));
ck.qualificationArraysEqual=sameArrays(D,Qa);ck.attemptArraysEqual=sameArrays(D,Na);
% ---- protected topology, ring polygons, C8 stations
T=g2_lp2b1eq_topology(D,Ma);ck.protectedTopology=T.pass;
ck.ringPolygonsEqualArchived=isfield(Ra,'audit')&&Ra.audit.ringPolygonsIdenticalToBaseline;
Bn=g2_lp2b1eq_banks(D,pol.tolerances.nodeMatch_mm);Ba=g2_lp2b1eq_banks(Ma,pol.tolerances.nodeMatch_mm);
S=struct('problemsNew',{Bn.problems},'problemsArchived',{Ba.problems},'nNew',Bn.n,'nArchived',Ba.n,'nearNew',NaN,'nearArchived',NaN,'nearMatched',NaN, ...
 'rangeNew',[NaN NaN],'rangeArchived',[NaN NaN]);
if isempty(Bn.problems)&&isempty(Ba.problems)
 tip=P(end,:);r=pol.tolerances.nearTipRadius_mm+pol.tolerances.nodeMatch_mm;nt=find(vecnorm(Bn.x-tip,2,2)<=r);
 mt=arrayfun(@(i)min(vecnorm(Ba.x-Bn.x(i,:),2,2))<=pol.tolerances.nodeMatch_mm,nt);
 S.nearNew=numel(nt);S.nearArchived=nnz(vecnorm(Ba.x-tip,2,2)<=r);S.nearMatched=nnz(mt);S.rangeNew=[Bn.s(1) Bn.s(end)];S.rangeArchived=[Ba.s(1) Ba.s(end)];
end
ck.stationCoverage=isempty(Bn.problems)&&isempty(Ba.problems)&&S.rangeNew(1)>=S.rangeArchived(1)&&S.rangeNew(2)<=S.rangeArchived(2)&& ...
 S.nearNew>0&&S.nearMatched==S.nearNew&&S.nearArchived==S.nearNew;
x=D.X6(:,1);y=D.X6(:,2);T3=D.T6(:,1:3);
Ael=.5*((x(T3(:,2))-x(T3(:,1))).*(y(T3(:,3))-y(T3(:,1)))-(x(T3(:,3))-x(T3(:,1))).*(y(T3(:,2))-y(T3(:,1))));
G=struct('pass',all(cell2mat(struct2cell(ck))),'checks',ck,'attempt',Ra,'D',D,'PM',PM,'A',A,'PA',PA,'act',act,'canonicalSHA256',h,'metadataSHA256',meta, ...
 'topology',T,'stations',S,'activeAreaGeometric_mm2',sum(Ael(act.phaseForAssembly==2)),'chordsPerCircle',chords(:).');
end

function ok=sameArrays(D,Q)
f={'X3','T3','X6','T6','upperBankT6','lowerBankT6','nodalQ','qActiveT6Rows','elementRows','crackPolyline','gates','extraVertexXY','physicalTipNode'};
ok=all(isfield(Q,[f,{'summary'}]));
for i=1:numel(f),ok=ok&&isequal(D.(f{i}),Q.(f{i}));end
ok=ok&&isequal(stripTiming(D.summary),stripTiming(Q.summary));
end
function s=stripTiming(s)
% the only field allowed to differ between deterministic repeats (LP2-B1 summary-difference check)
if isfield(s,'exterior')&&isstruct(s.exterior)&&isfield(s.exterior,'nativeMeshingSeconds'),s.exterior=rmfield(s.exterior,'nativeMeshingSeconds');end
if isfield(s,'nativeMeshingSeconds'),s=rmfield(s,'nativeMeshingSeconds');end
end
