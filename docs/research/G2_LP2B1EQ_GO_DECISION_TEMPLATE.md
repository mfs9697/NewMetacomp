# G2-LP2-B1-EQ — two fixed-geometry 0.40 mm equivalence solves: authorization decision record (TEMPLATE, NOT A GO)

Prepared under https://github.com/mfs9697/NewMetacomp/issues/78 (draft PR stacked on #77). **Only the principal investigator may complete this record, in a separate PR comment after an independent readiness review, and decide `GO_LP2B1_EQ` or `HOLD_LP2B1_EQ`.** No GO file exists. Without it, `g2_lp2b1eq_run(...,'Run',true)` refuses with `G2LP2B1EQ:HOLD_UNAUTHORIZED` before any folder, mesh or solve; a physical call without the normal preflight refuses with `G2LP2B1EQ:HOLD_PREFLIGHT_REQUIRED`; a physical call that does not come through `g2_lp2b1eq_external_run` refuses with `G2LP2B1EQ:HOLD_NO_RECEIPT`. Any change to a pinned source, policy, reference or qualification record changes the token, and the context fails closed with `G2LP2B1EQ:HOLD_SOURCE`. Earlier authorizations (WP5 A1/A2, LP2-A3) are consumed and cannot authorize this campaign. A GO_LP2B1_EQ would NOT authorize the target soft1 S10 solve, which needs a different, later decision.

## 1. Pins

| Field | Value |
|---|---|
| source commit of the evidence | `61733fd7d33adbaad69c09055b0bdcd74a1f93c3` |
| policy `matlab/g2/lp2b1eq/G2_LP2B1EQ_POLICY_v1.json` | `b113a7c6d7b2e8fe9950d817ccca3c851c05f1e347c73f66c604b9c41e54eecb` |
| `g2SourceSHA256` | `7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947` |
| `lp2SourceSHA256` | `357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca` |
| `lp2a2SourceSHA256` | `f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd` |
| `lp2a3SourceSHA256` | `fa3bcecfa9cd3044253d5a72253e2058bccd044d32345f51650dcd775f42e002` |
| `lp2b1SourceSHA256` | `9c7a1260e3bde5b59e1d93c47bc99cc4d7b89f9b0cc6e874572fb378f1717bee` |
| `lp2b1eqSourceSHA256` | `74a0edd827daca5714a1347705abc1429a7a573116ad3c438f9e5a1c12dfbf1f` |
| `closureSourceSHA256` | `76614f269810c6970544bca0c1c0f84ebf9131935554ebd75e57e24f819f65f7` |
| EQB-soft1-S9: archived STATE / SOLUTION / MESH / PHASE | `79ebecbc21b4d942…` / `ae981011e8092115…` / `5afd6e8199ca797c…` / `fe0ad27f471d0521…` (full values in the policy) |
| EQB-soft1-S9: next state S10, archived next tip (mm) | `114.29544883822506, 63.18559491151613` |
| EQB-soft1-S9: qualified 0.40 mm canonical digest / arrays file | `7535d71ad4790f3a24a47d03e27c3d73d8ba61df03050a2e952accfeffebee16` / `1c4de0dffd17a23aadb9f2b0e18250dd9f7c6c289d1679c47e1d074275b37449` |
| EQB-H-S10: archived STATE / SOLUTION / MESH / PHASE | `b1d929ab1faa4944…` / `51a232d061e3ceb9…` / `6e79b5e0c34cc7e0…` / `b64a080234eff198…` (full values in the policy) |
| EQB-H-S10: next state S11, archived next tip (mm) | `116.53715206030587, 66.63469316681929` |
| EQB-H-S10: qualified 0.40 mm canonical digest / arrays file | `45298fae6257674b99de036341b6d0c05b55fbb6bb7be635786f8ae71bb068e3` / `ffcb53f12c4b06b463a3df4c644d93459a4f456a04a5185fe3ad453b5db75122` |
| LP2-B1 qualification archive | `5a5a4179c987d04dcf14cf3d2552b8f9f1d9c370c370b0a6bd6c930748bbbd42` (76 members) |
| zero-FEM test evidence `docs/research/G2_LP2B1EQ_evidence/tests/tests_v3/LP2B1EQ_TESTS.json` | `35d891197fdcf7514f8486ace41ff56c406ebfa4370eb1733db99b81e5b4b77a` (252/252, `physicalSolves` 0) |
| independent hashcheck `docs/research/G2_LP2B1EQ_evidence/closure/LP2B1EQ_HASHCHECK_v1.json` | `9e30adfa724003355d089f1ad50170334ed08fc19c9c3a32cfd68491cb0d7b0b` (PASS) |
| protected records `docs/research/G2_LP2B1EQ_evidence/closure/LP2B1EQ_PROTECTED_AFTER.json` | `96c04253cc48dd5bc04808b6d0f114f8ef56864d3c831df83abbacc0d4e6753a` (PASS; 832 + 43 + 61 pinned) |
| token | `G2LP2B1EQ\|policy=b113a7c6d7b2e8fe9950d817ccca3c851c05f1e347c73f66c604b9c41e54eecb\|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947\|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca\|lp2a2source=f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd\|lp2a3source=fa3bcecfa9cd3044253d5a72253e2058bccd044d32345f51650dcd775f42e002\|lp2b1source=9c7a1260e3bde5b59e1d93c47bc99cc4d7b89f9b0cc6e874572fb378f1717bee\|lp2b1eqsource=74a0edd827daca5714a1347705abc1429a7a573116ad3c438f9e5a1c12dfbf1f\|closure=76614f269810c6970544bca0c1c0f84ebf9131935554ebd75e57e24f819f65f7\|references=63014a95ebeebd127ae094e9254331d6e32e314902b6c1d6ac2bf8abbeb3d89d\|qualification=441b1eadf330a720255f2c6b178c0c51a822e4ad99a24d0318230c0884c5d5ad\|solves=EQB-soft1-S9,EQB-H-S10\|limit=2\|seed=0.40\|campaign=G2-LP2B1-EQ-001\|run=run_lp2b1_eq_v1` |
| GO file path (fixed) | `matlab/g2/lp2b1eq/G2_LP2B1EQ_GO.json` |
| campaign / scope / run | `G2-LP2B1-EQ-001` / `LP2B1_EQ_TWO_FIXED_REFERENCES_0p40` / `run_lp2b1_eq_v1` |
| run root / receipt root (fresh; must not exist) | `outputs/g2_lp2b1_eq_v1/run_lp2b1_eq_v1` / `outputs/g2_lp2b1_eq_receipts/G2-LP2B1-EQ-001` |

