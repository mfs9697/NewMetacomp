function T = run_g2_m3_faults_batch()
%RUN_G2_M3_FAULTS_BATCH  Issue #39 stage E: tamper, restart, interrupt and replay tests.
%
%  T = run_g2_m3_faults_batch()
% All cases act on DISPOSABLE copies under outputs/g2_material_trajectories_v1/faults_run_<time>/;
% the accepted chains are hashed before and after and must be unchanged. Each case states
% the expected refusal identifier or the expected safe behaviour (reuse / promotion without
% FEM, bit-identical replay).
here=fileparts(mfilename('fullpath'));repo=fileparts(fileparts(here));
root=fullfile(repo,'outputs','g2_material_trajectories_v1');
folder=fullfile(root,['faults_run_',datestr(now,'yyyymmdd_HHMMSS_FFF')]);assert(~exist(folder,'dir'));mkdir(folder);
work=fullfile(folder,'work');mkdir(work);
diary(fullfile(folder,'m3_faults_console.log'));cl=onCleanup(@()diary('off')); %#ok<NASGU>
polSHA=upper(g2_sha256_file(fullfile(here,'G2_M3_TRAJECTORY_POLICY_v1.json')));
tok=@(m)sprintf('G2M3RUN|%s|%s|maxState=2',polSHA,m);
acc=@(m)fullfile(root,['chain_',m,'_v1']);
before=[tree(acc('soft'));tree(acc('stiff'))];
cases=struct('id',{},'expect',{},'observed',{},'pass',{},'note',{});
% ---- F01 dry on a complete copy: no writes, STEP_CAP
c=cp(acc('soft'),work,'F01_soft');h0=tree(c);
R=g2_m3_trajectory_run('Material','soft','ChainDir',c);
cases=add(cases,'F01_dry_no_writes','STEP_CAP and identical tree',sprintf('%s, tree same %d',R.stage,isequal(h0,tree(c))),strcmp(R.stage,'STEP_CAP')&&isequal(h0,tree(c)),'');
% ---- F02 run on a complete copy: reuse both states without FEM, no writes
c=cp(acc('soft'),work,'F02_soft');h0=tree(c);
R=g2_m3_trajectory_run('Material','soft','ChainDir',c,'Run',true,'AuthToken',tok('soft'));
cases=add(cases,'F02_run_reuses_states_no_FEM','statesReused 2, computed 0, tree same',sprintf('reused %d computed %d tree same %d',R.statesReused,R.statesComputed,isequal(h0,tree(c))), ...
 R.statesReused==2&&R.statesComputed==0&&isequal(h0,tree(c)),'');
