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
| `LP2A2_PROTECTED_CHECK.json` | 541 protected files, tree `20f2d54f…`, identical to `LP2_PROTECTED_AFTER.json` of LP2-A1; 158 LP2-A1 run/ledger files unchanged | after `d3a8d8d` |
| `figures/` | Ukrainian figures LP2A2-1…8 (PNG 300 dpi + vector PDF), `scripts/g2/lp2a2/lp2a2_figures.m` | `d3a8d8d` |

Policy `matlab/g2/lp2a2/G2_LP2A2_EQ_POLICY_v1.json` (`d09f59b2…`, status `PREREGISTERED_NOT_AUTHORIZED`); LP2-A2 source digest `f9c15e01…` (14 files); shared g2 `7e568370…` and LP2 `357dfdcd…` unchanged.

Reproduction: `python -I scripts/g2/lp2a2/lp2a2_analyze.py <qualification.json> LP2A2_TEST_SET.json <out>`; `python -I scripts/g2/lp2a2/lp2a2_reconcile.py docs/research/G2_LP2A2_evidence <out>`.
