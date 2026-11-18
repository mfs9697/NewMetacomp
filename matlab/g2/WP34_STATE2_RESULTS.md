# WP3.4 results: qualified Cornell trajectory controller and numerical State 2

Issue #30 (parent #28). Branch `research/g2-wp34-state2-qualification-20261118`,
stacked on draft PR #29 (`49daa2e`). The plan was preregistered in
`WP34_QUALIFICATION_PLAN.md` (`8eb407a`) before any WP3.4 run.

All numbers below come from genuine MATLAB R2023a runs (PDE Toolbox 3.10) on
2026-11-18. Free RAM at every MATLAB launch was 5.40–6.00 GiB (5 GiB guard,
never lowered).

**Scope.**
- The model is the idealized 1 N pin/roller BVP: plane stress, E = 3268.115 MPa, ν = 0.35, t = 12.7 mm.
- State 2 is a numerical, policy-capped state: `physicalFractureGrowthProven = false`, `tipAccepted = false`, `physical_onset = false`.
- No onset, toughness, load or experimental-path claim is made. No State 3 exists.

## Verdicts

| Stage | Verdict | Evidence (under `evidence/wp34_20261118/`) |
|---|---|---|
| A. Source/contract audit | **8 defects found (D1–D8), all fixed** | plan §1; commit `e482673` |
| B. Synthetic + fault tests | **GO** (B1–B6; 36/36 faults; SIF regression) | `controller_tests/B3_*` (exit 0) |
| C. Zero-write dry preflight | **GO** (twice: `e482673`, `384e3f1`) | `launcher/C1_*`, `launcher/C2*` |
| D. One numerical State 2 | attempt 1 **HOLD-1** (implementation defect, before any solve); attempt 2 **GO** | `launcher/D1_*`, `launcher/D2_*`, `WP34_HOLD1_INVESTIGATION.md` |
| E. Restart/interrupt/tamper/replay | **GO** (20/20) | `restart/` |

## A. Audit of PR #29 (static, before any run)

PR #29's "23/23" was a static review only. The audit found eight defects:

| ID | Defect | Fix |
|---|---|---|
| D1 | `g2_williams_field.m` and `g2_pde_toolbox_preflight.m` missing from the source lock | Both hashed (25 files in total) |
| D2 | Promotion/reuse checked mesh bytes only, not mesh content | Polyline/tangent equality plus a fresh 34/34 re-audit |
| D3 | Dry chain check skipped the MTS forecast | Exact forecast check |
| D4 | `commitBeforeRun` not enforced | `G2Chain:DirtySource` |
| D5 | Chain could lie inside an evidence folder | `G2Chain:SelfReference` |
| D6 | RAM shortfall untestable | `-SimulateFreePhysicalGiB` (can only lower) |
| D7 | State 2 inherited WP2 K provenance | Provenance replaced |
| D8 | No release check | R2023a + PDE Toolbox required |

Details are in plan §1. No threshold, policy value or gate changed. The policy SHA-256 stays
`1D6AF7F6F3E8AF389AB02330D9A1EAEBDBC00BEDB52AAD54DB902B4DE36B39DC`.

## B. Synthetic and fault qualification

**Baseline: PR #29 controller unmodified** (`B1_pr29_prefix_baseline`): **25/33**. The
failures confirm the static findings:
- F01: the lock misses 2 files.
- F20: a forged review citing the State 1 mesh **was promoted to a State 2** (disposable chain), and the dry preflight passed it.
- F21 (dry): a tip shifted 1e-6 mm was accepted.
- F22: an uncommitted kernel change went undetected.
- F23: chain/evidence overlap was not refused (3 cases).
- F30: the launcher had no safe RAM-shortfall hook (PowerShell parameter error).

One earlier attempt (`B0_FAILED_ATTEMPT_harness_make_root`) stopped on a defect in
my test harness (`make_root` returned nothing). It is preserved, and the harness
was fixed in `fbc130a`.

**After the fixes** (`B2_postfix`: 33/33). After the HOLD-1 fix (`B3_postfix_hold1_regression`):
- 36/36 faults pass;
- all originals unchanged (SHA-256 listing before and after);
- exit 0.

| Test | Result |
|---|---|
| B1 first MTS | −12.595693701643° |
| B2 second MTS (full-precision State 1 K) | **−0.949827756717°**; independent bracketed root agrees, \|Δ\| = 0 |
| B3 analytic tip 2 | (103.409150916458, 33.192469183868) mm |
| B4 four-vertex K1–K10 | 10/10 (the inherited 0.98 guard would reject: true, reported only) |
| B5 negatives | wrong count, length, tip in hole, tangent, fold: all rejected |
| B6 records | round trip; no overwrite; manifest, byte-flip and no-manifest tampering rejected |
| F02–F19, F24 | expected identifier in every case, nothing forbidden written |
| F30 / F31 (launcher) | `HOLD_RAM` at simulated 4.25 GiB / `HOLD_RAM_POLICY`; exit 1; MATLAB not started |
| SIF regression | fixed routine on the accepted State 1 mesh: K_I 0.182584879, K_II +0.001513654, ΔEDI = ΔCOD = **0**; all 9 trajectory SIF criteria pass |

