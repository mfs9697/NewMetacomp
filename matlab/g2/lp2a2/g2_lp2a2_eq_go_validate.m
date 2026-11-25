function V=g2_lp2a2_eq_go_validate(G,C,callerToken,git)
%G2_LP2A2_EQ_GO_VALIDATE  Pure validator of the LP2-A2 equivalence GO record (no FEM, no write).
%  V = g2_lp2a2_eq_go_validate(G, C, token)        % G decoded GO file, C = g2_lp2a2_eq_context()
%  V = g2_lp2a2_eq_go_validate(G, C, token, git)   % injected git queries (tests)
% Every check is evaluated and named; V.pass requires all of them:
%  fields          all required fields present
%  decision        G.decision == 'GO_LP2A2_EQ'
%  token           G.token == C.token == callerToken
%  solveLimit      G.solveLimit == 4
%  solves          exactly {'EQ-H','EQ-stiff13','EQ-soft2','EQ-soft1'} in this order (= policy)
%  campaignId      G.campaignId == policy campaignId
%  decisionUrl     https://github.com/mfs9697/NewMetacomp/pull/<n>#issuecomment-<n> or
%                  #pullrequestreview-<n> (repository-specific)
%  approvedHead    full 40-character lower-case hex; ONLY then is it passed to git
%  contractEvidence  file exists in the repository and its SHA-256 == G.contractEvidenceSHA256
%  ancestor        approvedHead is an ancestor of HEAD
%  activationBinding  HEAD's parent == approvedHead and HEAD changes exactly the GO file
%                  (the activation commit adds only the GO file on the reviewed head)
% Default git queries go through g2_lp2a2_git (shell-safe on Windows cmd.exe: the parent is HEAD~1,
% never an unquoted caret; exit status checked; a commit is accepted only as an exact 40-hex output;
% any git failure makes ancestor / activationBinding false).
if nargin<4||isempty(git),git=defaultGit(C.repo);end
pol=C.policy;req={'decision','decisionUrl','approvedHead','token','solveLimit','solves','campaignId','contractEvidenceFile','contractEvidenceSHA256'};
c=struct();c.fields=isstruct(G)&&all(isfield(G,req));
gf=@(f)fieldOr(G,f);
c.decision=c.fields&&isequal(gf('decision'),'GO_LP2A2_EQ');
c.token=c.fields&&ischar(gf('token'))&&strcmp(gf('token'),C.token)&&strcmp(char(callerToken),C.token);
c.solveLimit=c.fields&&isnumeric(gf('solveLimit'))&&isscalar(gf('solveLimit'))&&gf('solveLimit')==4;
want={pol.solves.id};s=gf('solves');if ischar(s),s={s};end
c.solves=c.fields&&iscellstr(s)&&isequal(s(:).',want)&&isequal(want,{'EQ-H','EQ-stiff13','EQ-soft2','EQ-soft1'});
c.campaignId=c.fields&&isequal(gf('campaignId'),pol.campaignId);
u=gf('decisionUrl');
c.decisionUrl=c.fields&&ischar(u)&&~isempty(regexp(u,'^https://github\.com/mfs9697/NewMetacomp/pull/[1-9][0-9]*#(issuecomment|pullrequestreview)-[1-9][0-9]*$','once'));
h=gf('approvedHead');
c.approvedHead=c.fields&&ischar(h)&&~isempty(regexp(h,'^[0-9a-f]{40}$','once'));
ef=gf('contractEvidenceFile');es=gf('contractEvidenceSHA256');
c.contractEvidence=false;
if c.fields&&ischar(ef)&&ischar(es)&&~isempty(regexp(es,'^[0-9a-f]{64}$','once'))&&isempty(strfind(ef,'..'))
 p=fullfile(C.repo,ef);c.contractEvidence=isfile(p)&&strcmpi(g2_sha256_file(p),es);
end
c.ancestor=false;c.activationBinding=false;
if c.approvedHead   % never pass an unvalidated string to git
 c.ancestor=logical(git.isAncestor(h));
 ch=git.changedFiles(h);if ischar(ch),ch={ch};end
 c.activationBinding=strcmp(git.headParent(),h)&&isequal(sort(ch(:)).',{pol.goFile});
end
v=cell2mat(struct2cell(c));f=fieldnames(c);
V=struct('pass',all(v),'checks',c,'failed',{f(~v)});
end

function v=fieldOr(G,f)
if isstruct(G)&&isfield(G,f),v=G.(f);else,v=[];end
end

function g=defaultGit(repo)
g=struct('isAncestor',@(h)val(g2_lp2a2_git('isAncestor',repo,h),false), ...
 'headParent',@()val(g2_lp2a2_git('parent',repo),''), ...
 'changedFiles',@(h)val(g2_lp2a2_git('changedFiles',repo,h),{'<git-query-failed>'}));
end
function v=val(R,bad)
if R.ok,v=R.value;else,v=bad;end
end
