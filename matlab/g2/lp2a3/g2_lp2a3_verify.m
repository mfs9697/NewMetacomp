function R=g2_lp2a3_verify(V)
%G2_LP2A3_VERIFY  Read-only semantic verification of LP2-A3 chains, terminal records and ledger.
% Prospective copy of the accepted g2_lp2_verify with only these changes: LP2-A3 schemas; the state
% binds the token, the policy and the g2, lp2a2 and lp2a3 source digests; parents are the original
% LP2-A1 S8 states; every accepted state must record the default mesh rung (seedRung 1, 0.45 mm);
% the terminal labels come from the LP2-A3 policy (PASSIVE_CONTOUR_APPROACH added).
%  R = g2_lp2a3_verify(V)      R.pass, R.problems (cellstr), R.cases
% V fields: rd, lroot, ids, masks (4x3), parents.(id).state/.stateSHA256, pol, token, policySHA256,
% g2SourceSHA256, lp2a2SourceSHA256, lp2a3SourceSHA256, cases (default all), requireTerminal.
% Nothing is written and nothing is recomputed except the geometric recurrence (g2_lp2_forecast);
% any inconsistency is a problem (integrity HOLD).
if ~isfield(V,'cases')||isempty(V.cases),V.cases=V.ids;end
if ~isfield(V,'requireTerminal'),V.requireTerminal=false;end
pol=V.pol;labels=cellstr(pol.classification.labels);P={};folders={};S=struct();
for i=1:numel(V.ids)
 id=V.ids{i};chain=fullfile(V.rd,id);mask=reshape(V.masks(i,:),1,3);
 d=dir(fullfile(chain,'S*'));d=d([d.isdir]);ks=sort(cellfun(@(n)str2double(n(2:end)),{d.name}));ks=ks(isfinite(ks));
 for k=ks,folders{end+1}=sprintf('%s_S%d',id,k);end %#ok<AGROW>
 if ~any(strcmp(V.cases,id)),continue,end
 c=struct('caseId',id,'acceptedStates',[],'failedFolder',NaN,'terminal','');
 if ~isempty(ks)&&(ks(1)~=pol.caps.firstStateIndex||any(diff(ks)~=1)||ks(end)>pol.caps.maxStateIndex)
  bad(sprintf('%s: state folders are not contiguous from S%d (%s)',id,pol.caps.firstStateIndex,mat2str(ks)));
 end
 parent=V.parents.(id).state;ph0=lower(V.parents.(id).stateSHA256);
 for k=ks
  sd=fullfile(chain,sprintf('S%d',k));sf=fullfile(sd,'STATE.mat');
  if ~isfile(sf)
   if k~=ks(end),bad(sprintf('%s S%d: state folder without STATE before the end of the chain',id,k));end
   [~,~,okh]=g2_trajectory_record('read',fullfile(sd,'HOLD.mat'));
   if ~okh,bad(sprintf('%s S%d: folder without STATE and without a valid HOLD record',id,k));end
   c.failedFolder=k;continue
  end
  [St,sth,ok]=g2_trajectory_record('read',sf);
  if ~ok,bad(sprintf('%s S%d: STATE manifest fails',id,k));continue,end
  chk(strcmp(St.schema,'NewMetacomp.G2.LP2A3.State.v1')&&St.stateIndex==k&&strcmp(St.caseId,id)&&isequal(reshape(St.mask,1,3),mask),'%s S%d: identity',id,k);
  chk(strcmp(St.token,V.token)&&strcmpi(St.policySHA256,V.policySHA256)&&strcmpi(St.g2SourceSHA256,V.g2SourceSHA256)&& ...
   strcmpi(St.lp2a2SourceSHA256,V.lp2a2SourceSHA256)&&strcmpi(St.lp2a3SourceSHA256,V.lp2a3SourceSHA256),'%s S%d: token, policy or source digest',id,k);
  chk(isfield(St,'seedRung')&&isequal(St.seedRung,1)&&isfield(St,'seedSpacing_mm')&&isequal(St.seedSpacing_mm,0.45),'%s S%d: not the default 0.45 mm mesh rung',id,k);
  chk(strcmpi(St.parentSHA256,ph0),'%s S%d: parent SHA-256 link',id,k);
  mf=fullfile(sd,'MESH.mat');mh='';if isfile(mf),mh=lower(g2_sha256_file(mf));end
  chk(~isempty(mh)&&strcmpi(mh,St.meshSHA256),'%s S%d: MESH hash',id,k);
  [Ph,phs,okp]=g2_trajectory_record('read',fullfile(sd,'PHASE.mat'));
  chk(okp&&strcmpi(phs,St.phaseSHA256)&&strcmpi(Ph.meshSHA256,mh)&&Ph.stateIndex==k&&strcmp(Ph.caseId,id)&&isequal(reshape(Ph.mask,1,3),mask), ...
   '%s S%d: PHASE hash or links',id,k);
  [So,sos,oks]=g2_trajectory_record('read',fullfile(sd,'SOLUTION.mat'));
  chk(oks&&strcmpi(sos,St.solutionSHA256)&&strcmpi(So.meshSHA256,mh)&&strcmpi(So.phaseSHA256,phs)&&So.stateIndex==k&&strcmp(So.caseId,id), ...
   '%s S%d: SOLUTION hash or links',id,k);
  if oks,chk(isequal(St.KI,So.K.KI)&&isequal(St.KII,So.K.KII),'%s S%d: signed K_I/K_II differ between STATE and SOLUTION',id,k);end
  try
   F=g2_lp2_forecast(parent,pol);chk(isequal(F.polyline_mm,St.polyline_mm)&&isequal(F.tangent,St.tangent)&&isequal(St.tip_mm,St.polyline_mm(end,:)), ...
    '%s S%d: polyline or tangent is not the recurrence from the parent',id,k);
  catch ME
   bad(sprintf('%s S%d: recurrence check failed (%s)',id,k,ME.identifier));
  end
  c.acceptedStates(end+1)=k;parent=St;ph0=lower(sth);
 end
 last=parent.stateIndex;tf=fullfile(chain,'TERMINAL.mat');
 if isfile(tf)
  [Tm,~,okt]=g2_trajectory_record('read',tf);
  if ~okt,bad(sprintf('%s: TERMINAL manifest fails',id));
  else
   c.terminal=Tm.classification;
   chk(strcmp(Tm.caseId,id)&&strcmp(Tm.token,V.token)&&any(strcmp(Tm.classification,labels))&&~strcmp(Tm.classification,'INTERFACE_ENCOUNTER'), ...
    '%s: terminal identity, token or label',id);
   chk(Tm.lastAcceptedState==last&&Tm.acceptedPrefixLength==last-pol.caps.firstStateIndex+1&&strcmpi(Tm.parentSHA256,ph0), ...
    '%s: terminal does not bind the last accepted state S%d',id,last);
   if isfinite(c.failedFolder),chk(strcmp(Tm.classification,'NUMERICAL_HOLD')&&c.failedFolder==last+1,'%s: failed folder S%d inconsistent with the terminal',id,c.failedFolder);end
   if strcmp(Tm.classification,'CAMPAIGN_LIMIT_REACHED'),chk(last==pol.caps.maxStateIndex,'%s: ceiling terminal before S%d',id,pol.caps.maxStateIndex);end
  end
 elseif V.requireTerminal
  bad(sprintf('%s: TERMINAL record missing',id));
 end
 S.(id)=c;
