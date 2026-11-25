function R=g2_lp2a2_git(op,repo,varargin)
%G2_LP2A2_GIT  Shell-safe git queries for the LP2-A2 activation checks (MATLAB system()).
%  R = g2_lp2a2_git('head', repo)               HEAD commit
%  R = g2_lp2a2_git('parent', repo)             first parent of HEAD, queried as HEAD~1
%  R = g2_lp2a2_git('isAncestor', repo, sha)    sha is an ancestor of HEAD (merge-base --is-ancestor)
%  R = g2_lp2a2_git('changedFiles', repo, sha)  'git diff --name-only <sha> HEAD'
%  R = g2_lp2a2_git('activationParent', repo, approvedHead)
%        head and parent both resolved, and parent == approvedHead (the external pre-wrapper check)
% Every result has: op, command (exact string given to system), status (exit code), output
% (trimmed), value, ok. A commit value is accepted only when the exit status is 0 AND the whole
% output is one 40-character lower-case hex SHA; otherwise ok = false and value = ''.
% isAncestor: status 0 -> true, status 1 -> false (both ok); any other status -> ok = false.
% changedFiles: status 0 -> cellstr of paths; otherwise ok = false and value = {}.
%
% Windows: system() runs cmd.exe, which consumes an unquoted caret (^) as its escape character, so
% 'git rev-parse HEAD^' reaches git as 'rev-parse HEAD' and returns HEAD itself (the cause of
% HOLD_LP2A2_EQ_ACTIVATION_BINDING_WINDOWS_CARET). The parent is therefore queried as HEAD~1, and
% every argument string is refused if it contains a cmd.exe/sh metacharacter (^ & | < > % ! " ` $ ;
% newline); SHA arguments must be 40-hex; the repository path is quoted and may not contain " % !.
switch op
 case 'head',R=q(repo,'rev-parse --verify HEAD','commit');
 case 'parent',R=q(repo,'rev-parse --verify HEAD~1','commit');
 case 'isAncestor'
  h=hex40(varargin{1});R=q(repo,['merge-base --is-ancestor ' h ' HEAD'],'raw');
  R.ok=any(R.status==[0 1]);R.value=R.status==0;
 case 'changedFiles'
  h=hex40(varargin{1});R=q(repo,['diff --name-only ' h ' HEAD'],'raw');
  R.ok=R.status==0;
  if R.ok,c=strtrim(strsplit(R.output,{char(10),char(13)}));R.value=c(~cellfun(@isempty,c));else,R.value={};end
 case 'activationParent'
  h=hex40(varargin{1});H=g2_lp2a2_git('head',repo);P=g2_lp2a2_git('parent',repo);
  R=struct('op',op,'command',{{H.command,P.command}},'status',[H.status P.status],'output',{{H.output,P.output}}, ...
   'value',H.ok&&P.ok&&strcmp(P.value,h),'ok',H.ok&&P.ok,'head',H,'parent',P,'approvedHead',h);
 otherwise,error('G2LP2A2:GIT_UNKNOWN_OP','Unknown op %s.',op);
end
end

function R=q(repo,args,kind)
if ~ischar(repo)||isempty(repo)||any(ismember(repo,['"%!' char(10) char(13)]))
 error('G2LP2A2:GIT_UNSAFE_REPO','Repository path is empty or contains a shell metacharacter.');
end
if any(ismember(args,['^&|<>%!"`$;' char(10) char(13)]))
 error('G2LP2A2:GIT_UNSAFE_ARG','git argument string contains a shell metacharacter: %s',args);
end
cmd=sprintf('git -C "%s" %s',repo,args);
[st,o]=system(cmd);o=strtrim(o);
R=struct('op',args,'command',cmd,'status',st,'output',o,'value','','ok',false);
if strcmp(kind,'commit')&&st==0&&~isempty(regexp(o,'^[0-9a-f]{40}$','once')),R.ok=true;R.value=o;end
end

function h=hex40(h)
if ~(ischar(h)&&~isempty(regexp(h,'^[0-9a-f]{40}$','once')))
 error('G2LP2A2:GIT_UNSAFE_ARG','A SHA argument must be a full 40-character lower-case hex string.');
end
end
