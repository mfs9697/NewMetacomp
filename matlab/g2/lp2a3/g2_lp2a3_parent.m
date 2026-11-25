function Par=g2_lp2a3_parent(C,id)
%G2_LP2A3_PARENT  Authoritative parent of one LP2-A3 case: the ORIGINAL accepted LP2-A1 S8 STATE.
%  Par = g2_lp2a3_parent(C,'H')   (C from g2_lp2a3_context; read-only)
% Checks: S8 STATE/MESH/PHASE/SOLUTION and TERMINAL file SHA-256 against the policy pins; record
% manifests; identity (S8, case, mask, ratio); STATE links to MESH/PHASE/SOLUTION; signed KI/KII of
% STATE equal SOLUTION bitwise; 10-vertex polyline; TERMINAL binds this S8 (CAMPAIGN_LIMIT_REACHED,
% last state 8, parent SHA = S8 STATE). The S9 candidate of g2_lp2_forecast under the LP2-A3 policy
% must equal the archived TERMINAL candidate polyline bitwise (no tolerance). Returns the full-precision
% state, its SHA-256, the clearance geometry stored with the accepted S8 state, and the comparison.
pol=C.policy;ix=find(strcmp({pol.cases.id},id));assert(isscalar(ix),'G2LP2A3:HOLD_INPUT','Unknown case %s.',id);c=pol.cases(ix);
p=pol.parents.S8.(id);d=fullfile(C.repo,strrep(pol.parents.run,'/',filesep),id);s8=fullfile(d,'S8');
h=struct();for f={'STATE','MESH','PHASE','SOLUTION'},h.(f{1})=lower(g2_sha256_file(fullfile(s8,[f{1} '.mat'])));end
h.TERMINAL=lower(g2_sha256_file(fullfile(d,'TERMINAL.mat')));
for f=fieldnames(h).',assert(strcmpi(h.(f{1}),p.(f{1})),'G2LP2A3:HOLD_SOURCE','Parent %s of %s differs from its pin.',f{1},id);end
[St,sth,ok]=g2_trajectory_record('read',fullfile(s8,'STATE.mat'));[So,~,ok2]=g2_trajectory_record('read',fullfile(s8,'SOLUTION.mat'));
[Ph,phs,ok3]=g2_trajectory_record('read',fullfile(s8,'PHASE.mat'));[Tm,~,ok4]=g2_trajectory_record('read',fullfile(d,'TERMINAL.mat'));
INT='G2LP2A3:HOLD_RECORD_INTEGRITY';
assert(ok&&ok2&&ok3&&ok4&&strcmpi(sth,h.STATE),INT,'Parent records of %s fail their manifests.',id);
assert(St.stateIndex==8&&strcmp(St.caseId,id)&&isequal(reshape(St.mask,1,3),reshape(c.mask,1,3))&&St.ratio==c.ratio&& ...
 strcmpi(St.meshSHA256,h.MESH)&&strcmpi(St.solutionSHA256,h.SOLUTION)&&strcmpi(St.phaseSHA256,phs)&&strcmpi(Ph.meshSHA256,h.MESH)&& ...
 isequal(St.KI,So.K.KI)&&isequal(St.KII,So.K.KII)&&St.KI>0&&isequal(size(St.polyline_mm),[10 2])&&isequal(St.tip_mm,St.polyline_mm(end,:)), ...
 INT,'Parent S8 of %s fails its identity or links.',id);
assert(strcmp(Tm.caseId,id)&&strcmp(Tm.classification,'CAMPAIGN_LIMIT_REACHED')&&Tm.lastAcceptedState==8&&strcmpi(Tm.parentSHA256,h.STATE), ...
 INT,'TERMINAL of %s does not bind its S8 state.',id);
F=g2_lp2_forecast(St,pol);Pt=Tm.candidate.polyline_mm;
cmp=struct('bitwiseEqual',isequal(F.polyline_mm,Pt),'maxAbsDiff_mm',max(abs(F.polyline_mm(:)-Pt(:))),'archivedClassification',Tm.candidate.classification);
assert(cmp.bitwiseEqual,'G2LP2A3:HOLD_SOURCE','S9 forecast of %s does not reproduce the archived TERMINAL candidate (max |d| %.3g mm).',id,cmp.maxAbsDiff_mm);
Par=struct('state',St,'stateSHA256',h.STATE,'hashes',h,'geom',St.clearanceGeometry,'terminal',Tm,'S9forecast',F,'terminalComparison',cmp,'solution',So);
end
