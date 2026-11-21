# Claude Code execution prompt — G2-M3 independently evolved two-phase crack paths

> **Issue:** [#39](https://github.com/mfs9697/NewMetacomp/issues/39). **Status:** assignment, not executed simulation. Issue #39 is the authoritative, full scientific and fault-injection specification. Follow it in full.

You are the senior fracture-mechanics / MATLAB R2023a investigator for `mfs9697/NewMetacomp`.

**Mission:** Determine whether material-induced crack steering **reinforces or counters the direct elastic shielding/amplification** when the soft and stiff two-phase crack paths are *independently calculated*. Implement a bounded **two-increment** numerical experiment using the already qualified p010/Cornell mesh-and-signed-SIF engine. This is the first material-specific trajectory study; it is not physical crack onset, not a new general convergence exercise, and not an automatic multi-step campaign.

## Scientific and repository baseline

Work from actual head of [draft PR #38](https://github.com/mfs9697/NewMetacomp/pull/38), currently `49ec4fc6867c5be70e18f9c6b79db708190e3aa9`, branch `research/g2-m2-shielding-steering-20261121`. All previous PRs #8–#38 are draft/unmerged and immutable. Create a **NEW separate implementation branch** and draft PR(s) **stacked directly on PR #38**, without changing PR #38, `main` or any accepted State, mesh, evidence, source or earlier policy.

Before any numerical attempt inspect:
- `matlab/g2/G2_M2_SHIELDING_STEERING_RESULTS.md`, `G2_M2_POLICY_v1.json`, `G2_M2_SHIELDING_STEERING_PREREGISTRATION.md`, and original SHA-256 evidence `matlab/g2/evidence/m2_20261121/SHA256SUMS_original_outputs.txt`; accepted three-state material run `outputs/g2_material_evolution_v1/run_20261121_132226_301`.
- `matlab/g2/g2_trajectory_run.m` from the qualified homogeneous controller (PR #32), including review-before-state, source locks, dry preflight, corrupted child refusal, and finite state cap. Its existing policy v1 is fixed at homogeneous State 2; **do not modify it or reuse its chain to march the material**.
- `g2_kinked_join.m`, `g2_kinked_mesh_auditor.m`, `g2_kink_admissibility.m`, `g2_mts_direction.m` (qualified three-hole re-meshing, 34/34 saved T6 audit and signed MTS).
- `g2_material_phase_map.m`, `g2_material_phase_verify.m`, `g2_t6_elasticity_phase.m`, `g2_material_sif_on_mesh.m`, `check_g2_m2_phase_controls.m` (perfectly bonded T6 phase FEM, independent analytical benchmark and full matrix-only q verification).
- Primary true-void nominal Cornell JSON and `EdgeCrackHoleLEFM@a14d8872ab588ac551e41b4531bffee2dcd0ce2c` algorithm, for provenance rather than transplanting a two-hole mesh or the old 0.98 tangent guard.

**Already verified, but on frozen HOMOGENEOUS crack shapes:** `s=25.4,29.4,33.4mm`, common 3×76-chord perfectly bonded bands, `R_soft=0.99391,1.00620,1.02181`; `R_stiff=0.99096,0.98187,0.97069`. The local MTS shifts from the homogeneous reference were approximately +0.65 to +0.74° for soft, −0.42 to −0.49° for stiff. S2 one-mesh alternate polygon/exterior test gave 0.067–0.068% of effect drift. **The previous study never computed a material-specific trajectory.**

## Implement only the following two-step experiment

- **Start:** original saved straight-crack State 0, exact `(101.6,0)→(101.6,25.4)mm`, accepted WP2 mesh SHA `05d5c3fcf5152c30bb0e5c288dc109bfce42b8d677077c4631254ab5887657dc`. Verify source and parent H1=M0, Msoft and Mstiff actual State 0 SIFs from original PR #38 records, do not seed material parent K from homogeneous values.
- **Material path A:** bonded bands `E_r/E_m=0.5`, `ν=0.35` in both phases.
- **Material path B:** bonded bands `E_r/E_m=2`, `ν=0.35` in both phases.
- **Fixed illustrative BVP:** plane stress `E_m=3268.115MPa`, thickness 12.7mm, three real void holes `R=6.35mm`, annular outer guide boundary radius `19.05mm`, 1N downward top point at (254,203.2)mm, pin (25.4,0)mm and roller (482.6,0)mm. No constitutive fitting, plasticity, interface decohesion or experimental Cornell load claim.
- **Numerical steps:** **exactly Δa=4mm**, material-specific `M1` ends at arc 29.4mm, independently recompute and then `M2` ends at 33.4mm. Their geometry is NOT forced to equal homogeneous S1/S2. No State 3.
- **Three paths for comparison:** H = existing homogeneous S0/S1/S2 (source locked/read-only), soft and stiff freshly rebuilt at each step. The fact the two contrasts use the same three holes and material-band geometry is an explicit control.

### Stage A — preregister new policy before new numbers

Commit `G2_M3_PREREGISTRATION.md` and `G2_M3_TRAJECTORY_POLICY_v1.json` **before executing the first material MTS numerical increment**. Derive and freeze source SHAs, exact original source seeds, separate chain IDs per material, authorized 2-step/33.4mm caps, clean source/≥5GiB RAM/R2023a/PDE Toolbox/40k T3 gates, independent test and failure matrix, local MTS sign conventions, K1–K10, mesh/phase/q/FEM/SIF gates and ratio/path-resolution uncertainty criteria. The old homogeneous trajectory/material policies remain untouched. New authorization must bind **policy SHA + material ID + max step**; default must be read-only.

Source-lock all qualifying PR #38 modules, material phase solver, review/checkpoint logic, and the versioned policy. Verify source and full-precision S0 signed K from accepted MATLAB MAT; quoted approximate original first directions **H−12.596°, soft−11.949°, stiff−13.020°** are preflight sanity checks, not rounded instructions for generating tips.

### Stage B — independent phase-aware M1 meshes and solutions

For each material separately, calculate signed MTS from its own S0 K, append a full-precision 4-mm segment, and **build an entirely new protected mesh**. Enforce original Cornell K1–K10, p010 kernel/3.3mm collar/64+64 seams, min angle≥20°, neighbor ratio≤1.8, max primary T3 40000, 3 true holes / 4 loops, correct upper/lower crack banks at every kink. Independently audit the **saved** T3/T6 arrays 34/34.

On each new mesh, independently rebuild the *actual* perfectly bonded annulus phase map. Require three conforming two-owner polygonal interfaces with shared T6 midsides, 1 connected matrix, no void fill or accidental tip-guide material phase, correct areas and phase negative controls. Verify every q-active cell and its full nodal support is in the homogeneous matrix with admissible clearance. A different band polygonization than the baseline must be recorded and handled under the preregistered comparability rule.

**Only then** solve anew using `g2_t6_elasticity_phase`; independent blind COD before signed five-annulus interaction EDI, matrix E and ν at tip, residual/force/energy/traction balance, opening/face orientation, 4×4 versus 6×6 and COD/EDI sign and magnitude. No previous U, K or mesh phase IDs reused.

On GO, save immutable SHA-256 mesh and phase evidence and **REVIEW_M1 before STATE_M1**, including parent/material/policy/source hashes, full-precision tip and tangent, signed SIF and all gate outcomes. Review reuse must recheck **actual saved mesh+phase map+34/34** (guard the forged-review defect), rather than merely rehashing a forged manifest. HOLD before FEM or child promotion on any missing gate; preserve errors and original data.

### Stage C — own M2 mesh from own M1 SIF; hard stop

For each material independently, derive the second signed MTS from **its own accepted M1** full-precision SIF, not from homogeneous S1 or State 2 frozen fields. Rebuild new 4-vertex crack mesh, independently recheck K1–K10 and full 34/34, construct new compliant material regions, perform fresh phase FEM, COD, EDI, and review-first checkpoint. Stop exactly at material STATE_M2 and arc 33.4mm. The *original homogeneous* chain stays source-locked and cannot grow to State 3.

### Stage D — separate *direct material* from *indirect path* effect

Use the three measured energy functions at **the same applied 1N and same arc length**:

`G_H[Γ_H]` — read-only existing homogeneous-tip result;
`G_M[Γ_H]` — previously measured material effect at the frozen homogeneous-reference geometry (read-only PR #38);
`G_M[Γ_M]` — new material-specific tip at its own independently computed geometry.

For M=soft,stiff calculate at each s:

`R_direct = G_M[Γ_H]/G_H[Γ_H]`

`R_path = G_M[Γ_M]/G_M[Γ_H]`

`R_total = G_M[Γ_M]/G_H[Γ_H] = R_direct × R_path`

No-hole counterfactuals belong to a separate protocol; this is a **phase-only, path-feedback decomposition** on the same perforated specimen. At S0, the paths coincide and `R_path=1`.

Report tip coordinates, equal-arclength signed lateral/full-path differences, local+global terminal tangents, signed `K_I,K_II`, `G`, direct/path/total ratios, hole+interface clearances and compliance. Use correct raw MPa√mm → physical 1N G conversions; do not square normalized per-kN reported K without undoing load/length factors. Explicitly classify changes against **both preregistered primary paired-estimator and conservative uncorrelated uncertainty**, plus a prospective numerical **path separation resolution** rule. A nonzero tip shift does not by itself prove a materially different converged path.

At minimum verify the exact decomposition algebraically and numerically for each complete case. A sign reversal in the path factor or no resolved difference is scientifically acceptable. Do not claim physical growth or crack-arrest thresholds.

### Stage E — fault cases and realistic replay

On disposable copies, test: tampered/forged review whose *mesh belongs to another step or material*, phase labels inconsistent with the saved polygonal interfaces, switched soft/stiff policy, q crossing material, source/policy drift, wrong parent K or hash, invalid bank sign, bad 4mm segment or attempt at step 3, crash between review and state. Verify safe refusal; validated replay and interrupted-review resume must **not rerun FEM**, and valid review/state must not be silently overwritten.

If feasible **after preregistration and the two main paths pass**, perform one selected independent alternative exterior+band mesh at a material M1 or M2 state to quantify path-separation/`R_path` stability. Do not relax mesh quality, expand to >40k T3 automatically, or use this as a reason to repeat historical general convergence studies. Without this evidence, label path-separation conclusions **single-mesh numerical observations**.

### Stage F — deliver actual scientific data

Create new draft PR(s), `G2_M3_RESULTS.md`, policy+preregistration, MATLAB R2023a scripts, PowerShell launcher, actual results graphs with all three crack paths, local MTS vs arclength, `G` vs s, the three ratios and their uncertainties, independent bands and q-support snapshots, failure and SHA-256 ledgers, fresh timestamped immutable `outputs/g2_material_trajectories_v1/` with raw MATs kept outside Git. Report exact branches/commits and GO/HOLD/replay results to Issue #39. Do not overwrite accepted outputs.

**Non-negotiable:** no physical onset, no fracture toughness, no actual observed Cornell path, no CZM/debonding, no State 3 or unrestricted campaign, no weakening 5GiB/20°/1.8/40k/K1–K10/34/34/q/signed SIF gates, no changed earlier PRs or policies, no PR merge, and no invented MATLAB results. If no access to real R2023a, report **RUN PENDING** with exact Windows commands.

**Start with source inspection, a preregistration review and zero-write preflight. Then execute at most the two authorized material-specific steps, conditional on all gates. Report the resulting direct-versus-path inference without overstating numerical or physical evidence.**
