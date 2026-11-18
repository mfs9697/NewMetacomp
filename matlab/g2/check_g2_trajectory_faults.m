function T=check_g2_trajectory_faults(outDir)
%CHECK_G2_TRAJECTORY_FAULTS  WP3.4 controller fault-injection matrix F01-F23.
%
%  T = check_g2_trajectory_faults(outDir)   % outDir must not exist; it is created
% WP34_QUALIFICATION_PLAN.md section 2. Every case works on DISPOSABLE copies under
% outDir/work; the original WP3 State 1, its replay twin, State 0 and the P0 evidence
% are only read, and their SHA-256 listing is compared before/after. Each Run=true case
% uses ForbidNewComputation=true, except F15 (partial step) and F17 (arc cap), which
% stop before any mesh by construction. No PDE mesh, no FEM, no new State on the
% original chain. Cases do not abort the suite: every outcome is recorded.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
run0=fullfile(repo,'outputs','g2_wp3_state','run_20261118_185808_963');
seed=fullfile(run0,'step1_a');seedB=fullfile(run0,'step1_b');state0=fullfile(run0,'state0');
p0dir=fullfile(repo,'outputs','g2_p010_isolated','run_20261118_163657_790');
p0=fullfile(p0dir,'P010_ISOLATED_REGULAR_ONLY.mat');
outDir=char(outDir);
assert(~exist(outDir,'dir'),'G2Faults:Exists','outDir must be new: %s',outDir);mkdir(outDir);
work=fullfile(outDir,'work');mkdir(work);
originals={seed,seedB,state0,p0dir};
if isfolder(fullfile(repo,'outputs','g2_trajectory_chain_v1')),originals{end+1}=fullfile(repo,'outputs','g2_trajectory_chain_v1');end
before=hash_tree(originals);
policyFile=fullfile(here,'G2_TRAJECTORY_POLICY_v1.json');shaP=g2_sha256_file(policyFile);
auth=struct('token','CORNELL_G2_BOUNDED_NUMERICAL_V1','policySHA256',shaP,'maxStateIndex',2);
saved=path;restorePath=onCleanup(@()path(saved)); %#ok<NASGU>
[S1,rootHash]=g2_wp3_state_io('load',fullfile(seed,'state'));
p0Hash=g2_sha256_file(p0);
M=g2_mts_direction(S1.KI_MPa_sqrt_m_per_kN,S1.KII_MPa_sqrt_m_per_kN);
t=S1.t(:).';n=[-t(2),t(1)];tnew=cos(M.theta_rad)*t+sin(M.theta_rad)*n;
tip=S1.tip_mm(:).'+S1.DeltaA_mm*tnew;Pf=[S1.crackPolyline_mm;tip];
C={};
dry=@(s,p,ch)g2_trajectory_run('SeedStepDir',s,'P0Mat',p,'ChainDir',ch);
runF=@(s,p,ch,a)g2_trajectory_run('SeedStepDir',s,'P0Mat',p,'ChainDir',ch,'Run',true, ...
 'ForbidNewComputation',true,'AuthorizeNumericalMarch',a);

