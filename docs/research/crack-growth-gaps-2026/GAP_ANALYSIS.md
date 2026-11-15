# Critical gap analysis G1–G6 — 15 November 2026

## Scientific rule
A **scientific gap** here means a measurable, falsifiable distinction from the *nearest* primary published study; using FEM, tracing a path, adding an interface or optimizing a unit cell is **not** automatically novel. All statements below are **literature-screening hypotheses**, not discoveries. The source-level evidence and access flags are in [LITERATURE_MATRIX.csv](LITERATURE_MATRIX.csv). A "not established" methodological detail is **unknown**, not a documented absence.

**Critical 2026 update:** Gupta & Moini, [10.1617/s11527-026-03269-0](https://doi.org/10.1617/s11527-026-03269-0), published 23 Oct 2026, explicitly reviews crack twisting, steering, arrest, re-nucleation, bridging and interface-controlled bio-inspired architected cementitious materials. It directly rules out describing these mechanisms *per se* as new.

## G1 — Architecture-controlled transition between crack-trajectory families
- **Known:** Free crack-path modeling in discrete lattices (Gao–Liu–Wei [2026](https://doi.org/10.1016/j.jmps.2026.106729)); around/through aggregate competition (Li et al. [2026](https://doi.org/10.1016/j.engfracmech.2026.112098)); structural crack guidance reviewed in [2026](https://doi.org/10.1016/j.revmat.2026.100153); architected cementitious crack mechanisms surveyed by [Gupta–Moini 2026](https://doi.org/10.1617/s11527-026-03269-0).
- **Unknown at present:** whether a *specified infrastructure-mortar perforation geometry with a prescribed crack origin* has a reproducible parameter threshold separating two distinct **independently propagated** trajectories, after controlling initial defect, mesh, loading, loss of ligament, and cell length scale. This is a restricted question, not a claim of universal absence from literature.
- **Measure:** whole `Γ_p(s)`, signed local turn `θ(s)`, corridor occupancy or winding class, minimum signed distances to cell boundaries; ratio `p=d/a_cell`, normalized crack starting offset, critical interval `p_c` if any, and uncertainty due to `h`, `Δa`, perturbations.
- **Falsify:** threshold disappears under fixed near-tip refinement; path family changes only because crack strikes geometric boundary/interface; transitions are not robust to an independently re-meshed propagation or tiny physical tolerances; or the closest paper already reports an equivalent mapping.
- **Feasibility A** for voids within a **single homogeneous isotropic cementitious continuum** and a tip never reaching a corner/void; **B/C** once interface, bridging, bifurcation or failure of discrete ligaments is required.
- **Assessment:** **conditional retain** as secondary research target; novelty claim requires evidence against 2026 competitors.

## G2 — Crack steering versus amplification of crack-driving force
- **Known:** Arunkumar & Nithin [2023](https://doi.org/10.3233/SFC-220294) already report a minimum `K_I` as hole distance varies; Fageehi & Alshoaibi [2024](https://doi.org/10.3390/app14020897) independently remesh three-hole crack paths and compare hole/no-hole SIF; a 2022 hole-near-crack-path study [10.3390/ma15010363](https://doi.org/10.3390/ma15010363) already exists. Thus hole-induced shielding or steering *per se* is NOT a novel claim. More specifically, local force can be topology sensitive and LEFM invalid under failed scale separation (Gao–Liu–Wei [2026](https://doi.org/10.1016/j.jmps.2026.106729)); deliberately shaped meta-rebar interfaces change pull-out and force transfer (Huang et al. [2026](https://doi.org/10.1016/j.jobe.2025.115139)); auxetic reinforcement causes already observed crack kinking/debonding (Vandadi et al. [2025](https://doi.org/10.1002/admi.202500095)); cementitious fracture toughening well established (Gupta–Moini [2026](https://doi.org/10.1617/s11527-026-03269-0)); local damage suppression in polymer-auxetic cement systems (Li–Wang [2026](https://doi.org/10.1016/j.compstruct.2026.120474)).
- **Unknown at present:** for an explicitly delimited **single-phase perforated mortar layer**, does steering toward a chosen corridor reduce `G` for the advancing crack along its *actual propagated path*, or does it merely relocate concentration / raise `G` before avoidance? A cross-architecture `G`–path **tradeoff with controls** is more specific than a report of crack shielding.
- **Measure:** in a homogeneous crack-tip annulus `K_I,K_{II},T`; `G=(K_I²+K_{II}²)/E'` *only under the valid isotropic homogeneous plane-stress/strain assumptions*; `G/G_0` compared at matched length and matched applied loading; local max tensile stress at a regularized, consistently defined ROI away from both crack-tip and sharp corner singularities; crack corridor and clearance.
- **Falsify:** all curves are explained by net-section loss or total void fraction controls; apparent shielding vanishes at matched crack length; claimed `G` improvement is based on differing tips or invalid heterogeneous EDI contour; `G/G_0` is strongly mesh-contaminated; strongest analogy already measures same controlled Pareto curve.
- **Feasibility A** for geometric voids with a homogeneous continuous tip region; **B** for intact bonded inclusions; **C** for debonded inclusions.
- **Assessment (updated after direct comparator check):** **reject G2 as standalone novelty**. Continue only as a *verification-oriented* quantitative investigation of `R_direct`, `R_path`, and `R_total` defined in [G2 focused protocol](G2_FOCUSED_AUDIT_AND_TEST_PROTOCOL.md). This decomposition is a proposed control, not yet literature-proven novel.

## G3 — Architecture-dependent geometric feedback in MTS versus GMTS
- **Known:** MTS has a classical foundation in Erdogan–Sih [1963](https://doi.org/10.1115/1.3656897); kink perturbations in Cotterell–Rice [1980](https://doi.org/10.1007/BF00012619); different architecture-dependent crack-tip fields are documented by Gao–Liu–Wei [2026](https://doi.org/10.1016/j.jmps.2026.106729).
- **Unknown:** whether introducing a *specific perforated cementitious architecture* changes the sign/magnitude of **path-level** MTS–GMTS feedback, beyond only frozen-field angle corrections, under a **pre-registered physical distance** for GMTS.
- **Measure:** at matched frozen tips `Δθ_frozen`, full independently propagated `Γ_MTS` and `Γ_GMTS`, separation and tip path end-state, signed `T` at a qualified Williams annulus, sensitivity to `r_c` and cell scale.
- **Falsify:** path separation collapses under mesh/increment refinement; correction depends on arbitrary `r_c`; a path-level effect is merely the accumulation of local roundoff error.
- **Feasibility A**, conditional on homogeneous tip region and separately validated `T` extraction.
- **Assessment:** **methodical secondary observable, not independent main novelty** at Stage 0.

## G4 — Interface deflection / penetration / debonding in cement–polymer architecture
- **Known:** He–Hutchinson [1989](https://doi.org/10.1016/0020-7683(89)90021-8) established the elastic deflection-vs-penetration comparison; Tao–Zhang [2026](https://doi.org/10.1016/j.conbuildmat.2026.146654) validated mixed-mode ECC/substrate crack deflection; Huang et al. [2026](https://doi.org/10.1016/j.jobe.2025.115139) quantified patterned meta-rebar bond/slip; Vandadi et al. [2025](https://doi.org/10.1002/admi.202500095) document reinforcement debonding and kinking; Zhang et al. [2025](https://doi.org/10.1016/j.conbuildmat.2025.144534) addressed polymer–concrete interface under low-temperature conditions.
- **Unknown:** a specific controlled crack-mode transition map in **periodic meta-rebar geometry under mixed mode**, including a matrix/interfacial fracture-energy ratio and geometrically driven failure paths with experimental confirmation. Need check nearest full methods first.
- **Measure:** cohesive dissipated work partition, mode mixity `ψ`, full trajectory and interface-debonded length, load-displacement, `G_c(ψ)`, and map axes `G_{c,int}/G_{c,bulk}` and geometric spacing.
- **Falsify:** regime map agrees entirely with existing interface theories without an additional architecture-controlled distinction; uncalibrated traction–separation law dominates; interface `K` interpreted via homogeneous crack formula.
- **Feasibility B→C**: multi-phase FE, bimaterial interface traction processing, contact/CZM and matched toughness calibration not ready in current homogeneous LEFM code.
- **Assessment:** **physically relevant longer-term, reject as immediate Stage 1 pilot**.

## G5 — Auxetic hinge rotation competing with failure and bridging
- **Known:** Xu et al. [2020](https://doi.org/10.1016/j.cemconcomp.2020.103624) discovered bridging-induced auxetic behavior and cyclic response; Xie et al. [2025](https://doi.org/10.1016/j.cemconcomp.2025.106069) extended the SHCC softening regime; Chen et al. [2024](https://doi.org/10.1016/j.jobe.2024.108999) compared printed re-entrant/chiral/buckling cells; Vo–Kim [2025](https://doi.org/10.1016/j.jobe.2025.114425) compared diamond/elliptical/peanut architectures; reviewed in [2026](https://doi.org/10.1016/j.tws.2025.114425).
- **Unknown:** any *additional, falsifiable* hinge stability bifurcation under a specified cohesive law after matching measured SHCC behavior. The plain idea of rotation plus bridging is **not novel**.
- **Measure:** crack opening, bridge work, hinge rotation, apparent Poisson ratio vs load and residual strength; calibrated process-zone length.
- **Falsify:** proposed behavior merely reproduces Xu/Xie/Vo or depends on mesh cohesive regularization.
- **Feasibility C**: nonlinear material and fracture, cohesive softening, possible large rotations.
- **Assessment:** **reject as standalone novelty and immediate pilot**. Retain only for validated 2027–28 CZM model extension.

## G6 — Dynamic attenuation versus local fracture risk in resonant metaconcrete
- **Known:** metaconcrete introduced by Mitchell et al. [2014](https://doi.org/10.1016/j.jmps.2014.01.003); low-frequency slit resonators tested by Imagawa et al. [2025](https://doi.org/10.1016/j.cemconcomp.2025.106191); blast response tested by Liu et al. [2025](https://doi.org/10.1016/j.ijimpeng.2025.105371); reviews [Wang et al. 2025](https://doi.org/10.3390/ma18174032).
- **Unknown:** for a *specified* cracked slab/coated resonator, whether minimizing transmission amplitude conflicts with peak local fracture driving force across an excitation spectrum.
- **Measure:** transmission and bandgap, local transient energy-release rate via dynamic J where valid, maximum `G(t)`, coating damage, wave-to-crack energy budgets.
- **Falsify:** apparent amplification explained by unmodeled damping/contact or disappears upon dynamic energy accounting; attenuation cannot be reproduced.
- **Feasibility C**: transient elastodynamics, interface and mode treatment, dynamic crack growth and separate validation.
- **Assessment:** **retain as long-term scientific question; do not use static `K` to claim dynamic fracture**.

## Prioritization decision (critical, provisional)
| Rank | Hypothesis | Novelty *after* screening | Physical meaning | Testability now | Cost | Experimental bridge | Infrastructure fit | Decision |
|---|---|---|---|---|---|---|---|---|
| 1 | **G2** | Low as broad claim; conditional as new controlled comparison | high | A for voids | modest-to-medium | SCB/beam | high | **priority candidate** |
| 2 | **G1** | Conditional / medium-low | high | A for voids | medium | DIC path | high | **secondary candidate** |
| 3 | G3 | low as standalone | medium | A | medium/high (two full paths) | possible | medium | supporting diagnostic |
| 4 | G4 | crowded, specificity needed | high | B/C | high | push-out/bending | high | future extension |
| 5 | G6 | possible but unverified | high | C | very high | impact tests | high | later |
| 6 | G5 | known mechanism | high | C | high | hinge tests | medium | **reject as novel by itself** |

**Decision gate:** none of these hypotheses is currently proven novel. First pilot (later, if authorized) should investigate **G2 with G1 path-classification measured on exactly the same physical sample**. That is narrower, more defensible and computationally affordable than promising all six proposal simulations. Do not run any FEM/CZM at Stage 0.
