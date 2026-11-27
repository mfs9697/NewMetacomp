"""Write docs/research/G2_LP2B1S10_GO_DECISION_TEMPLATE.md from the committed LP2-B1-S10 policy, the committed sanitized zero-FEM
test evidence, the independent hashcheck and the protected check (values copied mechanically). The template is NOT a GO and creates
no GO file; its JSON block contains investigator-only placeholders that the validator rejects.
usage: python lp2b1s10_go_template.py <repo> <testsJson(committed)> <hashcheckJson> <protectedJson> <sourceCommit>"""
import hashlib, json, os, sys
R, tj, hj, pj, commit = sys.argv[1:6]
pf = os.path.join(R, 'matlab/g2/lp2b1s10/G2_LP2B1S10_POLICY_v1.json')
P = json.load(open(pf, encoding='utf-8')); T = json.load(open(tj, encoding='utf-8')); H = json.load(open(hj, encoding='utf-8')); Q = json.load(open(pj, encoding='utf-8'))
sh = lambda p: hashlib.sha256(open(p, 'rb').read()).hexdigest()
ps, ts, hs, qs = sh(pf), sh(tj), sh(hj), sh(pj)
assert ps == T['policySHA256'] == H['policySHA256'] and T['passed'] == T['total'] and T['physicalSolves'] == 0 and H['pass'] and Q['pass']
rel = lambda p: os.path.relpath(p, R).replace(os.sep, '/')
tok = T['token']; au = P['authorization']; sp = P['sourcePins']; tg = P['target']; pa = P['parent']; fa = P['failedA3S10']; q = P['qualification']; ex = P['meshFamily']['expected']
esc = lambda s: s.replace('|', chr(92) + '|')
L = ['# G2-LP2-B1-S10 — one soft1 S10 admission and solve at 0.40 mm: authorization decision record (TEMPLATE, NOT A GO)\n',
     'Prepared under https://github.com/mfs9697/NewMetacomp/issues/81 (draft PR stacked on #79). **Only the principal investigator may complete this '
     'record, in a separate PR comment after an independent exact-head readiness review, and decide `GO_LP2B1_S10` or `HOLD_LP2B1_S10`.** No GO file exists. '
     'Without it, `g2_lp2b1s10_run(\'Run\',true,...)` refuses with `G2LP2B1S10:HOLD_UNAUTHORIZED` before any folder, mesh or solve; a physical call without '
     'the normal preflight refuses with `G2LP2B1S10:HOLD_PREFLIGHT_REQUIRED`; a physical call that does not come through `g2_lp2b1s10_external_run` refuses '
     'with `G2LP2B1S10:HOLD_NO_RECEIPT`; any existing soft1 case folder or ledger admission refuses with `G2LP2B1S10:HOLD_ONE_ATTEMPT`. Any change to a '
     'pinned source, policy, parent, failed-S10, qualification or LP2-B1-EQ evidence file changes the token or fails the context closed '
     '(`G2LP2B1S10:HOLD_SOURCE`). All earlier authorizations (LP2-A3, LP2-B1-EQ) are consumed and revoked and cannot authorize this campaign. '
     'A `GO_LP2B1_S10` would NOT authorize any S11 mesh, admission or solve, any other spacing, or LP2-B2.\n',
     '## 1. Pins\n', '| Field | Value |\n|---|---|',
     f'| source commits of the evidence | {commit} |', f'| policy `matlab/g2/lp2b1s10/G2_LP2B1S10_POLICY_v1.json` | `{ps}` |']
for k in ('g2SourceSHA256', 'lp2SourceSHA256', 'lp2a2SourceSHA256', 'lp2a3SourceSHA256', 'lp2b1SourceSHA256', 'lp2b1eqSourceSHA256', 'closureSourceSHA256', 'lp2b1s10SourceSHA256'):
    L.append(f'| `{k}` | `{sp[k]}` |')
