function O=g2_lp2b1eq_run(solveId,varargin)
%G2_LP2B1EQ_RUN  Driver of ONE solve of the PROSPECTIVE campaign G2-LP2B1-EQ-001 (never physical at readiness).
%  O = g2_lp2b1eq_run('EQB-soft1-S9')                                  archived-reference qualification only
%  O = g2_lp2b1eq_run('EQB-soft1-S9','Mesh',true,'ReplayRoot',dir)     + geometry-only 0.40 mm admission replay
%                                                                       (writes only under dir; no solve)
%  O = g2_lp2b1eq_run('EQB-soft1-S9','Run',true,'Token',tok)           FUTURE authorized call only
% Physical call (Run=true) requires, in this order, before any folder, mesh or solve: the normal preflight
% (Preflight=false refuses: HOLD_PREFLIGHT_REQUIRED); the GO file of the policy accepted by g2_lp2b1eq_go_validate
% (HOLD_UNAUTHORIZED); the run root outside every historical root; no folder of this solve (HOLD_ONE_ATTEMPT, no
% retry); the fixed order (EQB-H-S10 only after a complete EQUIVALENT_CASE EQB-soft1-S9; no later folder first:
% HOLD_ORDER); the campaign RECEIPT bound to the token, written only by g2_lp2b1eq_external_run (HOLD_NO_RECEIPT);
% the archived reference qualification (HOLD_REFERENCE); the 7 GiB memory gate (HOLD_MEMORY, before the folder).
% Then: geometry admission (g2_lp2b1eq_geometry; any failure HOLD_MESH_QUALIFICATION before FEM), MESH, PHASE,
% memory gates (7 GiB and the inherited 5 GiB), the UNCHANGED g2_m4b_sif_partial with the audited phase labels and
% the original BVP, SOLUTION, comparison (g2_lp2b1eq_compare_case), COMPARISON.mat + COMPARISON.json, re-read and
% hash check (HOLD_INCOMPLETE_WRITE). Any error after the folder exists writes HOLD.json and re-throws; partial
% records are preserved. No STATE, no admission, no propagation.
% 'Test',T (zero-FEM tests only): T.root must be an existing folder under tempdir and contain every root of
% T.context; T.ops may replace gate, head, reference, geometry, memgate, freeRAM, solve. Otherwise refused.
ip=inputParser;addParameter(ip,'Run',false,@islogical);addParameter(ip,'Token','',@(x)ischar(x)||isstring(x));
addParameter(ip,'Preflight',true,@islogical);addParameter(ip,'Mesh',false,@islogical);addParameter(ip,'ReplayRoot','',@ischar);
addParameter(ip,'Test',[]);parse(ip,varargin{:});o=ip.Results;
if o.Run&&~o.Preflight,error('G2LP2B1EQ:HOLD_PREFLIGHT_REQUIRED','A physical call requires the normal preflight; Preflight=false is for read-only replay and tests.');end
[C,ops]=setup(o);pol=C.policy;ids=cellfun(@(x)x.id,C.solves,'UniformOutput',false);j=find(strcmp(ids,char(solveId)));
assert(isscalar(j),'G2LP2B1EQ:HOLD_UNKNOWN_SOLVE','Unknown solve %s (only EQB-soft1-S9 and EQB-H-S10).',char(solveId));s=C.solves{j};solveId=s.id;
if o.Run
 G=ops.gate(C,char(o.Token));
 refuseHistorical(C,C.runRoot);sd=fullfile(C.runRoot,solveId);
 assert(~isfolder(sd),'G2LP2B1EQ:HOLD_ONE_ATTEMPT','%s already attempted; no retry.',solveId);
 checkOrder(C,j,ids);
 [Rr,~,okr]=g2_trajectory_record('read',fullfile(C.receiptRoot,'RECEIPT.mat'));
 assert(okr&&isfield(Rr,'token')&&strcmp(Rr.token,C.token)&&strcmp(Rr.campaignId,pol.campaignId),'G2LP2B1EQ:HOLD_NO_RECEIPT', ...
  'No campaign receipt bound to this token: a physical call is possible only through g2_lp2b1eq_external_run.');
 activationHead=ops.head();
