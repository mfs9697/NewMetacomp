# G2-LP2-A2 evidence (paired crack-bank meshing, geometry only)

Memorandum: [`../G2_LP2A2_MESH_QUALIFICATION_MEMO_UA.md`](../G2_LP2A2_MESH_QUALIFICATION_MEMO_UA.md). GO template (not a GO): [`../G2_LP2A2_EQ_GO_DECISION_TEMPLATE.md`](../G2_LP2A2_EQ_GO_DECISION_TEMPLATE.md).

**Zero physical FEM solves, zero accepted states, no GO file.** All runs were made in the LF execution clone at the commit printed in each log. Absolute local paths are sanitized (`SANITIZATION.json` in each folder).

| Path | Content | Source commit |
|---|---|---|
| `LP2A2_TEST_SET.json`, `lp2a2_testset_build.m/.log` | Predeclared set: 127 rows (A 4, B 4, C1 82, C2 29, C3 8; 10 guard rows), SHA `7d2b6d35…`, committed before any evaluation | `338ccab` → committed `9a2442b` |
| `attempt1/` | Attempt 1 (`g2_lp2a2_join`, spacing 0.45 mm): qualification JSON, summary, wrapper and log. HOLD: 107/117, 2 regressions | `9a2442b` |
| `attempt2/LP2A2_SPACING_EXPLORATION.json` | Spacing exploration on 46 polylines disjoint from the test set × 4 spacings (184 meshes) | `7e2b858` |
| `attempt2/LP2A2_MESH_QUALIFICATION_ATTEMPT2.json`, `LP2A2_SUMMARY_ATTEMPT2.json` | Attempt 2 (`g2_lp2a2_mesh`, ladder 0.45/0.40/0.50/0.35 fixed in `7a1ca24`): 112/117, no regression, per-geometry ladder records | `7e2b858` |
| `attempt2/lp2a2_batch2.m/.log` | Same batch; includes the failed EQ-test attempt (E1 only, `g2_lp2_forecast` not on the path) | `7e2b858` |
| `supplement/LP2A2_SUPPLEMENT.json` | Determinism re-mesh 117/117, forced-pair audit on 113 meshes, per-rung + inherited-mesher diagnostics of the 5 remaining rows. Its `predictedDx_mm` field carries the opposite sign (corrected in `52d94ef`; magnitudes agree to 1.7e-9 mm) | `7481509` |
| `supplement/LP2A2_RECONCILIATION.json` | Populations, paired outcome tables, regressions/resolutions, ladder usage, remaining-failure table, forced-pair maxima (`scripts/g2/lp2a2/lp2a2_reconcile.py`) | read-only |
| `eq/LP2A2_EQ_TESTS.json`, `lp2a2_batch4.m/.log` | EQ contract tests 24/24 (E1–E6), refusal without GO, four dry calls at rung 1. An intermediate attempt at `7481509` stopped at the unchanged 5 GiB preflight (4.86 GiB free); no test ran | `1200dde` |
| `eq/LP2A2_HS8_RUNG_CHECK.json` | H S8 meshed at 0.45/0.40/0.50/0.35 mm: all pass every audit (input to the proposed supplementary experiment) | `1200dde` |
| `supplement/ERRATUM_FORCED_PAIR_SIGNED_TERM.md` | Appended erratum: sign of `predictedDx_mm` in `LP2A2_SUPPLEMENT.json`; station vs coordinate residual; no universal pairing guarantee | review closeout |
| `independent/LP2A2_INDEPENDENT_SET.json`, `lp2a2_indep_build.*` | Eight S11 polylines (±1° from each S9 predictor), frozen before meshing, SHA `ab7096d0…`; all admissible, clearance 1.716–2.818 mm | `13fc23e` → committed `7a96184` |
| `independent/LP2A2_INDEPENDENT_QUALIFICATION.json`, `lp2a2_indep_qual.*` | 8/8 pass every audit at rung 1; inherited mesher 2/8 | `7a96184` |
| `eq/v2_attempt1_vendor_path/` | Failed v2 suite run (60/64: E6 dry calls without the vendor folder first on the path), preserved | `bf9cb8a` |
| `eq/v2/LP2A2_EQ_TESTS_v2.json`, `lp2a2_eqtests_v2.*` | Contract suite v2 64/64 (E1–E11), SHA `84f518a6…`; v1 kept as history in `eq/` | `7282530` |
| `eq/v2/LP2A2_EQ_HASHCHECK_v2.json` | Independent Python recomputation of the pins, the 20 archived hashes, the token and the evidence SHA (`scripts/g2/lp2a2/lp2a2_eq_hashcheck.py`) | read-only |
| `eq/v2/LP2A2_PROTECTED_CHECK_v2.json` | 541 protected files, tree `20f2d54f…`, unchanged after the closeout | after `7282530` |
| `LP2A2_PROTECTED_CHECK.json` | 541 protected files, tree `20f2d54f…`, identical to `LP2_PROTECTED_AFTER.json` of LP2-A1; 158 LP2-A1 run/ledger files unchanged | after `d3a8d8d` |
| `figures/` | Ukrainian figures LP2A2-1…8 (PNG 300 dpi + vector PDF), `scripts/g2/lp2a2/lp2a2_figures.m` | `d3a8d8d` |
| `eq_campaign/` | WP5 attempt `G2-LP2A2-EQ-001` under `GO_LP2A2_EQ` (PR #71 comment 7167996437): pre-activation checks, GO `91667cf`, dry validation, revocation `91718b0`, archive, post-revocation refusal. **HOLD before the first call** (`HOLD_LP2A2_EQ_ACTIVATION_BINDING_WINDOWS_CARET`: unquoted `git rev-parse HEAD^` is mangled by `cmd.exe`); 0 solves, no records. Report `../G2_LP2A2_EQ_DEMONSTRATION_REPORT_UA.md` | `4d3701e` (approved), GO `91667cf`, revocation `91718b0` |

| `eq/v3/` | Windows activation correction (review 6063184270): contract suite v3 **80/80** = the 64 earlier tests + 16 real-git tests E12 through MATLAB R2023a `system()` → cmd.exe → git on inert disposable fixtures (valid activation, wrong parent, non-ancestor, extra changed file, git failure ×2, caret defect reproduced, unsafe arguments refused); commands, exit statuses, outputs and fixture SHAs in `LP2A2_EQ_TESTS_v3.json` → `realGit`; SHA `75057751…`. Independent hashcheck 13/13, 699 protected records unchanged, pre-start check (≥ 8.2 GiB) exercised in pass and refuse modes | `0809c67` |
Current pins (after the Windows activation correction, activation attempt A2 prepared): policy `matlab/g2/lp2a2/G2_LP2A2_EQ_POLICY_v1.json` `6f2c290b…` (status `PREREGISTERED_NOT_AUTHORIZED`), LP2-A2 source digest `f1d7e4d6…` (21 files), shared g2 `7e568370…` and LP2 `357dfdcd…` unchanged, contract evidence `eq/v3/LP2A2_EQ_TESTS_v3.json` `75057751…`. History: `bc1f86e7…`/`00c99e93…` with v2 evidence `84f518a6…` (64/64; used by activation attempt A1, whose authorization is consumed); `d09f59b2…`/`f9c15e01…` with v1 evidence 24/24.

Reproduction: `python -I scripts/g2/lp2a2/lp2a2_analyze.py <qualification.json> LP2A2_TEST_SET.json <out>`; `python -I scripts/g2/lp2a2/lp2a2_reconcile.py docs/research/G2_LP2A2_evidence <out>`.
