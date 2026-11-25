function T=g2_lp2a3_tests(varargin)
%G2_LP2A3_TESTS  Zero-FEM contract qualification of the prepared LP2-A3 controller.
% Inert fixtures under tempdir and injected non-solving operations; real archived S8 parents are read
% only; no record of the repository is written; no GO is created in the repository.
%  A  context, pins, token, no GO, four parents (bitwise S9 = archived TERMINAL candidate)
%  B  1-mm ring-proximity guard: exactly 1 mm passes, below fails; active/passive attribution
%  C  classification wrapper (MATRIX_ADVANCE, INTERFACE_APPROACH, PASSIVE_CONTOUR_APPROACH, precedence)
%  D  default-rung mesh: identical to rung 1 of g2_lp2a2_mesh; a rung-1 failure never falls back
%     (real geometry that needs rung 2 in the LP2-A2 ladder); seed spacing cannot be passed
%  E  failure classes
%  F  admission hook: S9 first, order, repeat, S12, 3 per case, 12 total, closed campaign
%  G  chain with injected operations: normal S9-S11 path + S12 information-only, all four cases and
%     closure; local stops (guard, mesh rung 1, invalid MTS); pre-admission memory and unexpected
%     global failure (ledger HOLD, no terminal); no retry; verify of prefix, terminal, ledger;
%     tampering (mesh hash, parent link, gap in the chain); post-closure read-only replay
%  H  GO: refusal without GO, preflight bypass, validator negatives, JSON round trip (empty / mixed lists)
%  I  real git through MATLAB system() on an inert fixture (validator default path, external check)
%  J  regression: corrected WP5 replay (lp2a2_eq_closure_verify) on the real records, read-only
ip=inputParser;addParameter(ip,'Mesh',true,@islogical);addParameter(ip,'RealGit',true,@islogical);addParameter(ip,'Closure',true,@islogical);parse(ip,varargin{:});o=ip.Results;
C=g2_lp2a3_context('Preflight',false);pol=C.policy;R={};ids={pol.cases.id};
R{end+1}=t('A1_token_and_no_GO',startsWith(C.token,'G2LP2A3|policy=')&&~isfile(C.goFile)&&strcmp(pol.status,'PROPOSED_NOT_AUTHORIZED'));
R{end+1}=t('A2_roots_absent',~isfolder(C.runRoot)&&~isfolder(C.ledgerRoot));
Par=struct();ok=true;
for k=1:4,Pk=g2_lp2a3_parent(C,ids{k});Par.(ids{k})=Pk;ok=ok&&Pk.terminalComparison.bitwiseEqual&&Pk.state.stateIndex==8;end
R{end+1}=t('A3_four_S8_parents_bitwise_terminal',ok);
% ---------------------------------------------------------------- B guard
pg=pol;pg.geometry.centres_mm=[0 0;1000 0;2000 0];pg.ringProximityGuard.ringR_mm=19;pg.ringProximityGuard.guideRadius_mm=15;
G1=g2_lp2a3_guard([35 0],[0 0 0],pg);G2=g2_lp2a3_guard([35-1e-9 0],[0 0 0],pg);G3=g2_lp2a3_guard([35-1e-9 0],[1 0 0],pg);
R{end+1}=t('B1_exactly_1mm_passes',G1.pass&&G1.minGap_mm==1);
R{end+1}=t('B2_below_1mm_fails_passive',~G2.pass&&strcmp(G2.constraints(1).type,'NUMERICAL_RING')&&strcmp(G2.constraints(1).object,'ring1'));
R{end+1}=t('B3_below_1mm_fails_active',~G3.pass&&strcmp(G3.constraints(1).type,'PHYSICAL_INTERFACE'));
G4=g2_lp2a3_guard([1500 0],[1 1 1],pg);R{end+1}=t('B4_every_ring_checked',G4.pass&&abs(G4.gap_mm(2)-466)<1e-9&&numel(G4.gap_mm)==3);
try,g2_lp2a3_guard([NaN 0],[0 0 0],pg);ok=false;catch ME,ok=strcmp(ME.identifier,'G2LP2A3:HOLD_INPUT');end,R{end+1}=t('B5_nonfinite_tip_refused',ok);
% ---------------------------------------------------------------- C classification
H9=Par.H.S9forecast.polyline_mm;Rh=g2_lp0_clearance(H9(1:end-1,:),H9(end,:),Par.H.geom,pol);
Th=g2_lp2a3_classify(Rh,[0 0 0],pol,H9(end,:));R{end+1}=t('C1_H_S9_matrix_advance',strcmp(Th.classification,'MATRIX_ADVANCE'));
Rp=struct('pass',true,'status','OK','reasons',{{}},'metrics',Rh.metrics);
Tp=g2_lp2a3_classify(Rp,[0 0 0],pg,[35-1e-9 0]);Ta=g2_lp2a3_classify(Rp,[1 0 0],pg,[35-1e-9 0]);
R{end+1}=t('C2_passive_only_is_PASSIVE_CONTOUR_APPROACH',strcmp(Tp.classification,'PASSIVE_CONTOUR_APPROACH'));
R{end+1}=t('C3_active_is_INTERFACE_APPROACH',strcmp(Ta.classification,'INTERFACE_APPROACH'));
Tx=g2_lp2a3_classify(Rp,[0 1 0],pg,[35-1e-9 0]);R{end+1}=t('C4_attribution_by_ring_activity',strcmp(Tx.classification,'PASSIVE_CONTOUR_APPROACH'));
% ---------------------------------------------------------------- D mesh
if o.Mesh
 addpath(fullfile(C.here,'vendor_p010_a14d8872'),'-begin');
 op=pol.meshFamily.ExteriorOptions;xo={'BottomVertices_mm',op.BottomVertices_mm(:).','TopVertices_mm',op.TopVertices_mm,'TipGuideRadius_mm',op.TipGuideRadius_mm,'TipGuideHface_mm',op.TipGuideHface_mm};
 S8=Par.H.state;a={'ExpectedVertices',10,'ExpectedTangent',S8.tangent,'ExteriorOptions',xo,'MaxT3Elements',40000};
 D3=g2_lp2a3_mesh(S8.polyline_mm,a{:});D2=g2_lp2a2_mesh(S8.polyline_mm,a{:});
 same=D3.pass&&D2.pass&&D2.seedRung==1&&isequal(D3.X6,D2.X6)&&isequal(D3.T6,D2.T6)&&isequal(D3.T3,D2.T3)&&isequal(D3.upperBankT6,D2.upperBankT6)&&isequal(D3.lowerBankT6,D2.lowerBankT6);
 R{end+1}=t('D1_identical_to_ladder_rung1_H_S8',same);
 TS=jsondecode(fileread(fullfile(C.repo,'docs','research','G2_LP2A2_evidence','LP2A2_TEST_SET.json')));rows=TS.rows;if ~iscell(rows),rows=num2cell(rows);end
 r=rows{cellfun(@(x)strcmp(x.id,'C2_stiff13_straight_S10'),rows)};b={'ExpectedVertices',size(r.polyline_mm,1),'ExpectedTangent',reshape(r.tangent,1,2),'ExteriorOptions',xo,'MaxT3Elements',40000};
 F3=g2_lp2a3_mesh(r.polyline_mm,b{:});F2=g2_lp2a2_mesh(r.polyline_mm,b{:});
 R{end+1}=t('D2_rung1_failure_no_fallback',~F3.pass&&numel(F3.ladder)==1&&F3.seedSpacing_mm==0.45&&F2.pass&&F2.seedRung==2);
 fprintf('LP2A3_TEST D2 rung1 stage=%s gates=[%s]; ladder rung=%d\n',F3.stage,strjoin(F3.failedGates,','),F2.seedRung);
end
try,g2_lp2a3_mesh([0 0;0 1;1 1],'ExteriorOptions',{'SeedSpacing_mm',0.4});ok=false;catch ME,ok=strcmp(ME.identifier,'G2LP2A3:HOLD_INPUT');end
R{end+1}=t('D3_seed_spacing_cannot_be_passed',ok);
% ---------------------------------------------------------------- E failure classes
R{end+1}=t('E1_failure_classes',strcmp(g2_lp2a3_failure_class('G2LP2A3:HOLD_MESH_QUALITY',true),'LOCAL')&&strcmp(g2_lp2a3_failure_class('G2LP2A3:HOLD_PAIRING',true),'LOCAL')&& ...
 strcmp(g2_lp2a3_failure_class('G2LP2:HOLD_K_EXTRACTION',false),'LOCAL')&&strcmp(g2_lp2a3_failure_class('G2LP1:HOLD_MEMORY',false),'PREADMISSION_MEMORY')&& ...
 strcmp(g2_lp2a3_failure_class('G2LP1:HOLD_MEMORY',true),'GLOBAL')&&strcmp(g2_lp2a3_failure_class('G2LP2A3:HOLD_SOURCE',true),'GLOBAL')&&strcmp(g2_lp2a3_failure_class('X:unexpected',true),'GLOBAL'));
% ---------------------------------------------------------------- F admission hook
fx=fullfile(tempdir,sprintf('lp2a3_tests_%s',datestr(now,'yyyymmddHHMMSSFFF')));mkdir(fx);
L=fullfile(fx,'ledgerF');Op=struct('mode','OPEN_NEW');hk=@(id,k)g2_lp2a3_admit_hook(L,Op,'FIX',id,k,pol);
R{end+1}=t('F1_S10_before_S9_refused',refuses(@()hk('H',10),'G2LP1:HOLD_CAMPAIGN_INTEGRITY'));
hk('H',9);R{end+1}=t('F2_repeat_refused',refuses(@()hk('H',9),'G2LP1:HOLD_CAMPAIGN_INTEGRITY'));
R{end+1}=t('F3_S11_skipping_S10_refused',refuses(@()hk('H',11),'G2LP1:HOLD_CAMPAIGN_INTEGRITY'));
hk('H',10);hk('H',11);R{end+1}=t('F4_S12_refused',refuses(@()hk('H',12),'G2LP2A3:HOLD_UNAUTHORIZED_STATE'));
for id=ids(2:4),for k=9:11,hk(id{1},k);end,end
Ls=g2_lp1_campaign_ledger('snapshot',L);R{end+1}=t('F5_twelve_admissions_recorded',numel(Ls.admits)==12&&Ls.integrityOK);
R{end+1}=t('F6_thirteenth_refused',refuses(@()hk('soft1',9),'G2LP2A3:HOLD_UNAUTHORIZED_STATE'));
R{end+1}=t('F7_closed_campaign_refused',refuses(@()g2_lp2a3_admit_hook(fullfile(fx,'ledgerF2'),struct('mode','VERIFY_ONLY'),'FIX','H',9,pol),'G2LP1:HOLD_CAMPAIGN_CLOSED'));
% ---------------------------------------------------------------- G chain with injected operations
stub=struct('forecast',@g2_lp2_forecast,'clearance',@(P,n,g,p)struct('pass',true,'status','OK','reasons',{{}},'metrics',Rh.metrics), ...
 'classify',@(Rr,m,p,tip)struct('classification','MATRIX_ADVANCE','constraints',struct('object',{},'type',{},'guard',{},'margin_mm',{})));
run=newRun(fx,'runG',C);out={};
for k=1:4,[out{k},env]=chainCase(run,ids{k},Par,C,stub,[]);end %#ok<ASGLU,AGROW>
Tm=readT(run,'H');
R{end+1}=t('G1_three_states_and_limit',strcmp(out{1}.terminal,'CAMPAIGN_LIMIT_REACHED')&&out{1}.computed==3&&out{1}.lastState==11&&Tm.candidateIsInformationOnly&&size(Tm.candidate.polyline_mm,1)==14);
R{end+1}=t('G2_S12_information_only_label',~isempty(strfind(Tm.note,'S12 candidate forecast for information only'))&&~isfolder(fullfile(run.rd,'H','S12')));
R{end+1}=t('G3_all_cases_closed',all(cellfun(@(x)strcmp(x.terminal,'CAMPAIGN_LIMIT_REACHED'),out))&&out{4}.campaignClosed&&isfile(fullfile(run.lroot,'CLOSED.mat')));
Vr=g2_lp2a3_verify(verifierFor(run,C,Par,true));R{end+1}=t('G4_full_verify_pass',Vr.pass&&Vr.closed&&Vr.ledgerAdmits==12);
h0=treeHash(fx);Vr2=g2_lp2a3_verify(verifierFor(run,C,Par,true));R{end+1}=t('G5_postclosure_replay_read_only',Vr2.pass&&isequal(h0,treeHash(fx)));
envV=env;envV.campMode='VERIFY_ONLY';envV.caseId='H';envV.chain=fullfile(fx,'emptyChain');
Ov=g2_lp2a3_chain(envV,stub);
R{end+1}=t('G6_closed_campaign_computes_nothing',strcmp(Ov.status,'GLOBAL_HOLD')&&Ov.hold.campaignRefusal&&Ov.computed==0);
% local stop by the real guard at S10 (classification), real clearance from the parent geometry
run2=newRun(fx,'runG2',C);cntG=containers.Map({'n'},{0});
real=struct('forecast',@g2_lp2_forecast,'clearance',stub.clearance,'classify',@(Rr,m,p,tip)guardStop(Rr,m,p,tip,cntG,2));
Og=chainCase(run2,'stiff13',Par,C,real,[]);Tg=readT(run2,'stiff13');
R{end+1}=t('G7_local_guard_stop_at_S10',strcmp(Og.terminal,'INTERFACE_APPROACH')&&Og.lastState==9&&~isfolder(fullfile(run2.rd,'stiff13','S10'))&&any(strcmp({Tg.candidate.constraints.guard},'guideRingGap1mm')));
Ls=g2_lp1_campaign_ledger('snapshot',run2.lroot);R{end+1}=t('G8_no_admission_after_guard_stop',isequal(sort(cellstr(Ls.admits)),{'stiff13_S9'}));
% local mesh failure at S9: NUMERICAL_HOLD, HOLD.mat, never retried
Om=chainCase(run2,'soft2',Par,C,stub,'G2LP2A3:HOLD_MESH_QUALITY');
R{end+1}=t('G9_rung1_mesh_failure_local_hold',strcmp(Om.terminal,'NUMERICAL_HOLD')&&Om.lastState==8&&isfile(fullfile(run2.rd,'soft2','S9','HOLD.mat'))&&~isfile(fullfile(run2.rd,'soft2','S9','STATE.mat')));
Om2=chainCase(run2,'soft2',Par,C,stub,[]);R{end+1}=t('G10_no_retry_after_local_hold',strcmp(Om2.terminal,'NUMERICAL_HOLD')&&Om2.computed==0);
% invalid signed MTS (KI <= 0) of a parent: LOCAL, terminal without folder
P2=Par;P2.soft1.state.KI=-abs(P2.soft1.state.KI);Oi=chainCase(run2,'soft1',P2,C,stub,[]);
R{end+1}=t('G11_invalid_MTS_local_hold',strcmp(Oi.terminal,'NUMERICAL_HOLD')&&~isfolder(fullfile(run2.rd,'soft1','S9')));
% global failures: unexpected error after admission; pre-admission memory
run3=newRun(fx,'runG3',C);Ox=chainCase(run3,'H',Par,C,stub,'X:unexpected');Lx=g2_lp1_campaign_ledger('snapshot',run3.lroot);
R{end+1}=t('G12_unexpected_global_hold',strcmp(Ox.status,'GLOBAL_HOLD')&&~isfile(fullfile(run3.rd,'H','TERMINAL.mat'))&&numel(Lx.holds)==1&&isfile(fullfile(run3.rd,'H','S9','HOLD.mat')));
run4=newRun(fx,'runG4',C);Oq=chainCase(run4,'H',Par,C,setfield(stub,'admitError','G2LP1:HOLD_MEMORY'),[]); %#ok<SFLD>
Lq=g2_lp1_campaign_ledger('snapshot',run4.lroot);
R{end+1}=t('G13_preadmission_memory_global',strcmp(Oq.status,'GLOBAL_HOLD')&&~isfolder(fullfile(run4.rd,'H','S9'))&&numel(Lq.holds)==1&&~isfile(fullfile(run4.rd,'H','TERMINAL.mat')));
% tampering of the verified closed fixture
V0=verifierFor(run,C,Par,true);Vt=V0;Vt.parents.H.stateSHA256=repmat('0',1,64);R{end+1}=t('G14_altered_parent_link_detected',~g2_lp2a3_verify(Vt).pass);
mf=fullfile(run.rd,'H','S10','MESH.mat');fid=fopen(mf,'r');b0=fread(fid,inf,'*uint8');fclose(fid);fid=fopen(mf,'a');fwrite(fid,'x');fclose(fid);
Vb=g2_lp2a3_verify(V0);R{end+1}=t('G15_mesh_tamper_detected',~Vb.pass&&any(contains(Vb.problems,'MESH hash')));
fid=fopen(mf,'w');fwrite(fid,b0,'uint8');fclose(fid);   % restore (fixture only)
movefile(fullfile(run.rd,'soft1','S10'),fullfile(fx,'S10_moved'));Vg=g2_lp2a3_verify(V0);
R{end+1}=t('G16_gap_in_chain_detected',~Vg.pass&&any(contains(Vg.problems,'contiguous')));
Pa=pol;Pa.parents.S8.H.STATE=repmat('a',1,64);Ca=C;Ca.policy=Pa;R{end+1}=t('G17_parent_pin_mismatch_refused',refuses(@()g2_lp2a3_parent(Ca,'H'),'G2LP2A3:HOLD_SOURCE'));
% ---------------------------------------------------------------- H GO
R{end+1}=t('H0_no_GO_refused_with_real_preflight',refuses(@()g2_lp2a3_run('Case','H','Run',true,'AuthToken',C.token),'G2LP2A3:HOLD_UNAUTHORIZED')&&~isfolder(C.runRoot)&&~isfolder(C.ledgerRoot));
R{end+1}=t('H1_preflight_bypass_refused',refuses(@()g2_lp2a3_run('Case','H','Run',true,'Preflight',false,'AuthToken',C.token),'G2LP2A3:HOLD_PREFLIGHT_REQUIRED'));
head='0123456789abcdef0123456789abcdef01234567';au=pol.authorization;
ev=struct('exists',true,'sha256',repmat('b',1,64),'text',jsonencode(struct('passed',60,'total',60,'physicalSolves',0,'token',C.token)));
G0=struct('decision','GO_LP2A3_PHYSICAL','decisionUrl','https://github.com/mfs9697/NewMetacomp/pull/75#issuecomment-123','approvedHead',head,'token',C.token, ...
 'campaignId',au.campaignId,'campaignScope',au.campaignScope,'runName',au.runName,'cases',{{'H','stiff13','soft2','soft1'}},'maxStateIndex',11,'maxAdmissions',12, ...
 'seedSpacing_mm',0.45,'contractEvidenceFile',[au.contractEvidenceDir 'x/T.json'],'contractEvidenceSHA256',repmat('b',1,64));
cnt=containers.Map({'n'},{0});gitOK=struct('isAncestor',@(h)bump(cnt,true),'headParent',@()bump(cnt,head),'changedFiles',@(h)bump(cnt,{au.goPath}));
le=@(p)ev;V=@(G,g)g2_lp2a3_go_validate(G,C,C.token,g,le);
R{end+1}=t('H2_valid_fixture_passes',V(G0,gitOK).pass);
Gj=jsondecode(jsonencode(G0));R{end+1}=t('H3_json_round_trip_passes',V(Gj,gitOK).pass);
mut={'decision',@(G)setfield(G,'decision','GO_LP2A_PHYSICAL'),'decision';'url',@(G)setfield(G,'decisionUrl','https://github.com/other/NewMetacomp/pull/1#issuecomment-1'),'decisionUrl'; ...
 'token',@(G)setfield(G,'token','G2LP2A3|x'),'token';'campaignId',@(G)setfield(G,'campaignId','G2-LP2A-001'),'campaign';'runName',@(G)setfield(G,'runName','run_lp2a_s5_s8_v1'),'campaign'; ...
 'scope',@(G)setfield(G,'campaignScope','LP2A_S5_S8_MAX16'),'campaign';'order',@(G)setfield(G,'cases',{{'stiff13','H','soft2','soft1'}}),'cases'; ...
 'casesEmptyJSON',@(G)jsondecode(strrep(jsonencode(G),'["H","stiff13","soft2","soft1"]','[]')),'cases'; ...
 'casesMixedJSON',@(G)jsondecode(strrep(jsonencode(G),'["H","stiff13","soft2","soft1"]','["H",1,"soft2","soft1"]')),'cases'; ...
 'maxState',@(G)setfield(G,'maxStateIndex',12),'caps';'maxAdm',@(G)setfield(G,'maxAdmissions',13),'caps';'seed',@(G)setfield(G,'seedSpacing_mm',0.4),'caps'; ...
 'headShort',@(G)setfield(G,'approvedHead','0123456'),'approvedHead';'headUpper',@(G)setfield(G,'approvedHead',upper(head)),'approvedHead'; ...
 'headInject',@(G)setfield(G,'approvedHead',[head(1:39) '&']),'approvedHead';'evidenceDir',@(G)setfield(G,'contractEvidenceFile','docs/research/x/T.json'),'evidence'; ...
 'evidenceSHA',@(G)setfield(G,'contractEvidenceSHA256',repmat('c',1,64)),'evidence';'missingField',@(G)rmfield(G,'maxAdmissions'),'fields'};
for q=1:size(mut,1),Vq=V(mut{q,2}(G0),gitOK);R{end+1}=t(['H4_reject_' mut{q,1}],~Vq.pass&&any(strcmp(Vq.failed,mut{q,3})));end %#ok<AGROW>
cnt('n')=0;Vi=V(setfield(G0,'approvedHead',[head(1:39) '&']),gitOK);R{end+1}=t('H5_invalid_head_never_reaches_git',~Vi.pass&&cnt('n')==0); %#ok<SFLD>
evBad=ev;evBad.text=jsonencode(struct('passed',59,'total',60,'physicalSolves',0,'token',C.token));
R{end+1}=t('H6_reject_failed_evidence',~g2_lp2a3_go_validate(G0,C,C.token,gitOK,@(p)evBad).pass);
evTok=ev;evTok.text=jsonencode(struct('passed',60,'total',60,'physicalSolves',0,'token','other'));
R{end+1}=t('H7_reject_evidence_other_token',~g2_lp2a3_go_validate(G0,C,C.token,gitOK,@(p)evTok).pass);
R{end+1}=t('H8_reject_caller_token',~g2_lp2a3_go_validate(G0,C,'wrong',gitOK,le).pass);
g=gitOK;g.isAncestor=@(h)false;R{end+1}=t('H9_reject_not_ancestor',any(strcmp(V(G0,g).failed,'ancestor')));
g=gitOK;g.headParent=@()repmat('f',1,40);R{end+1}=t('H10_reject_wrong_parent',any(strcmp(V(G0,g).failed,'activationBinding')));
g=gitOK;g.changedFiles=@(h){au.goPath,'matlab/g2/lp2a3/g2_lp2a3_run.m'};R{end+1}=t('H11_reject_extra_file',any(strcmp(V(G0,g).failed,'activationBinding')));
R{end+1}=t('H12_malformed_record_rejected',~V([],gitOK).pass&&~V(struct('decision',{1,2}),gitOK).pass);
% ---------------------------------------------------------------- I real git (Windows system())
RG=struct();if o.RealGit,[Ri,RG]=realGit(pol);R=[R,Ri];end
% ---------------------------------------------------------------- J WP5 replay regression (read-only)
RJ=struct();
if o.Closure
 addpath(fullfile(C.repo,'scripts','g2','lp2a2','closure'),'-begin');
 RJ=lp2a2_eq_closure_verify(C.repo);R{end+1}=t('J1_WP5_corrected_replay_VERIFIED_V2',strcmp(RJ.outcome,'VERIFIED_V2'));
 RJ=struct('outcome',RJ.outcome,'problems',{RJ.problems});
end
rm=true;try,[~,~]=system(sprintf('attrib -R "%s\\*" /S /D',fx));rmdir(fx,'s');catch,rm=false;end
R{end+1}=t('Z1_repository_untouched',~isfile(C.goFile)&&~isfolder(C.runRoot)&&~isfolder(C.ledgerRoot));
T=struct('schema','NewMetacomp.G2.LP2A3.Tests.v1','physicalSolves',0,'token',C.token,'lp2a3SourceSHA256',C.lp2a3SourceSHA256,'policySHA256',C.policySHA256, ...
 'passed',nnz(cellfun(@(r)r.pass,R)),'total',numel(R),'tests',{R},'realGit',RG,'closureRegression',RJ,'fixturesRemoved',rm);
fprintf('LP2A3_TESTS %d/%d\n',T.passed,T.total);
end

% =====================================================================
function r=t(name,ok),r=struct('name',name,'pass',logical(ok));fprintf('LP2A3_TEST %-46s %d\n',name,ok);end
function v=bump(m,v),m('n')=m('n')+1;end
function ok=refuses(f,id)
try,f();ok=false;catch ME,ok=strcmp(ME.identifier,id);if ~ok,fprintf('   (got %s: %s)\n',ME.identifier,ME.message);end,end
end
function run=newRun(fx,name,C)
run=struct('rd',fullfile(fx,name),'lroot',fullfile(fx,[name '_ledger']),'cid','FIX-LP2A3');mkdir(run.rd);
g2_lp1_campaign_ledger('write',run.lroot,'RECEIPT','RECEIPT.mat',struct('campaignId',run.cid,'runName','run_fixture','goSHA256',repmat('0',1,64),'token',C.token,'sourceCommit','fixture','openedUTC','fixture'));
end
function V=verifierFor(run,C,Par,reqT)
pol=C.policy;ids={pol.cases.id};V=struct('rd',run.rd,'lroot',run.lroot,'ids',{ids},'masks',reshape([pol.cases.mask],3,[]).','parents',struct(),'pol',pol, ...
 'token',C.token,'policySHA256',C.policySHA256,'g2SourceSHA256',C.g2SourceSHA256,'lp2a2SourceSHA256',C.lp2a2SourceSHA256,'lp2a3SourceSHA256',C.lp2a3SourceSHA256,'requireTerminal',reqT);
for i=1:numel(ids),V.parents.(ids{i})=struct('state',Par.(ids{i}).state,'stateSHA256',Par.(ids{i}).stateSHA256);end
end
function [O,env]=chainCase(run,id,Par,C,ops,failId)
pol=C.policy;c=pol.cases(strcmp({pol.cases.id},id));chain=fullfile(run.rd,id);if ~isfolder(chain),mkdir(chain);end
Camp=struct('mode','OPEN_NEW');
env=struct('caseId',id,'mask',reshape(c.mask,1,3),'ids',{{pol.cases.id}},'rd',run.rd,'chain',chain,'lroot',run.lroot,'campMode',Camp.mode,'campaignId',run.cid, ...
 'runName','run_fixture','token',C.token,'pol',pol,'parent',Par.(id).state,'parentHash',Par.(id).stateSHA256,'geom',Par.(id).geom, ...
 'verifyAll',@()g2_lp2a3_verify(verifierFor(run,C,Par,true)));
admitErr='';if isfield(ops,'admitError'),admitErr=ops.admitError;ops=rmfield(ops,'admitError');end
ops.admit=@(sd,k)admitFix(sd,k,run,Camp,id,pol,admitErr);
ops.computeState=@(sd,k,F,parent,ph)fixState(sd,k,F,parent,ph,C,c,env.geom,failId);
O=g2_lp2a3_chain(env,ops);
end
function admitFix(sd,k,run,Camp,id,pol,err)
if ~isempty(err),error(err,'injected pre-admission failure');end
g2_lp1_admit_state(sd,99,@()g2_lp2a3_admit_hook(run.lroot,Camp,run.cid,id,k,pol));
end
function [St,sth,geom]=fixState(sd,k,F,parent,parentHash,C,c,geom,failId)
% Synthetic, non-physical records with the exact LP2-A3 schema and links (no mesh, no solve).
if ~isempty(failId),error(failId,'injected failure at S%d',k);end
mf=fullfile(sd,'MESH.mat');fixture=sprintf('LP2A3 inert fixture S%d',k);save(mf,'fixture','-v7');mh=lower(g2_sha256_file(mf));
ph=lower(g2_trajectory_record('write',fullfile(sd,'PHASE.mat'),struct('schema','NewMetacomp.G2.LP2A3.Phase.v1','stateIndex',k,'caseId',c.id,'mask',reshape(c.mask,1,3),'meshSHA256',mh)));
K=struct('KI',parent.KI*1.01,'KII',parent.KII*0.9);
sh=lower(g2_trajectory_record('write',fullfile(sd,'SOLUTION.mat'),struct('schema','NewMetacomp.G2.LP2A3.Solution.v1','stateIndex',k,'caseId',c.id,'meshSHA256',mh,'phaseSHA256',ph,'K',K)));
St=struct('schema','NewMetacomp.G2.LP2A3.State.v1','stateIndex',k,'caseId',c.id,'mask',reshape(c.mask,1,3),'token',C.token,'policySHA256',C.policySHA256, ...
 'g2SourceSHA256',C.g2SourceSHA256,'lp2a2SourceSHA256',C.lp2a2SourceSHA256,'lp2a3SourceSHA256',C.lp2a3SourceSHA256,'parentSHA256',parentHash, ...
 'polyline_mm',F.polyline_mm,'tangent',F.tangent,'tip_mm',F.polyline_mm(end,:),'KI',K.KI,'KII',K.KII,'meshSHA256',mh,'phaseSHA256',ph,'solutionSHA256',sh, ...
 'seedRung',1,'seedSpacing_mm',0.45,'clearanceGeometry',geom,'numericalStatus','FIXTURE_NOT_PHYSICAL');
sth=lower(g2_trajectory_record('write',fullfile(sd,'STATE.mat'),St));
end
function T=guardStop(Rr,m,p,tip,cnt,nStop)
% Real classification wrapper; at the nStop-th candidate the tip is moved radially to a 0.5 mm gap
% to ring 1 (below the 1-mm guard). Fixture only.
cnt('n')=cnt('n')+1;
if cnt('n')==nStop
 c=p.geometry.centres_mm(1,:);u=(tip-c)/norm(tip-c);tip=c+u*(p.ringProximityGuard.ringR_mm+p.ringProximityGuard.guideRadius_mm+0.5);
end
T=g2_lp2a3_classify(Rr,m,p,tip);
end
function Tm=readT(run,id),[Tm,~,~]=g2_trajectory_record('read',fullfile(run.rd,id,'TERMINAL.mat'));end
function H=treeHash(root)
d=dir(fullfile(root,'**','*'));d=d(~[d.isdir]);H=cell(numel(d),2);
for k=1:numel(d),p=fullfile(d(k).folder,d(k).name);H{k,1}=p;H{k,2}=lower(g2_sha256_file(p));end
H=sortrows(H,1);
end
function [R,Rec]=realGit(pol)
% Real git through MATLAB system() (cmd.exe on Windows) on disposable inert fixtures outside the repository.
R={};fx=fullfile(tempdir,sprintf('lp2a3_git_%s',datestr(now,'yyyymmddHHMMSSFFF')));fr=[fx '_root'];fn=[fx '_notrepo'];
[~,gv]=system('git --version');goF=pol.authorization.goPath;
Rec=struct('matlab',version,'comSpec',getenv('ComSpec'),'git',strtrim(gv),'cases',struct([]));
try
 mkdir(fx);sh(sprintf('git init -q "%s"',fx));sh(sprintf('git -C "%s" config core.autocrlf false',fx));
 wf(fx,'README_FIXTURE.txt','Inert LP2-A3 git fixture; not an authorization; no token.');c0=commit(fx);
 wf(fx,'evidence.txt','inert');c1=commit(fx);
 sh(sprintf('git -C "%s" checkout -q -b valid %s',fx,c1));wf(fx,goF,'{"fixture":"INERT_NOT_AN_AUTHORIZATION"}');cA=commit(fx);
 sh(sprintf('git -C "%s" checkout -q -b extra %s',fx,c1));wf(fx,goF,'{"fixture":"INERT"}');wf(fx,'extra.txt','x');cX=commit(fx);
 mkdir(fr);sh(sprintf('git init -q "%s"',fr));wf(fr,'a.txt','root');cR=commit(fr);mkdir(fn);
 Rec.commits=struct('c0',c0,'c1',c1,'cA',cA,'cX',cX,'cR',cR);
 tokF='FIXTURE-INERT-TOKEN';Cf=struct('repo',fx,'policy',pol,'token',tokF);
 evF=struct('exists',true,'sha256',repmat('b',1,64),'text',jsonencode(struct('passed',60,'total',60,'physicalSolves',0,'token',tokF)));
 G=struct('decision','GO_LP2A3_PHYSICAL','decisionUrl','https://github.com/mfs9697/NewMetacomp/pull/75#issuecomment-1','approvedHead',c1,'token',tokF, ...
  'campaignId',pol.authorization.campaignId,'campaignScope',pol.authorization.campaignScope,'runName',pol.authorization.runName,'cases',{{'H','stiff13','soft2','soft1'}}, ...
  'maxStateIndex',11,'maxAdmissions',12,'seedSpacing_mm',0.45,'contractEvidenceFile',[pol.authorization.contractEvidenceDir 'x.json'],'contractEvidenceSHA256',repmat('b',1,64));
 K={'valid','valid',c1,fx,true,true;'wrong_parent','valid',c0,fx,false,false;'extra_file','extra',c1,fx,false,false;'root_commit','',c1,fr,false,false;'not_a_repo','',c1,fn,false,false};
 for k=1:size(K,1)
  [nm,br,ah,rp,expV,expP]=K{k,:};if ~isempty(br),sh(sprintf('git -C "%s" checkout -q %s',rp,br));end
  Gk=G;Gk.approvedHead=ah;Ck=Cf;Ck.repo=rp;Vk=g2_lp2a3_go_validate(Gk,Ck,tokF,[],@(p)evF);
  Pk=g2_lp2a3_external_run(ah,'','','ParentCheckOnly',true,'Repo',rp);Hp=g2_lp2a2_git('parent',rp);
  R{end+1}=t(['I_' nm],Vk.pass==expV&&Pk.pass==expP); %#ok<AGROW>
  c=struct('case',nm,'approvedHead',ah,'parentStatus',Hp.status,'parentValue',Hp.value,'command',strrep(Hp.command,rp,'<fixture>'),'validatorPass',Vk.pass,'failed',{Vk.failed},'externalPass',Pk.pass);
  if isempty(Rec.cases),Rec.cases=c;else,Rec.cases(end+1)=c;end
 end
 sh(sprintf('git -C "%s" checkout -q valid',fx));[s1,o1]=system(sprintf('git -C "%s" rev-parse HEAD^',fx));
 if ispc,R{end+1}=t('I_caret_defect_still_reproduced',s1==0&&strcmp(strtrim(o1),cA));end
catch ME
 fprintf('LP2A3 I ERROR %s: %s\n',ME.identifier,ME.message);R{end+1}=t('I_fixture_error',false);
end
for d={fx,fr,fn},if isfolder(d{1}),[~,~]=system(sprintf('attrib -R "%s\\*" /S /D',d{1}));try,rmdir(d{1},'s');catch,end,end,end
end
function sh(cmd),[st,o]=system(cmd);assert(st==0,'LP2A3T:SETUP','fixture setup failed (%d): %s',st,o);end
function wf(root,rel,txt),p=fullfile(root,rel);d=fileparts(p);if ~isfolder(d),mkdir(d);end;fid=fopen(p,'w');fwrite(fid,txt,'char');fclose(fid);end
function c=commit(root)
sh(sprintf('git -C "%s" add -A',root));sh(sprintf('git -C "%s" -c user.name=lp2a3-fixture -c user.email=fixture@example.invalid -c commit.gpgsign=false commit -q -m fixture',root));
[st,o]=system(sprintf('git -C "%s" rev-parse --verify HEAD',root));c=strtrim(o);assert(st==0&&~isempty(regexp(c,'^[0-9a-f]{40}$','once')),'LP2A3T:SETUP','commit hash');
end
