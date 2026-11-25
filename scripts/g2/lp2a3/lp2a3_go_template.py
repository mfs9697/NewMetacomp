"""Write docs/research/G2_LP2A3_GO_DECISION_TEMPLATE.md from the committed LP2-A3 policy and the zero-FEM
contract evidence (values copied mechanically; the template is NOT a GO and creates no GO file).
usage: python -I scripts/g2/lp2a3/lp2a3_go_template.py <repo> <LP2A3_TESTS.json> <sourceCommit>"""
import json, sys, os, hashlib
R, tj, commit = sys.argv[1], sys.argv[2], sys.argv[3]
pf = os.path.join(R, 'matlab/g2/lp2a3/G2_LP2A3_POLICY_v1.json')
P = json.load(open(pf, encoding='utf-8')); T = json.load(open(tj, encoding='utf-8'))
ps = hashlib.sha256(open(pf, 'rb').read()).hexdigest(); ts = hashlib.sha256(open(tj, 'rb').read()).hexdigest()
assert ps == T['policySHA256'] and T['passed'] == T['total'] and T['physicalSolves'] == 0
tok = T['token']; au = P['authorization']; c = P['caps']; sp = P['sourcePins']; res = P['resources']
rel = os.path.relpath(tj, R).replace(os.sep, '/')
L = ['# G2-LP2-A3 — restricted S9–S11 continuation: authorization decision record (TEMPLATE, NOT A GO)\n',
     'Prepared under https://github.com/mfs9697/NewMetacomp/issues/74 (draft PR stacked on #71). **Only the principal investigator may '
     'complete this record, in a separate PR comment, and decide `GO_LP2A3_PHYSICAL` or `HOLD_LP2A3`.** No GO file exists. Without it, '
     '`g2_lp2a3_run(...,\'Run\',true)` refuses with `G2LP2A3:HOLD_UNAUTHORIZED` before any folder, mesh or solve; a physical call without '
     'the normal preflight refuses with `G2LP2A3:HOLD_PREFLIGHT_REQUIRED`. The GO record is checked by `g2_lp2a3_go_validate`, including '
     'the git activation binding. Any change to a pinned source, policy, parent or qualification record changes the token, and the context '
     'fails closed with `G2LP2A3:HOLD_SOURCE`. The WP5 authorizations (A1 and A2) are consumed and cannot authorize LP2-A3.\n',
     '## 1. Pins\n', '| Field | Value |\n|---|---|',
     f'| source commit of the evidence | `{commit}` |', f'| policy `matlab/g2/lp2a3/G2_LP2A3_POLICY_v1.json` | `{ps}` |']
for k in ('g2SourceSHA256', 'lp2SourceSHA256', 'lp2a2SourceSHA256', 'lp2a3SourceSHA256'):
    L.append(f'| `{k}` | `{sp[k]}` |')
L += [f'| S8 parents (20 files, LP2-A1 ledger manifest) | see `parents.S8` in the policy; manifest `{P["parents"]["manifestSHA256"]}` |',
      f'| WP5 qualification (24 records + 8 evidence files + archive `{P["qualificationEvidence"]["archiveSHA256"][:16]}…`) | see `qualificationEvidence` in the policy |',
      f'| zero-FEM contract evidence `{rel}` | `{ts}` ({T["passed"]}/{T["total"]}, `physicalSolves` 0) |',
      f'| token | `{tok.replace("|", chr(92) + "|")}` |',
      f'| GO file path (fixed) | `{au["goPath"]}` |',
      f'| campaign / scope / run | `{au["campaignId"]}` / `{au["campaignScope"]}` / `{au["runName"]}` |',
      f'| run root / ledger root (fresh; must not exist) | `{au["runRoot"]}` / `{au["ledgerRoot"]}` |\n',
      '## 2. Decision record (investigator completes; the JSON below is inside Markdown and its placeholders are rejected)\n']
G = {'decision': '<INVESTIGATOR ONLY: GO_LP2A3_PHYSICAL, or do not create the file (HOLD_LP2A3)>',
     'decisionUrl': '<INVESTIGATOR ONLY: https://github.com/mfs9697/NewMetacomp/pull/<n>#issuecomment-<n> (or issues/<n>, or #pullrequestreview-<n>)>',
     'approvedHead': '<INVESTIGATOR ONLY: full 40-character reviewed head; the activation commit must add ONLY this GO file directly on it>',
     'token': tok, 'campaignId': au['campaignId'], 'campaignScope': au['campaignScope'], 'runName': au['runName'],
     'cases': [x['id'] for x in P['cases']], 'maxStateIndex': c['maxStateIndex'], 'maxAdmissions': c['maxAdmissions'],
     'seedSpacing_mm': P['meshFamily']['seedSpacing_mm'], 'contractEvidenceFile': rel, 'contractEvidenceSHA256': ts}
