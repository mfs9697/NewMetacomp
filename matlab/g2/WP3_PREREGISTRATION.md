# WP3 preregistration: first MTS kink, kinked protected mesh, kinked-tip signed SIF, one-step restart (Issue #24)

**Committed before any WP3 MATLAB code was written, before the kinked mesher exists, and before any WP3 number was computed in MATLAB.** The only numbers below are closed-form evaluations of the issue's own formula (cross-checked in Python before this file was written). Nothing here may be relaxed after results are seen. A failed gate is a finding to diagnose, not permission to change the test.

## 0. Base state and immutable sources

| Item | Value |
|---|---|
| Branch base | PR #23 head `513044cc2c5e2db68fc6630c3fe356769abd5e83` (WP2), stacked on PR #22 `81a7ea72d17f3c06949680d9bd2c7c9ece93b9d3` (WP0/WP1) |
| Cornell geometry JSON | `docs/research/crack-growth-gaps-2026/G2_SPECIMEN1_1990_GEOMETRY.json`, SHA-256 `45A88FA0926472DDBE5E70E4C80A97B88196DD45D8A266FA04273F89790B47BF` |
| Vendor p010 sources | six files in `vendor_p010_a14d8872/`, Git blob SHAs pinned in `run_g2_protected_mesh.ps1`; unchanged |
| Accepted state 0 | straight starter crack (101.6, 0) → (101.6, 25.4) mm; WP2 idealized BVP; K_I = 0.166436, K_II = +0.018827 MPa·√m per kN (plane stress, family A, `SIF_WP2_RESULTS.md`) |
| BVP (unchanged from WP2 §1) | pin u_x = u_y = 0 at (25.4, 0); roller u_y = 0 at (482.6, 0); P = 1 N downward at (254, 203.2) on t = 12.7 mm; traction-free holes and crack faces; E = 3268.115 MPa, ν = 0.35, plane stress primary; plane strain ν 0.35 and plane stress ν 0.30 as invariance cases |

Unchanged and not edited by WP3:
- all WP0–WP2 code;
- the 38-gate `g2_independent_t6_checker.m` and the 24-gate `g2_protected_tip_checker.m`;
- all existing `outputs/` folders and committed evidence.

WP3 code is new files only. The straight-crack checkers stay separately runnable, and **their verdicts do not certify a kinked mesh.**

## 1. MTS direction: formula, sign convention, regimes

**Frame.** At a tip with unit tangent t (growth direction), take n = R(+90°) t. The upper face is θ = +π, on the +n side. K_II > 0 means the upper face slides in +t relative to the lower face (the WP2 convention). At state 0, t0 = (0, 1) and n0 = (−1, 0), so the upper face is the left face.

**Direction.** The continuous tensile root of K_I sin θ + K_II (3 cos θ − 1) = 0 is

  θ = 2 atan2(−2 K_II, K_I + √(K_I² + 8 K_II²)),

which is free of cancellation for small K_II. The new tangent and tip are

  t1 = cos θ · t + sin θ · n,  tip1 = tip + Δa · t1.

So θ < 0 turns towards −n; at state 0 that is towards +x.

**Regimes** (`g2_mts_direction`; the returned `status` must be checked by every consumer):

| Input | status | θ returned | Admissible for a geometric step |
|---|---|---|---|
| any non-finite K | `HOLD_NONFINITE_K` | none (empty) | no |
| K_I = K_II = 0 | `HOLD_ZERO_K` (no energy, no direction) | none | no |
| K_I < 0 | `HOLD_NEGATIVE_KI_CONTACT_OR_COMPRESSION` (faces interpenetrate; a contact model is needed) | none | no |
| K_I = 0, K_II ≠ 0 | `DOCUMENTED_PURE_MODE_II` | ±70.528779°, for the algebra test only | no (requires a separate contact/onset policy) |
| K_I > 0 | `OK` | the tensile root | yes, subject to the hoop-stress checks |

