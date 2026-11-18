function W=run_g2_wp34_restart_batch(acceptedChain)
%RUN_G2_WP34_RESTART_BATCH  WP3.4 stage E: restart, interruption, tamper, replay (E1-E13).
%  W = run_g2_wp34_restart_batch(acceptedChain)
% WP34_QUALIFICATION_PLAN.md section 5. The accepted chain is ONLY read (SHA-256
% listing compared before/after). E1/E3 build fresh disposable chains (one mesh+FEM
% each, needed to exercise the real interrupt hook and deterministic replay); every
% other case runs on a copy with ForbidNewComputation=true. Writes a NEW
% outputs/g2_wp34_restart/run_<time>/ folder.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
seed=fullfile(repo,'outputs','g2_wp3_state','run_20261118_185808_963','step1_a');
p0=fullfile(repo,'outputs','g2_p010_isolated','run_20261118_163657_790','P010_ISOLATED_REGULAR_ONLY.mat');
A=char(acceptedChain);
outRoot=fullfile(repo,'outputs','g2_wp34_restart');if ~exist(outRoot,'dir'),mkdir(outRoot);end
folder=fullfile(outRoot,['run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);assert(~exist(folder,'dir'));mkdir(folder);
diary(fullfile(folder,'restart_console.log'));cl=onCleanup(@()diary('off')); %#ok<NASGU>
[~,head]=system(sprintf('git -C "%s" rev-parse HEAD',repo));
fprintf('STAGE=G2_WP34_E_RESTART\nDATE=%s\nMATLAB_RELEASE=%s\nGIT_HEAD=%s\nACCEPTED_CHAIN=%s\n',datestr(now,31),version('-release'),strtrim(head),A);
shaP=g2_sha256_file(fullfile(here,'G2_TRAJECTORY_POLICY_v1.json'));
auth=struct('token','CORNELL_G2_BOUNDED_NUMERICAL_V1','policySHA256',shaP,'maxStateIndex',2);
beforeA=hash_tree(A);beforeSeed=hash_tree(seed);
W=struct('pass',false,'cases',{{}},'replay',struct(),'exception','');C={};
run=@(ch,varargin)g2_trajectory_run('SeedStepDir',seed,'P0Mat',p0,'ChainDir',ch,'Run',true,'AuthorizeNumericalMarch',auth,varargin{:});
dry=@(ch)g2_trajectory_run('SeedStepDir',seed,'P0Mat',p0,'ChainDir',ch);
try
 % ---- E1 fresh chain, interrupt after the immutable review
 e1=fullfile(folder,'E1_chain');t=tic;
 C{end+1}=run_case('E1','fresh chain, SimulateInterrupt review@2',@()run(e1,'SimulateInterrupt',struct('point','review','step',2)), ...
  {'G2Chain:SimulatedInterrupt'},{fullfile(e1,'STEP_002','state')},{fullfile(e1,'STEP_002','REVIEW.mat')});
 C{end}.seconds=toc(t);
 % ---- E2 resume: promote the verified review, no mesh/FEM
 t=tic;R2=[];
 C{end+1}=run_case('E2','resume E1 with ForbidNewComputation',@()run(e1,'ForbidNewComputation',true),{'STEP_CAP'},{},{fullfile(e1,'STEP_002','state','state.mat')});
 C{end}.seconds=toc(t);
 C{end}.pass=C{end}.pass&&C{end}.reviewsReused==1&&C{end}.newStatesCreated==0;
 % ---- E3 fresh chain, interrupt after the State, then rerun (reuse)
 e3=fullfile(folder,'E3_chain');t=tic;
 C{end+1}=run_case('E3a','fresh chain, SimulateInterrupt state@2',@()run(e3,'SimulateInterrupt',struct('point','state','step',2)), ...
  {'G2Chain:SimulatedInterrupt'},{},{fullfile(e3,'STEP_002','state','state.mat')});
 C{end}.seconds=toc(t);t=tic;
 C{end+1}=run_case('E3b','rerun E3 with ForbidNewComputation',@()run(e3,'ForbidNewComputation',true),{'STEP_CAP'},{},{});
 C{end}.seconds=toc(t);
 C{end}.pass=C{end}.pass&&C{end}.statesReused==1&&C{end}.newStatesCreated==0;
 % ---- E4 deterministic replay against the accepted chain
 W.replay=struct('E1',compare_chain(A,e1),'E3',compare_chain(A,e3));
 C{end+1}=struct('id','E4','description','E1/E3 mesh arrays, banks and K bit-identical to the accepted chain', ...
  'expected',{{'IDENTICAL'}},'outcome','','message','','pass',W.replay.E1.identical&&W.replay.E3.identical, ...
  'forbiddenPathsCreated',{{}},'newStatesCreated',NaN,'reviewsReused',NaN,'statesReused',NaN);
 if C{end}.pass,C{end}.outcome='IDENTICAL';else,C{end}.outcome='DIFFERENT';end
 fprintf('E4 replay: E1 identical %d, E3 identical %d\n',W.replay.E1.identical,W.replay.E3.identical);
 % ---- E5 rerun a copy of the accepted chain: STEP_CAP, no State 3, only a run log added
 e5=copy_chain(A,fullfile(folder,'E5_chain'));b5=hash_tree(e5);
 C{end+1}=run_case('E5','rerun accepted-chain copy',@()run(e5,'ForbidNewComputation',true),{'STEP_CAP'},{fullfile(e5,'STEP_003')},{});
 a5=hash_tree(e5);added=setdiff(a5(:,1),b5(:,1));changed=intersect(b5(:,1),a5(:,1));
 sameOld=isequal(b5,a5(ismember(a5(:,1),b5(:,1)),:));
 C{end}.addedFiles=strrep(added,e5,'<E5>');C{end}.oldFilesUnchanged=sameOld;
 C{end}.pass=C{end}.pass&&C{end}.statesReused==1&&sameOld&&all(contains(added,'RUN_'))&&numel(changed)==size(b5,1);
 C{end+1}=run_case('E5b','accepted-chain copy, MaxStateIndex 3',@()g2_trajectory_run('SeedStepDir',seed,'P0Mat',p0,'ChainDir',e5, ...
  'MaxStateIndex',3,'Run',true,'AuthorizeNumericalMarch',setfield(auth,'maxStateIndex',3)),{'G2Chain:StepCap'},{fullfile(e5,'STEP_003')},{}); %#ok<SFLD>
 % ---- E6 State tamper
 e6=copy_chain(A,fullfile(folder,'E6_chain'));flip(fullfile(e6,'STEP_002','state','state.mat'),-200);
 C{end+1}=run_case('E6a','State 2 byte flip (Run)',@()run(e6,'ForbidNewComputation',true),{'G2Chain:ChildStateIntegrity'},{fullfile(e6,'STEP_003')},{});
 C{end+1}=run_case('E6b','State 2 byte flip (dry)',@()dry(e6),{'G2Chain:ChildIntegrity'},{},{});
 e6c=copy_chain(A,fullfile(folder,'E6c_chain'));fid=fopen(fullfile(e6c,'STEP_002','state','state.sha256'),'w');fprintf(fid,'%s *state.mat\n',repmat('0',1,64));fclose(fid);
 C{end+1}=run_case('E6c','wrong state.sha256 (Run)',@()run(e6c,'ForbidNewComputation',true),{'G2Chain:ChildStateIntegrity'},{},{});
 % ---- E7 review missing
 e7=copy_chain(A,fullfile(folder,'E7_chain'));delete(fullfile(e7,'STEP_002','REVIEW.mat'));
 C{end+1}=run_case('E7a','review missing, State kept (Run)',@()run(e7,'ForbidNewComputation',true),{'G2Chain:ChildReviewIntegrity'},{},{});
 C{end+1}=run_case('E7b','review missing, State kept (dry)',@()dry(e7),{'G2Chain:ReviewIntegrity'},{},{});
 % ---- E8 review byte flip
 e8=copy_chain(A,fullfile(folder,'E8_chain'));flip(fullfile(e8,'STEP_002','REVIEW.mat'),-300);
 C{end+1}=run_case('E8','review byte flip (Run)',@()run(e8,'ForbidNewComputation',true),{'G2Chain:ChildReviewIntegrity'},{},{});
 % ---- E9 mesh byte flip
 e9=copy_chain(A,fullfile(folder,'E9_chain'));flip(fullfile(e9,'STEP_002','KINKED_GEOMETRY_ONLY_candidate.mat'),-5000);
 C{end+1}=run_case('E9','State 2 mesh byte flip (Run)',@()run(e9,'ForbidNewComputation',true),{'G2Chain:ReviewMeshSHA'},{},{});
 % ---- E10 re-parented State 2 (re-hashed)
 e10=copy_chain(A,fullfile(folder,'E10_chain'));sd=fullfile(e10,'STEP_002','state');
 S=load(fullfile(sd,'state.mat'));S=S.state;S.parentStateSHA256=repmat('a',1,64);rmdir(sd,'s');g2_wp3_state_io('save',sd,S);
 C{end+1}=run_case('E10','State 2 with a forged parent hash (Run)',@()run(e10,'ForbidNewComputation',true),{'G2Chain:ChildMismatch'},{},{});
 % ---- E11 source / policy drift in a re-manifested ROOT
 e11=copy_chain(A,fullfile(folder,'E11_chain'));rewrite_root(e11,'source');
 C{end+1}=run_case('E11a','ROOT source hash drift (Run)',@()run(e11,'ForbidNewComputation',true),{'G2Chain:SourceDrift'},{},{});
 C{end+1}=run_case('E11b','ROOT source hash drift (dry)',@()dry(e11),{'G2Chain:SourceDrift'},{},{});
 e11p=copy_chain(A,fullfile(folder,'E11p_chain'));rewrite_root(e11p,'policy');
 C{end+1}=run_case('E11c','ROOT policy hash drift (Run)',@()run(e11p,'ForbidNewComputation',true),{'G2Chain:SourceDrift'},{},{});
 % ---- E13 incomplete State folder (state.sha256 missing)
 e13=copy_chain(A,fullfile(folder,'E13_chain'));delete(fullfile(e13,'STEP_002','state','state.sha256'));
 C{end+1}=run_case('E13','State folder without state.sha256 (Run)',@()run(e13,'ForbidNewComputation',true),{'G2Chain:ChildStateIntegrity'},{},{});
 % ---- E12 dry preflight on the accepted chain itself (read only)
 C{end+1}=run_case('E12','dry preflight on the accepted chain',@()dry(A),{'DRY_PREFLIGHT_STEP_CAP'},{fullfile(A,'STEP_003')},{});
catch ME
 W.exception=getReport(ME,'extended','hyperlinks','off');fprintf(2,'G2_WP34_RESTART_EXCEPTION=%s\n',W.exception);
end
afterA=hash_tree(A);afterSeed=hash_tree(seed);
W.acceptedChainUnchanged=isequal(beforeA,afterA);W.seedUnchanged=isequal(beforeSeed,afterSeed);
fprintf('ACCEPTED_CHAIN_UNCHANGED=%d SEED_UNCHANGED=%d\n',W.acceptedChainUnchanged,W.seedUnchanged);
W.cases=C;ok=cellfun(@(c)c.pass,C);
W.pass=isempty(W.exception)&&all(ok)&&numel(C)>=20&&W.acceptedChainUnchanged&&W.seedUnchanged;
W.failedCases=cellfun(@(c)sprintf('%s: %s -> %s',c.id,c.description,c.outcome),C(~ok),'UniformOutput',false);
f=fopen(fullfile(folder,'restart_summary.json'),'w');fwrite(f,jsonencode(W,'PrettyPrint',true),'char');fclose(f);
fprintf('G2_WP34_RESTART_CASES=%d PASSED=%d\nG2_WP34_RESTART_PASS=%d\nOUTDIR=%s\n',numel(C),nnz(ok),W.pass,folder);
if ~W.pass,error('G2WP34:RestartHOLD','WP3.4 stage E HOLD (see %s).',folder);end
end

% ======================================================================
function c=run_case(id,desc,fn,expected,mustNotExist,mustExist)
c=struct('id',id,'description',desc,'expected',{expected},'outcome','','message','','pass',false, ...
 'forbiddenPathsCreated',{{}},'newStatesCreated',NaN,'reviewsReused',NaN,'statesReused',NaN);
L=get(0,'DiaryFile');on=strcmp(get(0,'Diary'),'on');
try
 R=fn();c.outcome=R.stage;c.message=R.message;
 c.newStatesCreated=R.newStatesCreated;c.reviewsReused=R.reviewsReused;c.statesReused=R.statesReused;
catch ME
 c.outcome=ME.identifier;c.message=ME.message;
end
if on,diary(L);end % the controller's run-log diary switches the caller's diary off
made={};for k=1:numel(mustNotExist),if ~isempty(dir(mustNotExist{k})),made{end+1}=mustNotExist{k};end,end %#ok<AGROW>
miss={};for k=1:numel(mustExist),if ~isfile(mustExist{k}),miss{end+1}=mustExist{k};end,end %#ok<AGROW>
c.forbiddenPathsCreated=made;c.requiredPathsMissing=miss;
c.pass=any(strcmp(c.outcome,expected))&&isempty(made)&&isempty(miss);
fprintf('%s %s: outcome=%s | expected=%s | reused review/state %g/%g new %g -> %d\n',id,desc,c.outcome, ...
 strjoin(expected,'|'),c.reviewsReused,c.statesReused,c.newStatesCreated,c.pass);
if ~c.pass&&~isempty(c.message),fprintf('   message: %s\n',strtok(c.message,newline));end
end

function Q=compare_chain(A,B)
ma=load(fullfile(A,'STEP_002','KINKED_GEOMETRY_ONLY_candidate.mat'));mb=load(fullfile(B,'STEP_002','KINKED_GEOMETRY_ONLY_candidate.mat'));
f={'X3','T3','X6','T6','upperBankT6','lowerBankT6','physicalTipNode','nodalQ','crackPolyline','tipTangent','kinkNodeIDs'};
same=cellfun(@(k)isequal(ma.(k),mb.(k)),f);
sa=load(fullfile(A,'STEP_002','state','state.mat'));sb=load(fullfile(B,'STEP_002','state','state.mat'));sa=sa.state;sb=sb.state;
kf={'KI_raw','KII_raw','KI_MPa_sqrt_m_per_kN','KII_MPa_sqrt_m_per_kN','KI_COD_MPa_sqrt_m_per_kN','KII_COD_MPa_sqrt_m_per_kN','tip_mm','t'};
sameK=cellfun(@(k)isequal(sa.(k),sb.(k)),kf);
ra=load(fullfile(A,'STEP_002','REVIEW.mat'));rb=load(fullfile(B,'STEP_002','REVIEW.mat'));
Q=struct('meshFieldsIdentical',all(same),'differingMeshFields',{f(~same)},'KfieldsIdentical',all(sameK), ...
 'differingKFields',{kf(~sameK)},'EDIallIdentical',isequal(ra.record.sif.EDI_all,rb.record.sif.EDI_all), ...
 'meshFileBytesIdentical',strcmpi(g2_sha256_file(fullfile(A,'STEP_002','KINKED_GEOMETRY_ONLY_candidate.mat')), ...
   g2_sha256_file(fullfile(B,'STEP_002','KINKED_GEOMETRY_ONLY_candidate.mat'))), ...
 'createdA',sa.created,'createdB',sb.created);
Q.identical=Q.meshFieldsIdentical&&Q.KfieldsIdentical&&Q.EDIallIdentical;
end

function d=copy_chain(A,d)
mkdir(d);copyfile(fullfile(A,'*'),d);
end

function rewrite_root(ch,what)
[Root,~,ok]=g2_trajectory_record('read',fullfile(ch,'ROOT.mat'));assert(ok);
delete(fullfile(ch,'ROOT.mat'));delete(fullfile(ch,'ROOT.mat.manifest.json'));
if strcmp(what,'source'),Root.sourceHashes(3).sha256=repmat('B',1,64);else,Root.policySHA256=repmat('C',1,64);end
g2_trajectory_record('write',fullfile(ch,'ROOT.mat'),Root);
end

function flip(file,offset)
fid=fopen(file,'r+');fseek(fid,offset,'eof');b=fread(fid,1,'*uint8');fseek(fid,offset,'eof');
fwrite(fid,bitxor(b,uint8(1)));fclose(fid);
end

function H=hash_tree(d)
f=dir(fullfile(d,'**','*'));f=f(~[f.isdir]);H=cell(numel(f),2);
for k=1:numel(f),p=fullfile(f(k).folder,f(k).name);H(k,:)={p,g2_sha256_file(p)};end
H=sortrows(H,1);
end