% ---- refusals
cases=expectErr(cases,'F03_step3_request','G2M3:StepCap',@()g2_m3_trajectory_run('Material','soft','ChainDir',cp(acc('soft'),work,'F03_soft'),'MaxStateIndex',3));
cases=expectErr(cases,'F04_wrong_token_material','G2M3:Authorization',@()g2_m3_trajectory_run('Material','soft','ChainDir',cp(acc('soft'),work,'F04_soft'),'Run',true,'AuthToken',tok('stiff')));
cases=expectErr(cases,'F05_switched_material_on_chain','G2M3:ChainName',@()g2_m3_trajectory_run('Material','stiff','ChainDir',cp(acc('soft'),work,'F05_soft'),'Run',true,'AuthToken',tok('stiff')));
% F06 forged review: soft step-1 review re-pointed to the STIFF step-1 mesh (manifests valid)
c=cp(acc('soft'),work,'F06_soft');s1=fullfile(c,'STEP_001');
copyfile(fullfile(acc('stiff'),'STEP_001','KINKED_GEOMETRY_ONLY_candidate.mat'),fullfile(s1,'KINKED_GEOMETRY_ONLY_candidate.mat'),'f');
Rv=rd(fullfile(s1,'REVIEW.mat'));Rv.meshSHA256=g2_sha256_file(fullfile(s1,'KINKED_GEOMETRY_ONLY_candidate.mat'));rewrite(fullfile(s1,'REVIEW.mat'),Rv);delrec(fullfile(s1,'STATE.mat'));
cases=expectErr(cases,'F06_forged_review_other_material_mesh','G2M3:ReviewMeshContent',@()g2_m3_trajectory_run('Material','soft','ChainDir',c,'Run',true,'AuthToken',tok('soft')));
% F07 phase labels inconsistent with the saved polygons (forged consistently)
c=cp(acc('soft'),work,'F07_soft');s1=fullfile(c,'STEP_001');
Ph=rd(fullfile(s1,'PHASE_MAP.mat'));Ph.phase(Ph.interfaces(1).innerOwner(1))=1;ph=rewrite(fullfile(s1,'PHASE_MAP.mat'),Ph);
Rv=rd(fullfile(s1,'REVIEW.mat'));Rv.phaseSHA256=ph;rewrite(fullfile(s1,'REVIEW.mat'),Rv);delrec(fullfile(s1,'STATE.mat'));
cases=expectErr(cases,'F07_phase_labels_inconsistent','G2M3:ReviewPhase',@()g2_m3_trajectory_run('Material','soft','ChainDir',c,'Run',true,'AuthToken',tok('soft')));
% F08 policy drift / source drift recorded in ROOT
c=cp(acc('soft'),work,'F08a_soft');Ro=rd(fullfile(c,'ROOT.mat'));Ro.policySHA256(1)=char('0'+mod(Ro.policySHA256(1)-'0'+1,10));rewrite(fullfile(c,'ROOT.mat'),Ro);
cases=expectErr(cases,'F08a_policy_drift','G2M3:RootDrift',@()g2_m3_trajectory_run('Material','soft','ChainDir',c));
c=cp(acc('soft'),work,'F08b_soft');Ro=rd(fullfile(c,'ROOT.mat'));if Ro.sourceHashes(3).sha256(end)=='0',Ro.sourceHashes(3).sha256(end)='1';else,Ro.sourceHashes(3).sha256(end)='0';end;rewrite(fullfile(c,'ROOT.mat'),Ro);
cases=expectErr(cases,'F08b_source_drift','G2M3:RootDrift',@()g2_m3_trajectory_run('Material','soft','ChainDir',c));
% F09 wrong parent K (state tampered with a valid manifest) / wrong parent hash in review
c=cp(acc('soft'),work,'F09a_soft');St=rd(fullfile(c,'STEP_001','STATE.mat'));St.KI_perkN=St.KI_perkN*(1+1e-9);rewrite(fullfile(c,'STEP_001','STATE.mat'),St);
cases=expectErr(cases,'F09a_changed_parent_K','G2M3:StateMismatch',@()g2_m3_trajectory_run('Material','soft','ChainDir',c));
c=cp(acc('soft'),work,'F09b_soft');s2=fullfile(c,'STEP_002');Rv=rd(fullfile(s2,'REVIEW.mat'));Rv.parentSHA256=repmat('A',1,64);rewrite(fullfile(s2,'REVIEW.mat'),Rv);delrec(fullfile(s2,'STATE.mat'));
cases=expectErr(cases,'F09b_wrong_parent_hash','G2M3:ReviewLinks',@()g2_m3_trajectory_run('Material','soft','ChainDir',c));
% F10 swapped crack banks in the saved mesh (forged consistently)
c=cp(acc('soft'),work,'F10_soft');s1=fullfile(c,'STEP_001');mf=fullfile(s1,'KINKED_GEOMETRY_ONLY_candidate.mat');D=load(mf);
tmp=D.upperBankT6;D.upperBankT6=D.lowerBankT6;D.lowerBankT6=tmp;delete(mf);save(mf,'-struct','D','-v7.3');
Rv=rd(fullfile(s1,'REVIEW.mat'));Rv.meshSHA256=g2_sha256_file(mf);rewrite(fullfile(s1,'REVIEW.mat'),Rv);delrec(fullfile(s1,'STATE.mat'));
cases=expectErr(cases,'F10_swapped_banks','G2M3:Review',@()g2_m3_trajectory_run('Material','soft','ChainDir',c));
% F11 bad 4-mm segment in a forged review
c=cp(acc('soft'),work,'F11_soft');s1=fullfile(c,'STEP_001');Rv=rd(fullfile(s1,'REVIEW.mat'));Rv.polyline_mm(end,:)=Rv.polyline_mm(end,:)+[.1 0];
rewrite(fullfile(s1,'REVIEW.mat'),Rv);delrec(fullfile(s1,'STATE.mat'));
cases=expectErr(cases,'F11_bad_segment','G2M3:ForecastDrift',@()g2_m3_trajectory_run('Material','soft','ChainDir',c));
% F12 tampered child state bytes (manifest not updated)
c=cp(acc('soft'),work,'F12_soft');f=fullfile(c,'STEP_002','STATE.mat');fid=fopen(f,'r+');fseek(fid,2000,'bof');x=fread(fid,1,'uint8');fseek(fid,2000,'bof');fwrite(fid,bitxor(x,255),'uint8');fclose(fid);
cases=expectErr(cases,'F12_tampered_state_bytes','G2M3:StateIntegrity',@()g2_m3_trajectory_run('Material','soft','ChainDir',c));
% F13 dirty source (temporary untracked file under matlab/g2)
c=cp(acc('soft'),work,'F13_soft');probe=fullfile(here,'zz_m3_dirty_probe.m');fid=fopen(probe,'w');fprintf(fid,'%% probe\n');fclose(fid);
try
 cases=expectErr(cases,'F13_dirty_source','G2M3:DirtySource',@()g2_m3_trajectory_run('Material','soft','ChainDir',c,'Run',true,'AuthToken',tok('soft')));
