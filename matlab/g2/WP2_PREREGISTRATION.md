# WP2 preregistration: idealized elastic BVP and signed SIF acceptance criteria (Issue #20)

**Committed before any WP2 solver code was written or any WP2 number was computed.** Nothing below may be relaxed after results are seen; a failed criterion is a finding to diagnose.

## 1. Source and evidence table

Source: `docs/research/crack-growth-gaps-2026/G2_SPECIMEN1_1990_GEOMETRY.json` (SHA-256 `45A88FA0…790B47BF`).

| Item | Original Cornell specimen #1 (1990) | Status in the source | Idealized WP2 model (declared, not experimental) |
|---|---|---|---|
| Geometry | 508 × 203.2 × 12.7 mm PMMA beam, 3 holes R 6.35 mm, edge crack 25.4 mm at x = 101.6 mm | nominal reconstruction, secondary figure confirmed | as the source (nominal) |
| Supports | pin at (25.4, 0), roller at (482.6, 0); span 457.2 mm | idealized; roller/pin compliance, contact radii, friction, horizontal restraint **unknown** | point pin u_x = u_y = 0 at (25.4, 0); point roller u_y = 0 at (482.6, 0) |
| Load | downward at top midspan (254, 203.2) | resultant position only; **magnitude not recorded**; nose contact width unknown | point force P = 1 N downward (2D line load P/t, t = 12.7 mm) |
| Control | slow monotonic CMOD control; force is a measured response | not reproduced | linear static, load-controlled unit load (results scale linearly with P) |
| Plane assumption | not stated | **unknown** | plane stress (primary); plane strain computed as an invariance check |
| E, ν | 1990 calibration (no holes) mean E = 3268.115 MPa; ν not given; secondary model E = 3102.641 MPa, ν = 0.35 | specimen-#1-specific values **unknown** | E = 3268.115 MPa, ν = 0.35 (selected, not measured) |
| Crack faces, holes | traction free | nominal | traction free (no contact) |
| K_Ic, G_c | — | **unknown** | none; WP2 makes **no** fracture-onset statement |
| Experimental path | intercepted by an interior hole (Fig. 5.5) | coordinates **not obtained** | no comparison in WP2 |

Units: mm, N, MPa (N/mm²). K is computed in MPa·√mm and reported also in MPa·√m (÷ √1000). For the statically determinate supports and traction-free holes used here, the continuum stress field per unit load does not depend on E, ν or the plane assumption; only displacements, compliance and G = (K_I² + K_II²)/E′ do.

## 2. Local crack frame and sign convention

- Tip at (101.6, 25.4) mm; crack tangent **t = (0, 1)** (direction of growth), normal **n = (−1, 0)**.
- Local coordinates x₁ = (x − x_tip)·t, x₂ = (x − x_tip)·n; polar angle θ from +x₁ towards +x₂; the crack faces are θ = ±π.
- **Upper face** (θ = +π) = the face on the +n side = the left face (x < 101.6 mm) = `upperBankT6`; **lower face** (θ = −π) = right face = `lowerBankT6`.
- Opening δ_n = u·n(upper) − u·n(lower); sliding δ_t = u·t(upper) − u·t(lower). K_I > 0 for an opening crack; K_II > 0 when the upper face slides in +t relative to the lower face (standard Williams convention).

## 3. Methods

- **FE solver:** quadratic straight-sided T6, plane stress / plane strain, consistent stiffness by Gaussian quadrature; sparse direct solve.
- **Estimator 1 (EDI):** domain interaction integral with FE-nodal q (q = 1 for r ≤ r_in, linear to 0 at r_out), Williams leading-term auxiliary fields, over q-active elements only. Primary annulus r_in = 0.4, r_out = 2.6 mm (source p010). Additional admissible annuli (support inside the kernel inradius 2.996 mm): (0.2, 1.0), (0.4, 1.6), (0.8, 2.6), (1.2, 2.4) mm. J from the same domain without auxiliary fields.
- **Estimator 2 (COD), algebraically independent of EDI:** crack-face displacement jumps of the T6 twin node pairs on both banks; apparent K(r) = (E′/8)·√(2π/r)·δ; least-squares line K(r) = K₀ + K₁ r fitted on **0.1 ≤ r ≤ 1.5 mm**, extrapolated to r → 0. E′ = E (plane stress) or E/(1 − ν²) (plane strain).

## 4. Acceptance criteria (K_ref = √(K_I² + K_II²) of the reference)

| ID | Test | Criterion |
|---|---|---|
| S1 | patch test: linear displacement field imposed on the boundary of the protected block | stresses exact to ≤ 1e−9 relative; zero strain energy for the 3 rigid modes ≤ 1e−12 relative |
| S2 | auxiliary-field self-check: Williams u differentiated numerically vs Williams σ through Hooke's law | ≤ 1e−6 relative |
| M1 | manufactured Williams fields (exact displacements on the r = 3.3 mm rim of the isolated p010 block; crack faces free): pure I (1, 0), pure II (0, 1), mixed (0.6, −0.8), each with and without T | EDI: abs(K − K_exact) ≤ 1.0 % K_ref; COD: ≤ 3.0 % K_ref; sign of K_II correct in every case |
| M2 | path independence (5 annuli) in M1 and C2 | (max − min)/K_ref ≤ 0.5 % for each of K_I, K_II |
| M3 | energy consistency in M1 and C2 | abs(J/((K_I² + K_II²)/E′) − 1) ≤ 0.5 % |
| M4 | quadrature: 4×4 vs 6×6 collapsed Gauss in the EDI | abs(ΔK) ≤ 0.1 % K_ref |
| B1 | classical benchmark: edge crack a = 25.4 mm in a holeless beam of the same depth W = 203.2 mm, pure bending, crack ≥ 2.5 W from the loaded ends; Tada–Paris–Irwin F(a/W) = 1.122 − 1.40α + 7.33α² − 13.08α³ + 14.0α⁴ (stated accuracy 0.2 %) | EDI: abs(K_I/K_Tada − 1) ≤ 1.0 %; COD: ≤ 3.0 %; abs(K_II)/K_I ≤ 0.5 % |
| C1 | Cornell idealized BVP: equilibrium | relative residual ≤ 1e−8; reactions balance the load to ≤ 1e−8 relative (forces and moment) |
| C2 | Cornell idealized BVP: EDI vs COD | abs(K_EDI − K_COD) ≤ 3.0 % K_ref for K_I and K_II |
| C3 | Cornell: elastic-constant invariance (plane stress ν 0.35 vs plane strain ν 0.35 vs plane stress ν 0.30) | K changes ≤ 0.5 % K_ref |
| C4 | Cornell: exterior refinement (qualified family Hmax 6 / Hface 1.5 / Hedge 0.45 vs refined family Hmax 4 / Hface 1.0 / Hedge 0.30, each passing the WP1 38-gate and protected-tip audits) | abs(ΔK) ≤ 1.0 % K_ref |

A Cornell SIF is reported as **verified** only if S1, S2, M1–M4, B1 and C1–C4 all pass. Any failure is a HOLD for WP3. All Cornell numbers are for the idealized unit-load model of §1 and are **not** experimental values.