## C. Read-only preflight (brief command, no `-Run`)

- **Inputs:** State 1 `CB05BD61…5D441`, mesh `ECD6A7B8…32461`, P0 `15201996…37C58`, JSON `45A88FA0…B47BF`, policy `1D6AF7F6…39DC`. All six vendor blobs pinned and clean.
- **Forecast:** θ2 −0.949827756717°, trial tip (103.409150916458, 33.192469183868) mm, K1–K10 10/10. This is a forecast, not a trajectory.
- **Zero writes:**

  | Run | Files hashed | Listing hash (before = after) |
  |---|---|---|
  | `e482673` | 849 | `25FD54C7…` |
  | `384e3f1` | 1,113 | `ABAEBA2F…` |

  No chain folder was created.

## D. State 2

### Attempt 1: HOLD-1, preserved, not reused

- **Run:** HEAD `e482673`, chain `outputs/g2_trajectory_chain_v1`.
- **Mesh:** built and audited **34/34**.
- **Stop:** in `g2_trajectory_sif_on_mesh` **before the solve**. `jsondecode` returns the policy's pin/roller/load coordinates as 2×1 columns, so the anchor lookup failed with `MATLAB:sizeDimensionsMustMatch`.
- **Record:** `HOLD.mat` `491D8FC0…D859`; no review, no State.
- **Investigation, fix and regression:** `WP34_HOLD1_INVESTIGATION.md` (fix `21f91d6`), committed (`384e3f1`) before attempt 2.

### Attempt 2: GO

- **Run:** HEAD `384e3f1`, chain `outputs/g2_trajectory_chain_v1_attempt2`, 15 s, exit 0, `STEP_CAP`.
- **Determinism:** the rebuilt mesh equals the HOLD-1 mesh in all 22 saved fields.

**Geometry.**

| Quantity | Value |
|---|---|
| Polyline | (101.6, 0) → (101.6, 25.4) → (102.4722795671, 29.3037326185) → **(103.4091509165, 33.1924691839)** mm |
| Turns | −12.5956937016°, −0.9498277567° |
| Tip-2 tangent | (0.234217837, 0.972184141) |
| Arc length | 33.4 mm (= policy cap) |

**Mesh.**

| Quantity | Value |
|---|---|
| Vendor kernel / block / join gates | 15/15 / 12/12 / 13/13 |
| T3 elements | **28,625** (core 2,788 + collar 128 + exterior 25,709); budget 40,000 |
| Nodes | 14,767 T3, 58,161 T6 |
| Min angle | **30.126847°** (kernel) |
| Max neighbour ratio | **1.591829** |
| Min T6 Jacobian | 1.504e−3 mm² |
| Topology | Euler −2, 4 boundary loops, holes 152/152/152 edges |
| Seams | 64 + 64 |
| Banks | 92 edges / 185 T6 nodes per side, one node per bank at both kinks |
| Lips | 65 pairs, station mismatch 1.68e−3 mm |
| Kernel vs P0 local coordinates | 2.58e−14 mm |
| q | 2,443 active parents; support 2.7692 mm (< 3cos(π/64)); 1.234 mm clear of the nearest kink |
| Area | material 102,845.678 vs analytic 102,845.569 mm² |
| Independent audit of the saved MAT | **34/34** |

**Signed SIF** (idealized BVP, MPa√m per kN; blind COD computed before EDI):

| | EDI 6×6, annulus 0.4–2.6 mm | Blind bank COD | State 1 (WP3.2) |
|---|---|---|---|
| K_I | **0.195982362** | 0.194259931 | 0.182585 |
| K_II | **+0.003149970** | +0.003101658 | +0.001514 |

| Criterion (v1, unchanged) | Value | Limit |
|---|---|---|
| relative residual | 1.01e−12 | ≤ 1e−8 |
| statics (max) | 2.73e−13 | ≤ 1e−8 |
| COD vs EDI | 0.879 % of \|K\| | ≤ 3 % |
| contour spread (5 annuli) | 1.64e−6 | ≤ 0.5 % |
| J energy identity | 1.51e−5 | ≤ 0.5 % |
| 4×4 vs 6×6 quadrature | 3.7e−13 | ≤ 0.1 % |
| whole-crack normal opening, min | 0 mm (shared tip node) | ≥ −1e−9 mm |
| K_II/K_I | 0.0161, so the sign gate is **enforced**; EDI and COD signs agree (+) | — |

