# WP3.4 HOLD-1 investigation: first State 2 attempt

Issue #30. This record is required by the brief ("no second-step retry after HOLD
without a separately documented investigation"). It was written and committed
**before** any second attempt.

## Event

- **Command:** the brief's `-Run` command, unchanged.
- **Commit:** HEAD `e48267325c80bbc60debb0dd90d7252153bdd3a4`, clean tree.
- **Free RAM:** 5.77 GiB at launch.
- **When:** 2026-11-18 22:37:07–22:37:12 (16 s).

Before stopping, the controller completed:

| Stage | Result |
|---|---|
| Signed MTS forecast | θ2 = −0.9498277567°, K1–K10 10/10, arc 33.4 mm ≤ 33.4 mm |
| Rotated p010 vendor kernel | 15/15 |
| Regular block | 12/12 (min angle 30.126847°, ratio 1.591829, q 2,443) |
| Exterior | 25,709 native T3, 65 rim nodes |
| Join | 13/13 → 28,625 T3, 58,161 T6 nodes, min angle 30.126847°, max ratio 1.591829 |
| Saved MAT | written, then independently audited **34/34** with `expectedVertices = 4` |

It then stopped in `g2_trajectory_sif_on_mesh` line 18, **before the elasticity
solve**. The HOLD record (`STEP_002/HOLD.mat`, SHA-256
`491D8FC0B52AB262AC7B063A4FD00204CB2F81AF58DB3E8955ED1141FB15D859`) gives:
- identifier: `MATLAB:sizeDimensionsMustMatch`
- classification: `SOURCE`
- message: "Arrays have incompatible sizes for this operation."
- location: `nodeAt=@(xy)D.extraVertexNodes(vecnorm(D.extraVertexXY-xy,2,2)<1e-9)` called with `policy.bvp.pin_mm`

No review and no State were written.

The failed chain `outputs/g2_trajectory_chain_v1` is preserved unchanged:
- `ROOT.mat` + manifest;
- `RUN_20261118_223707_946.log`;
- `STEP_002/HOLD.mat` + manifest;
- `STEP_002/KINKED_GEOMETRY_ONLY_candidate.mat` (1,644,155 bytes).

The controller refuses to reuse that chain, and it is never overwritten. The
preregistered expectation was `HOLD_PARTIAL_STEP` (dry) and `G2Chain:PartialStep`
(`-Run`), as in fault F15. In the event, the dry preflight on commit `384e3f1`
stopped one check earlier with `G2Chain:SourceDrift`: the chain ROOT pins the
`e482673` kernel hashes and `g2_trajectory_sif_on_mesh.m` has since changed.
That refusal is stricter, and nothing was written (log
`evidence/wp34_20261118/launcher/C2b_dry_preflight_384e3f1_hold1_chain.log`).

## Root cause

An implementation defect in PR #29, not a numerical or mesh failure.
- `jsondecode` turns the policy's JSON arrays (`"pin_mm": [25.4, 0]`, and likewise `roller_mm` and `load_mm`) into **2×1 columns**.
- The anchor lookup subtracts that column from the 3×2 `extraVertexXY` array.
- The WP3.2 helper this was derived from (`g2_wp3_sif_on_mesh`) used literal row vectors, so the defect was new in PR #29. It was never executed before, because PR #29 had only static checks.

The remaining policy array uses take scalar elements (`(1)`), so they are unaffected.

## Fix and regression evidence

- **Fix:** the lookup compares `reshape(xy,1,2)` (commit `21f91d6`). No threshold, window, annulus, mesh control or policy value changed. The policy SHA-256 is still `1D6AF7F6…39DC`.
- **Regression test:** `check_g2_trajectory_sif_regression`. It decodes the policy exactly as the controller does (and asserts that the 2×1 trigger shape is present), then runs the fixed routine on the **accepted, hash-checked WP3 State 1 mesh**. It reproduced the recorded State 1 values **bit-identically**:

  | Quantity | Value |
  |---|---|
  | K_I | 0.182584879 |
  | K_II | +0.001513654 MPa√m/kN |
  | ΔEDI | 0 |
  | ΔCOD | 0 |
  | Trajectory SIF criteria | all 9 pass |

  Run: `outputs/g2_wp34_controller/run_20261118_223951_893_postfix_hold1`, R2023a exit 0.
- **Code that follows the SIF** (review, State, reuse) had never run either. Fault F24 exercised it first, on a disposable chain with **synthetic** K and a copy of the HOLD-1 mesh:
  - re-audit 34/34;
  - promotion (`reviewsReused = 1`);
  - State 2 provenance (D7);
  - State reuse (`statesReused = 1`);
  - dry `DRY_PREFLIGHT_STEP_CAP`.

  The whole suite passed 36/36, with all originals unchanged.

## Decision

The HOLD is resolved: the cause is identified, and both the fix and the
regression test ran in genuine MATLAB R2023a. The first attempt produced no
displacement field and no K, so no numerical State 2 trial has been carried
out yet.

One further attempt is made under the unchanged v1 policy, into a **new**
chain folder `outputs/g2_trajectory_chain_v1_attempt2`, only after:
- stage B passes on commit `21f91d6` or later;
- the stage C zero-write preflight is repeated on that commit, because a PASS on `e482673` does not carry over to changed sources.

The second attempt's mesh must match the HOLD-1 mesh arrays (deterministic
rebuild). This is checked afterwards and reported. If the second attempt
HOLDs, the work stops without a further retry.
