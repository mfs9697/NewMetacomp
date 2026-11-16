# Cornell specimen #1 — successful three-annulus geometry-only candidate (author's actual MATLAB batch)

**Researcher run:** 2026-11-16 21:43:46 (Kyiv), MATLAB R2023a 9.14.0.2206163, PDE Toolbox 3.10. Console and original generated files remain on the researcher's Windows checkout (not uploaded or committed):

```
outputs/g2_specimen1_pencil/run_20261116_214346_310/
```

**Provenance:** `research/g2-three-hole-annulus-pilot-20261116` (draft PR #16 stacked over #15 → #13). All three original Cornell specimen #1 circular holes are represented with true CAD circles; the three **nonphysical** 3R=19.05mm guide circles partition remaining **material** into 4 PDE faces (bulk + 3 annuli). No fourth physical hole. Hole radius is 6.35mm, plate 508×203.2mm, crack `(101.6,0)→(101.6,25.4)mm`. Experimental mechanical BVP remains unspecified. No FEM solve was performed.

## Frozen control and actual diagnostic console

| Parameter | Author actual |
|---|---:|
| Global Hmax | 6mm |
| All 3 hole-local Hface targets | 1.5mm |
| Annular guide outer radii | 19.05mm |
| Hmin | 0.12mm |
| Hgrad | 1.12 |
| Pencil lip Hedge | 0.45mm |
| Pencil channel half-width | 0.020mm |
| Max T3 allowable | 40,000 |
| Min T3 angle required | ≥20° |
| Max adjacent T3 longest-edge ratio | ≤1.8 |
| Original physical hole count | 3 |

MATLAB **actually reported**:

```text
PDE_PREFLIGHT_PASS=1
T3_FORENSICS_SELFTEST_PASS=1
G2_LOCAL_CAD_FACE_PREFLIGHT_PASS=1
G2_LOCAL_CAD_FACE_IDS=[1 2 3]
G2_LOCAL_CAD_FACE_COUNT=4
G2_T3_NATIVE_MIN_ANGLE_DEG=33.63741002
G2_T3_COLLAPSED_MIN_ANGLE_DEG=33.63741002
G2_T3_NATIVE_MAX_RATIO=1.62557238
G2_T3_COLLAPSED_MAX_RATIO=1.62557238
G2_T3_NATIVE_RATIO_HOLDS=0/34394
G2_T3_COLLAPSED_RATIO_HOLDS=0/34394
G2_T3_SAME_FAILED_EDGE_IDS=1
CANDIDATE_GEOMETRY_PASS=1
P010_PROTECTED_CORE_QUALIFIED=0
FEM_ADMISSIBLE=0
G2_CANDIDATE_DONE=1; SOURCE_P010_PENDING=1; NO_ELASTICITY_SOLVE=1
```

The `G2_T3_SAME_FAILED_EDGE_IDS=1` result is a **vacuous equality of two empty failure sets**, not positive validation of all paired crack nodes on its own; the other code's banks/topology gates provide those checks.

The returned MATLAB struct showed `coord3 [12018×2]`, `connect3 [23207×3]`, `coord6 [47245×2]`, `connect6 [23207×6]`, 105 nodes on **each separate T6 crack bank**, and one common `physicalTipNode=6` (MATLAB node index; not geometry-wide anchor). All candidate gates reported `pass=1`, `stage='CANDIDATE_TOPOLOGY_PASS'`. The specimen-specific mesher returned `approvedForLEFM=0`, `p010TipCoreQualified=0` and `physicalSolvePerformed=0`.

### Independent combinatorial cross-check from **reported counts only**

With straight-sided T6 constructed as T3 corners plus one midside per unique edge, the reported numbers imply

```
unique T3 edges E = N6 - N3 = 47,245 - 12,018 = 35,227
boundary edges B = 2E - 3T = 2(35,227) - 3(23,207) = 833
interior edges I = E - B = 35,227 - 833 = 34,394
Euler characteristic = V - E + T = 12,018 - 35,227 + 23,207 = -2.
```

The computed interior-edge count **exactly matches** the native and collapsed quality forensics `34,394`. For a single connected planar domain, `chi=1-holes=-2` corresponds to **3 holes**. This is strong numerical consistency, **not a substitute for an independently executed whole-T6 topology checker or original experiment certification**. It does not prove physical crack-tip regularity, which is missing p010.

### History, as observed (each a distinct generated mesh)

| Author run | T3 minimum angle | Max neighbor size ratio | Bad interior edges |
|---|---:|---:|---:|
| Hmax 7mm; no guide annulus | 20.96808450° | 2.48807517 | 23 / 24,545 |
| Hmax 6mm; no guide annulus | 26.26756357° | 2.25936462 | 19 / 27,520 |
| Hmax 6mm; annuli at holes #1/#3 | 31.02994128° | 1.81651696 | 1 / 31,676 |
| **Hmax 6mm; annuli at all 3 holes** | **33.63741002°** | **1.62557238** | **0 / 34,394** |

The worst ratio still occurs in the mesh (element IDs 22,596 and 22,695, midpoint (98.611142,31.707925)mm), but it is **below** the fixed 1.8 limit. No further mesh-parameter sweep is currently motivated.

### Acceptance boundaries and next actions

1. **Accept as a geometry-only numerical candidate**, retaining original author source console and `GEOMETRY_ONLY_candidate.mat` under their unique immutable local output folder. Draft PR #16 **should remain unmerged** pending review.
2. Run a **separate read-only independent T6 checker** against saved MAT arrays (no re-meshing), checking all T6 unique midsides, constant positive Jacobians, crack face twins, one tip, three true CAD hole boundary chords, four boundary components, area, connectedness and Euler identity. Do not accidentally apply source's **two-hole** or p010-specific gates to this mesh.
3. Port/adapt and independently qualify the **protected p010 local tip patch + analytical collar + FE-nodal q** from `mfs9697/EdgeCrackHoleLEFM`. The successful candidate deliberately **does not contain this protected patch**; any transfer changes the mesh family and requires new full mesh/quality validation.
4. Only after geometry + protected tip + independent verifier admission, formulate and verify Cornell-specific material, supports, CMOD loading and plane assumption; then physical solves, signed EDI/COD/K and crack trajectory.

**No experimental match, SIF, J, COD, crack propagation or physical solver acceptance is claimed.**
