# WP3.4 qualification plan: Cornell trajectory controller and numerical State 2

Issue #30 (parent #28). Preregistered **before** any WP3.4 MATLAB execution and before
any State 2 numbers exist. Baseline: draft PR #29, head
`49daa2ef13ada4e693563f860cb7705a0a90422c`, stacked on PR #27 (`ebe6235`). This
plan is committed on branch `research/g2-wp34-state2-qualification-20261118`
before the controller code is changed or run.

Nothing in this plan changes a numerical threshold. The v1 policy
`G2_TRAJECTORY_POLICY_v1.json` is **not edited** (its SHA-256 is part of the
authorization), and the 20° / 1.8 / 40,000-T3 / 34-gate / 2,443-q / 5 GiB /
SIF tolerances stay as they are. The model stays the idealized 1 N pin/roller
BVP: no physical onset, no toughness, no experimental path.

## 0. Fixed inputs (verified by SHA-256 before this plan was written)

| Input | Location (repository-relative) | SHA-256 |
|---|---|---|
| WP3 State 1 (`step1_a`) | `outputs/g2_wp3_state/run_20261118_185808_963/step1_a/state/state.mat` | `cb05bd61…5d441` |
| WP3 State 1 mesh | `…/step1_a/KINKED_GEOMETRY_ONLY_candidate.mat` | `ecd6a7b8…32461` |
| Replay twin (`step1_b`) | `…/step1_b/state/state.mat`, mesh | `ca70f324…88c49`, `118e6b0e…922eb` |
| P0 isolated kernel | `outputs/g2_p010_isolated/run_20261118_163657_790/P010_ISOLATED_REGULAR_ONLY.mat` | `15201996…37c58` |
| Cornell nominal JSON | `docs/research/crack-growth-gaps-2026/G2_SPECIMEN1_1990_GEOMETRY.json` | `45A88FA0…B47BF` |

All five match `G2_TRAJECTORY_POLICY_v1.json` and
`evidence/wp3_20261118/SHA256SUMS_original_outputs.txt`. The P0 run folder
lives in the WP1 worktree. A byte-identical copy (7/7 files, equal SHA-256) is
placed under this worktree's gitignored `outputs/` so that the brief's relative
commands work unchanged. The original is not touched.

## 1. Static audit of PR #29 (done before this plan; no MATLAB)

Defects found. Each gets a code fix and its own regression test; none changes a
threshold.

