% LP2-B1-S10 closure (READ-ONLY; after revocation of GO_LP2B1_S10, commit 37458ef):
% 1 post-revocation correct-token refusal under the real preflight, zero writes (run/receipt trees, summary, outputs listing, git);
% 2 the read-only verifier g2_lp2b1s10_verify (tree unchanged);
% 3 full dump of every run/receipt record + raw little-endian float64 exports (shape in the index) for the independent Python audit;
% 4 parent-chain histories of all four architectures, walked through the recorded parentSHA256 (no assumed paths).
ex='<repo>';
out='<scratch>\lp2b1s10run';
restoredefaultpath;g2d=fullfile(ex,'matlab','g2');for f={'','lp2','lp2a2','lp2a3','lp2b1','lp2b1eq'},addpath(fullfile(g2d,f{1}));end
addpath(fullfile(ex,'scripts','g2','lp2a2','closure'));addpath(fullfile(g2d,'lp2b1s10'));
TOK=['G2LP2B1S10|policy=f57433eccc5641ba253da52b723a0de6b1ad299793aa227235d309e57f120171|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947', ...
 '|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca|lp2a2source=f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd', ...
 '|lp2a3source=fa3bcecfa9cd3044253d5a72253e2058bccd044d32345f51650dcd775f42e002|lp2b1source=9c7a1260e3bde5b59e1d93c47bc99cc4d7b89f9b0cc6e874572fb378f1717bee', ...
 '|lp2b1eqsource=74a0edd827daca5714a1347705abc1429a7a573116ad3c438f9e5a1c12dfbf1f|closure=76614f269810c6970544bca0c1c0f84ebf9131935554ebd75e57e24f819f65f7', ...
 '|lp2b1s10source=d544fcfde1cfaa1e7118e0c5959551bdddb1cd477739bcf55376c45fe8388ab9|parent=9f3c173fadd370ae3e455b3aef3d5aa4d1f3035faf6100d717d4175ae33f194b', ...
 '|qualification=773f42aef75b13542efc6a169c9f526f6e64597a8d359df0ab067abf6cf161df|eqcampaign=91ff13fa86617f8236b09c439f7048f4542520e79c31003c01f07957e5cf17b9', ...
 '|case=soft1|state=S10|admissions=1|seed=0.40|campaign=G2-LP2B1-S10-001|run=run_lp2b1_s10_v1'];
summ=fullfile(ex,'outputs','LP2B1S10_CAMPAIGN.json');
% ---------------------------------------------------------------- 1 post-revocation refusal (real preflight)
try
 C=g2_lp2b1s10_context();H=g2_lp2a2_git('head',ex);assert(~isfile(C.goFile),'POST:GO','GO still present.');
 T0=treeHash(C.runRoot);T0r=treeHash(C.receiptRoot);s0=lower(g2_sha256_file(summ));L0=listing(fullfile(ex,'outputs'));[~,g0]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 i='<no error>';m='';try,g2_lp2b1s10_run('Run',true,'Token',TOK);catch ME,i=ME.identifier;m=ME.message;end;fprintf('POSTREV soft1-S10 %s\n',i);
 T1=treeHash(C.runRoot);T1r=treeHash(C.receiptRoot);s1=lower(g2_sha256_file(summ));L1=listing(fullfile(ex,'outputs'));[~,g1]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 pf=C.preflight;if isfield(pf,'matlabProcessInfo'),pf=rmfield(pf,'matlabProcessInfo');end
 PR=struct('sourceCommit',H.value,'preflight',pf,'tokenEqualsAuthorization',strcmp(C.token,TOK),'goAbsent',~isfile(C.goFile),'probe',struct('identifier',i,'message',m), ...
  'runFilesUnchanged',isequal(T0,T1),'receiptUnchanged',isequal(T0r,T1r),'summaryUnchanged',strcmp(s0,s1),'outputsListingUnchanged',isequal(L0,L1), ...
  'runFiles',size(T0,1),'receiptFiles',size(T0r,1),'gitClean',isempty(strtrim(g0))&&isempty(strtrim(g1)),'physicalSolves',0,'externalEntryInvoked',false);
 PR.pass=strcmp(i,'G2LP2B1S10:HOLD_UNAUTHORIZED')&&PR.runFilesUnchanged&&PR.receiptUnchanged&&PR.summaryUnchanged&&PR.outputsListingUnchanged&&PR.gitClean&&PR.tokenEqualsAuthorization&&PR.goAbsent;
 wj(fullfile(out,'post','LP2B1S10_POST_REVOCATION.json'),PR);fprintf('POSTREV_RESULT pass=%d head=%s runFiles=%d receipt=%d\n',PR.pass,H.value,PR.runFiles,PR.receiptFiles);
