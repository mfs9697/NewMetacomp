function T=g2_lp2a2_eq_tests(varargin)
%G2_LP2A2_EQ_TESTS  Zero-FEM qualification of the PREPARED SIF-equivalence package.
%  E1 context: every pin verified, token formed, no GO file present
%  E2 identity: archived S8 solution compared with itself passes every criterion with zero deltas;
%     the S9 forecast recomputed from the archived K equals the TERMINAL candidate bitwise
%  E3 negatives: each criterion fails when its quantity is perturbed to twice its tolerance
%  E4 contrast: identity passes; F_G shift of 1.5x tolerance, sign flip and MTS shift fail
%  E5 refusal: Run=true with the correct token -> G2LP2A2:HOLD_UNAUTHORIZED, no output folder
%  E6 dry calls: all four solves READY_NOT_SOLVED (new-family mesh, audits, pairing, phase map;
%     zero solves, no write)
%  E3 also: direct perturbations aimed at C3 (K_II/K_I) and C5 (MTS); at the preregistered
%     tolerances both are implied by C2, so they fail TOGETHER with C2 (not separately triggerable)
%  E7 memory gate: the ACTUAL helper (PhysicalMemory.Available, same field as g2_lp0_preflight)
%     returns a finite positive reading consistent with memory(); >= 7 GiB gate pass/refuse logic;
%     below-threshold, NaN, non-positive and query-error readings refuse; the driver uses the gate
%  E8 GO validator: a valid in-memory fixture passes; every malformed or wrong field refuses with
%     the named check; an unvalidated approved head is never passed to git (no live GO file)
%  E9 preflight bypass: Run=true with Preflight=false -> HOLD_PREFLIGHT_REQUIRED, no folder
%  E10 wrapper: injected runners - all pass -> EQUIVALENT; exception / HOLD stage / incomplete
%     record / failed comparison / rejected GO stop the whole campaign at once (no later calls)
%  E11 replay: g2_lp2a2_eq_verify without records -> NO_RECORDS, nothing created
%  E12 real git (no injection): MATLAB system() -> cmd.exe on Windows -> git, on disposable inert
%     fixtures outside the repository (no production token, no physical record, no GO in the
%     repository): the ACTUAL default path of g2_lp2a2_eq_go_validate and the pre-wrapper check of
%     g2_lp2a2_eq_external_run, both through g2_lp2a2_git (HEAD~1, exit status, exact 40-hex):
%     valid activation, wrong parent (ancestor), non-ancestor, extra changed file, git failure (root
%     commit without parent; not a repository); the historical unquoted-caret defect reproduced as a
%     diagnostic; unsafe arguments refused. Commands, statuses, outputs and the independently known
%     fixture SHAs are returned in T.realGit.
ip=inputParser;addParameter(ip,'Dry',true,@islogical);parse(ip,varargin{:});
C=g2_lp2a2_eq_context();pol=C.policy;tol=pol.tolerances;R={};
R{end+1}=t('E1_context_pins_token',~isempty(strfind(C.token,'G2LP2A2EQ|policy='))&&~isfile(fullfile(C.repo,pol.goFile))&&strcmp(pol.status,'PREREGISTERED_NOT_AUTHORIZED'));
ids={'H','stiff13','soft2','soft1'};KA=struct();
pol9=jsondecode(fileread(fullfile(C.here,'lp2','G2_LP2A_POLICY_v1.json')));pol9.caps.maxStateIndex=9;pol9.caps.maxArcLength_mm=61.4;
lp=jsondecode(fileread(fullfile(C.here,'G2_LP1_POLICY_v2.json')));pm=jsondecode(fileread(fullfile(C.here,'G2_MATERIAL_POLICY_v1.json')));
po=struct('onCircleTol_mm',pm.phaseMap.onCircleTolerance_mm,'minGap_mm',pm.phaseMap.minGapToNextT3Vertex_mm,'midsideTol_mm',pm.phaseMap.midsideOnChordTolerance_mm);
for k=1:4
 ab=fullfile(C.archiveBase,ids{k});St=load(fullfile(ab,'S8','STATE.mat'));St=St.record;So=load(fullfile(ab,'S8','SOLUTION.mat'));So=So.record;
 Tm=load(fullfile(ab,'TERMINAL.mat'));Tm=Tm.record;Ma=load(fullfile(ab,'S8','MESH.mat'));
 PMa=g2_material_phase_map(Ma.X6,Ma.T6,lp.geometry.centres_mm,6.35*ones(3,1),19.05*ones(3,1),po);ch=arrayfun(@(q)size(q.chords,1),PMa.interfaces);
 F=g2_lp2_forecast(St,pol9);
 A=struct('state',St,'K',So.K,'D',Ma,'S9tip_mm',Tm.candidate.polyline_mm(end,:),'chordsPerCircle',ch);
 N=struct('K',So.K,'D',Ma,'activeArea_mm2',So.K.activeArea_mm2,'chordsPerCircle',ch,'S9tip_mm',F.polyline_mm(end,:));
 I=g2_lp2a2_eq_compare(N,A,tol);mv=cell2mat(struct2cell(rmfield(I.metrics,{'newJoverGminus1','newCODminusEDI_rel','archivedCODminusEDI_rel','newPathSpread_rel','archivedPathSpread_rel','newQuad4x4_rel','archivedQuad4x4_rel', ...
  'newMinSignedOpening_mm','archivedMinSignedOpening_mm','newSolverGatesPass','archivedSolverGatesPass'})));
 R{end+1}=t(sprintf('E2_identity_%s',ids{k}),I.pass&&all(mv==0)&&isequal(F.polyline_mm,Tm.candidate.polyline_mm)); %#ok<AGROW>
 KA.(ids{k})=So.K;
 if k==1
  Keq=hypot(So.K.KI,So.K.KII);neg={};
  neg(end+1,:)={'KI','C1_KI',@(n)setK(n,'KI',n.K.KI+2*tol.KI_overKeq*Keq)};
  neg(end+1,:)={'KII','C2_KII',@(n)setK(n,'KII',n.K.KII+2*tol.KII_overKeq*Keq)};
  neg(end+1,:)={'C3_direct','C3_KIIoverKI',@(n)setK(n,'KII',n.K.KII+1.2*tol.KIIoverKI_abs*n.K.KI)};
  neg(end+1,:)={'C5_direct','C5_MTS',@(n)setK(n,'KII',n.K.KII+1.2*tol.KII_overKeq*Keq)};
  neg(end+1,:)={'J','C4_G_J',@(n)setK(n,'J',n.K.J*(1+2*tol.J_rel))};
  neg(end+1,:)={'COD','C6_COD_EDI',@(n)setK(n,'KI_COD',n.K.KI_COD+sign(n.K.KI_COD-n.K.KI)*2*tol.dCODminusEDI*Keq)};
  neg(end+1,:)={'spread','C7_EDI_spread_quadrature',@(n)setEDI(n,2*max(tol.spreadFloor,tol.spreadFactor*1.7e-6)*Keq)};
  neg(end+1,:)={'opening','C8_crackOpening',@(n)scaleOpening(n,1+2*tol.openingWholeCrackRel)};
  neg(end+1,:)={'chords','C9_phaseActivation',@(n)setfield(n,'chordsPerCircle',n.chordsPerCircle+1)}; %#ok<SFLD>
  neg(end+1,:)={'area','C9_phaseActivation',@(n)setfield(n,'activeArea_mm2',n.activeArea_mm2+1e-6*max(n.activeArea_mm2,1))}; %#ok<SFLD>
  neg(end+1,:)={'S9tip','C10_S9predictor',@(n)setfield(n,'S9tip_mm',n.S9tip_mm+[2*tol.S9tipDisplacement_mm 0])}; %#ok<SFLD>
  neg(end+1,:)={'compliance','C11_compliance',@(n)setK(n,'compliance_mm_per_N',n.K.compliance_mm_per_N*(1+2*tol.compliance_rel))};
  for q=1:size(neg,1)
   Iq=g2_lp2a2_eq_compare(neg{q,3}(N),A,tol);
   R{end+1}=t(['E3_negative_',neg{q,1}],~Iq.pass&&any(strcmp(Iq.failed,neg{q,2}))); %#ok<AGROW>
  end
 end
