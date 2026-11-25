function O=g2_lp2a3_chain(env,ops)
%G2_LP2A3_CHAIN  Advance ONE LP2-A3 case (S9 to at most S11) from its last accepted state.
% Prospective copy of the accepted g2_lp2_chain (LP2-A1) with only these changes: LP2-A3 record
% schemas and messages; g2_lp2a3_failure_class; ops.classify receives the candidate tip (1-mm
% ring-proximity guard); the closing candidate after an accepted S11 is an S12 forecast for
% INFORMATION ONLY (outside the campaign; no admission, mesh or FEM). All operations that touch
% geometry, mesh or physics are injected through ops (identical contract to g2_lp2_chain):
%   ops.forecast(parent,pol) ops.clearance(P,next,geom,pol) ops.classify(R,mask,pol,tip)
%   ops.admit(sd,k)  ops.computeState(sd,k,F,parent,parentHash) -> [St,sth,geomNew]  env.verifyAll()
% Outcomes per case (never a retry; physical arrest never inferred):
%   candidate not MATRIX_ADVANCE   -> TERMINAL(classification), no mesh, no solve
%   LOCAL failure                  -> HOLD.mat (if a state folder exists) + TERMINAL(NUMERICAL_HOLD)
%   accepted S11                   -> TERMINAL(CAMPAIGN_LIMIT_REACHED)
%   PREADMISSION_MEMORY / GLOBAL   -> ledger HOLD (blocks the campaign), HOLD.mat if a state folder
%                                     exists; NO terminal, NO closure
%   CAMPAIGN_REFUSAL               -> nothing written
pol=env.pol;tf=fullfile(env.chain,'TERMINAL.mat');parent=env.parent;parentHash=env.parentHash;geom=env.geom;
O=struct('status','','computed',0,'reused',0,'caseId',env.caseId,'terminal','','lastState',parent.stateIndex,'campaignClosed',false);
F=[];R=[];T=[];
for k=pol.caps.firstStateIndex:pol.caps.maxStateIndex
 sd=fullfile(env.chain,sprintf('S%d',k));sf=fullfile(sd,'STATE.mat');
 if isfile(sf)   % prefix already verified by the caller (g2_lp2_verify)
  [St,sth,ok]=g2_trajectory_record('read',sf);
  if ~ok,O=globalHold(O,env,k,sd,'G2LP2A3:HOLD_RECORD_INTEGRITY','Accepted state became unreadable.');return,end
  O.reused=O.reused+1;parent=St;parentHash=lower(sth);geom=St.clearanceGeometry;continue
 end
 if isfile(tf),break,end
 if strcmp(env.campMode,'VERIFY_ONLY')
  O=globalHold(O,env,k,'', 'G2LP1:HOLD_CAMPAIGN_CLOSED','Campaign is closed: no new state may be computed.',true);return
 end
 F=[];R=[];T=[];
 try
  F=ops.forecast(parent,pol);P=F.polyline_mm;
  R=ops.clearance(P(1:end-1,:),P(end,:),geom,pol);T=ops.classify(R,env.mask,pol,P(end,:));
 catch ME
  if strcmp(g2_lp2a3_failure_class(ME.identifier,false),'LOCAL')
   writeTerminal(tf,env,'NUMERICAL_HOLD',parent,parentHash,F,R,T,ME,'forecast/clearance/classification','candidate could not be evaluated');break
  end
  O=globalHold(O,env,k,'',ME.identifier,ME.message);return
 end
 if ~strcmp(T.classification,'MATRIX_ADVANCE')
  writeTerminal(tf,env,T.classification,parent,parentHash,F,R,T,[],'candidate','candidate segment fails a guard; no mesh, no solve');break
 end
 try
  ops.admit(sd,k);
 catch ME
  cls=g2_lp2a3_failure_class(ME.identifier,isfolder(sd));
  O=globalHold(O,env,k,sd,ME.identifier,ME.message,strcmp(cls,'CAMPAIGN_REFUSAL'));return
 end
 try
  [St,sth,geomNew]=ops.computeState(sd,k,F,parent,parentHash);O.computed=O.computed+1;
 catch ME
  if strcmp(g2_lp2a3_failure_class(ME.identifier,true),'LOCAL')
   writeHold(sd,env,k,parentHash,ME);
   writeTerminal(tf,env,'NUMERICAL_HOLD',parent,parentHash,F,R,T,ME,'mesh/audit/solve','local numerical HOLD; accepted prefix preserved; never retried');break
  end
  O=globalHold(O,env,k,sd,ME.identifier,ME.message);return
 end
 parent=St;parentHash=lower(sth);geom=geomNew;
