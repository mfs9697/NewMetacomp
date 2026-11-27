function R=g2_lp2b1eq_compare(N,A,tol,ref)
%G2_LP2B1EQ_COMPARE  Fixed-geometry SIF-equivalence comparison of ONE new 0.40 mm solution with the ORIGINAL accepted
% LP2-A3 record of the same geometry and material (pure function; no FEM, no I/O).
% Prospective copy of the accepted WP5 comparator g2_lp2a2_eq_compare with ONLY these changes:
%  1. C10 uses the STATE-SPECIFIC archived next tip (S10 for EQB-soft1-S9, S11 for EQB-H-S10) passed in A/ref,
%     never a hard-coded S9; tolerance unchanged (5e-4 mm).
%  2. C9 adds the stronger draft subgate: archived active area exactly 0 -> new active area exactly 0 (H).
%  3. Validation BEFORE any criterion (outcome INPUT_INVALID = verification-infrastructure HOLD): finite real
%     inputs of the right shape/type, positive archived KI/Keq/G/J/compliance, valid archived MTS root and 16 gates,
%     u of length 2*N_T6, identity (solve/case/state/mask/geometry/predictor/pins/canonical digest), paired banks
%     with unique stations, near-tip node identity within 1e-9 mm, NO extrapolation of the archived jump, nonzero
%     normalizations, finite metrics. WP5 recorded a missing near-tip match as a C8 failure; here it is a HOLD.
%  4. Absolute values with units are reported as metrics; criteria are evaluated by g2_lp2b1eq_criteria (pure).
% Every metric definition (C1-C8, C11) is the WP5 line, including G = (KI^2+KII^2)/E, Keq = hypot of the ARCHIVED K,
% C8 on the scalar jump magnitude |u_U - u_L| (difference of magnitudes), near-tip normalization by the new near-tip
% maximum, whole-crack linear interpolation of the archived jump onto the new stations and new-maximum
% normalization; the signed normal opening is reported only.
%  N: K, D (X6,T6,upperBankT6,lowerBankT6,crackPolyline), activeArea_mm2, chordsPerCircle, nextTip_mm, nextState,
%     id (solveId, caseId, stateIndex, mask, canonicalSHA256)
%  A: state (archived STATE), K (archived SOLUTION K), D (archived MESH), nextTip_mm, nextState, chordsPerCircle,
%     id (solutionSHA256)
%  tol: policy tolerances;  ref: the policy solve entry (expected identities and pins)
% R.outcome: EQUIVALENT_CASE | NOT_EQUIVALENT | INPUT_INVALID.
cn={'C1_KI','C2_KII','C3_KIIoverKI','C4_G_J','C5_MTS','C6_COD_EDI','C7_EDI_spread_quadrature','C8_crackOpening', ...
 'C9_phaseActivation','C10_nextPredictor','C11_compliance'};
V={};m=struct();vec=struct();
try
 V=validateInputs(N,A,ref);
catch ME
 V{end+1}=['VALIDATION_ERROR: ' ME.identifier];
end
if isempty(V)
 try
  [m,vec,V]=metrics(N,A,tol);
 catch ME
  V{end+1}=['METRIC_ERROR: ' ME.identifier];
 end
end
if isempty(V)
 f=fieldnames(m);
 for k=1:numel(f),x=m.(f{k});if ~(islogical(x)&&isscalar(x))&&~(isnumeric(x)&&isscalar(x)&&isreal(x)&&isfinite(x)),V{end+1}=['METRIC_NONFINITE: ' f{k}];end,end %#ok<AGROW>
end
if isempty(V)
 c=g2_lp2b1eq_criteria(m,tol);v=cellfun(@(n)c.(n),cn);
 if all(v),out='EQUIVALENT_CASE';else,out='NOT_EQUIVALENT';end
else
 c=cell2struct(num2cell(false(numel(cn),1)),cn,1);v=false(1,numel(cn));out='INPUT_INVALID';
end
R=struct('outcome',out,'valid',isempty(V),'validation',{V},'pass',strcmp(out,'EQUIVALENT_CASE'),'criteria',c,'criteriaPassed',nnz(v), ...
 'criteriaTotal',numel(v),'failed',{cn(~v)},'metrics',m,'vectors',vec);
end

