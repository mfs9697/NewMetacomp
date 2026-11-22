# Claude Code execution prompt — G2-LP0/LP1, Issue #52

You are acting as the MATLAB R2023a research implementation engineer for the NewMetacomp fracture-mechanics study. The scientific investigator and ChatGPT have **authorized a limited LP0 feasibility + conditional LP1 pilot only**. The work is **not** a request to calculate full-length crack paths at this time.

### Required reading, before coding

1. **Issue #52** (normative assignment): https://github.com/mfs9697/NewMetacomp/issues/52
2. **Scientific design file, on this docs-only branch:** \`docs/research/crack-growth-gaps-2026/G2_LP0_LP1_MATRIX_ONLY_PATHS_SCIENTIFIC_DESIGN.md\`
3. **R1 review:** https://github.com/mfs9697/NewMetacomp/issues/50#issuecomment-7077407079
4. **Parent evidence:** draft PR #51, accepted scoped verdict \`R1_PLACEMENT_STABLE\`, pinned head \`6699c544bbdb99d26a89a647f79b868a5488a96a\`; inspect its source and all linked M4.B, M4.A, M3 and WP3 records.

**Starting branch for your implementation:** \`research/g2-lp0-lp1-guarded-paths-brief-20261122\` (the new docs-only assignment draft PR is stacked directly on PR #51). Verify its exact HEAD and parent before writing; create **one distinct implementation branch and DRAFT PR stacked on the assignment PR**. Do not modify the assignment PR or previous PRs, even when convenient.

## A. Precise scientific objective

Compute four **independently evolving conditional LEFM/MTS** trajectories while the crack tip and the entire proposed increment remain **in the matrix**, with no annulus intersection, true-hole penetration, external-boundary crossing or illegal self-intersection:

| Case ID | Active rings | Active E/E_m |
|---|---|---|
| \`H\` | none | all E_m |
| \`stiff13\` | 1 and 3 | 2.0 |
| \`soft2\` | 2 | 0.5 |
| \`soft1\` | 1 | 0.5 |

The three rings are centred at (152.4,69.85), (152.4,120.65), (152.4,171.45) mm, inner/outer radii 6.35/19.05 mm. Preserve the original Cornell plane-stress plate 508×203.2 mm, E_m=3268.115 MPa, ν=0.35, thickness=12.7mm, point load P=1N, pin/roller locations and top/bottom edges, all per qualified source policy. Inactive annuli remain geometrically meshed but have matrix material; no voids are filled and all interfaces stay perfectly bonded. Report an approach/crossing of a *nominal inactive ring* as a model-scope geometric event, not real physical interface fracture.

**No physical crack onset or stability is asserted.** MTS indicates a conditional direction if a crack is forced to advance by 4mm; no \`G_c\`, cohesive law or interface toughness has been supplied.

## B. Non-negotiable numerical sequence

### LP0 — inventory, prospective preregistration, mesh-only feasibility

**B0.1. Inspect and pin the exact source.** Inventory all MATLAB code, old policies, original WP2 S0 mesh, WP3 S1/S2 homogeneous path records, M3/M4.A material-path controllers, M4.B ring-owner oracle/activation/partial SIF, R1 matched-family verification. Specifically inspect and understand:
\`\`\`
matlab/g2/g2_kinked_join.m
matlab/g2/g2_kinked_regular_block.m
matlab/g2/g2_kinked_exterior_mesh.m
matlab/g2/g2_kink_admissibility.m
matlab/g2/g2_kinked_mesh_auditor.m
matlab/g2/g2_m4a_trajectory_run.m
matlab/g2/g2_m4a_s0alt.m
matlab/g2/g2_m4b_ring_owner_oracle.m
matlab/g2/g2_m4b_ring_activation.m
matlab/g2/g2_m4b_activation_verify.m
matlab/g2/g2_m4b_sif_partial.m
matlab/g2/g2_mts_direction.m
matlab/g2/g2_sif_interaction.m
matlab/g2/g2_sif_cod_banks.m
matlab/g2/G2_M3_TRAJECTORY_POLICY_v1.json
matlab/g2/G2_M4_POLICY_v1.json
matlab/g2/G2_M4B_POLICY_v2.json
matlab/g2/G2_M4B_R1_POLICY_v1.json
\`\`\`
Inspect the actual saved MAT/ledger and hash each source. Verify that all accepted historical inputs and baseline results are present. Do NOT invent lost files or change their SHA expectations.

**B0.2. Versioned policy BEFORE any LP1 FEM.** Create and commit:
\`\`\`
matlab/g2/G2_LP1_POLICY_v1.json
matlab/g2/G2_LP1_PREREGISTRATION.md
matlab/g2/G2_LP0_FEASIBILITY.md
\`\`\`
The policy must include immutable source SHA256s, expected geometry/BVP, each architecture mask and contrast, a fixed count of **four** paths and maxStateIndex **4**, max arc length **41.4 mm**, step=4mm, S0 initial polyline, inherited quality/SIF gates, a deterministic source+policy+geometry+case+cap token, complete accept/HOLD criteria, resource limits, negative controls, baseline reproduction thresholds, original q support definition and anticipated output schema. It must not modify the old policies or relax any numerical gate after results are observed. Dry mode writes NOTHING. All actual solves require a committed, clean source tree and authorized explicit token.

**B0.3. Verify geometry builder feasibility BEFORE launching four chains.** The existing \`g2_kink_admissibility\` has \`ExpectedVertices=3\` by default; \`g2_kinked_join\`, its block and exterior builders accept explicit \`ExpectedVertices\`. Whether the vendor p010 kernel, collapsed channel, notch-bank miter and independent auditor **actually work** with 5 or 6 polyline vertices has **not yet been established**. Build synthetic kinked \`N=5,6\` meshes *in memory, geometry-only*, using \`ExpectedVertices=N\` as appropriate, and perform original independent saved-array audits. Synthetic test polylines must have truthful labels \`MESH_ONLY_SYNTHETIC\`, never \`trajectory\`. Audit split banks, twin nodes, tip core 2788, collar 128, seams, q active parents 2443, 34/34, T3 budget≤40000, minAngle≥20°, neighbor ratio≤1.8 and material ring topology. If the existing builder fails, perform a source-scoped diagnosis and **HOLD_LP0_FEASIBILITY**; propose a new versioned meshing module only after the researcher reviews the change. No “fix” by weakening the accepted geometry/quality rules.

**B0.4. Introduce an independent robust segment clearance oracle**, run against synthetic cases and mutation negatives, with *continuous segment-to-polygon intersection* rather than endpoint-only distance. The entire new segment and tip guide/q domains must be checked against all three annulus outer interfaces, true hole walls, prior crack segments, all four external plate sides. Separate geometric observables:
- tip-to-each ring wall and to nearest true hole wall;
- whole new segment-to-each annulus/hole/boundary;
- full tip guide radius **15 mm** and collar/core geometric domains;
- all five q-annulus supports to the ring-owner field, with outer nominal q radius **2.6 mm**, strict matrix-only ownership;
- clearance of crack-bank channel, miter and tip rim from earlier segments;
- near-external-boundary termination capability.

Test an illegal proposed segment whose endpoints are outside but whose interior crosses an interface; boundary grazing, q-only overlap, self-intersection, altered ring ID, geometry drift and masked passive-ring crossing must be rejected by the intended control. Never treat a nominal passive boundary as physical fracture, but preserve the strict common geometric run domain for these four comparisons.

**B0.5. Resource/preflight:** genuine MATLAB R2023a+PDE Toolbox, one MATLAB process, >=5 GiB of free physical RAM (do not lower the guard); no hidden MATLAB runs in dry mode; unchanged source tree; deterministic UTF-8/LF SHA; no touching old run folders. Prior R1 had two environmental \`HOLD_MEMORY\` dry runs; preserving the guard is more important than a fast answer.

**LP0 Gate:** provide one consolidated feasible/HOLD verdict per architecture, list all variable-vertex-count problems, describe the limited meaning of extrapolated future proximity, and either proceed with bounded LP1 under the committed policy or **STOP**. You may not replace a failed feasibility test with a different geometry or mesh without preregistering it.

### LP1 — conditional pilot after LP0 qualification

**Path origin: S0, not S2.** For all four material distributions build or SHA-verify the original *common* S0 crack mesh (arclength **25.4 mm**) and **independently solve the material-specific S0 elasticity problem**. Extract each S0's own full-precision signed \`K_I,K_{II}\` (EDI, blind-bank COD, J) in its own local tip frame; record source MAT+SHA.

Recompute the local MTS root from \`g2_mts_direction\` at EVERY parent state, then conditionally move the tip \`4mm\` and **build a newly qualified mesh from the full case-specific crack polyline**:

\`\`\`
S0  s=25.4 mm   own K per case, common starting crack
S1  s=29.4 mm   1st prescribed increment, own path
S2  s=33.4 mm   2nd prescribed increment, own path
S3  s=37.4 mm   3rd increment, NEW and only if all gates pass
S4  s=41.4 mm   4th increment, NEW and FINAL LP1 cap
\`\`\`

All 4-mm increments must use **full precision**, signed modes and the inherited tensile branch. H must reproduce accepted H S1/S2 before *new states* can be admitted; set exact bytewise/numerical regression rules prospectively. Each candidate's own S2 is **not** the frozen homogeneous S2 of M4.B/R1. Reusing the M4.B/R1 S2 K, solution, mask or saved geometry as a path state is forbidden.

At each state, block advancement until checks pass: immutable parent/mesh SHA; exact material mask and independent ring IDs; phase/geometry audit; complete proposed segment clearance; tip-guide and q-domain matrix-only; COD bank twins and normal-opening; EDI signed KI/KII over five registered q rings, independent COD, 4×4 vs 6×6 EDI, J identity, equilibrium/positive-definite stiffness and energy; material balance across active rings, mixed-mode MTS root and new tangent; unchanged 1N force/thickness/unit conversion; valid T3 count and quality.

Do NOT pass just an endpoint-clearance gate. Do NOT alter old lower-level geometry/SIF routines merely to accommodate step 3/4; use separately named, independently audited wrappers/new controllers while preserving old SHA. If an existing module cannot handle variable length consistently, **HOLD**, document and request an isolated new-qualified implementation rather than weakening the gate.

**Absolute hard caps:** no \`S5\`; no \`MaxStateIndex>4\`; no \`s>41.4mm\`; no dynamic custom adaptive step or different q radius without a new prospective policy and scientist permission; no membrane-interface crossing regardless of active/passive modulus; no remeshing beyond accepted qualification and new policy.

**Required STOP taxonomy** (document exact cause and saved evidence):
\`\`\`
MATRIX_ADVANCE
HOLD_LP0_FEASIBILITY
HOLD_INPUT
HOLD_INTERFACE_APPROACH
HOLD_Q_PHASE
HOLD_TIP_GUIDE
HOLD_CRACK_SELF_INTERSECTION
HOLD_EXTERNAL_BOUNDARY
HOLD_MESH_QUALITY
HOLD_K_EXTRACTION
HOLD_OWNER_MASK
HOLD_POLICY_DRIFT
HOLD_SOURCE
HOLD_MEMORY
HOLD_RECORD_INTEGRITY
HOLD_UNAUTHORIZED_STATE
\`\`\`
It is valid to stop early. **HOLD is a numerical/model-scope limitation, never proof of crack arrest.**

## C. Scientific analyses and uncertainties

At each accepted state report all x-y vertices (mm), cumulative arclength, unit tangent and local normal, signed \`K_I,K_{II}\` in MPa√m per kN, \`J,G\` at the 1N reference load, COD/EDI/J cross-checks and mode mix, signed local MTS angle and global tangent, compliance (point-load sensitive), force and per-ring energy, active area, and **geometric margins for guide/q/entire segment**. Keep \`U_primary\` (same-mesh estimator agreement), \`U_cons\`, and prior observed family drift clearly separate. Do not call either estimator a proven upper bound on future tip-remeshing error.

At matched arclength \`s\`, use H's local normal to calculate signed lateral offsets of each material-specific tip from homogeneous H, Euclidean tip separation, and relative G where independently comparable. Do not introduce or apply \`R_path/R_total\` decomposition unless the compared definitions are explicitly written and verified for different polylines; physical interpretation stays conditional.

**Specific scientific questions for the review:** Are the initial differences seen on frozen S2 reflected in S0→S4 paths? Does the soft1 turn progressively away from rings? Does stiff13 move toward a nominal ring despite shielding at frozen S2? Is soft2 merely a modestly steered case, or does its actual predicted path lead elsewhere? Null, reversed and numerically unresolved observations are equally acceptable.

## D. Provenance, negative controls, plots and Ukrainian Word handoff

- One new versioned run root \`outputs/g2_lp1_matrix_paths_v1/run_*/\` (or independent immutable per-case roots beneath it); source SHA ledger, policy SHA, full parent and next-state hashes, immutable MATS, failed HOLD snapshots, clear dry-run log. Distinguish a committed file SHA from Git working-tree line endings. Fault suite must include altered parent KI/KII, wrong activity mask, illegal segment tunnel, forged q clearance, source drift, S5 request, replay/interrupt, low RAM, dirty source and file-tamper. Replay must not re-solve verified prior cases.
- Separate canonical \`matlab/g2/G2_LP1_RESULTS.md\`, \`G2_LP1_RUNLOG.md\` and machine-readable per-state CSV/JSON + source references, with true full-precision numbers and no invented trajectories.
- **Figures:** print-friendly monotonic greyscale; line styles/markers distinguish all 4 paths, ring circles/hole voids are physically positioned and to scale, true axes/aspect, full x-y path geometry, \`G\`, signed K and angles vs arclength, tip/whole-segment/guide/q clearance and labeled STOP events. Any saved-result stress maps must use proper matched common limits, logarithmic vs signed relative quantity labels and a clear zero contour; avoid the known zero-contour-at-bottom plotting artifact in PR #51 or clearly flag it. **Every word inside every new figure, legend, caption and axis must be Ukrainian.**
- **Word/report is a parallel editorial task:** Issue #53 owns canonical Ukrainian Word v0.4.1. Do not independently rebuild or replace v0.3 or candidate v0.4 in this LP1 PR. Prepare insertion-ready Ukrainian scientific paragraphs, numbered tables/captions, a source-register and a new editable native Ukrainian DOCX proposal if useful, with rendered page checks. Future integration into a consolidated Word edition requires scientist review. Preserve the existing report's EDI/COD/J/MTS derivations and all review corrections.
- **Review:** one draft implementation PR stacked on this docs-only assignment branch. Deliver ONE coherent evidence packet with pass/fail details, failures/negative controls and methodological limitations, and STOP at \`REVIEW_STOP_LP1\`. The results are not accepted just because tests pass; physical interpretations await scientist+ChatGPT review.

## E. Explicitly forbidden

- No fully traversing crack to opposite free surface (LP2) under this assignment.
- No post-S4 step, speculative terminal break-through or treating inability to mesh near the boundary as physical arrest.
- No interface penetration, debonding, kinking off interface, cohesive-zone or phase-field fracture model.
- No fracture toughness or \`G_c\` fitted from these numerical results, no load-controlled stable-growth interpretation, no experimental-Cornell fit.
- No M4.C, full 3³ mixed architectures, parameter optimisation, unbounded mesh campaign, lowering RAM or SIF gates, or silent retry after a scientific HOLD.
- No edits/merges to previous PRs (#38/#41/#43/#45/#46/#48/#49/#51), original source/policies, v0.3/v0.4 Word files.

**Return to the investigator:** draft PR URL, branch/head SHA, policy SHA, all 4 architecture chains through last qualified state, source and replay/negative-test results, per-step signed SIF/energy/path/clearance data, Ukrainian greyscale figure bundle, Word handoff status and all limitations. If blocked during LP0, return a fully documented HOLD without trying to force the science forward.

**Terminal state: \`REVIEW_STOP_LP1\` (or a documented preregistered HOLD).**
