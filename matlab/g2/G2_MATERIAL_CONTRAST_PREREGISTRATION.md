# G2 material contrast on frozen State 2: preregistration (Issue #33)

**Status:** committed before any two-phase solve, benchmark solve or contrast result.
The only MATLAB run so far was a read-only geometry inspection of the saved State 2 mesh
(see §2). Machine-readable contract: `G2_MATERIAL_POLICY_v1.json` (this commit).
The trajectory policy v1, the original solver and the accepted chain are not changed.

## 1. Question

At the identical, already-verified State 2 crack Γ₂, with identical voids, mesh, supports and
load, does a perfectly bonded elastic band around each hole (6.35 mm < r < 19.05 mm) change
the crack-driving force?

R_mat = G_M(Γ₂) / G_H1(Γ₂), with G = (K_I² + K_II²)/E'_m evaluated only in the proven homogeneous
matrix region around the tip.

This is the `R_direct` of the G2 protocol, but for a **phase** counterfactual on a perforated
specimen, not the hole-versus-no-hole counterfactual. R_mat ≈ 1 is a legitimate result. No
toughness, onset, arrest, durability or experimental claim follows from any outcome.

## 2. Source state and audit facts (read-only)

| Item | SHA-256 / value |
|---|---|
| Parent | PR #32 head `f2c9790d9802e9ce40a55978ea0b6e13feafb7bf` |
| Chain | `outputs/g2_trajectory_chain_v1_attempt2` (the HOLD-1 chain `g2_trajectory_chain_v1` is not used) |
| ROOT / REVIEW / State 2 | `fa24bc43…14edb` / `e5ad2c17…78055` / `4603095b…ee2e6` |
| State 2 mesh MAT | `9269be43…5c412`: 28,625 T3/T6, 58,161 T6 nodes |
| Trajectory policy v1 / Cornell JSON / P0 | `1d6af7f6…39dc` / `45a88fa0…b47bf` / `15201996…37c58` |
| Recorded State 2 K (per kN) | K_I 0.195982362, K_II +0.003149970 |

Read-only inspection of the saved mesh (`MAT_inspect`, before this document):

- Each nominal 19.05 mm circle carries exactly 76 saved T3 vertices with |r − 19.05| ≤ 2.2e−14 mm.
- The nearest other T3 vertex is 1.30 mm off the circle.
- T6 midside nodes on the circle chords sit 0.01576 mm inside, the sagitta of a 76-gon.
- Each hole rim carries 152 T3 vertices on r = 6.35 mm (≤ 1.7e−14 mm).

So the PDE guide faces G1–G3 left **conforming polygonal interfaces** in the saved mesh, and no
rebuild is needed. The material interface is defined as the inscribed 76-gon of the saved mesh,
not the nominal circle. Its area deficit relative to the nominal annulus is reported (about 0.1 %
expected) and is part of the model definition.

## 3. Phase map (two independent classifiers, no centroid-only rule)

- **Mapper** (`g2_material_phase_map`):
  - circle vertices are selected by the on-circle tolerance (1e−9 mm) and a required gap (≥ 1e−3 mm) to the next vertex;
  - they are sorted by angle, and each consecutive chord must be a T3 edge with exactly two owners that share the same midside T6 node;
  - a T3 edge-adjacency flood fill, blocked only at those chords, must give exactly four components: one matrix and three annuli;
  - the inner owner of every chord must lie in its annulus and the outer owner in the matrix.
- **Verifier** (`g2_material_phase_verify`, written separately):
  - point-in-polygon classification of all six T6 nodes of every element against each interface polygon; an element with nodes strictly on both sides fails;
  - the label vector must equal the verifier result element by element;
  - also checked: annulus area = polygon(interface) − polygon(hole) to 1e−12; total mesh area = plate − Σ hole polygons to 1e−9; no node inside a void; every interface chord has two owners with labels {1,2} and a shared midside node;
  - coincident node pairs are allowed only for the registered crack-bank twins;
  - every element within the 15 mm tip guide is matrix;
  - the whole FE-nodal q support of every annulus is matrix, with clearance ≥ 1 mm to any reinforcement node.
- **Negative controls on the State 2 map:** swapped labels, one flipped element at an interface, a detached interface (duplicated nodes), a nonconforming interface (one interface vertex moved off the circle), a filled void, a q domain reaching a band, and a label inside the tip guide. Each must be rejected.

## 4. Phase-aware solver and its qualification

`g2_t6_elasticity_phase` is new; `g2_t6_elasticity.m` is unchanged. It uses:
- the same straight-sided T6 kinematics and 3-point rule;
- a per-element D_e(E_phase, ν_phase) and shared nodal DOFs;
- no fill of the voids.

It reports per-phase strain energy and per-phase internal nodal forces, checks every element D_e
for positive definiteness, and checks the reduced stiffness by Cholesky.

