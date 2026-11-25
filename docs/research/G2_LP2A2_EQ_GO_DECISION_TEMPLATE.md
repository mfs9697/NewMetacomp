# G2-LP2-A2 — SIF-equivalence authorization decision record, activation attempt A2 (TEMPLATE, NOT A GO)

**Activation history.** Attempt A1 (authorization https://github.com/mfs9697/NewMetacomp/pull/71#issuecomment-7167996437 on `4d3701e`; GO `91667cf`, revoked `91718b0`) stopped before the first wrapper call with `HOLD_LP2A2_EQ_ACTIVATION_BINDING_WINDOWS_CARET` (an unquoted `HEAD^` lost its caret in cmd.exe); zero solves. That authorization is consumed and **may not be reused**. This template is for a separate attempt A2 only, after the Windows correction prepared under https://github.com/mfs9697/NewMetacomp/pull/71#pullrequestreview-6063184270.

Prepared under the LP2-A2 assignment (draft PR #71 stacked on #70). **Only the investigator may complete this record and decide `GO_LP2A2_EQ` or `HOLD_LP2A2_EQ`.** No GO file exists; `g2_lp2a2_eq_run(...,'Run',true)` refuses with `G2LP2A2:HOLD_UNAUTHORIZED` before any folder, mesh record or solve (E5), and a physical call without the normal preflight refuses with `G2LP2A2:HOLD_PREFLIGHT_REQUIRED` (E9). The GO record is checked by `g2_lp2a2_eq_go_validate` (E8). Any change to a pinned source, policy, test set or archived record changes the token, and the context fails closed with `G2LP2A2:HOLD_SOURCE`.

## 1. Pins

| Field | Value |
|---|---|
| source commit of the evidence | `0809c6737a6aad29f7aacea5b9d63c0e1077277a` |
| policy `matlab/g2/lp2a2/G2_LP2A2_EQ_POLICY_v1.json` | `6f2c290b37d4f8291f428ec8b9e0a886fe6b31fc901bee5781f2518e67c94756` |
| `g2SourceSHA256` | `7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947` |
| `lp2SourceSHA256` | `357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca` |
| `lp2a2SourceSHA256` | `f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd` |
| `testSetSHA256` | `7d2b6d352217bd5130f14f3d4aa9c89145b0efc7cd56a0c065abcaf9ebc4d711` |
| `lp1PolicySHA256` | `074d7edc981920537726314f781f24b41ac7224c18d594d6a1b15343084e5091` |
| `lp2PolicySHA256` | `093a546b9bae54d8fab0026420c8d85dced85f0e0e6ed212d597b3fd1aa6eec5` |
| zero-FEM evidence `docs/research/G2_LP2A2_evidence/eq/v3/LP2A2_EQ_TESTS_v3.json` | `75057751f4d58733d988dc8480440ae4a5ad6f3dff9c9d8819119919c1d2482f` (80/80, `physicalSolves` 0) |
| token | `G2LP2A2EQ\|policy=6f2c290b37d4f8291f428ec8b9e0a886fe6b31fc901bee5781f2518e67c94756\|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947\|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca\|lp2a2source=f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd\|archivedS8=da951c99c0d8c1d5dd731986d8f3b30e3db3f71854166a634d35b739757def8d\|solves=EQ-H,EQ-stiff13,EQ-soft2,EQ-soft1\|limit=4` |
| GO file path (fixed) | `matlab/g2/lp2a2/G2_LP2A2_EQ_GO.json` |
| campaign / output | `G2-LP2A2-EQ-001` / `outputs/g2_lp2a2_eq_v1/<solveId>/` |

## 2. Decision record (investigator completes; the JSON below is inside Markdown and its placeholders are rejected)

```json
{
 "decision": "<INVESTIGATOR ONLY: GO_LP2A2_EQ, or do not create the file (HOLD_LP2A2_EQ)>",
 "decisionUrl": "<INVESTIGATOR ONLY: https://github.com/mfs9697/NewMetacomp/pull/<n>#issuecomment-<n> or #pullrequestreview-<n>>",
 "approvedHead": "<INVESTIGATOR ONLY: full 40-character reviewed head; the activation commit must add ONLY this GO file directly on it>",
 "token": "G2LP2A2EQ|policy=6f2c290b37d4f8291f428ec8b9e0a886fe6b31fc901bee5781f2518e67c94756|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca|lp2a2source=f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd|archivedS8=da951c99c0d8c1d5dd731986d8f3b30e3db3f71854166a634d35b739757def8d|solves=EQ-H,EQ-stiff13,EQ-soft2,EQ-soft1|limit=4",
 "solveLimit": 4,
 "solves": [
  "EQ-H",
  "EQ-stiff13",
  "EQ-soft2",
  "EQ-soft1"
 ],
 "campaignId": "G2-LP2A2-EQ-001",
 "contractEvidenceFile": "docs/research/G2_LP2A2_evidence/eq/v3/LP2A2_EQ_TESTS_v3.json",
 "contractEvidenceSHA256": "75057751f4d58733d988dc8480440ae4a5ad6f3dff9c9d8819119919c1d2482f"
}
```

## 3. What a GO_LP2A2_EQ would authorize, and what it would not

| Authorized | Not authorized |
|---|---|
| Exactly four fixed-geometry solves, one attempt each, in this order: EQ-H (H S8, H), EQ-stiff13 (stiff13 S8, stiff13), EQ-soft2 (soft2 S8, soft2), EQ-soft1 (soft1 S8, soft1), on the bit-identical accepted LP2-A1 S8 polylines with the LP2-A2 paired-bank mesh family at rung 1 (0.45 mm) | Any S9 or later solve, any accepted state, any trajectory step (S9-S11 physical continuation stays HOLD until equivalence passes and a separate authorization), fallback-spacing solves (0.40/0.50/0.35 mm), adaptive stepping, guide reduction, passive-ring crossing, interface/CZM, M5, retries, tolerance changes after a solve |
| Comparison with the archived S8 solutions by the preregistered criteria C1–C11 and the architecture-contrast check | Treating equivalence as a certified discretization-error bound |

## 4. Preregistered tolerances (fixed before any solve)

| Criterion | Tolerance |
|---|---|
| C1 K_I | |ΔK_I|/K_eq ≤ 0.0005 |
| C2 K_II | |ΔK_II|/K_eq ≤ 5e-05 |
| C3 K_II/K_I | |Δ| ≤ 0.0001 |
| C4 G, J | |ΔG/G|, |ΔJ/J| ≤ 0.001; new |J/G−1| ≤ 0.0001 |
| C5 MTS | |Δθ| ≤ 0.006° |
| C6 COD–EDI | new ≤ 0.03 (inherited gate); |Δ| ≤ 0.001 |
| C7 EDI spread, 4×4 quadrature | new ≤ max(1e-05, 5× archived) |
| C8 crack opening | near tip ≤ 0.001; whole crack ≤ 0.002 of the maximum |
| C9 phase activation | solver gates pass, same chords per circle, active area ≤ 1e-09 relative |
| C10 S9 predictor | tip displacement ≤ 0.0005 mm |
| C11 compliance | ≤ 0.001 relative |
| Contrast | |ΔF_G| ≤ 0.0002, same signs and order; |Δ(θ_X−θ_H)| ≤ 0.01° |

Justifications are in the policy (`toleranceJustification`). EQUIVALENT means all criteria of all four solves and the contrast pass: numerical equivalence on four geometries, **not** a certified error bound. Any failure → HOLD, no retry.

## 5. Execution protocol after a GO (activation attempt A2)

1. Verify externally (independent Python, `scripts/g2/lp2a2/lp2a2_eq_hashcheck.py`) the contract-evidence SHA-256 above, the policy SHA, the three source digests and the token at the approved head.
2. Activation commit: add ONLY `matlab/g2/lp2a2/G2_LP2A2_EQ_GO.json` directly on the approved head (validator check `activationBinding`); no other change. All activation git queries go through `g2_lp2a2_git` (parent as `HEAD~1`, exit status checked, exact 40-hex output; real-git Windows tests E12).
3. Before MATLAB starts: `scripts/g2/lp2a2/lp2a2_eq_prestart_check.ps1` must pass (>= 8.2 GiB available, no MATLAB process, removable backup drive). Then one MATLAB R2023a process, normal preflight (5 GiB guard unchanged), physical-memory gate `g2_lp2a2_eq_memgate` >= 7 GiB inside MATLAB, the single execution clone (no alternate clone).
4. Run the external script `g2_lp2a2_eq_external_run(approvedHead, tok, outDir)` (the corrected successor of the preserved attempt-1 script): it repeats the parent and changed-file check, the context, token, GO validation and memory gate, and only then calls the wrapper `g2_lp2a2_eq_campaign(tok)` once. The wrapper calls EQ-H, EQ-stiff13, EQ-soft2, EQ-soft1 once each and stops the WHOLE campaign at any exception, HOLD stage, incomplete record or failed comparison (E10); attempted folders are preserved; no retry; after four passes the contrast check decides EQUIVALENT / NOT_EQUIVALENT_HOLD.
5. Whatever the outcome (also after a HOLD): read-only replay `g2_lp2a2_eq_verify` (zero solves, records unchanged), protected trees before/after identical, archive on two physical devices, revoke the GO in a separate commit and verify the refusal.
6. Names: docs/research/G2_LP2A2_evidence/eq_campaign_A2/, LP2A2_EQ_A2_*.json, NewMetacomp_G2_LP2A2_EQ_A2_Records_<date>.zip; the attempt-A1 evidence `docs/research/G2_LP2A2_evidence/eq_campaign/` and its HOLD archive stay unchanged.
7. Known limitation: the one-attempt guard is the local solve folder; deleting it or using an independent clone would defeat it and is excluded by protocol and by the archive review.
