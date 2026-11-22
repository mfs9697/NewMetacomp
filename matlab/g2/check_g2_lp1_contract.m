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

% ---------------------------------------------------------------- summary
kinds={rows.kind};pass=[rows.pass];
neg=strcmp(kinds,'negative');rec=strcmp(kinds,'record');gok=strcmp(kinds,'go');adk=strcmp(kinds,'admission');itf=strcmp(kinds,'interface');
T=struct('pass',all(pass),'tests',rows,'passed',nnz(pass),'total',numel(rows), ...
 'physicalSolves',0,'meshBuilds',0, ...
 'negativeTestsPassed',nnz(neg)>=19&&all(pass(neg)), ...
 'recordIntegrityPassed',nnz(rec)>=8&&all(pass(rec)), ...
 'goFixturesPassed',nnz(gok)>=24&&all(pass(gok)), ...
 'admissionPassed',nnz(adk)>=9&&all(pass(adk)), ...
 'interfacePassed',nnz(itf)>=4&&all(pass(itf)), ...
 'exactIdentifierNegatives',true,'testFolder',strrep(folder,repo,'<repo>'), ...
 'schema','NewMetacomp.G2.LP1.ContractTests.v2');
T.pass=T.pass&&T.negativeTestsPassed&&T.recordIntegrityPassed&&T.goFixturesPassed&&T.admissionPassed&&T.interfacePassed;
fprintf('G2_LP1_CONTRACT_TESTS=%d/%d NEG=%d REC=%d GO=%d ADM=%d IFC=%d\n',T.passed,T.total, ...
 nnz(neg),nnz(rec),nnz(gok),nnz(adk),nnz(itf));
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
   'contractEvidenceSHA256',g2_lp1_digest(txt));
  L=@(p)loadFixture(p,G.contractEvidenceFile,txt);
 end
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
