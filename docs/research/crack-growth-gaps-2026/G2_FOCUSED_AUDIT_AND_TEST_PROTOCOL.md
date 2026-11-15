# G2 focused falsification audit — shielding vs amplification of crack-driving force
**Date:** 2026-11-15  
**Status:** literature + mathematical preflight only; **no new FEM/CZM solves**. Researcher selected **G2** for targeted scrutiny. This does **not** certify novelty, qualify a real mortar constitutive law, or automatically authorize a production computation.

## 1. Updated novelty verdict: reject the broad claim
The broad statement **“perforations shield cracks” is established, not novel**. Likewise **“holes alter free crack paths”** and **“amplification changes to shielding”** are prior results.

### Direct competitors audited in this pass
| Comparator | Verified source and access | What directly pre-empts G2 | Specific point requiring care |
|---|---|---|---|
| **Arunkumar & Nithin (2023)** | [10.3233/SFC-220294](https://doi.org/10.3233/SFC-220294), **publisher abstract**, restricted full text | ABAQUS, center crack, varied hole diameter/number/distance; reports a **minimum `K_I` at an optimum distance** | A mere `K`-versus-hole-distance curve is **already published** |
| **Fageehi & Alshoaibi (2024)** | [10.3390/app14020897](https://doi.org/10.3390/app14020897), **full publisher HTML** (methods, discussion, conclusions) | Three holes, remeshing, MTS, interaction-integral `K`, **free path** and direct comparison with hole-free beam; benchmarked against historical experiment | In §3.1.2 / Fig. 11, **`K_I` with holes is reported higher at the same crack length** in one case, even while the crack path hits a hole. Thus *geometrical termination at a void* ≠ demonstrated energetic shielding; check both `K_I,K_{II}` before judging total `G` |
| **Alshoaibi & Fageehi (2023)** | [10.3390/ma16196481](https://doi.org/10.3390/ma16196481), **full publisher HTML** | Fully remeshed LEFM growth, three-hole PMMA bending experiment comparison | A three-hole free-path prediction cannot stand alone as our novelty |
| **Bittencourt et al. (1996)** | [10.1016/0013-7944(95)00247-2](https://doi.org/10.1016/0013-7944(95)00247-2), **publisher abstract** | Classical 2D remeshed LEFM free crack paths validated with experiments | External benchmark for code qualification, *not* 2027–28 discovery |
| **Ayas, Touati & Chabaat (2025)** | [10.1177/15672069251326377](https://doi.org/10.1177/15672069251326377), **publisher abstract** | `K` shielding/amplification for interacting nearby cracks | Secondary microcracks, not engineered holes |
| **Jin et al. (2024)** | [10.1016/j.tafmec.2024.104559](https://doi.org/10.1016/j.tafmec.2024.104559), **publisher abstract** | Enhancement/shielding transition in interacting cracks | Fatigue and multiple cracks, not fixed-porosity void architecture |
| **Wang et al. (2019)** | [10.3390/ma12081331](https://doi.org/10.3390/ma12081331), **open full text/conclusions** | Criterion diagram of strengthening vs shielding based on spacing and offset of two parallel cracks | Prior transition maps preclude a broad novelty claim |
| **Gupta, Esmaeeli & Moini (2024)** | [10.1002/adfm.202313516](https://doi.org/10.1002/adfm.202313516), **full publisher HTML** | Cementitious nacre-like composites deliberately deflect cracks and improve measured toughness via interface/bridging | `R`-curve, strength, and ductility are **not** equivalent to local elastic `G` of a fixed geometry |
| **Gupta & Moini (2026)** | [10.1617/s11527-026-03269-0](https://doi.org/10.1617/s11527-026-03269-0), **full publisher HTML** | Architected cementitious fracture mechanisms already extensively reported | Review is methodological context, not proof no one has studied our narrowed decomposition |
| **Gao, Liu & Wei (2026)** | [10.1016/j.jmps.2026.106729](https://doi.org/10.1016/j.jmps.2026.106729), **publisher abstract** | Graph-field crack driving force in discrete lattices | Conventional `G=(K_I²+K_{II}²)/E'` may fail at lattice-scale tips |

### Critical source interpretation
Fageehi–Alshoaibi 2024 states in §3.1.2 that in case I (holes), `K_I` exceeds case II (no holes) even at the same crack length, **while** describing a path that terminates by hitting the middle hole. This does **not** by itself establish `G_{holes}>G_{solid}` because a separate `K_{II}` contribution must be accounted for, nor does it establish stronger crack resistance of the material. It **does** conclusively defeat the simplistic inference “hole captures crack, therefore hole shields its driving force.” Some of that paper's verbal accounts of von Mises stress also appear difficult to reconcile, so only directly stated paths, SIF definitions and numerical figures should be used.

## 2. Falsifiable narrower question
> In the *same one-phase, linearly elastic notched cementitious surrogate*, with **fixed number/area of smooth voids** and prescribed remote traction, can changing only **void placement** produce a measurable `G` shielding-to-amplification transition when (i) the crack **geometry is held fixed** and (ii) it is **independently propagated**? Does apparent crack trapping coincide with `G<G_c` or merely with geometric arrival at a free boundary?

This is a question, **not a verified literature gap**. The new contribution, if any, must go beyond Arunkumar 2023's optimum-distance `K_I`, Fageehi 2024's hole/no-hole `K_I` along paths, and Bittencourt's classic benchmark. A matched-path/counterfactual decomposition (below) is one possible **testable differentiator**, but its novelty requires a separate search for similar decompositions.

## 3. Define a three-way energy comparison (avoid confounding path and geometry)

Given a polygonal crack history `Γ_p(s)` grown with void architecture `p` and a *common prescribed traction* `λσ_0`, in a tip neighborhood contained in **homogeneous isotropic linear elasticity**, let:
- `G_A[Γ_p](s)`: architecture with voids and actual propagated path;
- `G_H[Γ_p](s)`: **counterfactual control**, identical non-straight crack `Γ_p` embedded in an intact homogeneous plate **without voids**, at the *same* load, supports, current arclength `s`, and crack orientation;
- `G_H[Γ_H](s)`: no-void reference with its **own** independently propagated crack path at the same arclength.

Then, when denominators nonzero and all geometries admissible:

```text
R_direct(s,p) = G_A[Γ_p](s) / G_H[Γ_p](s)
R_path(s,p)   = G_H[Γ_p](s) / G_H[Γ_H](s)
R_total(s,p)  = G_A[Γ_p](s) / G_H[Γ_H](s) = R_direct * R_path
```

- **`R_direct`** distinguishes the *architectural field modification at a frozen identical crack shape*; <1 is local screening, >1 is local amplification.
- **`R_path`** quantifies the *indirect effect of changing the crack shape*, in a homogeneous control; **this artificially imposed path is a diagnostic, not a physically spontaneous one**.
- **`R_total`** is the total difference for two independently propagated cases, potentially path-confounded.

The factorization is **algebraic**, not an independently established physical mechanism. Because it uses comparable energy-release rates **at each same frozen crack geometry** (not at a single shared tip location where paths differ), it is valid as a designed comparison only if all three solutions obey their own well-posed BVP and local energy definition. A path entering a void invalidates subsequent continuum comparisons.

At first *common frozen initial crack*, `Γ_p=Γ_H`, so `R_direct=R_total` and `R_path=1`: this is the clean initial screening.

### Load interpretation
For `G=G(λ=1) λ²` in elastic homogeneous fracture, a **separately specified** constant material toughness `G_c` yields the *required load factor for initiation* at that frozen state: `λ_c = sqrt(G_c/G(λ=1))`. Relative factor at **the same crack geometry** is `λ_{c,A}/λ_{c,H}=sqrt(1/R_direct)` if the same `G_c` applies. Without a calibrated `G_c` this ratio is only a conditional LEFM statement. Neither low `G` nor the MTS arrow alone proves *arrest*, *crack-growth rate*, *fatigue life*, *post-peak toughness* or *improved durability*. Reaching a hole is a **geometric termination of a solid tip**, not necessarily `G<G_c`.

## 4. Proposed exact computational surrogate **for a future separately authorized pilot**
Do not pass off historical homogeneous plate results as new data.

**Method anchor, not proven concrete specimen:** use frozen source boundary contract from `EdgeCrackHoleLEFM` 2026-10-25 integration audit: 2D domain `x∈[0,300]` mm, `y∈[-200,200]` mm, edge crack `(0,0)→(50,0)` mm, `E=4000` MPa, `ν=0.30`, plane strain, specified top/bottom signed 1 MPa tractions and geometrically defined three rigid-mode constraints. These are benchmark values **only**. First reproduce with zero holes and accepted historical two-hole geometry independently; do not assume the historic mesh/q fits modified holes.

**New void arrangements (design proposals, not optimized or run):**
| Case | Hole centers (mm) | Radii (mm) | Main purpose |
|---|---|---|---|
| H0 | none | — | intact primary baseline |
| H1+ | (90, +30) | 15 | single-hole proximity response |
| H1− | (90, −30) | 15 | signed mirror symmetry |
| H2a | (90,+15), (135,−15) | 15 each | staggered architecture, `p=|d|/r=1` |
| H2b | (90,+30), (135,−30) | 15 each | same porosity, `p=2` |
| H2c | (90,+45), (135,−45) | 15 each | same porosity, `p=3` |
| H2a− | (90,−15), (135,+15) | 15 each | mirror and `K_{II}` sign check |
| H2far | (160,+15), (205,−15) | 15 each | same two-hole area; remote placement control |

- At `H2a` the distance from the **initial crack tip** `(50,0)` to the *nearer hole boundary* is `sqrt(40²+15²)-15 ≈ 27.72 mm`, so a conventional few-mm initial interaction domain could fit. This is **only an analytical geometry clearance**, not proof of `K`-dominance or a solved mesh.
- All H2 variants contain two equal-radius circular voids and hence have **equal nominal removed area** `2π(15 mm)²`; **net-section minima are not automatically matched**. Compute the actual minimum ligament and net-section distribution per design and add a separately constructed matched-section control if needed.
- Changing `d` moves both centers; the remote-plate load and support contract is identical. Mirror tests must transform the loads/supports consistently: with a nonsymmetric support/traction setup, `K_{II}` sign mirroring is **not guaranteed**. Check BVP symmetry before asserting a sign identity.
- Do **not** treat voids as solid polymer inclusions or call them an auxetic architecture without additional evidence. They form only the first **single-phase perforated-geometry surrogate**.
- The initial 27.72 mm clearance is not the minimum **during propagation**. Re-evaluate on each accepted increment.

### Pilot sequence, each behind its own gate
**V0 — external benchmark:** rebuild a published three-hole bend specimen (Bittencourt 1996; Alshoaibi–Fageehi 2023; Fageehi–Alshoaibi 2024). Compare *both* path and SIF where reference data allow. This verifies the controller in an architecture different from the inherited two-hole tension benchmark. Do not guess experimental digitized coordinates; obtain primary data or explicitly compare visually only.

**V1 — frozen-tip mechanics:** after external benchmark passes, solve H0/H1±/H2a,b,c/H2a−/H2far at one initial crack geometry and identical load; independently refine FE mesh and tip extraction domains; calculate signed `K_I,K_{II}` with pinned EDI plus blind COD; record `G`, `R_direct`, `K_{II}/K_I`, hole clearance and section properties. **V1 is an elastic field experiment only**, no actual crack extension.

**V2 — full-path mechanics:** only if V1 is valid, propagate **independent** MTS polyline paths for H0, one responsive H1 and 2–3 H2 geometries. At each accepted `Γ_p(s)` also solve no-hole frozen counterfactual `G_H[Γ_p]`, then compute `R_direct, R_path, R_total`. Requires **separate `Δa` and `h_{tip}` variation**. A fixed-traction MTS continuation is a *conditional path under hypothetical crack advance* unless `G_c` is calibrated and growth condition demonstrated; never label it an observed fracture history.

**V3 — physical relevance:** with experimental calibration, analyze whether intended mortar has `K`-dominance (`r_{mesh} \ll r \ll \min(\ell_{void},\ell_{FPZ}^{-1}\text{ criterion})`); more precisely, a valid annulus needs **distance from inner numerical regularization and from any non-negligible process zone to be much smaller than distance to geometry/interface features**. Otherwise move to bulk CZM, strength-based or nonlocal concrete fracture; do not extrapolate V1–V2 to a real pavement slab.

## 5. Hard stops and scientific output contract
1. **Geometry:** exact smooth circles; no void overlap or unintended slit/hole collision; topological checks for both crack banks, T3/T6 Jacobians, contour clearance, minimum ligaments.
2. **Mathematics:** standard LEFM `K,T,G` are refused if q-domain touches a void or any heterogeneity, `K`-dominance fails, or COD and EDI do not agree within a **preregistered** tolerance.
3. **Discretization:** at fixed path/geometry, vary `h` and extractors separately; on growth studies vary `Δa` without simply scaling `h`; classify no convergence as failure, not as evidence of complex metamaterial physics.
4. **Controls:** consistent remote applied *traction* and geometry, reference plate, matched same-path and equal-void-area controls. A mere raw `K_I` decrease is inadequate when `K_{II}` changes.
5. **Acceptance:** declare **screening** only when the sign of `R_direct-1` exceeds numerical uncertainty, is stable to independent FE refinements, and remains separate from the path-change factor; declare a **transition** only if both (R_direct<1) and (R_direct>1) occur for different admissible fixed-area geometry parameters. A sign of `R_total-1` alone is insufficient.
6. **Falsification:** if `R_direct` is ~1 within uncertainty and all apparent gains originate in `R_path` or section loss, the hypothesized *direct architecture screening* is **rejected for this model**. If benchmark fails, no new physics inference. If prior works already report the same controlled decomposition, any reproduced effect is **validation**, not novelty.
7. **Novelty gate:** verify nearest paper *full methods* for same-path counterfactual field comparisons and control of void fraction. Current evidence supports a promising **falsifiable model comparison**, not a defensible assertion of being first.
8. **No premature claims:** use the terms “geometry-induced SIF change”, “conditional energy-release rate”, “geometric interception” accurately; no `G_c` changes unless CZM/experiments, and no durability, crash resistance or crack arrest from a frozen-tip LEFM field alone.

## 6. Researcher decision and next independent issue
The researcher has selected **G2** as the target. **Recommended outcome of this audit:** move G2 to *verification-oriented V0→V1*, while **downgrading G2 as a standalone novelty claim**. Perform a stringent benchmark first; only then consider V2. No solver execution is recorded in this PR and no acceptance metric has been achieved.
