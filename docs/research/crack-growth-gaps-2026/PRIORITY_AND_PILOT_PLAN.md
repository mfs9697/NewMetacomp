# Priority decision and pre-registered *future* pilot plan
**Stage:** 0; **NO FEM/CZM has been run under Issue #7**. This plan is subject to explicit researcher approval and is not permission to launch computation.

## Decision
- **Primary conditional hypothesis G2:** in a single-phase cementitious plate with **designed perforations** (an analytically manageable *surrogate of architected infrastructure material*, **not** the complete polymer–cement metacomposite), architecture can alter the **pathwise crack-driving force** independently of mere porosity/net-section changes. Directional steering may conflict with shielding.
- **Secondary conditional hypothesis G1:** varying normalized position/spacing of the same perforations induces a *robust transition* between two free-path corridor classes. The novelty would be the **controlled boundary of the transition**, not the existence of deflection or of a single numerical trace.
- **G3** is only an independent MTS–GMTS *diagnostic*, not an asserted primary discovery.
- **G4** is deferred pending new interface FEM/CZM; **G5** is not a novel standalone hinge mechanism (Xu 2020, Xie 2025); **G6** deferred pending transient dynamic fracture validation.

### Closest direct counterexamples
1. [Gao–Liu–Wei, JMPS 2026](https://doi.org/10.1016/j.jmps.2026.106729): architecture-sensitive crack paths and a topology-consistent configurational driving force in discrete lattices.
2. [Li–Liu–Jin–Du, EFM 2026](https://doi.org/10.1016/j.engfracmech.2026.112098): concrete aggregate bypass/penetration transition.
3. [Gupta–Moini, Materials and Structures 2026](https://doi.org/10.1617/s11527-026-03269-0): broad cementitious architected fracture/toughening mechanisms.
4. [Review of Materials Research 2026](https://doi.org/10.1016/j.revmat.2026.100153): crack regulation in lattice metamaterials.
5. [Vandadi et al. 2025](https://doi.org/10.1002/admi.202500095): debonding and kink in printed reinforced concrete.
6. [Huang et al. 2026](https://doi.org/10.1016/j.jobe.2025.115139): controllable reinforcement–cement interface.
7. [Tao–Zhang 2026](https://doi.org/10.1016/j.conbuildmat.2026.146654): mixed-mode ECC interface path control.
8. [Li–Wang 2026](https://doi.org/10.1016/j.compstruct.2026.120474): reduced stress concentrations in polymer-auxetic mortar.
9. [Chen et al. 2024](https://doi.org/10.1016/j.jobe.2024.108999): cross-architecture cementitious tests and FE.
10. [He–Hutchinson 1989](https://doi.org/10.1016/0020-7683(89)90021-8): canonical interface penetration/deflection criterion.

The extra distinguishable question is therefore **not “Can an architecture steer a crack?”** It is: **“At fixed geometric/material loading controls, does a robust free-path corridor transition coincide with amplification or screening of `G(s)` along the physically independently propagated path, and what reproducible geometry thresholds govern it?”** Negative answers are publishable as bounded, corroborated findings if competing literature did not already make the same controlled comparison.

## Two-step pilot funnel (not authorized)

### P0 — literature and model admissibility gate (read-only, now)
Verify full methods for 10 competitors; confirm final signed 2027–28 project version; identify physical mortar class and a measurable small-scale length (FPZ). Decline a sharp crack LEFM pilot if there is no (K)-dominant annulus in the intended ligament/cell size.

### P1 — frozen-crack controls (after research approval only)
**One 2D quasi-static specimen:** edge notch in rectangular **single-phase, isotropic, linear elastic** plate, with simple smooth circular/rounded voids laid out in two candidate bypass corridors. Use **same** `E,ν`, thickness assumption, prescribed remote load, edge-notch origin and size for all cases. Realistic material properties are **not** yet calibrated; old homogeneous `E=4 GPa, ν=.3` values are illustrative method references, not established concrete properties.

Predeclared cases:
- **C0:** intact plate, no voids, reference for `K`, direction and force.
- **C1:** one void with controlled clearance, reference for classical crack–hole interaction.
- **C2a/C2b/C2c:** *same void count and total removed area*, different offset `p` or normalized spacing, chosen as below/near/above an anticipated corridor transition; **do not** assert such a transition before data.
- **C3:** mirror-symmetric geometry as signed-angle and mesh-bias control.
- **C4:** matched net-section and minimum-ligament-width control if differences in C2 can be accounted for by loss of solid section.

First vary *one* architecture parameter `p=d/a_cell` at a time. Report `K_I,K_{II},T` from admissible homogeneous tip annuli, plus `G/G_0` at the **same frozen crack length** and applied traction. Also compare a rounded-feature tensile-stress ROI with a fixed physical exclusion radius. A hole near the tip is **not** permission to integrate across it.

### P2 — independent crack trajectories (after P1 passes and separate approval)
Propagate under **MTS** two or three corridor-distinguishing cases. Independently rebuild each mesh and solve each accepted increment; no frozen prescribed detour as an alleged predicted trajectory. Reserve GMTS independent trajectories for a **separately preregistered** material length `r_c`. Use separate nested studies:
- crack increment `Δa` variations at *fixed qualified near-tip resolution*;
- local `h_{tip}` variations at fixed `Δa`;
- geometry/feature-radius and tiny crack-origin perturbations;
- independent EDI vs blind COD comparison in each qualified homogeneous window.

No automatic branching, void crossing, interface penetration or physical arrest prediction. A prospective collision is a **terminal classification and escalation**.

## Measured responses (all predeclared)
1. **Path:** `Γ(s;p)`, tip coordinates, signed angle `θ(s;p)`; classify corridor A/B with a fixed geometric separating curve and a reproducible stopping crack length. Do not classify by visual inspection only.
2. **Driving force:** `G(s;p)/G_0(s)`, where `G=(K_I²+K_{II}²)/E'` is only used with same elastic phase and matching plane-stress/strain conventions, at matched arc length/load. Plot whole curves, local extrema and sign of `G-G_0`.
3. **Stress penalty:** region-limited `σ_1` normalized to nominal traction, with same physical smoothing radii and excluded singular sets.
4. **Geometry:** minimum tip-to-void clearance, normalized spacing, removed volume and net-section stress concentration controls.
5. **Numerical uncertainty:** mesh, `Δa`, contour stability, EDI/COD disagreements, and perturbation confidence interval.
6. **GMTS support:** on frozen matched paths and independently propagated GMTS paths, `Δθ`, full-path separation, fitted `T`; all conditional on a fixed `r_c`.

## Quantitative decision criteria — provisional, must freeze before runs
- **Mode identification:** at least two non-topologically equivalent corridor classes at a **common** stopping arc length, separated by more than the measured geometry/mesh/step uncertainty; otherwise conclude *no resolved transition*.
- **Threshold:** only report a bracketing **interval** `[p_low,p_high]` with at least one admissible pathway in each class; its width must exceed measurement resolution and neighboring numerical path uncertainty must not erase the class assignment. No fitted `p_c` without bracketing evidence.
- **Shielding vs steering:** `G/G_0<1` (screening) or `>1` (amplification) only when differences exceed combined mesh/EDI/COD uncertainty and persist at fixed crack length and applied load. Opposing signs along path should be reported, not averaged away.
- **Validity:** any hard stop in [CAPABILITY_MAP](CAPABILITY_MAP.md) invalidates the physical interpretation.
- **Novelty veto:** if Gao/Gupta–Moini/Li/other closest paper explicitly presents the same controls and threshold, the effect is a **reproduction**, not a new finding.

**No numeric tolerance can yet be asserted as achieved.** Before solving, define and freeze admissible relative `K`/contour error, angle/path error and maximum allowed geometry perturbations against resource constraints; use independent fidelity families, not only a 4/2/1-mm trajectory sequence.

## Experiment bridge (not a claim of existing facilities)
For a later concrete/cementitious specimen: notched three-point bending or SCB with manufactured smooth perforations and fixed notch geometry, optical DIC of advancing path, load–CMOD and imaging of fracture zones. Measure size dependence and FPZ length. If the material is quasibrittle at the cell size, abandon elastic LEFM alone and calibrate a cohesive model rather than fitting impossible effective `K` values.

## Disposition
**Recommended research decision:** approve *scope formulation* G2+G1 only after the unreviewed 2026 primary manuscripts and signed proposal versions are checked; do **not** issue a simulation permit on the basis of this Stage-0 document. If primary sources defeat novelty, close with an explicit negative novelty verdict and pivot to G4 only after heterogeneous/CZM qualification.