end
if ~isfile(tf)&&parent.stateIndex==pol.caps.maxStateIndex
 p9=pol;p9.caps.maxStateIndex=pol.caps.maxStateIndex+1;p9.caps.maxArcLength_mm=pol.caps.maxArcLength_mm+pol.caps.increment_mm;
 note=sprintf('S%d accepted; S%d candidate forecast for information only (outside the campaign; no admission, mesh or FEM)',pol.caps.maxStateIndex,pol.caps.maxStateIndex+1);
 try
  F=ops.forecast(parent,p9);R=ops.clearance(F.polyline_mm(1:end-1,:),F.polyline_mm(end,:),geom,pol);T=ops.classify(R,env.mask,pol,F.polyline_mm(end,:));
 catch ME
  F=[];R=[];T=[];note=sprintf('S%d accepted; S%d information unavailable (%s)',pol.caps.maxStateIndex,pol.caps.maxStateIndex+1,ME.identifier);
 end
 writeTerminal(tf,env,'CAMPAIGN_LIMIT_REACHED',parent,parentHash,F,R,T,[],'limit',note);
end
% ---------------------------------------------------------------- common terminal verification and closure
if ~isfile(tf)
 O=globalHold(O,env,parent.stateIndex+1,'','G2LP2A3:HOLD_RECORD_INTEGRITY','Case ended without a terminal record.');return
end
[Tm,~,okT]=g2_trajectory_record('read',tf);
if ~okT||~strcmp(Tm.caseId,env.caseId)||Tm.lastAcceptedState~=parent.stateIndex||~strcmpi(Tm.parentSHA256,parentHash)||~strcmp(Tm.token,env.token)
 O=globalHold(O,env,parent.stateIndex,'','G2LP2A3:HOLD_RECORD_INTEGRITY','Terminal record does not bind the last accepted state.');return
end
O.terminal=Tm.classification;O.lastState=Tm.lastAcceptedState;O.status=['TERMINAL_' Tm.classification];O.terminalRecord=Tm;
tfs=cellfun(@(id)fullfile(env.rd,id,'TERMINAL.mat'),env.ids,'UniformOutput',false);
if all(cellfun(@isfile,tfs))&&~isfile(fullfile(env.lroot,'CLOSED.mat'))&&~strcmp(env.campMode,'VERIFY_ONLY')
 V=env.verifyAll();
 if ~V.pass
  O=globalHold(O,env,parent.stateIndex,'','G2LP2A3:HOLD_RECORD_INTEGRITY',['Pre-closure verification failed: ' strjoin(V.problems,'; ')]);return
 end
 shs=cell(1,numel(tfs));for z=1:numel(tfs),shs{z}=lower(g2_sha256_file(tfs{z}));end
 g2_lp1_campaign_ledger('write',env.lroot,'CLOSED','CLOSED.mat',struct('campaignId',env.campaignId,'runName',env.runName, ...
  'cases',{env.ids},'terminalSHA256',{shs},'closedUTC',utcNow()));
 O.campaignClosed=true;
end
end

