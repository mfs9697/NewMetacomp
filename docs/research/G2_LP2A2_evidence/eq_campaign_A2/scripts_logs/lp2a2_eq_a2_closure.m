% LP2-A2 equivalence campaign G2-LP2A2-EQ-001: post-revocation probe (activation A2, after revocation commit). Correct-token Run=true calls and the external wrapper
% must be refused (HOLD_UNAUTHORIZED) with no write, no solve and unchanged campaign records. No FEM.
ex='<repo>';
out='<scratch>';
addpath(fullfile(ex,'matlab','g2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a2'),'-begin');
try
 C=g2_lp2a2_eq_context();
 [~,hh]=system(sprintf('git -C "%s" rev-parse HEAD',ex));head=strtrim(hh);
 assert(~isfile(fullfile(ex,'matlab','g2','lp2a2','G2_LP2A2_EQ_GO.json')),'PR:GO','GO still present.');
 rd=fullfile(ex,'outputs','g2_lp2a2_eq_v1');
 H0=hashes(rd);L0=listing(fullfile(ex,'outputs'));[~,g0]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 ids={'EQ-H','EQ-stiff13','EQ-soft2','EQ-soft1'};P=struct('solveId',{},'identifier',{},'message',{});
 for k=1:4
  i='<no error>';m='';try,g2_lp2a2_eq_run(ids{k},'Run',true,'Token',C.token);catch ME,i=ME.identifier;m=ME.message;end
  P(end+1)=struct('solveId',ids{k},'identifier',i,'message',m); %#ok<SAGROW>
  fprintf('POSTREV_RUN %s %s | %s\n',ids{k},i,m);
 end
 W=g2_lp2a2_eq_campaign(C.token);
 fprintf('POSTREV_WRAPPER outcome=%s solvesCalled=%d reason=%s\n',W.outcome,W.solvesCalled,W.reason);
 H1=hashes(rd);L1=listing(fullfile(ex,'outputs'));[~,g1]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 R=struct('schema','NewMetacomp.G2.LP2A2.EQ.PostRevocation.v1','sourceCommit',head,'token',C.token,'probes',P, ...
  'wrapper',struct('outcome',W.outcome,'solvesCalled',W.solvesCalled,'reason',W.reason), ...
  'campaignFilesUnchanged',isequal(H0,H1),'campaignFiles',size(H0,1),'outputsListingUnchanged',isequal(L0,L1),'gitClean',isempty(strtrim(g0))&&isempty(strtrim(g1)),'physicalSolves',0);
 R.outputRootExistsAfter=isfolder(rd);R.wrapperReason=W.reason;
 R.pass=all(strcmp({P.identifier},'G2LP2A2:HOLD_UNAUTHORIZED'))&&strcmp(W.outcome,'HOLD_UNAUTHORIZED')&&W.solvesCalled==0&&R.campaignFilesUnchanged&&R.outputsListingUnchanged&&R.gitClean;
 fid=fopen(fullfile(out,'LP2A2_EQ_A2_POST_REVOCATION.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
 fprintf('POSTREV_RESULT pass=%d files=%d (%d) listing=%d git=%d commit=%s\n',R.pass,R.campaignFilesUnchanged,R.campaignFiles,R.outputsListingUnchanged,R.gitClean,head);
catch ME
 fprintf(2,'POSTREV_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end

% ===== read-only replay and record dump (after the post-revocation probes) =====
ex='<repo>';
out='<scratch>';
addpath(fullfile(ex,'matlab','g2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a2'),'-begin');
try
 [~,hh]=system(sprintf('git -C "%s" rev-parse HEAD',ex));head=strtrim(hh);
 fprintf('AUDIT head=%s\n',head);
 C=g2_lp2a2_eq_context('Preflight',false);pol=C.policy;root=fullfile(ex,pol.outputRoot);
 Rv=g2_lp2a2_eq_verify();
 fprintf('AUDIT_VERIFY outcome=%s unchanged=%d solvesReplayed=%d problems=%d physicalSolves=%d\n',Rv.outcome,Rv.unchanged,numel(Rv.solves),numel(Rv.problems),Rv.physicalSolves);
 A=struct('head',head,'token',C.token,'verify',Rv,'solves',struct());
 d=dir(root);names={d([d.isdir]).name};names=names(~ismember(names,{'.','..'}));A.folders=names;
 for k=1:numel(pol.solves)
  s=pol.solves(k);sd=fullfile(root,s.id);key=strrep(s.id,'-','_');
  if ~isfolder(sd),A.solves.(key)=struct('present',false);continue,end
  f=@(n)fullfile(sd,n);dd=dir(sd);E=struct('present',true,'files',{{dd(~[dd.isdir]).name}});
  E.sha256=struct();for n=E.files,E.sha256.(strrep(n{1},'.','_'))=lower(g2_sha256_file(f(n{1})));end
  % manifests
  for n={'MESH.mat','PHASE.mat','SOLUTION.mat'}
   if isfile([f(n{1}) '.manifest.json']),Mj=jsondecode(fileread([f(n{1}) '.manifest.json']));E.manifest.(strrep(n{1},'.','_'))=struct('SHA256',Mj.SHA256,'bytes',Mj.bytes,'recordSchema',Mj.recordSchema);end
  end
  if ~all(isfile({f('SOLUTION.mat'),f('PHASE.mat'),f('MESH.mat'),f('COMPARISON.json')})),A.solves.(key)=E;continue,end
  Sx=load(f('SOLUTION.mat'));Sx=Sx.record;Ph=load(f('PHASE.mat'));Ph=Ph.record;D=load(f('MESH.mat'));Cm=jsondecode(fileread(f('COMPARISON.json')));
  ab=fullfile(C.archiveBase,s.caseId);St=load(fullfile(ab,'S8','STATE.mat'));St=St.record;So=load(fullfile(ab,'S8','SOLUTION.mat'));So=So.record;
  Tm=load(fullfile(ab,'TERMINAL.mat'));Tm=Tm.record;Ma=load(fullfile(ab,'S8','MESH.mat'));Pha=load(fullfile(ab,'S8','PHASE.mat'));Pha=Pha.record;
  E.solution=struct('schema',Sx.schema,'solveId',Sx.solveId,'caseId',Sx.caseId,'meshSHA256',Sx.meshSHA256,'phaseSHA256',Sx.phaseSHA256,'token',Sx.token, ...
   'approvedHead',Sx.approvedHead,'activationHead',Sx.activationHead,'solveSeconds',Sx.solveSeconds,'memoryGate',Sx.memoryGate);
  E.phase=struct('schema',Ph.schema,'solveId',Ph.solveId,'caseId',Ph.caseId,'mask',Ph.mask,'meshSHA256',Ph.meshSHA256, ...
   'ownerCounts',accumarray(Ph.owner(:)+1,1,[4 1]).','labelCounts',accumarray(Ph.labels(:),1,[2 1]).','nOwner',numel(Ph.owner));
  E.phaseArchived=struct('schema',Pha.schema,'mask',Pha.mask,'meshSHA256',Pha.meshSHA256, ...
   'ownerCounts',accumarray(Pha.owner(:)+1,1,[4 1]).','labelCounts',accumarray(Pha.labels(:),1,[2 1]).','nOwner',numel(Pha.owner));
  % mask from the policy's mask for this solve; ownership by identical activation rule
  E.policyMask=s.mask(:).';E.policyRatio=s.ratio;
  E.archivedState=struct('stateIndex',St.stateIndex,'caseId',St.caseId,'mask',St.mask,'ratio',St.ratio,'polyline_mm',St.polyline_mm,'tangent',St.tangent,'nVertices',size(St.polyline_mm,1));
  E.newMesh=struct('crackPolyline',D.crackPolyline,'polylineBitwiseEqualsArchived',isequal(D.crackPolyline,St.polyline_mm), ...
   'T3',size(D.T3,1),'X6',size(D.X6,1),'upperBankT6',numel(D.upperBankT6),'lowerBankT6',numel(D.lowerBankT6),'fieldnames',{fieldnames(D)});
  if isfield(D,'seedRung'),E.newMesh.seedRung=D.seedRung;end
  if isfield(D,'tipTangent'),E.newMesh.tipTangentEqualsArchived=isequal(D.tipTangent(:).',St.tangent(:).');end
  E.archivedMesh=struct('T3',size(Ma.T3,1),'X6',size(Ma.X6,1),'upperBankT6',numel(Ma.upperBankT6),'lowerBankT6',numel(Ma.lowerBankT6));
  E.K_new=kdump(Sx.K);E.K_archived=kdump(So.K);
  E.archivedS9tip_mm=Tm.candidate.polyline_mm(end,:);E.archivedS8tip_mm=St.polyline_mm(end,:);
  E.comparison=Cm;
  A.solves.(key)=E;
  fprintf('AUDIT_SOLVE %s files=%d links(mesh)=%d(phase)=%d polyBitwise=%d pass=%d\n',s.id,numel(E.files),strcmp(Sx.meshSHA256,E.sha256.MESH_mat),strcmp(Sx.phaseSHA256,E.sha256.PHASE_mat),E.newMesh.polylineBitwiseEqualsArchived,Cm.pass);
 end
 fid=fopen(fullfile(out,'LP2A2_EQ_A2_AUDIT_DUMP.json'),'w');fwrite(fid,jsonencode(A,'PrettyPrint',true),'char');fclose(fid);
 fprintf('AUDIT_DONE verify=%s\n',Rv.outcome);
catch ME
 fprintf(2,'AUDIT_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
function L=listing(folder)
d=dir(fullfile(folder,'**','*'));L=sort(strcat({d.folder},filesep,{d.name}))';
end
function H=hashes(root)
H=cell(0,2);if ~isfolder(root),return,end
d=dir(fullfile(root,'**','*'));d=d(~[d.isdir]);
for k=1:numel(d),f=fullfile(d(k).folder,d(k).name);H(end+1,:)={f,lower(g2_sha256_file(f))};end %#ok<AGROW>
if ~isempty(H),H=sortrows(H,1);end
end

function s=kdump(K)
s=struct('pass',K.pass,'status',K.status,'failedCriteria',{K.failedCriteria},'criteria',K.criteria,'KI',K.KI,'KII',K.KII,'J',K.J,'KI_COD',K.KI_COD,'KII_COD',K.KII_COD, ...
 'EDI_all',K.EDI_all,'EDI4x4',K.EDI4x4,'compliance_mm_per_N',K.compliance_mm_per_N,'activeArea_mm2',K.activeArea_mm2,'Ep_matrix',K.Ep_matrix, ...
 'relativeResidual',K.relativeResidual,'staticsMax',K.staticsMax,'energyIdentityRel',K.energyIdentityRel,'fullPolyOpeningMin_mm',K.fullPolyOpeningMin_mm, ...
 'CMOD_mm',K.CMOD_mm,'activeInterfaceBalanceRel',K.activeInterfaceBalanceRel,'activeAnnulusResultantRel',K.activeAnnulusResultantRel,'codFitPairs',K.codFitPairs, ...
 'KII_sign_edi_vs_cod_match',K.KII_sign_edi_vs_cod_match);
end