end
Ref=ops.reference(C,s);
assert(Ref.pass,'G2LP2B1EQ:HOLD_REFERENCE','%s: archived reference fails: %s',solveId,strjoin(failedNames(Ref.checks),', '));
O=struct('solveId',solveId,'caseId',s.caseId,'token',C.token,'run',o.Run,'solveCalls',0,'stage','REFERENCE_QUALIFIED','reference',summRef(Ref),'geometry',[]);
if ~o.Run
 if ~o.Mesh,return,end
 rr=o.ReplayRoot;assert(~isempty(rr),'G2LP2B1EQ:HOLD_INPUT','ReplayRoot is required for a geometry replay.');
 refuseHistorical(C,rr);
 assert(~under(rr,C.runRoot)&&~under(rr,C.receiptRoot)&&~under(C.runRoot,rr)&&~under(C.receiptRoot,rr),'G2LP2B1EQ:HOLD_INPUT','The replay root must be separate from the run and receipt roots.');
 od=fullfile(rr,solveId);assert(~isfolder(od),'G2LP2B1EQ:HOLD_OVERWRITE','Replay folder exists: %s',od);mkdir(od);
 Gq=ops.geometry(C,s,Ref,od);O.geometry=summGeo(Gq);O.stage='GEOMETRY_REPLAY_NO_SOLVE';
 wj(fullfile(od,'GEOMETRY_REPLAY.json'),O);return
