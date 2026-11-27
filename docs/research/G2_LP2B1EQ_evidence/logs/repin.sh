#!/bin/bash
# re-pin: regenerate the policy for the current lp2b1eq sources, commit with message $1, sync exec clone
set -e
W=<home>/Documents/GitHub/NewMetacomp_wt_b1eq; X=<repo>
S=<scratch>/lp2b1eq
cd $W
if grep -lU $'\r' matlab/g2/lp2b1eq/* scripts/g2/lp2b1eq/*; then echo "CR found"; exit 1; fi
D=$(python $S/digest.py matlab/g2/lp2b1eq | awk '{print $2}')
rm -f matlab/g2/lp2b1eq/G2_LP2B1EQ_POLICY_v1.json
python scripts/g2/lp2b1eq/lp2b1eq_make_policy.py $X matlab/g2/lp2b1eq/G2_LP2B1EQ_POLICY_v1.json $D 76614f269810c6970544bca0c1c0f84ebf9131935554ebd75e57e24f819f65f7 9c7a1260e3bde5b59e1d93c47bc99cc4d7b89f9b0cc6e874572fb378f1717bee
git add matlab/g2/lp2b1eq scripts/g2/lp2b1eq
git -c core.autocrlf=false commit -q -m "$1

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git log --oneline -1
cd $X && git fetch -q $W research/g2-lp2b1-eq-readiness-20261126 && git checkout -q FETCH_HEAD && git log --oneline -1 && python $S/digest.py matlab/g2/lp2b1eq && git status --porcelain --untracked-files=all | head -3
