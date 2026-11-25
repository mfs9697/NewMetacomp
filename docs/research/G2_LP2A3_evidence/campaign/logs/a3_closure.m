% LP2-A3 closure (READ-ONLY; after revocation): post-revocation refusals, controller verification, and a
% full dump of every LP2-A3 record, the ledger and the historical S0-S8 states for the independent audit.
ex='<repo>';
out='<scratch>';
addpath(fullfile(ex,'matlab','g2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a3'),'-begin');
TOK=['G2LP2A3|policy=7a6e17f8baa85c6e6f10186bfab3a9c10c9363e0acb5e532c00095961bf45d43|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947', ...
 '|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca|lp2a2source=f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd', ...
 '|lp2a3source=fa3bcecfa9cd3044253d5a72253e2058bccd044d32345f51650dcd775f42e002|parentsS8=da951c99c0d8c1d5dd731986d8f3b30e3db3f71854166a634d35b739757def8d', ...
 '|qualification=a77f49200f9f95b36260f44306afd4b05690d8ec9353c4fa71f4b5adbe5d4ded|cases=H,stiff13,soft2,soft1|states=S9-S11|maxAdmissions=12|seed=0.45|campaign=G2-LP2A3-001|run=run_lp2a3_s9_s11_v1'];
ids={'H','stiff13','soft2','soft1'};
% ---------------------------------------------------------------- 1 post-revocation refusals (real preflight)
try
 C=g2_lp2a3_context();H=g2_lp2a2_git('head',ex);
 assert(~isfile(C.goFile),'POST:GO','GO still present.');
 T0=treeHash(fullfile(ex,'outputs','g2_lp2a3_paths_v1'));T0b=treeHash(fullfile(ex,'outputs','g2_lp2a3_campaign_ledger'));[~,g0]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 P=struct('caseId',{},'identifier',{},'message',{});
 for k=1:4,i='<no error>';m='';try,g2_lp2a3_run('Case',ids{k},'Run',true,'AuthToken',TOK);catch ME,i=ME.identifier;m=ME.message;end,P(end+1)=struct('caseId',ids{k},'identifier',i,'message',m);fprintf('POSTREV %s %s\n',ids{k},i);end %#ok<SAGROW>
 T1=treeHash(fullfile(ex,'outputs','g2_lp2a3_paths_v1'));T1b=treeHash(fullfile(ex,'outputs','g2_lp2a3_campaign_ledger'));[~,g1]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));
 PR=struct('sourceCommit',H.value,'tokenEqualsAuthorization',strcmp(C.token,TOK),'probes',P,'runFilesUnchanged',isequal(T0,T1),'ledgerUnchanged',isequal(T0b,T1b), ...
  'runFiles',size(T0,1),'ledgerFiles',size(T0b,1),'gitClean',isempty(strtrim(g0))&&isempty(strtrim(g1)),'physicalSolves',0);
 PR.pass=all(strcmp({P.identifier},'G2LP2A3:HOLD_UNAUTHORIZED'))&&PR.runFilesUnchanged&&PR.ledgerUnchanged&&PR.gitClean&&PR.tokenEqualsAuthorization;
 wj(fullfile(out,'post','LP2A3_POST_REVOCATION.json'),PR);fprintf('POSTREV_RESULT pass=%d runFiles=%d ledger=%d\n',PR.pass,PR.runFiles,PR.ledgerFiles);