| ID | Defect | Consequence | Fix | Regression test |
|---|---|---|---|---|
| D1 | Source lock omits `g2_williams_field.m` (auxiliary field of the interaction integral, called by `g2_sif_interaction`) and `g2_pde_toolbox_preflight.m` (called by the exterior mesher) | An edit to the EDI auxiliary field would change K without `SourceDrift` | Add both to the hashed list; expose the list as `R.sourceHashes` | F01: every `g2_*` file reached statically from `g2_trajectory_run.m` is in the lock |
| D2 | Review promotion and State reuse check only the mesh **bytes** against the review's own SHA; they never check that the mesh **content** is the reviewed four-vertex geometry, and never re-audit it | A review that cites another valid mesh (for example the WP3 State 1 mesh) with consistent-looking SIF fields is promoted to State 2 without FEM | On every promotion and reuse, load the saved mesh and require: its polyline and tangent equal the review's (exact); a fresh **34/34** independent audit (`g2_kinked_mesh_auditor`, geometry only, no FEM); equal T3 count, min angle and ratio | F20: forged review citing the State 1 mesh. Run **before** the fix to record the defect, then after it |
| D3 | The read-only chain check (dry preflight) does not recompute the MTS tip from the parent K; only the `-Run` reuse path does | A consistent review with a different tip would pass the dry preflight | `local_verify_review` recomputes the forecast from the parent and requires exact equality | F21: review with a 1e-6 mm tip shift |
| D4 | The policy says `commitBeforeRun: true`, but nothing enforces it (upstream: `PencilMarch:DirtySource`) | A State could come from uncommitted, unreproducible kernel code | Before `-Run` writes anything: `git status --porcelain` must be empty for `matlab/g2` and the Cornell JSON folder (untracked `.m` files included). Record HEAD in the root and review | F22: disposable git copy with a modified kernel file must HOLD before any write |
| D5 | The chain folder may lie inside the seed or P0 evidence folder | `-Run` would write into original evidence | HOLD `G2Chain:SelfReference` if the chain is inside, or equal to, the seed or P0 folder, or vice versa | F23 |
| D6 | The RAM guard can only be tested by exhausting memory | No safe shortfall test | Launcher `-SimulateFreePhysicalGiB x` uses `min(measured, x)`. It can only **lower** the value, so it can only cause a HOLD. `MinFreeGiB < 5` still throws | F30/F31: 4.25 GiB gives HOLD_RAM, MATLAB not started |
| D7 | The child State inherits stale WP2 provenance from State 1 (`Ksource` names PR #23 family A; `KI/KII_fullPrecisionWP2`) | State 2 would carry misleading K provenance | Overwrite `Ksource` with the State 2 review identity; drop the WP2-only fields | E-test on the genuine State 2 and on F20 |
| D8 | No MATLAB release / PDE Toolbox check in the controller | A different release could make a State | HOLD `G2Chain:MatlabRelease` unless release 2023a and PDE Toolbox present | F24 (identifier and stop path reviewed; cannot run a second release here) |

Reviewed and found sound (no change):
- dry default and the authorization order (token, policy SHA and cap are checked before `mkdir`);
- STEP_CAP: `MaxStateIndex` in [2, 2], and the loop bound is the policy;
- ARC_CAP: 25.4 + 4 + 4 = 33.4 mm, so the cap is reached exactly at State 2;
- review is written before State;
- a HOLD writes `HOLD.mat` and no State;
- a partial step folder is never retried;
- the interrupt hook is rethrown, not swallowed;
- signed MTS in the last-segment frame (t, n = R(+90°)t);
- full-mesh rebuild through `g2_kinked_join` with `ExpectedVertices = 4`;
- the auditor generalizes to N vertices (per-segment twins, one node per bank at every kink, q clearance from every kink);
- the exterior mitres every interior vertex;
- the vendor builder uses the last prior segment's direction for any prior polyline;
- blind COD is computed before EDI with the same windows and annuli as WP3.2.

Known limitation kept as is: the 5 GiB guard is a **pre-launch** check, as in
WP2/WP3. An in-MATLAB check would see MATLAB's own footprint and is not added,
since that would effectively change the guard.

## 2. Stage B — synthetic and integrity tests (MATLAB R2023a, no PDE/FEM)

`check_g2_trajectory_controller.m` (extended). Pass requires every item:

| ID | Test | Criterion |
|---|---|---|
| B1 | First MTS from the preregistered WP2 K (0.166436, 0.018827) | θ1 = −12.5956937016° ± 1e-9° |
| B2 | Second MTS from the **full-precision** K of the real State 1 (loaded through the hash-checked state reader) | `g2_mts_direction` and an independent root of KI sin θ + KII(3cos θ − 1) = 0 (bracketed `fzero`, hoop-stress maximum check) agree within 1e-10°; θ2 < 0 |
| B3 | Analytic tip 2 = tip1 + 4(cos θ2 t1 + sin θ2 n1) | Equal to the controller's forecast to 1e-12 mm; reported, not compared to a target |
| B4 | Four-vertex K1–K10 | all ten true; `inheritedGuardWouldReject` reported |
| B5 | Negative polylines | wrong vertex count, wrong last length (+0.04 mm), tip in hole 1, wrong expected tangent, self-crossing: each rejected with the named gate |
| B6 | Record I/O | round trip; no overwrite; manifest SHA tamper, MAT byte flip, missing manifest: each read returns `pass = false` |

`check_g2_trajectory_faults.m` (new). Each case runs the controller on **disposable copies** in a temporary folder. All `Run = true` cases also pass `ForbidNewComputation = true`, so no case can mesh or solve. Pass requires the expected identifier or stage **and** no file or folder written where the case forbids it. Expected outcomes:

| ID | Corruption | Expected |
|---|---|---|
| F01 | source-lock closure (D1) | all statically reached `g2_*` files are hashed |
| F02 | dry preflight, true inputs, absent chain | `DRY_PREFLIGHT_PASS`, chain not created |
| F03 | authorization absent / wrong token / wrong policy SHA / `maxStateIndex` 3 | `G2Chain:AuthorizationRequired`, chain not created |
| F04 | `MaxStateIndex` 3 (step cap) | `G2Chain:StepCap` before any read |
| F05 | seed state byte flip (copy) | `G2Chain:RootIntegrity` |
| F06 | seed mesh byte flip (copy) | `G2Chain:RootMeshIntegrity` |
| F07 | self-consistent forged State 1 (re-hashed) | `G2Chain:TrustedWP3Root` |
| F08 | `step1_a` state with the `step1_b` mesh | `G2Chain:RootMeshIntegrity` |
| F09 | P0 byte flip (copy) | `G2Chain:TrustedP0` |
| F10 | shadowing `T3toT6_fast.m` first on the path | `G2Chain:VendorShadowed` |
| F11 | missing vendor file (code copy) | `G2Chain:MissingVendor` |
| F12 | chain ROOT with a stale source hash | `G2Chain:SourceDrift` (dry and Run) |
| F13 | chain ROOT bytes flipped | `G2Chain:RootRecordIntegrity` |
| F14 | chain folder without ROOT manifest | `G2Chain:PartialChain` (Run) |
| F15 | partial `STEP_002` (folder, no review) | dry `HOLD_PARTIAL_STEP`; Run `G2Chain:PartialStep`; nothing written |
| F16 | seed is a State 0 / wrong identity | `G2Chain:RootIdentity` |
| F17 | ARC_CAP (code copy whose policy has `maxArcLength_mm = 33.0`, own SHA) | `ARC_CAP`, `pass = true`, no `STEP_002` |
| F18 | Run with valid authorization and `ForbidNewComputation` | `HOLD_NEW_COMPUTATION_FORBIDDEN`, no `STEP_002` |
| F19 | review with a fabricated `pass = true` but COD/EDI 10 % apart | `G2Chain:ReviewNumericScreens`, no State |
| F20 | forged review citing the State 1 mesh (D2) | **pre-fix outcome recorded**; post-fix `G2Chain:ReviewMeshContent`, no State |
| F21 | review tip shifted 1e-6 mm (D3) | `G2Chain:ForecastDrift` in dry and Run |
| F22 | dirty kernel in a disposable git copy (D4) | `G2Chain:DirtySource`, chain not created |
| F23 | chain inside the seed copy (D5) | `G2Chain:SelfReference`, nothing created |
| F30 | launcher `-SimulateFreePhysicalGiB 4.25` | `HOLD_RAM`, exit ≠ 0, MATLAB not launched |
| F31 | launcher `-MinFreeGiB 4.25` | `HOLD_RAM_POLICY` |

Stop rule: a failing case is preserved (log + JSON), diagnosed and fixed in code
with the case as its regression test. Then the suite reruns. `PASS` is reported
only from a genuine R2023a exit 0.

## 3. Stage C — read-only preflight (the brief's command, no `-Run`)

Pass requires all of:
- launcher exit 0 with `DRY_PREFLIGHT_PASS`;
- vendor blobs pinned and clean;
- policy, JSON, State 1, mesh and P0 SHA-256 equal to section 0;
- free RAM ≥ 5 GiB;
- signed θ2 and tip 2 printed and equal to B2/B3;
- K1–K10 all true.

**Zero writes**: a SHA-256 listing of every file under the worktree, including
`outputs/` and evidence (`.git` excluded), is taken before and after. The two
listings must be identical: no new file, no changed byte, and
`outputs/g2_trajectory_chain_v1` absent. The forecast is reported as a forecast,
not a trajectory.

## 4. Stage D — exactly one numerical State 2 (only if B and C pass)

The brief's command with `-Run`, once. The controller gates, in order:
- MTS status OK;
- K1–K10 on the forecast;
- arc 33.4 ≤ 33.4 mm;
- full rebuild through `g2_kinked_join` (13 join gates; vendor 15/15; block 12/12; 4 vertices);
- save, then a **34/34** independent audit of the **saved** MAT with `expectedVertices = 4`.

The auditor groups cover:
- 3 holes, 4 loops, Euler −2;
- positive T3 areas and T6 Jacobians;
- angle ≥ 20°, ratio ≤ 1.8;
- 64 + 64 seams;
- one node per bank at both kinks;
- P0 kernel identity;
- 2,443 q parents;
- K1–K10 recomputed independently.

Native T3 ≤ 40,000. Then a new elasticity solve and:
- blind bank COD;
- five-annulus EDI;
- 4×4 versus 6×6 quadrature.

The criteria are the existing `g2_trajectory_sif_on_mesh` and v1 values:

| Check | Limit |
|---|---|
| Residual and statics | ≤ 1e-8 |
| COD vs EDI | ≤ 3 % of \|K\| |
| Path spread | ≤ 0.5 % |
| J identity | ≤ 0.5 % |
| Quadrature drift | ≤ 0.1 % |
| q support | inside 3 cos(π/64) |
| Whole-crack normal opening | ≥ −1e-9 mm |
| K_I | > 0 |
| K_II sign agreement | enforced when \|K_II/K_I\| > 0.01 |

Review is written before State 2. Any HOLD → `HOLD.mat`, no State, no retry,
no threshold change; the investigation is reported. STEP_CAP stops the run.

Reported: tip 2, θ2, mesh statistics, signed K_I, K_II (EDI) and COD, all
criteria values, and a q-annulus table. Figures (only if State 2 passes):
- full mesh;
- two-kink local zoom with seams and q;
- trajectory;
- K versus annulus.

## 5. Stage E — restart, interruption, tamper and replay

Only on disposable chains or copies; the accepted chain is never written.

| ID | Test | Criterion |
|---|---|---|
| E1 | fresh disposable chain, `SimulateInterrupt = review@2` | interrupt raised after `REVIEW.mat`; no State |
| E2 | resume E1 | State 2 promoted with **no mesh/FEM** (`reviewsReused = 1`); review re-audit 34/34 |
| E3 | fresh chain, `SimulateInterrupt = state@2`, then rerun | rerun reuses State 2 (`statesReused = 1`), no mesh/FEM, STEP_CAP |
| E4 | deterministic replay | E1/E3 mesh arrays and banks `isequal` to the accepted chain; K_I, K_II bit-identical; timestamps recorded |
| E5 | accepted-chain copy: rerun with Run | `STEP_CAP`, no State 3, no new file except the run log |
| E6 | copy: State byte flip / wrong `state.sha256` | `G2Chain:ChildStateIntegrity` (Run) / `G2Chain:ChildIntegrity` (dry) |
| E7 | copy: review missing, State kept | HOLD (`ChildReviewIntegrity`) |
| E8 | copy: review byte flip | HOLD |
| E9 | copy: mesh byte flip | `G2Chain:ReviewMeshSHA` |
| E10 | copy: State 2 re-parented (forged parent hash, re-hashed State) | `G2Chain:ChildMismatch` |
| E11 | policy or source drift (ROOT source hash edited and re-manifested) | `G2Chain:SourceDrift` |
| E12 | dry preflight on the accepted chain | `DRY_PREFLIGHT_STEP_CAP`, zero writes |

E1 and E3 each repeat one mesh + FEM on a disposable chain (needed to exercise
the real interrupt hook and for replay). No other test solves.

## 6. Stop rules

- Any unresolved HOLD in B or C → no `-Run`.
- A HOLD in D → stop, preserve, report; no second attempt under this issue.
- Never State 3.
- Never copy a PASS onto a changed mesh.
- Never weaken a gate.