## 2. Decision record (investigator completes; the JSON below is inside Markdown and its placeholders are rejected)

```json
{
 "decision": "<INVESTIGATOR ONLY: GO_LP2B1_EQ, or do not create the file (HOLD_LP2B1_EQ)>",
 "decisionUrl": "<INVESTIGATOR ONLY: https://github.com/mfs9697/NewMetacomp/pull/<n>#issuecomment-<n> (or issues/<n>, or #pullrequestreview-<n>)>",
 "approvedHead": "<INVESTIGATOR ONLY: full 40-character reviewed head; the activation commit must add ONLY this GO file directly on it>",
 "token": "G2LP2B1EQ|policy=b113a7c6d7b2e8fe9950d817ccca3c851c05f1e347c73f66c604b9c41e54eecb|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca|lp2a2source=f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd|lp2a3source=fa3bcecfa9cd3044253d5a72253e2058bccd044d32345f51650dcd775f42e002|lp2b1source=9c7a1260e3bde5b59e1d93c47bc99cc4d7b89f9b0cc6e874572fb378f1717bee|lp2b1eqsource=74a0edd827daca5714a1347705abc1429a7a573116ad3c438f9e5a1c12dfbf1f|closure=76614f269810c6970544bca0c1c0f84ebf9131935554ebd75e57e24f819f65f7|references=63014a95ebeebd127ae094e9254331d6e32e314902b6c1d6ac2bf8abbeb3d89d|qualification=441b1eadf330a720255f2c6b178c0c51a822e4ad99a24d0318230c0884c5d5ad|solves=EQB-soft1-S9,EQB-H-S10|limit=2|seed=0.40|campaign=G2-LP2B1-EQ-001|run=run_lp2b1_eq_v1",
 "campaignId": "G2-LP2B1-EQ-001",
 "campaignScope": "LP2B1_EQ_TWO_FIXED_REFERENCES_0p40",
 "runName": "run_lp2b1_eq_v1",
 "solves": [
  "EQB-soft1-S9",
  "EQB-H-S10"
 ],
 "solveLimit": 2,
 "attemptsPerSolve": 1,
 "seedSpacing_mm": 0.4,
 "contractEvidenceFile": "docs/research/G2_LP2B1EQ_evidence/tests/tests_v3/LP2B1EQ_TESTS.json",
 "contractEvidenceSHA256": "35d891197fdcf7514f8486ace41ff56c406ebfa4370eb1733db99b81e5b4b77a"
}
```

## 3. What a GO_LP2B1_EQ would authorize, and what it would not

| Authorized | Not authorized |
|---|---|
| Exactly two fixed-geometry solves in this order: EQB-soft1-S9 (accepted soft1 S9 geometry, mask 100, ratio 0.5), then EQB-H-S10 (accepted H S10 geometry, mask 000, ratio 1); each on the 0.40 mm mesh whose canonical digest and metadata equal the LP2-B1 qualification record; unchanged BVP, solver, 16 gates; comparison with the ORIGINAL accepted LP2-A3 record by C1–C11 with the original thresholds | The target soft1 S10 solve; any other geometry, state or spacing; propagation or any new STATE; a same-s or architecture contrast; retries, resumption, fallback, adaptive steps; LP2-B2; S12; tolerance or model changes; merges |
| Global stop at the first failure of any criterion, gate, integrity, resource or authorization check (the second solve is then not called) | Any claim beyond numerical equivalence on these two geometries (no discretization-error bound, convergence statement or multi-architecture qualification) |

