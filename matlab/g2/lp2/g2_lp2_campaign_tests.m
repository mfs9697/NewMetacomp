function rows=g2_lp2_campaign_tests(C)
%G2_LP2_CAMPAIGN_TESTS  Non-solving tests of LP2-A terminal handling, closure and verification.
% Runs the REAL g2_lp2_chain control logic, g2_lp2_verify, ledger, admission and forecast in fresh
% tempname folders, with injected stubs for clearance/classification and for computeState (which
% writes synthetic MESH/PHASE/SOLUTION/STATE records with the production link fields). No mesh,
% no FEM. Parents are the pinned A0 S4 records, read only. Returns test rows.
rows=struct('name',{},'kind',{},'expected',{},'observed',{},'pass',{});
pol=C.policy;ids={pol.cases.id};masks=reshape([pol.cases.mask],3,[]).';
A0=fullfile(C.repo,strrep(pol.parents.run,'/',filesep));par=struct();
for i=1:4
 f=fullfile(A0,ids{i},'S4','STATE.mat');[St,~,~]=g2_trajectory_record('read',f);
 par.(ids{i})=struct('state',St,'stateSHA256',lower(g2_sha256_file(f)));
end
TOK='G2LP2A|campaign-test';cnt=containers.Map('KeyType','char','ValueType','double');
% ================================================================= 1 complete campaign + 6 closure without computation
E=setup();for i=1:4,O{i}=run(E,i,struct());end %#ok<AGROW>
ok('c1_all_four_cases_complete_and_closed','campaign',@()all(cellfun(@(o)strcmp(o.terminal,'CAMPAIGN_LIMIT_REACHED')&&o.lastState==8,O))&& ...
 O{4}.campaignClosed&&isfile(fullfile(E.lroot,'CLOSED.mat'))&&nAdmits(E)==16&&cnt(E.key)==16);
Rv=ver(E,true);ok('c1_verifier_passes_complete_campaign','verify',@()Rv.pass);
L0=listing(E.root);
for i=1:4,Ov{i}=run(E,i,struct('mode','VERIFY_ONLY'));end %#ok<AGROW>
ok('c6_verify_only_reuses_without_computation','campaign',@()cnt(E.key)==16&&isequal(L0,listing(E.root))&& ...
 all(cellfun(@(o)o.computed==0&&o.reused==4&&strcmp(o.terminal,'CAMPAIGN_LIMIT_REACHED'),Ov)));
O2=run(E,1,struct());ok('c5_rerun_of_completed_case_admits_nothing','campaign',@()O2.computed==0&&nAdmits(E)==16&&isequal(L0,listing(E.root)));
ex('c5_admission_refused_in_full_campaign','campaign',@()g2_lp2_admit_hook(E.lroot,struct('mode','CONTINUE'),'FIX','H',6),'G2LP2:HOLD_UNAUTHORIZED_STATE','sixteen-solve ceiling');
Ed=setup();run(Ed,1,struct());
ex('c5_duplicate_admission_refused','campaign',@()g2_lp2_admit_hook(Ed.lroot,struct('mode','CONTINUE'),'FIX','H',6),'G2LP1:HOLD_CAMPAIGN_INTEGRITY','already admitted');
% ================================================================= 2 local HOLD in an earlier case, 7 prefix preserved
E=setup();for i=1:4,O{i}=run(E,i,struct('failAt',{{'stiff13',6,'G2LP2:HOLD_MESH_QUALITY'}}));end
T2=readTerm(E,'stiff13');sd6=fullfile(E.rd,'stiff13','S6');
ok('c2_local_hold_earlier_case_terminal','campaign',@()strcmp(T2.classification,'NUMERICAL_HOLD')&&T2.lastAcceptedState==5&& ...
 strcmp(T2.failure.identifier,'G2LP2:HOLD_MESH_QUALITY')&&isfile(fullfile(sd6,'HOLD.mat'))&&isfile(fullfile(sd6,'FAILED_MESH_STUB.mat'))&&~isfile(fullfile(sd6,'STATE.mat')));
ok('c2_other_cases_continue_and_campaign_closes','campaign',@()strcmp(O{1}.terminal,'CAMPAIGN_LIMIT_REACHED')&&strcmp(O{4}.terminal,'CAMPAIGN_LIMIT_REACHED')&& ...
 O{4}.campaignClosed&&nAdmits(E)==14&&ver(E,true).pass);
h5=lower(g2_sha256_file(fullfile(E.rd,'stiff13','S5','STATE.mat')));n0=cnt(E.key);L1=listing(E.root);
O3=run(E,2,struct());
ok('c7_failed_state_never_retried_prefix_preserved','campaign',@()cnt(E.key)==n0&&O3.computed==0&&isequal(L1,listing(E.root))&& ...
 strcmp(h5,lower(g2_sha256_file(fullfile(E.rd,'stiff13','S5','STATE.mat'))))&&strcmp(O3.terminal,'NUMERICAL_HOLD'));
