# G2-LP0/LP1 — Scientific design for conditional matrix-confined crack trajectories

**Document status:** Scientific assignment; no LP0/LP1 calculations have been performed by this document. **Authoritative issue:** [#52](https://github.com/mfs9697/NewMetacomp/issues/52). **Accepted source:** [R1 draft PR #51](https://github.com/mfs9697/NewMetacomp/pull/51), head \`6699c544bbdb99d26a89a647f79b868a5488a96a\`. **Research review:** [Issue #50 decision](https://github.com/mfs9697/NewMetacomp/issues/50#issuecomment-7077407079). **Editorial work is separate:** [Issue #53](https://github.com/mfs9697/NewMetacomp/issues/53).

## 1. Scientific problem: from frozen-tip attribution to actual numerical path geometry

The accepted G2-M4.B and R1 results show that, for a **fixed, homogeneous S2 crack**, the sign and magnitude of the direct elastic influence of an annulus depend strongly on its location. The seven targeted effects retain sign and rankings under the qualified 76-/112-chord ring/exterior comparison. In R1, however, the p010 near-tip region, collar and q-support remained shared across mesh families. These observations do **not** establish the shape of any long, individually propagated crack.

**LP0/LP1 question:** When each material architecture is allowed to influence the incremental MTS direction at *each* new crack tip, do the initial differences in local steering accumulate, cancel or change sign along a growing **matrix-confined** crack? Can a prospective geometric clearance test discriminate pathways that remain away from nominal rings from pathways tending towards the first interface?

This is a **conditional LEFM/MTS kinematic computation**, not a fracture-onset law. Without resistance \`G_c\`, load-path stability, interface toughness or cohesive kinetics, the program cannot prove that a crack actually grows, stops, penetrates, debonds or fully separates the plate.

## 2. Four contrasting prescribed material distributions

Use the same true 3-hole Cornell specimen and pinned BVP as the accepted work:

- Plate: 508 × 203.2 mm; holes centred \`(152.4,69.85)\`, \`(152.4,120.65)\`, \`(152.4,171.45)\` mm; hole radius 6.35 mm; outer annulus radius 19.05 mm.
- Plane stress, matrix \`E_m=3268.115 MPa\`, \`ν_m=ν_r=0.35\`, thickness 12.7 mm. One applied downward 1 N force at \`(254,203.2)\` mm; pin \`(25.4,0)\`, roller \`(482.6,0)\` mm.
- Perfectly bonded shared-node T6 kinematics; inactive annuli have matrix material; voids remain empty. Even when a ring is inactive, retain its **nominal annulus geometry** in clearances and mesh ownership. A crossing of a nominal passive boundary is a **geometric model-scope event**, not physical interface debonding.

| ID | Material distribution | Frozen-S2 observation, NOT a trajectory forecast |
|---|---|---|
| \`H\` | All annuli inactive (\`E_r=E_m\`) | Homogeneous reference |
| \`stiff13\` | Only rings 1 and 3 active, \`E_r=2 E_m\` | \`F_G≈−5.48%\`, \`F_θ≈−0.81°\`, forecasts toward ring side at S2 |
| \`soft2\` | Only ring 2 active, \`E_r=0.5 E_m\` | \`F_G≈−3.63%\`, \`F_θ≈−0.37°\`; NOT a known bypass |
| \`soft1\` | Only ring 1 active, \`E_r=0.5 E_m\` | \`F_G≈+4.43%\`, \`F_θ≈+1.31°\`; forecasts away from ring side at S2 |

These cases do **not** have identical amounts of reinforcement and must not be ranked as equal-cost optimal designs. The signs of \`F_theta\` above refer to the **frozen S2 terminal frame only**. In LP1, all angles must be recomputed locally at the new tip; the archived frozen S2 cannot seed a new case.

## 3. Geometry, steps, reference validation

Initial unpropagated cracked mesh: \`S0: s=25.4mm\`, crack polyline \`[(101.6,0);(101.6,25.4)]\` mm. Each case has the same initial geometric crack but its **own S0 FEM solution**, signed \`K_I,K_II\`, q-EDI/J, blind bank COD and MTS predictor. In each subsequent step:

\[
\theta_k = 2 \arctan\!\frac{-2K_{II,k}}{K_{I,k}+\sqrt{K_{I,k}^2+8K_{II,k}^2}},
\qquad
\mathbf t_{k+1}=\cos\theta_k\,\mathbf t_k+\sin\theta_k\,\mathbf n_k,
\qquad
\mathbf x_{k+1}=\mathbf x_k+4\,\mathbf t_{k+1}\ {\rm mm}.
\]

The expression is equivalent to the accepted signed MTS formula in \`g2_mts_direction.m\`; use its implementation and **do not substitute a different sign convention**. Every accepted increment uses a newly built full, conforming T6 mesh on the resulting case-specific polyline and a new FEM solve.

| State | Arclength | Role | Required behavior |
|---|---:|---|---|
| S0 | 25.4 mm | start | solve independently for H, stiff13, soft2 and soft1 |
| S1 | 29.4 mm | reference step 1 | independently recompute, complete checks |
| S2 | 33.4 mm | reference step 2 | H must regress to accepted WP3 path; material configurations have their OWN S2 paths |
| S3 | 37.4 mm | **new** step 3 | only after all LP0/LP1 preliminary gates pass |
| S4 | 41.4 mm | **new** step 4 | hard final cap; never attempt S5 in LP1 |

The LP1 limit is **four conditional 4-mm increments from S0, no more**. One state failing its gate terminates that case and is preserved as a model/numerical HOLD, without fabricated later points.

The old WP3 \`g2_kink_admissibility\` uses an explicit \`ExpectedVertices\` input (default 3) and \`g2_kinked_join\` forwards it through the regular-block/exterior builders. This is **not evidence that four increments work**. LP0 must test whether arbitrary \`N=5,6\` polyline vertices, vendor p010 kernel creation, miter offsets, full crack-bank pairing and 40,000-T3 budget remain valid, while not weakening or editing legacy functions. Generalizations, when required, are new and prospectively checked, not casual modifications of qualified gates.

## 4. LP0 preregistration and geometry-only feasibility

Required in order:

1. Read source PR #51, the full Issue #52, original S0 and WP3 references, M3/M4.A path chains, M4.B active-ring/owner oracle, and R1 matched S2alt audit. Record exact **full SHAs**; if pinned outputs are absent, **HOLD_INPUT** rather than fabricate replacement.
2. Create implementation branch stacked on the **docs-only assignment PR**, itself stacked on #51. First commit a versioned \`G2_LP1_POLICY_v1.json\`, \`G2_LP1_PREREGISTRATION.md\`, source-lock and tests **before any LP1 FEM solve**; historical policies and results remain unmodified. Explicitly retain original 76-chord ring geometry and chosen mesh family unless a separately qualified policy states otherwise.
3. Run read-only/geometry-only feasibility of S0 and representative kinked **S3/S4-like** polylines, including each of the four masks. Those candidate polylines are labelled *synthetic mesh-feasibility probes*, **not** computed crack paths. Verify allowable variable vertex count, geometric and topology audits, and physically meaningful clearances. Never print a synthetic path as a result.
4. A conservative **continuous segment-to-boundary test** must check each proposed segment against three polygonal annular boundaries, three holes, the prior crack polyline and all plate sides, not just endpoint distance. The negative-control library includes segment crossing even when both endpoints lie outside a ring, crack self-intersection, close-to-guide approach, subthreshold q clearance, false homogeneous material labels and illegal endpoint outside the plate.
5. The protected tip's **15-mm guide** and full \`q\` extraction support (maximum nominal radius 2.6 mm) must remain strictly in admissible matrix. A tip approaching a ring or boundary may trigger a numerical HOLD well before it physically touches the material interface. Quantify clearance margins separately for **tip centre**, full tip guide, q support, and each *whole proposed segment*; do not equate them.
6. Register the S1/S2 H-regression method to original accepted H path, exact full-precision polyline and K, plus separately recomputed S0 K for every case and independent material map checks **at every new mesh**. Do not copy M4.B S2 masks, displacement or K to a newly moved tip.
7. Define numerical thresholds, complete STOP taxonomy, first-case order, memory guard ≥5GiB, genuine MATLAB R2023a+PDE, no-writing dry mode, source/baseline SHA and deterministic replay **before reading new results**.

LP0 is a **mesher-and-proof feasibility stage**, not the place to run unregistered FEM. If every gate cannot pass, create \`HOLD_LP0_FEASIBILITY\` with a concrete violated constraint, preserve records and **do not run LP1**.

## 5. LP1 independent path pilot

After a qualified LP0, run all four case-specific trajectories under the new policy, with:

- Pre-step geometric forecast from each new parent \`K_I,K_{II}\`, valid tensile MTS root and exact \`Δa=4 mm\`; ineligible regimes are HOLD.
- Per-state independently rebuilt protected tip/collar/exterior T3→T6; original saved-array auditor **34/34** for kinked states, qualified phase topology, independent ring identity/mask verification, SPD elasticity, correct shared-node interfaces, no crossing/broken crack-bank twin nodes.
- Signed \`K_I,K_{II}\` by five-q-annulus EDI, independent COD on near-tip crack banks, \`J=(K_I^2+K_{II}^2)/E'\` in matrix (plane stress), quadrature and reaction/energy balance, full units. Check **every** q support element (including all T6 nodes) has \`ownerRing=0\`. Signed MTS direction must be recorded relative to the current tangent, in addition to global orientation.
- Reproduce H to accepted H S1/S2 (bitwise only if the same floating-point path applies; otherwise prespecify exact tolerance and document cause; **never loosen after results**). Material-specific S1/S2 are conditional independent paths and should not be forced to frozen-S2 results.
- At most S3 and S4 new states beyond S2. Do not automatically adjust the step size; any smaller step or different mesher would be a **new policy and scientific decision** unless explicitly preregistered and properly qualified beforehand.
- Separate immutable chain root for each architecture, parent SHA and full mesh/solution/phase provenance, fault injections for wrong parent K, wrong activity mask, forged saved state, q crossing, segment tunnelling, unauthorized S5, source drift, memory guard and interrupted-record resume/replay.
- Treat unresolved numerical discrepancies (especially q-vs-COD and low \`K_{II}\`) conservatively. Report \`U_primary\` (same-mesh estimator consistency), \`U_cons\` and **observed** R1 cross-family effect drift as *different* quantities. R1 did **not** bound all future path errors.

No preference for dramatic path separation: agreement, indistinguishability or a HOLD are admissible scientific outcomes.

## 6. Required consolidated review, visualization and future questions

One reproducible research packet at \`REVIEW_STOP_LP1\` should include:

- Full signed x-y crack polylines (mm), tangent, arclength, step-specific \`K_I,K_{II}\`, \`J,G\`, mode mix, MTS turn, q/COD/EDI checks, distance to each ring wall, tip-guide and q admissible margins, external-boundary margins, phase/energy/reactive loads, and clear per-case status.
- Comparison of each conditional material path to H at **matched arclength**, with signed lateral offset \`(x_M-x_H)\cdot n_H\`, tip separation, and direct/path decomposition only if the comparison definitions remain valid and independently qualified. Avoid extrapolating frozen-S2 relative effects to new path tips.
- The earliest unresolved constraint expected for **future** long-path continuation: first annular interface, hole wall, finite-element tip guide, q phase support, prior crack self-intersection or upper plate boundary. A predicted earliest failure from geometric extrapolation is a *proposal*, not a computed trajectory.
- Print-ready **greyscale** charts and any useful accepted stress maps with clear zero/sign/line-style conventions, all text within figures and scientific captions **in Ukrainian**. The report itself stays Ukrainian, whereas investigator exchanges and Claude instructions are English. Reuse accepted PR #51 greyscale source assets instead of recomputing old FEM.
- Word handling: do **not** rebuild v0.4/v0.4.1 in this scientific PR; prepare Ukrainian section, tables, source-based figures, updated \`G2-REV\` log and, if useful, a **separate native Ukrainian DOCX proposal**. Consolidation of the canonical v0.4.1 belongs to [Issue #53](https://github.com/mfs9697/NewMetacomp/issues/53), using an editorial-only draft PR.

**Decision after LP1:** whether to authorize a fully separate LP2 campaign, or first develop/qualify a mesh and fracture model for near-interface or external-boundary states. This assignment does not authorize LP2, fracture toughness, physical onset or arrest, interface debonding, CZM, optimization, 27 architecture variations, or mergers of earlier draft PRs.

**Definition of done:** prospectively fixed LP1 policy, authenticated LP0 geometry-only feasibility, four newly solved per-case S0→S2 paths plus at most S3/S4, evidence-checked tests and abort controls, one consolidated scientist packet, **REVIEW_STOP_LP1**. If blocked, deliver an honest **HOLD** and the smallest scientifically defensible proposed correction.