**Benchmark** (`g2_coated_hole_exact`, `check_g2_material_benchmark`):
- **Problem.** A traction-free hole a = 6.35 mm, a bonded band to b = 19.05 mm and a matrix to c = 57.15 mm, under a remote 1 MPa uniaxial field. The exact solution is Lamé (axisymmetric) plus Michell (cos 2θ: r², r⁴, r⁻², r⁰), with 2 + 8 constants from the hole, interface and outer conditions. The outer circle takes the exact displacement.
- **Self-check of the exact field.** Finite-difference strains → Hooke → Airy stresses to 1e−7, plus continuity and traction-free residuals.
- **Meshes.** PDE Toolbox with the interface as a face boundary, Hmax 2.4 / 1.2 / 0.6 mm, ratios E_r/E_m = 0.5, 2 and 10.
- **Gates at the finest level:**
  - nodal displacement error ≤ 5e−3 of max|u|;
  - strain energy ≤ 5e−3;
  - interface traction moments (∫t·n, ∫t·n cos2θ, ∫t·t sin2θ from each side) ≤ 2e−2;
  - monotone decrease, with an observed order ≥ 1.0 on the finest pair.
- **Identity and reference checks.** Ratio 1 must equal the homogeneous solver to 1e−12. The stiffness must equal an independent element-loop assembly with a 6-point rule to 1e−12.
- **Negative controls** must fail the gates: swapped phases, and a partially detached interface (duplicated nodes on half the interface).

## 5. Cases, order and stop rules

**Order:**
1. Source and chain integrity, plus the 34/34 re-audit of the saved mesh (unchanged auditor).
2. Phase map, verifier and phase negative controls.
3. Benchmark.
4. H1 and M0 identity.
5. Msoft and Mstiff.
6. Report.

**HOLD rule.** Any failure is a HOLD that stops all later stages and is preserved. No retry without a committed investigation. No tolerance change after results. No higher contrast after a null result.

**Cases:**
- **H1:** the unchanged `g2_t6_elasticity` + `g2_trajectory_sif_on_mesh` (must reproduce the recorded K).
- **M0:** the new pipeline at ratio 1.
- **Msoft / Mstiff:** ratio 0.5 / 2, ν = 0.35 everywhere.
- **Shared model:** plane stress, E_m = 3268.115 MPa, t = 12.7 mm, P = 1 N downward at (254, 203.2), pin (25.4, 0), roller (482.6, 0).

**M0 identity gates:**
- stiffness ≤ 1e−13;
- u ≤ 1e−9 of max|u|;
- K_I, K_II (EDI and COD) ≤ 1e−9 of |K|;
- energy and compliance ≤ 1e−9;
- reactions ≤ 1e−9 P;
- MTS ≤ 1e−7°.

**Per case, all inherited SIF gates unchanged**: residual 1e−8, COD–EDI 3 %, contour spread 0.5 %, J identity 0.5 %, quadrature 0.1 %, whole-crack opening ≥ −1e−9 mm, K_II sign gate above |K_II/K_I| = 0.01. Added gates:
- q support in matrix only;
- EDI/COD with matrix E, ν;
- heterogeneous energy identity (U = W) ≤ 1e−9;
- interface nodal force balance ≤ 1e−8;
- annulus resultant ≤ 1e−8;
- K_ff positive definite.

## 6. Reported quantities, units and uncertainty

| Quantity | Definition |
|---|---|
| K_raw | MPa√mm at P = 1 N (EDI and COD) |
| K_per_kN (MPa√m) | K_raw·√1000 |
| K_phys at 1 N (MPa√m) | K_raw/√1000 |
| G_1N (N/mm) | (K_raw,I² + K_raw,II²)/E_m (×1000 for J/m²); EDI J reported as a cross-check |
| R_mat | G_M/G_H1; EDI primary, COD and J secondary |
| Mixity | ψ = atan2(K_II, K_I) |
| MTS | θ_MTS from `g2_mts_direction` (forecast only), Δθ = θ_M − θ_H1 |
| Compliance | C = \|u_y(load)\|/P, CMOD at the mouth twins, per-phase strain energy |

**Uncertainty of R:**
- U_R = max(contour spread of R over the five annuli, |R_EDI,4×4 − R_EDI|, |R_COD − R_EDI|).
- The effect is **resolved** iff |R_EDI − 1| > 2·U_R and R_COD − 1 has the same sign. Otherwise the result is "no resolved material effect".
- A conservative uncorrelated bound R·(δG_M + δG_H1), with δG = |G_EDI − G_COD|/G_EDI, is also classified and reported.

**K_II sign** is resolved iff |K_II,EDI| exceeds max(EDI−COD gap, contour spread, quadrature drift) and the COD sign agrees.

**Not studied (out of scope):** mesh refinement of R_mat, other path states, band thickness or contrast maps, interface debonding, physical properties.

## 7. Limits stated in advance

- One frozen geometry and one mesh, so the stability of R_mat under refinement is not established.
- Polygonal interfaces (inscribed 76-gon).
- Illustrative moduli, not measured cement/polymer data.
- Idealized point-load pin/roller BVP.
- The only mechanism tested is perfectly bonded two-phase elastic contrast around voids.
