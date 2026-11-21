# G2-M4.B-R1 run log (Issue #50)

All runs used genuine MATLAB R2023a with the PDE Toolbox, one MATLAB process at a time, and the ≥ 5 GiB guard. That guard is applied in two places: by the launcher before MATLAB starts, and by the controller inside MATLAB. It was never lowered.

Evidence is in `evidence/m4b_r1_20261121/`. Raw records are in the gitignored `outputs/`, hashed in `SHA256SUMS_original_outputs.txt` (264 files).

| # | Commit | Run | Outcome | Notes |
|---|---|---|---|---|
| 0 | `ece7469` (PR #49) | read-only probe | matched | S2alt polyline, tangent and tip are bitwise equal to the original S2; core/collar/q 2788/128/2443 equal. No solve, no files. |
| 1 | `1e1b206` | — | policy | `G2_M4B_R1_POLICY_v1.json` (SHA-256 `51578049…d629`) and the preregistration committed **before any R1 solve**. |
| 2 | uncommitted code | dry preflight `r1_dry1` | **HOLD_MEMORY** (environmental) | 4.90 GiB free inside MATLAB, below the guard. The memory was held by other open applications. Nothing was written. |
| 3 | uncommitted code | dry preflight `r1_dry2` | **HOLD_MEMORY** (environmental) | 4.79 GiB. Nothing was written. |
| 4 | uncommitted code | dry preflight `r1_dry3` | **DRY_OK** | Free memory had recovered to 8.2 GiB without any change to code or guard. **B0:** matched geometry, pins, ledgers. **B1:** audit 34/34; legacy map, verifier and negatives; oracle = annulusOf (112-gon); 10/10 activations; 10/10 mutations. |
| 5 | `44a6b75` | `outputs/g2_m4b_r1_s2alt_v1/run_20261121_232938_287` | **GO** | 12 solves (10 cases + 2 legacy controls). B2 bitwise vs M2 S2alt. 7/7 targets pass every gate. |
| 6 | `44a6b75` | `analysis_run_20261121_233100_443` | **GO** | The self-test reproduces the M4.B ledger (maximum deviation 0). The anchors reproduce the M2 S2alt table. **Verdict: R1_PLACEMENT_STABLE.** |
| 7 | `7017b81` | `outputs/g2_m4b_r1_faults_v1/fault_20261121_233135_765` | **43/43** | Includes the matched-geometry negatives, interrupt/resume without FEM, a bit-identical replay of 10 records and 2 controls, and accepted runs unchanged. |
| 8 | uncommitted at run time | `outputs/g2_m4b_r1_report/run_20261121_233519_014` | superseded | Two defects in the stress figure: the bottom note overlapped an axis label, and contour clutter appeared across the crack slit. |
| 9 | `4c464a6` | `outputs/g2_m4b_r1_report/run_20261121_233703_904` | final figures | Notes moved into the layout x-label; a 0.75 mm crack band is masked in the contour grid. All 8 figures were inspected. |
| 10 | Python | Word proposal, render 1 | superseded | 9 pages. The page review found the drift sentence computed from G only (0.07 %, not 0.08 %) and a missing `f_i` subscript. |
| 11 | Python | Word proposal, render 2 | final | DOCX SHA-256 `42a56800…6814`. All 9 pages inspected; renders in `reports/G2/proposals/render_check_r1/`. |

**The two HOLD_MEMORY stops** were environmental and happened before any solve. They were retried with identical code and guard after memory freed. This does not count as a result-driven retry.

**There was no other HOLD.**

## Reproduction

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_m4b_r1.ps1 -Mode campaign          # dry
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_m4b_r1.ps1 -Mode campaign -Run     # clean tree
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_m4b_r1.ps1 -Mode analysis -RunDir <run>
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_m4b_r1.ps1 -Mode faults   -RunDir <run>
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_m4b_r1.ps1 -Mode report   -RunDir <analysis> -CampaignDir <run>
```

**Token:** `G2M4BR1RUN|51578049…d629|src=9915a958…a774|mesh=0627dd3a…3080|cases=10`.
