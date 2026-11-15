# G2 — Figure 16 geometry/BC reconstruction and original-experiment provenance
**Date:** 15 November 2026  
**Status:** **READ-ONLY SOURCE INVESTIGATION / NOT A QUALIFIED EXPERIMENTAL BVP**. No FEM, COD, SIF, trajectory or mesh was calculated.

## Executive finding (important correction)
The original geometry is **not yet a single unambiguous physical specimen**. Fig. 16(a) of Alshoaibi & Fageehi (2023) prints dimensions **without a unit label**, whereas §3.3 explicitly says **diameter 0.5 cm** and **starting crack `a=1 cm`**. Their referenced experimental source Ingraffea & Grigoriu (1990) uses a **20 × 8 inch** plexiglas beam, thickness **1/2 inch**, and **multiple specimens** with different starting crack locations and lengths. Thus the 2023 paper's Fig. 16 is reconstructable as a **numerical figure-coordinate geometry**, but it is NOT yet demonstrably an exact replication of a named 1990 specimen.

**Primary links:**
- 2023 [article §3.3, Fig.16 and Fig.17](https://doi.org/10.3390/ma16196481); direct [Fig.16(a) geometry picture](https://mdpi-res.com/materials/materials-16-06481/article_deploy/html/images/materials-16-06481-g016a-550.jpg), [Fig.17 comparison](https://mdpi-res.com/materials/materials-16-06481/article_deploy/html/images/materials-16-06481-g017-550.jpg).
- 1990 **Ingraffea & Grigoriu**, *Probabilistic Fracture Mechanics: A Validation of Predictive Capability*, Cornell Report **90-8**, AFOSR contract F49620-87-C-0054, archived under **DTIC ADA228877**, specifically §3 and §5; [DTIC identifier](https://apps.dtic.mil/sti/citations/ADA228877), [accessible scan-derived OCR text (Academia)](https://www.academia.edu/144534340/Probabilistic_fracture_mechanics_A_validation_of_predictive_capability). **Direct DTIC archive was unreachable during this audit**; statements about the original use an accessible scan-derived transcription and must be visually audited in a first-party archival copy before claiming exact dimensional traceability.
- 2014 independent reproduction: Holl, [*Multiscale crack propagation and crack coalescence using the XFEM*, PhD thesis](https://www.ikm.uni-hannover.de/fileadmin/ikm/publications/2014_Holl_PhD_Thesis_01.pdf), **p.55 Fig.5.3**. It explicitly fixes `a=25.4mm`, thickness `12.7mm`, `E=3.1 GPa`, `ν=.4`, and remarks that this benchmark has **only experimental crack paths, no published load–deflection or energy-release curve for this selected case**. **This is a separate reproduction with its own geometry/material inputs, not a replacement for Fig.16.**
- 2022 numerical comparator: Mohmadsalehi & Soghrati, [10.1016/j.cma.2022.115015](https://doi.org/10.1016/j.cma.2022.115015), cited as [54] by the 2023 paper; confirmed method/article from publisher abstract, full primary methods and digitized reference trajectory not yet obtained.
- 1996 numerical comparator: Bittencourt, Wawrzynek, Ingraffea & Sousa, [10.1016/0013-7944(95)00247-2](https://doi.org/10.1016/0013-7944(95)00247-2), based on same experiment family; original complete methods not yet retrieved.

## A. Geometry transcribed from **Fig. 16(a)** (native coordinate unit F)
Use `(x,y)=(0,0)` at the **bottom-left corner**, x right, y up. Values below are **not yet physical millimeters**.

| Feature | Coordinate / geometry in F | Status and derivation |
|---|---|---|
| Outer body | `0 ≤ x ≤ 20, 0 ≤ y ≤ 8` | **Printed** width: `10+10`, height 8 |
| Crack mouth | `(5,0)` | **Printed** distance 5 from left edge |
| Crack tip | `(5,1)`, initial straight vertical slit | **1F** comes from §3.3 prose `a=1cm` interpreted in its own units; figure depicts `a` but does not print numeric value adjacent to notch |
| Hole radii | `r=0.25` each | **Printed** diameter `φ0.5` |
| Top hole center | `(5.55,6.75)` | `x=10−4.45`, `y=8−1.25` |
| Middle hole center | `(5.55,4.75)` | Two units below top center |
| Bottom hole center | `(5.55,2.75)` | Two units below middle center |
| Load location | `(10,8)` downward | **Printed symbol** `P` at top center; **magnitude not stated** for §3.3 |
| Right roller | `(19,0)` | **Printed** `9` from centerline at x=10 to support |
| Left pinned support | `(1,0)` | **Inferred** from apparent symmetric spacing of support symbols; no independent explicit `1` dimension on left in Fig.16. **Must verify in primary report/figure before freezing.** |

**Geometric admissibility at initial crack (pure algebra only):** minimum distance from tip `(5,1)` to the bottom hole boundary is `sqrt((5.55−5)²+(2.75−1)²)−0.25 ≈ 1.5844 F`. This is NOT a finite-element clearance or proof that a chosen interaction-integral annulus is valid.

A machine-readable conservative reconstruction appears in [G2_FIG16_RECONSTRUCTION.json](G2_FIG16_RECONSTRUCTION.json). Missing values are **null, not guessed**.

## B. Boundary conditions shown vs actually known

Idealized **point support formulation** for later **separately permitted** FE preflight:

```text
Ω = ([0,20] × [0,8]) \ (C_top ∪ C_mid ∪ C_bottom ∪ Γ0)
Γ0 = {(5,y): 0≤y≤1}

at provisional left pin    (1,0): ux=uy=0
at dimensioned right roller(19,0): uy=0, ux is unconstrained
at top loading point        (10,8): downward resultant P (unknown magnitude)
elsewhere                   traction-free (incl. hole walls and slit banks)
```

This captures the **symbols** of a simply-supported three-point bending test but not the finite-width contact mechanics of supports and loading nose. Treat point loads and point constraints as mathematical idealizations; run a support/contact patch sensitivity control if near-edge stress concentrations or load–CMOD are claimed. The original experiment used **CMOD-controlled loading**, so a fixed force `P` in the figure describes a resultant, **not** the complete experimental control protocol.

**Known material for the 2023 *numerical article only*:** homogeneous isotropic PMMA, `E=2.8 GPa`, `ν=0.3`. **Unknown for the 2023 §3.3 case:** plane stress vs plane strain, thickness, amplitude/history of `P`, contact radius/support compliance and precise notch width. The article discusses both 2D constitutive options generally; do NOT borrow the separately specified *plane stress* in its §3.4 two-hole example. Consequence: absolute `K_I,K_{II},G` and load–CMOD curves cannot be certified as experimental replicas from Fig.16 alone.

At **fixed geometry, fixed elastic constitutive model, and a uniform proportional positive load scale**, mode-mix ratio and MTS direction should be independent of the unknown `P) magnitude in *linear elasticity*. This only justifies a **normalized/free-path numerical benchmark**, NOT validation of absolute SIF magnitudes nor fracture-initiation load. A missing thickness may also affect conversion of the physical load `P` into equivalent 2D line force.

### Two scale interpretations must not be silently merged

| Interpretation | Beam dimensions | Crack length | Hole diameter | Validity |
|---|---|---|---|---|
| **2023 text implied** `1 F=1 cm` | 200×80 mm | 10 mm | 5 mm | internally consistent with §3.3 text, **not confirmed experimental physical dimensions** |
| **1990 archival experiment** `1 F=1 inch` | 508×203.2 mm | **varies by specimen** (not simply 1F) | 12.7 mm | original family geometry; **not identical to 2023 Fig.16 by declaration** |

For the Cornell specimen, thickness is 0.5 in = 12.7 mm. Original 1990 report records average measured `E≈474,000 psi≈3.268 GPa` over four no-hole calibration specimens (manufacturer value 450,000 psi); do not substitute this average automatically for 2023's `E=2.8 GPa` or assert the original report established `ν=0.3`. The Holl thesis used `E=3.1GPa, ν=.4` for **its own reproduction**, while Wu & Nguyen (2018) used `E≈3.275GPa, ν=.35` for a different model. Material parameters are model-version-specific, not interchangeable ground truth.

## C. Experiment provenance: Cornell 1990 is **a family**, not one point set

From Cornell Report 90-8 §5 (accessible OCR transcription):
- **Seven** plexiglas specimens with three holes; overall dimensions/hole sizes/positions held fixed but initial **notch location `d` and length `a` varied**.
- Illustrated source specimens: **#1 `a=1in,d=6in`**, **#2 `a=2.5in,d=6in`**, **#3 `a=1.5in,d=5in`** (see captions for original Figs 5.2–5.4). These specimen IDs, not merely the test family, must be identified for a numerical-to-experiment comparison.
- Samples were cut, finish-machined and naturally precracked with a razor at the saw notch; drilled holes with residual-stress precautions. Reported preparation tolerances: edge dimensional accuracy ±1/32 in, notch length ±1/64 in and initial direction ±1/4°. These uncertainties can affect path comparisons.
- Applied **CMOD control** to allow slow stable crack growth, rather than assuming fixed load `P` throughout propagation.
- Their PROFRANC computational protocol used `Δa=0.25in`, MTS, remeshing, and **stopped numerical propagation near a hole** (distance about one tenth of hole radius): the solver **did not automatically propagate the crack into the void free boundary**.
- Observed and predicted path comparison in §5.3 notes **one significant failure** for specimen #3: PROFRANC did not reproduce capture into the loading side of the middle hole, though influence of the holes was evident. Reporting only successful cases would hide an important model limitation.
- Hole/no-hole specimen comparisons were **already conducted** (original Figs. 5.5–5.7): path steering and geometric capture therefore cannot be treated as new G2 results.

**Crucial consistency test:** Fig.16 of 2023 implies `d=10−5=5F` and `a=1F`. The explicitly illustrated historical specimen with `d=5in` (#3) had `a=1.5in`, while specimen #1 with `a=1in` had `d=6in`. The source may have additional specimens, but **there is no evidence yet that `(d=5,a=1)` coincides with the Fig.17 experimental trace**. Do not label a pixel digitization of Fig.17 as the measured curve for a known named 1990 specimen without this reconciliation.

### Independent geometry is not identical to Fig.16
Holl (2014), Fig.5.3, documents a **20a×8a** rectangle, `a=25.4mm`, thickness `12.7mm`; its figure positions the hole center at **`x=6a`** and initial slit length **`1.5a`**, while Fig.16 (2023) prints center `x=10−4.45=5.55F` and asserts starter length `1F`. This is a distinct configuration, so a successful reproduction of Holl's path would validate our method **for Holl's defined case**, not automatically that of 2023 Fig.16.

## D. Current source-confidence ledger
| Question | Verdict | Next evidence gate |
|---|---|---|
| 2023 dimensionless outer geometry/three hole centers and notch start | **HIGH for printed figure**, notch length cross-referenced to prose | independently transcribe Fig.16 image and compare to JSON |
| Boundary-support type and load direction | **HIGH for symbols** | verify contact and BC interpretation |
| Right support `x=19` | **HIGH** | quoted 9F distance |
| Left support `x=1` | **INFERRED** | original figure or experimental span |
| Physical length unit and match to Cornell specimen | **CONFLICT** | retrieve original scan and pin specimen ID |
| 2023 model `E=2.8GPa, ν=.3` | **HIGH** | direct §3.3 |
| Original measured `E≈474ksi` | **MEDIUM-HIGH for scanned transcription**, not same 2023 model | original report appendix A |
| `P` magnitude, thickness, plane state of 2023 §3.3 | **UNKNOWN** | original 2023 code/data or author response, explicit geometry paper |
| Exact experiment path from Fig.17 | **UNVERIFIED** | original Fig.5.8–5.14 identification + scan-grounded digitization uncertainty |
| Absolute `K` values in Fig.16 problem | **NOT PROVIDED AS NUMERIC REFERENCE** | separate published solution or independent high-precision benchmark |

## E. Decision: two independent future benchmark tracks
**Track V0–F (Figure reproduction):** use [JSON](G2_FIG16_RECONSTRUCTION.json) in **F units** to verify geometry/BC meshing *only*, and optionally a normalized elastic/MTS path once researcher approves scale, left support, constitutive option and P normalization. Cannot call this an exact 1990 experimental reproduction.

**Track V0–E (experiment reproduction):** identify one **actual 1990 named specimen**, ideally #1 `(a=1in,d=6in)` which has an observed trajectory and corresponding PROFRANC figure (Figs.5.5 and 5.8). Recover authoritative hole-center/support positions from scanned Fig.5.1 and load/support representation, and separate original material measurements and calibration. Only then create a physical-dimension FE input and compare actual experimentally sampled path points. **Specimen #3 with reported prediction failure** is an excellent later stress test to avoid cherry-picking.

**Stop conditions:** do not run numerical models against improperly mixed figure/experimental versions; do not claim a physical `K`/mixed-mode `G` benchmark from a figure providing only a pathway. Once V0 passes, G2 force decomposition `R_direct, R_path, R_total` is a **new separate controlled problem**, not measured by the Cornell experiments.

## F. Provenance references
1. [Alshoaibi & Fageehi (2023), doi:10.3390/ma16196481](https://doi.org/10.3390/ma16196481) — Fig.16, Fig.17, §3.3 and §2.
2. [Ingraffea & Grigoriu (1990), Cornell Report 90-8, DTIC ADA228877](https://apps.dtic.mil/sti/citations/ADA228877); OCR mirror [Academia](https://www.academia.edu/144534340/Probabilistic_fracture_mechanics_A_validation_of_predictive_capability) — §§3, 4, 5 and appendices A, B (archive scan not yet independently inspected).
3. [Holl (2014), PhD thesis](https://www.ikm.uni-hannover.de/fileadmin/ikm/publications/2014_Holl_PhD_Thesis_01.pdf) — p.55 Fig.5.3, experimental geometry/unit and independently reproduced paths.
4. [Wu & Nguyen (2018), JMPS 119, 20–42](https://doi.org/10.1016/j.jmps.2018.06.006) — multiple specimen variants and material; metadata and detailed source to be independently rechecked before taking numbers as canonical.
5. [Mohmadsalehi & Soghrati (2022)](https://doi.org/10.1016/j.cma.2022.115015) — numerical comparison used by 2023 Fig.17.
6. [Bittencourt et al. (1996)](https://doi.org/10.1016/0013-7944(95)00247-2) — classic 2D LEFM experimental comparison.

**No solver execution, numerical verification or experimental replication was performed as part of this reconstruction.**
