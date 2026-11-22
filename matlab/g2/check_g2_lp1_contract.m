function T=check_g2_lp1_contract(assertPass)
% check_g2_lp1_contract()      asserts that every test passes (batch use).
% check_g2_lp1_contract(false) returns the table without asserting; used only by the
%                              sensitivity check, which must observe the failing rows.
if nargin<1,assertPass=true;end
% Pure forecast/link/GO/admission controls + isolated immutable-record I/O. No mesh/FEM.
% VG1 (Issue #58): every negative now requires its exact MATLAB exception identifier
% AND the message fragment of the intended branch; any other error, or no error,
% is a FAIL. GO branches are exercised on in-memory synthetic fixtures through the
% pure validator g2_lp1_go_validate; no GO file is ever written, and the production
% gate is exercised only for the absent-GO case, on an empty temporary folder.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
pol=jsondecode(fileread(fullfile(here,'G2_LP1_POLICY_v2.json')));
c=pol.cases(1);P=pol.startPolyline_mm;tn=[0 1];
RI='G2LP1:HOLD_RECORD_INTEGRITY';SRC='G2LP1:HOLD_SOURCE';UN='G2LP1:HOLD_UNAUTHORIZED_STATE';
KX='G2LP1:HOLD_K_EXTRACTION';MEM='G2LP1:HOLD_MEMORY';
rows=struct('name',{},'kind',{},'expected',{},'observed',{},'pass',{});

% ---------------------------------------------------------------- record links
K=struct('pass',true,'criteria',struct('test',true),'KI',1,'KII',.1,'EDI_all',[1 .1 0], ...
 'KI_MPa_sqrt_m_per_kN',sqrt(1000),'KII_MPa_sqrt_m_per_kN',.1*sqrt(1000));
R=struct('schema','NewMetacomp.G2.LP1.Test.v1','stateIndex',0,'caseId','H','mask',[0 0 0],'ratio',1, ...
 'policySHA256','policy','sourceSHA256','source','parentSHA256','parent','polyline_mm',P,'tangent',tn,'arc_mm',25.4, ...
 'KI',1,'KII',.1,'EDI_all',[1 .1 0],'meshSHA256','mesh','phaseSHA256','phase');
S=struct('K',K,'caseId','H','meshSHA256','mesh','phaseSHA256','phase','policySHA256','policy','sourceSHA256','source');
verify=@(r,s)g2_lp1_validate_links(r,s,c,0,P,tn,'policy','source','parent');
ok('positive_links','positive',@()linksOK(verify,R,S));
mIdx='Case, mask, ratio or index changed.';mSrc='Parent/source/policy link differs.';
mGeo='Saved geometry differs';mK='Signed K or solution';mU='Unit conversion changed.';
spec={'KI',2,mK;'KII',-.1,mK;'caseId','soft1',mIdx;'mask',[1 0 0],mIdx;'ratio',.5,mIdx;'stateIndex',5,mIdx; ...
 'policySHA256','bad',mSrc;'sourceSHA256','bad',mSrc;'parentSHA256','bad',mSrc;'polyline_mm',P+.1,mGeo; ...
 'meshSHA256','bad',mK;'phaseSHA256','bad',mK};
for k=1:size(spec,1)
 r=R;r.(spec{k,1})=spec{k,2};id=RI;if strcmp(spec{k,3},mSrc),id=SRC;end
 expect(['mutate_',spec{k,1}],'negative',@()verify(r,S),id,spec{k,3});
end
s=S;s.K.KI_MPa_sqrt_m_per_kN=1;expect('wrong_units','negative',@()verify(R,s),RI,mU);
s=S;s.K.criteria.test=false;expect('forged_pass_flag','negative',@()verify(R,s),RI,mK);
s=S;s.caseId='soft1';expect('solution_case_link','negative',@()verify(R,s),RI,mK);
s=S;s.sourceSHA256='drifted';expect('solution_source_drift','negative',@()verify(R,s),RI,mK);

% ---------------------------------------------------------------- forecast / caps
parent=R;f=g2_lp1_forecast(parent,pol);
ok('own_signed_MTS','positive',@()f.stateIndex==1&&abs(f.arc_mm-29.4)<1e-12);
parent.KII=-parent.KII;f2=g2_lp1_forecast(parent,pol);
ok('signed_KII_changes_path','positive',@()f2.polyline_mm(end,1)~=f.polyline_mm(end,1));
parent=R;parent.stateIndex=4;expect('S5_forecast','negative',@()g2_lp1_forecast(parent,pol),UN,'S5 and later');
expect('S5_controller','negative',@()g2_lp1_run('MaxStateIndex',5),UN,'Only S0-S4');
expect('negative_state_controller','negative',@()g2_lp1_run('MaxStateIndex',-1),UN,'Only S0-S4');
expect('fractional_state_controller','negative',@()g2_lp1_run('MaxStateIndex',2.5),UN,'Only S0-S4');
parent=R;parent.KI=-1;expect('compressive_parent','negative',@()g2_lp1_forecast(parent,pol),KX,'Invalid tensile MTS root');
parent=R;parent.KII=NaN;expect('nonfinite_parent','negative',@()g2_lp1_forecast(parent,pol),KX,'Invalid tensile MTS root');
parent=R;parent.KI=0;parent.KII=0;expect('zero_K_parent','negative',@()g2_lp1_forecast(parent,pol),KX,'Invalid tensile MTS root');

% ---------------------------------------------------------------- authorization interface
expect('controller_rejects_go_path_argument','negative',@()g2_lp1_run('GoFile','x.json'), ...
 'MATLAB:InputParser:UnmatchedParameter','');
ok('gate_takes_context_only','interface',@()nargin('g2_lp1_scientific_gate')==1);
gs=fileread(fullfile(here,'g2_lp1_scientific_gate.m'));
ok('gate_go_path_hardcoded','interface',@()contains(gs,'p=fullfile(C.here,''G2_LP1_SCIENTIFIC_GO_v1.json'');')&& ...
 contains(gs,'g2_lp1_go_validate(G,C,@(f)repositoryContract(C.repo,f))'));
rs=fileread(fullfile(here,'g2_lp1_run.m'));
ok('controller_calls_gate_before_run_folder','interface',@()gateBeforeMkdir(rs));
ok('validator_opens_no_file','interface',@()~any(contains(fileread(fullfile(here,'g2_lp1_go_validate.m')), ...
 {'fileread(','fopen(','load(','isfile(','dir('})));

% ---------------------------------------------------------------- GO: absent (production gate)
folder=fullfile(repo,'outputs',['g2_lp1_contract_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);
assert(~isfolder(folder),'G2LP1:HOLD_TEST','Contract test folder exists.');mkdir(folder);
empty=fullfile(folder,'empty_go_folder');mkdir(empty);
Cabs=struct('here',empty,'repo',repo,'policySHA256','x','sourceSHA256','x','token','x', ...
 'policy',struct('lp0Evidence',struct('sha256','x')));
expect('go_absent_production_gate','go',@()g2_lp1_scientific_gate(Cabs),UN,'no separate GO record');
ok('go_absent_left_no_file','go',@()numel(dir(empty))==2);

% ---------------------------------------------------------------- GO: present but invalid (pure validator)
Cs=struct('policySHA256',repmat('a',1,64),'sourceSHA256',repmat('b',1,64), ...
 'token','G2LP1|SYNTHETIC_TEST_TOKEN|NOT_A_RUNTIME_TOKEN', ...
 'policy',struct('lp0Evidence',struct('sha256',repmat('c',1,64))));
Tc=struct('pass',true,'passed',30,'total',30,'physicalSolves',0,'meshBuilds',0, ...
 'negativeTestsPassed',true,'recordIntegrityPassed',true);
[G0,L0]=fixture(Tc);
ok('go_fixture_positive_control','go',@()isequal(g2_lp1_go_validate(G0,Cs,L0),G0));
mInc='Incomplete scientific GO record';mRev='absent or invalid';mBind='does not bind';
mPath='not pinned';mBytes='absent or changed';mLack='lacks negative';mNot='has not passed';
expect('go_not_struct','go',@()g2_lp1_go_validate('GO',Cs,L0),UN,mInc);
expect('go_missing_field','go',@()g2_lp1_go_validate(rmfield(G0,'approvedToken'),Cs,L0),UN,mInc);
g=G0;g.decision='HOLD';expect('go_wrong_decision','go',@()g2_lp1_go_validate(g,Cs,L0),UN,mRev);
g=G0;g.reviewStatus='PENDING';expect('go_wrong_review_status','go',@()g2_lp1_go_validate(g,Cs,L0),UN,mRev);
g=G0;g.scientificReviewer='  ';expect('go_empty_reviewer','go',@()g2_lp1_go_validate(g,Cs,L0),UN,mRev);
g=G0;g.reviewURL='https://example.org/review';expect('go_foreign_review_url','go',@()g2_lp1_go_validate(g,Cs,L0),UN,mRev);
g=G0;g.approvedPolicySHA256=repmat('d',1,64);expect('go_policy_mismatch','go',@()g2_lp1_go_validate(g,Cs,L0),SRC,mBind);
g=G0;g.approvedSourceSHA256=repmat('d',1,64);expect('go_source_mismatch','go',@()g2_lp1_go_validate(g,Cs,L0),SRC,mBind);
g=G0;g.approvedLP0SHA256=repmat('d',1,64);expect('go_lp0_mismatch','go',@()g2_lp1_go_validate(g,Cs,L0),SRC,mBind);
g=G0;g.approvedToken=[Cs.token,'|maxState=5'];expect('go_token_mismatch','go',@()g2_lp1_go_validate(g,Cs,L0),SRC,mBind);
g=G0;g.contractEvidenceFile='matlab/g2/G2_LP1_POLICY_v2.json';expect('go_contract_path_outside','go',@()g2_lp1_go_validate(g,Cs,L0),SRC,mPath);
g=G0;g.contractEvidenceFile='matlab/g2/evidence/lp1_preflight/../x.json';expect('go_contract_path_traversal','go',@()g2_lp1_go_validate(g,Cs,L0),SRC,mPath);
g=G0;g.contractEvidenceFile='matlab/g2/evidence/lp1_preflight/ABSENT.json';expect('go_contract_missing','go',@()g2_lp1_go_validate(g,Cs,L0),SRC,mBytes);
g=G0;g.contractEvidenceSHA256=repmat('e',1,64);expect('go_contract_sha_mismatch','go',@()g2_lp1_go_validate(g,Cs,L0),SRC,mBytes);
bad={'go_contract_lacks_fields',rmfield(Tc,'negativeTestsPassed'),mLack; ...
 'go_contract_not_pass',setf(Tc,'pass',false),mNot;'go_contract_incomplete_count',setf(Tc,'passed',29),mNot; ...
 'go_contract_too_few_tests',setf(setf(Tc,'passed',19),'total',19),mNot; ...
 'go_contract_physical_solve',setf(Tc,'physicalSolves',1),mNot;'go_contract_mesh_build',setf(Tc,'meshBuilds',1),mNot; ...
 'go_contract_negatives_false',setf(Tc,'negativeTestsPassed',false),mNot; ...
 'go_contract_integrity_false',setf(Tc,'recordIntegrityPassed',false),mNot};
for k=1:size(bad,1)
 [g,L]=fixture(bad{k,2});expect(bad{k,1},'go',@()g2_lp1_go_validate(g,Cs,L),UN,bad{k,3});
end

% ---------------------------------------------------------------- immutable records
file=fullfile(folder,'REVIEW.mat');h=g2_trajectory_record('write',file,R);
ok('record_roundtrip','record',@()roundtrip(file,R,h));
expect('overwrite_refused','record',@()g2_trajectory_record('write',file,R),'G2Chain:RecordExists','overwrite');
fid=fopen(file,'a');fwrite(fid,uint8(1));fclose(fid);
ok('byte_tamper','record',@()~readOK(file));
f2=fullfile(folder,'MANIFEST_TAMPER.mat');g2_trajectory_record('write',f2,R);
mt=fileread([f2,'.manifest.json']);mt2=regexprep(mt,'"SHA256": "[0-9A-Fa-f]+"','"SHA256": "00"');
assert(~strcmp(mt,mt2),'G2LP1:HOLD_TEST','Manifest tamper fixture did not change the manifest.');
fid=fopen([f2,'.manifest.json'],'w');fwrite(fid,mt2,'char');fclose(fid);
ok('manifest_tamper','record',@()~readOK(f2));
f3=fullfile(folder,'NO_MANIFEST.mat');g2_trajectory_record('write',f3,R);delete([f3,'.manifest.json']);
ok('mat_without_manifest','record',@()~readOK(f3));
ok('missing_record','record',@()~readOK(fullfile(folder,'ABSENT.mat')));
expect('record_without_schema','record',@()g2_trajectory_record('write',fullfile(folder,'NOSCHEMA.mat'),struct('a',1)), ...
 'G2Chain:RecordSchema','schema-tagged');
expect('record_missing_folder','record',@()g2_trajectory_record('write',fullfile(folder,'absent','X.mat'),R), ...
 'G2Chain:RecordFolder','Parent record folder');

% ---------------------------------------------------------------- state admission (memory-guard order)
adm=fullfile(folder,'admission');mkdir(adm);
part=fullfile(adm,'S1');mkdir(part);fid=fopen(fullfile(part,'MESH.mat'),'w');fwrite(fid,uint8(7));fclose(fid);
expect('admit_partial_state_refused','admission',@()g2_lp1_admit_state(part,64),RI,'Partial unreviewed state');
ok('admit_partial_state_untouched','admission',@()numel(dir(part))==3);
lo=fullfile(adm,'S2');expect('admit_low_memory_refused','admission',@()g2_lp1_admit_state(lo,4.958122),MEM,'5 GiB');
ok('admit_low_memory_no_folder','admission',@()~isfolder(lo));
expect('admit_boundary_below_refused','admission',@()g2_lp1_admit_state(lo,5-1e-9),MEM,'5 GiB');
expect('admit_nonfinite_memory_refused','admission',@()g2_lp1_admit_state(lo,NaN),MEM,'5 GiB');
ok('admit_nonfinite_no_folder','admission',@()~isfolder(lo));
ok('admit_at_threshold_creates_folder','admission',@()admitOK(fullfile(adm,'S3'),5));
ok('admit_threshold_equals_policy','admission',@()pol.resources.freePhysicalRAM_GiB_min==5);

% ---------------------------------------------------------------- source drift
lines={'legacy-lock X','g2_lp1_run.m 0123'};d0=g2_lp1_digest(strjoin(lines,newline));
lines2=lines;lines2{2}(end)='4';
ok('source_digest_detects_one_byte_drift','positive',@()~strcmp(d0,g2_lp1_digest(strjoin(lines2,newline))));

% ---------------------------------------------------------------- VG2: GO campaign fields (pure validator)
mScope='Campaign scope, run name or campaign ID is invalid';
expect('go_missing_campaign_id','go',@()g2_lp1_go_validate(rmfield(G0,'campaignId'),Cs,L0),UN,mInc);
expect('go_missing_run_name','go',@()g2_lp1_go_validate(rmfield(G0,'approvedRunName'),Cs,L0),UN,mInc);
g=G0;g.campaignScope='LP2_FULL_PATH';expect('go_wrong_campaign_scope','go',@()g2_lp1_go_validate(g,Cs,L0),UN,mScope);
g=G0;g.approvedRunName='run_20261122_lp1_v1';expect('go_historical_run_name','go',@()g2_lp1_go_validate(g,Cs,L0),UN,mScope);
g=G0;g.approvedRunName='run_../x';expect('go_run_name_syntax','go',@()g2_lp1_go_validate(g,Cs,L0),UN,mScope);
g=G0;g.campaignId='a';expect('go_campaign_id_syntax','go',@()g2_lp1_go_validate(g,Cs,L0),UN,mScope);

% ---------------------------------------------------------------- VG2: campaign decision (pure, in-memory facts)
CS='G2LP1:HOLD_CAMPAIGN_SCOPE';CI='G2LP1:HOLD_CAMPAIGN_INTEGRITY';CR='G2LP1:HOLD_CAMPAIGN_REVIEW_REQUIRED';
Gc=G0;goSha=repmat('9',1,64);tok=Cs.token;rn=Gc.approvedRunName;
L_=struct('integrityOK',true,'receipt',[],'admits',{{}},'holds',struct('file',{},'sha256',{},'caseId',{},'stateIndex',{}), ...
 'resumes',{{}},'closed',false);
F0=struct('exists',false,'hasRunRecord',false,'runTokenMatches',false);
F1=struct('exists',true,'hasRunRecord',true,'runTokenMatches',true);
rcp=struct('campaignId',Gc.campaignId,'runName',rn,'goSHA256',goSha,'token',tok);
Lr=L_;Lr.receipt=rcp;Lr.admits={'H_S0','H_S1'};
hs=repmat('7',1,64);Lh=Lr;Lh.holds=struct('file','HOLD_x.mat','sha256',hs,'caseId','H','stateIndex',2);
R1=struct('record',struct('decision','RESUME_AFTER_PREADMISSION_MEMORY_HOLD','campaignId',Gc.campaignId, ...
 'holdRecordSHA256',hs,'scientificReviewer','SYNTHETIC_TEST_REVIEW','reviewURL','https://github.com/mfs9697/NewMetacomp/issues/62'),'sha256',repmat('6',1,64));
cv=@(G,r,s,k,L,F,R)g2_lp1_campaign_validate(G,r,s,k,L,F,R);
ok('camp_open_new_positive','campaign',@()modeIs(cv(Gc,rn,goSha,tok,L_,F0,[]),'OPEN_NEW'));
expect('camp_wrong_run_name','campaign',@()cv(Gc,'run_other_campaign',goSha,tok,L_,F0,[]),CS,'not the run approved');
expect('camp_missing_run_name','campaign',@()cv(Gc,'',goSha,tok,L_,F0,[]),CS,'not the run approved');
expect('camp_historical_run_name','campaign',@()cv(Gc,'run_20261122_lp1_v1',goSha,tok,Lr,F1,[]),CS,'not the run approved');
expect('camp_duplicate_campaign_new_run','campaign',@()cv(Gc,'run_second_campaign',goSha,tok,Lr,F1,[]),CS,'not the run approved');
Lb=L_;Lb.integrityOK=false;expect('camp_ledger_integrity_fail','campaign',@()cv(Gc,rn,goSha,tok,Lb,F0,[]),CI,'ledger record failed');
expect('camp_run_folder_without_receipt','campaign',@()cv(Gc,rn,goSha,tok,L_,F1,[]),CI,'Run folder exists without');
Le=L_;Le.admits={'H_S0'};expect('camp_entries_without_receipt','campaign',@()cv(Gc,rn,goSha,tok,Le,F0,[]),CI,'Ledger entries exist without');
Le=L_;Le.closed=true;expect('camp_closure_without_receipt','campaign',@()cv(Gc,rn,goSha,tok,Le,F0,[]),CI,'Ledger entries exist without');
ok('camp_continue_positive','campaign',@()modeIs(cv(Gc,rn,goSha,tok,Lr,F1,[]),'CONTINUE'));
ok('camp_repeated_staged_calls_continue','campaign',@()stagedContinue(cv,Gc,rn,goSha,tok,Lr,F1));
x=Lr;x.receipt.goSHA256=repmat('8',1,64);expect('camp_receipt_other_go','campaign',@()cv(Gc,rn,goSha,tok,x,F1,[]),CI,'does not bind');
x=Lr;x.receipt.campaignId='OTHER-CAMPAIGN';expect('camp_receipt_other_campaign','campaign',@()cv(Gc,rn,goSha,tok,x,F1,[]),CI,'does not bind');
x=Lr;x.receipt.runName='run_other_campaign';expect('camp_receipt_other_run','campaign',@()cv(Gc,rn,goSha,tok,x,F1,[]),CI,'does not bind');
x=Lr;x.receipt.token=[tok,'|x'];expect('camp_receipt_other_token','campaign',@()cv(Gc,rn,goSha,tok,x,F1,[]),CI,'does not bind');
x=Lr;x.receipt=rmfield(x.receipt,'goSHA256');expect('camp_receipt_spoofed_fields','campaign',@()cv(Gc,rn,goSha,tok,x,F1,[]),CI,'does not bind');
x=Lr;x.admits={};ok('camp_interrupted_opening_continue','campaign',@()modeIs(cv(Gc,rn,goSha,tok,x,F0,[]),'CONTINUE'));
expect('camp_deleted_run_folder','campaign',@()cv(Gc,rn,goSha,tok,Lr,F0,[]),CI,'Admitted states are missing');
F2=F1;F2.runTokenMatches=false;expect('camp_run_token_mismatch','campaign',@()cv(Gc,rn,goSha,tok,Lr,F2,[]),CI,'Run record token differs');
x=Lr;x.closed=true;ok('camp_closed_verify_only','campaign',@()modeIs(cv(Gc,rn,goSha,tok,x,F1,[]),'VERIFY_ONLY'));
x=Lh;x.closed=true;ok('camp_closed_overrides_resume','campaign',@()modeIs(cv(Gc,rn,goSha,tok,x,F1,R1),'VERIFY_ONLY'));
expect('camp_hold_without_review','campaign',@()cv(Gc,rn,goSha,tok,Lh,F1,[]),CR,'Unreviewed pre-admission');
ok('camp_hold_reviewed_resume_positive','campaign',@()resumeOK(cv(Gc,rn,goSha,tok,Lh,F1,R1),hs));
mRes='does not bind this campaign and HOLD';
x=R1;x.record.holdRecordSHA256=repmat('5',1,64);expect('camp_resume_wrong_hold','campaign',@()cv(Gc,rn,goSha,tok,Lh,F1,x),CR,mRes);
x=R1;x.record.campaignId='OTHER-CAMPAIGN';expect('camp_resume_wrong_campaign','campaign',@()cv(Gc,rn,goSha,tok,Lh,F1,x),CR,mRes);
x=R1;x.record.decision='GO_LP1_PHYSICAL';expect('camp_resume_wrong_decision','campaign',@()cv(Gc,rn,goSha,tok,Lh,F1,x),CR,mRes);
x=R1;x.record.reviewURL='https://example.org/r';expect('camp_resume_foreign_url','campaign',@()cv(Gc,rn,goSha,tok,Lh,F1,x),CR,mRes);
x=R1;x.record.scientificReviewer=' ';expect('camp_resume_empty_reviewer','campaign',@()cv(Gc,rn,goSha,tok,Lh,F1,x),CR,mRes);
x=Lh;x.resumes={hs};x.holds(2)=struct('file','HOLD_y.mat','sha256',repmat('4',1,64),'caseId','H','stateIndex',2);
y=R1;y.record.holdRecordSHA256=repmat('4',1,64);
expect('camp_resume_allowance_exhausted','campaign',@()cv(Gc,rn,goSha,tok,x,F1,y),CR,'allowance exhausted');
x=Lh;x.holds(2)=struct('file','HOLD_y.mat','sha256',repmat('4',1,64),'caseId','H','stateIndex',2);
expect('camp_two_unreviewed_holds','campaign',@()cv(Gc,rn,goSha,tok,x,F1,R1),CR,'More than one');
x=Lh;x.resumes={hs};ok('camp_resolved_hold_continue_without_resume_file','campaign',@()modeIs(cv(Gc,rn,goSha,tok,x,F1,[]),'CONTINUE'));

% ---------------------------------------------------------------- VG2: immutable campaign ledger (temporary folder)
lr=fullfile(folder,'ledger_test');
ok('ledger_absent_snapshot','ledger',@()emptyLedger(g2_lp1_campaign_ledger('snapshot',lr)));
cid=Gc.campaignId;
g2_lp1_campaign_ledger('write',lr,'RECEIPT','RECEIPT.mat',struct('campaignId',cid,'runName',rn,'goSHA256',goSha,'token',tok));
g2_lp1_campaign_ledger('write',lr,'ADMIT','ADMIT_H_S0.mat',struct('campaignId',cid,'stateKey','H_S0','caseId','H','stateIndex',0));
hsh=g2_lp1_campaign_ledger('write',lr,'HOLD','HOLD_PREADMISSION_MEMORY_H_S1_X.mat',struct('campaignId',cid,'caseId','H','stateIndex',1));
g2_lp1_campaign_ledger('write',lr,'RESUME',['RESUME_',hsh(1:16),'.mat'],struct('campaignId',cid,'holdRecordSHA256',hsh));
Ls=g2_lp1_campaign_ledger('snapshot',lr);
ok('ledger_roundtrip_positive','ledger',@()Ls.integrityOK&&strcmp(Ls.receipt.runName,rn)&&isequal(Ls.admits,{'H_S0'})&& ...
 strcmp(Ls.holds(1).sha256,hsh)&&isequal(Ls.resumes,{hsh})&&~Ls.closed);
expect('ledger_duplicate_receipt_refused','ledger',@()g2_lp1_campaign_ledger('write',lr,'RECEIPT','RECEIPT.mat',struct('campaignId',cid)), ...
 'G2Chain:RecordExists','overwrite');
expect('ledger_duplicate_admit_refused','ledger',@()g2_lp1_campaign_ledger('write',lr,'ADMIT','ADMIT_H_S0.mat',struct('campaignId',cid,'stateKey','H_S0','stateIndex',0)), ...
 'G2Chain:RecordExists','overwrite');
expect('ledger_invalid_entry_name','ledger',@()g2_lp1_campaign_ledger('write',lr,'ADMIT','RECEIPT.mat',struct('campaignId',cid)),CI,'Invalid ledger entry name');
expect('ledger_path_traversal_name','ledger',@()g2_lp1_campaign_ledger('write',lr,'ADMIT',['ADMIT_..',filesep,'x.mat'],struct('campaignId',cid)),CI,'Invalid ledger entry name');
g2_lp1_campaign_ledger('write',lr,'CLOSED','CLOSED.mat',struct('campaignId',cid));
ok('ledger_closed_positive','ledger',@()snapField(lr,'closed'));
l2=fullfile(folder,'ledger_tamper');copyfile(lr,l2);
fid=fopen(fullfile(l2,'ADMIT_H_S0.mat'),'a');fwrite(fid,uint8(1));fclose(fid);
ok('ledger_tampered_entry_detected','ledger',@()~snapField(l2,'integrityOK'));
l3=fullfile(folder,'ledger_unexpected');copyfile(lr,l3);fid=fopen(fullfile(l3,'notes.txt'),'w');fwrite(fid,'x');fclose(fid);
ok('ledger_unexpected_file_detected','ledger',@()~snapField(l3,'integrityOK'));
l4=fullfile(folder,'ledger_foreign');copyfile(lr,l4);
g2_lp1_campaign_ledger('write',l4,'ADMIT','ADMIT_H_S1.mat',struct('campaignId','OTHER-CAMPAIGN','stateKey','H_S1','stateIndex',1));
ok('ledger_foreign_entry_detected','ledger',@()~snapField(l4,'integrityOK'));
l5=fullfile(folder,'ledger_kind');copyfile(lr,l5);
g2_trajectory_record('write',fullfile(l5,'HOLD_SPOOF.mat'),struct('schema','x','ledgerKind','ADMIT','campaignId',cid,'stateKey','H_S2','stateIndex',2));
ok('ledger_kind_spoof_detected','ledger',@()~snapField(l5,'integrityOK'));
l6=fullfile(folder,'ledger_orphan');copyfile(lr,l6);delete(fullfile(l6,'CLOSED.mat'));
ok('ledger_orphan_manifest_detected','ledger',@()~snapField(l6,'integrityOK'));

% ---------------------------------------------------------------- VG2: admission hook order
hk=fullfile(folder,'hook');mkdir(hk);hookCalls=0;
expect('admit_hook_not_called_on_low_memory','admission',@()g2_lp1_admit_state(fullfile(hk,'S1'),4.9,@()countHook()),MEM,'5 GiB');
ok('admit_hook_low_memory_no_call_no_folder','admission',@()hookCalls==0&&~isfolder(fullfile(hk,'S1')));
expect('admit_hook_refusal_leaves_no_folder','admission',@()g2_lp1_admit_state(fullfile(hk,'S2'),64,@()closedHook()), ...
 'G2LP1:HOLD_CAMPAIGN_CLOSED','Campaign is closed');
ok('admit_hook_refusal_no_folder','admission',@()~isfolder(fullfile(hk,'S2')));
ok('admit_hook_positive_then_folder','admission',@()hookThenFolder(fullfile(hk,'S3')));

% ---------------------------------------------------------------- VG2: controller wiring (static) and interface
ok('controller_campaign_decided_before_writes','interface',@()campaignBeforeWrites(rs));
ok('controller_receipt_only_on_open_new','interface',@()contains(rs,sprintf('if strcmp(Camp.mode,''OPEN_NEW'')\n g2_lp1_campaign_ledger(''write'',lroot,''RECEIPT'',''RECEIPT.mat''')));
ok('controller_admission_uses_campaign_hook','interface',@()contains(rs,'g2_lp1_admit_state(sd,freeRAM(),@()admitHook(lroot,Camp,goRec.campaignId,c.id,k));'));
ok('controller_verify_only_checked_before_loop','interface',@()verifyBeforeLoop(rs));
ok('controller_campaign_refusal_writes_no_state','interface',@()contains(rs,'if ~preAdmissionMemory&&~campaignRefusal&&~isfolder(sd),mkdir(sd);end'));
ok('gate_returns_validated_go_sha','interface',@()contains(gs,'G.goFileSHA256=goSHA;'));
ok('campaign_validator_opens_no_file','interface',@()~any(contains(fileread(fullfile(here,'g2_lp1_campaign_validate.m')), ...
 {'fileread(','fopen(','load(','isfile(','dir(','mkdir('})));
ok('resume_path_hardcoded','interface',@()contains(rs,'p=fullfile(here,''G2_LP1_CAMPAIGN_RESUME_v1.json'');'));
expect('controller_rejects_resume_path_argument','negative',@()g2_lp1_run('ResumeFile','x.json'),'MATLAB:InputParser:UnmatchedParameter','');
expect('controller_rejects_campaign_argument','negative',@()g2_lp1_run('CampaignId','X'),'MATLAB:InputParser:UnmatchedParameter','');

% ---------------------------------------------------------------- summary
kinds={rows.kind};pass=[rows.pass];
neg=strcmp(kinds,'negative');rec=strcmp(kinds,'record');gok=strcmp(kinds,'go');adk=strcmp(kinds,'admission');itf=strcmp(kinds,'interface');
cmp=strcmp(kinds,'campaign');led=strcmp(kinds,'ledger');
T=struct('pass',all(pass),'tests',rows,'passed',nnz(pass),'total',numel(rows), ...
 'physicalSolves',0,'meshBuilds',0, ...
 'negativeTestsPassed',nnz(neg)>=19&&all(pass(neg)), ...
 'recordIntegrityPassed',nnz(rec)>=8&&all(pass(rec)), ...
 'goFixturesPassed',nnz(gok)>=30&&all(pass(gok)), ...
 'admissionPassed',nnz(adk)>=14&&all(pass(adk)), ...
 'interfacePassed',nnz(itf)>=12&&all(pass(itf)), ...
 'campaignPassed',nnz(cmp)>=30&&all(pass(cmp)),'ledgerPassed',nnz(led)>=12&&all(pass(led)), ...
 'exactIdentifierNegatives',true,'testFolder',strrep(folder,repo,'<repo>'), ...
 'schema','NewMetacomp.G2.LP1.ContractTests.v3');
T.pass=T.pass&&T.negativeTestsPassed&&T.recordIntegrityPassed&&T.goFixturesPassed&&T.admissionPassed&&T.interfacePassed&& ...
 T.campaignPassed&&T.ledgerPassed;
fprintf('G2_LP1_CONTRACT_TESTS=%d/%d NEG=%d REC=%d GO=%d ADM=%d IFC=%d CAMP=%d LEDGER=%d\n',T.passed,T.total, ...
 nnz(neg),nnz(rec),nnz(gok),nnz(adk),nnz(itf),nnz(cmp),nnz(led));
if assertPass,assert(T.pass,'G2LP1:ContractTests','A contract test failed.');end

 function expect(name,kind,fn,id,frag)
  obs='<no error>';msgOK=false;
  try
   fn();
  catch ME
   obs=ME.identifier;msgOK=isempty(frag)||contains(ME.message,frag);
  end
  add(name,kind,[id,ternary(isempty(frag),'',[' | ',frag])],obs,strcmp(obs,id)&&msgOK);
 end
 function ok(name,kind,fn)
  obs='true';p=false;
  try
   p=isequal(fn(),true);if ~p,obs='false';end
  catch ME
   obs=['<error> ',ME.identifier];
  end
  add(name,kind,'true',obs,p);
 end
 function add(name,kind,ex,obs,p)
  rows(end+1)=struct('name',name,'kind',kind,'expected',ex,'observed',obs,'pass',logical(p));
  fprintf('%s %d [%s] expected=%s observed=%s\n',name,p,kind,ex,obs);
 end
 function [G,L]=fixture(Tx)
  txt=jsonencode(Tx);
  G=struct('decision','GO_LP1_PHYSICAL','reviewStatus','REVIEWED_ACCEPTED', ...
   'scientificReviewer','SYNTHETIC_TEST_FIXTURE_NOT_A_REVIEW', ...
   'reviewURL','https://github.com/mfs9697/NewMetacomp/issues/58', ...
   'approvedPolicySHA256',Cs.policySHA256,'approvedSourceSHA256',Cs.sourceSHA256, ...
   'approvedLP0SHA256',Cs.policy.lp0Evidence.sha256,'approvedToken',Cs.token, ...
   'contractEvidenceFile','matlab/g2/evidence/lp1_preflight/SYNTHETIC_FIXTURE.json', ...
   'contractEvidenceSHA256',g2_lp1_digest(txt), ...
   'approvedRunName','run_synthetic_test_campaign','campaignId','SYNTHETIC-TEST-CAMPAIGN', ...
   'campaignScope','A0_LP1_S0_S4_REPRODUCTION');
  L=@(p)loadFixture(p,G.contractEvidenceFile,txt);
 end
 function countHook(),hookCalls=hookCalls+1;end
end

function E=loadFixture(p,name,txt)
E=struct('exists',strcmp(p,name),'sha256','','text','');
if E.exists,E.sha256=g2_lp1_digest(txt);E.text=txt;end
end
function y=linksOK(verify,R,S),verify(R,S);y=true;end
function y=roundtrip(file,R,h),[b,h2,v]=g2_trajectory_record('read',file);y=v&&isequal(R,b)&&strcmp(h,h2);end
function y=readOK(file),[~,~,y]=g2_trajectory_record('read',file);end
function y=admitOK(sd,g),g2_lp1_admit_state(sd,g);y=isfolder(sd);end
function s=setf(s,f,v),s.(f)=v;end
function y=ternary(c,a,b),if c,y=a;else,y=b;end,end
function y=gateBeforeMkdir(src)
% The scientific gate must be invoked after the Run check and before every mkdir/record write.
iRun=strfind(src,'if ~o.Run,return,end');iGate=strfind(src,'g2_lp1_scientific_gate(C);');
iMk=strfind(src,'mkdir(');iW=strfind(src,'g2_trajectory_record(''write''');
y=isscalar(iRun)&&isscalar(iGate)&&iRun<iGate&&all(iMk>iGate)&&all(iW>iGate);
end
function y=modeIs(D,m),y=strcmp(D.mode,m);end
function y=resumeOK(D,hs),y=strcmp(D.mode,'CONTINUE')&&strcmp(D.consumeResume,hs);end
function y=emptyLedger(L),y=L.integrityOK&&isempty(L.receipt)&&isempty(L.admits)&&isempty(L.holds)&&~L.closed;end
function y=snapField(root,f),L=g2_lp1_campaign_ledger('snapshot',root);y=L.(f);end
function closedHook(),error('G2LP1:HOLD_CAMPAIGN_CLOSED','Campaign is closed: no new state may be computed.');end
function y=stagedContinue(cv,Gc,rn,goSha,tok,Lr,F1)
% Repeated staged calls of the same campaign (H prefix, candidate prefixes, S3/S4) keep CONTINUE.
sets={{'H_S0'},{'H_S0','H_S1','H_S2'},{'H_S0','H_S1','H_S2','stiff13_S0','soft2_S2','soft1_S2'}};y=true;
for i=1:numel(sets),L=Lr;L.admits=sets{i};y=y&&strcmp(cv(Gc,rn,goSha,tok,L,F1,[]).mode,'CONTINUE');end
end
function y=hookThenFolder(sd)
% The hook is called before the folder exists, and the folder exists afterwards.
seen=struct('folderBefore',true);
g2_lp1_admit_state(sd,64,@()noteFolder());
y=~seen.folderBefore&&isfolder(sd);
 function noteFolder(),seen.folderBefore=isfolder(sd);end
end
function y=campaignBeforeWrites(src)
% The campaign decision follows the gate and precedes every mkdir, ledger write and record write.
iG=strfind(src,'goRec=g2_lp1_scientific_gate(C);');iC=strfind(src,'Camp=g2_lp1_campaign_validate(');
iMk=strfind(src,'mkdir(');iLw=strfind(src,'g2_lp1_campaign_ledger(''write''');iW=strfind(src,'g2_trajectory_record(''write''');
y=isscalar(iG)&&isscalar(iC)&&iG<iC&&all(iMk>iC)&&all(iLw>iC)&&all(iW>iC);
end
function y=verifyBeforeLoop(src)
iV=strfind(src,'if strcmp(Camp.mode,''VERIFY_ONLY'')');iL=strfind(src,'for k=0:o.MaxStateIndex');iR=strfind(src,'if ~isfolder(rd),mkdir(rd);end');
y=isscalar(iV)&&isscalar(iL)&&isscalar(iR)&&iV<iR&&iR<iL;
end