% ================================================================= 3 local HOLD in the final case closes in the same call
E=setup();for i=1:3,run(E,i,struct());end
O4=run(E,4,struct('failAt',{{'soft1',7,'G2LP2:HOLD_K_EXTRACTION'}}));
ok('c3_local_hold_final_case_closes_campaign','campaign',@()strcmp(O4.terminal,'NUMERICAL_HOLD')&&O4.lastState==6&&O4.campaignClosed&& ...
 isfile(fullfile(E.lroot,'CLOSED.mat'))&&strcmp(O4.status,'TERMINAL_NUMERICAL_HOLD')&&isfield(O4,'terminalRecord')&&ver(E,true).pass);
% ================================================================= candidate terminal and forecast exceptions
E=setup();O5=run(E,1,struct('approachAt',7));T5=readTerm(E,'H');
ok('candidate_non_advance_terminal_without_admission','campaign',@()strcmp(T5.classification,'INTERFACE_APPROACH')&&T5.lastAcceptedState==6&& ...
 ~isfolder(fullfile(E.rd,'H','S7'))&&nAdmits(E)==2&&strcmp(O5.status,'TERMINAL_INTERFACE_APPROACH'));
O6=run(E,2,struct('forecastFailAt',6,'forecastId','G2LP2:HOLD_K_EXTRACTION'));T6=readTerm(E,'stiff13');
ok('forecast_local_exception_is_documented_terminal','campaign',@()strcmp(T6.classification,'NUMERICAL_HOLD')&&T6.lastAcceptedState==5&& ...
 strcmp(T6.failure.stage,'forecast/clearance/classification')&&~isfolder(fullfile(E.rd,'stiff13','S6')));
O7=run(E,3,struct('forecastFailAt',5,'forecastId','MATLAB:unexpected'));
ok('forecast_unexpected_exception_is_global','campaign',@()strcmp(O7.status,'GLOBAL_HOLD')&&~isfile(fullfile(E.rd,'soft2','TERMINAL.mat'))&&nHolds(E)==1);
% ================================================================= 4 global HOLDs
E=setup();O8=run(E,1,struct('ram',4.0));
ok('c4_preadmission_memory_hold_global','campaign',@()strcmp(O8.status,'GLOBAL_HOLD')&&~isfolder(fullfile(E.rd,'H','S5'))&& ...
 ~isfile(fullfile(E.rd,'H','TERMINAL.mat'))&&nHolds(E)==1&&nAdmits(E)==0);
ex('c4_campaign_blocked_after_global_hold','campaign',@()g2_lp1_campaign_validate(struct('approvedRunName','run_test','campaignId','FIX','campaignScope','x'), ...
 'run_test','gosha',TOK,g2_lp1_campaign_ledger('snapshot',E.lroot),struct('exists',true,'hasRunRecord',false,'runTokenMatches',false),[]), ...
 'G2LP1:HOLD_CAMPAIGN_REVIEW_REQUIRED','scientist review');
E=setup();run(E,1,struct());O9=run(E,2,struct('failAt',{{'stiff13',6,'G2LP2:HOLD_RECORD_INTEGRITY'}}));
for i=3:4,run(E,i,struct());end
ok('c4_global_hold_after_admission_no_terminal_no_closure','campaign',@()strcmp(O9.status,'GLOBAL_HOLD')&&isfile(fullfile(E.rd,'stiff13','S6','HOLD.mat'))&& ...
 ~isfile(fullfile(E.rd,'stiff13','TERMINAL.mat'))&&~isfile(fullfile(E.lroot,'CLOSED.mat'))&&nHolds(E)>=1);
ok('failure_class_table','campaign',@()strcmp(g2_lp2_failure_class('G2LP2:HOLD_MESH_QUALITY',true),'LOCAL')&& ...
 strcmp(g2_lp2_failure_class('G2LP1:HOLD_MEMORY',false),'PREADMISSION_MEMORY')&&strcmp(g2_lp2_failure_class('G2LP1:HOLD_MEMORY',true),'GLOBAL')&& ...
 strcmp(g2_lp2_failure_class('G2LP1:HOLD_CAMPAIGN_INTEGRITY',false),'CAMPAIGN_REFUSAL')&&strcmp(g2_lp2_failure_class('G2LP2:HOLD_SOURCE',true),'GLOBAL')&& ...
 strcmp(g2_lp2_failure_class('MATLAB:unexpected',false),'GLOBAL'));
