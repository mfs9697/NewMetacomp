# VG2 evidence (Issue #62), 22 November 2026: no FEM, no mesh, no GO

| Folder / file | Content | Outcome |
|---|---|---|
| `B_pure_suite_adbc8a6/` | Amended pure suite and mutation sensitivity on a clean LF clone of `adbc8a6` (18:07:24–18:07:53 UTC) | 138/138; 16/16 mutations detected |
| `D_development_runs_uncommitted_worktree/` | Development runs before the code commit (not qualification evidence) | 138/138; 16/16 |
| `E_batch_adbc8a6/` | Complete guarded prephysical batch on the clean clone, VG2 branch (18:08:04–18:08:47 UTC; RAM 6.727 → 6.365 GiB inside MATLAB) | `TESTS_PASS_SCIENTIFIC_HOLD`: 23/23, 4 dry cases, 138/138, two refusals including the correct current token; run root and ledger unchanged |
| `E_batch_adbc8a6/CONTRACT_TESTS.json` | Contract evidence for a future GO | SHA-256 `1332a4fb9b2a5a1f29f0c42024021b35b633f138b887d043fbcda599b5fc314f` (equal to the batch manifest) |
| `F_comparator_selftest_vg2/` | A0 comparator selftest on the original 20 states with VG2-pinned provenance | `A0_REPRODUCED_EXACT`, 12/12 |
| `SOURCE_INTEGRITY.json` | Source-set digests from Git blobs: original `2e575696…`, PR #55 `da8b9591…`, VG1/A0-P0 `6f7fb3ea…`, **VG2 `9b634df2…`** | policies, lock, LP0 evidence and raw ledger unchanged |
| `VG2_PIN_CHECK.json` | `a0_pin_check.py --profile vg2`, including clean-clone readiness and the raw archive | 21/21 |
| `A0P0_PROFILE_AT_VG2_HEAD.json` | Historical A0-P0 profile evaluated at the VG2 head | 13/15: fails exactly the source-set and token checks (expected; `6f7fb3ea…` is historical) |
| `TEST_TABLE.md` | All 138 tests with expected and observed identifiers, plus the 16 mutation checks | — |

`HOLD_ARCHIVE_BACKUP`: the raw archive `5b333b03…` exists only on drive C: (original plus a read-only copy). An off-device copy is required before any A0 execution.

Local paths are replaced by placeholders; each `SANITIZATION.json` keeps the original SHA-256 values.
