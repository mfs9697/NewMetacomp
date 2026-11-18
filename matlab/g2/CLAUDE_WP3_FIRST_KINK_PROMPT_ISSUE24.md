# Claude execution prompt — WP3 first kink in Cornell specimen #1

> **Ready-to-paste instructions for Claude Code.**
>
> Full authoritative assignment: [Issue #24](https://github.com/mfs9697/NewMetacomp/issues/24), continuing [Issue #20](https://github.com/mfs9697/NewMetacomp/issues/20). This file is a research brief only: **no crack-growth MATLAB run or kinked-SIF result has yet been produced by this assignment**.

---

Work in **`mfs9697/NewMetacomp`** as a fracture-mechanics researcher and MATLAB R2023a numerical developer. **Implement Issue #24 — a single signed-MTS kink followed by one independently validated kinked p010 mesh, one idealized signed-SIF recomputation, and deterministic one-step restart.** Do not start an uncontrolled crack-growth campaign or the LaTeX WP4 report.

## First: audit and protect proven work

Inspect the repository and all stacked open draft PRs, especially:

- [PR #22](https://github.com/mfs9697/NewMetacomp/pull/22), protected regular p010 and full three-hole mesh: head `81a7ea72d17f3c06949680d9bd2c7c9ece93b9d3`. Actual MATLAB P0 kernel 15/15 (original upstream geometry) plus **13/13 Cornell-specific** checks, full geometry 27,005 T3, min angle **30.127°**, max size-adjacency ratio **1.686**, independent **38/38 T6 + 24/24 protected tip**, six intentional failures detected.
- [PR #23](https://github.com/mfs9697/NewMetacomp/pull/23), signed SIF under the explicitly **idealized** pin/roller 1-kN model: head **`513044cc2c5e2db68fc6630c3fe356769abd5e83`**, stacked on #22. Actual R2023a manufactured Williams, classical Tada–Paris–Irwin, equilibrium, energy, contour, EDI and independent COD all passed preregistered tests. Initial **`K_I=0.166436`, `K_{II}=+0.018827` MPa√m per kN**.
- The original Cornell nominal geometry JSON `docs/research/crack-growth-gaps-2026/G2_SPECIMEN1_1990_GEOMETRY.json`, original unprotected-mesh MAT and saved R2023a evidence are **immutable**. Older PRs #13–#21 are also unchanged. No PR is merged.
- **Source-of-truth documents:** `matlab/g2/WP2_PREREGISTRATION.md`, `SIF_WP2_RESULTS.md`, `PROTECTED_MESH_WP1.md`, `P010_CORNELL_PORT_PLAN_2026-11-16.md`, and Issue #24. Check any more recent changes/actual logs before acting. Do not make undocumented assumptions about MATLAB execution.

**Create the WP3 implementation branch from the actual PR #23 head**, not `main`; use separate stacked draft PRs for kink geometry and conditional SIF/restart. Do not merge, rewrite, or edit previous approved artifacts. Begin with a concise audit and GO/HOLD table.

## Frozen analytical first-step reference — NOT a propagation event

Use Cornell's signed Mode I/II result and local basis at the *original* tip:

```matlab
KI   = 0.166436;   % MPa*sqrt(m) per kN
KII  = 0.018827;   % MPa*sqrt(m) per kN
tip0 = [101.6,25.4]; % mm
t0   = [0,1]; n0 = [-1,0];
theta = 2*atan2(-2*KII, KI+hypot(KI,sqrt(8)*KII)); % radians
da = 4;  % mm: provisional geometrical test increment only
t1 = cos(theta)*t0 + sin(theta)*n0;
tip1 = tip0 + da*t1;
```

Expected analytical values: **`theta = -12.5956937°`** (towards +x), **`cos(theta)=0.97593315`**, and trial tip **`(102.47227957,29.30373262) mm`**. These values are algebraic forecasts, not physical onset, executed FEM or propagated trajectories.

**Important blocker:** the pinned upstream `EdgeCrackHoleLEFM` general-polyline join has `MinKinkTangentDot=0.98`, which admits `|theta|<acos(0.98)=11.47834°`. Our required angle is larger. **Do not turn `0.98` into `0.97` just to obtain PASS**, claim the old two-hole gate applies to Cornell or silently cap the MTS prediction. Before meshing, preregister **new, independent Cornell-specific** polygon-miter, crack-bank offset, collar-entry, self-intersection and 3-hole clearance gates for this kink geometry. Then investigate the actual mesh and evidence. Treat geometrically inadmissible variants as HOLD.

## Implement in strict order

### A. WP3.0 — analytic MTS and preregistration

Commit `WP3_PREREGISTRATION.md` **before implementing/seeing the new mesher results**. Define the signed, tensile MTS root, sign convention, quality/admission thresholds and stop rules. Provide deterministic pure-I (`theta=0`), pure-II (opposite `±70.528779°`), sign-reversed Mode-II, general mixed-I/II and the Cornell initial trial tests, including the MTS stationarity residual and positive hoop-tension branch. Explicitly HOLD compression, zero `K`, degenerate roots, unknown propagation toughness or contact situations rather than defaulting to arbitrary turns.

### B. WP3.1 — ONE actually kinked, conforming protected mesh

Use the real original bottom-edge starter crack `(101.6,0)→(101.6,25.4)` mm and append **exactly one** `da=4mm` vector in the predicted direction. Rotate the **unchanged** 2,788-element/64-sector p010 local kernel and 128-element/0.3-mm collar to the new last-segment tangent; regenerate a new **full** PDE exterior with the 3 true holes, 3 nonphysical hole guide regions, tip guide and load/support vertices. Preserve 20-µm pencil half-width, two separate bank identities until the physical tip, 64+64 conforming seam edges, true circle boundaries, no overlaps and one connected solid.

**Do not reuse straight-crack checks as though they were kink-aware.** Audit and adapt the following without modifying the original baseline implementations: `g2_protected_exterior_mesh.m`, `g2_join_protected_mesh.m`, `g2_independent_t6_checker.m`, `g2_protected_tip_checker.m`, `g2_sif_cod.m`, and WP2 batch code. The current checkers explicitly assume `tip=(101.6,25.4)`, `x=101.6` for the whole crack, and `y`-sorted bank twins; these assumptions are false for a kinked path. Build **new, independent kink-aware audits** based on the saved crack polyline, dynamic tip/last-segment frames and exact T6 edge ownership, while keeping the old 38/38 and 24/24 straight-source tools available and unchanged.

Preserve genuine gates: **min T3 corner angle ≥20°, max neighboring longest-edge ratio ≤1.8**, every T6 Jacobian positive, unique midside per edge, exact two-owner conforming seams, the p010 source core identity, 2,443 active FE-nodal-q parents within the protected region, no bank welds, 3 physical holes, **4 physical boundary loops and Euler −2**, actual updated tip tangent and safe crack-to-hole/plate clearances. Include negative controls for bank welding, seam mismatch, unphysical q-support, inversion, miter pathology and intersecting geometry. Retain the 5-GiB free-RAM guard and the normal 40k T3 primary budget; deviations require separate preregistration and clear HOLD/qualified-family categorization.

**Stop downstream work** if the actual MATLAB R2023a kinked mesh or its new independent auditors do not PASS. Never manufacture a PASS from old checkers.

### C. WP3.2 — conditional ONE idealized kinked-tip SIF calculation

**Only when B has independently passed in real MATLAB.** Solve exactly the declared WP2 **idealized** pin/roller, 1-kN top-midpoint load, plane-stress BVP, same `E,ν` and 12.7-mm thickness. Recompute **signed `K_I,K_{II}`** in the *new* local crack-tip tangent frame by both (1) FE-nodal-q interaction/domain integral and (2) independently classified crack-face COD/sliding jump, using the existing pre-registered 0.1–1.5-mm COD fit window. Keep the full q-support within the 3-mm p010 core and clear of the previous kink, 4mm behind the new tip.

On the kinked geometry verify solver equilibrium/residual, signed pure-I/II/mixed rotated manufactured cases, multiple q annuli and path-independence, quadrature, `J=(K_I^2+K_{II}^2)/E'`, and two independent SIF estimates. Preserve the applicable WP2 limits: equilibrium ≤1e−8, EDI vs COD ≤3% `K_ref`, path-independence ≤0.5%, energy identity ≤0.5%. Do not adjust COD fitting window, sign or q radii post hoc to force convergence. Report new values **only if actually calculated**. This remains an idealized BVP result, not Cornell experimental calibration.

### D. WP3.3 — conditional deterministic one-step replay

Only after C's actual PASS, implement an explicit `forecast → geometry → independent audit → signed SIF → accept ONE numerical trial state` interface. Preserve the original state with separate hashes and immutable logs; verify reproducibility on restart and negative-control HOLD. **No second step, unbounded loop or physical onset declaration** in this assignment. Missing `K_{IC}/G_c`, original CMOD/load/contact or experimental trajectory remains a scientific limitation, not a value to invent.

### E. Deliverables, review, and work policy

Provide MATLAB R2023a source and batch/PowerShell launchers, code and negative controls, immutable `outputs/g2_wp3_*/run_*/` evidence, SHA-256 input/output hashes, exact source commits and run commands, `WP3_FIRST_KINK_RESULTS.md`, a true MATLAB figure of the **rotated regular kernel/collar** and first kinked mesh, plus signed SIF contour/COD plots **only if** C passes. Use separate draft PRs stacked on PR #23 and link them to [Issue #24](https://github.com/mfs9697/NewMetacomp/issues/24) and parent Issue #20. No merge. Do not write the WP4 LaTeX report under this scope.

**First report:** show current PR state, verified vs NOT RUN, the exact MTS reference, why 12.60° exceeds the inherited 11.48° numerical geometry guard, the proposed independent kinked-geometry qualification, and one next executable batch. Then carry out the work in this session to the extent actual tools and MATLAB allow.

If MATLAB cannot be run, deliver source-ready scripts and exact commands and mark all new numerical checks `RUN PENDING`. Never invent new angles, signed SIF pairs, experimental values, checksums or a completed crack trajectory. Any failed stage means HOLD, with diagnosis and retained evidence.

**This assignment succeeds only if the verified WP2 base remains intact and the ONE kinked prototype is truly independently qualified.** One verified kinked-tip SIF and restart extend success conditionally; a complete growth campaign and LaTeX paper are later work.

---
