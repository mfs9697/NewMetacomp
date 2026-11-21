# Claude Code — G2-M4: Mechanism Attribution and Architecture-Controlled Fracture

**Authoritative issue:** [#44](https://github.com/mfs9697/NewMetacomp/issues/44). **Status: ASSIGNMENT — no new G2-M4 MATLAB numerical results.** Read the *entire issue* before implementation; this prompt supplements, but does not replace, its preregistered gates.

You are working in `mfs9697/NewMetacomp` as MATLAB R2023a fracture-mechanics developer and scientific assistant to the investigator. This project now maintains a **canonical Ukrainian Microsoft Word research report**. Each scientific packet must include our consolidated corrections and review decisions, with Ukrainian text in every figure, not just a Markdown manuscript.

## Scientific status and source

The last qualified physical/numerical state is [draft PR #41](https://github.com/mfs9697/NewMetacomp/pull/41), `92636e583e34f76e1eaafeda36de530c0c2f8655`. It contains independent two-step MTS trajectories for homogeneous H and perfectly bonded soft/stiff annuli. The S2 direct/path/total G ratios are:
- soft c=0.5: `R_direct=1.021813`, `R_path=0.998826`, `R_total=1.020614`;
- stiff c=2: `R_direct=0.970687`, `R_path=1.000813`, `R_total=0.971476`.
- S2 material-path tip displacement relative to H: soft left +0.09050 mm, stiff right −0.06022 mm.
Those are **actual previous results**, not G2-M4 results. G2-M3 checked an alternative mesh **at its already-selected final material paths**, not full newly propagated paths. Primary uncertainty resolves the measured small energy changes; the conservative ~±3.5% rule resolves none.

Read `G2_M3_RESULTS.md`, `G2_M3_TRAJECTORY_POLICY_v1.json`, `G2_M3_PREREGISTRATION.md`, `G2_M2_SHIELDING_STEERING_RESULTS.md`, `G2_MATERIAL_CONTRAST_RESULTS.md`, `g2_m3_trajectory_run.m`, `g2_material_phase_map.m`, `g2_material_phase_verify.m`, `g2_material_phase_stage.m`, `g2_t6_elasticity_phase.m`, `g2_material_sif_on_mesh.m`, and the original WP2 S0 straight-crack mesh generator. Pin their SHA and full run manifests; read-only operations first.

**Git branch:** Use the editorial/source-qualified [draft PR #43](https://github.com/mfs9697/NewMetacomp/pull/43) as the parent for this research assignment, because it contains the **mandatory Ukrainian Word-report protocol**, itself based directly on PR #41. The scientific assignment is prepared in the subsequent documentation-only brief branch `research/g2-m4-mechanism-attribution-brief-20261121`; create any **new implementation branch and draft PR stacked on this brief head**. Neither PR #41 nor #43 nor any historical PR/chain/policy/main is to be modified/merged.

**Canonical report handoff:** Latest user-visible Word planning draft `Metakompozyt_G2_Naukovyi_zvit_UA_v0_2_G2M4_plan.docx`, 19 pages, 10 Ukrainian figures (including a clearly labeled *schematic*, not a MATLAB output), 13 tables, SHA-256 `637e5f87c969ce918f20e4bf8d0720b314ba94909b1e07b1ff54e5b57d61788e`. This DOCX is downloadable from ChatGPT but **NOT currently in GitHub**. The investigator must put the actual file into the local `reports/G2/`; SHA-verify before use. If absent, log `HOLD_WORD_INPUT` and do not invent it. The earlier v0.1 SHA is `85ef072b9be4a6408570e4719aa97be04fa9e014ce589755bb046ca22bf7abc3`.

## G2-M4.0 — source audit and prospective mathematical preregistration (first implementation package)

Before any G2-M4 physical solve, commit separate `G2_M4_POLICY_v1.json` and `G2_M4_PREREGISTRATION.md`. The policy must explicitly distinguish *the full independent path robustness test (A)* and *the factorial ring-attribution pilot (B)*. Stage B defaults to **NOT AUTHORIZED**, requiring separate researcher approval after A's consolidated review. Register exact branch/policy/source Sha256, material library, original BVP and elastic constants, full q/phase/edge requirements, min resources, negative tests, two uncertainty rules, full-path resolution tolerances, deterministic replay and all stage STOP codes. Default controller dry mode creates NO files. Use 2023a/PDE Toolbox, 5 GiB RAM, 40k T3, min angle 20°, ratio≤1.8, exact p010/collar/64+64 and five q contours; never relax them.

**First real investigation:** inspect and qualify how to generate an independent *alternative S0 straight-crack mesh*. The original alternative G2-M2/3 mesh work mostly used kinked mesh generators. A final-state-only remesh DOES NOT satisfy G2-M4.A. Check the actual WP2 generation calls; if any missing builder, input, or conforming alternate hole-ring polygon fail, record `HOLD_ALT_S0`. No implicit change of physical geometry, source crack length, load or field material. Rebuilding S0 at a 112-sided polygon slightly modifies polygonal geometric area: report and control this approximation, never claim an identical discrete geometry if it differs. Any alternative path result must be obtained by recomputing S0 K on that actual alternative mesh, not reusing original K or origin policy tokens.

## G2-M4.A — full-history numerical trajectory robustness

**Only when M4.0 prerequisites pass**, generate a second, independent mesh family from S0 for H, Msoft and Mstiff. For each of the three materials, recompute S0 signed EDI/COD K; use own S0 K to append full-precision first 4mm segment; generate independent M1 protected T6 mesh, perform 34/34 audit, conforming annuli and q matrix-only controls, fresh phase-aware FEM, blind COD then five-annulus Williams EDI/J. Use own M1 signed K to append second full-precision 4mm segment and repeat all mesh/phase/FEM/SIF gates for M2. Limit to `s≤33.4 mm` and **two steps per path**. H's alternate path is NEW and serves as the alternate reference; original H path stays immutable. Use new policy-bound ROOT/REVIEW-before-STATE chains with source, parent, geometry and active material hashes, adversarial forgery and restart controls. When the alternative s=0 mesh cannot meet original gates, STOP, don't patch older baselines.

**Targeted test:** compare original vs independently regenerated alternative trajectories at 25.4/29.4/33.4mm: coordinates, signed lateral separation (defined in a common H-reference frame), global terminal tangent, local signed KII/KI, G and `R_direct`, `R_path`, `R_total` computed consistently *within each mesh family*. Resolution of difference should be judged with prospectively declared absolute and relative tolerances, acknowledging source S0 K precision; original H S1 six-digit seed offset ≈4.4e−6mm. Preserve the main paired-estimator and conservative error classifications, and separately account for different 76/112-gon band areas. Report if path offsets are stable, marginal or nonrobust. Endpoint-only G stability is insufficient.

**REVIEW STOP:** Submit one consolidated scientific review packet with real plots/tables, all HOLD failures, uncertainty, exact SHA/commit, and proposed revised **Ukrainian Word** chapter/figures. Our correction workflow `G2-REV-###` then occurs. Do NOT automatically begin G2-M4.B from an A success; the researcher/ChatGPT explicitly authorize or defer B. No per-sentence approvals, only whole-stage scientific review.

## G2-M4.B — eight fixed-geometry architectures for each contrast

After explicit authorization **only**, on accepted frozen **homogeneous State 2** (never material-specific geometry), use physical ring identity `PM.annulusOf` from the validated flood-fill map. There are 3 rings (1 near/lower hole, 2 middle, 3 far/upper). Each is a polygonal physical annulus in the computational material, while its center hole stays void. Its contrast can be active (`E_ring/E_matrix=c`) or inactive (`E_ring/E_matrix=1`). Evaluate the complete small `2^3` family `S={∅,1,2,3,12,13,23,123}` for each `c=0.5` and `c=2.0`. Source-lock the same crack mesh, 1 N load, hole geometry and all DOFs for the eight cases. No new crack growth during attribution.

**Critical code-architecture instruction:**
- Existing `g2_material_phase_verify` and `g2_material_sif_on_mesh` assume **all three** rings represent active material contrast. Switching one off can produce a physically passive mesh guide and make their old interface force tests inappropriate. Do NOT modify, weaken, or bypass these previously qualified tests to force PASS.
- First run existing *canonical all-annuli topology* mapper/verifier on the original saved mesh. Then implement a **new tested per-ring constitutive ownership mask** and independent geometrical hole-ID/mask verification that checks every element, the exact active volumes, real shared T6 DOFs, all void exclusions and unchanged q support. For active vs inactive interfaces, distinguish actual material jump from a passive geometric face; require correctly formulated global equilibrium/interface resultants, not misleading per-phase forces at an equal-modulus internal subdivision. Reuse the qualified T6 material assembly where valid; create separate, independently validated phase-aware extraction / interface-check code for these subsets. No hardcoded centroid-only regional assignment.
- **Controls:** `S=∅` reproduces frozen H1 bitwise at the same mesh; `S=123` reproduces verified PR #38 soft or stiff complete results to a preregistered tight tolerance; 2-phase analytical benchmark remains pinned, negative mutation controls and genuine MATLAB 2023a replay. Stop when any source/mesh/topology/SIF/COD/EDI/J/checkpoint gate fails. Report component-wise sign uncertainty for very small KII and all five q annuli entirely in the unchanged matrix.

On identical S2 reference Γ_H, define `F_G(S)=G(S)/G(∅)−1` and `F_theta(S)=θ_MTS(S)−θ_MTS(∅)` (same LOCAL terminal frame), and compliance `C(S)`. Record signed KI,KII, energy, COD/EDI/J, band active area volume and near/far distance. For **each** observable `F` (G and theta independently), compute
- main ring values `f_i=F({i})`;
- pair interactions `I_ij=F({i,j})−f_i−f_j`;
- triple interaction `I_123=F({1,2,3})−Σ f_i−Σ I_ij`;
- exact reconstruction `F(123)=Σ f_i+Σ I_ij+I_123`;
- optional Shapley averages of ring marginal contributions over all six orders, which sum to `F(123)`. Shapley is **allocation** of model response, not a proven physical mechanism in isolation.

Declare numerical uncertainty for the small interaction terms; apply both inherited primary and conservative rules to material effects and perturbations rather than just round them to six digits. Compare subsets with equal number of active bands to control nominal active reinforcement volume. A single-ring model is not the same reinforcement volume as a three-ring model. Attributing *physical causality* to a hole may require additional elastic field examination; describe these as counterfactual contributions conditional on fixed mesh/BVP.

**REVIEW STOP B:** deliver a whole-science package and updated Ukrainian Word with all eight architecture diagrams and real plots (every axis/legend/title/caption in Ukrainian), complete corrections and failed-run evidence. Only after investigator/ChatGPT approval should a new distinct design-screening / mixed c∈{1,0.5,2}^3 / further-propagation issue be proposed. Do NOT automatically run 27 mixed-material candidates or State 3 under M4.

## Writing, evidence and final reporting

Follow `reports/G2/REPORT_PROTOCOL_UA.md` and `reports/G2/CLAUDE_WORD_REPORT_PROMPT_ISSUE42.md`. Preserve all source results and accepted MATLAB chains. Each actual packet has:
1. versioned preregistration/policy, original and current source SHA, exact MATLAB command, failed attempt logs, fault tests and timing;
2. **one consolidated review draft** with hypotheses, stepwise model equations, detailed method of signed KI,KII via independent COD and Williams auxiliary-field EDI, J check, material interface controls and uncertainty;
3. recorded investigator/ChatGPT corrections under `G2-REV-###` with reason, code/formula/text before+after, post-fix rerun evidence, and GO/HOLD;
4. **native .docx**, not just Markdown/PDF: all text and figure labels in Ukrainian, numbered tables/figures, real source provenance, old versions archived, SHA-256 of new report, page-by-page PNG render inspection and a revision log. A schematic figure must explicitly say “Схематично”, not pretend to be MATLAB data.

Final outputs belong in separate `outputs/g2_m4_*/run_*/` roots plus an evidence folder/ledger and new draft PR(s). Include the baseline full-precision SIF conversions (raw MPa√mm at 1 N vs reported MPa√m per kN, J and G in N/mm or J/m²), current 0.88% EDI/COD method offset and both uncertainty rules. No hidden changes in old PR #41, #43, original homogeneous/material chains or old source policies.

**Start now with M4.0 only:** source and Word report presence check, exact alternate S0 feasibility, preregistration/policy draft and a single consolidated proposed review. Then perform M4.A only after meeting explicit preregistration and authorization gates. **Do not initiate M4.B or design optimization until the scientist's next decision.** Stop on any failed verification; no invented numbers or physical fracture claims.
