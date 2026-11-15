# Capability and mathematical stop-condition map
**Scope:** evidence audited from `mfs9697/EdgeCrackHoleLEFM` README/STATUS and [first-kink trajectory integration audit](https://github.com/mfs9697/EdgeCrackHoleLEFM/blob/main/docs/M1I_CRACKFROMHOLE_TRAJECTORY_INTEGRATION_AUDIT_2026-10-25.md). Main README is a **stale overview** relative to dated subreports; newer physical statuses are **stage specific**. The qualified legacy methods do not thereby validate a metacomposite model.

## A/B/C definitions
- **A** — conceptually implementable using a **homogeneous isotropic elastic single-phase domain with geometric voids**. Before new production runs, must still verify the mesh, solver and extraction on each new architecture.
- **B** — new heterogeneous FEM/phase-aware post-processing and interface treatment needed.
- **C** — nonlinear cohesive constitutive or transient/dynamic experiments and/or new algorithms needed.

| Component | Current evidence and limitation | Class | Required independent gate |
|---|---|---|---|
| T3→T6 displacement FEM and re-meshing | Source reports mesh qualification in separately run homogeneous/holed-plate cases; **not** proof of validity for sub-cell ligament networks | A | Conformity, crack-bank ownership, Jacobian, elasticity patch/energy balance |
| Polyline crack extension | Source controller available in `CrackFromHoleLEFM`; integration audit says reuse architecture, **not drop-in** for other geometry | A | Exact geometry, full path persistence, mesh restart and independent solves |
| Signed `K_I,K_{II}` (interaction integral) | Qualified for verified homogeneous tip neighborhoods and controlled extraction domains | A | Contour/domain consistency, 16GP/other quadrature, independent displacement-based COD |
| MTS propagation | Established and numerically implemented for qualified isotropic local tip fields | A | Frame rotations, root sign, predeclared `Δa` convergence comparison |
| Williams `T` extraction / GMTS | Separate source methods and pilots exist; GMTS introduces characteristic length `r_c` | A conditional | Homogeneous fitting annulus; prescribed `r_c`, independent full path propagation |
| Void/perforation shaping | Can in principle be handled as **holes in otherwise homogeneous continuum**; thin ligaments and near-contact difficult | A conditional | Clearance, feature radius, no collision, mesh independent `K` and path |
| Elastic inclusion with `E_f \ne E_m` | Needs phase-wise stiffness assembly, interface continuity and validated domain integrals | **B** | Piecewise manufactured solutions and independent interface benchmarks |
| Crack actually at heterogeneous interface | Standard homogeneous Williams fields and `G` formula cannot be applied indiscriminately | **B/C** | Dedicated bimaterial/interface singularity and energy-release formulation |
| Arbitrary interface kink/debonding/penetration | Not part of proven homogeneous path engine | **C** | Mixed-mode cohesive interface with independently calibrated `G_c(ψ)`, contact and bulk failure competition |
| Auxetic hinge/bridging | Large rotation, strain hardening and fracture-process zone | **C** | Cohesive and material constitutive identification; objective mesh dissipation |
| Dynamic resonators / blast / fatigue | Transient inertia, damping, history and potentially evolving contact not verified | **C** | Dynamic momentum/energy balance, wave and impact benchmark, dynamic fracture criterion |
| Concrete scale and experimental bridge | `K`-dominance may fail when FPZ `\ell_{FPZ}` comparable to ligament size | **B/C** | Size-effect/SCB calibration and physical process-zone estimates |

## Evidence from qualified *historical* method, NOT proposed material result
The dated 2026-10-25 [integration audit](https://github.com/mfs9697/EdgeCrackHoleLEFM/blob/main/docs/M1I_CRACKFROMHOLE_TRAJECTORY_INTEGRATION_AUDIT_2026-10-25.md) records author-run 300 × 400 mm **homogeneous** two-hole plate, edge slit 50 mm, physical first 4 mm kink, signed interaction integral and independent COD agreement at that **specific frozen tip**. It also identifies blockers for transplanting the controller: initial crack topology, support DOFs, true CAD holes, near-tip core and bank ownership, EDI/COD integration and checkpoint format. It does **not** establish a physically propagated architecture-dependent cementitious path or any polymer–cement bimaterial extraction. Thus `EdgeCrackHoleLEFM` is **method evidence** only.

## Formal stop conditions — run-time and interpretation

**STOP-1: invalid crack-tip asymptotics.** If any SIF extraction domain intersects a void, material boundary, cohesive zone, geometrical non-smooth feature or non-negligible distributed inelastic zone, decline to interpret returned homogeneous `K_I,K_{II},T` as qualified. Move to a new validated interface/energy formulation (class B/C). A contour crossing an inclusion is not automatically admissible merely because FE equilibrium is satisfied.

**STOP-2: broken `K` dominance / scale separation.** If the available uniform-tip annulus `r_{mesh} \ll r \ll \ell_{geom}` does not exist, where `\ell_{geom}` is clearance to the nearest hole or phase boundary, do not quote transferable LEFM crack-steering laws. The symbol `\ll` is a consistency requirement, not an observed numeric inequality.

**STOP-3: false convergence.** Vary crack increment `Δa` **independently** of tip mesh size `h_{tip}`; the historical 4/2/1 mm families with jointly rescaled tip meshes do **not** prove increment convergence. Separate `h\to0` at fixed `Δa`, `Δa\to0` at fixed qualified local resolution, and cross-check entire paths. Near path-transition parameters, classify uncertainty intervals, not exact critical points.

**STOP-4: unsupported fracture mode.** Penetration of a solid inclusion, branching, path along an interface, true arrest, ligament snapping and bridging have mechanisms not provided by single-phase incremental MTS alone. Stop the run before crossing; mark it as a **candidate hit or termination**, not a physically proven crack arrest/deflection.

**STOP-5: invalid energy conversion.** Only for homogeneous linear-isotropic elasticity and a matching near-tip field is `G=(K_I²+K_{II}²)/E'`, with `E'=E` plane stress and `E'=E/(1-ν²)` plane strain, justified. For discrete lattice/anisotropic/bimaterial and dynamic tips require their appropriate energy formulation. Gao et al. [2026](https://doi.org/10.1016/j.jmps.2026.106729) shows why graph-level configurational forces may be necessary.

**STOP-6: unresolved nonsingular `T`.** Require a Williams fitting annulus insensitive to radius and exclusion of neighboring notches; GMTS has no meaningful predictive separation without an explicit material length `r_c`. Never tune `r_c` post hoc to make G3 large.

**STOP-7: geometry and stress peak artefacts.** A pointwise maximum near ideal sharp corners or a crack tip may be singular and mesh dependent. Define physical feature fillets and fixed ROIs away from singularities, or report notch-radius sensitivity instead of unbounded max stress.

**STOP-8: controls and boundary conditions.** At each architecture compare same specimen, loading, crack length and boundary constraints; supplement with matched void fraction/net section/ligament width. No claim of shielding based solely on unlike net sections.

**STOP-9: validation refusal.** Stop if any T6 Jacobian nonpositive, crack bank topology fails, COD and EDI disagree beyond preregistered tolerance, equilibrium/energy checks fail or path classification flips with admissible remeshing. Tolerances must be frozen in a pre-pilot protocol.

**STOP-10: source/proposal authority.** Do not claim alignment to the *approved* 2027–28 plan before reviewing the signed formal request and version hierarchy in `SOURCE_INVENTORY.md`.

## Fit to six proposal simulations
| Simulation | Realistic earliest level | Ruling now |
|---|---|---|
| 1 auxetic cohesive hinge | C | not Stage 1 |
| 2 different architectures under compression/flexure | A for elastic hole geometry only; C for cohesive fracture or crushing | start with *single-phase perforated proxy* only; no implied auxetic strain-hardening |
| 3 resonant metaconcrete dynamic | C | not Stage 1 |
| 4 3D printed reinforcement | B/C | not Stage 1 |
| 5 cement–polymer interface degradation | C | not Stage 1 |
| 6 pavement slab with internal crack traps | A for geometrical holes and LEFM-only crack deflection; B/C for solid inserts or real arrest | **only eligible restricted pilot** |

In this document A is **methodological compatibility**, not a claim that all new meshes/solvers are already run and accepted.