catch ME,fprintf(2,'POSTREV_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));end
% ---------------------------------------------------------------- 2 controller verification (read-only)
try
 Cv=g2_lp2a3_context('Preflight',false);pol=Cv.policy;
 V=struct('rd',Cv.runRoot,'lroot',Cv.ledgerRoot,'ids',{ids},'masks',reshape([pol.cases.mask],3,[]).','parents',struct(),'pol',pol,'token',Cv.token, ...
  'policySHA256',Cv.policySHA256,'g2SourceSHA256',Cv.g2SourceSHA256,'lp2a2SourceSHA256',Cv.lp2a2SourceSHA256,'lp2a3SourceSHA256',Cv.lp2a3SourceSHA256,'requireTerminal',true);
 Par=struct();for k=1:4,Pk=g2_lp2a3_parent(Cv,ids{k});Par.(ids{k})=Pk;V.parents.(ids{k})=struct('state',Pk.state,'stateSHA256',Pk.stateSHA256);end
 h0=treeHash(Cv.runRoot);Rv=g2_lp2a3_verify(V);RV=struct('pass',Rv.pass,'problems',{Rv.problems},'closed',Rv.closed,'ledgerAdmits',Rv.ledgerAdmits,'ledgerHolds',Rv.ledgerHolds,'unchanged',isequal(h0,treeHash(Cv.runRoot)));
 for k=1:4,c=Rv.cases.(ids{k});RV.cases.(ids{k})=struct('acceptedStates',c.acceptedStates,'failedFolder',c.failedFolder,'terminal',c.terminal);end
 wj(fullfile(out,'verify','LP2A3_CONTROLLER_VERIFY.json'),RV);fprintf('VERIFY pass=%d closed=%d admits=%d holds=%d unchanged=%d\n',RV.pass,RV.closed,RV.ledgerAdmits,RV.ledgerHolds,RV.unchanged);
catch ME,fprintf(2,'VERIFY_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));end
% ---------------------------------------------------------------- 3 full dump
try
 A=struct('schema','NewMetacomp.G2.LP2A3.RecordDump.v1','token',Cv.token,'runRoot',strrep(Cv.runRoot,ex,'<repo>'),'files',struct(),'cases',struct(),'ledger',struct(),'history',struct());
 A.files.run=relHash(Cv.runRoot,ex);A.files.ledger=relHash(Cv.ledgerRoot,ex);
 for k=1:4
  id=ids{k};ch=fullfile(Cv.runRoot,id);E=struct('states',{{}},'folders',{{}},'terminal',[],'holds',{{}});
  d=dir(fullfile(ch,'S*'));d=d([d.isdir]);E.folders={d.name};
  for j=1:numel(d)
   sd=fullfile(ch,d(j).name);S=struct('folder',d(j).name,'files',{{dir(sd).name}});S.files=S.files(~ismember(S.files,{'.','..'}));
   if isfile(fullfile(sd,'STATE.mat'))
    [St,sth]=g2_trajectory_record('read',fullfile(sd,'STATE.mat'));[So,soh]=g2_trajectory_record('read',fullfile(sd,'SOLUTION.mat'));[Ph,phh]=g2_trajectory_record('read',fullfile(sd,'PHASE.mat'));
    D=load(fullfile(sd,'MESH.mat'));
    S.stateSHA256=sth;S.solutionSHA256=soh;S.phaseSHA256=phh;S.meshFileSHA256=lower(g2_sha256_file(fullfile(sd,'MESH.mat')));
    S.state=rmfield(St,intersect(fieldnames(St),{'clearanceGeometry','EDI_all'}));S.state.EDI_all=St.EDI_all;
    K=So.K;S.K=struct('pass',K.pass,'failedCriteria',{K.failedCriteria},'criteria',K.criteria,'KI',K.KI,'KII',K.KII,'J',K.J,'KI_COD',K.KI_COD,'KII_COD',K.KII_COD, ...
     'EDI_all',K.EDI_all,'EDI4x4',K.EDI4x4,'compliance_mm_per_N',K.compliance_mm_per_N,'activeArea_mm2',K.activeArea_mm2,'phaseCounts',K.phaseCounts);
    S.solutionLinks=struct('schema',So.schema,'stateIndex',So.stateIndex,'caseId',So.caseId,'meshSHA256',So.meshSHA256,'phaseSHA256',So.phaseSHA256,'token',So.token,'approvedHead',So.approvedHead,'memoryGate',So.memoryGate);
    S.phase=struct('schema',Ph.schema,'stateIndex',Ph.stateIndex,'caseId',Ph.caseId,'mask',Ph.mask,'meshSHA256',Ph.meshSHA256,'auditPass',Ph.audit.pass, ...
     'meshAuditGates',Ph.audit.meshAudit.gatesPassed,'pairingPass',Ph.pairingAudit.pass,'pairingGates',Ph.pairingAudit.gatesPassed,'ownerCounts',accumarray(Ph.owner(:)+1,1,[4 1]).');
    S.mesh=struct('T3',size(D.T3,1),'X6',size(D.X6,1),'upperBankT6',numel(D.upperBankT6),'lowerBankT6',numel(D.lowerBankT6),'crackPolylineEqualsState',isequal(D.crackPolyline,St.polyline_mm), ...
     'seedRung',fieldOr(D,'seedRung'),'seedSpacing_mm',fieldOr(D,'seedSpacing_mm'));
    M=g2_mts_direction(K.KI,K.KII);S.mts=struct('theta_deg',M.theta_deg,'status',M.status,'stationarity',M.stationarityResidual_rel,'admissible',M.admissibleForStep);
   end
   if isfile(fullfile(sd,'HOLD.mat')),[Hh,hh]=g2_trajectory_record('read',fullfile(sd,'HOLD.mat'));S.hold=Hh;S.holdSHA256=hh;end
   E.states{end+1}=S; %#ok<SAGROW>
  end
  if isfile(fullfile(ch,'TERMINAL.mat')),[Tm,th]=g2_trajectory_record('read',fullfile(ch,'TERMINAL.mat'));E.terminal=Tm;E.terminalSHA256=th;end
  E.parent=struct('stateSHA256',Par.(id).stateSHA256,'state',rmfield(Par.(id).state,intersect(fieldnames(Par.(id).state),{'clearanceGeometry'})));
  A.cases.(id)=E;
 end
 L=g2_lp1_campaign_ledger('snapshot',Cv.ledgerRoot);A.ledger=struct('integrityOK',L.integrityOK,'admits',{L.admits},'holds',L.holds,'closed',L.closed,'problems',{L.problems});
 dl=dir(fullfile(Cv.ledgerRoot,'*.mat'));En={};for j=1:numel(dl),[r,hh]=g2_trajectory_record('read',fullfile(Cv.ledgerRoot,dl(j).name));En{end+1}=struct('file',dl(j).name,'sha256',hh,'record',r);end %#ok<AGROW>
 A.ledger.entries=En;
 % historical S0-S8 (A0 S0-S4 and LP2-A1 S5-S8), read only
 a0=fullfile(ex,'outputs','g2_lp1_matrix_paths_v1','run_a0_lp1_repro_v1');l1=fullfile(ex,'outputs','g2_lp2a_paths_v1','run_lp2a_s5_s8_v1');
 for k=1:4
  id=ids{k};Hs={};
  for s=0:8
   if s<=4,f=fullfile(a0,id,sprintf('S%d',s),'STATE.mat');else,f=fullfile(l1,id,sprintf('S%d',s),'STATE.mat');end
   [St,~,ok]=g2_trajectory_record('read',f);if ~ok,continue,end
   G=NaN;if isfield(St,'G'),G=St.G;else,G=(St.KI^2+St.KII^2)/3268.115;end
   J=NaN;if isfield(St,'J'),J=St.J;end
   mts=NaN;if isfield(St,'MTS_deg'),mts=St.MTS_deg;end
   Hs{end+1}=struct('stateIndex',s,'tip_mm',St.polyline_mm(end,:),'polyline_mm',St.polyline_mm,'KI',St.KI,'KII',St.KII,'G',G,'J',J,'MTS_deg',mts,'arc_mm',sum(vecnorm(diff(St.polyline_mm),2,2))); %#ok<AGROW>
  end
  A.history.(id)=Hs;
 end
 wj(fullfile(out,'verify','LP2A3_RECORD_DUMP.json'),A);fprintf('DUMP done\n');
catch ME,fprintf(2,'DUMP_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));end
function v=fieldOr(S,f),if isfield(S,f),v=S.(f);else,v=[];end,end
function H=treeHash(root)
H=cell(0,2);if ~isfolder(root),return,end
d=dir(fullfile(root,'**','*'));d=d(~[d.isdir]);for k=1:numel(d),p=fullfile(d(k).folder,d(k).name);H(end+1,:)={p,lower(g2_sha256_file(p))};end %#ok<AGROW>
if ~isempty(H),H=sortrows(H,1);end
end
function S=relHash(root,ex)
H=treeHash(root);S=struct('path',strrep(strrep(H(:,1),[ex filesep],''),'\','/'),'sha256',H(:,2));
end
function wj(f,S),fid=fopen(f,'w');fwrite(fid,jsonencode(S,'PrettyPrint',true),'char');fclose(fid);end
