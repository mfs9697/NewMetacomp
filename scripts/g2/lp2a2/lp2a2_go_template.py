"""Write docs/research/G2_LP2A2_EQ_GO_DECISION_TEMPLATE.md from the committed policy and the zero-FEM
test evidence (values copied mechanically; the template is NOT a GO and creates no GO file).
usage: python -I scripts/g2/lp2a2/lp2a2_go_template.py <repo> <EQ_TESTS.json> <sourceCommit>"""
import json, sys, os, hashlib
R, tj, commit = sys.argv[1], sys.argv[2], sys.argv[3]
pf = os.path.join(R, 'matlab/g2/lp2a2/G2_LP2A2_EQ_POLICY_v1.json')
P = json.load(open(pf, encoding='utf-8')); T = json.load(open(tj, encoding='utf-8'))
ps = hashlib.sha256(open(pf, 'rb').read()).hexdigest(); ts = hashlib.sha256(open(tj, 'rb').read()).hexdigest()
assert ps == T['policySHA256'] and T['passed'] == T['total'] and T['physicalSolves'] == 0
tok = T['token']; tol = P['tolerances']
rel = os.path.relpath(tj, R).replace(os.sep, '/')
L = []
L.append('# G2-LP2-A2 — SIF-equivalence authorization decision record (TEMPLATE, NOT A GO)\n')
L.append('Prepared under the LP2-A2 assignment (draft PR #71 stacked on #70; review https://github.com/mfs9697/NewMetacomp/pull/71#pullrequestreview-6058599118). **Only the investigator may complete this record and decide `GO_LP2A2_EQ` or `HOLD_LP2A2_EQ`.** No GO file exists; `g2_lp2a2_eq_run(...,\'Run\',true)` refuses with `G2LP2A2:HOLD_UNAUTHORIZED` before any folder, mesh record or solve (E5), and a physical call without the normal preflight refuses with `G2LP2A2:HOLD_PREFLIGHT_REQUIRED` (E9). The GO record is checked by `g2_lp2a2_eq_go_validate` (E8). Any change to a pinned source, policy, test set or archived record changes the token, and the context fails closed with `G2LP2A2:HOLD_SOURCE`.\n')
L.append('## 1. Pins\n')
L.append('| Field | Value |\n|---|---|')
L.append(f'| source commit of the evidence | `{commit}` |')
L.append(f'| policy `matlab/g2/lp2a2/G2_LP2A2_EQ_POLICY_v1.json` | `{ps}` |')
for k in ('g2SourceSHA256', 'lp2SourceSHA256', 'lp2a2SourceSHA256', 'testSetSHA256', 'lp1PolicySHA256', 'lp2PolicySHA256'):
    L.append(f'| `{k}` | `{P["pins"][k]}` |')
L.append(f'| zero-FEM evidence `{rel}` | `{ts}` ({T["passed"]}/{T["total"]}, `physicalSolves` 0) |')
L.append(f'| token | `{tok.replace("|", chr(92) + "|")}` |')
L.append(f'| GO file path (fixed) | `{P["goFile"]}` |')
L.append(f'| campaign / output | `{P["campaignId"]}` / `{P["outputRoot"]}/<solveId>/` |\n')
L.append('## 2. Decision record (investigator completes; the JSON below is inside Markdown and its placeholders are rejected)\n')
G = {'decision': '<INVESTIGATOR ONLY: GO_LP2A2_EQ, or do not create the file (HOLD_LP2A2_EQ)>',
     'decisionUrl': '<INVESTIGATOR ONLY: https://github.com/mfs9697/NewMetacomp/pull/<n>#issuecomment-<n> or #pullrequestreview-<n>>',
     'approvedHead': '<INVESTIGATOR ONLY: full 40-character reviewed head; the activation commit must add ONLY this GO file directly on it>',
     'token': tok, 'solveLimit': 4, 'solves': [s['id'] for s in P['solves']], 'campaignId': P['campaignId'],
     'contractEvidenceFile': rel, 'contractEvidenceSHA256': ts}
