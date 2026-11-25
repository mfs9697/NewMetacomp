# G2-LP2-A3 — restricted S9–S11 continuation: authorization decision record (TEMPLATE, NOT A GO)

Prepared under https://github.com/mfs9697/NewMetacomp/issues/74 (draft PR stacked on #71). **Only the principal investigator may complete this record, in a separate PR comment, and decide `GO_LP2A3_PHYSICAL` or `HOLD_LP2A3`.** No GO file exists. Without it, `g2_lp2a3_run(...,'Run',true)` refuses with `G2LP2A3:HOLD_UNAUTHORIZED` before any folder, mesh or solve; a physical call without the normal preflight refuses with `G2LP2A3:HOLD_PREFLIGHT_REQUIRED`. The GO record is checked by `g2_lp2a3_go_validate`, including the git activation binding. Any change to a pinned source, policy, parent or qualification record changes the token, and the context fails closed with `G2LP2A3:HOLD_SOURCE`. The WP5 authorizations (A1 and A2) are consumed and cannot authorize LP2-A3.

## 1. Pins

| Field | Value |
|---|---|
| source commit of the evidence | `2775d8b21ec908d7c626d24013c7e8053d63e5e1` |
| policy `matlab/g2/lp2a3/G2_LP2A3_POLICY_v1.json` | `7a6e17f8baa85c6e6f10186bfab3a9c10c9363e0acb5e532c00095961bf45d43` |
| `g2SourceSHA256` | `7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947` |
| `lp2SourceSHA256` | `357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca` |
| `lp2a2SourceSHA256` | `f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd` |
| `lp2a3SourceSHA256` | `fa3bcecfa9cd3044253d5a72253e2058bccd044d32345f51650dcd775f42e002` |
| S8 parents (20 files, LP2-A1 ledger manifest) | see `parents.S8` in the policy; manifest `bd0aa185e1858c82ff0864730d38dd873328297767627d9b366ebe6b837e1de3` |
| WP5 qualification (24 records + 8 evidence files + archive `96ed7a364d874254…`) | see `qualificationEvidence` in the policy |
| zero-FEM contract evidence `docs/research/G2_LP2A3_evidence/LP2A3_TESTS_v1.json` | `2aa6a9046c9611786963f1abb3d9567aeab2b7f71f4ea80ec1d01e08b29c6a0c` (78/78, `physicalSolves` 0) |
| token | `G2LP2A3\|policy=7a6e17f8baa85c6e6f10186bfab3a9c10c9363e0acb5e532c00095961bf45d43\|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947\|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca\|lp2a2source=f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd\|lp2a3source=fa3bcecfa9cd3044253d5a72253e2058bccd044d32345f51650dcd775f42e002\|parentsS8=da951c99c0d8c1d5dd731986d8f3b30e3db3f71854166a634d35b739757def8d\|qualification=a77f49200f9f95b36260f44306afd4b05690d8ec9353c4fa71f4b5adbe5d4ded\|cases=H,stiff13,soft2,soft1\|states=S9-S11\|maxAdmissions=12\|seed=0.45\|campaign=G2-LP2A3-001\|run=run_lp2a3_s9_s11_v1` |
| GO file path (fixed) | `matlab/g2/lp2a3/G2_LP2A3_GO.json` |
| campaign / scope / run | `G2-LP2A3-001` / `LP2A3_S9_S11_MAX12` / `run_lp2a3_s9_s11_v1` |
| run root / ledger root (fresh; must not exist) | `outputs/g2_lp2a3_paths_v1/run_lp2a3_s9_s11_v1` / `outputs/g2_lp2a3_campaign_ledger/G2-LP2A3-001` |

## 2. Decision record (investigator completes; the JSON below is inside Markdown and its placeholders are rejected)

```json
{
 "decision": "<INVESTIGATOR ONLY: GO_LP2A3_PHYSICAL, or do not create the file (HOLD_LP2A3)>",
 "decisionUrl": "<INVESTIGATOR ONLY: https://github.com/mfs9697/NewMetacomp/pull/<n>#issuecomment-<n> (or issues/<n>, or #pullrequestreview-<n>)>",
 "approvedHead": "<INVESTIGATOR ONLY: full 40-character reviewed head; the activation commit must add ONLY this GO file directly on it>",
 "token": "G2LP2A3|policy=7a6e17f8baa85c6e6f10186bfab3a9c10c9363e0acb5e532c00095961bf45d43|g2source=7e5683703bd104547ef5d013aa0253ad2819b59dc58693957e2d04b4707f0947|lp2source=357dfdcdb576d2866b9d1b41a14265300a14c30700d6475f995881041ba822ca|lp2a2source=f1d7e4d67b91968e16ebaead13be86667c7776ce48971ed5206c7f136fae7afd|lp2a3source=fa3bcecfa9cd3044253d5a72253e2058bccd044d32345f51650dcd775f42e002|parentsS8=da951c99c0d8c1d5dd731986d8f3b30e3db3f71854166a634d35b739757def8d|qualification=a77f49200f9f95b36260f44306afd4b05690d8ec9353c4fa71f4b5adbe5d4ded|cases=H,stiff13,soft2,soft1|states=S9-S11|maxAdmissions=12|seed=0.45|campaign=G2-LP2A3-001|run=run_lp2a3_s9_s11_v1",
 "campaignId": "G2-LP2A3-001",
 "campaignScope": "LP2A3_S9_S11_MAX12",
 "runName": "run_lp2a3_s9_s11_v1",
 "cases": [
  "H",
  "stiff13",
  "soft2",
  "soft1"
 ],
 "maxStateIndex": 11,
 "maxAdmissions": 12,
 "seedSpacing_mm": 0.45,
 "contractEvidenceFile": "docs/research/G2_LP2A3_evidence/LP2A3_TESTS_v1.json",
 "contractEvidenceSHA256": "2aa6a9046c9611786963f1abb3d9567aeab2b7f71f4ea80ec1d01e08b29c6a0c"
}
```

