# G2-M2 scientific design — direct elastic shielding and local steering

**Date:** 2026-11-21. **Status:** research protocol / execution assignment, **no additional R2023a material runs completed by this document**. Implementation instructions: [Issue #36](https://github.com/mfs9697/NewMetacomp/issues/36) and `matlab/g2/CLAUDE_G2_M2_SHIELDING_STEERING_PROMPT_ISSUE36.md`. Numerical predecessor: genuinely qualified [draft PR #35](https://github.com/mfs9697/NewMetacomp/pull/35), unchanged.

## Scientific question and scope

In a three-hole Cornell-type plate with three perfectly bonded, concentric matrix/reinforcement annuli, does the **direct material-phase modification** to the energy-release rate and the predicted MTS direction depend on the *position of a preexisting homogeneous-reference crack*?

The experiment has three **fixed, previously independently qualified** reference geometries:
`Γ_0` (straight crack, s=25.4mm), `Γ_1` (first kink, s=29.4mm), and `Γ_2` (two kinks, s=33.4mm). No new propagation is modeled under the material contrast. Models use nominally the same holes/annulus geometry; their **actual polygonal interfaces** need independent measurement per saved mesh. Each geometry is evaluated under the same idealized 1N downward load and pin/roller boundary conditions, for H1 (single-phase), M0 (equal phase) and soft/stiff `E_r/E_m=.5/2`. All moduli illustrative.

## Comparisons and equation definitions

For `j∈{0,1,2}` and material case `m`, define energy-release rate at the *matrix-phase crack tip* using the full signed mode pair:

`G_{m,j}=(K_{I,m,j}²+K_{II,m,j}²)/E'_m`, with `E'_m=E_m` in the declared plane-stress model, after consistent physical 1N conversion.

`R_{m,j}=G_{m,j}/G_{H1,j}`, `δR_{m,j}=R_{m,j}-1`.

`θ_{m,j}=\mathrm{MTS}(K_{I,m,j},K_{II,m,j})` in each state’s **own terminal-segment local frame**, and `Δθ_{m,j}=θ_{m,j}-θ_{H1,j}`. Also record the global terminal tangent and `ψ_{m,j}=\operatorname{atan2}(K_{II,m,j},K_{I,m,j})`.

- **R<1** means a **same-crack-shape, same-load elastic driving-force reduction** versus H1; it does NOT imply increased `G_c`, fracture onset or arrest.
- **R>1** means amplification of the driving force on that same frozen crack.
- `Δθ` is a **forecast** of local direction only; it is not an actual modified crack path.
- Differences in `G_{H1,j}` as `j` increases reflect the changing *reference crack geometry* and must not be attributed to reinforcement.
- This `R_material` is the **phase-contrast direct effect** on a perforated specimen. It is **not** the hole-versus-no-hole G2 `R_direct·R_path=R_total` decomposition; the latter requires separate geometry controls and independently evolved paths.

## Three source mesh identities

| State | Original saved mesh path (under `outputs/`) | Original mesh SHA256 | Historical qualification |
|---|---|---|---|
| Γ0 | `g2_protected_mesh/run_20261118_165922_343_famA/GEOMETRY_ONLY_candidate.mat` | `05d5c3fcf5152c30bb0e5c288dc109bfce42b8d677077c4631254ab5887657` | WP2 protected join, 38/38 T6 + 24/24 tip |
| Γ1 | `g2_wp3_state/run_20261118_185808_963/step1_a/KINKED_GEOMETRY_ONLY_candidate.mat` | `ecd6a7b873bc2cd758a0f88391e564dfb6c90249024bc1a8768f9f5d93732461` | WP3 true kink, 34/34 kinked mesh |
| Γ2 | `g2_trajectory_chain_v1_attempt2/STEP_002/KINKED_GEOMETRY_ONLY_candidate.mat` | `9269be43141014eff1e9f7ef6ef0cdc82b2772c62a12ccf3d847549c7485c412` | WP3.4 two kinks, 34/34; original material pilot GO |

Original data, geometry and MATLAB outputs are not attached to this new research note. Their cited hashes are from the verified repository evidence. The new execution must independently verify file existence, content, phase geometry and accepted source history on the investigator's workstation.

## Primary evidence design

A qualified case requires: exact source SHA, correct legacy independent mesh checker, *two independent* band-region classifiers with perfect T6 interface topology, all q-active elements in matrix, exact H1/M0 equivalence on that mesh, accepted 2-phase FEM benchmark, force/energy and interface balance, sign-resolved Mode-II where claimed, and independent blind COD plus EDI on the five frozen q annuli. A State 2 numerical repeat must reproduce [PR #35](https://github.com/mfs9697/NewMetacomp/pull/35).

Keep **both** previously preregistered G-ratio uncertainty assessments: the correlated **ratio-of-extractor** spread and the conservative uncorrelated COD/EDI bound. Compare `|R-1|` against both rather than selecting the more favorable result after the fact. Declare cross-state phase-geometry discrepancies and, if necessary, classify a trend as geometry-confounded.

The project already qualified the crack-mesh algorithm elsewhere. The only new discretization experiment considered is a **single targeted independent alternative mesh at Γ2** to test the stability of *the material-effect ratio*. It is not a general tip-size or crack-step convergence campaign; if this ratio check cannot be performed, do not label results refinement-qualified.

## Figures and scientific decision table

A completed report should provide, without inventing results:
- `R_soft(s)` and `R_stiff(s)` with both uncertainty classifications and actual polygonal annulus areas;
- signed `K_I(s),K_{II}(s)`, mixity `ψ(s)`, the terminal local `θ_{\mathrm{MTS}}(s)` and material steering differences `Δθ(s)`;
- total absolute `G_H1(s)` and per-case `G_m(s)`, compliance ratios, and matrix-only q footprints;
- controls for H1=M0 and source/hash/interface/phase-integrity negative tests.

**Interpretation questions:** Do soft bands always amplify G? Do stiff bands always shield it? Does the contrast effect grow as the tip moves closer? Does material-induced steering follow the same sign as the energy change? Does a low KII near a mixed-mode turning point make a steering prediction uncertain? Is there an apparent transition beyond uncertainty, or merely a small persistent effect?

Do not assume any answer in advance. The already verified Γ2 result is **R_soft=1.021813, R_stiff=0.970687** with local MTS angles −1.1464°/−2.2923° versus −1.8407° homogeneous. All Γ0/Γ1 material outcomes remain **NOT RUN** until genuine MATLAB checks are executed.

## Exclusions

No State 3, new propagation, physical fracture onset, experimental Cornell path comparison, cohesive debonding, material calibration, durability or unsupported novelty claim. Keep existing PRs untouched/unmerged and preserve failure records; implement on stacked draft PR(s) only.