L.append('```json\n' + json.dumps(G, indent=1, ensure_ascii=False) + '\n```\n')
L.append('## 3. What a GO_LP2A2_EQ would authorize, and what it would not\n')
L.append('| Authorized | Not authorized |\n|---|---|')
L.append('| Exactly four fixed-geometry solves, one attempt each, in this order: EQ-H (H S8, H), EQ-stiff13 (stiff13 S8, stiff13), EQ-soft2 (soft2 S8, soft2), EQ-soft1 (soft1 S8, soft1), on the bit-identical accepted LP2-A1 S8 polylines with the LP2-A2 paired-bank mesh family at rung 1 (0.45 mm) | Any S9 or later solve, any accepted state, any trajectory step (S9-S11 physical continuation stays HOLD until equivalence passes and a separate authorization), fallback-spacing solves (0.40/0.50/0.35 mm), adaptive stepping, guide reduction, passive-ring crossing, interface/CZM, M5, retries, tolerance changes after a solve |')
L.append('| Comparison with the archived S8 solutions by the preregistered criteria C1–C11 and the architecture-contrast check | Treating equivalence as a certified discretization-error bound |\n')
L.append('## 4. Preregistered tolerances (fixed before any solve)\n')
L.append('| Criterion | Tolerance |\n|---|---|')
rows = [('C1 K_I', f'|ΔK_I|/K_eq ≤ {tol["KI_overKeq"]:g}'), ('C2 K_II', f'|ΔK_II|/K_eq ≤ {tol["KII_overKeq"]:g}'),
        ('C3 K_II/K_I', f'|Δ| ≤ {tol["KIIoverKI_abs"]:g}'), ('C4 G, J', f'|ΔG/G|, |ΔJ/J| ≤ {tol["G_rel"]:g}; new |J/G−1| ≤ {tol["newJoverGminus1"]:g}'),
        ('C5 MTS', f'|Δθ| ≤ {tol["MTS_deg"]:g}°'), ('C6 COD–EDI', f'new ≤ {tol["newCODminusEDI_gate"]:g} (inherited gate); |Δ| ≤ {tol["dCODminusEDI"]:g}'),
        ('C7 EDI spread, 4×4 quadrature', f'new ≤ max({tol["spreadFloor"]:g}, {tol["spreadFactor"]:g}× archived)'),
        ('C8 crack opening', f'near tip ≤ {tol["openingNearTipRel"]:g}; whole crack ≤ {tol["openingWholeCrackRel"]:g} of the maximum'),
        ('C9 phase activation', f'solver gates pass, same chords per circle, active area ≤ {tol["activeArea_rel"]:g} relative'),
        ('C10 S9 predictor', f'tip displacement ≤ {tol["S9tipDisplacement_mm"]:g} mm'), ('C11 compliance', f'≤ {tol["compliance_rel"]:g} relative'),
        ('Contrast', f'|ΔF_G| ≤ {tol["contrast_FG_abs"]:g}, same signs and order; |Δ(θ_X−θ_H)| ≤ {tol["contrast_MTS_deg"]:g}°')]
for a, b in rows: L.append(f'| {a} | {b} |')
L.append('\nJustifications are in the policy (`toleranceJustification`). EQUIVALENT means all criteria of all four solves and the contrast pass: numerical equivalence on four geometries, **not** a certified error bound. Any failure → HOLD, no retry.\n')
L.append('## 5. Execution protocol after a GO\n')
L.append('1. Verify externally (independent Python) the contract-evidence SHA-256 above, the policy SHA, the three source digests and the token at the approved head.\n'
         '2. Activation commit: add ONLY `' + P['goFile'] + '` directly on the approved head (validator check `activationBinding`); no other change.\n'
         '3. One MATLAB process, normal preflight (≥ 5 GiB guard unchanged), physical-memory gate `g2_lp2a2_eq_memgate` ≥ 7 GiB inside MATLAB, removable backup device attached, the single execution clone (no alternate clone).\n'
         '4. Run the external wrapper `g2_lp2a2_eq_campaign(tok)`: it validates the GO again, calls EQ-H, EQ-stiff13, EQ-soft2, EQ-soft1 once each and stops the WHOLE campaign at any exception, HOLD stage, incomplete record or failed comparison (E10); attempted folders are preserved; no retry; after four passes the contrast check decides EQUIVALENT / NOT_EQUIVALENT_HOLD.\n'
         '5. Whatever the outcome (also after a HOLD): read-only replay `g2_lp2a2_eq_verify` (zero solves, records unchanged), protected trees before/after identical, archive on two physical devices, revoke the GO in a separate commit and verify the refusal.\n'
         '6. Known limitation: the one-attempt guard is the local solve folder; deleting it or using an independent clone would defeat it and is excluded by protocol and by the archive review.\n')
out = os.path.join(R, 'docs/research/G2_LP2A2_EQ_GO_DECISION_TEMPLATE.md')
open(out, 'w', encoding='utf-8', newline='\n').write('\n'.join(L))
print('written', out)