end
Ci=g2_lp2a2_eq_contrast(KA,KA,tol);R{end+1}=t('E4_contrast_identity',Ci.pass&&all(Ci.dFG==0));
KB=KA;KB.soft2.KI=KB.soft2.KI*sqrt(1+1.5*tol.contrast_FG_abs/(1+Ci.FG_archived(2)));Cb=g2_lp2a2_eq_contrast(KB,KA,tol);
R{end+1}=t('E4_contrast_FG_shift',~Cb.pass&&any(strcmp(Cb.failed,'FG_within')));
KB=KA;KB.soft2.KI=KB.soft2.KI*sqrt(1.03);Cb=g2_lp2a2_eq_contrast(KB,KA,tol);R{end+1}=t('E4_contrast_sign_flip',~Cb.pass&&any(strcmp(Cb.failed,'FG_signs')));
KB=KA;KB.soft1.KII=KB.soft1.KII+0.0004*KB.soft1.KI;Cb=g2_lp2a2_eq_contrast(KB,KA,tol);R{end+1}=t('E4_contrast_MTS_shift',~Cb.pass&&any(strcmp(Cb.failed,'MTS_contrast_within')));
% ---- E7 memory gate (actual helper and injected readings; no FEM)
Ma7=g2_lp2a2_eq_memgate(7);[~,sv]=memory;ref=sv.PhysicalMemory.Available/2^30;
R{end+1}=t('E7_actual_helper_reading',isfinite(Ma7.freeGiB)&&Ma7.freeGiB>0&&abs(Ma7.freeGiB-ref)<0.5&&Ma7.pass==(Ma7.freeGiB>=7));
fprintf('EQ_MEMGATE actual free %.3f GiB, gate 7 GiB pass=%d (%s)\n',Ma7.freeGiB,Ma7.pass,Ma7.reason);
R{end+1}=t('E7_gate_at_threshold',g2_lp2a2_eq_memgate(7,@()7).pass&&~g2_lp2a2_eq_memgate(7,@()6.999).pass);
R{end+1}=t('E7_below_threshold_refuses',startsWith(getfield(g2_lp2a2_eq_memgate(7,@()3),'reason'),'BELOW_THRESHOLD')); %#ok<GFLD>
R{end+1}=t('E7_error_refuses',~g2_lp2a2_eq_memgate(7,@()error('x:y','probe')).pass&&startsWith(getfield(g2_lp2a2_eq_memgate(7,@()error('x:y','probe')),'reason'),'MEMORY_QUERY_FAILED')); %#ok<GFLD>
R{end+1}=t('E7_invalid_refuses',~g2_lp2a2_eq_memgate(7,@()NaN).pass&&~g2_lp2a2_eq_memgate(7,@()0).pass&&~g2_lp2a2_eq_memgate(7,@()[8 8]).pass);
src=fileread(fullfile(C.lp2a2,'g2_lp2a2_eq_run.m'));
R{end+1}=t('E7_driver_uses_gate',isempty(strfind(src,'PhysMemory'))&&~isempty(strfind(src,'g2_lp2a2_eq_memgate(pol.resources.freeRAMInsideMATLAB_GiB_min)'))&&pol.resources.freeRAMInsideMATLAB_GiB_min==7);
% ---- E8 GO validator on in-memory fixtures (no GO file is written)
ev=fullfile('matlab','g2','lp2a2','G2_LP2A2_EQ_POLICY_v1.json');head='0123456789abcdef0123456789abcdef01234567';
G0=struct('decision','GO_LP2A2_EQ','decisionUrl','https://github.com/mfs9697/NewMetacomp/pull/71#issuecomment-123456789','approvedHead',head, ...
 'token',C.token,'solveLimit',4,'solves',{{'EQ-H','EQ-stiff13','EQ-soft2','EQ-soft1'}},'campaignId',pol.campaignId, ...
 'contractEvidenceFile',strrep(ev,filesep,'/'),'contractEvidenceSHA256',lower(g2_sha256_file(fullfile(C.repo,ev))));
