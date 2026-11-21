# Claude Code assignment — G2-M2: material-induced shielding and steering along three frozen crack states

> **Ready to paste into Claude Code.** Authoritative research issue: [#36](https://github.com/mfs9697/NewMetacomp/issues/36); scientific background: [#7](https://github.com/mfs9697/NewMetacomp/issues/7), previous verified fixed-State-2 experiment [#33](https://github.com/mfs9697/NewMetacomp/issues/33), and the actual [draft PR #35](https://github.com/mfs9697/NewMetacomp/pull/35). This prompt prescribes work; it **does not report additional MATLAB results**.

You are the senior fracture-mechanics researcher and MATLAB R2023a implementation agent for `mfs9697/NewMetacomp`.

**New scientific objective:** Study how the presence of three **perfectly bonded elastic reinforcement annuli around the Cornell holes** changes (i) signed crack-driving force `G` and (ii) prospective MTS kink direction as an **already-qualified reference crack** lengthens. Do **not** spend this assignment repeating the prior `EdgeCrackHoleLEFM` convergence campaign or advancing another crack. The effects, not the mesher, are the scientific subject.

## Repository and source locks

Base all new implementation work **directly on the current actual head of draft PR #35**, presently `75a4bce9d72968ae22bac17719d233cfa62e880e`, branch `research/g2-material-contrast-20261119`, stacked on PR #32. PR #35 is a real MATLAB-qualified result: coated-hole benchmark **14/14**, State-2 phase interfaces validated, homogeneous/equal-modulus identity **bitwise**, soft+stiff results PASS and accepted replay bit-identical. All earlier PRs, `main`, old trajectory/material policies and their original accepted outputs are immutable and unmerged. Create a **new separate draft implementation PR** stacked on #35. Never modify #35 or its head.

Read before coding:
- `matlab/g2/G2_MATERIAL_CONTRAST_RESULTS.md`, `G2_MATERIAL_CONTRAST_PREREGISTRATION.md`, `G2_MATERIAL_POLICY_v1.json`, `g2_material_phase_map.m`, `g2_material_phase_verify.m`, `g2_t6_elasticity_phase.m`, `g2_material_sif_on_mesh.m` and `run_g2_material_contrast_batch.m`.
- Historical pre-verified `SIF_WP2_RESULTS.md` (straight crack, State 0), `WP3_FIRST_KINK_RESULTS.md` (first kink, State 1), and `WP34_STATE2_RESULTS.md` (second kink, State 2). Inspect their exact MATLAB output schemas. The State 0 straight-crack mesh is **not** guaranteed to have the fields expected by the State 2 material runner; add explicit, independently tested adapters rather than faking data fields.
- `docs/research/crack-growth-gaps-2026/G2_FOCUSED_AUDIT_AND_TEST_PROTOCOL.md`. It forbids calling path interception “arrest,” or describing a single-mesh ratio as a refinement-qualified screening mechanism.
- The full [Issue #36](https://github.com/mfs9697/NewMetacomp/issues/36), especially its preregistration, stops and targeted ratio-robustness provisions.

### Input data — three immutable HOMOGENEOUS reference paths

| State | Crack shape | s (mm) | Stored original T3/T6 mesh | Original mesh SHA-256 | K_I / K_II, MPa√m per kN |
|---|---|---:|---|---|---|
| S0 | original vertical crack | 25.4 | `outputs/g2_protected_mesh/run_20261118_165922_343_famA/GEOMETRY_ONLY_candidate.mat` | `05d5c3fcf5152c30bb0e5c288dc109bfce42b8d677077c4631254ab5887657` | approx 0.166436 / +0.018827 |
| S1 | one −12.5957° kink | 29.4 | `outputs/g2_wp3_state/run_20261118_185808_963/step1_a/KINKED_GEOMETRY_ONLY_candidate.mat` | `ecd6a7b873bc2cd758a0f88391e564dfb6c90249024bc1a8768f9f5d93732461` | approx 0.182585 / +0.001514 |
| S2 | two kinks | 33.4 | `outputs/g2_trajectory_chain_v1_attempt2/STEP_002/KINKED_GEOMETRY_ONLY_candidate.mat` | `9269be43141014eff1e9f7ef6ef0cdc82b2772c62a12ccf3d847549c7485c412` | approx 0.195982362 / +0.003149970 |

Source hashes must be checked against the existing committed `SHA256SUMS_original_outputs.txt` files, not inferred from these rounded reference K values. All three meshes must preserve three actual holes and the **same nominal** radius 6.35mm, band boundary radius 19.05mm, geometry, 1-N point-load BVP, thickness 12.7mm, plane stress `E_m=3268.115MPa`, `ν_m=ν_r=0.35`. Original State 0 must be validated by its own WP2 **38/38 T6 plus 24/24 protected** auditors, States 1 and 2 by their *actual kink-aware* 34/34 auditors. Audit all checkers against the genuine saved schema, keeping historical tool sources unchanged.

The previous source accepted **State 2** at frozen crack:
(101.6,0)→(101.6,25.4)→(102.4722795671,29.3037326185)→(103.4091509165,33.1924691839)mm.
State 2 material results must reproduce PR #35 on unchanged mesh:
- `R_soft(S2)=1.021813`, `R_stiff(S2)=0.970687`;
- `θ_H1=-1.8407°`, `θ_soft=-1.1464°`, `θ_stiff=-2.2923°` in the **last-segment local frame**;
- H1 and M0 bitwise identical.

## Work order and mandatory STOP/GO

**A. Preregister first.** Before computing any new material-contrast fields, commit `G2_M2_SHIELDING_STEERING_PREREGISTRATION.md` and immutable prospective `G2_M2_POLICY_v1.json` based on the three exact mesh SHAs, planned tests, scientific falsification, state-specific data adapters, original numerical and RAM gates, 5GiB minimum free RAM and numerical uncertainties. Fix beforehand how much *cross-state polygonized band area* may vary, and how deviations affect interpretation; never retrospectively tune thresholds. This pilot is **three separate matched same-mesh material contrasts**, not one physically evolving material-crack simulation.

**B. Validate original phase geometry at S0 and S1.** Do not assume that State 2's 3×76 conforming band edges transfer to earlier meshes. On each saved mesh: two-owner polygonal band interfaces, common T6 midside nodes/shared displacement DOFs, 3 holes and exactly connected matrix and annuli, original crack-bank twins, and entire q-domain in MATRIX only; the 15mm tip guide must stay matrix. Independently verify polygons, area fraction, chord counts and exact distances from each tip. HOLD if any “guide circle” is not truly a conforming phase interface. No centroid-only labels.

**C. Reuse validated solver, verify each state.** The existing coated-hole two-phase benchmark need not be recomputed unchanged for every crack state; verify its hashes and rerun if the stiffness solver, constitutive assembly or interface mapper changes. At S0 and S1, first reproduce original HOMOGENEOUS accepted K in the exact idealized BVP. Then compare homogeneous H1 with equal-phase M0 on the identical mesh: complete displacement, stiffness/energy, reactions, signed COD/EDI K, `G` and compliance. Require the existing preregistered identity limits, not new loose tolerances. S2 must reproduce PR #35 as an immutable regression.

**D. Only after above GO**, solve two material contrasts on each saved state, preserving phase distribution, load and actual crack shape:
- `Msoft:E_annulus/E_matrix=0.5`;
- `Mstiff:E_annulus/E_matrix=2`;
- full phase-aware T6 FEM, bonded interfaces, equilibrium, reaction force, energy, negative opening, independent blind COD before signed EDI;
- homogeneous matrix q-support for all five original contours, original q and quadrature tolerances, EDI/COD≤3%-of-K reference, component-wise Mode-II sign test;
- independent numerical reproduction of both original PR #35 uncertainties: (1) correlated same-mesh ratio-of-extractor uncertainty, (2) conservative uncorrelated bound. **Both verdicts must be reported**, even if they disagree.

**E. Calculate scientifically meaningful functions of s=25.4,29.4,33.4mm.** For each STATE and MATERIAL:
`G=(KI²+KII²)/E'_matrix` at the tip, `R_material(s)=G_phase[Γ_H(s)]/G_H1[Γ_H(s)]`, `ΔR=R_material-1`, `ψ(s)=atan2(KII,KI)`, `θ_MTS(s)` and `Δθ_MTS(s)=θ_material(s)-θ_H1(s)` **in that state’s local last-segment frame**. Also record global tangent direction, compliance and CMOD. Report full `G_H1(s)` alongside `R_material(s)`: energy variation along a growing geometry is NOT automatically a material-induced effect. An increased MTS deflection need not mean a higher driving force. A sign change in `R-1` across states is a conditional observation, **not** evidence of physical crack arrest.

**F. One focused numerical-ratio robustness probe (not a new general convergence study).** If all three frozen states pass, prospectively make a single **independently qualified alternative conforming band mesh** at S2 to test whether the ±2–3% `R_material` effects are stable to exterior and polygonal interface discretization under the *same* material architecture and crack shape. Do NOT automatically authorize >40k T3 or lower 20°/1.8/p010/34-gate thresholds. Report actual band area differences and their uncertainty; failed or unavailable alternative mesh means **HOLD refined shielding claim**, not necessarily invalidation of the reproducible same-mesh pilot. Reuse the prior numerical method qualification wherever valid.

**G. Deliver real results.** New draft PR(s) stacked on PR #35; reproducible MATLAB R2023a/PowerShell batch, original input hash ledger, source-locked timestamped immutable `outputs/g2_material_evolution_v1/run_*/`, sanitized failure/pass logs, compact CSV/JSON and actual plots of `R_mat(s)` with both uncertainties, signed mode mixity, steering difference, compliance, and saved material-interface/q geometry. Write `G2_M2_SHIELDING_STEERING_RESULTS.md`. Report null effects accurately.

**Absolutely prohibited:** State 3; further MTS propagation; autonomous paths; rewriting source data, legacy solvers, original policies, previous PRs, or historical accepted outputs; cohesive debonding, fracture toughness or physical onset claims; calibrated cement/polymer material claims; unsupported novelty; WP4 article. The explored ratio is for perfectly bonded two-phase elastic annuli under an illustrative 1N BVP. No new MATLAB data? Report RUN PENDING, not GO.

**First response:** show the exact prior source state and hashes; state which historic MAT meshes and their independent audit tools can be reused; identify any schema/adaptor or polygonal-interface concerns; present the preregistration plan and first executable read-only inspection. Then proceed to actual test implementation and R2023a runs if accessible.

**Final report:** stage-by-stage GO/HOLD/NOT RUN, case table for all three states, uncertainty classifications, whether material-induced shielding and steering persist or change sign, original and alternative mesh ratio comparison if available, SHA-256 and draft PR IDs, and a bounded proposal for later independently evolved material-specific trajectories only if justified.