end
% ---------------------------------------------------------------- ledger
L=g2_lp1_campaign_ledger('snapshot',V.lroot);
chk(isequal(L.integrityOK,true),'ledger integrity: %s',strjoin(L.problems,','));
chk(~isempty(L.receipt)&&strcmp(L.receipt.token,V.token),'ledger receipt missing or bound to another token');
ad=sort(cellstr(L.admits));fo=sort(folders);
chk(isequal(ad(:),fo(:)),'ADMIT entries (%s) differ from state folders (%s)',strjoin(ad,','),strjoin(fo,','));
if L.closed
 [Cr,~,okc]=g2_trajectory_record('read',fullfile(V.lroot,'CLOSED.mat'));
 tfs=cellfun(@(id)fullfile(V.rd,id,'TERMINAL.mat'),V.ids,'UniformOutput',false);
 if okc&&all(cellfun(@isfile,tfs))
  cur=cellfun(@(f)lower(g2_sha256_file(f)),tfs,'UniformOutput',false);
  chk(isequal(cellstr(Cr.cases(:)).',V.ids)&&isequal(lower(cellstr(Cr.terminalSHA256(:))).',cur),'CLOSED does not bind the current TERMINAL records');
 else
  bad('CLOSED exists but a TERMINAL record or the CLOSED record is missing/unverifiable');
 end
end
R=struct('pass',isempty(P),'problems',{P},'cases',S,'ledgerAdmits',numel(L.admits),'ledgerHolds',numel(L.holds),'closed',L.closed);
 function chk(c,varargin),if ~c,bad(sprintf(varargin{:}));end,end
 function bad(s),P{end+1}=s;end
end