With status `OK`, two further checks apply; if either fails, the status becomes `HOLD_NONTENSILE_OR_NOT_MAXIMUM`:
- the hoop stress σ_θθ(θ) ∝ cos(θ/2)[K_I cos²(θ/2) − (3/2) K_II sin θ] must be > 0;
- its second derivative must be < 0 (a maximum).

There is no fracture-onset claim in any regime. Onset needs K_Ic or G_c and the experimental load, which are unknown. Every WP3 step is tagged `idealized_propagation_demo = true` and `physical_onset = false`.

## 2. WP3.0 analytic acceptance tests (pure algebra, MATLAB `run_g2_wp3_mts_tests_batch`)

| ID | Test | Criterion |
|---|---|---|
| A1 | pure I: (K_I, K_II) = (1, 0) and (0.37, 0) | θ = 0 exactly (abs(θ) ≤ 1e−15 rad), status OK |
| A2 | pure II: (0, +1) and (0, −1) | θ = ∓2 atan(1/√2) = ∓70.52877937°, within 1e−9°; opposite signs; status `DOCUMENTED_PURE_MODE_II` |
| A3 | antisymmetry on a grid of 2,001 ratios K_II/K_I in [−50, 50] (K_I = 1) | max abs(θ(K_I, −K_II) + θ(K_I, K_II)) ≤ 1e−12 rad; sign(θ) = −sign(K_II) |
| A4 | stationarity residual on the A3 grid and for Cornell | abs(K_I sin θ + K_II (3 cos θ − 1)) / √(K_I² + K_II²) ≤ 1e−12 |
| A5 | tensile maximum: σ_θθ(θ) > 0 and d²σ_θθ/dθ² < 0 at the root; the root is the global maximiser of σ_θθ on a 2,000,001-point grid over (−π, π) | abs(θ − θ_grid) ≤ 2π/2e6 + 1e−9; σ_θθ(θ) ≥ grid maximum − 1e−12 |
| A6 | small-K_II cancellation: K_I = 1, K_II ∈ {1e−6, 1e−10, 1e−14} | θ / (−2 K_II/K_I) − 1 ≤ 1e−6 (no cancellation loss) |
| A7 | scale invariance: θ(cK_I, cK_II) = θ(K_I, K_II) for c ∈ {1e−6, 1e3} on the A3 grid | ≤ 1e−14 rad |
| A8 | regimes of §1: (0, 0), (−1, 0.2), (−1, 0), (NaN, 1), (1, Inf) | the stated HOLD status, θ empty, no NaN returned |
| A9 | Cornell state 0 (K_I = 0.166436, K_II = 0.018827) | θ = −12.5956937°, within 1e−6°; cos θ = 0.97593315, within 1e−8; t1 = (0.21806989, 0.97593315), within 1e−8; tip1 = (102.47227957, 29.30373262) mm, within 1e−8 mm for Δa = 4 mm |

