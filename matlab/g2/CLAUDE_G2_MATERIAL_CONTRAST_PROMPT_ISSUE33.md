# Claude Code execution prompt — G2 material shielding/amplification by bonded annular reinforcement

> Companion to [Issue #33](https://github.com/mfs9697/NewMetacomp/issues/33). This file is an **assignment, not a numerical result**. The full issue is authoritative if scope details differ.

---

You are the lead fracture-mechanics investigator and MATLAB R2023a developer for `mfs9697/NewMetacomp`. We have completed and verified the numerical trajectory algorithm. **Stop improving it merely for its own sake.** Your next objective is an actual **metacomposite material-architecture comparison**, not another 4-mm crack step or a method-convergence campaign.

**Mission:** Implement Issue #33: a perfectly bonded, two-phase elastic architecture around the three existing Cornell holes. Using the exact saved and verified **State 2** crack, test whether three soft/stiff annular reinforcement bands change signed SIF, crack-driving force, compliance and prospective MTS direction relative to an identical-geometry single-phase control. **The crack path and all geometric voids must remain frozen in all cases.**

## 0. Repository and scientific provenance

Start with a current audit, not a rewrite. Use genuinely MATLAB-qualified [draft PR #32](https://github.com/mfs9697/NewMetacomp/pull/32), branch `research/g2-wp34-state2-qualification-20261118`, head `f2c9790d9802e9ce40a55978ea0b6e13feafb7bf`, as the **unchanged** parent. Inspect:
- `matlab/g2/WP34_STATE2_RESULTS.md` and the full SHA list in `matlab/g2/evidence/wp34_20261118/SHA256SUMS_original_outputs.txt`;
- `matlab/g2/g2_kinked_exterior_mesh.m` and its three 3R **nonphysical guide faces**;
- `matlab/g2/g2_t6_elasticity.m` (homogeneous element constitutive tensor), `g2_sif_interaction.m` (homogeneous crack-tip Williams auxiliary fields), `g2_sif_cod_banks.m` and `g2_trajectory_sif_on_mesh.m`;
- `docs/research/crack-growth-gaps-2026/G2_FOCUSED_AUDIT_AND_TEST_PROTOCOL.md`, `GAP_ANALYSIS.md` and [Issue #7](https://github.com/mfs9697/NewMetacomp/issues/7).
- The original **accepted** chain `outputs/g2_trajectory_chain_v1_attempt2/STEP_002/`, including source/policy/review/state ancestry and saved `KINKED_GEOMETRY_ONLY_candidate.mat`. Do not use the failed `outputs/g2_trajectory_chain_v1` as an accepted numerical state.

State 2 (actual verified idealized model): crack vertices in mm
`(101.6,0) → (101.6,25.4) → (102.4722795671,29.3037326185) → (103.4091509165,33.1924691839)`,
28,625 T3, 34/34 independent saved-array audit, signed normalized `K_I=0.195982362`, `K_II=+0.003149970` **MPa√m per kN**, independent COD agreement 0.88%. Existing source/result files, earlier PR heads, original P0 and Cornell JSON, and the accepted chain are **immutable**.

Create a **new implementation branch based on actual PR #32 head**, with draft PRs only. Never edit or merge any prior PR, never change `main`, and never modify the trajectory policy v1. Preserve the ≥5 GiB prelaunch free-RAM guard.

## 1. Freeze the exact proposed material comparison BEFORE running contrast FEM

Commit `G2_MATERIAL_CONTRAST_PREREGISTRATION.md` and a separate prospective experimental `G2_MATERIAL_POLICY_v1.json` before writing or observing contrast numerical results. Declare material, phase/edge classification, validation tests, equality tolerances, uncertainty rule, mesh/resource gates, unit conversions, abort-on-HOLD and source SHA. Material ratios are exploration, **not measured** polymer/cement properties.

**Identical State 2 geometry/mesh for every case:**
- Plate 508 × 203.2 mm, thickness 12.7 mm, three true circular holes of radius 6.35 mm, centers x=152.4 mm at y=(69.85,120.65,171.45) mm; all hole interiors stay **void**.
- **H1:** existing single-phase matrix model, with the three holes and unchanged State 2 path.
- **M0:** same holes and mesh, distinct material phase labels but exactly equal moduli (`E_r/E_m=1`), mandatory numerical identity benchmark.
- **Msoft:** same mesh/labels, bonded bands of `E_r/E_m=0.5`.
- **Mstiff:** same mesh/labels, bonded bands of `E_r/E_m=2`.
- Phase layout: three identical candidate bands `6.35 mm < r_h < 19.05 mm`, i.e., within the current nominal 3R mesh guides; everything else (including protected tip and the 15-mm *meshing guide* around it) remains matrix. Choose `ν_r=ν_m=0.35` to isolate modulus contrast.
- Idealized plane stress with `E_m=3268.115 MPa`, pin (25.4,0), roller (482.6,0), load point (254,203.2) downward **P=1 N**; unchanged thickness and DOFs. Do not recalibrate from literature or call this a cement/polymer experiment.

**Question:** under identical crack `Γ₂`, BVP and void geometry, does the phase contrast produce direct shielding or amplification?
`R_mat(Γ₂)=G_M(Γ₂)/G_H1(Γ₂)`, with `G=(K_I²+K_{II}²)/E'_m` **only** in the proven homogeneous crack-tip matrix domain. Report signed K, ratio KII/KI, `Δθ_MTS` as a **forecast** (no advancing geometry), and `C=|u_y(load)|/P`; do not infer toughness, onset, arrest or improved durability.

## 2. Implement phase topology and independent heterogeneous FEM verification

**Do not merely color elements by their centroids.** The source three 3R circles are currently CAD **size-guide interfaces**, not physical discontinuities. On the original saved State 2 mesh, reconstruct/materialize the intended interfaces with element/facet ownership and independently prove:
- each band is connected, contains only valid material elements and excludes all three physical voids;
- every matrix/reinforcement interface is a **conforming two-owner T3 and T6 edge** with separate phase labels but the SAME displacement nodes, hence perfect bond, no unintended duplicate DOFs;
- annular boundaries coincide with actual mesh edges; if the saved mesh does not truly resolve them, **HOLD** and document what geometry would need rebuilding—do not quietly accept a centroid-only approximation while claiming the original mesh is untouched;
- the original crack banks remain distinct at both kinks, and entire FE-nodal q support lies strictly inside the unchanged host matrix, with no inclusion or interface crossing;
- the phase-0 result reduces precisely to the original matrix, the nonphysical tip-guide does not turn into a material inclusion, and exact geometry + material areas are independently checked.

Implement a **new** phase-aware T6 linear-elastic assembly (leave existing `g2_t6_elasticity.m` unchanged), using per-parent `D_e(E_phase,ν_phase)`, unchanged nodal topology, and a verifiable mapping from saved faces to each element. Enforce stiffness positive-definiteness, force/reaction balance and matching external work/strain energy. Verify bonded interface tractions in a weak/integrated sense (do not demand full component-wise equality of stress tensors). Add label/interface corruption negatives. Independent calibration benchmark should be a valid analytic **two-phase** elasticity solution (e.g., axisymmetric coated circular hole with compatible internal/external tractions and Lamé fields); a uniform global affine strain imposed across unlike phases is not necessarily an equilibrium solution.

**HOLD if independent two-phase elasticity validation fails.** No SIF/shielding conclusions on a failed phase assembly.

## 3. Equal-phase identity then the two material contrasts

First run **H1 and M0** with identical saved mesh/BVP. Independently compare entire displacement field, equilibrium, reactions, potential/strain energy, signed `K_I,K_{II}`, blind COD and EDI, mode mixity and G. Predeclare tight machine-precision-aware relative/absolute tolerances before running M0. **DO NOT require bitwise equality** if summation order differs, but record deviations. The source State 2 values are a reference **only for the same BVP and explicitly consistent unit normalization**.

Critical **unit audit**: Existing raw EDI returns `K_raw` in **MPa√mm** from the actual **P=1 N** solve. Thus
- physical `K_phys` in MPa√m at **1 N** is `K_raw/√1000`;
- numerically reported normalized `K_per_kN` in MPa√m per kN is `K_raw×√1000`, because a **1 kN** load is 1000 times the existing 1 N solve;
- physical `G_{1N}` in N/mm is `(K_raw,I²+K_raw,II²)/E'_m`.
Never square a K value normalized per kN to compute G at **1 N** without undoing that load normalization and the length-unit conversion. For `R_mat` under the same load, the normalization cancels; nevertheless calculate/report absolute G consistently.

Only after M0 full PASS, solve **Msoft** and **Mstiff** on the same fixed geometry. Required:
- force balance, residual, energy identity for heterogeneous assembly, no artificial interface displacement discontinuity;
- local-tip q-support entirely homogeneous matrix for every contour; use matrix `E_m,ν_m` in Williams EDI and COD material parameters, not band-average parameters;
- blind COD and independent domain-integral SIF, original preregistered limits and SIF sign conventions;
- contour and quadrature checks, full crack opening, component-wise sign resolution for small Mode II;
- calculate `G` and `R_mat` using both signed modes with uncertainty. A modest difference within numerical uncertainty ⇒ **no resolved material effect**, not a pretext to increase contrast or change tolerances.
- A secondary observation of changes in `C` or `θ_MTS` is allowed; do not treat that as a predicted new trajectory or physical growth.

The original hole-vs-no-hole G2 decomposition `R_direct/R_path/R_total` addresses a **different counterfactual**. In this experiment the direct **phase** effect is isolated on an identical perforated specimen and crack; a no-hole H0 control or independent metacomposite path would need a separately designed CAD model and separate authorization.

## 4. Deliver genuine science, including null results

Deliver reproducible MATLAB R2023a code, tests and a PowerShell runner; timestamped immutable outputs outside Git; a machine-readable PASS/HOLD case ledger and complete SHA-256 provenance; `G2_MATERIAL_CONTRAST_RESULTS.md` with H1/M0/Msoft/Mstiff signed K, normalized G, R_mat, compliance and ΔMTS; and actual MATLAB images showing phase boundaries, frozen crack, matrix-only q support, interface stress/traction diagnostics, SIF cross-checks and G ratio. Keep private workstation paths out of committed logs.

Open one or more new **draft PRs stacked on #32**; do not touch #32 or any prior PR head. Include all genuine MATLAB command logs and failed-attempt explanations. If you lack access to the machine, report **RUN PENDING**, provide exact Windows PowerShell commands, and never present code completion as numerical GO. STOP on invalid interfaces, mismatched source hashes, any domain-integral crossing of a material boundary, failed equal-phase identity or any failed numerical gate.

**First response:** report source audit, evidence hashes, precise model hypothesis and validation plan, and the single next executable verification step. Then implement and run as tools permit.

**Out of scope:** further crack growth, State 3, autonomous trajectory, method-convergence campaign already studied in EdgeCrackHoleLEFM, mixed-mode interface crack extraction, traction-separation law/CZM, experimental material identification, dynamic/resonant or truly auxetic response, and full WP4 LaTeX report. No unsupported assertion of novelty. A reproducible **null effect** is a scientifically acceptable outcome.

**SUCCESS:** independent two-phase assembly qualification + equal-modulus identity GO + verified frozen-path soft/stiff results, or an evidence-backed HOLD explaining what is impossible with the present saved mesh.