## 3. What a GO_LP2A3_PHYSICAL would authorize, and what it would not

| Authorized | Not authorized |
|---|---|
| Continuation of the four accepted LP2-A1 S8 paths (H 000, stiff13 101, soft2 010, soft1 100; this order) by 4-mm signed-MTS steps to at most S11 (61.4 / 65.4 / 69.4 mm); at most 3 admitted states per case and 12 in total; each state meshed ONLY with the LP2-A2 family at 0.45 mm (rung 1); unchanged BVP, SIF gates and MTS; per-case stop at the first non-MATRIX_ADVANCE candidate (inherited guards + 1-mm guide-to-ring gap) or local numerical HOLD | Any S12 or later admission (S12 is forecast for information only), any other seed spacing (no fallback), retries or resumption, adaptive steps, guide reduction, passive-ring crossing, interface propagation/CZM, LP2-B, tolerance or model changes, physical arrest or interface-encounter claims, merges |
| Acceptance of a new state only after all inherited gates and verified record completion | Comparison with fictitious archived S9–S11 states (none exist); WP5 C1–C11 are not acceptance thresholds |

## 4. Guards and stop rules (fixed before any solve)

| Guard / rule | Value | Outcome on failure |
|---|---|---|
| inherited nominal and actual-polygon clearance, kink/geometry, q support, tip guide 15 mm, collar 3.3 mm | unchanged (g2_lp0_clearance, g2_lp2_classify) | INTERFACE_APPROACH / HOLE_BOUNDARY_APPROACH / EXTERNAL_BOUNDARY_APPROACH / PASSIVE_CONTOUR_APPROACH; no mesh, no solve |
| guide-to-every-ring gap min_i(‖tip−c_i‖ − 19.05 − 15) | ≥ 1 mm (exactly 1 mm passes) | active ring: INTERFACE_APPROACH; passive ring: PASSIVE_CONTOUR_APPROACH; no mesh, no solve |
| mesh rung 1 (0.45 mm): 34 kink-mesh gates, pairing P1–P10, phase/owner, 76 chords, T3 ≤ 40000, min angle ≥ 20°, neighbour ratio ≤ 1.8 | unchanged | TERMINAL NUMERICAL_HOLD (FAILED_MESH kept); no other spacing |
| 16 SIF gates, MTS status OK, stationarity ≤ 1e-12, K_I > 0 | unchanged | TERMINAL NUMERICAL_HOLD |
| source, policy, authorization, memory, record/ledger integrity, unexpected error | — | global HOLD (ledger), campaign stops, partial records kept, no resumption |
| S11 accepted | cap | TERMINAL CAMPAIGN_LIMIT_REACHED (S12 candidate labelled information only) |

## 5. Execution protocol after a GO

1. Verify independently (`scripts/g2/lp2a3/lp2a3_hashcheck.py`) the contract-evidence SHA-256, policy, four source digests, 20 parent pins, 24 qualification records and token at the approved head; verify the 723 protected records (`lp2a3_protected.py`); confirm the GO file, run root and ledger root are absent.
2. Activation commit: add ONLY `matlab/g2/lp2a3/G2_LP2A3_GO.json` directly on the approved head; verify HEAD~1 and the sole changed file independently (also through cmd.exe).
3. Immediately before MATLAB starts: `scripts/g2/lp2a2/lp2a2_eq_prestart_check.ps1` at its default (≥ 8.2 GiB available, no MATLAB process, removable backup drive). One MATLAB R2023a/PDE process; normal preflight (5 GiB guard unchanged); `g2_lp2a2_eq_memgate` ≥ 7 GiB inside MATLAB before each admission and again before each solve; no automatic retry.
4. Run once `g2_lp2a3_external_run(approvedHead, tok, outDir)` with a fresh outDir outside the worktree: parent/changed-file check, fresh roots, context, token, memory gate, then `g2_lp2a3_run('Run',true)` per case in the fixed order; a global HOLD stops the campaign; afterwards `g2_lp2a3_verify` with terminals required.
5. Whatever the outcome: independent read-only verification of the complete accepted prefix, terminals and ledger (not only pass labels); protected records before/after; archive on two physical devices; revoke the GO in a separate commit and show the refusal afterwards.
6. Known limitation: the one-attempt guard is the local ledger and state folders; deleting them or using an independent clone would defeat it and is excluded by protocol.