catch ME,fprintf(2,'POSTREV_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));end
% ---------------------------------------------------------------- 2 read-only verifier
try
 Cv=g2_lp2b1s10_context('Preflight',false);h0=treeHash(Cv.runRoot);h0r=treeHash(Cv.receiptRoot);Rv=g2_lp2b1s10_verify(Cv);Rv2=Rv;
 Rv2.treeUnchanged=isequal(h0,treeHash(Cv.runRoot))&&isequal(h0r,treeHash(Cv.receiptRoot));wj(fullfile(out,'verify','LP2B1S10_VERIFY_POSTREV.json'),Rv2);
 fprintf('VERIFY outcome=%s unchanged=%d\n',Rv.outcome,Rv2.treeUnchanged);
catch ME,fprintf(2,'VERIFY_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));end
% ---------------------------------------------------------------- 3 full dump + raw exports
try
 pol=Cv.policy;fp=@(p)fullfile(ex,strrep(p,'/',filesep));raw=fullfile(out,'verify','raw');mkdir(raw);IX=struct('file',{},'shape',{},'class',{});
 sd=fullfile(Cv.runRoot,'soft1','S10');
 A=struct('schema','NewMetacomp.G2.LP2B1S10.RecordDump.v1','token',Cv.token,'policySHA256',Cv.policySHA256,'files',struct());
 A.files.run=relHash(Cv.runRoot,ex);A.files.receipt=relHash(Cv.receiptRoot,ex);
 [Rc,rch,okr]=g2_trajectory_record('read',fullfile(Cv.receiptRoot,'RECEIPT.mat'));A.receipt=struct('record',Rc,'sha256',rch,'manifestOK',okr);
 [Ad,adh,oka]=g2_trajectory_record('read',fullfile(Cv.receiptRoot,'ADMIT_soft1_S10.mat'));A.admit=struct('record',small(Ad),'sha256',adh,'manifestOK',oka);
 L=g2_lp1_campaign_ledger('snapshot',Cv.receiptRoot);A.ledger=small(struct('integrityOK',L.integrityOK,'nAdmits',numel(L.admits),'nHolds',numel(L.holds),'closed',L.closed));
 D=load(fullfile(sd,'MESH.mat'));A.meshFields=fieldnames(D);A.meshCanonical=g2_lp2b1eq_canon(D);A.meshFileSHA256=lower(g2_sha256_file(fullfile(sd,'MESH.mat')));
 big={'X3','T3','X6','T6','upperBankT6','lowerBankT6','nodalQ','qActiveT6Rows','crackPolyline'};
 for q=big,IX=ex64(IX,raw,['new_' q{1}],D.(q{1}));end
 A.meshScalars=small(rmfield(D,intersect(fieldnames(D),big)));
 Q=load(fp(pol.qualification.arrays.path));A.qualificationFields=fieldnames(Q);A.qualificationArraysSHA256=lower(g2_sha256_file(fp(pol.qualification.arrays.path)));
 for q=reshape(fieldnames(Q),1,[]),x=Q.(q{1});if (isnumeric(x)||islogical(x))&&~isempty(x),IX=ex64(IX,raw,['qual_' q{1}],x);end,end
 [Ph,phh,okp]=g2_trajectory_record('read',fullfile(sd,'PHASE.mat'));A.phase=small(Ph);A.phaseSHA256=phh;A.phaseManifestOK=okp;
 IX=ex64(IX,raw,'new_owner',Ph.owner);IX=ex64(IX,raw,'new_labels',Ph.labels);
 A.phaseAudit=struct('auditPass',fieldOr(Ph.audit,'pass'),'pairingPass',fieldOr(Ph.pairingAudit,'pass'),'auditGates',fieldOr(fieldOr(Ph.audit,'meshAudit'),'gatesPassed'),'pairingGates',fieldOr(Ph.pairingAudit,'gatesPassed'));
 [So,soh,oks]=g2_trajectory_record('read',fullfile(sd,'SOLUTION.mat'));A.solution=small(rmfield(So,'K'));A.solutionSHA256=soh;A.solutionManifestOK=oks;
 A.K=small(So.K);IX=ex64(IX,raw,'new_u',So.K.u);if isfield(So.K,'EDI_all'),IX=ex64(IX,raw,'new_EDI_all',So.K.EDI_all);end
 M=g2_mts_direction(So.K.KI,So.K.KII);A.newMTS=small(M);
 [St,sth,okst]=g2_trajectory_record('read',fullfile(sd,'STATE.mat'));A.state=small(St);A.stateSHA256=sth;A.stateManifestOK=okst;
 IX=ex64(IX,raw,'new_statePoly',St.polyline_mm);IX=ex64(IX,raw,'new_tangent',St.tangent);IX=ex64(IX,raw,'new_EDI_state',St.EDI_all);
 cg=St.clearanceGeometry;A.clearanceGeometry=small(cg);
 [Tr,trh,oktr]=g2_trajectory_record('read',fullfile(Cv.runRoot,'soft1','TERMINAL.mat'));A.terminal=small(Tr);A.terminalSHA256=trh;A.terminalManifestOK=oktr;
 if ~isempty(Tr.candidate.polyline_mm),IX=ex64(IX,raw,'s11_poly',Tr.candidate.polyline_mm);end
 A.attempt=jsondecode(fileread(fullfile(sd,'GEOMETRY_h040','ATTEMPT.json')));
 % archived: original S9 parent and the preserved FAILED_MESH of the same geometry (policy paths)
 Tq=g2_lp2b1s10_target(Cv);A.target=small(struct('pass',Tq.pass,'checks',Tq.checks,'info',Tq.info,'parentSHA256',Tq.parentSHA256));
 IX=ex64(IX,raw,'target_forecastPoly',Tq.forecast.polyline_mm);IX=ex64(IX,raw,'target_forecastTangent',Tq.forecast.tangent);
 A.failedMeshFields=fieldnames(Tq.failedMesh);
 for q={'X3','T3','X6','T6','crackPolyline'},if isfield(Tq.failedMesh,q{1}),IX=ex64(IX,raw,['fail_' q{1}],Tq.failedMesh.(q{1}));end,end
 A.geometryConstants=struct('centres_mm',pol.geometry.centres_mm,'ringR_mm',pol.geometry.ringR_mm,'holeR_mm',pol.geometry.holeR_mm,'E_MPa',pol.bvp.E_MPa,'ratio',pol.target.ratio);
 wj(fullfile(out,'verify','LP2B1S10_RECORD_DUMP.json'),A);fprintf('DUMP done raw=%d\n',numel(IX));
catch ME,fprintf(2,'DUMP_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));end
% ---------------------------------------------------------------- 4 histories through parentSHA256
try
 roots={'outputs/g2_lp1_matrix_paths_v1/run_20261122_lp1_v1','outputs/g2_lp2a_paths_v1/run_lp2a_s5_s8_v1','outputs/g2_lp2a3_paths_v1/run_lp2a3_s9_s11_v1','outputs/g2_lp2b1_s10_v1/run_lp2b1_s10_v1'};
 idx=containers.Map();
 for r=roots
  d=dir(fullfile(ex,strrep(r{1},'/',filesep),'**','STATE.mat'));
  for k=1:numel(d),p=fullfile(d(k).folder,d(k).name);idx(lower(g2_sha256_file(p)))=p;end
 end
 starts=struct('H','outputs/g2_lp2a3_paths_v1/run_lp2a3_s9_s11_v1/H/S10/STATE.mat','stiff13','outputs/g2_lp2a3_paths_v1/run_lp2a3_s9_s11_v1/stiff13/S10/STATE.mat', ...
  'soft2','outputs/g2_lp2a3_paths_v1/run_lp2a3_s9_s11_v1/soft2/S10/STATE.mat','soft1','outputs/g2_lp2b1_s10_v1/run_lp2b1_s10_v1/soft1/S10/STATE.mat');
 HI=struct();
 for c=fieldnames(starts).'
  p=fullfile(ex,strrep(starts.(c{1}),'/',filesep));chain={};
  while true
   [S,sh,ok]=g2_trajectory_record('read',p);
   e=struct('path',strrep(strrep(p,[ex filesep],''),'\','/'),'sha256',sh,'manifestOK',ok,'stateIndex',fieldOr(S,'stateIndex'),'caseId',fieldOr(S,'caseId'), ...
    'arc_mm',fieldOr(S,'arc_mm'),'tip_mm',fieldOr(S,'tip_mm'),'heading_deg',fieldOr(S,'heading_deg'),'KI',fieldOr(S,'KI'),'KII',fieldOr(S,'KII'),'J',fieldOr(S,'J'), ...
    'G',fieldOr(S,'G'),'MTS_deg',fieldOr(S,'MTS_deg'),'tipToRingCircle_mm',fieldOr(S,'tipToRingCircle_mm'),'compliance_mm_per_N',fieldOr(S,'compliance_mm_per_N'), ...
    'parentSHA256',fieldOr(S,'parentSHA256'),'tangent',fieldOr(S,'tangent'),'mask',fieldOr(S,'mask'),'ratio',fieldOr(S,'ratio'),'numericalStatus',fieldOr(S,'numericalStatus'));
   chain{end+1}=e; %#ok<AGROW>
   ps=lower(char(fieldOr(S,'parentSHA256')));if isempty(ps)||~isKey(idx,ps),break,end
   p=idx(ps);
  end
  HI.(c{1})=chain;fprintf('HISTORY %s states=%d first=S%d\n',c{1},numel(chain),chain{end}.stateIndex);
  for k=1:numel(chain),IX=ex64(IX,raw,sprintf('hist_%s_S%d_poly',c{1},chain{k}.stateIndex),getfield(g2_trajectory_record('read',fullfile(ex,strrep(chain{k}.path,'/',filesep))),'polyline_mm'));end %#ok<GFLD>
 end
 wj(fullfile(out,'verify','LP2B1S10_HISTORIES.json'),HI);wj(fullfile(raw,'RAW_INDEX.json'),IX);fprintf('HISTORIES done raw=%d\n',numel(IX));
catch ME,fprintf(2,'HIST_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));end

function IX=ex64(IX,raw,name,x)
f=fullfile(raw,[name '.f64']);fid=fopen(f,'w','l');fwrite(fid,double(x(:)),'float64');fclose(fid);
IX(end+1)=struct('file',[name '.f64'],'shape',size(x),'class',class(x));
end
function S=small(S)
if ~isstruct(S)||~isscalar(S),return,end
f=fieldnames(S);
for k=1:numel(f)
 x=S.(f{k});
 if isstruct(x)&&isscalar(x),S.(f{k})=small(x);
 elseif isstruct(x)||iscell(x)
  if numel(x)>64,S=rmfield(S,f{k});end
 elseif ischar(x)||isstring(x)
 elseif (isnumeric(x)||islogical(x))&&numel(x)>64,S=rmfield(S,f{k});
 elseif isa(x,'function_handle'),S=rmfield(S,f{k});
 end
end
end
function v=fieldOr(S,f),if isstruct(S)&&isfield(S,f),v=S.(f);else,v=[];end,end
function L=listing(folder),d=dir(fullfile(folder,'**','*'));L=sort(strcat({d.folder},filesep,{d.name}))';end
function H=treeHash(root)
H=cell(0,2);if ~isfolder(root),return,end
d=dir(fullfile(root,'**','*'));d=d(~[d.isdir]);for k=1:numel(d),p=fullfile(d(k).folder,d(k).name);H(end+1,:)={p,lower(g2_sha256_file(p))};end %#ok<AGROW>
if ~isempty(H),H=sortrows(H,1);end
end
function S=relHash(root,ex)
H=treeHash(root);S=struct('path',strrep(strrep(H(:,1),[ex filesep],''),'\','/'),'sha256',H(:,2));
end
function wj(f,S),fid=fopen(f,'w');fwrite(fid,jsonencode(S,'PrettyPrint',true),'char');fclose(fid);end