**WP3.0 GO** requires A1–A9 all to pass in MATLAB R2023a. The batch also writes the **reference manifest** `WP3_REFERENCE_MANIFEST.json`, with:
- tip_old, K_I, K_II, θ, Δa, tip_trial, t1 and n1;
- the BVP of §0;
- source hashes (JSON, vendor blobs, PR #23 head);
- the tags `analytical_trial_geometry = true`, `physical_propagation = false` and `idealized_propagation_demo = true`.

A9 also records that the inherited upstream guard `MinKinkTangentDot = 0.98` would **reject** this kink (cos θ = 0.97593 < 0.98, bound acos 0.98 = 11.47834°). This is a documented fact, not a WP3 gate (§3).

## 3. Why the inherited 0.98 guard is replaced, and the new Cornell-specific admissibility gates

The guard comes from `EdgeCrackHoleLEFM@a14d8872`, `src/trajectory/edge_pencil_join_native_mesh.m` (`smallKinksOK = all(tangentDots > 0.98)`). Its own documentation calls it:
- "a mesh-admissibility limit inherited from H1–H3, not a physical criterion" (`docs/PRD_H4_CANDIDATE_POLICY_2026-10-30.md`);
- with the ±12.14° and ±15° envelope "still needed" and "not qualified" (`docs/PRD_H4_FIRST_GUARDED_CANDIDATE_2026-10-30.md`).

No derivation from a failure mechanism is recorded; it is the largest turn that the H1–H3 runs happened to need. **It is not lowered to 0.97** and is not claimed to hold. Instead, each mechanism that a kink can actually break is gated explicitly with a value derived from the construction. The actual mesh must then pass every unchanged quality gate. Gates K1–K10 are computed by the pure-geometry function `g2_kink_admissibility` before meshing, and recomputed independently by the kink-aware auditor from the saved polyline.

| ID | Mechanism | Gate | Value at this kink |
|---|---|---|---|
| K1 | polyline identity | exactly 3 vertices; segment 1 equals the JSON starter crack (1e−12 mm); segment 2 length = Δa = 4 mm and direction = t1 (1e−12) | — |
| K2 | mitred channel offset must stay finite and close to w (collapse moves the miter vertex by w / cos(θ/2)) | inherited non-singular miter rule 1 + t_prev·t_next > 1.8 (equivalently, miter factor < 1.054) | 1.97593 (factor 1.00607) |
| K3 | the collar entry must lie on the last segment, past the kink | last segment length > r_o = 3.3 mm, and the entry point tip1 − r_o·t1 lies strictly inside segment 2 | 4 > 3.3 |
| K4 | the 64 single-chord rim, the channel and the previous crack must not compete for the same rim-scale band | distance(tip1, every earlier segment) − r_o − w ≥ h_rim = 2 r_o sin(π/64) = 0.32385 mm | 0.68000 mm (×2.10) |
| K5 | the p010 core and the q support must not contain earlier crack geometry | distance(tip1, every earlier segment) > r_c = 3 mm (> q r_out 2.6 mm) | 4.000 mm |
| K6 | crack versus true holes (inherited 3 mm rule, now applied to all three holes and every segment) | segment-to-hole-wall clearance > 3 mm | min 57.97 mm |
| K7 | the channel must not cut a nonphysical 3R guide face (which would split faces and change the CAD) | segment-to-guide-circle clearance > w + guide Hface (1.5 mm) | min 45.27 mm |
| K8 | collar disk inside the material | collar (r_o) clear of true hole walls, guide circles and all four plate sides, each > 0 | min 26.00 mm (plate bottom) |
| K9 | tip guide (radius 15 mm, centred at tip1) | inside the plate; disjoint from all 3R guides; contains no hole | margin 14.30 mm (bottom); 30.27 mm to guide 1 |
| K10 | self-intersection | nonadjacent segments separated by ≥ 2w + Hmin (vacuous for N = 3, implemented generally); the CAD boundary polygon is simple and positively oriented | — |

The thresholds in K2–K10 are construction constants (w = 0.020, r_c = 3, r_o = 3.3, Hmin = 0.12, guide Hface = 1.5, 3 mm hole rule). None is tuned to this kink. **A kink failing any of K1–K10 is a GEOMETRY HOLD.**

## 4. WP3.1 kinked protected mesh: construction (frozen choices)

- **Kernel.** The unchanged vendor builder `main_m1i_increment_ring_geometry_only('PriorCrackPolyline_m', [mouth; tip0]/1000, 'Delta_mm', 4, 'Turn_deg', θ in degrees)`. The 2,788-T3 p010 kernel is a rigid rotation plus translation of the accepted kernel. Its 15 vendor gates must pass; they use the vendor's own old two-hole plate and are reported as such, not as Cornell qualification.
- **Collar.** Analytic 128-T3 collar at r_o = 3.3 mm in the rotated frame (the formula of WP1 and upstream: tip1 + r_o(cos φ t1 + sin φ n1), φ = 2πj/64). The entry node at φ = π is duplicated: outer(33) belongs to the upper bank (+n1) and outer(65) to the lower bank.
- **Exterior.** A new native PDE Toolbox exterior built from the polyline:
  - a mitred 20 µm half-width channel (offset ±w along each segment normal; the miter vertex at P2 ± w (n_a + n_b)/(1 + t_a·t_b));
  - the 64-gon rim cavity with vertices at the exact collar outer nodes. The entry is split on the chords P33–P32 and P33–P34 at local η = ±w;
  - the three true holes, the three nonphysical 3R guides and the 15 mm tip guide centred at tip1;
  - point vertices at (25.4, 0), (482.6, 0) and (254, 203.2).
- **Family A controls.** As in WP2: Hmax 6, Hmin 0.12, Hgrad 1.12, lip Hedge 0.45, guide Hface 1.5, tip guide 15 / 1.5, 40k T3 budget.
- **Family B** (only for the WP3.2 exterior refinement check, same deviation as WP2): Hmax 4, guide Hface 1.0, tip guide 15 / 1.0, lip Hedge 0.30, 80k budget, disclosed.
- **Lip collapse.** The lips are collapsed onto the polyline without welding. The nodes of each offset segment are paired by centre-line station; the pairing tolerance is 0.15 mm (unchanged from WP1). The miter vertex nodes go to P2 exactly and the entry nodes to tip1 − r_o t1. **Unequal node counts per segment or a station mismatch is a HOLD.**
- **No fallback.** No reduction of Δa, no change of θ and no relaxation of any gate.
- **Secondary geometry-only control.** The mirrored kink +12.5956937° with family A: same code, mesh and audit only, not used for any SIF. It tests that the construction is not sign-specific.

## 5. WP3.1 independent kink-aware audit (`g2_kinked_mesh_auditor`, separate MATLAB process)

The auditor reads only the saved arrays, the saved polyline, the pinned JSON and the immutable WP1 P0 evidence MAT. It never calls the mesher, the join or the vendor builders. **Every gate must pass:**

1. **Arrays and T6.** Shapes and indices are valid. T6 corners equal the T3 arrays. Every T6 node is used. Each edge has a unique midside, which is its geometric midpoint (1e−10 mm), and the T6 count equals corners plus edges. No edge is nonmanifold.
2. **Quality.** All T3 areas and all T6 Jacobians (13-point independent routine) are positive. Global minimum T3 angle ≥ 20°; maximum neighbouring longest-edge ratio ≤ 1.8.
3. **Boundary.** Every boundary edge falls in exactly one physical class: plate side, one of the three true circles (endpoints on the circle within 1e−5 mm), or crack (on the saved polyline within 1e−7 mm). There are 4 boundary components: the outer loop with the opened crack, plus 3 pure hole loops. Each hole loop has ≥ 12 chords.
4. **Topology and lengths.** The outer perimeter equals the plate perimeter. The crack boundary length equals twice the polyline length (1e−5 mm). The material is one connected triangulation; the Euler characteristic is −2. The material area matches the analytic plate minus three circles within 0.5 %.
5. **Banks.**
   - The upper and lower bank sets are valid and equal in size; they share exactly the declared tip node, which sits at tip1 (1e−9 mm).
   - Every bank node lies on the polyline. Upper-bank owner elements lie on the +n side of their segment and lower ones on the −n side.
   - Twins coincide pairwise with distinct IDs. Every geometric crack edge has exactly two topological twins on each segment.
   - The banks reach the mouth and the tip. The kink vertex P2 carries exactly two node IDs, one per bank.
   - The saved banks cover exactly the crack boundary T6 nodes. Coincident distinct nodes occur only as bank twins.
6. **Kernel identity.**
   - The rotated kernel's local coordinates (X − tip1)·[t1 n1] equal the P0 evidence kernel's local coordinates (X − tip0)·[t0 n0] within 1e−9 mm.
   - The kernel connectivity is identical to P0.
   - There are exactly 2,916 elements (2,788 + 128) with centroid inside r_o, and no exterior node strictly inside the rim.
7. **Seams.**
   - 64 edges on r = 3 and 64 edges on r = 3.3 about tip1, each with two owners on opposite sides.
   - 65 node identities on each circle (the split entry).
   - Each r = 3.3 seam edge spans exactly 2π/64.
8. **Tip.**
   - The tip fan has 6 triangles and 7 neighbours, and the first tip edge equals the scaled p010 pitch.
   - The last-segment length is 4 mm (1e−9) and its tangent equals t1 (1e−12).
9. **q support.**
   - FE-nodal q, recomputed about tip1 (0.4–2.6 mm), has exactly 2,443 active parents. All are kernel rows and they equal the P0 active set.
   - Support radius < 3 cos(π/64) = 2.99639 mm.
   - q = 0 on all collar and exterior nodes.
   - The q support is clear of the kink: its distance to P2 is > 0, and is reported.
10. **Geometry.**
    - K1–K10 are recomputed from the saved polyline.
    - The minimum distance from every mesh node of the protected region to the hole walls, guides and plate is > 0.
    - No crack-segment intersection (K10).
11. **Source.** `geometryOnly = true` and `approvedForLEFM = false` in the saved file.

**Negative controls** (`check_g2_kinked_auditor_controls`). Each corrupted copy of the accepted kinked mesh must be rejected (pass = false), with the expected gate among the failures:

| ID | Corruption | Expected failing gate group |
|---|---|---|
| N1 | bad bend: the saved polyline's kink vertex moved 0.05 mm off the mesh | 3 or 5 (crack/bank not on polyline) |
| N2 | bad miter: the kink-vertex upper node displaced 0.01 mm along n | 5 |
| N3 | welded banks: lower twins on the final segment replaced by the upper IDs | 5 |
| N4 | seam mismatch: one r = 3.3 seam node moved 1e−6 mm radially | 7 |
| N5 | wrong hole: hole 2 centre in the JSON copy shifted by 0.5 mm | 3 |
| N6 | inverted element: two corners of one exterior T3 swapped | 2 |
| N7 | clipped q: saved nodalQ zeroed on 10 active nodes | 9 |
| N8 | intersecting geometry: a saved polyline whose segment 2 enters hole 1, and one with a 100° fold | 10 (K-gates) |
| N9 | straight-crack control: the WP2 family-A straight mesh with the kinked manifest | 5, 6 or 8 |

**WP3.1 GO** requires all of the following:
- the actual R2023a kinked family-A mesh passes the join gates and the kink-aware audit;
- all negative controls are detected;
- the mirrored geometry-only control (mesh and audit) is reported. If it fails, the failure is recorded as a sign-dependence finding; it does not block the −12.60° primary result unless the failure is in shared code.

The unchanged 38/24-gate straight checkers may be run on the kinked mesh for information only; their failures are expected and are not a verdict.

## 6. WP3.2 kinked-tip SIF (only after WP3.1 GO)

- **Solve.** The same BVP as §0 on the audited family-A kinked mesh (and family B for C4). Supports and the load are found by exact vertex coordinates.
- **EDI.** `g2_sif_interaction` with tip1 and tdir = t1, the five WP2 annuli (0.4–2.6, 0.2–1.0, 0.4–1.6, 0.8–2.6, 1.2–2.4 mm) and 6×6 versus 4×4 quadrature.
- **COD.** The new `g2_sif_cod_banks`. It reads the saved bank IDs and pairs twins by coordinate. It uses only twins on the final segment (local η = 0, 0 < r ≤ Δa), with the preregistered 0.1–1.5 mm window and the same E′/8 √(2π/r) formula. No geometric face classifier is used and nothing is combined across the kink.
- **Manufactured rotated Williams fields** (MK) on the rotated isolated block (the kernel plus collar of §4, Dirichlet on the r = 3.3 rim, in the t1/n1 frame). Cases: (1, 0), (0, 1), (0, −1), (0.6, −0.8), (1, 0, T = 0.2), (0.6, −0.8, T = −0.2).

| ID | Criterion (WP2 thresholds, unchanged) |
|---|---|
| MK | EDI error ≤ 1.0 % K_ref; COD ≤ 3.0 % K_ref; K_II sign correct in every case |
| M2 | five-annulus spread ≤ 0.5 % K_ref (MK and Cornell) |
| M3 | abs(J/((K_I² + K_II²)/E′) − 1) ≤ 0.5 % |
| M4 | 4×4 versus 6×6 ≤ 0.1 % K_ref |
| C1 | relative residual ≤ 1e−8; force and moment balance ≤ 1e−8; reactions equal the statics values |
| C2 | EDI versus COD ≤ 3.0 % K_ref |
| C3 | plane stress ν 0.35 / plane strain ν 0.35 / plane stress ν 0.30: K change ≤ 0.5 % K_ref |
| C4 | family A versus family B (exterior refinement): ≤ 1.0 % K_ref |
| QK | every node of every q-active element lies within 2.99639 mm of tip1, so the support excludes the kink at 4 mm |

**No criterion is placed on the values of K_I, K_II at the new tip** (for example, K_II ≈ 0 by local symmetry is not required). Tip-size convergence (scaling the p010 kernel) is **out of scope** and reported NOT RUN, because the frozen kernel scale is fixed; C4 tests only the exterior. The result is tagged numerical/idealized and is not an experimental value.

**WP3.2 GO** requires MK, M2–M4, C1–C4 and QK all to pass.

## 7. WP3.3 one-step transaction and restart (only after WP3.2 GO)

**Transaction** `g2_wp3_one_step(state0File, outRoot, 'Authorize', 'ONE_IDEALIZED_DEMO_STEP')`:
1. Load state 0 and verify its SHA-256 against the recorded value.
2. Forecast θ with `g2_mts_direction`; any status other than OK means HOLD.
3. Admissibility K1–K10.
4. Mesh (family A).
5. Independent audit.
6. Solve, EDI and COD with the WP3.2 criteria C1, C2, M2, M3, M4 and QK.
7. Write state 1 to a **new** folder: the polyline, tip, t, K (both methods), mesh hash, audit verdict and parent-state hash, plus the tags `idealized_propagation_demo = true` and `physical_onset = false`.

State 0 is never written to. Without the `Authorize` token the transaction refuses (`HOLD_NOT_AUTHORIZED`). It refuses a second step (a state whose parent is not state 0): `HOLD_SECOND_STEP_NOT_AUTHORIZED`.

| ID | Criterion |
|---|---|
| R1 | replay: a second transaction from the same state 0 gives isequal mesh arrays and bank IDs, and K within 1e−12 relative |
| R2 | restart: reloading state 1 verifies its hash, re-solves the saved state-1 mesh and reproduces the recorded K within 1e−12 relative, and the next-step forecast θ₂ is computed and recorded **but not executed** |
| R3 | integrity control: a state file with one altered byte (or a mismatching recorded hash) yields `HOLD_STATE_INTEGRITY` |
| R4 | frame consistency: state 1's t equals t1 from WP3.0 within 1e−12, and K_I > 0 |
| R5 | no second step: attempting a transaction from state 1 yields `HOLD_SECOND_STEP_NOT_AUTHORIZED` and writes nothing |

**WP3.3 GO** requires R1–R5.

## 8. Stop rules and labels

- Each stage is labelled GO, HOLD or NOT RUN, together with the evidence folder, the exact command and the commit SHA.
- A HOLD stops every downstream stage.
- Failed attempts are kept under `outputs/` and listed in the results file.
- Evidence goes to new `outputs/g2_wp3_*/run_*` folders with console logs, JSON summaries, and SHA-256 of inputs and outputs. Committed copies have local paths replaced by `<repo>`.
- Every MATLAB process is preceded by the 5 GiB free-RAM guard.
- **Out of scope:** no WP4 report, no multi-step campaign, no experimental comparison and no onset claim.
