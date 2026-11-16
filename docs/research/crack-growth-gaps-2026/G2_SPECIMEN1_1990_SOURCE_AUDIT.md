# G2 / V0–E — Ingraffea–Grigoriu (1990), **holed experimental specimen #1**
**Reconstruction:** 2026-11-16. **Evidence level:** high-confidence *nominal geometry* from Cornell report OCR and visually inspected two later technical re-drawings; **not** certified as specimen-specific metrology or a fully reconstructed physical BVP. **No FEM or mesh run.**

## 1. First-party historical identity (avoid conflation)
**Source:** A. R. Ingraffea, M. Grigoriu, *Probabilistic Fracture Mechanics: A Validation of Predictive Capability*, Cornell University Structural Engineering Report **90-8** (August 1990), `DTIC ADA228877`. Its **Section 5** includes seven drilled Plexiglas (PMMA) specimens with the same body and holes and different starter-crack parameters. The hole-bearing **specimen #1** is unambiguously `a=1 inch`, `d=6 inches`; verify original Figs **5.1, 5.2, 5.5, 5.8**.

- [1990 archival record](https://apps.dtic.mil/sti/citations/ADA228877); [accessible OCR transcription](https://www.academia.edu/144534340/Probabilistic_fracture_mechanics_A_validation_of_predictive_capability), particularly §5 pp.52–64, Appendix A. **The actual archival PDF/scans could not be obtained or inspected visually**, so direct figure-source verification remains **PENDING**.
- [Peterson & Cairns (2015), ICCM20, Fig.11, PDF page 7](https://wmpeterson.com/files/peterson-iccm-2015.pdf) [***visually examined***]: exact 20×8 body, common three-hole geometry, dimensions and 18-inch support span. Their **notch is a=2.5 in, d=6 in**, so **DO NOT** copy their crack length, model `E=450000 psi`, `ν=.35`, cohesive parameters or prescribed actuator displacement as original specimen #1 properties.
- [Holl (2014), dissertation, Fig.5.3, printed p.55](https://www.ikm.uni-hannover.de/fileadmin/ikm/publications/2014_Holl_PhD_Thesis_01.pdf) [***visually examined***]: independently shows a dimensionally matching 20a×8a, 3-hole arrangement with `a=25.4mm` as **unit length** and original support scheme; his starting slit has length **1.5a** at **x=5a** and is a different specimen than Cornell #1.

**Do not confuse this with Cornell report Section 4's unperforated “specimen #1” of `a=1in,d=6in`, with 2023 Alshoaibi–Fageehi Fig.16 `a=1cm,d=5cm`, or with the 2015 Peterson demonstration `a=2.5in,d=6in`.** Even when the relative starter labels coincide, the presence of three holes is essential.

## 2. Nominal body/holes/crack geometry (source-frame inches; coordinates of exterior bottom-left = (0,0))
**Units:** 1 in = exactly 25.4 mm. All coordinates are a reconstruction of **nominal design geometry**, not scanned micrometric measurements of the 1990 machined sample.

| Entity | Imperial nominal | MATLAB SI coordinates |
|---|---|---|
| Plate outline | `x∈[0,20]`, `y∈[0,8]` in | `x∈[0,0.508]`, `y∈[0,0.2032]` m |
| Plate thickness | `0.5` in | `0.0127` m |
| Upper hole | center `(6,6.75)` in; Ø`0.5` in | center `(152.4,171.45)` mm; `R=6.35` mm |
| Middle hole | center `(6,4.75)` in; Ø`0.5` in | center `(152.4,120.65)` mm; `R=6.35` mm |
| Lower hole | center `(6,2.75)` in; Ø`0.5` in | center `(152.4,69.85)` mm; `R=6.35` mm |
| Hole-center pitch | `2` in vertically | `50.8` mm |
| Initial crack mouth | `(4,0)` in | `(101.6,0)` mm |
| Initial crack tip | `(4,1)` in | `(101.6,25.4)` mm |
| Starter length `a` | `1` in | `25.4` mm |
| Offset `d` from load centerline | `10−4=6` in | `152.4` mm |
| Top load point | `(10,8)` in, `-y` | `(254,203.2)` mm |
| Left support | `(1,0)` in | `(25.4,0)` mm |
| Right support | `(19,0)` in | `(482.6,0)` mm |
| Span | `18` in | `457.2` mm |

**Derivation of the holes:** 2015 Fig.11 gives horizontal distance **4 in** leftwards from the centered load line `x=10`, so `x_h=10−4=6`. The upper center is **1.25 in** below the top `y=8`, so `y_{upper}=8−1.25=6.75`; the next two centers each lie **2 in** lower. All radii are `0.5/2=0.25` in. Support center positions `x=1,19` follow from the 20-in total and 18-in displayed symmetric support span; left support is visually offset 1in. The initial crack is **6in left of load** so x=4in and extends **1in upward**. The 2015 secondary drawing was visually checked in the PDF image, not merely via text extraction.

**Geometric start-tip clearance:** `sqrt((6−4)^2 + (2.75−1)^2) − 0.25 ≈ 2.40754 in ≈ 61.1514 mm` to the *lower-hole wall*. This is an **exact nominal Euclidean geometry result** (within displayed decimals), **not** a qualified FEM q-domain or K-dominance result.

A versioned input is saved as [G2_SPECIMEN1_1990_GEOMETRY.json](G2_SPECIMEN1_1990_GEOMETRY.json). This is our **single-source-of-truth proposal** for geometry-only MATLAB plotting. No hand-transcribed COMSOL dimensions, no arbitrary physical parameter defaults.

## 3. Boundary conditions and physical loading: not entirely determined by Figure 5.1
Three-point bending:
- **Idealized 2D support model, to be confirmed/approved:** left pin `u_x(1,0)=u_y(1,0)=0`; right roller `u_y(19,0)=0`, `u_x(19,0)` free. Contact conditions of finite support pads are not specified in the accessible source. Original text §6.4 discusses sensitivity to horizontal restraint of roller support, reinforcing importance of this qualification.
- Top-center resultant `P` acts downward at `(10,8)` in. **Do not hardcode a numeric P** as an original experimental load: tests were **slow CMOD controlled**, and `P(t)` was observed response. For a first frozen-tip **normalized linear elastic** calculation, a reproducibly defined unit external load is possible, but it is *not the original CMOD loading history* and requires a stated 2D thickness/load conversion.
- Other edges, slit banks and hole walls are nominally traction free; external support/indenter contacts are not zero-width in a real experiment.
- Cross-section width 0.5in may motivate a plane-stress approximation, but **plane stress vs plane strain was NOT independently established for this specific original experiment**. Do not interpret `G=(K_I²+K_{II}²)/E'` numerically without fixing the correct `E'` assumption.
- Starter saw kerf width/natural razor precrack: original report describes a band-saw notch followed by razor; **initial crack in JSON is a zero-width idealization**. Some later models prescribe kerf `0.05in`, which is **not a verified as-manufactured dimension of specimen #1**.

The 1990 report identifies approximate fabrication tolerances of **±1/32 in** on external dimensions, **±1/64 in** on notch length and **±0.25°** on notch direction; these are fabrication capabilities, not directly recorded actual errors for this sample. Original precrack shape, contact compliance, and actual CMOD history have not been retrieved.

## 4. Material parameters: separate experimental averages from later modeling choices

| Origin | Young's modulus | Poisson's ratio | Appropriate interpretation |
|---|---|---|---|
| Cornell 1990 Appendix A, 4 **unperforated calibration specimens** | Mean **474,000 psi ≈ 3268.1 MPa**, roughly 6% variation | **not established in accessible OCR for perforated specimen #1** | General material calibration, **not** this particular perforated sample's measured modulus |
| Manufacturer in Cornell 1990 | **450,000 psi ≈ 3102.6 MPa** | unknown | Nominal PMMA properties |
| Peterson–Cairns 2015, **another** specimen `a=2.5,d=6` | **450,000 psi**, `ν=0.35` | **0.35** | Reproduction-specific modeling parameters; do not promote to original fact |
| Alshoaibi–Fageehi 2023 Fig.16 `a=1cm,d=5cm` | **2800 MPa**, `ν=0.30` | **0.30** | **Different** geometry and scale, must not be mixed |

Cornell's text also reports an independently measured mean fracture toughness `K_{Ic}≈944 lb in^{-3/2}` for its broader PMMA test program. That value **does not by itself supply this specimen's initiation force nor a valid 2023-model toughness**, and is not needed for first *unit-load* normalized (K) and MTS comparisons. The actual `K_{Ic}`, `G_c`, `E` and `ν` for a particular perforated sample are not yet individually pinned.

## 5. Scientific observation and benchmark target
Cornell **Fig.5.5** compares *observed* paths of holed vs no-hole specimens for `a=1,d=6`, and **Fig.5.8** compares the *observed path with holes* against a PROFRANC-predicted path. The report says that the trajectory of specimen #1 leads into a hole. **This is a geometrical interception, not proof of `G<G_c`**. PROFRANC's historical `Δa=0.25in=6.35mm` numerical path stopped when the tip was within `~0.1R` of a hole, because it did not automatically insert a kink into a free surface. These are benchmark protocol facts, not the user's newly simulated results.

**No vector ground-truth tip coordinates were obtained from the original paper.** Do not claim a numerical path error or trajectory agreement until first-party figure scanned, scales/digitization uncertainty recorded and *matching* specimen verified. If the original report's figure is unavailable, label any later overlay **secondary visual comparison**, not experiment-validated path accuracy.

## 6. Geometry-only qualification checklist before MATLAB
- [x] Nominal specimen identity `a=1,d=6`, no accidental substitutions from 2023 figure or 2015 `a=2.5`.
- [x] Same 3 holes in all seven original holed configurations; nominal `x=6`, `y=2.75,4.75,6.75` based on two independently visually inspected technical diagrams.
- [x] Common `20×8×0.5`, support span 18 and 1-in end offsets, load at center.
- [x] Source coordinates in inches, exact SI conversion, geometric clearances; no voids overlap initial slit.
- [ ] **Original Cornell Fig.5.1 and Fig.5.2 high-resolution page inspected** (archival DTIC inaccessible in current tools). Before declaring *source-certified exact* input, visually compare directly.
- [ ] Extract actual specimen #1 notch measurement and choose reference `E,ν`; experimental plane state/contact formulation not established.
- [ ] Acquire original specimen #1 **Fig.5.5 and Fig.5.8** in printable resolution and define path-digitization uncertainty.
- [ ] Approve MATLAB geometry-only render as a separate step; **do not solve FEM or propagate cracks in this source-verification stage**.

## 7. Disposition
**Scientific recommendation:** the **nominal geometry is sufficiently corroborated to implement a *geometry-only MATLAB drawing and topological preflight***. It is **not sufficiently verified to claim an exact experimental BVP, absolute `K_I,K_{II},G`, or quantitative experimental path match**. We should explicitly freeze the source hierarchy and uncertainty flags in code rather than silently replacing unavailable values by `E=2.8GPa,ν=.3` or `plane strain`.

Original documents `proposal2.tex` and existing PDF/DOCX files are unchanged; this report is a separate addition on a draft stacked GitHub branch. **No FEM/CZM executed.**
