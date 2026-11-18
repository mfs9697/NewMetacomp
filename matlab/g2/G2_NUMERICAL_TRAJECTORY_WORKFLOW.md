# Cornell #1 — final-style bounded numerical crack-trajectory workflow (source implementation)

**STATUS (2026-11-18): CODE COMMITTED / STATICALLY INSPECTED; NEW MATLAB R2023a TRAJECTORY BATCH **NOT YET RUN**.** The independently verified WP3 first kink remains the authoritative State 1. This implementation does **not** claim a second accepted numerical tip, a physical onset, experimental trajectory or a full multi-step experiment.

## Reference: actual final EdgeCrackHoleLEFM architecture

Pinned authoritative source repository: [`EdgeCrackHoleLEFM@a14d8872ab588ac551e41b4531bffee2dcd0ce2c`](https://github.com/mfs9697/EdgeCrackHoleLEFM/tree/a14d8872ab588ac551e41b4531bffee2dcd0ce2c).

Relevant *actual source*:
- [`verification/main_pencil_full_trajectory_run.m`](https://github.com/mfs9697/EdgeCrackHoleLEFM/blob/a14d8872ab588ac551e41b4531bffee2dcd0ce2c/verification/main_pencil_full_trajectory_run.m): default dry preflight, explicit SHA-policy authorization, bounded state/arc caps, stop-on-HOLD, review-first restart, no re-solve of accepted states;
- [`src/trajectory/edge_pencil_numerical_candidate.m`](https://github.com/mfs9697/EdgeCrackHoleLEFM/blob/a14d8872ab588ac551e41b4531bffee2dcd0ce2c/src/trajectory/edge_pencil_numerical_candidate.m): signed last-segment MTS with no physical acceptance;
- [`src/trajectory/edge_pencil_numerical_checkpoint.m`](https://github.com/mfs9697/EdgeCrackHoleLEFM/blob/a14d8872ab588ac551e41b4531bffee2dcd0ce2c/src/trajectory/edge_pencil_numerical_checkpoint.m): immutable SHA-256 review/state ancestry, no overwrite, recovery from interrupted review;
- [`docs/PRE_CONSECUTIVE_TRAJECTORY_RESTART_CONTRACT_2026-10-30.md`](https://github.com/mfs9697/EdgeCrackHoleLEFM/blob/a14d8872ab588ac551e41b4531bffee2dcd0ce2c/docs/PRE_CONSECUTIVE_TRAJECTORY_RESTART_CONTRACT_2026-10-30.md): numerical continuation is **not** physically accepted fracture propagation; accepts new numerical State only after verified review; no reuse of previous-step U;
- [`docs/PRE_NUMERICAL_TRAJECTORY_RESTART_REPORT_2026-10-31.md`](https://github.com/mfs9697/EdgeCrackHoleLEFM/blob/a14d8872ab588ac551e41b4531bffee2dcd0ce2c/docs/PRE_NUMERICAL_TRAJECTORY_RESTART_REPORT_2026-10-31.md): H0–H4 bounded numerical multi-step evidence and deterministic checkpoint replay, not a general physical fracture history.

**Do NOT transplant:** two-hole nominal geometry, H0–H4 sample K/path values, x-monotone assumptions, two-hole load/anchors, old `MinKinkTangentDot=.98`, physical acceptance flags, Hgrad fallback schedule, COD windows or 50mm initial crack. Cornell uses a vertical bottom-edge 25.4mm starter, three true circles, pin/roller idealized point-load BVP and a separate Cornell-specific ten-gate K1–K10 geometric admission.

## Existing real MATLAB predecessor, unmodified

- [WP3 draft PR #26](https://github.com/mfs9697/NewMetacomp/pull/26), head `99c476f3e344a5db75edec7df90b78318beca824`: first −12.5957° 4mm kink, family A 28,421 T3, min angle 30.127°, max adjacent-longest-edge ratio 1.592, 34/34 independent kink audit, all 10 corruptions caught.
- [WP3 draft PR #27](https://github.com/mfs9697/NewMetacomp/pull/27), head `ebe6235e93bd8abc008c351032aa01b4acfe8178`: real kinked tip idealized signed `K_I=0.182585`, `K_{II}=+0.001514` MPa√m per kN, independent COD within 0.90%, positive numerical replay/restart; next MTS approximately −0.95° forecast **only**.
- The accepted State 1 saved by original WP3.3 contains `state/state.mat`, `state/state.sha256` and `KINKED_GEOMETRY_ONLY_candidate.mat`. Exact WP3 SHA variants (`step1_a`, `step1_b`) are pinned **as pairs** in the new policy; an arbitrary reproduced but different SHA is intentionally held until its provenance is reviewed.
- The P0 isolated source MAT SHA is pinned to the exact accepted `15201996b4165aa9980f61f370a75749b1ce28ec0accaa061902641524c37c58`. Never substitute another p010 MAT with the same nominal size without new qualification.

## New code and purpose

| File | Function |
|---|---|
| `G2_TRAJECTORY_POLICY_v1.json` | Immutable prospective **numerical-only** contract: source/evidence hashes, geometry and SIF thresholds, first step cap = **State 2**, maximum arc length = **33.4mm**, no automatic retry |
| `g2_kink_admissibility.m` | Strengthened K1 so **all appended segments** have the agreed 4mm length; its previous 3-vertex default unchanged |
| `g2_kinked_regular_block.m` / `g2_kinked_exterior_mesh.m` | Opt-in `ExpectedVertices` for a general polyline, original default 3; 2,788-T3 source kernel, 128-T3 collar, 64-sector rim, 3 holes and internal size-guide faces unchanged |
| `g2_kinked_join.m` | Opt-in variable vertex count; checks two distinct crack-bank identities at **every internal kink vertex**, not only the first one |
| `g2_kinked_mesh_auditor.m` | Still independent of mesher; opt-in expected vertices, checks **every 4mm increment**, multiple kink vertices, T3/T6/q/seams and 3 physical holes; original 34-gate straight-one-kink signature unchanged by default |
| `g2_trajectory_sif_on_mesh.m` | One **NEW** idealized elastic solve for each saved new mesh; independent blind COD/slip **before** 5-contour signed EDI; energy, residual and force balance; full-crack normal opening screen; mandatory KII sign agreement above mixity 1%, diagnostic for smaller mixity |
| `g2_trajectory_record.m` | Atomic, nonoverwriting SHA-256-manifested ROOT / REVIEW / HOLD files |
| `g2_trajectory_run.m` | Final-style bounded controller: dry preflight, source-hash verification, numerical authorization, MTS forecast, K1–K10, new mesh, independent kink audit, new physical FEM, blind COD→signed EDI, **REVIEW then numerical State**, restart and no-solve reuse, caps and HOLDs |
| `run_g2_trajectory.ps1` | Windows MATLAB R2023a batch launcher: ≥5GiB physical RAM guard, original JSON sha, six frozen p010 vendor blob checks; `-Run` required to perform mesh/FEM |
| `check_g2_trajectory_controller.m` | Synthetic two-kink MTS, K1–K10, corrupted-geometry, record checksum and no-overwrite regression; **not a substitute for actual T6/elastic runtime** |

### Main scientific sequence

```text
Existing genuine WP3 numerical State 1, SHA+mesh verified
  -> dry-only source + chain audit (no file changes)
  -> bounded MTS next-direction forecast from full-precision signed K
  -> K1–K10 for the complete four-vertex polyline (no global physical onset)
  -> rebuild the entire Cornell three-hole PDE exterior and protected p010 tip
  -> preserve 64+64 seams and separate banks through BOTH kink stations
  -> save new T3/T6 arrays; independently audit saved data (34 gates)
  -> solve NEW 1-N idealized T6 BVP, never reuse previous U
  -> independent blind COD first; EDI on five q-annuli second
  -> energy/reactions/contours/full-face opening/conditional KII sign gates
  -> save immutable REVIEW_002.mat + SHA manifest
  -> only on full pass, save numerical State 2 (SHA-linked to parent/review)
  -> stop at the versioned STEP_CAP (v1 max state = 2)
```

**HOLD never creates a child State.** An aborted REVIEW is read and revalidated, then may be promoted to a State with NO new FEM. A completed State is read and revalidated without remeshing/re-solving. If interrupted after producing an unreviewed MAT, preserve that incomplete folder and STOP rather than silently overwrite. `SimulateInterrupt=struct('point','review'|'state','step',2)` is available for explicit replay tests.

## Local commands (PowerShell from root of NewMetacomp)

First switch to this new implementation branch and check the **read-only** preflight:

```powershell
git fetch origin
git switch research/g2-bounded-trajectory-workflow-20261118
git pull --ff-only

powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_trajectory.ps1 `
 -SeedStepDir ".\outputs\g2_wp3_state\run_20261118_185808_963\step1_a" `
 -P0RunDir ".\outputs\g2_p010_isolated\run_20261118_163657_790"
```

This should produce `G2_TRAJECTORY_DRY_NO_MESH_NO_FEM_NO_FILES=1` if all source/analytical prerequisites pass. No new numerical State is created in this command.

**Only if the dry preflight passes and the investigator authorizes the bounded numerical second step**, re-run **the same command with `-Run`**:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_trajectory.ps1 `
 -SeedStepDir ".\outputs\g2_wp3_state\run_20261118_185808_963\step1_a" `
 -P0RunDir ".\outputs\g2_p010_isolated\run_20261118_163657_790" `
 -Run
```

The PowerShell launcher computes the actual SHA of the checked-out versioned policy and supplies a policy-bound authorization to MATLAB. The first policy allows exactly the source State 1 and at most **one new numerical step** (State 2), preserving source originals. No further trajectory steps are authorized by this policy, even if the second step succeeds.

**Output:** `outputs/g2_trajectory_chain_v1/ROOT.mat[.manifest.json]`, `STEP_002/KINKED_GEOMETRY_ONLY_candidate.mat`, `STEP_002/REVIEW.mat[.manifest.json]`, `STEP_002/state/state.mat[.sha256]`, `STEP_002/HOLD.mat[.manifest.json]` **only on HOLD**, plus timestamped RUN console logs.

## GO/HOLD boundary and next research qualification

All new MATLAB runs (including the synthetic test) are **RUN PENDING**, not PASS. The source code was built via GitHub and verified by static analysis, with no MATLAB runtime in the execution environment. The first trial may expose new limitations of the native PDE mesher, the hole guide partition, new normal-opening gate, or multiple-kink lip pairing. **Preserve actual failures; do not weaken K1–K10, the 20°/1.8 quality limits, p010 identity, q containment or SIF criteria.**

After actual State 2 and independent restart tests pass, start a **separate policy version** for a longer multi-step Cornell numerical campaign, with explicit max-step/arc caps and new SHA identity. Before a paper or physical crack-growth claim, independently study tip-size convergence, `\Delta a`/mesh sensitivity, real Cornell loading/contact/toughness and digitized experimental path. A geometric intersection with a true hole is an event/stop, not automatically an energetic arrest.
