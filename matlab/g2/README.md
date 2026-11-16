# Recommended workflow: MATLAB R2023a BATCH + experimental pencil collapse

**Researcher decision (16 Nov 2026):** all new geometry runs use `matlab -batch`; crack faces are modeled by a finite-width **pencil channel and guarded collapse**, following the established *geometry strategy* of [EdgeCrackHoleLEFM](https://github.com/mfs9697/EdgeCrackHoleLEFM). The previous `build_g2_specimen1_geometry.m` remains an **uncracked illustration only** and MUST NOT substitute for the crack mesh.

**Latest upstream family audited:** `src/trajectory/edge_trajectory_candidate_mesh_pencil_p010.m`, `edge_pencil_join_native_mesh.m`, `edge_pencil_crack_banks_from_topology.m`, `edge_pencil_mesh_invariants.m` in EdgeCrackHoleLEFM main @ `a14d8872ab588ac551e41b4531bffee2dcd0ce2c`. The H0 trial C evidence is [H0_PENCIL_P010_QUALIFIED_GEOMETRY_REFERENCE_2026-10-28.md](https://github.com/mfs9697/EdgeCrackHoleLEFM/blob/main/docs/H0_PENCIL_P010_QUALIFIED_GEOMETRY_REFERENCE_2026-10-28.md). **Do not reuse its two-hole 300×400-mm hard-coded geometry/BC as Cornell #1.**

### One command on Windows

From a local checkout of **branch `research/g2-pencil-collapse-batch-20261116`** (which includes stacked PR #12 and original geometry JSON), in PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_specimen1_pencil.ps1
```

The launcher checks for MATLAB R2023a, **at least 5 GiB free physical RAM**, and source JSON, then executes `matlab -batch`. Headless MATLAB produces an **immutable per-run folder** under `outputs/g2_specimen1_pencil/run_YYYYmmdd_HHMMSS_FFF/` with `batch_console.log` and `batch_summary.json`. On a candidate pass it additionally writes `GEOMETRY_ONLY_candidate.mat` (T3/T6 arrays and bank IDs) and a vector PDF/PNG if plotting succeeds. On a HOLD the batch exits **nonzero**, and the exact stage/reason is in the summary. Generated output is ignored by Git.

The pilot `g2_specimen1_pencil_mesh.m` does **not** import physical source states or solve a PDE:
1. Read nominal specimen #1 JSON (508×203.2 mm, three exact CAD circles, initial `(101.6,0)→(101.6,25.4)` mm).
2. Subtract a pencil-shaped channel with half-width `0.020 mm` from the bottom boundary; preserve the single geometric tip.
3. Native PDE `generateMesh` (T3 **geometry**, with `Hmin=.12mm`, `Hmax=7mm`, `Hgrad=1.12` and lip `Hedge=.45mm` pilot targets).
4. Identify both physical lip chains, pair their arclength stations, adjust each pair to the centerline **while preserving distinct node IDs** and leave **only one common tip**. Reject mismatched numbers/stations, bad quality or lost topology; no invented correspondence or blind retry.
5. Construct straight-sided T6 with unique midsides, check 4 boundary loops (outer + three holes), each circle's boundary, T3 angles/neighbor growth, bank chains and solid area.

**Crucial difference from verified upstream H0/H3:** this isolated *first transfer* currently does **NOT** incorporate the upstream **3-mm structured p010 tip patch** or **0.3-mm analytical collar**, nor the original independent 21-gate T6 checker. Thus even if `CANDIDATE_TOPOLOGY_PASS`, the flag `approvedForLEFM=false` is never relaxed. In particular, **do not calculate K, G, COD, EDI or crack paths from this candidate mesh**. Follow-up engineering must port/pin the protected p010/collar for the **vertical crack, three circles, eccentric load geometry**, qualify the final conforming T3/T6 mesh and obtain independent signed EDI/COD before any physics.

This branch contains **unexecuted MATLAB source**. Static checks are not runtime evidence. The first `-batch` invocation may produce `HOLD_UNMATCHED_LIP_COUNTS`, `HOLD_T3_QUALITY` or another genuine diagnostic; that is a useful preflight, not a scientific failure to conceal. Never loosen thresholds or replace the tip by coincident but welded IDs to claim success.

### Older geometry-only display

# MATLAB geometry-only reconstruction — Cornell (1990), specimen #1

This directory constructs **the nominal specimen #1 geometry**, as recorded in [G2_SPECIMEN1_1990_GEOMETRY.json](../../docs/research/crack-growth-gaps-2026/G2_SPECIMEN1_1990_GEOMETRY.json), and **nothing more**.

## Run in MATLAB R2023a (requires PDE Toolbox)

From the root of your local checkout of `NewMetacomp`:

```matlab
addpath(fullfile(pwd,'matlab','g2'));
R = build_g2_specimen1_geometry();
ok = check_g2_specimen1_geometry();
```

The first command reads the source JSON with **millimetre coordinates**, validates the geometry, constructs a two-dimensional PDE geometry by the **exact set difference `R1-H1-H2-H3`** with **true circles** (`decsg` / `geometryFromEdges`), and creates an annotated figure. It exports:

- `matlab/g2/output/G2_Specimen1_1990_nominal_geometry.pdf` (vector);
- `matlab/g2/output/G2_Specimen1_1990_nominal_geometry.png` (240 dpi);
- `matlab/g2/output/G2_Specimen1_1990_nominal_geometry.fig` (editable MATLAB figure).

The second command performs a MATLAB-only internal geometry check with no output files and closes its test figure. These checks are **not yet run/observed in this repository**; they are supplied for the researcher to execute in MATLAB.

If your current folder is not the repo root, run using the known local clone absolute path. The MATLAB function locates the JSON relative to its own file, so it does not depend on the MATLAB current working directory. To suppress output:

```matlab
R = build_g2_specimen1_geometry('Visible','off','Export',false);
```

To inspect the exact PDE **uncracked** model and numbered boundary edges in MATLAB:

```matlab
figure; pdegplot(R.model,'EdgeLabels','on'); axis equal
```

## Essential caveat about the crack

**The red vertical starter crack in the drawing is ONLY a plot annotation** `(101.6,0) → (101.6,25.4) mm`. There is no actual split-bank slit in `R.model`. Do not call `generateMesh` and then infer crack-tip SIFs or propagation from the uncracked PDE solid. For LEFM we must construct separate topological crack-face banks, qualified tip patch and extraction domains; that is a distinct subsequent task.

The physical test was CMOD controlled. The marker `P` shows **where the load is applied**, not its measured magnitude/time history. Support symbols are idealizations. Material values, plane stress versus plane strain, and CMOD/contact relations are deliberately **not** coded. No mechanics or FEM operation runs here.

## Nominal dimensions (millimetres)

| Entity | Values |
|---|---|
| Plate | \(508 \times 203.2\), thickness \(12.7\) |
| Circle centers (bottom to top) | \((152.4,69.85)\), \((152.4,120.65)\), \((152.4,171.45)\) |
| Each circle | \(R=6.35\) |
| Initial crack annotation | mouth \((101.6,0)\), tip \((101.6,25.4)\) |
| Top-center load | \((254,203.2)\), down; \(P\) unknown |
| Supports | \((25.4,0)\) pin and \((482.6,0)\) roller, idealized |

**Provenance/holds:** [G2_SPECIMEN1_1990_SOURCE_AUDIT.md](../../docs/research/crack-growth-gaps-2026/G2_SPECIMEN1_1990_SOURCE_AUDIT.md). The nominal dimensions have corroborating later redrawings, but direct visual inspection of the original Cornell scans and specimen-specific material/contact details is still pending. The plotted figure therefore says **nominal** and cannot be presented as a completed experimental verification.

## Acceptance before the next stage

1. Run `check_g2_specimen1_geometry` in MATLAB R2023a with PDE Toolbox.
2. Visually verify the vector PDF and the edge-labelled PDE geometry (exact 3 holes, no extra face/edge).
3. Save the MATLAB console output and figure as evidence and compare the original Cornell Fig. 5.1/5.2 when archival scan becomes available.
4. Only then consider *separate crack-bank topology/meshing task*; still no automatic permission for physical LEFM runs.
