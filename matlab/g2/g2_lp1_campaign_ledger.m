function out=g2_lp1_campaign_ledger(action,ledgerRoot,varargin)
%G2_LP1_CAMPAIGN_LEDGER Local, immutable admission ledger of one LP1 campaign (VG2, Issue #62).
% Location (chosen by the controller): <repo>/outputs/g2_lp1_campaign_ledger/<campaignId>/,
% outside the run folder, so deleting a run folder does not erase its admissions.
% Every entry is an immutable g2_trajectory_record (MAT + SHA-256 manifest; no overwrite).
%   L = g2_lp1_campaign_ledger('snapshot',root)              read-only, verifies every entry
%   h = g2_lp1_campaign_ledger('write',root,kind,name,record) kind: RECEIPT|ADMIT|HOLD|RESUME|CLOSED
% RESIDUAL THREAT: this is local state. Deleting the whole ledger AND the run folder, or
% running from an independent clone, cannot be detected here. It is not a cryptographic
% or global single-use guarantee; the GO must also be removed/revoked after closure.
switch lower(action)
 case 'snapshot'
  out=struct('integrityOK',true,'receipt',[],'admits',{{}},'holds',struct('file',{},'sha256',{},'caseId',{},'stateIndex',{}), ...
   'resumes',{{}},'closed',false,'problems',{{}},'entries',{{}});
  if ~isfolder(ledgerRoot),return,end
  d=dir(ledgerRoot);d=d(~[d.isdir]);
  for i=1:numel(d)
   n=d(i).name;
   if endsWith(n,'.mat.manifest.json')
    if ~isfile(fullfile(ledgerRoot,extractBefore(n,'.manifest.json'))),out=bad(out,['orphan manifest ',n]);end
    continue
   end
   if ~endsWith(n,'.mat'),out=bad(out,['unexpected file ',n]);continue,end
   [r,h,ok]=g2_trajectory_record('read',fullfile(ledgerRoot,n));
   if ~ok,out=bad(out,['unverifiable ',n]);continue,end
   out.entries{end+1}=n;
   kind=regexp(n,'^(RECEIPT|ADMIT|HOLD|RESUME|CLOSED)','tokens','once');
   if isempty(kind)||~isfield(r,'ledgerKind')||~strcmp(r.ledgerKind,kind{1}),out=bad(out,['kind mismatch ',n]);continue,end
   switch kind{1}
    case 'RECEIPT'
     if ~strcmp(n,'RECEIPT.mat')||~isempty(out.receipt),out=bad(out,'duplicate receipt');else,out.receipt=r;end
    case 'ADMIT',out.admits{end+1}=r.stateKey;
    case 'HOLD',out.holds(end+1)=struct('file',n,'sha256',lower(h),'caseId',r.caseId,'stateIndex',r.stateIndex);
    case 'RESUME',out.resumes{end+1}=lower(r.holdRecordSHA256);
    case 'CLOSED',out.closed=true;
   end
  end
  if ~isempty(out.receipt)
   % every non-receipt entry must carry the receipt's campaign identity
   for i=1:numel(out.entries)
    r=g2_trajectory_record('read',fullfile(ledgerRoot,out.entries{i}));
    if ~isfield(r,'campaignId')||~strcmp(r.campaignId,out.receipt.campaignId),out=bad(out,['foreign entry ',out.entries{i}]);end
   end
  end
 case 'write'
  [kind,name,rec]=varargin{:};
  assert(any(strcmp(kind,{'RECEIPT','ADMIT','HOLD','RESUME','CLOSED'}))&&startsWith(name,kind)&& ...
   ~isempty(regexp(name,'^[A-Za-z0-9_]+\.mat$','once')),'G2LP1:HOLD_CAMPAIGN_INTEGRITY','Invalid ledger entry name.');
  if ~isfolder(ledgerRoot),mkdir(ledgerRoot);end
  rec.ledgerKind=kind;rec.schema=['NewMetacomp.G2.LP1.CampaignLedger.',kind,'.v1'];
  out=lower(g2_trajectory_record('write',fullfile(ledgerRoot,name),rec));
 otherwise
  error('G2LP1:HOLD_INPUT','Unknown ledger action.');
end
end

function L=bad(L,why)
L.integrityOK=false;L.problems{end+1}=why;
end
