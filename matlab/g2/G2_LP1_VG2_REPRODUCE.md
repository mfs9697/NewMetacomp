# G2-LP1-VG2 — reproducing the no-FEM qualification (Windows PowerShell 5.1, MATLAB R2023a)

[Issue #62](https://github.com/mfs9697/NewMetacomp/issues/62). Nothing below creates a GO, a resume record, a mesh or a FEM solve.

## Prerequisites

Same as VG1 (`G2_LP1_VG1_REPRODUCE.md`):
- `core.autocrlf=false` clone;
- one MATLAB engine;
- ≥ 5 GiB free inside MATLAB (unchanged threshold), with an operational target of ≈ 7 GiB free in Windows;
- inputs restored by hash.

## Commands

```powershell
git clone -c core.autocrlf=false <repo> NewMetacomp_vg2_clean
cd NewMetacomp_vg2_clean
git checkout -b research/g2-lp1-vg2-campaign-go-20261122 adbc8a6ab6cfb609a052626889ca7d22e7d0c1c5
python -I scripts/g2/restore_lp1_evidence.py --historical-root <accepted worktree> --raw-archive <archive.zip> --restore
python -I scripts/g2/restore_lp1_evidence.py
git status --porcelain     # must be empty

# pure suite + mutation sensitivity (expected 138/138 and 16/16)
& 'C:\Program Files\Polyspace\R2023a\bin\matlab.exe' -batch "cd('<clone>'); addpath(fullfile(pwd,'matlab','g2'),'-begin'); T=check_g2_lp1_contract(); S=check_g2_lp1_contract_sensitivity();"

# complete guarded prephysical batch (single attempt; a HOLD is a result)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\g2\Invoke-G2LP1-PrephysicalBatch.ps1 -MatlabExe 'C:\Program Files\Polyspace\R2023a\bin\matlab.exe'

# source-set digests from Git blobs
python -I scripts/g2/vg1/vg1_source_integrity.py --commit VG1=f65d2523fe2e5e333f0c6a675deacbf217e1c5ea --commit VG2=adbc8a6ab6cfb609a052626889ca7d22e7d0c1c5 --out SOURCE_INTEGRITY.json

# pins for a future GO (profile vg2; G1 must fail only after a genuine GO exists)
python -I scripts/g2/a0/a0_pin_check.py --profile vg2 --commit <commit> --clone <clone> --archive <archive.zip> --out VG2_PIN_CHECK.json
```

| Item | Expected value |
|---|---|
| Source set | `9b634df22d2c44ba9f6465fa9c88f54274afa3a17aa5d43df1e2b2ac58b5c2b5` |
| Contract evidence SHA-256 | `1332a4fb9b2a5a1f29f0c42024021b35b633f138b887d043fbcda599b5fc314f` |