L.append('```json\n' + json.dumps(G, indent=1, ensure_ascii=False) + '\n```\n')
L += ['## 3. What a GO_LP2A3_PHYSICAL would authorize, and what it would not\n', '| Authorized | Not authorized |\n|---|---|',
      '| Continuation of the four accepted LP2-A1 S8 paths (H 000, stiff13 101, soft2 010, soft1 100; this order) by 4-mm signed-MTS steps to at most S11 (61.4 / 65.4 / 69.4 mm); at most 3 admitted states per case and 12 in total; each state meshed ONLY with the LP2-A2 family at 0.45 mm (rung 1); unchanged BVP, SIF gates and MTS; per-case stop at the first non-MATRIX_ADVANCE candidate (inherited guards + 1-mm guide-to-ring gap) or local numerical HOLD | Any S12 or later admission (S12 is forecast for information only), any other seed spacing (no fallback), retries or resumption, adaptive steps, guide reduction, passive-ring crossing, interface propagation/CZM, LP2-B, tolerance or model changes, physical arrest or interface-encounter claims, merges |',
      '| Acceptance of a new state only after all inherited gates and verified record completion | Comparison with fictitious archived S9–S11 states (none exist); WP5 C1–C11 are not acceptance thresholds |\n',
      '## 4. Guards and stop rules (fixed before any solve)\n', '| Guard / rule | Value | Outcome on failure |\n|---|---|---|',
      '| inherited nominal and actual-polygon clearance, kink/geometry, q support, tip guide 15 mm, collar 3.3 mm | unchanged (g2_lp0_clearance, g2_lp2_classify) | INTERFACE_APPROACH / HOLE_BOUNDARY_APPROACH / EXTERNAL_BOUNDARY_APPROACH / PASSIVE_CONTOUR_APPROACH; no mesh, no solve |',
      f'| guide-to-every-ring gap min_i(‖tip−c_i‖ − {P["ringProximityGuard"]["ringR_mm"]} − 15) | ≥ {P["ringProximityGuard"]["minGap_mm"]:g} mm (exactly 1 mm passes) | active ring: INTERFACE_APPROACH; passive ring: PASSIVE_CONTOUR_APPROACH; no mesh, no solve |',
      '| mesh rung 1 (0.45 mm): 34 kink-mesh gates, pairing P1–P10, phase/owner, 76 chords, T3 ≤ 40000, min angle ≥ 20°, neighbour ratio ≤ 1.8 | unchanged | TERMINAL NUMERICAL_HOLD (FAILED_MESH kept); no other spacing |',
      '| 16 SIF gates, MTS status OK, stationarity ≤ 1e-12, K_I > 0 | unchanged | TERMINAL NUMERICAL_HOLD |',
      '| source, policy, authorization, memory, record/ledger integrity, unexpected error | — | global HOLD (ledger), campaign stops, partial records kept, no resumption |',
      f'| S{c["maxStateIndex"]} accepted | cap | TERMINAL CAMPAIGN_LIMIT_REACHED (S12 candidate labelled information only) |\n',
      '## 5. Execution protocol after a GO\n',
      '1. Verify independently (`scripts/g2/lp2a3/lp2a3_hashcheck.py`) the contract-evidence SHA-256, policy, four source digests, 20 parent pins, 24 qualification records and token at the approved head; verify the 723 protected records (`lp2a3_protected.py`); confirm the GO file, run root and ledger root are absent.\n'
      '2. Activation commit: add ONLY `' + au['goPath'] + '` directly on the approved head; verify HEAD~1 and the sole changed file independently (also through cmd.exe).\n'
      f'3. Immediately before MATLAB starts: `scripts/g2/lp2a2/lp2a2_eq_prestart_check.ps1` at its default (≥ {res["freeRAMBeforeMATLABStart_GiB_min"]:g} GiB available, no MATLAB process, removable backup drive). One MATLAB R2023a/PDE process; normal preflight ({res["preflightGuard_GiB"]:g} GiB guard unchanged); `g2_lp2a2_eq_memgate` ≥ {res["freeRAMInsideMATLAB_GiB_min"]:g} GiB inside MATLAB before each admission and again before each solve; no automatic retry.\n'
      '4. Run once `g2_lp2a3_external_run(approvedHead, tok, outDir)` with a fresh outDir outside the worktree: parent/changed-file check, fresh roots, context, token, memory gate, then `g2_lp2a3_run(\'Run\',true)` per case in the fixed order; a global HOLD stops the campaign; afterwards `g2_lp2a3_verify` with terminals required.\n'
      '5. Whatever the outcome: independent read-only verification of the complete accepted prefix, terminals and ledger (not only pass labels); protected records before/after; archive on two physical devices; revoke the GO in a separate commit and show the refusal afterwards.\n'
      '6. Known limitation: the one-attempt guard is the local ledger and state folders; deleting them or using an independent clone would defeat it and is excluded by protocol.\n']
out = os.path.join(R, 'docs/research/G2_LP2A3_GO_DECISION_TEMPLATE.md')
open(out, 'w', encoding='utf-8', newline='\n').write('\n'.join(L))
print('written', out)
