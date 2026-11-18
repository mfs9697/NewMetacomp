# G2 material contrast: run log and HOLD investigations (Issue #33)

Every formal run writes a new `outputs/g2_material_contrast_v1/run_<time>/`. Failed runs are kept unchanged.

## Pre-run checks

**Checkpoint integrity test (PR #32 controller, dry):**
- Command: `run_g2_trajectory.ps1 … -ChainDir .\outputs\g2_trajectory_chain_v1_attempt2`
- Result: `DRY_PREFLIGHT_STEP_CAP`, States verified through 2, re-audit 34/34, `G2_TRAJECTORY_DRY_NO_MESH_NO_FEM_NO_FILES=1`.
- The 8 chain files are byte-identical before and after.

## Run A: `run_20261119_003303_004`, HEAD `66f25d3`, HOLD (harness)

- **Stage:** S0 SOURCE, the first statement after the folder was created. Nothing was computed; only the console log, `LEDGER.json` and `SHA256SUMS.txt` were written.
- **Message:** `G2Material:Release: MATLAB 2023a is not R2023a.`
- **Cause:** `version('-release')` returns `'2023a'`, but the policy stores `"R2023a"`. The check compared the two strings literally. MATLAB itself was R2023a (launcher path `R2023a\bin\matlab.exe`).
- **Fix:** record and compare `['R',version('-release')]`. No gate, tolerance, policy value or numerical code changed.
- **Retry:** the next run goes to a new folder after this note is committed.
