% LP2-A1 after closure: four VERIFY_ONLY calls (zero solves, no writes), full read-only verification of
% production records (links, gates, activation, MTS/G/J recomputation, recurrence, terminals, ledger),
% and the preregistered analysis. No FEM.
ex='<repo>';
out='<scratch>';
addpath(fullfile(ex,'matlab','g2','lp2'));RUN='run_lp2a_s5_s8_v1';CID='G2-LP2A-001';ids={'H','stiff13','soft2','soft1'};
try
 assert(~isfolder(out));mkdir(out);C=g2_lp2_context();pol=C.policy;
 rd=fullfile(ex,'outputs','g2_lp2a_paths_v1',RUN);lroot=fullfile(ex,'outputs','g2_lp2a_campaign_ledger',CID);
 L0=listing(rd,lroot);
 vo={};for i=1:4
  O=g2_lp2_run('Case',ids{i},'Run',true,'AuthToken',C.token,'RunName',RUN);
  vo{end+1}=struct('caseId',ids{i},'status',O.status,'computed',O.computed,'reused',O.reused,'mode',O.campaignMode,'verifyPass',O.verification.pass); %#ok<SAGROW>
  fprintf('LP2A_VERIFY_ONLY %s %s computed=%d reused=%d mode=%s verify=%d\n',ids{i},O.status,O.computed,O.reused,O.campaignMode,O.verification.pass);
 end
 L1=listing(rd,lroot);noWrites=isequal(L0,L1);
 % full verifier
 A0=fullfile(ex,strrep(pol.parents.run,'/',filesep));V=struct('rd',rd,'lroot',lroot,'ids',{ids},'masks',reshape([pol.cases.mask],3,[]).','parents',struct(), ...
  'pol',pol,'token',C.token,'policySHA256',C.policySHA256,'g2SourceSHA256',C.g2SourceSHA256,'lp2SourceSHA256',C.lp2SourceSHA256,'requireTerminal',true);
 for i=1:4,f=fullfile(A0,ids{i},'S4','STATE.mat');[St,~,~]=g2_trajectory_record('read',f);V.parents.(ids{i})=struct('state',St,'stateSHA256',lower(g2_sha256_file(f)));end
 Rv=g2_lp2_verify(V);
 % numerical gates, activation, recomputed MTS/G/J per production state
 ns={};Em=pol.bvp.E_MPa;Ep=Em;   % plane stress E'=E
 for i=1:4
  mask=logical(V.masks(i,:));
  for k=5:8
   sd=fullfile(rd,ids{i},sprintf('S%d',k));[St,~,~]=g2_trajectory_record('read',fullfile(sd,'STATE.mat'));[So,~,~]=g2_trajectory_record('read',fullfile(sd,'SOLUTION.mat'));
   [Ph,~,~]=g2_trajectory_record('read',fullfile(sd,'PHASE.mat'));K=So.K;M=g2_mts_direction(K.KI,K.KII);cr=cell2mat(struct2cell(K.criteria));
   expLab=ones(size(Ph.owner));sel=Ph.owner>0;expLab(sel)=1+double(mask(Ph.owner(sel)));
   r=struct('caseId',ids{i},'state',k,'sifCriteria',sprintf('%d/%d',nnz(cr),numel(cr)),'sifPass',isequal(K.pass,true)&&all(cr)&&numel(cr)==16, ...
    'MTSrecomputed',abs(M.theta_deg-St.MTS_deg)<=1e-12&&M.admissibleForStep,'Grecomputed',abs(St.G/((K.KI^2+K.KII^2)/Ep)-1)<=1e-12,'Jequal',isequal(St.J,K.J), ...
    'activationLabels',isequal(Ph.labels(:),expLab(:)),'phaseCounts',isequal(K.phaseCounts(:).',[nnz(expLab==1),nnz(expLab==2)]), ...
    'CODminusEDI_rel',St.CODminusEDI_rel,'pathSpread_rel',St.pathSpread_rel,'JoverGminus1',St.JoverGminus1,'T3',St.T3,'solveSeconds',St.solveSeconds, ...
    'accepted',strcmp(St.numericalStatus,'ACCEPTED'));
   r.pass=r.sifPass&&r.MTSrecomputed&&r.Grecomputed&&r.Jequal&&r.activationLabels&&r.phaseCounts&&r.accepted;ns{end+1}=r; %#ok<SAGROW>
  end
 end
 ns=[ns{:}];
 Lg=g2_lp1_campaign_ledger('snapshot',lroot);
 Rver=struct('schema','NewMetacomp.G2.LP2A.VerifyOnly.v1','verifyOnlyCalls',[vo{:}],'noWritesDuringVerifyOnly',noWrites,'filesChecked',size(L0,1), ...
  'verifier',Rv,'numericalChecks',ns,'allNumericalPass',all([ns.pass]),'ledger',struct('integrityOK',Lg.integrityOK,'admits',numel(Lg.admits), ...
  'holds',numel(Lg.holds),'closed',Lg.closed,'receiptToken',strcmp(Lg.receipt.token,C.token)),'token',C.token,'sourceCommit',C.preflight.sourceCommit);
 fid=fopen(fullfile(out,'LP2A_VERIFY_ONLY.json'),'w');fwrite(fid,jsonencode(Rver,'PrettyPrint',true),'char');fclose(fid);
 fprintf('LP2A_VERIFY_DONE noWrites=%d verifier=%d problems=%d numerical=%d/%d ledger admits=%d holds=%d closed=%d\n',noWrites,Rv.pass,numel(Rv.problems), ...
  nnz([ns.pass]),numel(ns),numel(Lg.admits),numel(Lg.holds),Lg.closed);
 % analysis: A0 S0-S4 + LP2 S5-S8
 ch=struct();
 for i=1:4
  ch.(ids{i})=[arrayfun(@(k)fullfile(A0,ids{i},sprintf('S%d',k),'STATE.mat'),0:4,'UniformOutput',false), ...
   arrayfun(@(k)fullfile(rd,ids{i},sprintf('S%d',k),'STATE.mat'),5:8,'UniformOutput',false)];
  ch.terminal.(ids{i})=fullfile(rd,ids{i},'TERMINAL.mat');
 end
 An=g2_lp2_analyze(ch,fullfile(out,'LP2A_ANALYSIS.json'));
 for c={'stiff13','soft2','soft1'}
  r=An.(c{1});fprintf('LP2A_FG %-7s %s\n',c{1},sprintf('%+.5f ',100*r.F_G));fprintf('LP2A_D  %-7s %s\n',c{1},sprintf('%+.4f ',r.d_mm));
 end
 fprintf('LP2A_H1 %s | H2 %s | H4 %s\n',An.stiff13.H1.status,An.soft2.H2.status,An.H4.status);
catch ME
 fprintf(2,'LP2A_VERIFY_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
function H=listing(varargin)
H=cell(0,2);
for r=1:numel(varargin)
 d=dir(fullfile(varargin{r},'**','*'));d=d(~[d.isdir]);
 for k=1:numel(d),f=fullfile(d(k).folder,d(k).name);H(end+1,:)={f,lower(g2_sha256_file(f))};end %#ok<AGROW>
end
H=sortrows(H,1);
end
