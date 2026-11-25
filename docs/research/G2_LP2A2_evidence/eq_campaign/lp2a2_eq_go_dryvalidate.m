% LP2-A2 equivalence campaign G2-LP2A2-EQ-001: DRY validation of the committed GO file (pure validator, no solve, no wrapper call, no driver call).
% Diagnostic of the Windows command line: git 'rev-parse HEAD^' through MATLAB system() (cmd.exe treats ^ as the escape character).
ex='<repo>';
out='<scratch>\campaign';
addpath(fullfile(ex,'matlab','g2'),'-begin');addpath(fullfile(ex,'matlab','g2','lp2a2'),'-begin');
TOK=['G2LP2A2EQ|policy=bc1f86e7750aaea653cd7544c8fff0ad757843a23bd00608145dad70dcd8a330|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947', ...
 '|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca|lp2a2source=00c99e93915ad2c0dbd4eaeb307d94d65b4c71300f94a0f073aadacb9c5a61c2', ...
 '|archivedS8=da951c99c0d8c1d5dd731986d8f3b30e3db3f71854166a634d35b739757def8d|solves=EQ-H,EQ-stiff13,EQ-soft2,EQ-soft1|limit=4'];
try
 R=struct();[~,h]=system(sprintf('git -C "%s" rev-parse HEAD',ex));R.head=strtrim(h);
 [~,a]=system(sprintf('git -C "%s" rev-parse HEAD^',ex));R.revParseHeadCaretUnquoted=strtrim(a);        % exactly the string used by g2_lp2a2_eq_go_validate
 [~,b]=system(sprintf('git -C "%s" rev-parse "HEAD^"',ex));R.revParseHeadCaretQuoted=strtrim(b);        % diagnostic only
 [~,c]=system(sprintf('git -C "%s" rev-parse HEAD~1',ex));R.revParseHeadTilde1=strtrim(c);              % diagnostic only
 [~,d]=system(sprintf('git -C "%s" diff --name-only 4d3701e1ccc91b7512db9052c927f32af52e2479 HEAD',ex));R.changedFiles=strtrim(d);
 fprintf('DRY head=%s\nDRY HEAD^ (unquoted, as in the validator)=%s\nDRY "HEAD^" quoted=%s\nDRY HEAD~1=%s\nDRY changed=%s\n',R.head,R.revParseHeadCaretUnquoted,R.revParseHeadCaretQuoted,R.revParseHeadTilde1,R.changedFiles);
 C=g2_lp2a2_eq_context();G=jsondecode(fileread(fullfile(ex,C.policy.goFile)));
 V=g2_lp2a2_eq_go_validate(G,C,TOK);R.validatorDefaultGit=V;
 fprintf('DRY validator(default git): pass=%d failed=[%s]\n',V.pass,strjoin(V.failed,','));
 % diagnostic ONLY (never used for activation): the same pure validator with the parent resolved through a quoted caret
 pq=strtrim(b);cf=cellstr(strsplit(strtrim(d),newline));
 gq=struct('isAncestor',@(x)system(sprintf('git -C "%s" merge-base --is-ancestor %s HEAD',ex,x))==0, ...
  'headParent',@()pq,'changedFiles',@(x)cf);
 V2=g2_lp2a2_eq_go_validate(G,C,TOK,gq);R.validatorDiagnosticQuotedCaret=V2;
 fprintf('DRY diagnostic (quoted caret, NOT used): pass=%d failed=[%s]\n',V2.pass,strjoin(V2.failed,','));
 Rv=g2_lp2a2_eq_verify();R.verify=Rv;R.outputRootExists=isfolder(fullfile(ex,C.policy.outputRoot));
 fprintf('DRY verify outcome=%s outputRootExists=%d physicalSolves=0\n',Rv.outcome,R.outputRootExists);
 [~,g]=system(sprintf('git -C "%s" status --porcelain --untracked-files=all',ex));R.gitClean=isempty(strtrim(g));R.physicalSolves=0;R.wrapperCalled=false;R.driverRunCalled=false;
 fid=fopen(fullfile(out,'LP2A2_EQ_GO_DRYVALIDATE.json'),'w');fwrite(fid,jsonencode(R,'PrettyPrint',true),'char');fclose(fid);
 fprintf('DRY_DONE gitClean=%d\n',R.gitClean);
catch ME
 fprintf(2,'DRY_ERROR %s: %s\n',ME.identifier,ME.message);disp(getReport(ME));
end
