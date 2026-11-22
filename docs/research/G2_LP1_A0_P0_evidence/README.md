# A0-P0 evidence (Issue #60): read-only, no FEM, no mesh, no GO

| File | Content | Result |
|---|---|---|
| `A0_P0_PIN_CHECK.json` | `scripts/g2/a0/a0_pin_check.py` at commit `7cced5a`: source set, policies, lock, LP0, token, contract evidence (bytes, validator predicates, manifest equality), absent GO, run name; execution-clone checks on the clean `f65d252` clone (autocrlf, clean, no run folder, 182 records, 654 inputs); raw archive | **21/21**; contract SHA-256 `78b6897f…15be` |
| `comparator_selftest_and_determinism/A0_COMPARATOR_SELFTEST.json` | `a0_compare_records(hist, hist, …, 'selftest')`: historical-vs-historical comparison and 12 in-memory perturbations | `A0_REPRODUCED_EXACT`, 12/12; S4 classes equal SR1 |
| `comparator_selftest_and_determinism/determinism.log` | LP1 H S0 solution vs the M2 `CASE_S0_H1` record (another controller and session) | K_I, K_II, J, EDI_all and the full u vector **bitwise equal** |
| `SOURCE_SET_F65D252_VS_7CCED5A.json` | `vg1_source_integrity.py` | source set `6f7fb3ea…` at both commits; no source-set file changed |

**Archive backup.** A read-only copy of the raw archive was placed outside every repository, at `<user>/Documents/NewMetacomp_LP1_archive_backup/`. Its SHA-256 `5b333b03…` was verified. It is on the **same physical drive**, so an off-device copy is still required (protocol P4).

Paths are sanitized (`<repo>`, `<scratch>`, `<user>`, `<a0-worktree>`). `SANITIZATION.json` keeps the original hashes.
