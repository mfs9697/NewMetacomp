@echo off
rem Independent Windows (cmd.exe) check of the activation commit: HEAD, HEAD~1, sole changed path, committed bytes.
cd /d <repo>
echo HEAD:
git rev-parse HEAD
echo HEAD~1:
git rev-parse HEAD~1
echo CHANGED:
git diff --name-only 0fcee176a5e294b7c8d7f33711ad7d3897be6538 HEAD
echo DIFFSTAT:
git diff --stat 0fcee176a5e294b7c8d7f33711ad7d3897be6538 HEAD
echo COMMITTED_BLOB:
git rev-parse HEAD:matlab/g2/lp2b1s10/G2_LP2B1S10_GO.json
echo WORKTREE_BLOB:
git hash-object matlab/g2/lp2b1s10/G2_LP2B1S10_GO.json
echo CANDIDATE_BLOB:
git hash-object <scratch>\lp2b1s10run\pre\GO_candidate.json
echo COMMITTED_SHA256:
git show HEAD:matlab/g2/lp2b1s10/G2_LP2B1S10_GO.json | certutil -hashfile - SHA256 2>nul
certutil -hashfile <scratch>\lp2b1s10run\pre\GO_candidate.json SHA256
echo STATUS:
git status --porcelain --untracked-files=all
echo END
