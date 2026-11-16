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
