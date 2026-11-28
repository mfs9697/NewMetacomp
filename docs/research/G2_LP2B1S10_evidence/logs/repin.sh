#!/bin/bash
# re-pin: regenerate the LP2-B1-S10 policy for the current lp2b1s10 sources, commit with message $1, sync exec clone
set -e
W=<worktree>; X=<repo>
S=<scratch>/lp2b1eq
cd $W
if grep -lU $'\r' matlab/g2/lp2b1s10/* scripts/g2/lp2b1s10/*; then echo "CR found"; exit 1; fi
D=$(python $S/digest.py matlab/g2/lp2b1s10 | awk '{print $2}')
rm -f matlab/g2/lp2b1s10/G2_LP2B1S10_POLICY_v1.json
python scripts/g2/lp2b1s10/lp2b1s10_make_policy.py $X matlab/g2/lp2b1s10/G2_LP2B1S10_POLICY_v1.json $D
git add matlab/g2/lp2b1s10 scripts/g2/lp2b1s10
git -c core.autocrlf=false commit -q -m "$1

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git log --oneline -1
cd $X && git fetch -q $W research/g2-lp2b1-s10-readiness-20261127 && git checkout -q FETCH_HEAD && git log --oneline -1 && python $S/digest.py matlab/g2/lp2b1s10 && git status --porcelain --untracked-files=all | head -3
