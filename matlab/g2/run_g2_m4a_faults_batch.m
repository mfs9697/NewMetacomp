function T = run_g2_m4a_faults_batch()
%RUN_G2_M4A_FAULTS_BATCH  G2-M4.A tamper, restart, interrupt and replay suite (Issue #44).
%
% All cases act on DISPOSABLE copies under outputs/g2_m4_alt_family_v1/faults_run_<time>/work;
% the accepted PR #41 chains, the accepted S0ALT and the three accepted alternative chains are
% hashed before and after and must be unchanged. Each case states the expected refusal
% identifier or the expected safe behaviour.
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
root=fullfile(repo,'outputs','g2_m4_alt_family_v1');
folder=fullfile(root,['faults_run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);assert(~exist(folder,'dir'));mkdir(folder);
work=fullfile(folder,'work');mkdir(work);
diary(fullfile(folder,'m4a_faults_console.log'));cl=onCleanup(@()diary('off')); %#ok<NASGU>
pol=jsondecode(fileread(fullfile(here,'G2_M4_POLICY_v1.json')));
polSHA=upper(g2_sha256_file(fullfile(here,'G2_M4_POLICY_v1.json')));fam=pol.altFamily.id;
tok=@(m)sprintf('G2M4ARUN|%s|%s|family=%s|maxState=2',polSHA,m,fam);
acc=@(m)fullfile(root,['chain_',m,'_alt_v1']);s0acc=fullfile(root,'S0ALT');
o41=@(m)fullfile(repo,'outputs','g2_material_trajectories_v1',['chain_',m,'_v1']);
before=[tree(acc('homogeneous'));tree(acc('soft'));tree(acc('stiff'));tree(s0acc);tree(o41('soft'));tree(o41('stiff'))];
cases=struct('id',{},'expect',{},'observed',{},'pass',{},'note',{});
run=@(m,c,varargin)g2_m4a_trajectory_run('Material',m,'ChainDir',c,varargin{:});
% ---- F01 dry on a complete copy: STEP_CAP, no writes
c=cp(acc('soft'),work,'F01_soft');h0=tree(c);R=run('soft',c);
cases=add(cases,'F01_dry_no_writes','STEP_CAP, tree identical',sprintf('%s, same %d',R.stage,isequal(h0,tree(c))),strcmp(R.stage,'STEP_CAP')&&isequal(h0,tree(c)));
% ---- F02 run on a complete copy: both states reused without FEM
c=cp(acc('homogeneous'),work,'F02_homogeneous');h0=tree(c);R=run('homogeneous',c,'Run',true,'AuthToken',tok('homogeneous'));
cases=add(cases,'F02_run_reuses_states_no_FEM','reused 2, computed 0, tree identical',sprintf('reused %d computed %d same %d',R.statesReused,R.statesComputed,isequal(h0,tree(c))), ...
 R.statesReused==2&&R.statesComputed==0&&isequal(h0,tree(c)));
% ---- S0ALT dry writes nothing / never overwritten
d0=dir(root);R=g2_m4a_s0alt('Mode','build');d1=dir(root);
cases=add(cases,'F03a_S0ALT_dry_no_writes','DRY_S0ALT_NO_FILES, root listing unchanged',sprintf('%s, same %d',R.stage,isequal({d0.name},{d1.name})),strcmp(R.stage,'DRY_S0ALT_NO_FILES')&&isequal({d0.name},{d1.name}));
cases=expectErr(cases,'F03b_S0ALT_never_overwritten','G2M4S0:Exists',@()g2_m4a_s0alt('Mode','build','Run',true,'AuthToken',sprintf('G2M4AS0|%s|family=%s',polSHA,fam)));
% ---- refusals: tokens, cap, location, name
cases=expectErr(cases,'F04a_wrong_token_material','G2M4:Authorization',@()run('soft',cp(acc('soft'),work,'F04a_soft'),'Run',true,'AuthToken',tok('stiff')));
cases=expectErr(cases,'F04b_wrong_token_family','G2M4:Authorization',@()run('soft',cp(acc('soft'),work,'F04b_soft'),'Run',true,'AuthToken',strrep(tok('soft'),fam,'famA')));
m3sha=upper(g2_sha256_file(fullfile(here,'G2_M3_TRAJECTORY_POLICY_v1.json')));
cases=expectErr(cases,'F04c_token_other_policy','G2M4:Authorization',@()run('soft',cp(acc('soft'),work,'F04c_soft'),'Run',true,'AuthToken',strrep(tok('soft'),polSHA,m3sha)));
cases=expectErr(cases,'F05_step3_request','G2M4:StepCap',@()run('soft',cp(acc('soft'),work,'F05_soft'),'MaxStateIndex',3));
cases=expectErr(cases,'F06a_chain_under_M3_root','G2M4:ChainLocation',@()run('soft',fullfile(repo,'outputs','g2_material_trajectories_v1','chain_soft_m4probe')));
cases=expectErr(cases,'F06b_switched_material_on_chain','G2M4:ChainName',@()run('stiff',cp(acc('soft'),work,'F06b_soft'),'Run',true,'AuthToken',tok('stiff')));
% ---- F07 forged S0ALT: famA mesh with a consistently re-hashed record
s0f=fullfile(work,'F07_S0ALT');copyfile(s0acc,s0f);
copyfile(fullfile(repo,pol.base.famA_S0Mesh),fullfile(s0f,'GEOMETRY_ONLY_candidate.mat'),'f');
Rr=rd(fullfile(s0f,'S0ALT.mat'));Rr.meshSHA256=g2_sha256_file(fullfile(s0f,'GEOMETRY_ONLY_candidate.mat'));rewrite(fullfile(s0f,'S0ALT.mat'),Rr);
cases=expectErr(cases,'F07_forged_S0ALT_famA_mesh','G2M4S0:MeshContent',@()run('soft',cp(acc('soft'),work,'F07_soft'),'S0Dir',s0f));
% ---- F08 forged review re-pointed to the ORIGINAL-family (PR #41) mesh of the same step
c=cp(acc('soft'),work,'F08_soft');s1=fullfile(c,'STEP_001');
copyfile(fullfile(o41('soft'),'STEP_001','KINKED_GEOMETRY_ONLY_candidate.mat'),fullfile(s1,'KINKED_GEOMETRY_ONLY_candidate.mat'),'f');
Rv=rd(fullfile(s1,'REVIEW.mat'));Rv.meshSHA256=g2_sha256_file(fullfile(s1,'KINKED_GEOMETRY_ONLY_candidate.mat'));rewrite(fullfile(s1,'REVIEW.mat'),Rv);delrec(fullfile(s1,'STATE.mat'));
cases=expectErr(cases,'F08_forged_review_original_family_mesh','G2M4:ReviewMeshContent',@()run('soft',c,'Run',true,'AuthToken',tok('soft')));
% ---- F09 ROOT parent K replaced by the original-family (PR #38) S0 K
c=cp(acc('soft'),work,'F09_soft');Ro=rd(fullfile(c,'ROOT.mat'));
[r38,~,ok]=g2_trajectory_record('read',fullfile(repo,pol.base.m2Run,'CASE_S0_Msoft.mat'));assert(ok);
Ro.parent.KI_perkN=r38.KI_perkN;Ro.parent.KII_perkN=r38.KII_perkN;rewrite(fullfile(c,'ROOT.mat'),Ro);
cases=expectErr(cases,'F09_root_seeded_with_original_K','G2M4:RootParent',@()run('soft',c));
% ---- F10 phase labels inconsistent with the saved polygons (consistently forged)
c=cp(acc('stiff'),work,'F10_stiff');s1=fullfile(c,'STEP_001');
Ph=rd(fullfile(s1,'PHASE_MAP.mat'));Ph.phase(Ph.interfaces(1).innerOwner(1))=1;ph=rewrite(fullfile(s1,'PHASE_MAP.mat'),Ph);
Rv=rd(fullfile(s1,'REVIEW.mat'));Rv.phaseSHA256=ph;rewrite(fullfile(s1,'REVIEW.mat'),Rv);delrec(fullfile(s1,'STATE.mat'));
cases=expectErr(cases,'F10_phase_labels_inconsistent','G2M4:ReviewPhase',@()run('stiff',c,'Run',true,'AuthToken',tok('stiff')));
% ---- F11 policy / source drift recorded in ROOT
c=cp(acc('soft'),work,'F11a_soft');Ro=rd(fullfile(c,'ROOT.mat'));Ro.policySHA256(1)=char('0'+mod(Ro.policySHA256(1)-'0'+1,10));rewrite(fullfile(c,'ROOT.mat'),Ro);
cases=expectErr(cases,'F11a_policy_drift','G2M4:RootDrift',@()run('soft',c));
c=cp(acc('soft'),work,'F11b_soft');Ro=rd(fullfile(c,'ROOT.mat'));if Ro.sourceHashes(3).sha256(end)=='0',Ro.sourceHashes(3).sha256(end)='1';else,Ro.sourceHashes(3).sha256(end)='0';end;rewrite(fullfile(c,'ROOT.mat'),Ro);
cases=expectErr(cases,'F11b_source_drift','G2M4:RootDrift',@()run('soft',c));
% ---- F12 tampered child state bytes; F13 changed parent K in a valid state
c=cp(acc('soft'),work,'F12_soft');f=fullfile(c,'STEP_002','STATE.mat');fid=fopen(f,'r+');fseek(fid,2000,'bof');x=fread(fid,1,'uint8');fseek(fid,2000,'bof');fwrite(fid,bitxor(x,255),'uint8');fclose(fid);
cases=expectErr(cases,'F12_tampered_state_bytes','G2M4:StateIntegrity',@()run('soft',c));
c=cp(acc('homogeneous'),work,'F13_homogeneous');St=rd(fullfile(c,'STEP_001','STATE.mat'));St.KII_perkN=St.KII_perkN*(1+1e-9);rewrite(fullfile(c,'STEP_001','STATE.mat'),St);
cases=expectErr(cases,'F13_changed_parent_K','G2M4:StateMismatch',@()run('homogeneous',c));
% ---- F14 dirty source
c=cp(acc('soft'),work,'F14_soft');probe=fullfile(here,'zz_m4a_dirty_probe.m');fid=fopen(probe,'w');fprintf(fid,'%% probe\n');fclose(fid);
try
 cases=expectErr(cases,'F14_dirty_source','G2M4:DirtySource',@()run('soft',c,'Run',true,'AuthToken',tok('soft')));
catch
end
if isfile(probe),delete(probe);end
% ---- F15 HOLD chain refused; F16 partial step
c=cp(acc('soft'),work,'F15_soft');g2_trajectory_record('write',fullfile(c,'STEP_002','HOLD.mat'),struct('schema','NewMetacomp.G2.M4A.Hold.v1','stateIndex',2,'identifier','test','message','test'));
cases=expectErr(cases,'F15_hold_chain_refused','G2M4:HoldChain',@()run('soft',c,'Run',true,'AuthToken',tok('soft')));
c=cp(acc('soft'),work,'F16_soft');s2=fullfile(c,'STEP_002');for n={'REVIEW.mat','STATE.mat','SOLUTION.mat'},delrec(fullfile(s2,n{1}));end
cases=expectErr(cases,'F16_partial_step','G2M4:PartialStep',@()run('soft',c,'Run',true,'AuthToken',tok('soft')));
% ---- F17 interrupt after review (fresh), promotion without FEM
c=fullfile(work,'F17_soft_fresh');
R1=run('soft',c,'Run',true,'AuthToken',tok('soft'),'MaxStateIndex',1,'SimulateInterrupt',struct('point','review','step',1));
R2=run('soft',c,'Run',true,'AuthToken',tok('soft'),'MaxStateIndex',1);
Sa=rd(fullfile(acc('soft'),'STEP_001','STATE.mat'));Sf=rd(fullfile(c,'STEP_001','STATE.mat'));
ok=strcmp(R1.stage,'SIMULATED_INTERRUPT_AFTER_REVIEW')&&R2.reviewsPromoted==1&&R2.statesComputed==0&&isequal(Sa.crackPolyline_mm,Sf.crackPolyline_mm)&&isequal(Sa.EDI_all,Sf.EDI_all);
cases=add(cases,'F17_interrupt_after_review_promoted_without_FEM','promoted 1, computed 0, state equals accepted',sprintf('%s; promoted %d computed %d',R1.stage,R2.reviewsPromoted,R2.statesComputed),ok);
% ---- F18 interrupt after state (fresh), reuse without FEM
c=fullfile(work,'F18_stiff_fresh');
R1=run('stiff',c,'Run',true,'AuthToken',tok('stiff'),'MaxStateIndex',1,'SimulateInterrupt',struct('point','state','step',1));
h0=tree(c);R2=run('stiff',c,'Run',true,'AuthToken',tok('stiff'),'MaxStateIndex',1);
cases=add(cases,'F18_interrupt_after_state_reused','reused 1, computed 0, tree identical',sprintf('%s; reused %d computed %d same %d',R1.stage,R2.statesReused,R2.statesComputed,isequal(h0,tree(c))), ...
 R2.statesReused==1&&R2.statesComputed==0&&isequal(h0,tree(c)));
% ---- F19 deterministic replay of the complete homogeneous chain (H1, M0, Msoft, Mstiff)
c=fullfile(work,'F19_homogeneous_replay');R=run('homogeneous',c,'Run',true,'AuthToken',tok('homogeneous'));
same=R.statesComputed==2;
names={'SOLUTION.mat','SOLUTION_M0.mat','SOLUTION_Msoft.mat','SOLUTION_Mstiff.mat'};
for n=names,A=rd(fullfile(acc('homogeneous'),'ROOT_S0',n{1}));Bq=rd(fullfile(c,'ROOT_S0',n{1}));same=same&&isequal(A.u,Bq.u)&&isequal(A.EDI_all,Bq.EDI_all);end
for k=1:2
 sa=fullfile(acc('homogeneous'),sprintf('STEP_%03d',k));sb=fullfile(c,sprintf('STEP_%03d',k));
 Pa=rd(fullfile(sa,'PHASE_MAP.mat'));Pb=rd(fullfile(sb,'PHASE_MAP.mat'));
 Ma=load(fullfile(sa,'KINKED_GEOMETRY_ONLY_candidate.mat'));Mb=load(fullfile(sb,'KINKED_GEOMETRY_ONLY_candidate.mat'));
 same=same&&isequal(Pa.phase,Pb.phase)&&isequal(Ma,Mb);
 for n=names,A=rd(fullfile(sa,n{1}));Bq=rd(fullfile(sb,n{1}));same=same&&isequal(A.u,Bq.u)&&isequal(A.EDI_all,Bq.EDI_all)&&isequal(A.KI_COD_raw,Bq.KI_COD_raw);end
end
cases=add(cases,'F19_deterministic_replay_homogeneous','2 steps computed; mesh, phase, u, EDI, COD identical (4 solves per state)',sprintf('computed %d, identical %d',R.statesComputed,same),same);
after=[tree(acc('homogeneous'));tree(acc('soft'));tree(acc('stiff'));tree(s0acc);tree(o41('soft'));tree(o41('stiff'))];
untouched=isequal(before,after);
T=struct('cases',cases,'acceptedUnchanged',untouched,'pass',all([cases.pass])&&untouched);
for k=1:numel(cases),fprintf('M4A_FAULT %-48s expect %-36s observed %-52s -> %d\n',cases(k).id,cases(k).expect,cases(k).observed,cases(k).pass);end
fprintf('M4A_FAULTS %d/%d pass; accepted PR #41, S0ALT and alternative chains unchanged %d; PASS=%d\n',nnz([cases.pass]),numel(cases),untouched,T.pass);
txt=jsonencode(T,'PrettyPrint',true);txt=strrep(txt,strrep(repo,'\','\\'),'<repo>');
fid=fopen(fullfile(folder,'m4a_faults_summary.json'),'w');fwrite(fid,txt,'char');fclose(fid);
end

% =====================================================================
function cases=add(cases,id,expect,observed,pass)
cases(end+1)=struct('id',id,'expect',expect,'observed',observed,'pass',logical(pass),'note','');
end

function cases=expectErr(cases,id,expectId,fn)
try
 R=fn();obs=sprintf('NO ERROR (stage %s)',R.stage);pass=false;
catch ME
 obs=ME.identifier;pass=startsWith(ME.identifier,expectId);
end
cases=add(cases,id,expectId,obs,pass);
end

function c=cp(src,work,name)
c=fullfile(work,name);copyfile(src,c);
end

function r=rd(f)
[r,~,ok]=g2_trajectory_record('read',f);assert(ok,'G2M4F:Read','Cannot read %s.',f);
end

function h=rewrite(f,r)
delrec(f);h=g2_trajectory_record('write',f,r);
end

function delrec(f)
if isfile(f),delete(f);end
if isfile([f,'.manifest.json']),delete([f,'.manifest.json']);end
end

function H=tree(d)
f=dir(fullfile(d,'**','*'));f=f(~[f.isdir]);H=cell(numel(f),1);
for k=1:numel(f),p=fullfile(f(k).folder,f(k).name);H{k}=[strrep(p,d,''),' ',g2_sha256_file(p)];end
H=sort(H);
end
