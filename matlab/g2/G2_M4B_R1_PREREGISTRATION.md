# G2-M4.B-R1 preregistration: matched frozen S2alt check of ring placement (Issue #47 → Issue #50)

**Status:** prospective. This file and `G2_M4B_R1_POLICY_v1.json` are committed **before any R1 solve**. No R1 result exists yet.

- **Authorization:** scientist review on Issue #47 (comment 7068731805, decision 3) and Issue #50.
- **Base:** draft PR #49 at `ece7469`, verified unchanged.
- **Unchanged policies:** `G2_M4_POLICY_v1.json` and `G2_M4B_POLICY_v2.json`.

## 1. Question

Do the single-ring placement effects found on the original 76-chord S2 mesh keep their sign, magnitude and equal-area ranking on an independently regenerated mesh family? The second family has 112-chord ring polygons and a finer exterior, and the crack is identical. The same question is asked for the stiff {1,3} candidate.

This is a cross-family check of a fixed-crack computation:
- not a mesh-convergence study;
- not a near-tip study, because the p010 core, collar and q support are shared;
- not a re-test of interactions.

## 2. Matched geometry (checked before any solve)

**S2alt** is the PR #38 run D mesh, `S2ALT_KINKED_GEOMETRY_ONLY_candidate.mat`, SHA-256 `0627dd3a…3080`. It is pinned in the committed M2 ledger.
- Mesh: 35,125 T3 elements, 71,207 nodes, 3×112 chords.
- Build: `g2_kinked_join` on the **saved** full-precision S2 polyline, with GuideHface 1.0 mm and Hmax 5 mm.

**Rule:** `crackPolyline`, `tipTangent` and the physical tip coordinates must be **bitwise equal** to the original S2 (`9269be43…`). The p010 core, collar and q-active row counts must be equal (2788 / 128 / 2443). Otherwise the run stops with **HOLD_MATCHED_S2ALT**.
- The M4.A alternative homogeneous S2 (a different crack shape) is forbidden as a substitute.
- A read-only probe before this commit found bitwise equality on all three and equal core counts. That probe used no solve and wrote nothing.

**Area disclosure.** The 112-gon ring area is 1012.852964 mm² against 1012.152529 mm² for the 76-gon (+0.0692 %).

## 3. Cases (10 solves on S2alt)

| Role | IDs |
|---|---|
| Targets (7) | soft `c0p5_100`, `c0p5_010`, `c0p5_001`; stiff `c2p0_100`, `c2p0_010`, `c2p0_001`, `c2p0_101` |
| Anchors (3) | `none`, `c0p5_111`, `c2p0_111` |
| Legacy controls | `g2_material_sif_on_mesh` (unchanged) on both 111 states |

- **Anchors** are re-solved and must equal the accepted M2 S2alt records **bitwise** (B2). A saved anchor is never used in place of a solve.
- **Any other case** is refused before a solve (`HOLD_CASE_OUTSIDE_DESIGN`).
- **Reused M4.B modules, byte-identical to PR #49:** oracle, activation, verifier (with `expectedChords = 112`), `g2_m4b_sif_partial`, negatives.
- **New code:** the R1 controller, the matched-geometry check, the comparison analysis, faults and figures.

## 4. Comparison rules (fixed now)

**Per target.** For each target S and each observable Q ∈ {F_G, F_θ}, every family uses its own `none` and its own primary and conservative uncertainty (as in policy v2).

| Class | Condition |
|---|---|
| UNRESOLVED | Q not resolved under the primary rule in either family (no sign statement) |
| NOT_ROBUST | both resolved and the signs differ |
| STABLE | same sign and \|Q_alt − Q_orig\| ≤ 0.10 \|Q_orig\| |
| SENSITIVE | same sign and a larger difference |

The 0.10 threshold is the one the M2 policy used for this exact mesh pair (S2 vs S2alt).

**Equal-area ranking.** For each contrast and observable, the signed order of (f_1, f_2, f_3) is compared between families, and each d_ij = f_i − f_j is classified with the same four classes.
- RANKING_STABLE: identical order and no NOT_ROBUST difference.
- RANKING_UNRESOLVED: some difference is UNRESOLVED but no sign flips.
- RANKING_CHANGED: otherwise.

**Stiff {1,3}.** Its F_G and F_θ classes are reported. Its F_G position among the stiff S2alt cases evaluated here is reported as **unequal-area context only**. No other two-ring set is computed on S2alt.

**Verdict.**
- R1_PLACEMENT_STABLE: all 12 single-ring classes STABLE and all 4 rankings stable.
- R1_PLACEMENT_SENSITIVE: no NOT_ROBUST and no RANKING_CHANGED, but some SENSITIVE or UNRESOLVED.
- R1_NOT_ROBUST: any sign flip or changed ranking.
- HOLD: any gate failure.

**Three questions reported side by side:**
1. primary uncertainty;
2. conservative uncertainty;
3. cross-family drift.

**Not claimed:**
- I_ij, I_123 or Shapley values;
- equal-cost two-ring rankings;
- convergence.

## 5. Integrity, faults, figures, Word

**Integrity:**
- Token `G2M4BR1RUN|policy|src|mesh|cases=10`; a case token in every record.
- Dry runs write nothing; a clean tree is required.
- R2023a with the PDE Toolbox, ≥ 5 GiB RAM (cannot be lowered), one MATLAB process.
- Immutable SHA-manifested records and a case ledger; reuse only after re-verification, with no FEM on reuse.

**Faults (policy list):**
- dry run;
- tampered mesh;
- the matched-geometry rule rejects the M4.A S2 and a perturbed polyline;
- mutations on the 112-gon;
- bad tokens;
- policy and source drift;
- low RAM;
- out-of-design case;
- tampered or forged records;
- interrupt and resume;
- bit-identical replay;
- accepted runs unchanged.

**Figures:**
- monotonic greyscale (black to white);
- signed fields with a bold zero contour and solid/dashed ± contours;
- common limits for comparisons, with separately labelled local-limit versions;
- all text in Ukrainian;
- accepted data only; stresses come from saved displacements via the unchanged `g2_t6_point_stress`.

**Word:** a small native Ukrainian proposal package, rendered with every page inspected. The v0.4 candidate and v0.3 are untouched.

## 6. Stop

**REVIEW_STOP_R1.** No long paths, M4.C, mixed layouts, State 3, CZM, interface penetration or arrest claims.