cnt=containers.Map({'n'},{0});
gitOK=struct('isAncestor',@(h)bump(cnt,true),'headParent',@()bump(cnt,head),'changedFiles',@(h)bump(cnt,{pol.goFile}));
V0=g2_lp2a2_eq_go_validate(G0,C,C.token,gitOK);R{end+1}=t('E8_valid_fixture_passes',V0.pass);
mut={'decision_wrong',@(g)setfield(g,'decision','GO'),'decision'; ...
 'decision_missing',@(g)rmfield(g,'decision'),'fields'; ...
 'token_wrong',@(g)setfield(g,'token',[C.token 'x']),'token'; ...
 'solveLimit_5',@(g)setfield(g,'solveLimit',5),'solveLimit'; ...
 'solves_reordered',@(g)setfield(g,'solves',{'EQ-stiff13','EQ-H','EQ-soft2','EQ-soft1'}),'solves'; ...
 'solves_three',@(g)setfield(g,'solves',{'EQ-H','EQ-stiff13','EQ-soft2'}),'solves'; ...
 'solves_extra',@(g)setfield(g,'solves',{'EQ-H','EQ-stiff13','EQ-soft2','EQ-soft1','EQ-H-R2'}),'solves'; ...
 'campaign_wrong',@(g)setfield(g,'campaignId','G2-LP2A-001'),'campaignId'; ...
 'url_other_repo',@(g)setfield(g,'decisionUrl','https://github.com/other/NewMetacomp/pull/71#issuecomment-1'),'decisionUrl'; ...
 'url_http',@(g)setfield(g,'decisionUrl','http://github.com/mfs9697/NewMetacomp/pull/71#issuecomment-1'),'decisionUrl'; ...
 'url_no_comment',@(g)setfield(g,'decisionUrl','https://github.com/mfs9697/NewMetacomp/pull/71'),'decisionUrl'; ...
 'url_placeholder',@(g)setfield(g,'decisionUrl','<INVESTIGATOR ONLY>'),'decisionUrl'; ...
 'head_short',@(g)setfield(g,'approvedHead','05bc5f1'),'approvedHead'; ...
 'head_uppercase',@(g)setfield(g,'approvedHead',upper(head)),'approvedHead'; ...
 'head_injection',@(g)setfield(g,'approvedHead',[head(1:39) ' && echo x']),'approvedHead'; ...
 'evidence_sha_wrong',@(g)setfield(g,'contractEvidenceSHA256',repmat('0',1,64)),'contractEvidence'; ...
 'evidence_path_escape',@(g)setfield(g,'contractEvidenceFile','../x.json'),'contractEvidence'};
