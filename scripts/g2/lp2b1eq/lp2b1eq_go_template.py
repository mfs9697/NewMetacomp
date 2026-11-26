"""Write docs/research/G2_LP2B1EQ_GO_DECISION_TEMPLATE.md from the committed LP2-B1-EQ policy, the zero-FEM test
evidence and the independent hashcheck (values copied mechanically). The template is NOT a GO and creates no GO file;
its JSON block contains investigator-only placeholders that the validator rejects.
usage: python lp2b1eq_go_template.py <repo> <testsJson> <hashcheckJson> <protectedJson> <sourceCommit>"""
import hashlib, json, os, sys
R, tj, hj, pj, commit = sys.argv[1:6]
pf = os.path.join(R, 'matlab/g2/lp2b1eq/G2_LP2B1EQ_POLICY_v1.json')
P = json.load(open(pf, encoding='utf-8')); T = json.load(open(tj, encoding='utf-8')); H = json.load(open(hj, encoding='utf-8')); Q = json.load(open(pj, encoding='utf-8'))
sh = lambda p: hashlib.sha256(open(p, 'rb').read()).hexdigest()
ps, ts, hs, qs = sh(pf), sh(tj), sh(hj), sh(pj)
assert ps == T['policySHA256'] == H['policySHA256'] and T['passed'] == T['total'] and T['physicalSolves'] == 0 and H['pass'] and Q['pass']
rel = lambda p: os.path.relpath(p, R).replace(os.sep, '/')
tok = T['token']; au = P['authorization']; sp = P['sourcePins']; res = P['resources']; S = P['solves']
L = ['# G2-LP2-B1-EQ — two fixed-geometry 0.40 mm equivalence solves: authorization decision record (TEMPLATE, NOT A GO)\n',
     'Prepared under https://github.com/mfs9697/NewMetacomp/issues/78 (draft PR stacked on #77). **Only the principal investigator may complete '
     'this record, in a separate PR comment after an independent readiness review, and decide `GO_LP2B1_EQ` or `HOLD_LP2B1_EQ`.** No GO file '
     'exists. Without it, `g2_lp2b1eq_run(...,\'Run\',true)` refuses with `G2LP2B1EQ:HOLD_UNAUTHORIZED` before any folder, mesh or solve; a '
     'physical call without the normal preflight refuses with `G2LP2B1EQ:HOLD_PREFLIGHT_REQUIRED`; a physical call that does not come through '
     '`g2_lp2b1eq_external_run` refuses with `G2LP2B1EQ:HOLD_NO_RECEIPT`. Any change to a pinned source, policy, reference or qualification '
     'record changes the token, and the context fails closed with `G2LP2B1EQ:HOLD_SOURCE`. Earlier authorizations (WP5 A1/A2, LP2-A3) are '
     'consumed and cannot authorize this campaign. A GO_LP2B1_EQ would NOT authorize the target soft1 S10 solve, which needs a different, later decision.\n',
     '## 1. Pins\n', '| Field | Value |\n|---|---|',
     f'| source commit of the evidence | `{commit}` |', f'| policy `matlab/g2/lp2b1eq/G2_LP2B1EQ_POLICY_v1.json` | `{ps}` |']
for k in ('g2SourceSHA256', 'lp2SourceSHA256', 'lp2a2SourceSHA256', 'lp2a3SourceSHA256', 'lp2b1SourceSHA256', 'lp2b1eqSourceSHA256', 'closureSourceSHA256'):
    L.append(f'| `{k}` | `{sp[k]}` |')
for s in S:
    q = s['qualification']
    L.append(f"| {s['id']}: archived STATE / SOLUTION / MESH / PHASE | `{s['archived']['STATE']['record']['sha256'][:16]}…` / `{s['archived']['SOLUTION']['record']['sha256'][:16]}…` / "
             f"`{s['archived']['MESH']['sha256'][:16]}…` / `{s['archived']['PHASE']['record']['sha256'][:16]}…` (full values in the policy) |")
    L.append(f"| {s['id']}: next state {s['nextPredictor']['state']}, archived next tip (mm) | `{s['nextPredictor']['tip_mm'][0]!r}, {s['nextPredictor']['tip_mm'][1]!r}` |")
    L.append(f"| {s['id']}: qualified 0.40 mm canonical digest / arrays file | `{q['canonicalSHA256']}` / `{q['arrays']['sha256']}` |")
L += [f"| LP2-B1 qualification archive | `{P['qualificationEvidence']['b1ArchiveSHA256']}` ({P['qualificationEvidence']['b1ArchiveMembers']} members) |",
      f"| zero-FEM test evidence `{rel(tj)}` | `{ts}` ({T['passed']}/{T['total']}, `physicalSolves` 0) |",
      f"| independent hashcheck `{rel(hj)}` | `{hs}` (PASS) |", f"| protected records `{rel(pj)}` | `{qs}` (PASS; 832 + 43 + {Q['policyPinnedFiles']} pinned) |",
      f'| token | `{tok.replace("|", chr(92) + "|")}` |', f"| GO file path (fixed) | `{au['goPath']}` |",
      f"| campaign / scope / run | `{au['campaignId']}` / `{au['campaignScope']}` / `{au['runName']}` |",
      f"| run root / receipt root (fresh; must not exist) | `{au['runRoot']}` / `{au['receiptRoot']}` |\n",
      '## 2. Decision record (investigator completes; the JSON below is inside Markdown and its placeholders are rejected)\n']
