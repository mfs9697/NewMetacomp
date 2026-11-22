# Inspect LP0/LP1 evidence with MATLAB R2023a — current scientific HOLD

The investigator's [concurrent review](https://github.com/mfs9697/NewMetacomp/pull/55#issuecomment-7079495852) requires a separately approved, committed GO before any physical Run=true. No GO exists. **Do not run or replay physical controllers, create a dummy GO, or checkout older code to bypass this HOLD.** The supplied 20-state campaign was computed with the earlier pinned source; its provenance and discrepancy are documented in [reconciliation](G2_LP1_CONCURRENT_REVIEW_RECONCILIATION.md).

Use a clean checkout with exact UTF-8/LF Git bytes (disable autocrlf before checkout). MATLAB R2023a + PDE Toolbox 3.10, one MATLAB engine and >=5 GiB free RAM are mandatory. Python 3.11+ is used by the restore helper. Existing accepted evidence is immutable.

## Restore and verify evidence without solving

The historical MATs are ignored outputs, not part of a fresh clone. Provide the investigator's accepted worktree(s) and the separately supplied local raw archive. The helper verifies hashes, refuses mismatching destinations, and copies only missing outputs after all inputs have been validated.

```powershell
python scripts/g2/restore_lp1_evidence.py --historical-root C:/Users/Mikhailo/Documents/GitHub/NewMetacomp_wt_wp3 --historical-root C:/Users/Mikhailo/Documents/GitHub/NewMetacomp --raw-archive ../outputs/NewMetacomp_G2_LP1_Raw_Records_20261122.zip --restore
python scripts/g2/restore_lp1_evidence.py
```

The second command is read-only: 689 historical source/evidence hashes, 654 historical MATs and 182 campaign files. Missing inputs mean HOLD_INPUT; do not generate substitutes with an old controller. Raw-archive SHA/member hashes are committed. Persistent raw-archive upload failed at DNS; the actual archive is local, not remotely published.

## Current no-FEM verification batch

From the repository root, with no GO file and clean source:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/g2/Invoke-G2LP1-PrephysicalBatch.ps1 -MatlabExe 'C:\Program Files\Polyspace\R2023a\bin\matlab.exe'
```

This runs preflight, 23 geometry algebra tests, four dry cases, the amended 25-test contract suite, and missing-GO refusal before any run-folder creation. It writes its own ignored evidence folder, performs zero meshing/FEM and retains scientific HOLD. It does not authorize a new calculation.

```powershell
matlab -batch "addpath('matlab/g2'); R=run_g2_lp1_preflight_faults(); assert(R.pass);"
matlab -batch "addpath('matlab/g2'); R=run_g2_lp1_evidence_audit(); assert(R.pass);"
matlab -batch "addpath('matlab/g2'); run_g2_lp1_report_batch(fullfile(pwd,'outputs','LP1_report_reproduction'));"
python scripts/g2/restore_lp1_evidence.py
```

The fault suite injects only a 2-GiB OS-memory observation, then a dirty-source sentinel; it restores its own path/file changes. No large memory allocations or physical solve occur. The independent evidence audit reads the original saved records, reconstructs actual owner geometry, checks all q supports, parent-MTS relationships, byte hashes and recorded clearance. It does not claim the historical states were produced by the current source. The report exporter reads the same saved records and requires a new output directory.

## Historical execution provenance

The archived logs record the original sequence: prospective LP0 v1 commit, geometry-only S0/N5/N6 qualification, v2/controller commit, 24-test contract suite, interrupted H S0 REVIEW and promotion, H S1/S2 regression, each candidate's independent S0–S2, then S3/S4 for all four. Full replay on that exact physical source reused all 20 states with zero solves and preserved all 182 file hashes.

The computation source is local `3dadf0d43aba0c5b2b3e8c69b90c2d42e89866f8`, identical tree to remote `60358bbafb43a58458c7b37262956d8c21102800`. The current amended source deliberately has a different token. Historical Run=true commands are not offered as a way around the current scientific gate. A prospective physical reproduction needs the investigator's new decision, exact reviewed current source/policy/evidence pins and a genuine separately committed GO. None is supplied here. Absolute S4/41.4-mm caps remain in force.

Current execution: HOLD_LP1_PHYSICAL_AUTHORIZATION. Evidence-delivery stop: REVIEW_STOP_LP1. No S5, interface fracture, CZM, optimization, full-length path or physical-arrest claim.
