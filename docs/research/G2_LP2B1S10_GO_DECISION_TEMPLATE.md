# G2-LP2-B1-S10 — one soft1 S10 admission and solve at 0.40 mm: authorization decision record (TEMPLATE, NOT A GO)

Prepared under https://github.com/mfs9697/NewMetacomp/issues/81 (draft PR stacked on #79). **Only the principal investigator may complete this record, in a separate PR comment after an independent exact-head readiness review, and decide `GO_LP2B1_S10` or `HOLD_LP2B1_S10`.** No GO file exists. Without it, `g2_lp2b1s10_run('Run',true,...)` refuses with `G2LP2B1S10:HOLD_UNAUTHORIZED` before any folder, mesh or solve; a physical call without the normal preflight refuses with `G2LP2B1S10:HOLD_PREFLIGHT_REQUIRED`; a physical call that does not come through `g2_lp2b1s10_external_run` refuses with `G2LP2B1S10:HOLD_NO_RECEIPT`; any existing soft1 case folder or ledger admission refuses with `G2LP2B1S10:HOLD_ONE_ATTEMPT`. Any change to a pinned source, policy, parent, failed-S10, qualification or LP2-B1-EQ evidence file changes the token or fails the context closed (`G2LP2B1S10:HOLD_SOURCE`). All earlier authorizations (LP2-A3, LP2-B1-EQ) are consumed and revoked and cannot authorize this campaign. A `GO_LP2B1_S10` would NOT authorize any S11 mesh, admission or solve, any other spacing, or LP2-B2.

## 1. Pins

