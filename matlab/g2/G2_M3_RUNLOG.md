# G2-M3 run log (Issue #39)

All runs used genuine MATLAB R2023a, with ≥ 5 GiB free RAM at every launch. Raw outputs are in `outputs/g2_material_trajectories_v1/` and `outputs/g2_m3_report/`.

| # | Mode | HEAD | Outcome |
|---|---|---|---|
| 1 | dry soft + dry stiff | `c5af00d` | **HOLD at H-REC** (read-only control), no files written; see amendment A1 |
| 2 | dry soft + dry stiff | `6c929fc` | same HOLD: the amendment text was committed, but my scripted code edit had aborted, so the code was unchanged; no files written |
| 3 | dry soft + dry stiff | `923b6b8` | PASS: H-REC exact; S0 recompute bitwise; step-1 forecasts soft −11.9488616952°, stiff −13.0203114434°; no files written |
| 4 | Run soft | `923b6b8` | **GO**: `chain_soft_v1`, STEP_CAP at state 2 |
| 5 | Run stiff | `923b6b8` | **GO**: `chain_stiff_v1`, STEP_CAP at state 2 |
| 6 | analysis | `4719fd0` | **GO**: `analysis_run_20261121_142837_725` (both chains re-verified read-only; alternative M2 meshes ROBUST) |
| 7 | faults | `4719fd0` | **20/20 PASS**: `faults_run_20261121_142937_205`; accepted chains unchanged |
| 8 | report | `4719fd0` | crash in the figure code (`jsondecode` returns column struct arrays); no evidence affected |
| 9 | report | `db63954` | done: `outputs/g2_m3_report/run_20261121_143202_547` |

**Source lock.** Runs 6–9 came after commits that added only the analysis, faults and report batches; none of these is in the controller's hashed source list. Every reuse re-verifies each ROOT's `sourceHashes` against the current files. That check passed in runs 6 and 7, so the chains and the controller sources are unchanged since runs 4–5.

**Amendment A1 (H-REC):** see `G2_M3_PREREGISTRATION.md`. The homogeneous S1 was seeded from the six-digit WP3 K. This is a control definition only; no threshold changed.
