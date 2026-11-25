function O=g2_lp2a2_eq_run(solveId,varargin)
%G2_LP2A2_EQ_RUN  PREPARED driver of the LP2-A2 SIF-equivalence campaign (G2-LP2A2-EQ-001).
%  O = g2_lp2a2_eq_run('EQ-H')              % dry (default): pins, archived records, new-family
%                                            % mesh + audits + phase map; NO solve, NO write
%  O = g2_lp2a2_eq_run('EQ-H','Run',true,'Token',tok)
%       Run=true REQUIRES the normal preflight (Preflight=false refuses: HOLD_PREFLIGHT_REQUIRED)
%       and the GO file named in the policy (absent at preparation), accepted by
%       g2_lp2a2_eq_go_validate (decision, token, solveLimit 4, exact ordered solves, campaignId,
%       repository-specific decision URL, 40-hex approved head, contract-evidence SHA, ancestry,
%       activation commit = approved head + GO file only); otherwise G2LP2A2:HOLD_UNAUTHORIZED
%       before any folder, mesh record or solve. One attempt per solve (an existing solve folder
%       refuses), physical-memory gate g2_lp2a2_eq_memgate (>= 7 GiB inside MATLAB), every
%       record re-read and hash-checked after writing (HOLD_INCOMPLETE_WRITE), no retry.
% Each solve: accepted LP2-A1 S8 polyline (bitwise), case material, g2_lp2a2_join mesh, unchanged
% LP1 audit, pairing audit, phase map, activation, g2_m4b_sif_partial (unchanged), comparison with
% the archived S8 SOLUTION (g2_lp2a2_eq_compare, preregistered tolerances). Records: MESH, PHASE,
% SOLUTION, COMPARISON in outputs/g2_lp2a2_eq_v1/<solveId>/. No state acceptance, no trajectory.
ip=inputParser;addParameter(ip,'Run',false,@islogical);addParameter(ip,'Token','',@(s)ischar(s)||isstring(s));
addParameter(ip,'Preflight',true,@islogical);parse(ip,varargin{:});o=ip.Results;
if o.Run&&~o.Preflight,error('G2LP2A2:HOLD_PREFLIGHT_REQUIRED','A physical call requires the normal preflight; Preflight=false is for dry calls only.');end
C=g2_lp2a2_eq_context('Preflight',o.Preflight);pol=C.policy;
j=find(strcmp({pol.solves.id},solveId));assert(isscalar(j),'G2LP2A2:HOLD_UNKNOWN_SOLVE','Unknown solve %s.',solveId);s=pol.solves(j);
if o.Run
 % ---- authorization BEFORE anything else (no folder, no mesh, no solve)
 gf=fullfile(C.repo,pol.goFile);
 assert(isfile(gf),'G2LP2A2:HOLD_UNAUTHORIZED','No GO file (%s): the campaign is prepared, not authorized.',pol.goFile);
 G=jsondecode(fileread(gf));V=g2_lp2a2_eq_go_validate(G,C,o.Token);
 assert(V.pass,'G2LP2A2:HOLD_UNAUTHORIZED','GO record rejected: %s',strjoin(V.failed,', '));
 AH=g2_lp2a2_git('head',C.repo);assert(AH.ok,'G2LP2A2:HOLD_GIT','git rev-parse HEAD failed (status %d): %s',AH.status,AH.output);activationHead=AH.value;
 sd=fullfile(C.repo,pol.outputRoot,solveId);
 assert(~exist(sd,'dir'),'G2LP2A2:HOLD_ONE_ATTEMPT','%s already attempted; no retry.',solveId);
