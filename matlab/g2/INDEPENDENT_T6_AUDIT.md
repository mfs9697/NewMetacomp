# Cornell #1 — independent saved-mesh T6 geometry audit

**Status:** prepared as new draft research code, NOT executed in MATLAB yet. This audit is independent of the pencil-mesh generator: it reads the researcher's **already-generated accepted geometry candidate**, without invoking `decsg`, `generateMesh`, `g2_specimen1_pencil_mesh` or any physical solver. It does not edit the source run.

## Canonical author input

2026-11-16 21:43:46 Kyiv, MATLAB R2023a and PDE 3.10, author-reported `CANDIDATE_TOPOLOGY_PASS`:

```text
outputs/g2_specimen1_pencil/run_20261116_214346_310/
    GEOMETRY_ONLY_candidate.mat
    batch_console.log
    batch_summary.json
    quality_forensics.json
    mesh_candidate_overview.png
```

The MAT was written from a successful run: `X3` 12018×2, `T3` 23207×3, `X6` 47245×2, `T6` 23207×6, two distinct 105-node T6 bank arrays and shared tip ID 6. T3 angle 33.63741002°, max adjacent size ratio 1.62557238, zero of 34394 interior edges above 1.8. This is **actual author evidence**, but has not been independently checked in ChatGPT.

## Exact next one-time command: NO REMESH

From the local repository root:

```powershell
git fetch origin
git switch research/g2-independent-t6-audit-20261116
git pull --ff-only

powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_independent_t6.ps1 -RunDir ".\outputs\g2_specimen1_pencil\run_20261116_214346_310"
```

The PowerShell launcher verifies source MAT + nominal JSON existence, prints **SHA-256 hashes** of the two original inputs for provenance and enforces a minimum of 5 GiB free physical RAM before starting `matlab -batch`. It does not modify either original input.

MATLAB writes one new folder under `outputs/g2_independent_t6/run_YYYYmmdd_HHMMSS_FFF/` with `independent_t6_console.log` and `independent_t6_summary.json`. A failed gate produces an explicit `HOLD_INDEPENDENT_T6` and exit 1; no source mesh is changed. The author should share the console and summary for review.

## Independent checks

`g2_independent_t6_checker.m` implements **38 separate Boolean geometry-only tests** using only the saved arrays and the original source JSON. These include:
- Original three-hole dimensions, all array/index shapes, no orphans, all six T6 local IDs distinct, T3 corners and T6 midsides disjoint;
- Rebuilt unique topological edges, exactly one midside per edge, midpoint coordinates, absence of nonmanifold edges, equality `N6 = N3 + edges`;
- Independently calculated T3 angles, adjacent-longest-edge ratios, and quadratic T6 Jacobian at 13 evaluation points (constant, strictly positive for straight T6 elements);
- Complete boundary edge classification into plate sides, three actual CAD-circle chord faces, and two crack faces; 4 boundary components (outer/slit + 3 distinct holes), plate perimeter and twice 25.4mm crack length;
- Exactly one connected material body (internal 3R helper guide circles **are not physical holes**), Euler characteristic `V-E+T=-2`, original area minus the three disks up to explicitly allowed circular-chord error;
- Two distinct T6 banks whose paired coordinates coincide, exactly one common undeformed tip, full crack boundary coverage with geometrically paired twin edges, no duplicates off crack.

**Purposefully excluded:** previous two-hole frozen support-DOF IDs and boundary traction assumptions; p010 3mm protected tip core/collar; q-support and its EDI radii; COD, stress intensity factors, material properties, CMOD, or the unknown experimental load/contact. The independent checker is **not** the upstream protected-p010 21-gate verifier and must not be passed off as a substitute.

A successful `INDEPENDENT_T6_GEOMETRY_PASS` is an additional *geometric* check only: `approvedForLEFM=false`, `p010TipCoreQualified=false` always. It would help qualify the stored **candidate**, not authorize fracture mechanics until the protected tip mesh is transferred and the full final mesh independently verified again.

## Mathematical consistency already checked from console counts

`E = 47245 - 12018 = 35227`, `B = 2(35227)-3(23207)=833`, `I=35227-833=34394`, `chi=12018-35227+23207=-2`. The independent MATLAB check recomputes these from connectivity rather than taking the reported counts on trust.

**No claimed independent runtime PASS yet.** Do not merge or perform mechanics on this basis.
