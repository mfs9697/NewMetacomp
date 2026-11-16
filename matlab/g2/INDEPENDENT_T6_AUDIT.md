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

## Actual first independent audit (2026-11-16 22:02:49 Kyiv): implementation exception, not a geometric verdict

The researcher executed the audit from this PR and supplied actual batch output. Free RAM **7.10 GiB**, R2023a, original inputs hashed by PowerShell:

```text
Source candidate SHA256:
9D74134FDF4765449C0F4E4EC87EA5B9E3B0A94B542A80E7E04DF3BC4EDC6A96

Pinned specimen JSON SHA256:
45A88FA0926472DDBE5E70E4C80A97B88196DD45D8A266FA04273F89790B47BF

Audit output:
outputs/g2_independent_t6/run_20261116_220249_096/
```

First audit stopped at **`g2_independent_t6_checker.m:102`**:

```text
Error using *
Incorrect dimensions for matrix multiplication.
dj=(x*dNr).*(y*dNs)-(x*dNs).*(y*dNr);
```

The root cause was our incorrect coordinate indexing `x=X6(T6,1); y=X6(T6,2);`. In MATLAB, this is not guaranteed to return **M-elements by 6-nodes** arrays for a matrix-valued row subscript. The intended, shape-safe operation is:

```matlab
x=reshape(X6(T6(:),1),size(T6));
y=reshape(X6(T6(:),2),size(T6));
```

The correction is isolated in `g2_independent_t6_jacobian.m`, a read-only **13-position** quadratic Jacobian helper. The original independent 38-gate checker calls this helper, leaving **all acceptance thresholds and other checks unchanged**.

A deterministic no-PDE synthetic test `check_g2_independent_t6_jacobian.m` is now called **before** loading the author's MAT:
- Two separate affine T6 elements with expected constant positive Jacobians **2 and 6 mm²**, verifying the exact **2-by-6** gathering layout.
- One inverted T6 that must be rejected as negative.
- One intentionally displaced midside producing a non-affine, nonconstant Jacobian that must be detected.
- Original inputs must not be modified.

**Test/code status:** source-level verification and independent arithmetic cross-check of these manufactured cases succeeded. **New MATLAB runtime has not yet been executed**, so do not claim the synthetic preflight or the 38 geometry gates passed. The original failed `run_20261116_220249_096` remains immutable and documented as **`HOLD_INDEPENDENT_T6_EXCEPTION`**; this is **NOT `HOLD_T6_GEOMETRY`**.

Repeat the same command below after fetching the latest PR head. It writes a new audit run, reads exactly the **same source candidate MAT and geometry JSON**, and does **not** regenerate a mesh. Expected first new evidence is `G2_INDEPENDENT_T6_SYNTHETIC_PASS=1`, followed by actual 38-gate results or another explicit diagnostic. A synthetic PASS does not imply 38/38 on the real candidate.

**If a geometric gate fails after the corrected Jacobian**, preserve its actual name and computed evidence. Do not suppress, weaken or reclassify it to get a PASS.

## Actual second independent batch (2026-11-16 22:09:01 Kyiv) — **38/38 PASS**

The researcher reran the corrected independent checker against the **same original saved geometry MAT** and immutable source JSON. This is actual MATLAB R2023a user-provided evidence, not local or CI execution by ChatGPT:

```text
Free RAM: 7.16 GiB
Source MAT SHA256:
9D74134FDF4765449C0F4E4EC87EA5B9E3B0A94B542A80E7E04DF3BC4EDC6A96
Source geometry JSON SHA256:
45A88FA0926472DDBE5E70E4C80A97B88196DD45D8A266FA04273F89790B47BF
G2_INDEPENDENT_T6_SYNTHETIC_PASS=1
G2_INDEPENDENT_T6_SYNTHETIC_POSITIVE_DET_RANGE=[2.000000000,6.000000000]
G2_INDEPENDENT_T6_SYNTHETIC_INVERTED_DETECTED=1
G2_INDEPENDENT_T6_SYNTHETIC_NONAFFINE_DETECTED=1
G2_INDEPENDENT_T6_GATES=38/38
G2_INDEPENDENT_T6_PASS=1
G2_INDEPENDENT_T6_BOUNDARY_LOOPS=4
G2_INDEPENDENT_T6_EULER=-2
G2_INDEPENDENT_T6_TIP=6
G2_INDEPENDENT_T6_MAX_RATIO=1.62557238
G2_INDEPENDENT_T6_MIN_ANGLE_DEG=33.63741002
G2_INDEPENDENT_T6_NO_LEFM=1
G2_INDEPENDENT_T6_GEOMETRY_ACCEPTED=1
G2_INDEPENDENT_T6_DONE=1; P010_PROTECTED_CORE_PENDING=1; NO_LEFM=1
```

**Original, untouched independent audit output directory:**
`outputs/g2_independent_t6/run_20261116_220901_848/`, including `independent_t6_summary.json` and console log on the researcher's machine.

**Decision:** ACCEPT **the current three-hole, three-annulus, pencil-collapsed `T3→T6` geometry-only candidate** as an independently checked geometric **reference baseline** for the next research stage. The first failed independent audit from 22:02 was an indexing/shape **implementation exception** and has been preserved; this rerun resolves that blocker without any source mesh regeneration.

**Important nuance:** this is a 38-gate independent audit of the existing **non-p010 straight-sided T6 candidate**; it does not certify a protected tip patch, physical boundary condition, mode-mixity, EDI support, SIF, crack trajectory or Cornell experimental match. The independent checker intentionally returns `approvedForLEFM=false` even with `38/38`. Do not merge draft PRs automatically; do not rename the current source mesh as a physics-ready benchmark. The next structural task is to port/adapt the source **3-mm/64-sector p010 tip patch + 0.3-mm collar** and perform new T3/T6 qualification on that **changed** mesh family, after which genuine experimental support/loading/CMOD source verification is still necessary.

**Provenance note:** The upstream `EdgeCrackHoleLEFM` p010 mesh has its own separate 15/15 kernel and 21/21 whole-T6 qualification; those pass counts are NOT to be copied to this Cornell geometry.
