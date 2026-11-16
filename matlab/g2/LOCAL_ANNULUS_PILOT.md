# G2 / Cornell specimen #1 — local annular face-refinement pilot (16 Nov 2026)

**Classification:** single candidate **geometry-only** meshing study stacked on draft PR #13. **No FEM/LEFM, COD/EDI/SIF or crack propagation.** MATLAB **R2023a + PDE Toolbox 3.10**. Original Cornell geometry JSON and existing qualified upstream `EdgeCrackHoleLEFM` sources are untouched.

## Evidence-based localization

The user's **actual** `Hmax=6mm` batch, `run_20261116_200724_582`, obtained:

| Quantity | Native / collapsed observed |
|---|---:|
| Minimum T3 angle | 26.26756357° / same |
| Worst adjacent-longest-edge ratio | 2.25936462 / same |
| T3 edges above the unchanged 1.8 limit | 19 of 27,520 / same |
| Same failing T3 edges native vs collapsed | true |

The subsequent **read-only 19-edge** clustering found:
- **15 near upper hole #3**, wall clearances **2.49–3.56 mm**.
- **4 near lower hole #1**, wall clearances **6.73–9.54 mm**.
- **0 near middle hole #2**.
- **15** of 19 within one `R=6.35mm` of the nearest hole wall, **4** between `R` and `2R`, **none beyond `2R`**.
- Existing failed IDs remained identical pre/post collapse; the native PDE mesh (not pencil collapse) is the first target for intervention.

This distribution excludes both a crack-tip defect and a need for immediate global refinement. It also indicates that the 19 failures have **two spatial groups**: upper and lower, not upper alone.

## One experimental intervention — annular material subdomains / local Hface

MATLAB's `generateMesh` supports `Hface` on 2D material subdomains and has done so since R2021b ([MathWorks documentation](https://www.mathworks.com/help/pde/ug/pde.pdemodel.generatemesh.html)). `nearestFace` identifies their IDs ([MathWorks documentation](https://www.mathworks.com/help/pde/ug/discretegeometry.nearestface.html)), and `decsg` constructs their decomposed 2D boundary arcs ([MathWorks documentation](https://www.mathworks.com/help/pde/ug/decsg.html)).

The opt-in pilot adds **two helper circles of radius `3R=19.05mm`**, at original holes #1 and #3, as **internal CAD boundaries**. They do not remove any physical material. The 3 real circular holes (radii **6.35mm**) remain unchanged. A CSG decomposition yields **three connected material faces** (bulk + two annuli). If `NumFaces ~= 3` or interior sample points do not identify three distinct faces, return **`HOLD_LOCAL_ANNULUS_PARTITION` before meshing**, preserving the face-labeled CAD diagnostic plot.

For this single run, set:
- **`Hmax=6mm`**, unchanged from actual author baseline.
- **`Hface=1.5mm` ONLY on lower + upper annular material faces**; no new target on the middle hole or bulk material.
- Retain `Hmin=0.12mm`, `Hgrad=1.12`, lip `Hedge=0.45mm`, `ChannelHalfWidth=0.020mm`, 3 original CAD circles, pencil-collapse algorithm, 40k-element work budget.
- Retain **minimum T3 angle >=20°** and **adjacent longest-edge ratio <=1.8**. No relaxation, special-case acceptance or automatic retry.
- Expect `4` actual material boundary loops (external/slit + 3 holes); new internal 3R subdomain edges must NOT be counted as added holes.
- `approvedForLEFM=false` even if all candidate gates pass; no protected p010 tip core/collar, no independent whole T6 checker yet.

**Suggested one-shot command** from the complete local checkout of this branch:

```powershell
git fetch origin
git switch research/g2-local-hole-annulus-pilot-20261116
git pull --ff-only

powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_specimen1_pencil.ps1 -Hmax_mm 6 -LocalHoleAnnulusHface_mm 1.5 -MinFreeGiB 7
```

This creates a NEW unique folder under `outputs/g2_specimen1_pencil/run_*/`. The 7-GiB RAM guard is conservative because an internal-partition mesh is a new sizing family. A memory HOLD does not mean CAD failure. The existing local Hmax7 and Hmax6 outputs remain untouched. No commands that resemble log output are needed.

Review:
- `G2_LOCAL_CAD_FACE_PREFLIGHT_PASS`, `G2_LOCAL_CAD_FACE_IDS` and `G2_CAD_MATERIAL_FACES`;
- `G2_T3_NATIVE_MAX_RATIO`, `G2_T3_NATIVE_RATIO_HOLDS`, `G2_T3_COLLAPSED_MAX_RATIO`, `G2_T3_SAME_FAILED_EDGE_IDS`;
- `HOLD_STAGE` or `CANDIDATE_GEOMETRY_PASS`, `batch_summary.json` and `quality_forensics.json`;
- `quality_worst_edge_zoom.png`, `mesh_candidate_overview.png` (plot labels indicate whether held at CAD or postmesh).

**Scientific decision after this one run:** compare 3 real holes / actual material area, quality after collapse, and new native PDE grading. If `HOLD_LOCAL_ANNULUS_PARTITION`, first repair source CSG without changing mesh parameters. If `HOLD_T3_QUALITY`, use exact new worst-edge locations and observed quality to decide whether an annular sizing transition requires a second protected region, but **do not immediately launch sweeps**. If geometry candidate passes, continue only to **Issue #14** protected p010 core/collar and independent T6 verification, NOT elasticity.

## No runtime claim

Source was reviewed statically; assistant does not have MATLAB available. The modified `decsg` boolean, 3-face topology, target size, work budget and all stability gates are **hypotheses pending real MATLAB R2023a execution**. The Hmax6 author's observed `HOLD_T3_QUALITY` remains a HOLD.

**No PR merged.**
