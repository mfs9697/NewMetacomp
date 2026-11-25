% M5-X6 after closure: six VERIFY_ONLY calls (zero solves), ledger snapshot, record checks, preregistered analysis.
ex='<repo>';
out='<scratch>\m5x6run\verify';
addpath(fullfile(ex,'scripts','g2','m5','x6'));
RUN='run_m5x6_crossed_s4_b9_v1';CID='G2-M5-X6-001';ids={'X6-01','X6-02','X6-03','X6-04','X6-05','X6-06'};
try
 assert(~isfolder(out));mkdir(out);
 C=g2_m5x6_context();lroot=fullfile(ex,'outputs','g2_m5x6_campaign_ledger',CID);rd=fullfile(ex,'outputs','g2_m5x6_crossed_v1',RUN);
 L0=g2_lp1_campaign_ledger('snapshot',lroot);
 V=struct('config',{},'status',{},'computed',{},'reused',{},'mode',{},'stateSHA256',{},'solutionSHA256',{},'solutionInState',{},'stateEqualsSolution',{},'sifPass',{},'auditPass',{});
 for k=1:6
  O=g2_m5x6_run('Config',ids{k},'Run',true,'AuthToken',C.token,'RunName',RUN);
  key=strrep(ids{k},'-','_');[St,hs,ok1]=g2_trajectory_record('read',fullfile(rd,key,'STATE.mat'));[So,ho,ok2]=g2_trajectory_record('read',fullfile(rd,key,'SOLUTION.mat'));K=So.K;
  V(end+1)=struct('config',ids{k},'status',O.status,'computed',O.computed,'reused',O.reused,'mode',O.campaignMode,'stateSHA256',lower(hs), ...
   'solutionSHA256',lower(ho),'solutionInState',ok1&&ok2&&strcmpi(St.solutionSHA256,ho), ...
   'stateEqualsSolution',isequal(St.KI,K.KI)&&isequal(St.KII,K.KII)&&isequal(St.J,K.J)&&isequal(St.EDI_all,K.EDI_all)&&isequal(St.KI_COD,K.KI_COD), ...
   'sifPass',isequal(K.pass,true)&&isempty(K.failedCriteria),'auditPass',isequal(St.swappedMaterialAudit.pass,true)); %#ok<SAGROW>
  fprintf('M5X6_VERIFY %s %s computed=%d mode=%s state=%s sol=%d eq=%d sif=%d audit=%d\n',ids{k},O.status,O.computed,O.campaignMode,lower(hs(1:12)),V(k).solutionInState,V(k).stateEqualsSolution,V(k).sifPass,V(k).auditPass);
 end
 L1=g2_lp1_campaign_ledger('snapshot',lroot);
 Lsum=struct('integrityOK',L1.integrityOK,'closed',L1.closed,'admits',{L1.admits},'holds',numel(L1.holds),'resumes',numel(L1.resumes), ...
  'entries',{L1.entries},'unchangedByVerify',isequal(L0.entries,L1.entries)&&isequal(L0.admits,L1.admits));
 R=struct('schema','NewMetacomp.G2.M5X6.VerifyOnly.v1','calls',V,'ledger',Lsum,'zeroSolves',all([V.computed]==0), ...
  'allReusedVerifyOnly',all(strcmp({V.status},'REUSED_ZERO_SOLVE'))&&all(strcmp({V.mode},'VERIFY_ONLY')), ...
  'allRecordsVerified',all([V.solutionInState])&&all([V.stateEqualsSolution])&&all([V.sifPass])&&all([V.auditPass]),'token',C.token,'sourceCommit',C.preflight.sourceCommit);
 fid=fopen(fullfile(out,'M5X6_VERIFY_ONLY.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
 fprintf('M5X6_VERIFY_DONE zeroSolves=%d reused=%d records=%d ledger closed=%d admits=%d holds=%d integrity=%d\n',R.zeroSolves,R.allReusedVerifyOnly,R.allRecordsVerified,L1.closed,numel(L1.admits),numel(L1.holds),L1.integrityOK);
 A=m5x6_analyze(ex,RUN,CID,fullfile(out,'M5X6_ANALYSIS.json'));
 fprintf('M5X6_ANALYSIS_DONE\n');
catch ME
 fprintf(2,'M5X6_VERIFY_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