% =====================================================================
function O=globalHold(O,env,k,sd,id,msg,refusal)
% Campaign-level stop. Campaign refusals write nothing; otherwise an immutable ledger HOLD entry
% blocks every later call (no reviewed resumption record exists) and a HOLD.mat is kept if the
% state folder exists. No TERMINAL record and no closure are produced.
if nargin<7,refusal=false;end
h=struct('schema','NewMetacomp.G2.LP2A3.Hold.v1','scope','GLOBAL','stateIndex',k,'caseId',env.caseId,'identifier',id,'message',msg,'physicalArrest',false);
if ~refusal
 if ~isempty(sd)&&isfolder(sd)&&~isfile(fullfile(sd,'HOLD.mat')),g2_trajectory_record('write',fullfile(sd,'HOLD.mat'),h);end
 try
  g2_lp1_campaign_ledger('write',env.lroot,'HOLD',sprintf('HOLD_GLOBAL_%s_S%d_%s.mat',env.caseId,k,datestr(now,'yyyymmddTHHMMSSFFF')), ...
   struct('campaignId',env.campaignId,'caseId',env.caseId,'stateIndex',k,'hold',h));
 catch
 end
end
O.status='GLOBAL_HOLD';O.hold=struct('identifier',id,'message',msg,'campaignRefusal',refusal);
fprintf(2,'G2_LP2A3_GLOBAL_HOLD %s S%d %s: %s\n',env.caseId,k,id,msg);
end
function writeHold(sd,env,k,parentHash,ME)
if ~isfolder(sd),mkdir(sd);end
hf=fullfile(sd,'HOLD.mat');
if ~isfile(hf)
 g2_trajectory_record('write',hf,struct('schema','NewMetacomp.G2.LP2A3.Hold.v1','scope','LOCAL','stateIndex',k,'caseId',env.caseId, ...
  'identifier',ME.identifier,'message',ME.message,'parentSHA256',parentHash,'physicalArrest',false));
end
end
function writeTerminal(tf,env,cls,parent,parentHash,F,R,T,ME,stage,note)
tip=parent.polyline_mm(end,:);g=env.pol.geometry;cen=g.centres_mm;
cand=struct('polyline_mm',[],'classification','','constraints',struct('object',{},'type',{},'guard',{},'margin_mm',{}),'clearance',struct());
if ~isempty(F),cand.polyline_mm=F.polyline_mm;end
if ~isempty(T),cand.classification=T.classification;cand.constraints=T.constraints;end
if ~isempty(R),cand.clearance=R.metrics;end
fail=struct('identifier','','message','','stage',stage);if ~isempty(ME),fail.identifier=ME.identifier;fail.message=ME.message;end
d=vecnorm(cen-tip,2,2).'-g.ringR_mm;mask=reshape(env.mask,1,3);
[~,near]=min(d);
Rt=struct('schema','NewMetacomp.G2.LP2A3.Terminal.v1','caseId',env.caseId,'mask',mask,'classification',cls, ...
 'lastAcceptedState',parent.stateIndex,'acceptedPrefixLength',parent.stateIndex-env.pol.caps.firstStateIndex+1, ...
 'lastTip_mm',tip,'lastArc_mm',sum(vecnorm(diff(parent.polyline_mm),2,2)), ...
 'lastTipToRingCircle_mm',d,'lastTipToHoleCircle_mm',vecnorm(cen-tip,2,2).'-g.holeR_mm, ...
 'nearestRing',near,'nearestRingActive',logical(mask(near)), ...
 'candidate',cand,'failure',fail,'truncatedByCeiling',strcmp(cls,'CAMPAIGN_LIMIT_REACHED'),'candidateIsInformationOnly',strcmp(cls,'CAMPAIGN_LIMIT_REACHED'), ...
 'parentSHA256',parentHash,'token',env.token,'note',note,'interfaceEncounter',false,'physicalArrest',false);
if ~isfolder(fileparts(tf)),mkdir(fileparts(tf));end
g2_trajectory_record('write',tf,Rt);
fprintf('G2_LP2A3_TERMINAL %s %s last=S%d (%s)\n',env.caseId,cls,parent.stateIndex,note);
end
function s=utcNow()
s=char(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ss.SSS''Z'''));
end