for q=1:size(mut,1)
 Vq=g2_lp2a2_eq_go_validate(mut{q,2}(G0),C,C.token,gitOK);R{end+1}=t(['E8_reject_' mut{q,1}],~Vq.pass&&any(strcmp(Vq.failed,mut{q,3}))); %#ok<AGROW>
end
cnt('n')=0;Vi=g2_lp2a2_eq_go_validate(mut{15,2}(G0),C,C.token,gitOK);R{end+1}=t('E8_injection_never_reaches_git',~Vi.pass&&cnt('n')==0);
Vc=g2_lp2a2_eq_go_validate(G0,C,'wrong-caller-token',gitOK);R{end+1}=t('E8_reject_caller_token',~Vc.pass&&any(strcmp(Vc.failed,'token')));
gitNA=gitOK;gitNA.isAncestor=@(h)false;Vn=g2_lp2a2_eq_go_validate(G0,C,C.token,gitNA);R{end+1}=t('E8_reject_not_ancestor',~Vn.pass&&any(strcmp(Vn.failed,'ancestor')));
gitP=gitOK;gitP.headParent=@()repmat('f',1,40);Vp=g2_lp2a2_eq_go_validate(G0,C,C.token,gitP);R{end+1}=t('E8_reject_activation_parent',~Vp.pass&&any(strcmp(Vp.failed,'activationBinding')));
gitX=gitOK;gitX.changedFiles=@(h){pol.goFile,'matlab/g2/lp2a2/g2_lp2a2_mesh.m'};Vx=g2_lp2a2_eq_go_validate(G0,C,C.token,gitX);R{end+1}=t('E8_reject_activation_extra_file',~Vx.pass&&any(strcmp(Vx.failed,'activationBinding')));
% ---- E9 preflight bypass
od=fullfile(C.repo,pol.outputRoot);ex0=exist(od,'dir');
try,g2_lp2a2_eq_run('EQ-H','Run',true,'Token',C.token,'Preflight',false);ok=false;catch ME,ok=strcmp(ME.identifier,'G2LP2A2:HOLD_PREFLIGHT_REQUIRED');end
R{end+1}=t('E9_preflight_bypass_refused',ok&&exist(od,'dir')==ex0&&~ex0);
% ---- E10 wrapper stop rules with injected runners (no FEM, no write)
cid=containers.Map({'EQ-H','EQ-stiff13','EQ-soft2','EQ-soft1'},{'H','stiff13','soft2','soft1'});vOK=@()struct('pass',true,'failed',{{}});
okO=@(id)struct('stage','SOLVED_COMPARED','comparisonPass',true,'newK',struct('KI',KA.(cid(id)).KI,'KII',KA.(cid(id)).KII),'solutionSHA256',repmat('a',1,64),'failed',{{}});
calls=containers.Map({'n'},{0});
Wa=g2_lp2a2_eq_campaign(C.token,'Context',C,'Validator',vOK,'Runner',@(id)countRun(calls,okO(id)));
R{end+1}=t('E10_all_pass_equivalent',strcmp(Wa.outcome,'EQUIVALENT')&&calls('n')==4&&Wa.contrast.pass);
calls('n')=0;Wb=g2_lp2a2_eq_campaign(C.token,'Context',C,'Validator',vOK,'Runner',@(id)countRun(calls,failAt(id,'EQ-stiff13',okO(id),'throw')));
R{end+1}=t('E10_exception_stops',strcmp(Wb.outcome,'HOLD_EXCEPTION')&&strcmp(Wb.stoppedAt,'EQ-stiff13')&&calls('n')==2);
calls('n')=0;Wc=g2_lp2a2_eq_campaign(C.token,'Context',C,'Validator',vOK,'Runner',@(id)countRun(calls,failAt(id,'EQ-H',okO(id),'hold')));
R{end+1}=t('E10_hold_stage_stops',strcmp(Wc.outcome,'HOLD_STAGE')&&calls('n')==1);
calls('n')=0;Wd=g2_lp2a2_eq_campaign(C.token,'Context',C,'Validator',vOK,'Runner',@(id)countRun(calls,failAt(id,'EQ-soft2',okO(id),'compare')));
R{end+1}=t('E10_failed_comparison_stops',strcmp(Wd.outcome,'NOT_EQUIVALENT_HOLD')&&strcmp(Wd.stoppedAt,'EQ-soft2')&&calls('n')==3);
calls('n')=0;We=g2_lp2a2_eq_campaign(C.token,'Context',C,'Validator',vOK,'Runner',@(id)countRun(calls,failAt(id,'EQ-soft1',okO(id),'incomplete')));
R{end+1}=t('E10_incomplete_record_stops',strcmp(We.outcome,'HOLD_INCOMPLETE_RECORD')&&calls('n')==4);
calls('n')=0;Wf=g2_lp2a2_eq_campaign(C.token,'Context',C,'Validator',@()struct('pass',false,'failed',{{'decision'}}),'Runner',@(id)countRun(calls,okO(id)));
R{end+1}=t('E10_rejected_go_no_solve',strcmp(Wf.outcome,'HOLD_UNAUTHORIZED')&&calls('n')==0);
calls('n')=0;Wg=g2_lp2a2_eq_campaign(C.token,'Context',C,'Runner',@(id)countRun(calls,okO(id)));
R{end+1}=t('E10_default_validator_no_go_file',strcmp(Wg.outcome,'HOLD_UNAUTHORIZED')&&calls('n')==0);
% ---- E11 read-only replay without records
Rv=g2_lp2a2_eq_verify();R{end+1}=t('E11_replay_no_records',strcmp(Rv.outcome,'NO_RECORDS')&&Rv.physicalSolves==0&&~exist(od,'dir'));