end
% ------------------------------------------------------------------ authorized path (never executed at readiness)
Mg0=ops.memgate(pol.resources.freeRAMInsideMATLAB_GiB_min);
assert(Mg0.pass,'G2LP2B1EQ:HOLD_MEMORY','Pre-admission memory gate: %s',Mg0.reason);
mkdir(sd);stage='GEOMETRY';
try
 Gq=ops.geometry(C,s,Ref,sd);O.geometry=summGeo(Gq);
 assert(Gq.pass,'G2LP2B1EQ:HOLD_MESH_QUALIFICATION','%s: 0.40 mm admission failed before FEM: %s',solveId,strjoin(failedNames(Gq.checks),', '));
 stage='MESH';D=Gq.D;mf=fullfile(sd,'MESH.mat');save(mf,'-struct','D','-v7.3');mh=lower(g2_sha256_file(mf));D=load(mf);
 assert(strcmpi(g2_lp2b1eq_canon(D),s.qualification.canonicalSHA256),'G2LP2B1EQ:HOLD_MESH_QUALIFICATION','Reloaded MESH canonical digest differs from the pin.');
 stage='PHASE';
 Ph=struct('schema','NewMetacomp.G2.LP2B1EQ.Phase.v1','solveId',solveId,'caseId',s.caseId,'stateIndex',s.stateIndex,'mask',reshape(s.mask,1,3), ...
  'meshSHA256',mh,'canonicalSHA256',Gq.canonicalSHA256,'owner',Gq.PM.annulusOf,'labels',Gq.act.phaseForAssembly,'chordsPerCircle',Gq.chordsPerCircle, ...
  'audit',Gq.A,'pairingAudit',Gq.PA,'token',C.token);
 ph=lower(g2_trajectory_record('write',fullfile(sd,'PHASE.mat'),Ph));
 stage='MEMORY';Mg=ops.memgate(pol.resources.freeRAMInsideMATLAB_GiB_min);
 assert(Mg.pass,'G2LP2B1EQ:HOLD_MEMORY','Pre-solve memory gate: %s',Mg.reason);
 assert(ops.freeRAM()>=pol.resources.preflightGuard_GiB,'G2LP2B1EQ:HOLD_MEMORY','Less than %g GiB free physical RAM; no retry.',pol.resources.preflightGuard_GiB);
 stage='SOLVE';polT=jsondecode(fileread(fullfile(C.here,'G2_TRAJECTORY_POLICY_v1.json')));Em=pol.bvp.E_MPa;mk=@(E)struct('E',E,'nu',pol.bvp.nu,'plane','stress');
 expect=struct('P_N',1,'thickness_mm',12.7,'load_mm',[254 203.2],'E_matrix',Em);   % literal values of LP2-A3, equal to the policy BVP
 assert(pol.bvp.P_N==expect.P_N&&pol.bvp.thickness_mm==expect.thickness_mm&&isequal(pol.bvp.load_mm(:).',expect.load_mm),'G2LP2B1EQ:HOLD_SOURCE','BVP.');
 t0=tic;O.solveCalls=1;K=ops.solve(D,Gq.act,[mk(Em),mk(Em*s.ratio)],polT,Gq.PM,expect);secs=toc(t0);
 stage='SOLUTION';
 S=struct('schema','NewMetacomp.G2.LP2B1EQ.Solution.v1','solveId',solveId,'caseId',s.caseId,'stateIndex',s.stateIndex,'meshSHA256',mh,'phaseSHA256',ph, ...
  'canonicalSHA256',Gq.canonicalSHA256,'policySHA256',C.policySHA256,'lp2b1eqSourceSHA256',C.lp2b1eqSourceSHA256,'token',C.token,'K',K,'solveSeconds',secs, ...
  'approvedHead',G.approvedHead,'activationHead',activationHead,'goFileSHA256',G.goFileSHA256,'memoryGate',Mg,'archivedSolutionSHA256',Ref.solutionSHA256);
 sh=lower(g2_trajectory_record('write',fullfile(sd,'SOLUTION.mat'),S));
 stage='COMPARISON';Rc=g2_lp2b1eq_compare_case(C,s,Ref,K,D,Gq.chordsPerCircle);
 Cm=struct('schema','NewMetacomp.G2.LP2B1EQ.Comparison.v1','solveId',solveId,'caseId',s.caseId,'stateIndex',s.stateIndex,'solutionSHA256',sh, ...
  'meshSHA256',mh,'phaseSHA256',ph,'canonicalSHA256',Gq.canonicalSHA256,'archivedSolutionSHA256',Ref.solutionSHA256,'token',C.token, ...
  'outcome',Rc.outcome,'valid',Rc.valid,'validation',{Rc.validation},'pass',Rc.pass,'criteria',Rc.criteria,'failed',{Rc.failed},'metrics',Rc.metrics,'vectors',Rc.vectors, ...
  'interpretation','numerical equivalence on this fixed geometry only; not a discretization-error bound, convergence statement or architecture contrast');
 cmh=lower(g2_trajectory_record('write',fullfile(sd,'COMPARISON.mat'),Cm));
 Cj=Cm;Cj.comparisonRecordSHA256=cmh;cf=fullfile(sd,'COMPARISON.json');assert(~isfile(cf),'G2LP2B1EQ:HOLD_OVERWRITE','COMPARISON.json exists.');wj(cf,Cj);
 stage='VERIFY_WRITE';
 ok=strcmpi(g2_sha256_file(mf),mh)&&strcmpi(g2_sha256_file(fullfile(sd,'PHASE.mat')),ph)&&strcmpi(g2_sha256_file(fullfile(sd,'SOLUTION.mat')),sh)&& ...
  strcmpi(g2_sha256_file(fullfile(sd,'COMPARISON.mat')),cmh)&&isfile(cf);
 if ok,Cr=jsondecode(fileread(cf));ok=strcmp(Cr.solutionSHA256,sh)&&strcmp(Cr.outcome,Rc.outcome)&&isequal(Cr.pass,Rc.pass)&&strcmp(Cr.comparisonRecordSHA256,cmh);end
 assert(ok,'G2LP2B1EQ:HOLD_INCOMPLETE_WRITE','Records of %s incomplete or inconsistent after writing.',solveId);
 O.stage='SOLVED_COMPARED';O.outcome=Rc.outcome;O.comparisonPass=Rc.pass;O.failed=Rc.failed;O.validation=Rc.validation;
 O.newK=struct('KI',K.KI,'KII',K.KII);O.solutionSHA256=sh;O.comparisonSHA256=cmh;O.activationHead=activationHead;
catch ME
 holdRecord(sd,stage,ME);rethrow(ME);
end
end

% =====================================================================
function [C,ops]=setup(o)
if isempty(o.Test)
 C=g2_lp2b1eq_context('Preflight',o.Preflight);ops=defaults(C);return
end
T=o.Test;tr=cpath(T.root);
assert(isfolder(tr)&&under(tr,tempdir),'G2LP2B1EQ:HOLD_TEST_INJECTION','Injected operations are allowed only under a tempdir test root.');
C=T.context;assert(under(C.runRoot,tr)&&under(C.receiptRoot,tr)&&under(C.goFile,tr),'G2LP2B1EQ:HOLD_TEST_INJECTION','Every test root must lie inside the test root.');
C.test=true;ops=defaults(C);
if isfield(T,'ops'),f=fieldnames(T.ops);for k=1:numel(f),ops.(f{k})=T.ops.(f{k});end,end
end
function ops=defaults(C)
ops=struct('gate',@gate,'head',@()headOf(C),'reference',@g2_lp2b1eq_reference,'geometry',@g2_lp2b1eq_geometry, ...
 'memgate',@(m)g2_lp2a2_eq_memgate(m),'freeRAM',@freeRAM,'solve',@g2_m4b_sif_partial);
end
function G=gate(C,tok)
assert(isfile(C.goFile),'G2LP2B1EQ:HOLD_UNAUTHORIZED','No GO_LP2B1_EQ record (%s): the campaign is prepared, not authorized.',C.policy.authorization.goPath);
fid=fopen(C.goFile,'r');raw=fread(fid,inf,'*uint8');fclose(fid);
md=java.security.MessageDigest.getInstance('SHA-256');md.update(raw);goSHA=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
try,Gd=jsondecode(native2unicode(raw.','UTF-8'));catch,Gd=[];end
G=g2_lp2b1eq_go_validate(Gd,C,tok);
assert(G.pass,'G2LP2B1EQ:HOLD_UNAUTHORIZED','GO record rejected: %s',strjoin(G.failed,', '));
G.goFileSHA256=goSHA;G.approvedHead=Gd.approvedHead;
end
function h=headOf(C)
H=g2_lp2a2_git('head',C.repo);assert(H.ok,'G2LP2B1EQ:HOLD_GIT','git rev-parse HEAD failed (status %d): %s',H.status,H.output);h=H.value;
end
function checkOrder(C,j,ids)
for i=j+1:numel(ids),assert(~isfolder(fullfile(C.runRoot,ids{i})),'G2LP2B1EQ:HOLD_ORDER','%s exists before %s: order violated.',ids{i},ids{j});end
for i=1:j-1
 d=fullfile(C.runRoot,ids{i});cf=fullfile(d,'COMPARISON.json');
 assert(isfile(cf)&&~isfile(fullfile(d,'HOLD.json')),'G2LP2B1EQ:HOLD_ORDER','%s requires a complete %s first.',ids{j},ids{i});
 Cr=jsondecode(fileread(cf));
 assert(isfield(Cr,'outcome')&&strcmp(Cr.outcome,'EQUIVALENT_CASE')&&isequal(Cr.pass,true),'G2LP2B1EQ:HOLD_ORDER','%s is not EQUIVALENT_CASE: global stop.',ids{i});
end
end
function refuseHistorical(C,root)
for k=1:numel(C.historicalRoots)
 assert(~under(root,C.historicalRoots{k})&&~under(C.historicalRoots{k},root),'G2LP2B1EQ:HOLD_HISTORICAL_ROOT','Refusing to write at or under a historical root: %s',C.historicalRoots{k});
end
end
function t=under(p,root)
a=lower(cpath(p));b=lower(cpath(root));if ~endsWith(b,filesep),b=[b filesep];end;t=startsWith([a filesep],b);
end
function p=cpath(p),p=char(java.io.File(char(p)).getCanonicalPath());end
function holdRecord(sd,stage,ME)
f=fullfile(sd,'HOLD.json');if isfolder(sd)&&~isfile(f)
 wj(f,struct('schema','NewMetacomp.G2.LP2B1EQ.Hold.v1','stage',stage,'identifier',ME.identifier,'message',ME.message, ...
  'utc',char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss.SSS''Z'''))));end
end
function n=failedNames(c),f=fieldnames(c);v=cellfun(@(x)isequal(x,true),struct2cell(c));n=f(~v).';if isempty(n),n={'(none)'};end,end
function r=summRef(R)
r=struct('pass',R.pass,'checks',R.checks,'stateSHA256',R.stateSHA256,'solutionSHA256',R.solutionSHA256,'meshSHA256',R.meshSHA256,'phaseSHA256',R.phaseSHA256, ...
 'nextState',R.nextState,'nextTip_mm',R.nextTip_mm,'chordsPerCircle',R.chordsPerCircle,'banks',R.banks,'maxJump_mm',R.maxJump_mm,'maxJumpNearTip_mm',R.maxJumpNearTip_mm, ...
 'uLength',R.uLength,'N_T6',R.N_T6,'mts',R.mts,'KI',R.state.KI,'KII',R.state.KII,'activeArea_mm2',R.state.activeArea_mm2);
end
function g=summGeo(G)
g=struct('pass',G.pass,'checks',G.checks,'canonicalSHA256',G.canonicalSHA256,'metadataSHA256',G.metadataSHA256,'chordsPerCircle',G.chordsPerCircle, ...
 'activeAreaGeometric_mm2',G.activeAreaGeometric_mm2,'stations',G.stations,'attemptChecks',sprintf('%d/%d',fieldOr(G.attempt,'checksPassed'),fieldOr(G.attempt,'checksTotal')), ...
 'attemptCanonicalSHA256',fieldOr(G.attempt,'canonicalSHA256'),'attemptArraysSHA256',fieldOr(G.attempt,'arraysFileSHA256'),'T3',fieldOr(G.attempt,'T3'), ...
 'minAngle_deg',NaN,'maxNeighborRatio',NaN,'topology',G.topology);
ind=fieldOr(G.attempt,'independent');if isstruct(ind),g.minAngle_deg=ind.minAngle_deg;g.maxNeighborRatio=ind.maxNeighborRatio;end
end
function v=fieldOr(s,f),if isfield(s,f),v=s.(f);else,v=[];end,end
function g=freeRAM(),[~,s]=memory;g=s.PhysicalMemory.Available/2^30;end
function wj(f,S)
fid=fopen(f,'w');assert(fid>0,'G2LP2B1EQ:Write','Cannot write %s',f);fwrite(fid,jsonencode(S,'PrettyPrint',true),'char');fclose(fid);
end
