# Scientific report outline — 2027–2028 metacomposite fracture project
**Draft for author decision; not an approved research report or evidence of completed simulations.**

## Proposed working title
**Architecture–crack interactions in cementitious infrastructure composites: path selection, driving force and the limits of elastic modeling**

This deliberately narrows the first mechanics report to a **falsifiable question** rather than claiming all six project scenarios are complete. The broader approved research task remains subject to source-version comparison in [SOURCE_INVENTORY.md](SOURCE_INVENTORY.md).

## Proposed structure, evidence classes and expected tables
| Section | Scientific content | Evidence available now | Evidence **not** available |
|---|---|---|---|
| 1. Problem and infrastructure context | Pavement/cementitious architecture, competing toughness/strength/attenuation objectives; definitions of ACM vs ACC | Moini 2023/2024; Gupta–Moini 2026 and proposals | Final proposal approval hierarchy |
| 2. Literature and falsifiable gap | Critical synthesis of 32 records; 10 nearest competitors; G1–G6; avoid unqualified “first” claims | [LITERATURE_MATRIX.csv](LITERATURE_MATRIX.csv), [GAP_ANALYSIS.md](GAP_ANALYSIS.md) | Full methods for paywalled papers and repository PDF review |
| 3. Mechanics and admissibility | Homogeneous plane-strain/stress LEFM; signed SIF, interaction integral, MTS, T/GMTS, crack-step recurrence; regularity/scales and criteria for refusing results | Source-qualified historical single-phase examples; [CAPABILITY_MAP.md](CAPABILITY_MAP.md) | Qualified heterogeneity/interface/3D/dynamics |
| 4. Controlled architected-pavement surrogate | Smooth void arrays, matched solid fraction/net section, notch/loading controls, reference geometry and parameterization | Planned in [PRIORITY_AND_PILOT_PLAN.md](PRIORITY_AND_PILOT_PLAN.md) | No new geometric specimens solved |
| 5. FE and verification protocol | T3→T6, convergent mesh/independent increment families, q-domain SIF, COD, independent path comparisons and geometric diagnostics | Provenance/source audit from `EdgeCrackHoleLEFM` | No new metacomposite model tests |
| 6. **Future** physics results | `Γ(s;p)`, `G/G_0`, path-class transitions, steering vs shielding, stress penalties | No Stage-0 physical results | Entire results section pending authorization |
| 7. Interface/CZM extension | Bimaterial, adhesion/debonding, toughness ratios, mode-dependent laws; compare He–Hutchinson and Tao–Zhang | Classical theory and publications | Phase-aware FE/CZM not qualified |
| 8. Dynamic / auxetic extensions | Interaction between vibration mitigation and crack risk; hinge rotation with material bridging | Literature mechanisms known | Transient experiments and cohesive dynamic model not performed |
| 9. Validation and discussion | Concrete fracture-process zone, SCB/DIC or flexural tests, limits of model and generalization | Literature benchmarks | New experimental calibration |
| 10. Conclusions and negative outcomes | Distinguish established algorithms, null results and novel mechanics; publish only reproducible controlled difference | Stage-0 decisions | Any claim of discovered architecture law |

## Planned figures
1. Infrastructure specimen and scales: cell, notch, smooth voids, nearest tip-to-void distance; **schematic only until geometry qualified**.
2. Literature comparison: direct analogs vs proposed controls; from matrix with access labels.
3. Flow of gated calculation: FEM → qualified SIF → MTS → remesh → repeated independent solve; **methods diagram**, not validation plot.
4. Future `G/G_0(s;p)` for equal-length paths and homogenous controls: **placeholder only**.
5. Future corridor classification vs geometry parameter with uncertainty intervals: **placeholder only**.
6. Future two independently solved MTS–GMTS paths for fixed material `r_c`: **optional placeholder only**.
7. Future experiment/FE crack-path overlay with DIC validation: **not available**.

## Required comparison tables
- **T1:** verified 32-work matrix and top-ten closest prior models, including limitations of abstract-only inference.
- **T2:** 6 proposed simulations against A/B/C capability and experimental cost.
- **T3:** benchmark progression: analytic/legacy homogeneous vs one-hole vs multi-void vs *future* interface model.
- **T4:** blinded mesh and increment convergence; record missing/failed runs, not just selected winners.
- **T5:** hypothesis decision: known → unknown → discriminating metric → failure criterion → status.

## Expected scientific results by stage (no double counting)
- **Already achieved independently:** method experience in homogeneous cracked plates, source evidence for T3→T6, signed SIF, MTS and isolated T/GMTS investigations; this is *not* a research result on new cementitious architecture.
- **Stage 0 under Issue #7:** literature review, access-qualified matrix, source inventory, critical hypothesis and feasibility decisions. The matrix is a **screening bibliography**, not evidence that 32 primary papers have been read cover to cover.
- **Future after explicit approval:** independent single-phase architecture G2/G1 experiments with falsification, a bounded generalization or documented failure, and possible laboratory test design.
- **Future after new qualification:** two-phase polymer–cement CZM and/or auxetic hinge dynamics, linked to simulations 1/3/4/5 in the proposal.

## Scientific publication standards
Do not write “first” or “novel crack steering” without a detailed closest-paper method table. Do not infer physical arrest from an unpropagated path, `K` at an invalid interface, or enhanced durability from reduced elastic stress alone. An adequately verified **negative result** (no change in crack-driving force at controlled architecture parameters) is an acceptable scientific conclusion and should not be rewritten as a positive one.

**Approval gate:** the researcher reviews the newest proposal, selects G2/G1 or rejects both, approves physical dimensions and geometry, and only then may authorize a separate FEM/CZM issue.