G = {'decision': '<INVESTIGATOR ONLY: GO_LP2B1_EQ, or do not create the file (HOLD_LP2B1_EQ)>',
     'decisionUrl': '<INVESTIGATOR ONLY: https://github.com/mfs9697/NewMetacomp/pull/<n>#issuecomment-<n> (or issues/<n>, or #pullrequestreview-<n>)>',
     'approvedHead': '<INVESTIGATOR ONLY: full 40-character reviewed head; the activation commit must add ONLY this GO file directly on it>',
     'token': tok, 'campaignId': au['campaignId'], 'campaignScope': au['campaignScope'], 'runName': au['runName'],
     'solves': [s['id'] for s in S], 'solveLimit': P['solveLimit'], 'attemptsPerSolve': P['attemptsPerSolve'], 'seedSpacing_mm': P['meshFamily']['seedSpacing_mm'],
     'contractEvidenceFile': rel(tj), 'contractEvidenceSHA256': ts}
L.append('```json\n' + json.dumps(G, indent=1, ensure_ascii=False) + '\n```\n')
L += ['## 3. What a GO_LP2B1_EQ would authorize, and what it would not\n', '| Authorized | Not authorized |\n|---|---|',
      '| Exactly two fixed-geometry solves in this order: EQB-soft1-S9 (accepted soft1 S9 geometry, mask 100, ratio 0.5), then EQB-H-S10 (accepted H S10 geometry, mask 000, ratio 1); each on the 0.40 mm mesh whose canonical digest and metadata equal the LP2-B1 qualification record; unchanged BVP, solver, 16 gates; comparison with the ORIGINAL accepted LP2-A3 record by C1–C11 with the original thresholds | The target soft1 S10 solve; any other geometry, state or spacing; propagation or any new STATE; a same-s or architecture contrast; retries, resumption, fallback, adaptive steps; LP2-B2; S12; tolerance or model changes; merges |',
      '| Global stop at the first failure of any criterion, gate, integrity, resource or authorization check (the second solve is then not called) | Any claim beyond numerical equivalence on these two geometries (no discretization-error bound, convergence statement or multi-architecture qualification) |\n',
      '## 4. Criteria (fixed before any solve; every bound inclusive)\n', '| Criterion | Rule |\n|---|---|']
L += [f'| {k} | {v} |' for k, v in P['criteria'].items()]
L += ['', f"Validation before any criterion (verification-infrastructure HOLD, never an equivalence statement): {P['validation']}\n",
      '## 5. Execution protocol after a GO\n',
      '1. At the approved head: `scripts/g2/lp2b1eq/lp2b1eq_hashcheck.py` (policy, seven source digests, every file pin, token, canonical digests from raw exports) and `scripts/g2/lp2b1eq/lp2b1eq_protected.py` (832 + 43 + pinned files, both archive copies of LP2-A3 and LP2-B1); confirm GO file, run root and receipt root absent.\n'
      '2. Activation commit: add ONLY `' + au['goPath'] + '` directly on the approved head; verify HEAD~1 and the sole changed file independently (also through cmd.exe).\n'
      f"3. Immediately before MATLAB starts: `scripts/g2/lp2a2/lp2a2_eq_prestart_check.ps1` at its default (>= {res['freeRAMBeforeMATLABStart_GiB_min']:g} GiB available, no MATLAB process, removable backup drive). One MATLAB R2023a/PDE process; normal preflight ({res['preflightGuard_GiB']:g} GiB guard unchanged); `g2_lp2a2_eq_memgate` >= {res['freeRAMInsideMATLAB_GiB_min']:g} GiB before the solve folder and again before the solve; no automatic retry.\n"
      '4. Run once `g2_lp2b1eq_external_run(approvedHead, tok, outDir)` with a fresh outDir outside the worktree: parent/changed-file check, fresh roots, context, token, memory gate, GO validation, receipt, then `g2_lp2b1eq_campaign` (EQB-soft1-S9, then EQB-H-S10 only if the first is EQUIVALENT_CASE), then `g2_lp2b1eq_verify` (read-only).\n'
      '5. Whatever the outcome: independent read-only verification of every record and metric (not only pass labels); protected records before/after; archive on two physical devices; revoke the GO in a separate commit and show the refusal afterwards; independent external audit of the records and numbers.\n'
      '6. Known limitation: the one-attempt guard is the local solve folder and receipt; deleting them or using an independent clone would defeat it and is excluded by protocol.\n']
out = os.path.join(R, 'docs/research/G2_LP2B1EQ_GO_DECISION_TEMPLATE.md')
open(out, 'w', encoding='utf-8', newline='\n').write('\n'.join(L))
print('written', out)
