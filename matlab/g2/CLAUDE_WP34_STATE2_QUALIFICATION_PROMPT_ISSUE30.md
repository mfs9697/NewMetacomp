# Claude Code execution prompt — WP3.4: qualify the Cornell numerical trajectory controller

> This is a **ready-to-paste execution prompt** and companion to [Issue #30](https://github.com/mfs9697/NewMetacomp/issues/30). It contains **instructions, not performed simulations**. Read Issue #30 in full; its detailed verification matrix controls the work.

---

You are the **fracture-mechanics numerical investigator and MATLAB R2023a developer** for `mfs9697/NewMetacomp`.

**Mission:** Execute [Issue #30](https://github.com/mfs9697/NewMetacomp/issues/30) to independently qualify the port of the final `EdgeCrackHoleLEFM` restartable numerical crack-trajectory algorithm. This implementation is in **draft PR #29**, branch `research/g2-bounded-trajectory-workflow-20261118`, head **`49daa2ef13ada4e693563f860cb7705a0a90422c`**, stacked on the genuine R2023a-qualified WP3 first-kink/SIF/restart **draft PR #27**. The final upstream algorithm is pinned at `mfs9697/EdgeCrackHoleLEFM@a14d8872ab588ac551e41b4531bffee2dcd0ce2c`.

**Scope and conditional numerical authorization:** Audit the complete v1 controller, verify its algebraic and integrity controls and read-only preflight, then—**only after all those pass in actual MATLAB R2023a**—execute **at most one additional idealized 4-mm numerical trial**, from accepted State 1 to State 2. The v1 policy itself caps `maxStateIndex=2` and `maxArcLength_mm=33.4`. Do **not** authorize State 3, any longer autonomous campaign, physical crack onset, changes to the nominal Cornell experiment, or the WP4 LaTeX report.

**Preserve all existing work.** The original Cornell three-hole JSON and P0 MAT, genuine WP3 source outputs, six vendor p010 MATLAB files, `main`, and the heads of every existing draft PR **must remain untouched**. Your implementation/testing changes go in **one or more new draft PRs stacked on #29**. Do not merge anything. Start by fetching current PR #29 and reading its committed source, policy, `G2_NUMERICAL_TRAJECTORY_WORKFLOW.md`, upstream reference, and original WP3 state schema. Do not assume a new MATLAB run already took place: **PR #29 has only 23/23 static source checks, not a runtime numerical PASS**.

## Facts that are already verified

- The real MATLAB WP3 State 1 is the single-kink `−12.5956937016°` numerical geometry, new tip `(102.4722795671, 29.3037326185) mm`, 28,421 T3, min angle 30.127°, max neighbor longest-edge ratio 1.592, **34/34** saved-data independent topology gates and **10/10** negative corruption detections.
- The independently checked idealized signed SIFs at this first kink are `K_I=0.182585`, `K_{II}=+0.001514` MPa√m/kN; COD agrees within 0.90%; deterministic replay/restart succeeded.
- The prospective *algebraic only* second MTS angle is approximately `−0.95°` in the current tip frame. A 4-mm trial would end near `(103.40917, 33.19247) mm`. **This is not yet a computed State 2 or a physical crack-growth result.**
- Original WP3 State 1 and mesh are in `outputs/g2_wp3_state/run_20261118_185808_963/step1_a/`; the frozen, verified isolated regular P0 is in `outputs/g2_p010_isolated/run_20261118_163657_790/`. The policy pins exact eligible SHA-256 pairs. Work with the real files—not substitutes or approximations.
- The BVP remains the explicitly *idealized* Cornell pin/roller 1-N point-load model. Actual experimental load, contact conditions, fracture toughness, initiation threshold and digitized crack path are **not known**.

## Execution order — genuine STOP/GO gates

### 1. Preregister and inspect before tests
Inspect `g2_trajectory_run.m`, `g2_trajectory_record.m`, `g2_trajectory_sif_on_mesh.m`, `g2_kinked_*.m`, `g2_wp3_state_io.m`, `run_g2_trajectory.ps1` and `G2_TRAJECTORY_POLICY_v1.json`. Audit hidden assumptions that might break at a **four-vertex, two-kink polyline**, and check the upstream runner's failure/restart semantics. Record expected tests and their criteria in `WP34_QUALIFICATION_PLAN.md` **before producing new State 2 results**. Do not adjust any acceptance values to make tests pass.

### 2. Run real synthetic/integrity checks
In the real MATLAB R2023a, run:

```powershell
& "C:\Program Files\Polyspace\R2023a\bin\matlab.exe" -batch "addpath(fullfile(pwd,'matlab','g2')); T=check_g2_trajectory_controller(); assert(T.pass)"
```

Verify two-kink MTS algebra, four-vertex Cornell K1–K10, negative geometry cases, manifest tampering and no-overwrite. Extend the suite with adverse source/policy/state/mesh provenance, authorization/step/arc guard, and fake-input corruption tests **on disposable copies**. A RAM shortfall must HOLD without reducing the 5GiB physical-memory guard. Keep all authentic error logs and fix code defects separately from scientific thresholds.

### 3. Zero-write dry preflight
From the repository root, on the PR #29-based implementation branch, with **no `-Run`**:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_trajectory.ps1 `
  -SeedStepDir ".\outputs\g2_wp3_state\run_20261118_185808_963\step1_a" `
  -P0RunDir ".\outputs\g2_p010_isolated\run_20261118_163657_790"
```

Independently prove: exact original source hashes and frozen six vendor Git blobs; root state/mesh and P0 matches; free RAM ≥5GiB; signed second-turn prediction; all K1–K10; **no new mesh, no FEM, no new files or changed source/evidence bytes**. If it does not PASS, do not proceed to `-Run`.

### 4. Exactly one numerical State 2, conditional on 1–3 GO
**The assignment permits this one controlled numerical step** under the unchanged committed v1 policy, using the same PowerShell command **with `-Run`**. Do not begin if a prerequisite is HOLD. Before elasticity, independently audit the **new saved** four-vertex T3/T6 mesh: three physical holes, four boundary loops/Euler −2, exact distinct bank twins at both kink stations, 64+64 conforming seams, unchanged frozen p010 kernel and q support, positive T3/T6 Jacobians, min angle≥20°, neighbor ratio≤1.8, 34/34 independent saved-data checks, ≤40,000 T3 primary budget.

After that actual geometric PASS, solve the same idealized BVP anew (do not reuse previous displacement). Independently extract blind signed COD/sliding **before** interaction/domain EDI; verify reaction balance, residual, whole-crack normal opening, five q-contours, quadrature, energy identity and preserved WP2/WP3 EDI-vs-COD tolerances. **Record the actual signed K values only if computed.**

Save the immutable SHA-256 `REVIEW.mat` **before** the numerical State 2. Every stage has to return GO before numerical state is promoted. Any failed mesh, COD, SIF, sign, load or clearance condition means a classified **HOLD**, no child state, and **no silent fallback/retry**. Physical growth flags remain false.

### 5. Restart and fault injection
Use disposable chain copies to test interruption *after review* and *after State*; ensure an intact review can be promoted without re-solving, an accepted state can be verified without remeshing, and any altered bytes or wrong policy/parent/review/mesh SHA causes HOLD. Re-running a successful policy-v1 chain must stop at **State 2** and write no new State 3. Preserve source files and the original accepted chain.

### 6. Deliver reproducible scientific evidence
Prepare `WP34_QUALIFICATION_PLAN.md` and `WP34_STATE2_RESULTS.md`, machine-readable test results, complete but path-sanitized MATLAB R2023a logs, checksum ledger, exact branches and commit SHAs, true MATLAB plots of the two-kink regular p010 region and overall trajectory, and signed SIF convergence/comparison figures **only if actual State 2 passed**. Keep raw outputs under gitignored `outputs/`. Open/update **draft PR(s) against #29**, and post concise results and any HOLDs to [Issue #30](https://github.com/mfs9697/NewMetacomp/issues/30) and [Issue #28](https://github.com/mfs9697/NewMetacomp/issues/28).

**On completion:** Report (i) code review, (ii) genuine R2023a outcomes per gate, (iii) exact second-step numerical tip and `K_I,K_{II}` if qualified, (iv) replay/tamper/interrupt results, (v) provenance hashes, branch/PR URLs, and (vi) remaining blockers. If MATLAB is not accessible to you, do not claim PASS; prepare the scripts and give the precise PowerShell commands for the researcher to run, then diagnose their real logs.

**Non-negotiable:** no change to existing PRs, no merges, no physical propagation or Cornell experiment claims, no weakening K1–K10/20°/1.8/p010/q/SIF/RAM limits, no second-step retry after HOLD without a separately documented investigation, no State 3, no unattended growth campaign and no WP4 report under this issue.