end
% ---- archived records (pinned by the context)
ab=fullfile(C.archiveBase,s.caseId);
St=load(fullfile(ab,'S8','STATE.mat'));St=St.record;So=load(fullfile(ab,'S8','SOLUTION.mat'));So=So.record;
Tm=load(fullfile(ab,'TERMINAL.mat'));Tm=Tm.record;Ma=load(fullfile(ab,'S8','MESH.mat'));
assert(St.stateIndex==8&&strcmp(St.caseId,s.caseId)&&isequal(St.mask(:).',s.mask(:).')&&St.ratio==s.ratio,'G2LP2A2:HOLD_RECORD_INTEGRITY','Archived S8 identity.');
P=St.polyline_mm;t=St.tangent;N=size(P,1);
% ---- new-family mesh and audits (geometry only)
op=pol.meshFamily.options;xo={'BottomVertices_mm',op.BottomVertices_mm(:).','TopVertices_mm',op.TopVertices_mm,'TipGuideRadius_mm',op.TipGuideRadius_mm,'TipGuideHface_mm',op.TipGuideHface_mm};
D=g2_lp2a2_mesh(P,'ExpectedVertices',N,'ExpectedTangent',t,'ExteriorOptions',xo,'MaxT3Elements',op.MaxT3Elements);
assert(D.pass,'G2LP2A2:HOLD_MESH_QUALITY','%s %s',D.stage,D.message);
assert(D.seedRung==pol.meshFamily.requiredRung,'G2LP2A2:HOLD_MESH_QUALITY','Seed rung %d, policy requires %d for the equivalence campaign.',D.seedRung,pol.meshFamily.requiredRung);
D=rmfield(D,intersect(fieldnames(D),{'ladder','pairingAudit'}));D.tipTangent=t;
lp=jsondecode(fileread(fullfile(C.here,'G2_LP1_POLICY_v2.json')));
[A,PM]=g2_lp1_audit(D,N-2,struct('repo',C.repo,'here',C.here,'policy',lp));
PA=g2_lp2a2_pairing_audit(D);assert(PA.pass,'G2LP2A2:HOLD_PAIRING','Pairing audit: %s',strjoin(PA.failedGates,','));
lp2p=jsondecode(fileread(fullfile(C.here,'lp2','G2_LP2A_POLICY_v1.json')));Ra=g2_lp0_clearance(P(1:end-1,:),P(end,:),A.clearanceGeometry,lp2p);assert(Ra.pass,'G2LP2A2:HOLD_INTERFACE_APPROACH','Clearance.');
act=g2_m4b_ring_activation(PM.annulusOf,logical(s.mask(:).'));
PMa=g2_material_phase_map(Ma.X6,Ma.T6,lp.geometry.centres_mm,6.35*ones(3,1),19.05*ones(3,1),phaseOpts(C));
chN=arrayfun(@(q)size(q.chords,1),PM.interfaces);chA=arrayfun(@(q)size(q.chords,1),PMa.interfaces);
O=struct('solveId',solveId,'caseId',s.caseId,'token',C.token,'run',o.Run,'physicalSolves',0,'T3',size(D.T3,1),'archivedT3',size(Ma.T3,1), ...
 'auditGates',sprintf('%d/%d',A.meshAudit.gatesPassed,A.meshAudit.gatesTotal),'phaseAuditPass',A.pass,'phaseMapPass',PM.pass,'pairingAudit',PA.gatesPassed, ...
 'chordsPerCircle',chN,'archivedChordsPerCircle',chA,'bankPairsT6',PA.metrics.pairsT6,'archivedBankNodesT6',numel(Ma.upperBankT6),'seedRung',pol.meshFamily.requiredRung,'stage','READY_NOT_SOLVED');
if ~o.Run,return,end
% ---- authorized path (prepared; never executed at preparation)
Mg=g2_lp2a2_eq_memgate(pol.resources.freeRAMInsideMATLAB_GiB_min);assert(Mg.pass,'G2LP2A2:HOLD_MEMORY','Memory gate: %s',Mg.reason);
mkdir(sd);mf=fullfile(sd,'MESH.mat');save(mf,'-struct','D','-v7.3');mh=lower(g2_sha256_file(mf));D=load(mf);
Ph=struct('schema','NewMetacomp.G2.LP2A2.EQ.Phase.v1','solveId',solveId,'caseId',s.caseId,'mask',s.mask,'meshSHA256',mh,'owner',PM.annulusOf,'labels',act.phaseForAssembly);
ph=lower(g2_trajectory_record('write',fullfile(sd,'PHASE.mat'),Ph));
polT=jsondecode(fileread(fullfile(C.here,'G2_TRAJECTORY_POLICY_v1.json')));Em=pol.bvp.E_MPa;mk=@(E)struct('E',E,'nu',pol.bvp.nu,'plane','stress');
expect=struct('P_N',1,'thickness_mm',12.7,'load_mm',[254 203.2],'E_matrix',Em);t0=tic;
K=g2_m4b_sif_partial(D,act,[mk(Em),mk(Em*s.ratio)],polT,PM,expect);secs=toc(t0);O.physicalSolves=1;
S=struct('schema','NewMetacomp.G2.LP2A2.EQ.Solution.v1','solveId',solveId,'caseId',s.caseId,'meshSHA256',mh,'phaseSHA256',ph,'token',C.token,'K',K,'solveSeconds',secs, ...
 'approvedHead',G.approvedHead,'activationHead',activationHead,'memoryGate',Mg);
sh=lower(g2_trajectory_record('write',fullfile(sd,'SOLUTION.mat'),S));
pol9=jsondecode(fileread(fullfile(C.here,'lp2','G2_LP2A_POLICY_v1.json')));pol9.caps.maxStateIndex=9;pol9.caps.maxArcLength_mm=61.4;
Sn=St;Sn.KI=K.KI;Sn.KII=K.KII;F=g2_lp2_forecast(Sn,pol9);
Nn=struct('K',K,'D',D,'activeArea_mm2',K.activeArea_mm2,'chordsPerCircle',chN,'S9tip_mm',F.polyline_mm(end,:));
An=struct('state',St,'K',So.K,'D',Ma,'S9tip_mm',Tm.candidate.polyline_mm(end,:),'chordsPerCircle',chA);
Rc=g2_lp2a2_eq_compare(Nn,An,pol.tolerances);
Cm=struct('schema','NewMetacomp.G2.LP2A2.EQ.Comparison.v1','solveId',solveId,'caseId',s.caseId,'solutionSHA256',sh,'meshSHA256',mh, ...
 'archivedSolutionSHA256',pol.pins.archivedS8.(s.caseId).SOLUTION,'pass',Rc.pass,'criteria',Rc.criteria,'failed',{Rc.failed},'metrics',Rc.metrics, ...
 'newKI',K.KI,'newKII',K.KII,'newJ',K.J,'archivedKI',So.K.KI,'archivedKII',So.K.KII,'archivedJ',So.K.J,'S9tipNew_mm',Nn.S9tip_mm,'S9tipArchived_mm',An.S9tip_mm, ...
 'interpretation','numerical equivalence on this geometry only; not a certified discretization-error bound');
cf=fullfile(sd,'COMPARISON.json');fid=fopen(cf,'w');fwrite(fid,jsonencode(Cm,'PrettyPrint',true),'char');fclose(fid);
% ---- every record re-read and hash-checked (incomplete write -> HOLD)
ok=strcmpi(g2_sha256_file(mf),mh)&&strcmpi(g2_sha256_file(fullfile(sd,'PHASE.mat')),ph)&&strcmpi(g2_sha256_file(fullfile(sd,'SOLUTION.mat')),sh)&&isfile(cf);
if ok,Cr=jsondecode(fileread(cf));ok=strcmp(Cr.solutionSHA256,sh)&&isequal(logical(Cr.pass),Rc.pass);end
assert(ok,'G2LP2A2:HOLD_INCOMPLETE_WRITE','Records of %s incomplete or inconsistent after writing.',solveId);
O.stage='SOLVED_COMPARED';O.comparisonPass=Rc.pass;O.failed=Rc.failed;O.newK=struct('KI',K.KI,'KII',K.KII);O.solutionSHA256=sh;O.activationHead=activationHead;
end

function s=phaseOpts(C)
pm=jsondecode(fileread(fullfile(C.here,'G2_MATERIAL_POLICY_v1.json')));
s=struct('onCircleTol_mm',pm.phaseMap.onCircleTolerance_mm,'minGap_mm',pm.phaseMap.minGapToNextT3Vertex_mm,'midsideTol_mm',pm.phaseMap.midsideOnChordTolerance_mm);
end
