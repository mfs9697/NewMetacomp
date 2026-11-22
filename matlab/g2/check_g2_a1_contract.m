function T=check_g2_a1_contract(baselineS4MeshFile,assertPass)
%CHECK_G2_A1_CONTRACT  A1 transfer, validator, GO and runner contract tests (Issue #66). No FEM.
% baselineS4MeshFile: a saved S4 mesh of case H (A0 or the bitwise-identical historical record).
% Every negative requires its exact MATLAB identifier and the message fragment of its branch;
% any other error, or none, fails. GO fixtures are in-memory only; no GO file is written.
if nargin<2,assertPass=true;end
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
addpath(fullfile(here,'vendor_p010_a14d8872'),'-begin');
rows=struct('name',{},'kind',{},'expected',{},'observed',{},'pass',{});
UN='G2A1:HOLD_UNAUTHORIZED_STATE';SRC='G2A1:HOLD_SOURCE';
D=load(baselineS4MeshFile);P=D.crackPolyline;
[~,B]=evalc('g2_kinked_regular_block(P,''ExpectedTangent'',D.tipTangent,''ExpectedVertices'',size(P,1),''TipGuideRadius_mm'',15)');
Lr=B.sourceP010;
% ---------------------------------------------------------------- transfer (ported Family B builder)
expect('patch_band_pairs_zero','transfer',@()g2_a1_family_b_patch(struct('family','B','extraBandPairs',0),Lr),'PRH:PatchBands','positive integer');
expect('patch_band_pairs_fractional','transfer',@()g2_a1_family_b_patch(struct('family','B','extraBandPairs',1.5),Lr),'PRH:PatchBands','positive integer');
expect('patch_family_a_not_transferred','transfer',@()g2_a1_family_b_patch(struct('family','A'),Lr),'PRH:PatchFamily','Unknown patch family');
expect('patch_unqualified_ring','transfer',@()g2_a1_family_b_patch(struct('family','B','extraBandPairs',3),setfield(Lr,'pass',false)),'PRH:PatchParentRing','15/15'); %#ok<SFLD>
pit=arrayfun(@(m)getfield(g2_a1_family_b_patch(struct('family','B','extraBandPairs',m),Lr),'firstPitch_m'),[3 6 9]); %#ok<GFLD>
ok('patch_first_pitch_equals_edge_prh','transfer',@()max(abs(1000*pit-[0.025773614030 0.015942700324 0.009861624114]))<1e-11);
% ---------------------------------------------------------------- patch swap
[~,M0]=evalc('g2_a1_patch_swap(D,struct(''family'',''BASE''))');
kf={'X3','T3','X6','T6','upperBankT6','lowerBankT6','physicalTipNode','nodalQ','qActiveT6Rows','elementRows','collarOuterIDs','extraVertexNodes','kinkNodeIDs'};
ok('swap_m0_reproduces_saved_mesh_exactly','transfer',@()all(cellfun(@(k)isequal(M0.(k),D.(k)),kf)));
expect('swap_missing_field','transfer',@()g2_a1_patch_swap(rmfield(D,'nodalQ'),struct('family','BASE')),'G2A1:BaselineSchema','lacks required');
Dt=D;Dt.X3(5,1)=Dt.X3(5,1)+1e-9;
expect('swap_tampered_kernel','transfer',@()g2_a1_patch_swap(Dt,struct('family','BASE')),'G2A1:BaselineIdentity','differ from the saved');
[~,M3]=evalc('g2_a1_patch_swap(D,struct(''family'',''B'',''extraBandPairs'',3))');
V=g2_a1_mesh_validate(M3,D);ok('validator_B3_positive','validator',@()V.pass&&V.gatesPassed==V.gatesTotal);
x=M3;k=x.elementRows.core(1);x.T3(k,[2 3])=x.T3(k,[3 2]);gate('validator_flipped_element','allT3AreasPositive',x,D);
x=M3;x.X3(end,1)=x.X3(end,1)+1e-6;gate('validator_moved_exterior_node','exteriorNodesBitIdentical',x,D);
x=M3;r6=vecnorm(x.X6-P(end,:),2,2);i=find(r6>2.7,1);x.nodalQ(i)=.5;gate('validator_q_nonzero_beyond_support','qSupportInsideCoreAndZeroOnRim',x,D);
x=M3;x.T3(x.elementRows.core(end),:)=[];x.T6(x.elementRows.core(end),:)=[];x.elementRows.core(end)=[];
x.elementRows.collar=x.elementRows.collar-1;x.elementRows.exterior=x.elementRows.exterior-1;
gate('validator_missing_core_cell','boundaryEdgesOnlyPlateHolesOrCrack',x,D);
x=M3;x.upperBankT6(2)=x.upperBankT6(3);gate('validator_corrupted_bank','distinctMatchedBanks',x,D);
x=M3;x.physicalTipNode=x.physicalTipNode+1;gate('validator_wrong_tip','singleTipAtPolylineEnd',x,D);
x=M3;x.X6(1,1)=x.X6(1,1)*(1+eps);ok('content_sha_detects_one_ulp','validator',@()~strcmp(g2_a1_mesh_content_sha(x),g2_a1_mesh_content_sha(M3)));
% ---------------------------------------------------------------- A1 GO (pure, in-memory)
Cs=struct('policySHA256',repmat('a',1,64),'sourceSHA256',repmat('b',1,64),'meshManifestSHA256',repmat('c',1,64), ...
 'token','G2A1|SYNTHETIC_TEST_TOKEN');
Tc=struct('pass',true,'passed',40,'total',40,'physicalSolves',0,'negativeTestsPassed',true);
[G0,L0]=fixture(Tc);
ok('go_fixture_positive_control','go',@()isequal(g2_a1_go_validate(G0,Cs,L0),G0));
mI='Incomplete A1';mR='decision or review';mS='scope, run name or campaign ID';mB='does not bind';mP='not pinned';mY='absent or changed';
expect('go_not_struct','go',@()g2_a1_go_validate('x',Cs,L0),UN,mI);
expect('go_missing_mesh_manifest','go',@()g2_a1_go_validate(rmfield(G0,'approvedMeshManifestSHA256'),Cs,L0),UN,mI);
g=G0;g.decision='GO_LP1_PHYSICAL';expect('go_lp1_decision_rejected','go',@()g2_a1_go_validate(g,Cs,L0),UN,mR);
g=G0;g.reviewURL='https://example.org';expect('go_foreign_url','go',@()g2_a1_go_validate(g,Cs,L0),UN,mR);
g=G0;g.campaignScope='A0_LP1_S0_S4_REPRODUCTION';expect('go_a0_scope_rejected','go',@()g2_a1_go_validate(g,Cs,L0),UN,mS);
g=G0;g.approvedRunName='run_a0_lp1_repro_v1';expect('go_a0_run_name_rejected','go',@()g2_a1_go_validate(g,Cs,L0),UN,mS);
g=G0;g.approvedRunName='run_20261122_lp1_v1';expect('go_lp1_run_name_rejected','go',@()g2_a1_go_validate(g,Cs,L0),UN,mS);
g=G0;g.campaignId='G2-LP1-A0-001';expect('go_a0_campaign_rejected','go',@()g2_a1_go_validate(g,Cs,L0),UN,mS);
g=G0;g.campaignId='x';expect('go_campaign_id_syntax','go',@()g2_a1_go_validate(g,Cs,L0),UN,mS);
g=G0;g.approvedA1PolicySHA256=repmat('d',1,64);expect('go_policy_mismatch','go',@()g2_a1_go_validate(g,Cs,L0),SRC,mB);
g=G0;g.approvedSourceSHA256=repmat('d',1,64);expect('go_source_mismatch','go',@()g2_a1_go_validate(g,Cs,L0),SRC,mB);
g=G0;g.approvedMeshManifestSHA256=repmat('d',1,64);expect('go_mesh_manifest_mismatch','go',@()g2_a1_go_validate(g,Cs,L0),SRC,mB);
g=G0;g.approvedToken=[Cs.token,'|x'];expect('go_token_mismatch','go',@()g2_a1_go_validate(g,Cs,L0),SRC,mB);
g=G0;g.contractEvidenceFile='matlab/g2/evidence/lp1_preflight/x.json';expect('go_contract_path_outside','go',@()g2_a1_go_validate(g,Cs,L0),SRC,mP);
g=G0;g.contractEvidenceFile='matlab/g2/evidence/a1_preflight/../x.json';expect('go_contract_traversal','go',@()g2_a1_go_validate(g,Cs,L0),SRC,mP);
g=G0;g.contractEvidenceFile='matlab/g2/evidence/a1_preflight/ABSENT.json';expect('go_contract_missing','go',@()g2_a1_go_validate(g,Cs,L0),SRC,mY);
g=G0;g.contractEvidenceSHA256=repmat('e',1,64);expect('go_contract_sha_mismatch','go',@()g2_a1_go_validate(g,Cs,L0),SRC,mY);
[g,L]=fixture(rmfield(Tc,'negativeTestsPassed'));expect('go_contract_lacks_fields','go',@()g2_a1_go_validate(g,Cs,L),UN,'lacks required');
[g,L]=fixture(setf(Tc,'pass',false));expect('go_contract_not_passed','go',@()g2_a1_go_validate(g,Cs,L),UN,'has not passed');
[g,L]=fixture(setf(Tc,'physicalSolves',1));expect('go_contract_with_solves','go',@()g2_a1_go_validate(g,Cs,L),UN,'has not passed');
folder=fullfile(repo,'outputs',['g2_a1_contract_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);assert(~isfolder(folder));mkdir(folder);
Cabs=struct('here',folder,'repo',repo);
expect('gate_absent_go','go',@()g2_a1_scientific_gate(Cabs),UN,'no separate A1 GO');
% ---------------------------------------------------------------- runner interface (no context needed)
expect('runner_level_zero','runner',@()g2_a1_run('Level',0),UN,'Only Family B levels');
expect('runner_level_twelve','runner',@()g2_a1_run('Level',12),UN,'Only Family B levels');
expect('runner_level_fraction','runner',@()g2_a1_run('Level',4.5),UN,'Only Family B levels');
expect('runner_rejects_go_path','runner',@()g2_a1_run('GoFile','x'),'MATLAB:InputParser:UnmatchedParameter','');
expect('runner_rejects_resume_path','runner',@()g2_a1_run('ResumeFile','x'),'MATLAB:InputParser:UnmatchedParameter','');
rs=fileread(fullfile(here,'g2_a1_run.m'));gs=fileread(fullfile(here,'g2_a1_scientific_gate.m'));
ok('gate_path_hardcoded_and_a0_go_never_read','interface',@()contains(gs,'p=fullfile(C.here,''G2_A1_SCIENTIFIC_GO_v1.json'');')&& ...
 ~contains(gs,'G2_LP1_SCIENTIFIC_GO')&&~contains(rs,'G2_LP1_SCIENTIFIC_GO'));
ok('runner_authorizes_before_writes','interface',@()orderOK(rs));
ok('validator_opens_no_file','interface',@()~any(contains(fileread(fullfile(here,'g2_a1_go_validate.m')),{'fileread(','fopen(','load(','isfile(','dir('})));
% ---------------------------------------------------------------- summary
kinds={rows.kind};pass=[rows.pass];neg=~strcmp({rows.expected},'true');
T=struct('schema','NewMetacomp.G2.A1.ContractTests.v1','pass',all(pass),'tests',rows,'passed',nnz(pass),'total',numel(rows), ...
 'physicalSolves',0,'negativeTestsPassed',all(pass(neg))&&nnz(neg)>=25,'exactIdentifierNegatives',true, ...
 'counts',struct('transfer',nnz(strcmp(kinds,'transfer')),'validator',nnz(strcmp(kinds,'validator')),'go',nnz(strcmp(kinds,'go')), ...
 'runner',nnz(strcmp(kinds,'runner')),'interface',nnz(strcmp(kinds,'interface'))),'testFolder',strrep(folder,repo,'<repo>'));
T.pass=T.pass&&T.negativeTestsPassed;
fprintf('G2_A1_CONTRACT_TESTS=%d/%d\n',T.passed,T.total);
if assertPass,assert(T.pass,'G2A1:ContractTests','An A1 contract test failed.');end

 function expect(name,kind,fn,id,frag)
  obs='<no error>';msgOK=false;
  try,fn();catch ME,obs=ME.identifier;msgOK=isempty(frag)||contains(ME.message,frag);end
  add(name,kind,[id,ternary(isempty(frag),'',[' | ',frag])],obs,strcmp(obs,id)&&msgOK);
 end
 function ok(name,kind,fn)
  obs='true';p=false;
  try,p=isequal(fn(),true);if ~p,obs='false';end,catch ME,obs=['<error> ',ME.identifier];end
  add(name,kind,'true',obs,p);
 end
 function gate(name,g,x,D0)
  obs='';p=false;
  try,Vx=g2_a1_mesh_validate(x,D0);p=~Vx.gates.(g);obs=sprintf('%s=%d',g,Vx.gates.(g));catch ME,obs=['<error> ',ME.identifier];end
  add(name,'validator',[g,'=0'],obs,p);
 end
 function add(name,kind,ex,obs,p)
  rows(end+1)=struct('name',name,'kind',kind,'expected',ex,'observed',obs,'pass',logical(p));
  fprintf('%s %d [%s] expected=%s observed=%s\n',name,p,kind,ex,obs);
 end
 function [G,L]=fixture(Tx)
  txt=jsonencode(Tx);
  G=struct('decision','GO_A1_PHYSICAL','reviewStatus','REVIEWED_ACCEPTED','scientificReviewer','SYNTHETIC_TEST_FIXTURE_NOT_A_REVIEW', ...
   'reviewURL','https://github.com/mfs9697/NewMetacomp/issues/66','approvedA1PolicySHA256',Cs.policySHA256, ...
   'approvedSourceSHA256',Cs.sourceSHA256,'approvedMeshManifestSHA256',Cs.meshManifestSHA256,'approvedToken',Cs.token, ...
   'contractEvidenceFile','matlab/g2/evidence/a1_preflight/SYNTHETIC.json','contractEvidenceSHA256',g2_lp1_digest(txt), ...
   'approvedRunName','run_synthetic_a1','campaignId','SYNTHETIC-A1','campaignScope','A1_S4_FAMILY_B_FIXED_PATH_MAX12');
  L=@(p)loadFixture(p,G.contractEvidenceFile,txt);
 end
end

function E=loadFixture(p,name,txt)
E=struct('exists',strcmp(p,name),'sha256','','text','');
if E.exists,E.sha256=g2_lp1_digest(txt);E.text=txt;end
end
function s=setf(s,f,v),s.(f)=v;end
function y=ternary(c,a,b),if c,y=a;else,y=b;end,end
function y=orderOK(src)
iRun=strfind(src,'if ~o.Run,return,end');iG=strfind(src,'G=g2_a1_scientific_gate(C);');iC=strfind(src,'Camp=g2_lp1_campaign_validate(');
iMk=strfind(src,'mkdir(');iW=[strfind(src,'g2_trajectory_record(''write'''),strfind(src,'g2_lp1_campaign_ledger(''write''')];
iS=strfind(src,'K=g2_m4b_sif_partial(');iA=strfind(src,'g2_lp1_admit_state(sd,');
y=isscalar(iRun)&&isscalar(iG)&&isscalar(iC)&&iRun<iG&&iG<iC&&all(iMk>iC)&&all(iW>iC)&&isscalar(iS)&&isscalar(iA)&&iA<iS;
end
