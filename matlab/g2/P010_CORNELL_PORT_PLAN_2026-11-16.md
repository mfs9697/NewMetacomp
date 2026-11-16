# G2 Cornell specimen #1 — pinned protected-p010 transfer plan (geometry only)

**Status 2026-11-16:** p010 is NOT yet transferred. This document is an implementation contract, not a MATLAB result, not an LEFM permit. Source is [EdgeCrackHoleLEFM](https://github.com/mfs9697/EdgeCrackHoleLEFM) frozen at **`a14d8872ab588ac551e41b4531bffee2dcd0ce2c`**. The upstream Cornell-independent p010 kernel was previously qualified for a **different plate and two holes**; its geometry/BC cannot simply be copied as physical evidence.

## Accepted input — current Cornell reference (do not modify)

The user's 2026-11-16 21:43 MATLAB R2023a run:
`outputs/g2_specimen1_pencil/run_20261116_214346_310/GEOMETRY_ONLY_candidate.mat`

- Source MAT SHA256: `9D74134FDF4765449C0F4E4EC87EA5B9E3B0A94B542A80E7E04DF3BC4EDC6A96`.
- Original geometry JSON SHA256: `45A88FA0926472DDBE5E70E4C80A97B88196DD45D8A266FA04273F89790B47BF`.
- 3 actual holes, 4 CAD material faces from 3 nonphysical annular `3R` guides, `Hmax=6mm`, all `Hface=1.5mm`, `Hgrad=1.12`, `Hmin=.12mm`, lip `Hedge=.45mm`, pencil `w=.020mm`.
- T3: 12,018 nodes, 23,207 triangles, minimum angle **33.63741002°**, maximum adjacent-longest-edge ratio **1.62557238**, 0/34,394 violations.
- T6: 47,245 nodes; 105 nodes per separate bank, one tip node #6; candidate `CANDIDATE_TOPOLOGY_PASS`.
- **Independent check actually run 2026-11-16 22:09:** [draft PR #17](https://github.com/mfs9697/NewMetacomp/pull/17) passed **38/38**, 4 physical boundary loops, Euler `-2`, min angle 33.63741002°, max ratio 1.62557238. Audit evidence remains on author's machine in `outputs/g2_independent_t6/run_20261116_220901_848/`.
- **Only** the unprotected candidate has passed. Its `approvedForLEFM=false` is correct and must remain so until full protected mesh and physical BVP qualification. The independent 38/38 auditor **does not contain a p010 gate**.

## Pinned source files (do not alter source repository originals)

The relevant upstream frozen functions and Git **blob SHA-1** (not file SHA256) at commit `a14d8872...`:

| Source path under EdgeCrackHoleLEFM | Git blob SHA-1 | Role |
|---|---|---|
| `verification/main_m1i_increment_ring_geometry_only.m` | `40fbc6b2e4f35299f773fc14736961d4136a7bf7` | Qualified local 15-gate ring layout |
| `src/geometry/build_m1i_trial_tip_annulus_p010.m` | `9440ceda09609b4bcbb4bc7da2874f9fffde62b1` | Analytic frozen p010 disk + annulus |
| `src/geometry/build_m1i_trial_tip_disk_p010.m` | `877aa59c8d6cadc0987c791e1d13204f98125d7e` | Inner tip lattice |
| `src/geometry/build_twohole_literal_annulus.m` | `16b2045836f548bbc38eea944663a9eb09a5eec3` | Underlying 64-sector annulus |
| `src/geometry/cut_twohole_literal_annulus.m` | `bfdd4418193da5792e28e07562fffa46bfab8196` | True separate crack-face entries |
| `src/geometry/T3toT6_fast.m` | `29bf9d8e233b24d70cdc81e392f8b24e239c1afa` | T3-to-T6 unique midpoint source |
| `src/trajectory/edge_pencil_join_native_mesh.m` | `369227782871423171ad0ea0a0854b2be47c11d5` | Collar/exterior joining, original 2-hole assumptions |
| `src/trajectory/edge_pencil_crack_banks_from_topology.m` | `fd457816f89361fbe64315557077eb827b6531c4` | Geometric bank identification |
| `src/trajectory/edge_pencil_mesh_invariants.m` | `ea4b2e6695facf1389b407a97c115d55b745289f` | Original 2-hole p010 global gates |
| `src/trajectory/edge_trajectory_candidate_mesh_pencil_p010.m` | `88be0aff1b6e966ae65f41d90c57fd5073058bab` | General polyline source, but original specimen defaults |

**Source-named `twohole` routines do not imply two physical holes are permitted in Cornell.** They are local geometric generators to be run/tested under pinned code provenance; the *physical* three-hole exterior and its mechanical assumptions remain separate.

## Cornell vs frozen source — explicit differences

| Aspect | Cornell #1 | Upstream frozen source |
|---|---|---|
| Plate | `[0,508] × [0,203.2]` mm | Original 300 × 400 mm domain with its own origin |
| Physical holes | 3 circles, all `R=6.35mm`, centers `(152.4,69.85)`, `(152.4,120.65)`, `(152.4,171.45)` mm | 2 circles, source centers `(100,-50)`, `(170,50)` mm, radii 25 and 30 mm |
| Initial crack | Bottom vertical `(101.6,0)→(101.6,25.4)` mm | 50mm horizontal source crack |
| CAD local sizing | 3 nonphysical 3R annuli; `Hface=1.5mm` all 3; `Hmax=6mm`; `Hgrad=1.12` | Its source global mesh and two-hole `Hedge` assumptions |
| Contact / loading | Real support/load and CMOD details not source-certified | Frozen source problem; DO NOT copy traction/support nodes |

**Critical source caveat:** `main_m1i_increment_ring_geometry_only.m` explicitly checks clearance against its own hard-coded original **two holes** `[.100,-.050;.170,.050]` m with radii `[.025;.030]` m and original 300×400-mm plate. Passing its **15 local gates cannot certify clearance against Cornell geometry**. New Cornell-specific clearance checks MUST be independent, mandatory, and cannot be bypassed.

## Proposed geometry-only transfer, in strict gates

### P0 — frozen kernel placement, before changing successful exterior
Use the source ring-generator at a *fictional 4mm construction segment inside the already existing 25.4mm starter crack* (this is a geometric parameterization, **not** a real crack-growth step):

```matlab
Pprior_m = [0.1016, 0; 0.1016, 0.0214];
ring = main_m1i_increment_ring_geometry_only( ...
    'PriorCrackPolyline_m',Pprior_m, ...
    'Delta_mm',4,'Turn_deg',0,'Plot',false);
```

The intended terminal point is exactly `(101.6,25.4)mm` with upward (+90°) tangent. Original frozen source patch properties: **2,788 T3 cells**, **64 sectors**, **3.0mm** core radius, **0.3mm** analytic collar thickness (outer radius **3.3mm**), new-scaled first T3 tip edge **0.0416667mm**, EDI annulus **0.4…2.6mm**, original `q` active patch-parent count **2,443**. These are *source expectations only* until verified in the Cornell frame.

Independent Cornell clearances, derived from original JSON (the actual numerical preflight must recalculate them):
- Nearest original plate side is lower `y=0`: `25.4mm` from the tip, so the 3.3mm collar has **22.1mm** external-margin clearance.
- Nearest original true hole is lower `(152.4,69.85)mm` with R6.35: its surface clearance from the tip is approximately **61.15mm**. Subtract the 3.3mm collar radius for approximately **57.85mm** margin.
- The crack segment behind the tip must remain aligned with the local negative tangent; source `priorTip` at `y=21.4mm` leaves **4mm** to the actual tip, greater than collar radius 3.3mm.

P0 may verify the isolated analytic **ring** and local geometry, but **must not reinterpret the source 15/15 as Cornell three-hole global qualification**.

### P1 — conforming exterior cut, protected tip + analytic collar
The accepted original MAT **cannot simply be augmented** by gluing a disk to its existing tip node #6, because the already-generated exterior does **not** have the required 64-sector/65-source-node p010 rim. Generate a NEW geometry-only exterior CAD:
1. Replace the pencil apex near the tip by a circular outer rim of radius **3.3mm** with the two distinct crack-bank entries at the correct vertical tangent; a continuous CAD exterior must include exactly **64 rim edges**, **65 rim nodes** including duplicated crack entry, no overlapping physical circles.
2. Preserve **3 physical circular holes** and the **3 internal nonphysical 3R guide-circle material faces**; the original 4 material faces need explicit reidentification and hole/perimeter checks after the new cut.
3. Use original frozen upstream **2,788-T3 p010 patch** + **128-T3 analytic collar**; join them conformingly to the **new exterior** with exact 64+64 two-owner seam edges. No midpoint tying by coordinate alone and no welded crack banks.
4. Ensure all triangles have positive area; require global min corner angle **≥20°**, adjacent longest-edge ratio **≤1.8** *without relaxation*, work budget controlled, no nonmanifold/seam/bank gaps. T3→T6 must produce one and only one globally shared midside per joined edge.
5. Validate the exact original 3-hole solid area up to permitted circle chord error, 4 physical boundary components, two independent crack banks and a single physical tip. New T3/T6 counts will **differ** from 12,018 / 23,207 / 47,245; the accepted candidate is a baseline, **not a frozen output-size target**.

### P2 — independent protected mesh and FE-nodal q audit
Run **two separate** verifiers on the newly joined full mesh:
- Cornell-adapted independent **38-gate geometry-only T6 checker**, plus source-aligned seam/rim/first tip edge and 64-sector p010-specific checks.
- Check *actual* FE-nodal q on **all six T6 nodes per element** for `r_i=0.4mm`, `r_o=2.6mm`, 2,443 active patch-parent expectation and support entirely inside the p010 polygon inscribed radius, with an explicit buffer. Source's 2-hole support nodes, plate anchors and frozen stress solutions are **never** copied.

If any gate fails, preserve a new uniquely named batch log and source hashes, retain HOLD; do not repair silently, do not soften 1.8/20° or manufacture a 15/15/21/21 from the other specimen. Use MATLAB R2023a `-batch` with ≥5GiB resource guard, and a separate read-only evidence directory for original accepted candidate.

### P3 — physical problem, not part of this PR
Only after P0-P2 succeed: independently reconstruct Cornell's experimental specimen-specific PMMA properties, support/contact, displacement-controlled CMOD setup, plane-stress/strain assumptions and validation data. Then propose signed EDI/COD, `K_I/K_{II}`, and propagated trajectory. **No mechanics or crack growth now.**

**Current decision:** the three-hole no-p010 candidate is independently accepted **for geometry only**, but **not authorized for LEFM**. All PRs remain draft and unmerged.