% ================================================================= C2 verifier negatives (each on a fresh complete campaign)
neg('v_altered_mesh_hash',@(E)appendByte(fullfile(E.rd,'H','S6','MESH.mat')),'H S6: MESH hash');
neg('v_state_manifest_tamper',@(E)appendByte(fullfile(E.rd,'H','S5','STATE.mat')),'H S5: STATE manifest fails');
neg('v_incorrect_parent_link',@(E)rewrite(fullfile(E.rd,'stiff13','S7','STATE.mat'),'parentSHA256',repmat('0',1,64)),'stiff13 S7: parent SHA-256 link');
neg('v_inconsistent_sif',@(E)rewrite(fullfile(E.rd,'soft2','S5','STATE.mat'),'KI',[]),'soft2 S5: signed K_I/K_II differ');
neg('v_missing_phase_record',@(E)delrec(fullfile(E.rd,'soft1','S6','PHASE.mat')),'soft1 S6: PHASE hash or links');
neg('v_missing_solution_record',@(E)delrec(fullfile(E.rd,'H','S8','SOLUTION.mat')),'H S8: SOLUTION hash or links');
neg('v_terminal_wrong_last_state',@(E)rewrite(fullfile(E.rd,'H','TERMINAL.mat'),'lastAcceptedState',7),'H: terminal does not bind');
neg('v_closed_binding_broken',@(E)rewrite(fullfile(E.rd,'soft2','TERMINAL.mat'),'note','altered'),'CLOSED does not bind');
neg('v_extra_admission',@(E)g2_lp1_campaign_ledger('write',E.lroot,'ADMIT','ADMIT_H_S9.mat',struct('campaignId','FIX','stateKey','H_S9','caseId','H','stateIndex',9)),'ADMIT entries');
neg('v_missing_terminal',@(E)delrec(fullfile(E.rd,'soft1','TERMINAL.mat')),'soft1: TERMINAL record missing');
neg('v_state_gap',@(E)rmdir(fullfile(E.rd,'stiff13','S6'),'s'),'not contiguous');

 % ---------------------------------------------------------------- fixtures
 function E=setup()
  root=tempname;mkdir(root);E=struct('root',root,'rd',fullfile(root,'run','run_test'),'lroot',fullfile(root,'ledger','FIX'),'key',root);
  mkdir(E.rd);cnt(E.key)=0;
  g2_lp1_campaign_ledger('write',E.lroot,'RECEIPT','RECEIPT.mat',struct('campaignId','FIX','runName','run_test','goSHA256','gosha','token',TOK));
 end
 function O=run(E,i,opt)
  id=ids{i};mask=masks(i,:);mode='CONTINUE';if isfield(opt,'mode'),mode=opt.mode;end
  ram=99;if isfield(opt,'ram'),ram=opt.ram;end
  Camp=struct('mode',mode);
  env=struct('caseId',id,'mask',mask,'ids',{ids},'rd',E.rd,'chain',fullfile(E.rd,id),'lroot',E.lroot,'campMode',mode,'campaignId','FIX', ...
   'runName','run_test','token',TOK,'pol',pol,'parent',par.(id).state,'parentHash',par.(id).stateSHA256,'geom',[], ...
   'verifyAll',@()ver(E,true));
  if ~isfolder(env.chain),mkdir(env.chain);end
  ops=struct('forecast',@(p,q)fc(p,q,opt),'clearance',@(P,nx,g,q)struct('pass',true,'status','MATRIX_ADVANCE','reasons',{{}},'metrics',struct('k',size(P,1)-1)), ...
   'classify',@(R,m,q)cls(R,opt),'admit',@(sd,k)g2_lp1_admit_state(sd,ram,@()g2_lp2_admit_hook(E.lroot,Camp,'FIX',id,k)), ...
   'computeState',@(sd,k,F,p,ph)stubState(E,id,mask,sd,k,F,p,ph,opt));
  O=g2_lp2_chain(env,ops);
 end
 function F=fc(p,q,opt)
  k=p.stateIndex+1;
  if isfield(opt,'forecastFailAt')&&k==opt.forecastFailAt,error(opt.forecastId,'Synthetic forecast failure at S%d.',k);end
  F=g2_lp2_forecast(p,q);
 end
 function T=cls(R,opt)
  T=struct('classification','MATRIX_ADVANCE','constraints',struct('object',{},'type',{},'guard',{},'margin_mm',{}), ...
   'activeInterfaceClearance_mm',NaN,'passiveContourClearance_mm',NaN);
  if isfield(opt,'approachAt')&&R.metrics.k==opt.approachAt
   T.classification='INTERFACE_APPROACH';T.constraints=struct('object','ring1','type','PHYSICAL_INTERFACE','guard','tipGuideRadius','margin_mm',-0.1);
  end
 end
 function [St,sth,g]=stubState(E,id,mask,sd,k,F,p,ph,opt)
  cnt(E.key)=cnt(E.key)+1;g=[];
  if isfield(opt,'failAt')&&strcmp(opt.failAt{1},id)&&opt.failAt{2}==k
   x=1;save(fullfile(sd,'FAILED_MESH_STUB.mat'),'x');error(opt.failAt{3},'Synthetic failure %s S%d.',id,k);
  end
  x=k;save(fullfile(sd,'MESH.mat'),'x');mh=lower(g2_sha256_file(fullfile(sd,'MESH.mat')));
  phs=lower(g2_trajectory_record('write',fullfile(sd,'PHASE.mat'),struct('schema','NewMetacomp.G2.LP2A.Phase.v1','stateIndex',k,'caseId',id,'mask',mask,'meshSHA256',mh)));
  K=struct('KI',p.KI,'KII',p.KII);
  sos=lower(g2_trajectory_record('write',fullfile(sd,'SOLUTION.mat'),struct('schema','NewMetacomp.G2.LP2A.Solution.v1','stateIndex',k,'caseId',id, ...
   'meshSHA256',mh,'phaseSHA256',phs,'K',K)));
  St=struct('schema','NewMetacomp.G2.LP2A.State.v1','stateIndex',k,'caseId',id,'mask',mask,'policySHA256','p','g2SourceSHA256','g','lp2SourceSHA256','l', ...
   'token',TOK,'parentSHA256',ph,'polyline_mm',F.polyline_mm,'tangent',F.tangent,'tip_mm',F.polyline_mm(end,:),'arc_mm',F.arc_mm, ...
   'KI',K.KI,'KII',K.KII,'G',p.G,'MTS_deg',p.MTS_deg,'meshSHA256',mh,'phaseSHA256',phs,'solutionSHA256',sos,'clearanceGeometry',[]);
  sth=lower(g2_trajectory_record('write',fullfile(sd,'STATE.mat'),St));
 end
 function R=ver(E,req)
  V=struct('rd',E.rd,'lroot',E.lroot,'ids',{ids},'masks',masks,'parents',par,'pol',pol,'token',TOK,'policySHA256','p', ...
   'g2SourceSHA256','g','lp2SourceSHA256','l','requireTerminal',req);
  R=g2_lp2_verify(V);
 end
 function T=readTerm(E,id),[T,~,~]=g2_trajectory_record('read',fullfile(E.rd,id,'TERMINAL.mat'));end
 function n=nAdmits(E),L=g2_lp1_campaign_ledger('snapshot',E.lroot);n=numel(L.admits);end
 function n=nHolds(E),L=g2_lp1_campaign_ledger('snapshot',E.lroot);n=numel(L.holds);end
 function neg(name,mut,frag)
  E=setup();for j=1:4,run(E,j,struct());end
  try,mut(E);R=ver(E,true);v=~R.pass&&any(contains(R.problems,frag));o=strjoin(R.problems,' | ');
  catch ME,v=false;o=['error ' ME.identifier ': ' ME.message];end
  rows(end+1)=struct('name',name,'kind','verify','expected','error','observed',o(1:min(end,400)),'pass',v);
 end
 function ok(name,kind,f)
  try,v=isequal(f(),true);o=mat2str(v);catch ME,v=false;o=['error ' ME.identifier ': ' ME.message];end
  rows(end+1)=struct('name',name,'kind',kind,'expected','true','observed',o,'pass',v);
 end
 function ex(name,kind,f,id,frag)
  try,f();o='no error';v=false;catch ME,o=[ME.identifier ': ' ME.message];v=strcmp(ME.identifier,id)&&contains(ME.message,frag);end
  rows(end+1)=struct('name',name,'kind',kind,'expected','error','observed',o,'pass',v);
 end
end

function L=listing(root)
d=dir(fullfile(root,'**','*'));d=d(~[d.isdir]);L=sort(strcat({d.folder},filesep,{d.name}))';
H=cellfun(@(f)lower(g2_sha256_file(f)),L,'UniformOutput',false);L=[L,H];
end
function appendByte(f)
fid=fopen(f,'a');fwrite(fid,uint8(0));fclose(fid);
end
function delrec(f)
delete(f);if isfile([f '.manifest.json']),delete([f '.manifest.json']);end
end
function rewrite(f,field,val)
[r,~,~]=g2_trajectory_record('read',f);
if isempty(val)&&strcmp(field,'KI'),val=r.KI*(1+1e-9);end
r.(field)=val;delrec(f);g2_trajectory_record('write',f,r);
end
