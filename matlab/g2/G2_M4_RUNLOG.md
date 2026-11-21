# G2-M4 run log (Issue #44): M4.0 and M4.A

All runs used genuine MATLAB R2023a (PDE Toolbox 3.10), one process at a time, with ≥ 5 GiB of free RAM at every launch.

Raw outputs are in three gitignored folders:
- `outputs/g2_m4_feasibility/`
- `outputs/g2_m4_alt_family_v1/`
- `outputs/g2_m4_report/`

Sanitized copies are in `evidence/m4_20261121/`.

| # | Mode | HEAD | Outcome |
|---|---|---|---|
| 1 | M4.0 feasibility (mesh only) | `a06fc5b` | **False HOLD** in F0. My ledger lookup compared the lower-cased M3 ledger with a mixed-case path (`ROOT.mat`). No mesh was built; only the log and JSON were written (`run_20261121_172707_829`). |
| 2 | Diagnostic `-batch` expression | `a06fc5b` | Reproduced the lookup: the hash is present but the mixed-case key is absent. No files. |
| 3 | M4.0 feasibility | `b84dea3` | **FEASIBLE** (`run_20261121_172817_429`). F0 source lock PASS; F1 famA rebuild bitwise; F2 alternative S0: 34,641 T3, join 13/13, 38/38, 24/24, phase OK, 3×112 chords. |
| 4 | S0ALT dry | `70d0769` | PASS, no files. |
| 5 | S0ALT `-Run` | `70d0769` | S0ALT written: record `b02e7202…`, mesh `ce2f5eae…`. |
| 6–8 | Dry: homogeneous, soft, stiff | `70d0769` | PASS: own alternative-S0 K, step-1 forecasts, M0 identity bitwise. No files. |
| 9–11 | `-Run`: homogeneous, soft, stiff | `70d0769` | **STEP_CAP** at state 2 for all three chains. |
| 12 | Analysis | `a66cdca` | **GO** (`analysis_run_20261121_174528_727`). Original-family regression 0; verdict **FULL_PATH_ROBUST**. |
| 13 | Faults | `a66cdca` | **24/24** (`faults_run_20261121_174621_414`). Accepted PR #41, S0ALT and alternative chains unchanged. |
| 14 | Report | `a66cdca` | Superseded figure layout: overlapping legends and titles, a missing ∇ glyph, decimal points (`run_20261121_174934_833`). |
| 15 | Report | `c55a0b2` | Superseded: overlapping end labels in Fig. 1c (`run_20261121_175159_466`). |
| 16 | Report | `edfcaba` | Final figures (`run_20261121_175248_649`). |

**Source lock.** Commits after `70d0769` added only:
- the analysis, faults and report batches;
- the labels JSON;
- the Word builder.

None of these is in `g2_m4a_sources`. Runs 12 and 13 re-verified every chain's ROOT `sourceHashes` against the current files, and both passed.

**Word.** The canonical report v0.2/v0.3 is not on disk; only v0.1 is present (SHA-256 `85ef072b…bc3`, verified). This is logged as **HOLD_WORD_INPUT**.

The proposal DOCX is built by `scripts/report/build_g2m4a_proposal_docx.py` from the evidence folder. It was rendered through Word to PDF and then to 8 page PNGs, all inspected.
- A first render showed English table text, underscore notation, a wrapped equation label and theme fonts.
- I fixed the builder and rendered again; the second render passed.