The SIF varies by less than 1e−6 relative across the five q annuli
(0.4–2.6, 0.2–1.0, 0.4–1.6, 0.8–2.6 and 1.2–2.4 mm). See
`state2_report/state2_summary.json` and `state2_K_vs_annulus.png`.

**Identities.**

| Record | SHA-256 |
|---|---|
| ROOT record | `fa24bc43…14edb` |
| REVIEW | `e5ad2c17…78055` (written before the State) |
| State 2 | `4603095b…ee2e6` |
| mesh | `9269be43…5c412` |
| parent (State 1) | `cb05bd61…5d441` |
| git HEAD | `384e3f1` (recorded in ROOT, review and State) |

The next MTS forecast, −1.8407°, is **not executed**.

**Figures** (`state2_report/`):
- `state2_full_mesh.png`
- `state2_two_kink_zoom.png/.pdf` (both kinks, seams, q support)
- `state2_trajectory.png` (equal scale, nearby holes)
- `state2_K_vs_annulus.png`

## E. Restart, interruption, tamper, replay (20/20; accepted chain and seed unchanged)

| ID | Case | Outcome |
|---|---|---|
| E1 | fresh chain, interrupt after review | `SimulatedInterrupt`, REVIEW present, no State (5.0 s) |
| E2 | resume E1 | review promoted, **no mesh/FEM** (`reviewsReused = 1`), STEP_CAP (0.5 s) |
| E3 | fresh chain, interrupt after State, rerun | State reused, no mesh/FEM (`statesReused = 1`), STEP_CAP (2.8 s / 0.4 s) |
| E4 | replay | E1 and E3 mesh arrays, banks, K and all EDI annuli **bit-identical** to the accepted chain. The `.mat` bytes differ (MATLAB v7.3 stores write timestamps), which is why identity is checked on arrays and every file is hashed |
| E5 | rerun of accepted-chain copy | STEP_CAP, no `STEP_003`, only a new RUN log, old files unchanged |
| E5b | `MaxStateIndex 3` | `G2Chain:StepCap` |
| E6 | State byte flip / wrong `state.sha256` | `ChildStateIntegrity` (Run), `ChildIntegrity` (dry) |
| E7 | review missing | `ChildReviewIntegrity` / `ReviewIntegrity` |
| E8 | review byte flip | `ChildReviewIntegrity` |
| E9 | mesh byte flip | `ReviewMeshSHA` |
| E10 | forged parent (re-hashed State) | `ChildMismatch` |
| E11 | ROOT source or policy drift (re-manifested) | `SourceDrift` (Run and dry) |
| E13 | State without `state.sha256` | `ChildStateIntegrity` |
| E12 | dry on the accepted chain | `DRY_PREFLIGHT_STEP_CAP`, zero writes |

## Reproduction (PowerShell, repository root, R2023a)

```powershell
& "C:\Program Files\Polyspace\R2023a\bin\matlab.exe" -batch "addpath(fullfile(pwd,'matlab','g2'));addpath(fullfile(pwd,'matlab','g2','vendor_p010_a14d8872'));run_g2_wp34_controller_tests_batch('rerun')"
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_trajectory.ps1 -SeedStepDir ".\outputs\g2_wp3_state\run_20261118_185808_963\step1_a" -P0RunDir ".\outputs\g2_p010_isolated\run_20261118_163657_790" -ChainDir ".\outputs\g2_trajectory_chain_v1_attempt2"
& "C:\Program Files\Polyspace\R2023a\bin\matlab.exe" -batch "addpath(fullfile(pwd,'matlab','g2'));addpath(fullfile(pwd,'matlab','g2','vendor_p010_a14d8872'));run_g2_wp34_restart_batch(fullfile(pwd,'outputs','g2_trajectory_chain_v1_attempt2'))"
```

The second command is the read-only dry check of the accepted chain (expected
`DRY_PREFLIGHT_STEP_CAP`). The P0 run folder was copied byte-identically
(7/7 files) from the WP1 worktree into this worktree's `outputs/`.
`SHA256SUMS_original_outputs.txt` hashes every raw WP3.4 output (999 files).

## Limitations

- The first State 2 attempt failed on an implementation defect found only by execution. That chain is preserved unchanged and is refused for reuse; the accepted chain is attempt 2.
- The 5 GiB guard is pre-launch only.
- The 4×4/6×6 quadrature agreement (3.7e−13) shows the EDI integrand is integrated exactly at both orders on this mesh. It does not measure discretization error.
- No tip-size, Δa or mesh-family convergence was run for State 2 (no refined family B at this step).
- The path is a numerical MTS recurrence on the idealized BVP. It is not the Cornell experimental path. Hole proximity says nothing about arrest or a growth threshold.
- State 3, longer campaigns and WP4 need a new, separately versioned policy and authorization.