L += [f"| sole parent: ORIGINAL LP2-A3 soft1 S9 STATE / MESH / PHASE / SOLUTION | `{pa['STATE']['record']['sha256']}` / `{pa['MESH']['sha256']}` / `{pa['PHASE']['record']['sha256']}` / `{pa['SOLUTION']['record']['sha256']}` |",
      f"| preserved LP2-A3 soft1 S10 failure: TERMINAL / FAILED_MESH / HOLD | `{fa['TERMINAL']['record']['sha256']}` / `{fa['FAILED_MESH']['sha256']}` / `{fa['HOLD']['record']['sha256']}` |",
      f"| target: soft1 S10, mask 100, ratio 0.5, s = {tg['arc_mm']} mm, tip (mm) | `{tg['expectedTip_mm'][0]!r}, {tg['expectedTip_mm'][1]!r}` (signed-MTS forecast of the original S9, bitwise) |",
      f"| ring-1 guide gap (MATLAB guard / issue value) | `{tg['ring1GuideGap_mm']['matlabGuard']!r}` mm / `{tg['ring1GuideGap_mm']['issueValue']!r}` mm (|difference| <= 1e-12 mm) |",
      f"| qualified 0.40 mm canonical digest / arrays file | `{q['canonicalSHA256']}` / `{q['arrays']['sha256']}` |",
      f"| expected T3 / minimum angle / maximum neighbour ratio | {ex['T3']} / `{ex['minAngle_deg']!r}` deg / `{ex['maxNeighborRatio']!r}` (limits 20 deg / 1.8 / 40000 unchanged) |",
      f"| LP2-B1 archive / LP2-B1-EQ campaign archive | `{q['b1ArchiveSHA256']}` / `{P['b1eqEvidence']['archiveSHA256']}` |",
      f"| zero-FEM test evidence (committed, sanitized) `{rel(tj)}` | `{ts}` ({T['passed']}/{T['total']}, `physicalSolves` 0) |",
      f"| independent hashcheck `{rel(hj)}` | `{hs}` (PASS, {sum(H['checks'].values())}/{len(H['checks'])}) |",
      f"| protected records `{rel(pj)}` | `{qs}` (PASS; unique union {Q['unionFiles']} = 891 + 23 + {Q['unionFiles'] - 914} new S10 pins; manifest `{Q['unionManifestSHA256'][:16]}…`) |",
      f'| token | `{esc(tok)}` |', f"| GO file path (fixed) | `{au['goPath']}` |",
      f"| campaign / scope / run | `{au['campaignId']}` / `{au['campaignScope']}` / `{au['runName']}` |",
      f"| run root / receipt (ledger) root / summary (fresh; must not exist) | `{au['runRoot']}` / `{au['receiptRoot']}` / `{au['summaryPath']}` |\n",
      '## 2. Decision record (investigator completes; the JSON below is inside Markdown and its placeholders are rejected)\n']
G = {'decision': '<INVESTIGATOR ONLY: GO_LP2B1_S10, or do not create the file (HOLD_LP2B1_S10)>',
     'decisionUrl': '<INVESTIGATOR ONLY: https://github.com/mfs9697/NewMetacomp/pull/<n>#issuecomment-<n> (or issues/<n>, or #pullrequestreview-<n>)>',
     'approvedHead': '<INVESTIGATOR ONLY: full 40-character reviewed head; the activation commit must add ONLY this GO file directly on it>',
     'token': tok, 'campaignId': au['campaignId'], 'campaignScope': au['campaignScope'], 'runName': au['runName'], 'target': 'soft1-S10',
     'admissions': 1, 'physicalSolves': 1, 'attemptsPerSolve': 1, 'seedSpacing_mm': 0.4, 'contractEvidenceFile': rel(tj), 'contractEvidenceSHA256': ts}