try,g2_lp2a2_eq_run('EQ-H','Run',true,'Token',C.token);ok=false;catch ME,ok=strcmp(ME.identifier,'G2LP2A2:HOLD_UNAUTHORIZED');end
R{end+1}=t('E5_refusal_without_GO',ok&&exist(od,'dir')==ex0&&~ex0);
if ip.Results.Dry
 for k=1:4
  sid=pol.solves(k).id;
  try,O=g2_lp2a2_eq_run(sid);ok=strcmp(O.stage,'READY_NOT_SOLVED')&&O.physicalSolves==0&&strcmp(O.auditGates,'34/34')&&O.phaseAuditPass&&O.phaseMapPass&&O.pairingAudit==10;
   fprintf('EQ_DRY %s T3 %d (archived %d) pairsT6 %d (archived bank nodes %d) chords %s/%s\n',sid,O.T3,O.archivedT3,O.bankPairsT6,O.archivedBankNodesT6,mat2str(O.chordsPerCircle),mat2str(O.archivedChordsPerCircle));
  catch ME,ok=false;fprintf('EQ_DRY %s ERROR %s\n',sid,ME.message);end
  R{end+1}=t(['E6_dry_',sid],ok&&~exist(od,'dir')); %#ok<AGROW>
 end
end
[R12,RG]=realGitTests(pol,C.repo);R=[R,R12];
T=struct('schema','NewMetacomp.G2.LP2A2.EQ.Tests.v1','physicalSolves',0,'token',C.token,'lp2a2SourceSHA256',C.lp2a2SourceSHA256,'policySHA256',C.policySHA256, ...
 'passed',nnz(cellfun(@(r)r.pass,R)),'total',numel(R),'tests',{R},'realGit',RG);