% =====================================================================
function V=validateInputs(N,A,ref)
V={};
fin=@(x)isnumeric(x)&&isreal(x)&&~isempty(x)&&all(isfinite(x(:)));sc=@(x)fin(x)&&isscalar(x);
need={'KI','KII','J','KI_COD','KII_COD','compliance_mm_per_N','activeArea_mm2','EDI_all','EDI4x4','u','pass','criteria'};
for side={'new','archived'}
 if strcmp(side{1},'new'),S=N;else,S=A;end
 if ~isstruct(S)||~all(isfield(S,{'K','D','chordsPerCircle','nextTip_mm','nextState'})),V{end+1}=['FIELDS: ' side{1}];continue,end %#ok<AGROW>
 K=S.K;
 if ~isstruct(K)||~all(isfield(K,need)),V{end+1}=['K_FIELDS: ' side{1}];continue,end %#ok<AGROW>
 for q={'KI','KII','J','KI_COD','KII_COD','compliance_mm_per_N','activeArea_mm2'}
  if ~sc(K.(q{1})),V{end+1}=sprintf('K_NONFINITE: %s %s',side{1},q{1});end %#ok<AGROW>
 end
 if ~(fin(K.EDI_all)&&isequal(size(K.EDI_all),[5 3])),V{end+1}=['K_EDI_ALL: ' side{1}];end %#ok<AGROW>
 if ~(fin(K.EDI4x4)&&numel(K.EDI4x4)==2),V{end+1}=['K_EDI4X4: ' side{1}];end %#ok<AGROW>
 if ~(isfield(S.D,'X6')&&isa(K.u,'double')&&fin(K.u)&&isvector(K.u)&&numel(K.u)==2*size(S.D.X6,1)),V{end+1}=['U_SHAPE: ' side{1}];end %#ok<AGROW>
 if ~(islogical(K.pass)&&isscalar(K.pass)&&isstruct(K.criteria)&&numel(fieldnames(K.criteria))==16&&all(cellfun(@(x)islogical(x)&&isscalar(x),struct2cell(K.criteria)))), ...
   V{end+1}=['K_GATES_SHAPE: ' side{1}];end %#ok<AGROW>
 if ~(fin(S.chordsPerCircle)&&numel(S.chordsPerCircle)==3),V{end+1}=['CHORDS: ' side{1}];end %#ok<AGROW>
 if ~(fin(S.nextTip_mm)&&numel(S.nextTip_mm)==2),V{end+1}=['NEXT_TIP: ' side{1}];end %#ok<AGROW>
end
if ~isempty(V),return,end
Ka=A.K;
if ~(Ka.KI>0&&hypot(Ka.KI,Ka.KII)>0&&Ka.J>0&&Ka.compliance_mm_per_N>0&&Ka.activeArea_mm2>=0),V{end+1}='ARCHIVED_NONPOSITIVE';end
if ~(Ka.pass&&all(cell2mat(struct2cell(Ka.criteria)))),V{end+1}='ARCHIVED_GATES';end
try
 M=g2_mts_direction(Ka.KI,Ka.KII);if ~(M.admissibleForStep&&strcmp(M.status,'OK')),V{end+1}='ARCHIVED_MTS';end
catch
 V{end+1}='ARCHIVED_MTS';
end
if ~(N.K.KI~=0),V{end+1}='NEW_KI_ZERO';end
% ---- identity
id=N.id;
if ~(isstruct(id)&&all(isfield(id,{'solveId','caseId','stateIndex','mask','canonicalSHA256'}))&&isfield(A,'id')&&isfield(A.id,'solutionSHA256')&&isfield(A,'state')),V{end+1}='IDENTITY_FIELDS';return,end
if ~strcmp(id.solveId,ref.id),V{end+1}='IDENTITY_SOLVE';end
if ~(strcmp(id.caseId,ref.caseId)&&strcmp(A.state.caseId,ref.caseId)),V{end+1}='IDENTITY_CASE';end
if ~(isequal(id.stateIndex,ref.stateIndex)&&isequal(A.state.stateIndex,ref.stateIndex)),V{end+1}='IDENTITY_STATE';end
if ~(isequal(reshape(id.mask,1,3),reshape(ref.mask,1,3))&&isequal(reshape(A.state.mask,1,3),reshape(ref.mask,1,3))),V{end+1}='IDENTITY_MASK';end
if ~strcmpi(A.id.solutionSHA256,ref.archived.SOLUTION.record.sha256),V{end+1}='IDENTITY_ARCHIVED_SOLUTION';end
if ~strcmpi(id.canonicalSHA256,ref.qualification.canonicalSHA256),V{end+1}='IDENTITY_CANONICAL_MESH';end
if ~(isequal(N.D.crackPolyline,A.state.polyline_mm)&&isequal(A.D.crackPolyline,A.state.polyline_mm)),V{end+1}='IDENTITY_GEOMETRY';end
np=ref.nextPredictor;
if ~(ischar(N.nextState)&&ischar(A.nextState)&&strcmp(N.nextState,np.state)&&strcmp(A.nextState,np.state)),V{end+1}='IDENTITY_NEXT_STATE';end
if ~isequal(reshape(A.nextTip_mm,1,2),reshape(np.tip_mm,1,2)),V{end+1}='IDENTITY_ARCHIVED_NEXT_TIP';end
end