L += ['```json', json.dumps(G, indent=1), '```\n',
      '## 3. What a GO_LP2B1_S10 would authorize, and what it would not\n', '| Authorized | Not authorized |\n|---|---|',
      '| Exactly ONE admission and ONE physical solve: soft1 S10 continuing the ORIGINAL accepted LP2-A3 soft1 S9 STATE, on the 0.40 mm mesh whose canonical digest and metadata equal the LP2-B1 qualification (protected-block baseline: the preserved FAILED_MESH of the same geometry); original BVP, materials, unchanged solver and 16 gates; a new STATE only if every LP2-A3 acceptance gate passes; S11 forecast for information only | Any S11 mesh, admission or solve; any retry, resumption or fallback; another spacing; the LP2-B1-EQ re-solve as parent; any equivalence claim for the target; alteration of the closed LP2-A3 ledger or any historical record; LP2-B2; merges |',
      '| A local HOLD (mesh, clearance, gates, MTS) preserves the partial records and ends the campaign | Any claim of arrest, interface encounter, general numerical accuracy or convergence |\n',
      '## 4. Acceptance (fixed before any solve)\n']
L += [f'{i + 1}. {a}' for i, a in enumerate(P['acceptance'])]
L += ['\nNo C1–C11 equivalence criterion applies to the target: no valid 0.45 mm soft1 S10 solution exists. The accepted LP2-B1-EQ demonstration is qualification evidence for the 0.40 mm family only, not a proof that the target is equivalent or converged.\n',
      '## 5. Execution protocol after a GO\n',
      '1. At the approved head, in the single clean execution clone: `scripts/g2/lp2b1s10/lp2b1s10_hashcheck.py` and `scripts/g2/lp2b1s10/lp2b1s10_protected.py` (backup locations as arguments); confirm the GO file, run root, receipt root and summary absent; verify the removable backup drive is attached, stable (connection log) and holds every archive copy.',
      '2. Real correct-token refusal before activation (`G2LP2B1S10:HOLD_UNAUTHORIZED`, no writes) under the normal preflight.',
      '3. Activation commit: add ONLY `matlab/g2/lp2b1s10/G2_LP2B1S10_GO.json` directly on the approved head; verify HEAD~1, the committed bytes and the sole changed file independently (also through cmd.exe).',
      '4. Immediately before each MATLAB start: `scripts/g2/lp2a2/lp2a2_eq_prestart_check.ps1` at its default (>= 8.2 GiB available, no MATLAB process, removable backup drive). One MATLAB R2023a / PDE 3.10 process; normal preflight (5 GiB guard unchanged); `g2_lp2a2_eq_memgate` >= 7 GiB before the admission and again before the solve; no automatic retry.',
      '5. Run once `g2_lp2b1s10_external_run(approvedHead, tok, outDir)` with a fresh outDir outside the worktree: parent/changed-file check, fresh roots and summary, context, token, PDE 3.10, memory gate, GO validation, ledger RECEIPT, then exactly one `g2_lp2b1s10_run(\'Run\',true)`, then `g2_lp2b1s10_verify` (read-only). Never re-run the wrapper after any failure.',
      '6. Whatever the outcome: independent read-only audit beyond the verifier; protected records before/after; archive on two physical devices; revoke the GO in a separate commit restoring the reviewed tree and show the correct-token refusal afterwards.',
      '7. Known limitation: the one-attempt guard is the local case folder and ledger; deleting them or using an independent clone would defeat it and is excluded by protocol.\n',
      '## 6. Scientific analysis after an accepted S10 (separately reviewed)\n',
      'Evolution of soft1 amplification from S9 (no presupposed sign or trend); absolute G and F_G against the ORIGINAL accepted H S10 (not the LP2-B1-EQ re-solve); signed K_I, K_II and mixity; local MTS angle and global heading; lateral offset relative to H; distances to all three rings; comparison of the four architectures at the common accepted s = 65.4 mm; S11 forecast geometry and guide clearance for information only.']
out = os.path.join(R, 'docs', 'research', 'G2_LP2B1S10_GO_DECISION_TEMPLATE.md')
open(out, 'w', encoding='utf-8', newline='\n').write('\n'.join(L) + '\n')
print('template written', sh(out))