fprintf('LP2A2_EQ_TESTS %d/%d\n',T.passed,T.total);
end

function r=t(name,ok),r=struct('name',name,'pass',logical(ok));fprintf('EQ_TEST %-32s %d\n',name,ok);end
function n=setK(n,f,v),n.K.(f)=v;end
function v=bump(m,v),m('n')=m('n')+1;end
function O=countRun(m,O)
m('n')=m('n')+1;if isa(O,'MException'),throw(O);end
end
function O=failAt(id,bad,O,mode)
if ~strcmp(id,bad),return,end
switch mode
 case 'throw',O=MException('G2LP2A2:TEST_EXCEPTION','injected exception');
 case 'hold',O.stage='HOLD_MESH_QUALITY';
 case 'compare',O.comparisonPass=false;O.failed={'C2_KII'};
 case 'incomplete',O=rmfield(O,'solutionSHA256');
end
end
function n=setEDI(n,d),n.K.EDI_all(2,1)=n.K.EDI_all(2,1)+d;end
function n=scaleOpening(n,f)
U=reshape(n.K.u,2,[]);up=n.D.upperBankT6(:);P=n.D.crackPolyline;far=vecnorm(n.D.X6(up,:)-P(end,:),2,2)>3.3+1e-9;
lo=n.D.lowerBankT6(:);
% scale the jump of every far-field pair by f (upper moved away from lower)
[~,iu]=sort(vecnorm(n.D.X6(up,:)-P(1,:),2,2));[~,il]=sort(vecnorm(n.D.X6(lo,:)-P(1,:),2,2));up=up(iu);lo=lo(il);far=far(iu);
U(:,up(far))=U(:,lo(far))+f*(U(:,up(far))-U(:,lo(far)));n.K.u=U(:);
end

function [R,Rec]=realGitTests(pol,prodRepo)
% E12: real git through MATLAB system() (cmd.exe on Windows) on disposable inert fixtures.
R={};fx=fullfile(tempdir,sprintf('lp2a2_e12_fixture_%s',datestr(now,'yyyymmddHHMMSSFFF')));fr=[fx '_rootonly'];fn=[fx '_notrepo'];
[~,gv]=system('git --version');
Rec=struct('schema','NewMetacomp.G2.LP2A2.EQ.RealGit.v1','matlabVersion',version,'release',version('-release'),'computer',computer, ...
 'ispc',ispc,'comSpec',getenv('ComSpec'),'gitVersion',strtrim(gv),'fixture','<tempdir>/lp2a2_e12_fixture_<stamp>','cases',struct([]));