function [m,vec,V]=metrics(N,A,tol)
V={};m=struct();vec=struct();
Keq=hypot(A.K.KI,A.K.KII);
m.dKI_overKeq=(N.K.KI-A.K.KI)/Keq;m.dKII_overKeq=(N.K.KII-A.K.KII)/Keq;
m.dKIIoverKI=N.K.KII/N.K.KI-A.K.KII/A.K.KI;
Gn=(N.K.KI^2+N.K.KII^2)/tol.E_MPa;Ga=(A.K.KI^2+A.K.KII^2)/tol.E_MPa;m.dG_rel=Gn/Ga-1;m.dJ_rel=N.K.J/A.K.J-1;
m.newJoverGminus1=N.K.J/Gn-1;
Mn=g2_mts_direction(N.K.KI,N.K.KII);Ma=g2_mts_direction(A.K.KI,A.K.KII);m.dMTS_deg=Mn.theta_deg-Ma.theta_deg;
m.newCODminusEDI_rel=max(abs([N.K.KI_COD-N.K.KI,N.K.KII_COD-N.K.KII]))/hypot(N.K.KI,N.K.KII);
m.archivedCODminusEDI_rel=max(abs([A.K.KI_COD-A.K.KI,A.K.KII_COD-A.K.KII]))/Keq;m.dCODminusEDI=m.newCODminusEDI_rel-m.archivedCODminusEDI_rel;
spread=@(K)max(max(K.EDI_all(:,1:2))-min(K.EDI_all(:,1:2)))/hypot(K.KI,K.KII);quad=@(K)max(abs(K.EDI4x4(:).'-[K.KI,K.KII]))/hypot(K.KI,K.KII);
m.newPathSpread_rel=spread(N.K);m.archivedPathSpread_rel=spread(A.K);m.newQuad4x4_rel=quad(N.K);m.archivedQuad4x4_rel=quad(A.K);
m.dCompliance_rel=N.K.compliance_mm_per_N/A.K.compliance_mm_per_N-1;
m.dActiveArea_rel=(N.activeArea_mm2-A.K.activeArea_mm2)/max(A.K.activeArea_mm2,1);
m.nextTipDisplacement_mm=norm(reshape(N.nextTip_mm,1,2)-reshape(A.nextTip_mm,1,2));
[o,V]=openingDiff(N,A,tol);if ~isempty(V),return,end
m.openingNearTipRel=o.nearRel;m.openingWholeCrackRel=o.wholeRel;
m.signedOpeningNearTipRel=o.sgNearRel;m.signedOpeningWholeCrackRel=o.sgWholeRel;m.newMinSignedOpening_mm=o.newMin;m.archivedMinSignedOpening_mm=o.archMin;
m.newSolverGatesPass=logical(N.K.pass)&&all(cell2mat(struct2cell(N.K.criteria)));m.archivedSolverGatesPass=logical(A.K.pass);
m.newMTSadmissible=logical(Mn.admissibleForStep);m.chordsEqual=isequal(reshape(N.chordsPerCircle,1,3),reshape(A.chordsPerCircle,1,3));
% absolute values (units: K MPa*mm^0.5 at P = 1 N; G, J N/mm; compliance mm/N; area mm^2; angles deg; tips mm)
m.newKI=N.K.KI;m.archivedKI=A.K.KI;m.newKII=N.K.KII;m.archivedKII=A.K.KII;m.archivedKeq=Keq;
m.newG=Gn;m.archivedG=Ga;m.newJ=N.K.J;m.archivedJ=A.K.J;m.newMTS_deg=Mn.theta_deg;m.archivedMTS_deg=Ma.theta_deg;
m.newCompliance_mm_per_N=N.K.compliance_mm_per_N;m.archivedCompliance_mm_per_N=A.K.compliance_mm_per_N;
m.newActiveArea_mm2=N.activeArea_mm2;m.archivedActiveArea_mm2=A.K.activeArea_mm2;
m.newNextTipX_mm=N.nextTip_mm(1);m.newNextTipY_mm=N.nextTip_mm(2);m.archivedNextTipX_mm=A.nextTip_mm(1);m.archivedNextTipY_mm=A.nextTip_mm(2);
m.nearTipNodes=o.nNear;m.nearTipNodesArchived=o.nNearArch;m.bankStationsNew=o.nNew;m.bankStationsArchived=o.nArch;
m.newMaxJumpNearTip_mm=o.maxNear;m.newMaxJump_mm=o.maxAll;
vec=struct('newChordsPerCircle',reshape(N.chordsPerCircle,1,3),'archivedChordsPerCircle',reshape(A.chordsPerCircle,1,3), ...
 'newNextTip_mm',reshape(N.nextTip_mm,1,2),'archivedNextTip_mm',reshape(A.nextTip_mm,1,2),'nextState',N.nextState);
end

function [o,V]=openingDiff(N,A,tol)
% WP5 openingDiff with explicit station and identity validation (no silent NaN, no extrapolation)
o=struct();V={};
Bn=g2_lp2b1eq_banks(N.D,tol.nodeMatch_mm);Ba=g2_lp2b1eq_banks(A.D,tol.nodeMatch_mm);
for q=Bn.problems,V{end+1}=['C8_NEW_' q{1}];end %#ok<AGROW>
for q=Ba.problems,V{end+1}=['C8_ARCHIVED_' q{1}];end %#ok<AGROW>
if ~isempty(V),return,end
[jN,gN]=jumps(Bn,N.D,N.K.u);[jA,gA]=jumps(Ba,A.D,A.K.u);sN=Bn.s;sA=Ba.s;xN=Bn.x;xA=Ba.x;tip=N.D.crackPolyline(end,:);
nt=vecnorm(xN-tip,2,2)<=tol.nearTipRadius_mm+tol.nodeMatch_mm;ntA=vecnorm(xA-tip,2,2)<=tol.nearTipRadius_mm+tol.nodeMatch_mm;ix=find(nt);
d=inf(numel(ix),1);e=d;miss=0;
for i=1:numel(ix)
 [dd,k]=min(vecnorm(xA-xN(ix(i),:),2,2));
 if dd<=tol.nodeMatch_mm,d(i)=abs(jN(ix(i))-jA(k));e(i)=abs(gN(ix(i))-gA(k));else,miss=miss+1;end
end
if isempty(ix)||miss>0||nnz(ntA)~=numel(ix),V{end+1}='C8_NEAR_TIP_IDENTITY';end
if min(sN)<min(sA)||max(sN)>max(sA),V{end+1}='C8_EXTRAPOLATION';end
if ~(max(jN(nt))>0&&max(jN)>0&&max(abs(gN(nt)))>0&&max(abs(gN))>0),V{end+1}='C8_ZERO_NORMALIZATION';end
if ~(all(isfinite(jN))&&all(isfinite(jA))&&all(isfinite(gN))&&all(isfinite(gA))),V{end+1}='C8_NONFINITE_JUMP';end
if ~isempty(V),return,end
ji=interp1(sA,jA,sN,'linear');gi=interp1(sA,gA,sN,'linear');
if any(~isfinite(ji))||any(~isfinite(gi)),V{end+1}='C8_EXTRAPOLATION';return,end
o.nearRel=max(d)/max(jN(nt));o.wholeRel=max(abs(ji-jN))/max(jN);
o.sgNearRel=max(e)/max(abs(gN(nt)));o.sgWholeRel=max(abs(gi-gN))/max(abs(gN));o.newMin=min(gN);o.archMin=min(gA);
o.nNear=numel(ix);o.nNearArch=nnz(ntA);o.nNew=numel(sN);o.nArch=numel(sA);o.maxNear=max(jN(nt));o.maxAll=max(jN);
end

function [j,g]=jumps(B,D,u)
% WP5 jumps on validated, station-sorted banks: j = |u_U - u_L| per station, g = (u_U - u_L).n_segment
U=reshape(u,2,[]).';J=U(B.up,:)-U(B.lo,:);j=vecnorm(J,2,2);
P=D.crackPolyline;tt=diff(P);tt=tt./vecnorm(tt,2,2);nn=[-tt(:,2),tt(:,1)];g=sum(J.*nn(B.kq,:),2);
end
