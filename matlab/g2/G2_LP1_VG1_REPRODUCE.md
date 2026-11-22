# G2-LP1-VG1 — reproducing the no-FEM qualification (Windows, MATLAB R2023a)

[Issue #58](https://github.com/mfs9697/NewMetacomp/issues/58). Nothing below creates a mesh, runs a FEM solve, writes a GO record or authorizes a physical run. The scientific HOLD remains in force.

## Prerequisites

- Windows PowerShell 5.1, Git, Python ≥ 3.11 (standard library only), MATLAB R2023a with PDE Toolbox 3.10.
- **Exactly one MATLAB engine.** Check with `Get-Process MATLAB` before starting.
- **≥ 5 GiB free physical RAM** as seen *inside* MATLAB. That threshold is checked by the code and is unchanged. Operationally, start only when Windows reports about 7 GiB free, because MATLAB itself takes roughly 0.6–0.8 GiB and the batch re-checks the guard several times.
- **`core.autocrlf=false` for the clone (mandatory).** With `autocrlf=true`, the pinned JSON is checked out as CRLF and its SHA-256 changes (policy v2 `074d7edc…` becomes `50b2ee2a…`), so the preflight stops at `HOLD_POLICY_DRIFT`. The repository JSON must not be rewritten as a workaround.
- Historical MAT inputs (654) and the LP1 raw archive (182 files, SHA `5b333b03…c533`) are restored by hash only.

## 1. Clean clone of the commit under test

```powershell
cd C:\path\to\work
git clone -c core.autocrlf=false <NewMetacomp remote or local path> NewMetacomp_vg1_clean
cd NewMetacomp_vg1_clean
# Commit under test; the branch name must be one of the two accepted by the batch.
git checkout -b research/g2-lp1-vg1-guard-negatives-20261122 <commit>
python -I scripts/g2/restore_lp1_evidence.py --historical-root <accepted worktree> --raw-archive <NewMetacomp_G2_LP1_Raw_Records_20261122.zip> --restore
python -I scripts/g2/restore_lp1_evidence.py          # read-only re-verification: 689 / 654 / 182
git status --porcelain                                 # must print nothing
```

For the original PR #55 baseline, use `<commit>` = `70bf6f4baf9f4963380120964f6aaec04e65a349` with the branch name `research/g2-lp0-lp1-implementation-20261122`.

## 2. Amended pure suite and mutation sensitivity (no preflight, no FEM)

```powershell
& 'C:\Program Files\Polyspace\R2023a\bin\matlab.exe' -batch "cd('<clone>'); addpath(fullfile(pwd,'matlab','g2'),'-begin'); T=check_g2_lp1_contract(); S=check_g2_lp1_contract_sensitivity();"
```

Expected output:
- `G2_LP1_CONTRACT_TESTS=74/74 NEG=24 REC=8 GO=25 ADM=9 IFC=4`
- `G2_LP1_CONTRACT_SENSITIVITY=8/8 CLEAN_AFTER=1`

## 3. Complete guarded prephysical batch (single attempt, no automatic retry)

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\g2\Invoke-G2LP1-PrephysicalBatch.ps1 -MatlabExe 'C:\Program Files\Polyspace\R2023a\bin\matlab.exe'
```

The batch writes `outputs/g2_lp1_prephysical_batch/run_<UTC>/`, which contains:
- `PREPHYSICAL_RESULT.json` (schema v2, with RAM observations and refusal identifiers);
- `CONTRACT_TESTS.json`;
- `matlab_console.log`;
- `run_prephysical_tests.m`;
- `BATCH_MANIFEST.json` (SHA-256 of each file).

A HOLD (for example `HOLD_MEMORY`) is a genuine result: keep the folder and do not lower the threshold.

## 4. Independent source-integrity comparison

```powershell
python -I scripts/g2/vg1/vg1_source_integrity.py --commit ORIGINAL=3dadf0d43aba0c5b2b3e8c69b90c2d42e89866f8@<repo containing that commit> --commit PR55=70bf6f4baf9f4963380120964f6aaec04e65a349 --commit VG1=<commit> --out SOURCE_INTEGRITY.json
```

This recomputes the LP1 source-set digest from Git blobs exactly as `g2_lp1_context` does. The expected values are:

| Source | Digest |
|---|---|
| Original physical source | `2e5756969e456043e48f048ecc12ebf0c76980b113296eb3903c79ac172cab00` |
| PR #55 guarded source | `da8b95916823034c1afc9baeff02ec2c52949b697f81f2e43cedad15ae5de444` |
| VG1 source (`f65d252`) | `6f7fb3ea51a0ae64e30a5c63f8cc765af5308c511da315c989ae10235fbed030` |

## 5. Staging evidence for commit (path sanitization)

```powershell
python -I scripts/g2/vg1/vg1_stage_evidence.py <run folder> matlab/g2/evidence/lp1_preflight/vg1_20261122/<label> --repo-root <clone path>
```

The staging script replaces local paths with `<repo>`, `<scratch>` and `<user>`. `SANITIZATION.json` keeps the SHA-256 of each original file, which still matches the run's own manifest.
