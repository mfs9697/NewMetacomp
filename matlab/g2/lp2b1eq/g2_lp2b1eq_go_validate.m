function V=g2_lp2b1eq_go_validate(G,C,callerToken,git,loadEvidence)
%G2_LP2B1EQ_GO_VALIDATE  Pure validator of a decoded GO_LP2B1_EQ record (no FEM, no write).
%  V = g2_lp2b1eq_go_validate(G, C, token)                      real git (g2_lp2a2_git: HEAD~1, metachar refusal)
%  V = g2_lp2b1eq_go_validate(G, C, token, git, loadEvidence)   injected git / evidence (tests)
% Prospective copy of the accepted g2_lp2a3_go_validate. Every check is evaluated and named; pass needs all:
%  fields       all required fields present (scalar struct)
%  decision     'GO_LP2B1_EQ'
%  decisionUrl  https://github.com/mfs9697/NewMetacomp/pull|issues/<n>#issuecomment-<n> | #pullrequestreview-<n>
%  token        G.token == C.token == callerToken
%  campaign     campaignId, campaignScope, runName equal the policy; not a forbidden historical name
%  solves       exactly {'EQB-soft1-S9','EQB-H-S10'} in this order (cell array of text)
%  limits       solveLimit 2, attemptsPerSolve 1, seedSpacing_mm 0.40
%  approvedHead full 40-character lower-case hex (ONLY then passed to git)
%  evidence     contract evidence under the policy evidence directory, SHA-256 equal, passed == total >= 40,
%               physicalSolves 0, produced for this token
%  ancestor     approvedHead is an ancestor of HEAD
%  activationBinding  HEAD~1 == approvedHead and HEAD changes exactly the GO file
pol=C.policy;au=pol.authorization;
if nargin<4||isempty(git),git=defaultGit(C.repo);end
if nargin<5||isempty(loadEvidence),loadEvidence=@(p)readEvidence(C.repo,p);end
req={'decision','decisionUrl','approvedHead','token','campaignId','campaignScope','runName','solves','solveLimit','attemptsPerSolve', ...
 'seedSpacing_mm','contractEvidenceFile','contractEvidenceSHA256'};
c=struct();c.fields=isstruct(G)&&isscalar(G)&&all(isfield(G,req));gf=@(f)fieldOr(G,f);
c.decision=c.fields&&isequal(gf('decision'),'GO_LP2B1_EQ');
u=gf('decisionUrl');
c.decisionUrl=c.fields&&ischar(u)&&~isempty(regexp(u,'^https://github\.com/mfs9697/NewMetacomp/(pull|issues)/[1-9][0-9]*#(issuecomment|pullrequestreview)-[1-9][0-9]*$','once'));
c.token=c.fields&&ischar(gf('token'))&&strcmp(gf('token'),C.token)&&(ischar(callerToken)||isstring(callerToken))&&strcmp(char(callerToken),C.token);
c.campaign=c.fields&&isequal(gf('campaignId'),au.campaignId)&&isequal(gf('campaignScope'),au.campaignScope)&&isequal(gf('runName'),au.runName)&& ...
 ~any(strcmp(au.runName,cellstr(au.forbiddenRunNames)))&&~any(strcmp(au.campaignId,cellstr(au.forbiddenCampaignIds)));
sv=gf('solves');ids=cellfun(@(x)x.id,C.solves,'UniformOutput',false);
c.solves=c.fields&&iscellstr(sv)&&isequal(reshape(sv,1,[]),{'EQB-soft1-S9','EQB-H-S10'})&&isequal(ids,{'EQB-soft1-S9','EQB-H-S10'});
num=@(f,v)isnumeric(gf(f))&&isscalar(gf(f))&&gf(f)==v;
c.limits=c.fields&&num('solveLimit',pol.solveLimit)&&pol.solveLimit==2&&num('attemptsPerSolve',1)&&num('seedSpacing_mm',pol.meshFamily.seedSpacing_mm)&&pol.meshFamily.seedSpacing_mm==0.40;
h=gf('approvedHead');c.approvedHead=c.fields&&ischar(h)&&~isempty(regexp(h,'^[0-9a-f]{40}$','once'));
c.evidence=false;ef=gf('contractEvidenceFile');es=gf('contractEvidenceSHA256');
if c.fields&&ischar(ef)&&ischar(es)&&~isempty(regexp(es,'^[0-9a-f]{64}$','once'))&&startsWith(ef,au.contractEvidenceDir)&& ...
  isempty(strfind(ef,'..'))&&~isempty(regexp(ef,'^[A-Za-z0-9_./-]+$','once')) %#ok<STREMP>
 E=loadEvidence(ef);
 if isstruct(E)&&isfield(E,'exists')&&isequal(E.exists,true)&&strcmpi(E.sha256,es)
  try
   T=jsondecode(E.text);
   c.evidence=isstruct(T)&&all(isfield(T,{'passed','total','physicalSolves','token'}))&&isequal(T.passed,T.total)&&T.total>=40&& ...
    isequal(T.physicalSolves,0)&&ischar(T.token)&&strcmp(T.token,C.token);
  catch
   c.evidence=false;
  end
 end
end
c.ancestor=false;c.activationBinding=false;
if c.approvedHead   % never pass an unvalidated string to git
 c.ancestor=logical(git.isAncestor(h));
 ch=git.changedFiles(h);if ischar(ch),ch={ch};end
 c.activationBinding=strcmp(git.headParent(),h)&&isequal(sort(reshape(ch,1,[])),{au.goPath});
end
v=cell2mat(struct2cell(c));f=fieldnames(c);
V=struct('pass',all(v),'checks',c,'failed',{f(~v)},'campaignId',au.campaignId,'runName',au.runName);
end

function v=fieldOr(G,f)
if isstruct(G)&&isscalar(G)&&isfield(G,f),v=G.(f);else,v=[];end
end
function g=defaultGit(repo)
g=struct('isAncestor',@(h)val(g2_lp2a2_git('isAncestor',repo,h),false), ...
 'headParent',@()val(g2_lp2a2_git('parent',repo),''), ...
 'changedFiles',@(h)val(g2_lp2a2_git('changedFiles',repo,h),{'<git-query-failed>'}));
end
function v=val(R,bad)
if R.ok,v=R.value;else,v=bad;end
end
function E=readEvidence(repo,p)
f=fullfile(repo,strrep(p,'/',filesep));E=struct('exists',isfile(f),'sha256','','text','');
if E.exists,E.sha256=lower(g2_sha256_file(f));E.text=fileread(f);end
end
