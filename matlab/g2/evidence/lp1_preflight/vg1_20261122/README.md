# VG1 evidence (Issue #58), 22 November 2026: no FEM, no mesh, no GO

| Folder / file | Content | Outcome |
|---|---|---|
| `A_original_batch_70bf6f4/` | Unmodified PR #55 batch on a clean LF clone of `70bf6f4` (16:22:55–16:23:32 UTC; 6.839 GiB before launch, 6.145 GiB inside MATLAB) | `TESTS_PASS_SCIENTIFIC_HOLD`: 23/23 clearance, 4 dry cases, 25/25 original contract tests, refusal `G2LP1:HOLD_UNAUTHORIZED_STATE` |
| `B_amended_pure_suite_f65d252/` | Amended pure suite and mutation sensitivity on a clean LF clone of `f65d252` (16:34:45–16:34:59 UTC) | 74/74 contract tests, 8/8 mutations detected |
| `C_original_suite_mutation_comparison/` | The same sabotage set applied to the original 25-test suite at `70bf6f4` (scratch harness, temporary copies only) | 0/8 detected (7 applied; admission order not present) |
| `D_development_runs_uncommitted_worktree/` | Development runs before the code commit (CRLF worktree; not qualification evidence) | 74/74, 8/8 |
| `RAM_WAIT_BEFORE_E.log` | Polling of free RAM before the corrected batch, waiting for the ≈ 7 GiB operational margin (the threshold is unchanged at 5 GiB) | ready at 8.035 GiB |
| `E_corrected_batch_f65d252/` | Corrected batch on a clean LF clone of `f65d252` with the VG1 branch (16:45:52–16:46:30 UTC); RAM observations 7.343 → 6.955 GiB inside MATLAB | `TESTS_PASS_SCIENTIFIC_HOLD`: 23/23, 4 dry cases, 74/74, two refusals (invalid token and correct current token) |
| `SOURCE_INTEGRITY.json` | Source-set digests recomputed from Git blobs (`vg1_source_integrity.py`): original `2e575696…`, PR #55 `da8b9591…`, VG1 `6f7fb3ea…`; changed/added files; pinned-file hashes | policies, lock, LP0 evidence and raw ledger unchanged |
| `TEST_TABLE.md` | All 74 tests with expected and observed identifiers, plus the 8 mutation checks | — |

**Earlier failure, preserved unchanged.** `../concurrent_review_20261122/` holds the earlier `HOLD_MEMORY` at 4.958122 GiB.

**Path sanitization.** Local paths are replaced by `<repo>`, `<scratch>` and `<user>`. Each `SANITIZATION.json` keeps the SHA-256 of the original bytes, which match the run's own `BATCH_MANIFEST.json`. The raw runs remain in the ignored `outputs/` of the two clean clones.