catch
end
if isfile(probe),delete(probe);end
% F14 a chain holding a HOLD record is never reused
c=cp(acc('soft'),work,'F14_soft');g2_trajectory_record('write',fullfile(c,'STEP_002','HOLD.mat'),struct('schema','NewMetacomp.G2.M3.Hold.v1','stateIndex',2,'identifier','test','message','test'));
cases=expectErr(cases,'F14_hold_chain_refused','G2M3:HoldChain',@()g2_m3_trajectory_run('Material','soft','ChainDir',c,'Run',true,'AuthToken',tok('soft')));
% F15 partial step folder (mesh without review)
c=cp(acc('soft'),work,'F15_soft');s2=fullfile(c,'STEP_002');for n={'REVIEW.mat','STATE.mat','SOLUTION.mat'},delrec(fullfile(s2,n{1}));end
cases=expectErr(cases,'F15_partial_step','G2M3:PartialStep',@()g2_m3_trajectory_run('Material','soft','ChainDir',c,'Run',true,'AuthToken',tok('soft')));
% ---- F16 interrupt after review (fresh chain), then promotion without FEM
c=fullfile(work,'F16_soft_fresh');
R1=g2_m3_trajectory_run('Material','soft','ChainDir',c,'Run',true,'AuthToken',tok('soft'),'MaxStateIndex',1,'SimulateInterrupt',struct('point','review','step',1));
R2=g2_m3_trajectory_run('Material','soft','ChainDir',c,'Run',true,'AuthToken',tok('soft'),'MaxStateIndex',1);
Sa=rd(fullfile(acc('soft'),'STEP_001','STATE.mat'));Sf=rd(fullfile(c,'STEP_001','STATE.mat'));
ok=strcmp(R1.stage,'SIMULATED_INTERRUPT_AFTER_REVIEW')&&R2.reviewsPromoted==1&&R2.statesComputed==0&&isequal(Sa.crackPolyline_mm,Sf.crackPolyline_mm)&&isequal(Sa.EDI_all,Sf.EDI_all);
cases=add(cases,'F16_interrupt_after_review_promoted_without_FEM','promoted 1, computed 0, state equals accepted',sprintf('%s; promoted %d computed %d',R1.stage,R2.reviewsPromoted,R2.statesComputed),ok,'');
% ---- F17 interrupt after state (fresh chain), then reuse without FEM
c=fullfile(work,'F17_soft_fresh');
R1=g2_m3_trajectory_run('Material','soft','ChainDir',c,'Run',true,'AuthToken',tok('soft'),'MaxStateIndex',1,'SimulateInterrupt',struct('point','state','step',1));
h0=tree(c);R2=g2_m3_trajectory_run('Material','soft','ChainDir',c,'Run',true,'AuthToken',tok('soft'),'MaxStateIndex',1);
cases=add(cases,'F17_interrupt_after_state_reused','reused 1, computed 0, tree same',sprintf('%s; reused %d computed %d same %d',R1.stage,R2.statesReused,R2.statesComputed,isequal(h0,tree(c))), ...
 R2.statesReused==1&&R2.statesComputed==0&&isequal(h0,tree(c)),'');