## 4. Criteria (fixed before any solve; every bound inclusive)

| Criterion | Rule |
|---|---|
| C1_KI | |KI_new - KI_arch| / Keq_arch <= 5e-4, Keq_arch = hypot(KI_arch, KII_arch) |
| C2_KII | |KII_new - KII_arch| / Keq_arch <= 5e-5 (signed KII) |
| C3_KIIoverKI | |KII_new/KI_new - KII_arch/KI_arch| <= 1e-4 |
| C4_G_J | |G_new/G_arch - 1| <= 1e-3 and |J_new/J_arch - 1| <= 1e-3 and |J_new/G_new - 1| <= 1e-4, G = (KI^2 + KII^2)/E |
| C5_MTS | |theta_MTS,new - theta_MTS,arch| <= 0.006 deg and new tensile root admissible |
| C6_COD_EDI | new COD-EDI <= 0.03 and |new - archived COD-EDI| <= 1e-3 |
| C7_EDI_spread_quadrature | new path spread <= max(1e-5, 5 x archived) and new 4x4 quadrature drift <= max(1e-5, 5 x archived) |
| C8_crackOpening | scalar jump magnitude j = |u_U - u_L| (difference of magnitudes, NOT norm of vector differences); near tip (<= 3.3 mm, identical node positions within 1e-9 mm): max|j_new - j_arch| / max j_new(near) <= 1e-3; whole crack: archived j linearly interpolated in arc station onto new stations (no extrapolation), max|.| / max j_new <= 2e-3; signed normal opening reported only |
| C9_phaseActivation | all 16 inherited solver gates pass, chords per circle equal to archived (76 each), |dA_active| / max(A_arch, 1 mm^2) <= 1e-9 and, STRONGER (draft requirement), new active area exactly 0 when archived is exactly 0 (H) |
| C10_nextPredictor | |forecast(new K) - archived next tip| <= 5e-4 mm with the STATE-SPECIFIC next state: S10 for EQB-soft1-S9, S11 for EQB-H-S10 |
| C11_compliance | |C_new/C_arch - 1| <= 1e-3 |

Validation before any criterion (verification-infrastructure HOLD, never an equivalence statement): before any criterion: finite real inputs of the correct shape/type, positive archived KI/Keq/G/J/compliance, valid archived MTS root, all 16 archived gates, u of length 2*N_T6 for each mesh, identity of solve/case/state/mask/geometry/predictor/pins/canonical digest, paired banks with unique stations, near-tip node identity, station coverage without extrapolation, nonzero normalizations (C8 near-tip and whole-crack maxima and the maxima of the reported signed normal opening), finite metrics (a non-admissible new MTS root makes the forecast impossible: NaN next tip); any failure = INPUT_INVALID (verification-infrastructure HOLD, never an equivalence statement)

## 5. Execution protocol after a GO

1. At the approved head: `scripts/g2/lp2b1eq/lp2b1eq_hashcheck.py` (policy, seven source digests, every file pin, token, canonical digests from raw exports) and `scripts/g2/lp2b1eq/lp2b1eq_protected.py` (832 + 43 + pinned files, both archive copies of LP2-A3 and LP2-B1); confirm GO file, run root and receipt root absent.
2. Activation commit: add ONLY `matlab/g2/lp2b1eq/G2_LP2B1EQ_GO.json` directly on the approved head; verify HEAD~1 and the sole changed file independently (also through cmd.exe).
3. Immediately before MATLAB starts: `scripts/g2/lp2a2/lp2a2_eq_prestart_check.ps1` at its default (>= 8.2 GiB available, no MATLAB process, removable backup drive). One MATLAB R2023a/PDE process; normal preflight (5 GiB guard unchanged); `g2_lp2a2_eq_memgate` >= 7 GiB before the solve folder and again before the solve; no automatic retry.
4. Run once `g2_lp2b1eq_external_run(approvedHead, tok, outDir)` with a fresh outDir outside the worktree: parent/changed-file check, fresh roots, context, token, memory gate, GO validation, receipt, then `g2_lp2b1eq_campaign` (EQB-soft1-S9, then EQB-H-S10 only if the first is EQUIVALENT_CASE), then `g2_lp2b1eq_verify` (read-only).
5. Whatever the outcome: independent read-only verification of every record and metric (not only pass labels); protected records before/after; archive on two physical devices; revoke the GO in a separate commit and show the refusal afterwards; independent external audit of the records and numbers.
6. Known limitation: the one-attempt guard is the local solve folder and receipt; deleting them or using an independent clone would defeat it and is excluded by protocol.