| Field | Value |
|---|---|
| source commits of the evidence | `b2a0347799dc02ac6e2f1ab76eb2589d9bce4238` (MATLAB: tests, target qualification, replay, exports) and `116f3d017430ccf9f4922cfd03381b5afdf17612` (Python hashcheck and protected check; adds only scripts/g2/lp2b1s10/*.py, token unchanged) |
| policy `matlab/g2/lp2b1s10/G2_LP2B1S10_POLICY_v1.json` | `f57433eccc5641ba253da52b723a0de6b1ad299793aa227235d309e57f120171` |
| `g2SourceSHA256` | `7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947` |
| `lp2SourceSHA256` | `357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca` |
| `lp2a2SourceSHA256` | `f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd` |
| `lp2a3SourceSHA256` | `fa3bcecfa9cd3044253d5a72253e2058bccd044d32345f51650dcd775f42e002` |
| `lp2b1SourceSHA256` | `9c7a1260e3bde5b59e1d93c47bc99cc4d7b89f9b0cc6e874572fb378f1717bee` |
| `lp2b1eqSourceSHA256` | `74a0edd827daca5714a1347705abc1429a7a573116ad3c438f9e5a1c12dfbf1f` |
| `closureSourceSHA256` | `76614f269810c6970544bca0c1c0f84ebf9131935554ebd75e57e24f819f65f7` |
| `lp2b1s10SourceSHA256` | `d544fcfde1cfaa1e7118e0c5959551bdddb1cd477739bcf55376c45fe8388ab9` |
| sole parent: ORIGINAL LP2-A3 soft1 S9 STATE / MESH / PHASE / SOLUTION | `79ebecbc21b4d9425e3a2b82a9bc17270373a85f2a7c26d11cfe1e7c9b45aec6` / `5afd6e8199ca797ced1a73ba7584c29334abdad7d2413d1bc39a2e0385d1eae0` / `fe0ad27f471d052153edbebe6ecf39e525021f5051c4572b97e3f89907f0c83e` / `ae981011e8092115037b0ae910cd92d2e7e352b2fcb88677425dfd564abcc54b` |
| preserved LP2-A3 soft1 S10 failure: TERMINAL / FAILED_MESH / HOLD | `8f0289fdd4f9c665fb1666d50aa0a1a3126210cc5f05b70e048d9616328761e7` / `ab54ecaf0ff41bb7cd16cff0eb62c29cb9104d56490201337367bca6b54b8e12` / `dc4043f300dd459fceb4280022f8f1d2e1130c859ee8bb3b0d0a480e9d909ba0` |
| target: soft1 S10, mask 100, ratio 0.5, s = 65.4 mm, tip (mm) | `114.29544883822506, 63.18559491151613` (signed-MTS forecast of the original S9, bitwise) |
| ring-1 guide gap (MATLAB guard / issue value) | `4.6329563816383335` mm / `4.632956381638341` mm (|difference| <= 1e-12 mm) |
| qualified 0.40 mm canonical digest / arrays file | `54293d2a527f9bec33605ffea10c8f56af46a56291157f0d911cf68301b85bd2` / `086b6671a733bafad3874dee8d50c84bc52e6bfaa6ba0174caae09995c2f2a88` |
| expected T3 / minimum angle / maximum neighbour ratio | 30357 / `23.179107436795395` deg / `1.6015350873084404` (limits 20 deg / 1.8 / 40000 unchanged) |
| LP2-B1 archive / LP2-B1-EQ campaign archive | `5a5a4179c987d04dcf14cf3d2552b8f9f1d9c370c370b0a6bd6c930748bbbd42` / `1d739f80fe77597e3749de7e939abf8f572bc48f27bb703c28d02f94634d6e8a` |
| zero-FEM test evidence (committed, sanitized) `docs/research/G2_LP2B1S10_evidence/tests/tests_v2/LP2B1S10_TESTS.json` | `9d97017e78d0fdc58d1d75b45dcd8e8e58ed48c0e2874b9d6877cac32381cf64` (96/96, `physicalSolves` 0) |
| independent hashcheck `docs/research/G2_LP2B1S10_evidence/closure/LP2B1S10_HASHCHECK_v1.json` | `e8b489bea29a999b61a58afec65149e98e2e01037c98b7eebb789f8388d4b105` (PASS, 15/15) |
| protected records `docs/research/G2_LP2B1S10_evidence/closure/LP2B1S10_PROTECTED_BEFORE.json` | `7445eb76949ca3c9d77468dd332a41a88fc5980a0eb4e3ac41a60f5ad3887c8e` (PASS; unique union 918 = 891 + 23 + 4 new S10 pins; manifest `e1ed9be06011cb3e…`) |
| token | `G2LP2B1S10\|policy=f57433eccc5641ba253da52b723a0de6b1ad299793aa227235d309e57f120171\|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947\|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca\|lp2a2source=f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd\|lp2a3source=fa3bcecfa9cd3044253d5a72253e2058bccd044d32345f51650dcd775f42e002\|lp2b1source=9c7a1260e3bde5b59e1d93c47bc99cc4d7b89f9b0cc6e874572fb378f1717bee\|lp2b1eqsource=74a0edd827daca5714a1347705abc1429a7a573116ad3c438f9e5a1c12dfbf1f\|closure=76614f269810c6970544bca0c1c0f84ebf9131935554ebd75e57e24f819f65f7\|lp2b1s10source=d544fcfde1cfaa1e7118e0c5959551bdddb1cd477739bcf55376c45fe8388ab9\|parent=9f3c173fadd370ae3e455b3aef3d5aa4d1f3035faf6100d717d4175ae33f194b\|qualification=773f42aef75b13542efc6a169c9f526f6e64597a8d359df0ab067abf6cf161df\|eqcampaign=91ff13fa86617f8236b09c439f7048f4542520e79c31003c01f07957e5cf17b9\|case=soft1\|state=S10\|admissions=1\|seed=0.40\|campaign=G2-LP2B1-S10-001\|run=run_lp2b1_s10_v1` |
| GO file path (fixed) | `matlab/g2/lp2b1s10/G2_LP2B1S10_GO.json` |
| campaign / scope / run | `G2-LP2B1-S10-001` / `LP2B1_S10_SOFT1_SINGLE_STATE_0p40` / `run_lp2b1_s10_v1` |
| run root / receipt (ledger) root / summary (fresh; must not exist) | `outputs/g2_lp2b1_s10_v1/run_lp2b1_s10_v1` / `outputs/g2_lp2b1_s10_receipts/G2-LP2B1-S10-001` / `outputs/LP2B1S10_CAMPAIGN.json` |

## 2. Decision record (investigator completes; the JSON below is inside Markdown and its placeholders are rejected)

```json
{
 "decision": "<INVESTIGATOR ONLY: GO_LP2B1_S10, or do not create the file (HOLD_LP2B1_S10)>",
 "decisionUrl": "<INVESTIGATOR ONLY: https://github.com/mfs9697/NewMetacomp/pull/<n>#issuecomment-<n> (or issues/<n>, or #pullrequestreview-<n>)>",
 "approvedHead": "<INVESTIGATOR ONLY: full 40-character reviewed head; the activation commit must add ONLY this GO file directly on it>",
 "token": "G2LP2B1S10|policy=f57433eccc5641ba253da52b723a0de6b1ad299793aa227235d309e57f120171|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca|lp2a2source=f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd|lp2a3source=fa3bcecfa9cd3044253d5a72253e2058bccd044d32345f51650dcd775f42e002|lp2b1source=9c7a1260e3bde5b59e1d93c47bc99cc4d7b89f9b0cc6e874572fb378f1717bee|lp2b1eqsource=74a0edd827daca5714a1347705abc1429a7a573116ad3c438f9e5a1c12dfbf1f|closure=76614f269810c6970544bca0c1c0f84ebf9131935554ebd75e57e24f819f65f7|lp2b1s10source=d544fcfde1cfaa1e7118e0c5959551bdddb1cd477739bcf55376c45fe8388ab9|parent=9f3c173fadd370ae3e455b3aef3d5aa4d1f3035faf6100d717d4175ae33f194b|qualification=773f42aef75b13542efc6a169c9f526f6e64597a8d359df0ab067abf6cf161df|eqcampaign=91ff13fa86617f8236b09c439f7048f4542520e79c31003c01f07957e5cf17b9|case=soft1|state=S10|admissions=1|seed=0.40|campaign=G2-LP2B1-S10-001|run=run_lp2b1_s10_v1",
 "campaignId": "G2-LP2B1-S10-001",
 "campaignScope": "LP2B1_S10_SOFT1_SINGLE_STATE_0p40",
 "runName": "run_lp2b1_s10_v1",
 "target": "soft1-S10",
 "admissions": 1,
 "physicalSolves": 1,
 "attemptsPerSolve": 1,
 "seedSpacing_mm": 0.4,
 "contractEvidenceFile": "docs/research/G2_LP2B1S10_evidence/tests/tests_v2/LP2B1S10_TESTS.json",
 "contractEvidenceSHA256": "9d97017e78d0fdc58d1d75b45dcd8e8e58ed48c0e2874b9d6877cac32381cf64"
}
```

## 3. What a GO_LP2B1_S10 would authorize, and what it would not

| Authorized | Not authorized |
|---|---|
| Exactly ONE admission and ONE physical solve: soft1 S10 continuing the ORIGINAL accepted LP2-A3 soft1 S9 STATE, on the 0.40 mm mesh whose canonical digest and metadata equal the LP2-B1 qualification (protected-block baseline: the preserved FAILED_MESH of the same geometry); original BVP, materials, unchanged solver and 16 gates; a new STATE only if every LP2-A3 acceptance gate passes; S11 forecast for information only | Any S11 mesh, admission or solve; any retry, resumption or fallback; another spacing; the LP2-B1-EQ re-solve as parent; any equivalence claim for the target; alteration of the closed LP2-A3 ledger or any historical record; LP2-B2; merges |
| A local HOLD (mesh, clearance, gates, MTS) preserves the partial records and ends the campaign | Any claim of arrest, interface encounter, general numerical accuracy or convergence |

## 4. Acceptance (fixed before any solve)

1. target qualification (parent pins/links/identity, signed-MTS forecast bitwise = FAILED_MESH polyline = TERMINAL candidate = pinned tip, nominal clearance and 1 mm guard MATRIX_ADVANCE)
2. pre-admission 7 GiB memory gate, then g2_lp1_admit_state (5 GiB guard, no partial-state retry) with the campaign ledger ADMIT (exactly one, key soft1_S10)
3. g2_lp2b1eq_geometry PASS (attempt 19/19, canonical = pin, 14 arrays = qualification, pairing 10/10, audit 34/34, four-mask phase audit, 76 chords, protected topology, ring polygons, stations) and expected T3/min angle/max ratio exactly
4. actual-polygon clearance on the 0.40 mm clearance geometry and the 1 mm guide-to-every-ring guard: MATRIX_ADVANCE (as LP2-A3 computeState)
5. 7 GiB and 5 GiB memory gates before the solve
6. all 16 g2_m4b_sif_partial gates (K.pass)
7. KI > 0 and admissible tensile MTS root (status OK, stationarity <= 1e-12)
8. kink admissibility recorded (as LP2-A3)
9. STATE written only after all of the above; TERMINAL with the S11 forecast for information only

No C1–C11 equivalence criterion applies to the target: no valid 0.45 mm soft1 S10 solution exists. The accepted LP2-B1-EQ demonstration is qualification evidence for the 0.40 mm family only, not a proof that the target is equivalent or converged.

## 5. Execution protocol after a GO

1. At the approved head, in the single clean execution clone: `scripts/g2/lp2b1s10/lp2b1s10_hashcheck.py` and `scripts/g2/lp2b1s10/lp2b1s10_protected.py` (backup locations as arguments); confirm the GO file, run root, receipt root and summary absent; verify the removable backup drive is attached, stable (connection log) and holds every archive copy.
2. Real correct-token refusal before activation (`G2LP2B1S10:HOLD_UNAUTHORIZED`, no writes) under the normal preflight.
3. Activation commit: add ONLY `matlab/g2/lp2b1s10/G2_LP2B1S10_GO.json` directly on the approved head; verify HEAD~1, the committed bytes and the sole changed file independently (also through cmd.exe).
4. Immediately before each MATLAB start: `scripts/g2/lp2a2/lp2a2_eq_prestart_check.ps1` at its default (>= 8.2 GiB available, no MATLAB process, removable backup drive). One MATLAB R2023a / PDE 3.10 process; normal preflight (5 GiB guard unchanged); `g2_lp2a2_eq_memgate` >= 7 GiB before the admission and again before the solve; no automatic retry.
5. Run once `g2_lp2b1s10_external_run(approvedHead, tok, outDir)` with a fresh outDir outside the worktree: parent/changed-file check, fresh roots and summary, context, token, PDE 3.10, memory gate, GO validation, ledger RECEIPT, then exactly one `g2_lp2b1s10_run('Run',true)`, then `g2_lp2b1s10_verify` (read-only). Never re-run the wrapper after any failure.
6. Whatever the outcome: independent read-only audit beyond the verifier; protected records before/after; archive on two physical devices; revoke the GO in a separate commit restoring the reviewed tree and show the correct-token refusal afterwards.
7. Known limitation: the one-attempt guard is the local case folder and ledger; deleting them or using an independent clone would defeat it and is excluded by protocol.

## 6. Scientific analysis after an accepted S10 (separately reviewed)

Evolution of soft1 amplification from S9 (no presupposed sign or trend); absolute G and F_G against the ORIGINAL accepted H S10 (not the LP2-B1-EQ re-solve); signed K_I, K_II and mixity; local MTS angle and global heading; lateral offset relative to H; distances to all three rings; comparison of the four architectures at the common accepted s = 65.4 mm; S11 forecast geometry and guide clearance for information only.