% ---- F18 deterministic replay of the full stiff chain
c=fullfile(work,'F18_stiff_replay');
R=g2_m3_trajectory_run('Material','stiff','ChainDir',c,'Run',true,'AuthToken',tok('stiff'));
same=R.statesComputed==2;
for k=1:2
 sa=fullfile(acc('stiff'),sprintf('STEP_%03d',k));sb=fullfile(c,sprintf('STEP_%03d',k));
 A=rd(fullfile(sa,'SOLUTION.mat'));Bq=rd(fullfile(sb,'SOLUTION.mat'));Pa=rd(fullfile(sa,'PHASE_MAP.mat'));Pb=rd(fullfile(sb,'PHASE_MAP.mat'));
 Ma=load(fullfile(sa,'KINKED_GEOMETRY_ONLY_candidate.mat'));Mb=load(fullfile(sb,'KINKED_GEOMETRY_ONLY_candidate.mat'));
 same=same&&isequal(A.u,Bq.u)&&isequal(A.EDI_all,Bq.EDI_all)&&isequal(A.KI_COD_raw,Bq.KI_COD_raw)&&isequal(Pa.phase,Pb.phase)&&isequal(Ma,Mb);
end
cases=add(cases,'F18_deterministic_replay_stiff','2 steps computed, mesh/phase/u/EDI/COD identical',sprintf('computed %d, identical %d',R.statesComputed,same),same,'');
after=[tree(acc('soft'));tree(acc('stiff'))];
untouched=isequal(before,after);
T=struct('cases',cases,'acceptedChainsUnchanged',untouched,'pass',all([cases.pass])&&untouched);
for k=1:numel(cases),fprintf('M3_FAULT %-48s expect %-40s observed %-50s -> %d\n',cases(k).id,cases(k).expect,cases(k).observed,cases(k).pass);end
fprintf('M3_FAULTS %d/%d pass; accepted chains unchanged %d; PASS=%d\n',nnz([cases.pass]),numel(cases),untouched,T.pass);
fid=fopen(fullfile(folder,'m3_faults_summary.json'),'w');fwrite(fid,jsonencode(T,'PrettyPrint',true),'char');fclose(fid);
end

% =====================================================================
function cases=add(cases,id,expect,observed,pass,note)
cases(end+1)=struct('id',id,'expect',expect,'observed',observed,'pass',logical(pass),'note',note);
end

function cases=expectErr(cases,id,expectId,fn)
try
 R=fn();obs=sprintf('NO ERROR (stage %s)',R.stage);pass=false;
catch ME
 obs=ME.identifier;pass=startsWith(ME.identifier,expectId);
end
cases=add(cases,id,expectId,obs,pass,'');
end

function c=cp(src,work,name)
c=fullfile(work,name);copyfile(src,c);
end

function r=rd(f)
[r,~,ok]=g2_trajectory_record('read',f);assert(ok,'G2M3F:Read','Cannot read %s.',f);
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