goF=pol.goFile;
prodGo0=isfile(fullfile(prodRepo,goF));prodOut0=isfolder(fullfile(prodRepo,pol.outputRoot));
try
 % ---- fixture: c0 -> c1 (reviewed parent) -> cA (GO path only, inert content); side branch cS; extra cX
 mkdir(fx);sh(sprintf('git init -q "%s"',fx));sh(sprintf('git -C "%s" config core.autocrlf false',fx));
 wf(fx,'README_FIXTURE.txt','Inert LP2-A2 E12 git fixture. Not an authorization; no token; no physical record.');c0=commit(fx);
 wf(fx,'evidence/fixture_evidence.json','{"fixture":"inert contract-evidence stand-in"}');c1=commit(fx);
 sh(sprintf('git -C "%s" checkout -q -b side %s',fx,c0));wf(fx,'side.txt','side branch');cS=commit(fx);
 sh(sprintf('git -C "%s" checkout -q -b valid %s',fx,c1));wf(fx,goF,'{"fixture":"INERT_NOT_AN_AUTHORIZATION"}');cA=commit(fx);
 sh(sprintf('git -C "%s" checkout -q -b extra %s',fx,c1));wf(fx,goF,'{"fixture":"INERT_NOT_AN_AUTHORIZATION"}');wf(fx,'extra.txt','additional changed file');cX=commit(fx);
 mkdir(fr);sh(sprintf('git init -q "%s"',fr));sh(sprintf('git -C "%s" config core.autocrlf false',fr));wf(fr,'README_FIXTURE.txt','single root commit');cR=commit(fr);
 mkdir(fn);
 [~,cat]=system(sprintf('git -C "%s" cat-file -p %s',fx,cA));pl=regexp(cat,'(?m)^parent ([0-9a-f]{40})','tokens');pl=[pl{:}];
 Rec.fixtureCommits=struct('c0',c0,'c1_reviewedParent',c1,'cS_sideBranch',cS,'cA_validActivation',cA,'cX_extraFile',cX,'cR_rootOnly',cR,'catFileParentsOfCA',{pl});
 tokF='FIXTURE-INERT-TOKEN-NOT-A-PRODUCTION-TOKEN';
 ev='evidence/fixture_evidence.json';
 G=struct('decision','GO_LP2A2_EQ','decisionUrl','https://github.com/mfs9697/NewMetacomp/pull/71#pullrequestreview-6063184270','approvedHead',c1, ...
  'token',tokF,'solveLimit',4,'solves',{{'EQ-H','EQ-stiff13','EQ-soft2','EQ-soft1'}},'campaignId',pol.campaignId, ...
  'contractEvidenceFile',ev,'contractEvidenceSHA256',lower(g2_sha256_file(fullfile(fx,ev))));
 Cf=struct('repo',fx,'policy',pol,'token',tokF);
 inert=~contains(fileread(fullfile(fx,'README_FIXTURE.txt')),'G2LP2A2EQ|')&&~contains(fileread(fullfile(fx,ev)),'G2LP2A2EQ|')&&~startsWith(lower(strrep(fx,'\','/')),lower(strrep(prodRepo,'\','/')));
 R{end+1}=t('E12_fixture_inert_outside_repo',inert&&numel(pl)==1&&strcmp(pl{1},c1));
 % ---- historical defect reproduced (diagnostic): unquoted caret through system()
 sh(sprintf('git -C "%s" checkout -q valid',fx));
 [s1,o1]=system(sprintf('git -C "%s" rev-parse HEAD^',fx));[s2,o2]=system(sprintf('git -C "%s" rev-parse "HEAD^"',fx));
 Rec.caretDiagnostic=struct('unquotedCommand','git -C "<fixture>" rev-parse HEAD^','unquotedStatus',s1,'unquotedOutput',strtrim(o1), ...
  'quotedStatus',s2,'quotedOutput',strtrim(o2),'head',cA,'expectedParent',c1);
 if ispc,R{end+1}=t('E12_caret_defect_reproduced',s1==0&&strcmp(strtrim(o1),cA)&&strcmp(strtrim(o2),c1));end
 % ---- cases through the ACTUAL default validator path and the external parent check
 K={'valid_activation','valid',c1,fx,true,{},true; ...
    'wrong_parent_ancestor','valid',c0,fx,false,{'activationBinding'},false; ...
    'not_ancestor','valid',cS,fx,false,{'ancestor','activationBinding'},false; ...
    'extra_changed_file','extra',c1,fx,false,{'activationBinding'},false; ...
    'git_failure_root_commit','',c1,fr,false,{'ancestor','activationBinding'},false; ...
    'git_failure_not_a_repository','',c1,fn,false,{'ancestor','activationBinding'},false};
 for k=1:size(K,1)
  [nm,br,ah,rp,expPass,expFail,expExt]=K{k,:};
  if ~isempty(br),sh(sprintf('git -C "%s" checkout -q %s',rp,br));end
  Gk=G;Gk.approvedHead=ah;Ck=Cf;Ck.repo=rp;
  if ~strcmp(rp,fx),copyfile(fullfile(fx,'evidence'),fullfile(rp,'evidence'));end
  Hh=g2_lp2a2_git('head',rp);Hp=g2_lp2a2_git('parent',rp);Ha=g2_lp2a2_git('isAncestor',rp,ah);Hf=g2_lp2a2_git('changedFiles',rp,ah);
  V=g2_lp2a2_eq_go_validate(Gk,Ck,tokF);             % 3 arguments -> real default git path
  P=g2_lp2a2_eq_external_run(ah,'','','ParentCheckOnly',true,'Repo',rp);
  expParent='';if ~isempty(br),expParent=c1;end   % fixture branches valid/extra both sit on c1
  parentOK=strcmp(Hp.value,expParent)&&(isempty(expParent)||(Hp.status==0&&Hp.ok))&&(~isempty(expParent)||(Hp.status~=0&&~Hp.ok));
  okV=V.pass==expPass&&isequal(sort(reshape(V.failed,1,[])),sort(reshape(expFail,1,[])));okP=P.pass==expExt;
  R{end+1}=t(['E12_validator_' nm],okV&&parentOK); %#ok<AGROW>
  R{end+1}=t(['E12_external_check_' nm],okP&&parentOK); %#ok<AGROW>
  c=struct('case',nm,'approvedHead',ah,'expectedParent',expParent,'expectedValidatorPass',expPass,'expectedFailed',{expFail}, ...
   'gitHead',sanit(Hh,rp),'gitParent',sanit(Hp,rp),'gitIsAncestor',sanit(Ha,rp),'gitChangedFiles',sanit(Hf,rp), ...
   'validatorPass',V.pass,'validatorChecks',V.checks,'validatorFailed',{V.failed}, ...
   'externalCheck',struct('pass',P.pass,'parentOk',P.parentOk,'filesOk',P.filesOk,'head',P.head,'parent',P.parent,'statuses',P.statuses,'changedFiles',{P.changedFiles}));
  if isempty(Rec.cases),Rec.cases=c;else,Rec.cases(end+1)=c;end
 end
 % ---- unsafe arguments are refused before any shell call
 try,g2_lp2a2_git('isAncestor',fx,'HEAD^');a=false;catch ME,a=strcmp(ME.identifier,'G2LP2A2:GIT_UNSAFE_ARG');end
 try,g2_lp2a2_git('head','%TEMP%');b=false;catch ME,b=strcmp(ME.identifier,'G2LP2A2:GIT_UNSAFE_REPO');end
 R{end+1}=t('E12_unsafe_arguments_refused',a&&b);
catch ME
 fprintf('E12 ERROR %s: %s\n',ME.identifier,ME.message);R{end+1}=t('E12_fixture_error',false);Rec.error=[ME.identifier ': ' ME.message];
end
R{end+1}=t('E12_no_production_go_or_output',~prodGo0&&~prodOut0&&~isfile(fullfile(prodRepo,goF))&&~isfolder(fullfile(prodRepo,pol.outputRoot)));
rm=true;for d={fx,fr,fn},if isfolder(d{1}),[~,~]=system(sprintf('attrib -R "%s\\*" /S /D',d{1}));try,rmdir(d{1},'s');catch,rm=false;end,end,end
Rec.fixturesRemoved=rm&&~isfolder(fx)&&~isfolder(fr)&&~isfolder(fn);
end

function sh(cmd)
[st,o]=system(cmd);assert(st==0,'G2LP2A2:E12_SETUP','fixture setup failed (%d): %s',st,o);
end
function wf(root,rel,txt)
p=fullfile(root,rel);d=fileparts(p);if ~isfolder(d),mkdir(d);end
fid=fopen(p,'w');fwrite(fid,txt,'char');fclose(fid);
end
function c=commit(root)
sh(sprintf('git -C "%s" add -A',root));
sh(sprintf('git -C "%s" -c user.name=lp2a2-fixture -c user.email=fixture@example.invalid -c commit.gpgsign=false commit -q -m fixture',root));
[st,o]=system(sprintf('git -C "%s" rev-parse --verify HEAD',root));c=strtrim(o);
assert(st==0&&~isempty(regexp(c,'^[0-9a-f]{40}$','once')),'G2LP2A2:E12_SETUP','commit hash');
end
function S=sanit(Rg,rp)
S=Rg;S.command=strrep(S.command,rp,'<fixture>');
end