% ---- F02 dry preflight on true inputs (also provides the controller's source list)
ch=fullfile(work,'F02_chain');R02=[];
C{end+1}=run_case('F02','dry preflight, true inputs, absent chain',@()dry(seed,p0,ch),{'DRY_PREFLIGHT_PASS'},{ch});
try,R02=dry(seed,p0,fullfile(work,'F02b_chain'));catch,end
if ~isempty(R02)&&isfield(R02,'sourceHashes'),src=R02.sourceHashes;srcFrom='controller R.sourceHashes';
else,src=pr29_source_hashes(here);srcFrom='replica of the PR #29 list (controller exposes none)';end
fprintf('Source list for synthetic chains: %s (%d files)\n',srcFrom,numel(src));

% ---- F01 source-lock closure (D1)
c=struct('id','F01','description','every g2_* file statically reached from g2_trajectory_run is hashed', ...
 'expected',{{'CLOSED'}},'outcome','','message','','pass',false,'forbiddenPathsCreated',{{}});
try
 fl=matlab.codetools.requiredFilesAndProducts(fullfile(here,'g2_trajectory_run.m'));
 rel=strings(0);
 for k=1:numel(fl)
  [d,nm,ex]=fileparts(fl{k});
  if strcmpi(d,here),rel(end+1)=string([nm,ex]); %#ok<AGROW>
  elseif strcmpi(d,fullfile(here,'vendor_p010_a14d8872')),rel(end+1)="vendor_p010_a14d8872/"+[nm,ex];end %#ok<AGROW>
 end
 missing=setdiff(rel,string({src.file}));
 c.closure=cellstr(rel);c.missing=cellstr(missing);
 if isempty(missing),c.outcome='CLOSED';else,c.outcome='MISSING';c.message=strjoin(cellstr(missing),', ');end
 c.pass=isempty(missing);
catch ME
 c.outcome=ME.identifier;c.message=ME.message;
end
fprintf('F01 closure: %s %s -> %d\n',c.outcome,c.message,c.pass);C{end+1}=c;

% ---- F03 authorization
for a={struct(),setfield(auth,'token','WRONG'),setfield(auth,'policySHA256',repmat('0',1,64)),setfield(auth,'maxStateIndex',3)} %#ok<SFLD>
 k=numel(C);ch=fullfile(work,sprintf('F03_%d_chain',k));aa=a{1};
 C{end+1}=run_case('F03',sprintf('authorization variant %d',k),@()g2_trajectory_run('SeedStepDir',seed,'P0Mat',p0, ...
  'ChainDir',ch,'Run',true,'AuthorizeNumericalMarch',aa),{'G2Chain:AuthorizationRequired'},{ch}); %#ok<AGROW>
end
% ---- F04 step cap
ch=fullfile(work,'F04_chain');
C{end+1}=run_case('F04','MaxStateIndex 3',@()g2_trajectory_run('SeedStepDir',seed,'P0Mat',p0,'ChainDir',ch, ...
 'MaxStateIndex',3,'Run',true,'AuthorizeNumericalMarch',setfield(auth,'maxStateIndex',3)),{'G2Chain:StepCap'},{ch}); %#ok<SFLD>
% ---- F05 / F06 byte flips of the seed (copies)
s5=copy_seed(seed,fullfile(work,'F05_seed'));flip(fullfile(s5,'state','state.mat'),-200);
C{end+1}=run_case('F05','seed state byte flip',@()dry(s5,p0,fullfile(work,'F05_chain')),{'G2Chain:RootIntegrity'},{fullfile(work,'F05_chain')});
s6=copy_seed(seed,fullfile(work,'F06_seed'));flip(fullfile(s6,'KINKED_GEOMETRY_ONLY_candidate.mat'),-5000);
C{end+1}=run_case('F06','seed mesh byte flip',@()dry(s6,p0,fullfile(work,'F06_chain')),{'G2Chain:RootMeshIntegrity'},{});
% ---- F07 self-consistent forged State 1
s7=fullfile(work,'F07_seed');mkdir(s7);copyfile(fullfile(seed,'KINKED_GEOMETRY_ONLY_candidate.mat'),s7);
S7=S1;S7.note=[S1.note,' (forged copy)'];g2_wp3_state_io('save',fullfile(s7,'state'),S7);
C{end+1}=run_case('F07','re-hashed forged State 1',@()dry(s7,p0,fullfile(work,'F07_chain')),{'G2Chain:TrustedWP3Root'},{});
% ---- F08 wrong state/mesh pairing
s8=copy_seed(seed,fullfile(work,'F08_seed'));copyfile(fullfile(seedB,'KINKED_GEOMETRY_ONLY_candidate.mat'),fullfile(s8,'KINKED_GEOMETRY_ONLY_candidate.mat'),'f');
C{end+1}=run_case('F08','step1_a state with step1_b mesh',@()dry(s8,p0,fullfile(work,'F08_chain')),{'G2Chain:RootMeshIntegrity'},{});
% ---- F09 P0 byte flip
p9=fullfile(work,'F09_p0');mkdir(p9);copyfile(p0,p9);p9m=fullfile(p9,'P010_ISOLATED_REGULAR_ONLY.mat');flip(p9m,-300);
C{end+1}=run_case('F09','P0 byte flip',@()dry(seed,p9m,fullfile(work,'F09_chain')),{'G2Chain:TrustedP0'},{});
% ---- F10 shadowed vendor function
sh=fullfile(work,'F10_shadow');mkdir(sh);fid=fopen(fullfile(sh,'T3toT6_fast.m'),'w');
fprintf(fid,'function varargout=T3toT6_fast(varargin)\nerror(''shadow'');\nend\n');fclose(fid);
addpath(sh,'-begin');
C{end+1}=run_case('F10','shadowing T3toT6_fast first on path',@()dry(seed,p0,fullfile(work,'F10_chain')),{'G2Chain:VendorShadowed'},{});
rmpath(sh);
% ---- F11 missing vendor file (code copy)
g11=code_copy(here,repo,fullfile(work,'F11_code'),false);delete(fullfile(g11,'vendor_p010_a14d8872','build_twohole_literal_annulus.m'));
C{end+1}=in_copy(g11,@()run_case('F11','missing vendor file in a code copy',@()dry(seed,p0,fullfile(work,'F11_chain')),{'G2Chain:MissingVendor'},{}));
% ---- F16 seed identity (State 0 placed as a seed)
s16=fullfile(work,'F16_seed');mkdir(fullfile(s16,'state'));copyfile(fullfile(state0,'*'),fullfile(s16,'state'));
copyfile(fullfile(seed,'KINKED_GEOMETRY_ONLY_candidate.mat'),s16);
C{end+1}=run_case('F16','State 0 used as the seed',@()dry(s16,p0,fullfile(work,'F16_chain')),{'G2Chain:RootIdentity'},{});

% ---- synthetic chains (ROOT written by this test, never by the controller)
mk=@(name)make_root(fullfile(work,name),rootHash,S1.meshSHA256,p0Hash,shaP,src);
% F12 stale source hash in ROOT
srcBad=src;srcBad(1).sha256=repmat('A',1,64);ch=fullfile(work,'F12_chain');make_root(ch,rootHash,S1.meshSHA256,p0Hash,shaP,srcBad);
C{end+1}=run_case('F12','stale source hash in ROOT (dry)',@()dry(seed,p0,ch),{'G2Chain:SourceDrift'},{fullfile(ch,'STEP_002')});
C{end+1}=run_case('F12','stale source hash in ROOT (Run)',@()runF(seed,p0,ch,auth),{'G2Chain:SourceDrift'},{fullfile(ch,'STEP_002')});
% F13 ROOT byte flip
ch=mk('F13_chain');flip(fullfile(ch,'ROOT.mat'),-150);
C{end+1}=run_case('F13','ROOT byte flip (dry)',@()dry(seed,p0,ch),{'G2Chain:RootRecordIntegrity'},{fullfile(ch,'STEP_002')});
C{end+1}=run_case('F13','ROOT byte flip (Run)',@()runF(seed,p0,ch,auth),{'G2Chain:RootRecordIntegrity'},{fullfile(ch,'STEP_002')});
% F14 chain folder without ROOT
ch=fullfile(work,'F14_chain');mkdir(ch);
C{end+1}=run_case('F14','chain without ROOT manifest (Run)',@()runF(seed,p0,ch,auth),{'G2Chain:PartialChain'},{fullfile(ch,'ROOT.mat')});
% F15 partial step folder
ch=mk('F15_chain');mkdir(fullfile(ch,'STEP_002'));
C{end+1}=run_case('F15','partial STEP_002 (dry)',@()dry(seed,p0,ch),{'HOLD_PARTIAL_STEP'},{fullfile(ch,'STEP_002','REVIEW.mat')});
C{end+1}=run_case('F15','partial STEP_002 (Run, no ForbidNewComputation)',@()g2_trajectory_run('SeedStepDir',seed,'P0Mat',p0, ...
 'ChainDir',ch,'Run',true,'AuthorizeNumericalMarch',auth),{'G2Chain:PartialStep'}, ...
 {fullfile(ch,'STEP_002','REVIEW.mat'),fullfile(ch,'STEP_002','KINKED_GEOMETRY_ONLY_candidate.mat'),fullfile(ch,'STEP_002','HOLD.mat')});
% F18 valid chain, new computation forbidden
ch=mk('F18_chain');
C{end+1}=run_case('F18','valid ROOT, Run with ForbidNewComputation',@()runF(seed,p0,ch,auth),{'HOLD_NEW_COMPUTATION_FORBIDDEN'},{fullfile(ch,'STEP_002')});
% F19 / F20 / F21 forged reviews
mesh1=fullfile(seed,'KINKED_GEOMETRY_ONLY_candidate.mat');
ch=mk('F19_chain');forge_review(fullfile(ch,'STEP_002'),mesh1,S1,rootHash,shaP,src,p0Hash,Pf,tnew,M.theta_deg,'codgap');
C{end+1}=run_case('F19','review with fabricated pass but COD/EDI 10% apart (Run)',@()runF(seed,p0,ch,auth),{'G2Chain:ReviewNumericScreens'},{fullfile(ch,'STEP_002','state')});
ch=mk('F20_chain');forge_review(fullfile(ch,'STEP_002'),mesh1,S1,rootHash,shaP,src,p0Hash,Pf,tnew,M.theta_deg,'consistent');
C{end+1}=run_case('F20','forged review citing the State 1 mesh (dry)',@()dry(seed,p0,ch),{'G2Chain:ReviewMeshContent'},{fullfile(ch,'STEP_002','state')});
C{end+1}=run_case('F20','forged review citing the State 1 mesh (Run)',@()runF(seed,p0,ch,auth),{'G2Chain:ReviewMeshContent'},{fullfile(ch,'STEP_002','state')});
ch=mk('F21_chain');forge_review(fullfile(ch,'STEP_002'),mesh1,S1,rootHash,shaP,src,p0Hash,Pf,tnew,M.theta_deg,'tipshift');
C{end+1}=run_case('F21','review tip shifted 1e-6 mm (dry)',@()dry(seed,p0,ch),{'G2Chain:ForecastDrift'},{fullfile(ch,'STEP_002','state')});
C{end+1}=run_case('F21','review tip shifted 1e-6 mm (Run)',@()runF(seed,p0,ch,auth),{'G2Chain:ForecastDrift'},{fullfile(ch,'STEP_002','state')});

% ---- F17 arc cap in a committed code copy whose policy has maxArcLength_mm = 33.0
g17=code_copy(here,repo,fullfile(work,'F17_code'),false);
pf=fullfile(g17,'G2_TRAJECTORY_POLICY_v1.json');txt=fileread(pf);
txt2=strrep(txt,'"maxArcLength_mm": 33.4','"maxArcLength_mm": 33.0');assert(~strcmp(txt,txt2),'G2Faults:ArcEdit','Policy edit failed.');
fid=fopen(pf,'w');fwrite(fid,txt2,'char');fclose(fid);git_commit(fileparts(fileparts(g17)));
a17=setfield(auth,'policySHA256',g2_sha256_file(pf)); %#ok<SFLD>
ch=fullfile(work,'F17_chain');
C{end+1}=in_copy(g17,@()run_case('F17','arc cap 33.0 mm in a code copy (Run)',@()g2_trajectory_run('SeedStepDir',seed,'P0Mat',p0, ...
 'ChainDir',ch,'Run',true,'AuthorizeNumericalMarch',a17),{'ARC_CAP'},{fullfile(ch,'STEP_002')}));
% ---- F22 dirty kernel in a committed code copy (ROOT pre-made so the pre-fix code cannot mesh)
g22=code_copy(here,repo,fullfile(work,'F22_code'),false);git_commit(fileparts(fileparts(g22)));
fid=fopen(fullfile(g22,'g2_trajectory_sif_on_mesh.m'),'a');fprintf(fid,'\n%% uncommitted drift (WP3.4 F22)\n');fclose(fid);
src22=in_copy(g22,@()source_of(g22,seed,p0,fullfile(work,'F22_probe')));
ch=fullfile(work,'F22_chain');make_root(ch,rootHash,S1.meshSHA256,p0Hash,shaP,src22);
C{end+1}=in_copy(g22,@()run_case('F22','uncommitted kernel change (Run)',@()runF(seed,p0,ch,auth),{'G2Chain:DirtySource'},{fullfile(ch,'STEP_002'),fullfile(ch,'RUN_*.log')}));
% ---- F23 chain inside the seed or the P0 folder (copies)
s23=copy_seed(seed,fullfile(work,'F23_seed'));p23=fullfile(work,'F23_p0');mkdir(p23);copyfile(p0,p23);p23m=fullfile(p23,'P010_ISOLATED_REGULAR_ONLY.mat');
C{end+1}=run_case('F23','chain equal to the seed folder (Run)',@()runF(s23,p0,s23,auth),{'G2Chain:SelfReference'},{fullfile(s23,'ROOT.mat')});
C{end+1}=run_case('F23','chain inside the seed folder (Run)',@()runF(s23,p0,fullfile(s23,'chain'),auth),{'G2Chain:SelfReference'},{fullfile(s23,'chain')});
C{end+1}=run_case('F23','chain inside the P0 folder (Run)',@()runF(seed,p23m,fullfile(p23,'chain'),auth),{'G2Chain:SelfReference'},{fullfile(p23,'chain')});

% ---- F24 POSITIVE promotion path (SYNTHETIC K, NOT A RESULT). Uses a COPY of the genuine
% four-vertex mesh saved by the first State 2 attempt (HOLD-1, 34/34 audited) so that the
% review re-audit, local_child_state (D7), State save and State reuse code paths run in
% MATLAB before any new numerical attempt. All K values in this review are fabricated.
hm=fullfile(repo,'outputs','g2_trajectory_chain_v1','STEP_002','KINKED_GEOMETRY_ONLY_candidate.mat');
if isfile(hm)
 Dh=load(hm);Ch=g2_kinked_mesh_auditor(Dh,fullfile(repo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json'),p0,4);
 ch=mk('F24_chain');forge_review(fullfile(ch,'STEP_002'),hm,S1,rootHash,shaP,src,p0Hash,Pf,tnew,M.theta_deg,'consistent');
 rf=fullfile(ch,'STEP_002','REVIEW.mat');[rv,~,okr]=g2_trajectory_record('read',rf);assert(okr);
 delete(rf);delete([rf,'.manifest.json']);
 rv.geometrySummary=Ch.summary;rv.meshSummary=struct('T3elements',Ch.summary.T3elements,'minAngle_deg',Ch.summary.minAngle_deg, ...
  'maxNeighborRatio',Ch.summary.maxNeighborRatio);rv.note='SYNTHETIC K - WP3.4 F24 code-path test only, not a result';
 g2_trajectory_record('write',rf,rv);
 c=run_case('F24','synthetic positive promotion on the genuine 4-vertex mesh copy (Run)',@()runF(seed,p0,ch,auth),{'STEP_CAP'},{fullfile(ch,'STEP_003')});
 st=fullfile(ch,'STEP_002','state');okState=false;
 if isfolder(st)
  [S2,~,oks]=g2_wp3_state_io('load',st);
  okState=oks&&S2.stateIndex==2&&~isfield(S2,'KI_fullPrecisionWP2')&&startsWith(S2.Ksource,'g2_trajectory_sif_on_mesh')&& ...
   ~S2.physicalFractureGrowthProven&&~S2.tipAccepted&&isequal(S2.crackPolyline_mm,Pf);
  c.state2Fields=fieldnames(S2);
 end
 c.auditOfHoldMesh=sprintf('%d/%d',Ch.gatesPassed,Ch.gatesTotal);c.holdMeshSHA256=g2_sha256_file(hm);
 c.pass=c.pass&&c.reviewsReused==1&&c.newStatesCreated==0&&okState&&Ch.pass;
 fprintf('F24 promotion: reviewsReused %g, State 2 fields OK %d, hold-mesh audit %s -> %d\n',c.reviewsReused,okState,c.auditOfHoldMesh,c.pass);
 C{end+1}=c;
 C{end+1}=run_case('F24','rerun of the synthetic chain reuses State 2 (Run)',@()runF(seed,p0,ch,auth),{'STEP_CAP'},{fullfile(ch,'STEP_003')});
 C{end}.pass=C{end}.pass&&C{end}.statesReused==1&&C{end}.newStatesCreated==0;
 C{end+1}=run_case('F24','dry preflight of the synthetic chain',@()dry(seed,p0,ch),{'DRY_PREFLIGHT_STEP_CAP'},{fullfile(ch,'STEP_003')});
end

after=hash_tree(originals);
origOK=isequal(before,after);
ok=cellfun(@(c)c.pass,C);
T=struct('pass',all(ok)&&origOK,'originalsUnchanged',origOK,'nCases',numel(C), ...
 'nPass',nnz(ok),'sourceListFrom',srcFrom,'failedCases',{cellfun(@(c)sprintf('%s: %s -> %s',c.id,c.description,c.outcome),C(~ok),'UniformOutput',false)});
T.cases=C;
fprintf('G2_TRAJECTORY_FAULTS_CASES=%d PASSED=%d ORIGINALS_UNCHANGED=%d\n',T.nCases,T.nPass,origOK);
fprintf('G2_TRAJECTORY_FAULTS_PASS=%d\n',T.pass);
end

% ======================================================================
function c=run_case(id,desc,fn,expected,mustNotExist)
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
made={};
for k=1:numel(mustNotExist)
 if ~isempty(dir(mustNotExist{k})),made{end+1}=mustNotExist{k};end %#ok<AGROW>
end
c.forbiddenPathsCreated=made;
c.pass=any(strcmp(c.outcome,expected))&&isempty(made);
fprintf('%s %s: outcome=%s | expected=%s | forbidden created=%d -> %d\n',id,desc,c.outcome, ...
 strjoin(expected,'|'),numel(made),c.pass);
if ~c.pass&&~isempty(c.message),fprintf('   message: %s\n',strtok(c.message,newline));end
end

function out=in_copy(g,fn)
p=path;c=onCleanup(@()path(p)); %#ok<NASGU>
addpath(fullfile(g,'vendor_p010_a14d8872'),'-begin');addpath(g,'-begin');
out=fn();
end

function d=copy_seed(seed,d)
mkdir(d);copyfile(fullfile(seed,'*'),d);
end

function flip(file,offset)
fid=fopen(file,'r+');fseek(fid,offset,'eof');b=fread(fid,1,'*uint8');fseek(fid,offset,'eof');
fwrite(fid,bitxor(b,uint8(1)));fclose(fid);
end

function H=hash_tree(dirs)
H=cell(0,2);
for i=1:numel(dirs)
 f=dir(fullfile(dirs{i},'**','*'));f=f(~[f.isdir]);
 for k=1:numel(f),p=fullfile(f(k).folder,f(k).name);H(end+1,:)={p,g2_sha256_file(p)};end %#ok<AGROW>
end
H=sortrows(H,1);
end

function chain=make_root(chain,rootHash,meshHash,p0Hash,shaP,src)
mkdir(chain);
Root=struct('schema','NewMetacomp.G2.TrajectoryRoot.v1','stateIndex',1,'rootHash',rootHash, ...
 'rootMeshHash',meshHash,'p0SHA256',p0Hash,'policySHA256',shaP,'sourceHashes',src, ...
 'seedDirectory','<written by check_g2_trajectory_faults>','numericalOnly',true,'physicalFractureGrowthProven',false);
g2_trajectory_record('write',fullfile(chain,'ROOT.mat'),Root);
end

function forge_review(stepDir,meshSrc,S1,rootHash,shaP,src,p0Hash,Pf,tnew,theta_deg,mode)
mkdir(stepDir);mf=fullfile(stepDir,'KINKED_GEOMETRY_ONLY_candidate.mat');copyfile(meshSrc,mf);
mh=g2_sha256_file(mf);
mat=struct('E',S1.bvp.E_MPa,'nu',S1.bvp.nu,'plane',S1.bvp.plane);[~,Ep]=g2_plane_D(mat);
KI=S1.KI_raw;KII=.1*S1.KII_raw;J=(KI^2+KII^2)/Ep;KIc=KI;if strcmp(mode,'codgap'),KIc=.9*KI;end
crit=struct('elasticEquilibrium',true,'blindCODversusEDI',true,'contourIndependence',true,'JenergyIdentity',true, ...
 'EDIquadrature',true,'qSupportInsideCore',true,'wholeCrackOpening',true,'KIpositive',true,'conditionalHighMixityKIIagreement',true);
sif=struct('pass',true,'status','TRAJECTORY_NUMERICAL_SIF_VERIFIED','criteria',crit,'failedCriteria',{{}}, ...
 'KI',KI,'KII',KII,'J',J,'KI_COD',KIc,'KII_COD',KII,'KI_MPa_sqrt_m_per_kN',KI*sqrt(1000), ...
 'KII_MPa_sqrt_m_per_kN',KII*sqrt(1000),'fullPolyOpeningMin_mm',0,'KII_sign_edi_vs_cod_match',true, ...
 'qSupportMaxRadius_mm',2.769,'relativeResidual',1e-12,'staticsMax',1e-12,'EDI_all',repmat([KI KII J],5,1), ...
 'physicalFractureGrowthProven',false);
P=Pf;if strcmp(mode,'tipshift'),P(end,1)=P(end,1)+1e-6;end
rev=struct('schema','NewMetacomp.G2.TrajectoryReview.v1','stateIndex',2,'parentStateSHA256',rootHash, ...
 'policySHA256',shaP,'sourceHashes',src,'p0SHA256',p0Hash,'meshFile','KINKED_GEOMETRY_ONLY_candidate.mat', ...
 'meshSHA256',mh,'polyline_mm',P,'tip_mm',P(end,:),'tangent',tnew,'localTurn_deg',theta_deg,'forecast',struct(), ...
 'geometryGateCount',34,'geometryGatesPassed',34,'geometryPass',true,'geometrySummary',struct('T3elements',28421), ...
 'meshJoinPass',true,'meshSummary',struct('T3elements',28421,'minAngle_deg',30.1268,'maxNeighborRatio',1.59183), ...
 'sif',sif,'sifPass',true,'numericallyQualified',true,'physicalFractureGrowthProven',false,'tipAccepted',false, ...
 'eligibleForAutomaticPhysicalAcceptance',false);
g2_trajectory_record('write',fullfile(stepDir,'REVIEW.mat'),rev);
end

function g=code_copy(here,repo,dst,~)
g=fullfile(dst,'matlab','g2');mkdir(fullfile(g,'vendor_p010_a14d8872'));
copyfile(fullfile(here,'*.m'),g);copyfile(fullfile(here,'*.json'),g);
copyfile(fullfile(here,'vendor_p010_a14d8872','*.m'),fullfile(g,'vendor_p010_a14d8872'));
jd=fullfile(dst,'docs','research','crack-growth-gaps-2026');mkdir(jd);
copyfile(fullfile(repo,'docs','research','crack-growth-gaps-2026','G2_SPECIMEN1_1990_GEOMETRY.json'),jd);
end

function git_commit(root)
cmd=sprintf(['git -C "%s" init -q && git -C "%s" -c core.autocrlf=false add -A && git -C "%s" ' ...
 '-c core.autocrlf=false -c user.name=wp34-test -c user.email=wp34-test@example.invalid commit -q -m test'],root,root,root);
[st,out]=system(cmd);assert(st==0,'G2Faults:Git','git init/commit failed: %s',out);
end

function src=source_of(g,seed,p0,probe)
R=g2_trajectory_run('SeedStepDir',seed,'P0Mat',p0,'ChainDir',probe);
if isfield(R,'sourceHashes'),src=R.sourceHashes;else,src=pr29_source_hashes(g);end
end

function H=pr29_source_hashes(here)
% Exact replica of the PR #29 (49daa2e) local_source_hashes list, used only when the
% controller under test does not expose its own list.
names={'g2_trajectory_run.m','g2_trajectory_record.m','g2_trajectory_sif_on_mesh.m','g2_kink_admissibility.m', ...
 'g2_kinked_join.m','g2_kinked_exterior_mesh.m','g2_kinked_regular_block.m','g2_kinked_mesh_auditor.m', ...
 'g2_mts_direction.m','g2_polyline_frame.m','g2_sif_interaction.m','g2_sif_cod_banks.m','g2_t6_elasticity.m', ...
 'g2_plane_D.m','g2_independent_t6_jacobian.m','g2_wp3_state_io.m','g2_sha256_file.m'};
vn={'build_m1i_trial_tip_annulus_p010.m','build_m1i_trial_tip_disk_p010.m','build_twohole_literal_annulus.m', ...
 'cut_twohole_literal_annulus.m','T3toT6_fast.m','main_m1i_increment_ring_geometry_only.m'};
H=repmat(struct('file','','sha256',''),numel(names)+numel(vn),1);
for j=1:numel(names),H(j).file=names{j};H(j).sha256=g2_sha256_file(fullfile(here,names{j}));end
for j=1:numel(vn)
 H(numel(names)+j).file=['vendor_p010_a14d8872/',vn{j}];
 H(numel(names)+j).sha256=g2_sha256_file(fullfile(here,'vendor_p010_a14d8872',vn{j}));
end
end
