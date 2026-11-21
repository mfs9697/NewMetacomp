# G2-M4.B run log (Issue #47)

All runs used genuine MATLAB R2023a with the PDE Toolbox, one MATLAB process at a time, and ≥ 5 GiB free physical RAM checked at every launch. Evidence is in `evidence/m4b_20261121/`. Raw records are in the gitignored `outputs/`, hashed in `SHA256SUMS_original_outputs.txt`.

| # | Commit | Run | Outcome | Notes |
|---|---|---|---|---|
| 0 | `3b96715` | — | archive | Canonical Word v0.3 committed byte for byte (SHA-256 `49daba7e…0b40`, verified locally). |
| 1 | `c75a82b` | — | policy | `G2_M4B_POLICY_v2.json` and the preregistration committed **before any M4.B solve**. |
| 2 | (uncommitted code) | dry preflight `m4b_dry1` | **DRY_OK**, nothing written | **B0** inventory PASS. **B1:** auditor 34/34; legacy phase map, verifier and 8 negatives PASS; oracle = `annulusOf`; 15/15 activations PASS; 10/10 new negatives rejected. |
| 3 | `c11656a` | `outputs/g2_m4b_ring_factorial_v1/run_20261121_194814_009` | **GO** | 17 solves: 15 cases and 2 legacy controls. **B2** 33/33 bitwise. **B3** 12/12 cases pass every gate. |
| 4 | `de9d015` | `analysis_run_20261121_194953_501` | **GO** | Self-tests 5/5. Full-band cases equal the M2 ratio table exactly (deviation 0). |
| 5 | `de9d015` | `outputs/g2_m4b_faults_v1/fault_20261121_195051_593` | **38/38** | Includes an interrupt and resume (no FEM on reuse) and a bit-identical replay of all 15 records and both legacy controls. The accepted run was unchanged (80 files). |
| 6 | uncommitted at run time | `outputs/g2_m4b_report/run_20261121_195318_815` | superseded | In figures 2 and 3 the uncertainty note overlapped the legend. The note was moved into the legend title. |
| 7 | committed as `e2aba21` | `outputs/g2_m4b_report/run_20261121_195428_941` | final figures | All five figures were inspected visually. |
| 8 | Python (no MATLAB) | `scripts/report/build_g2_report_v0_4.py`, Word render 1 | superseded | v0.4 from verified v0.3 (38 pages). The page review found: table headers stranded at page feet, non-bold table captions, some indices without subscripts, new sources out of order. |
| 9 | Python (no MATLAB) | Word render 2 | final | v0.4 DOCX SHA-256 `c275d3fe…78f6`. All 38 pages inspected; renders in `reports/G2/render_check_v0_4/`. |

## Corrections and traps recorded during M4.B

- **Line endings (CRLF).** `git checkout` of the freshly committed policy rewrote it with CRLF (`core.autocrlf=true`), which changed its working-copy SHA from `758f4394…` to `b9435356…`. LF bytes, equal to the committed blob, were restored before any run, so the policy SHA used everywhere is `758f4394…`. Rule: do not re-checkout files whose SHA is pinned; the repository convention is LF on disk.
- **BOM.** PowerShell 5.1 `Set-Content -Encoding utf8` writes a BOM. It was removed from `g2_m4b_campaign.m` before the commit.
- **Figure glyphs.** MATLAB TeX labels need `\{ \}` around set braces. Arial lacks `∅`, so G₀ and θ₀ are used in the figures.
- **Figure layout.** The superseded report run 6 had a note overlapping the legend in figures 2 and 3 (layout only, no data change).
- **No HOLD occurred in M4.B.** There were no retries and no tolerance changes.

## Reproduction (R2023a)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_m4b.ps1 -Mode campaign                    # dry preflight
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_m4b.ps1 -Mode campaign -Run               # new run (clean tree)
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_m4b.ps1 -Mode campaign -Run -RunDir <run> # verified resume, no FEM
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_m4b.ps1 -Mode analysis -RunDir <run>
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_m4b.ps1 -Mode faults   -RunDir <run>
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_m4b.ps1 -Mode report   -RunDir <analysis> -CampaignDir <run>
```

**Token** of the accepted run:

`G2M4BRUN|758f4394…b37b|src=bc860312…a03e|mesh=9269be43…c412|cases=16|solves=15`

The launcher computes the token from the same files the controller verifies. It records intent and binds the run to the policy, source set, mesh and case cap. It is not an independent secret.
