# G2-M4.B preregistration: frozen-S2 ring attribution and nonadditivity (Issue #47)

**Status:** prospective. This file and `G2_M4B_POLICY_v2.json` are committed **before any M4.B solve**. Nothing below is a result.

- **Authorization:** scientist review on Issue #44 (comment 7066297598, decision C) and Issue #47.
- **Brief:** draft PR #48 (`9467e21`), stacked on PR #46 (`97c9562`).
- **Historical policy:** `G2_M4_POLICY_v1.json` (SHA-256 `2548f373…`) is not edited. Its `M4_B = NOT AUTHORIZED` stays as the record of the M4.A stage.

## 1. Question

On one frozen crack, mesh and load, how much of the direct elastic effect on G and on the MTS direction comes from each of the three bonded annuli? How much comes from their pairwise and triple interactions?

This is a material attribution at fixed geometry. It is not a trajectory, an onset or an arrest study.

## 2. Fixed inputs

**Crack and mesh.**
- **Mesh:** the original homogeneous S2 crack mesh, `outputs/g2_trajectory_chain_v1_attempt2/STEP_002/KINKED_GEOMETRY_ONLY_candidate.mat`, SHA-256 `9269be43…c412`. It has 28,625 T3 / T6 elements, 58,161 nodes, and 3 × 76 conforming ring chords at r = 19.05 mm.
- **Not used:** the M4.A 112-chord family, S2alt and the material-specific S2 geometries.

**Plate and loading.**
- Cornell plate 508 × 203.2 mm, plane stress, t = 12.7 mm.
- E_m = 3268.115 MPa, ν = 0.35.
- P = 1 N downward at (254, 203.2) mm; pin at (25.4, 0); roller at (482.6, 0).

**Rings.**
- IDs follow ascending y: 1 at (152.4, 69.85), 2 at (152.4, 120.65), 3 at (152.4, 171.45) mm.
- Holes are voids in every case.
- An inactive ring has the matrix modulus.
- An active ring has E = c·E_m, with c ∈ {0.5, 2.0}.

## 3. Design (exactly 16 logical cases, 15 solves)

| Mask | Bits | Active set | Use |
|---|---|---|---|
| none | 000 | ∅ | homogeneous control (shared by both c) |
| ring1 / ring2 / ring3 | 100 / 010 / 001 | {i} | single-ring effects |
| rings12 / rings13 / rings23 | 110 / 101 / 011 | {i,j} | pair effects |
| all | 111 | {1,2,3} | full-band regression control |

**Physical case IDs:** `none`, then `c0p5_<bits>` and `c2p0_<bits>` for the seven non-empty masks.

Any other case is refused before any solve (`HOLD_CASE_OUTSIDE_DESIGN`). Not allowed:
- a 17th case;
- mixed per-ring moduli;
- a retry after a HOLD without a documented investigation.

## 4. Material assignment (new, separate from legacy)

- **Topology** comes from the qualified mapper: `ownerRing = PM.annulusOf` from `g2_material_phase_map` (flood fill blocked at the chords).
- **Owner oracle** `g2_m4b_ring_owner_oracle` (new):
  - classifies all six T6 nodes of every element against each ring polygon and hole polygon;
  - uses the half-plane of the chord whose angular span contains the node, so it shares no code with the legacy mapper or the legacy verifier;
  - must equal `annulusOf` element by element.
- **Assembly label** `g2_m4b_ring_activation`: `phaseForAssembly = 1 + (ownerRing > 0 & mask(ownerRing))`.
  - `ownerRing` is always kept as a separate field.
  - The unchanged `g2_t6_elasticity_phase` assembles with `mats = [matrix, c·matrix]`.
- **Activation verifier** `g2_m4b_activation_verify` (new) checks:
  - oracle agreement, ring IDs (ascending y) and the canonical mask;
  - the label of every element derived from the mask;
  - per-ring counts and areas, the active area, and the chord owners with shared midsides;
  - material jump present on active-ring chords and absent on passive-ring chords; jump-edge count = 76 × number of active rings;
  - no void filling, and admissible SPD materials;
  - q support and the 15 mm tip guide free of any ring-owned element, with q clearance ≥ 1 mm;
  - connectivity, and coincident nodes only at registered crack twins.

**Legacy routines.** `g2_material_phase_map`, `g2_material_phase_verify`, `check_g2_m2_phase_controls` and `g2_material_sif_on_mesh` are not modified. They run first, unchanged, on the full-band topology, and must PASS.

**Negative controls of the new verifier:**
- wrong mask;
- swapped ring IDs;
- swapped centre order;
- matrix element given label 2;
- ring element dropped;
- detached midside;
- q reaching a ring;
- node moved into a hole;
- wrong modulus;
- inactive ring given a jump.

Each control must be rejected by the intended check.

**Partial-activation SIF** `g2_m4b_sif_partial` (new): the same solve and the same COD and EDI calls as `g2_material_sif_on_mesh`. Differences:
- interface balance and resultant gates are applied to active rings only;
- passive rings get geometric checks; their side tractions are reported as information, not as a gate;
- the q support must be free of every ring-owned element.

## 5. Blocking baselines (B2), before any subset case

1. **`none`** must equal `CASE_S2_H1` of PR #38 run D **bitwise** in:
   - u, the five-annulus EDI [K_I K_II J], EDI 4×4, K_COD, CMOD and compliance.

   The basis is that the same assembly path gave an exactly zero M0 identity. There is no fallback threshold.
2. **`c0p5_111` and `c2p0_111`** must equal `CASE_S2_Msoft` / `CASE_S2_Mstiff` **bitwise** in:
   - u, EDI, EDI 4×4, COD, J, compliance, CMOD, reactions, and total and phase energy.

   In addition, the legacy `g2_material_sif_on_mesh` must PASS on both states and agree bitwise.
3. Any failure → `HOLD_BASELINE_REGRESSION`. No subset result is produced.

## 6. Quantities

- **G** = (K_I² + K_II²)/E_m, primary estimator EDI 6×6 on q = 0.4–2.6 mm.
- **θ** = MTS direction in the S2 terminal-segment frame, signed degrees.
- **F_G**(S;c) = G(S;c)/G(∅) − 1, and **F_θ**(S;c) = θ(S;c) − θ(∅).
- **Decomposition:** f_i = F({i}), I_ij = F({i,j}) − f_i − f_j, and I_123 = F({1,2,3}) − Σf_i − ΣI_ij.
  - It is computed for F_G and F_θ separately; the two are never combined.
  - Reconstruction identity ≤ 1e−12 (F_G) and ≤ 1e−10° (F_θ).
- **Shapley values:** reported as bookkeeping, with an exact sum identity.
- **Equal-area comparisons:** 1-ring vs 1-ring and 2-ring vs 2-ring only.
- **Also reported:**
  - signed K (EDI, COD, 4×4, five contours) and J;
  - compliance, CMOD, total and per-ring energy, reactions;
  - active area;
  - active-interface balance;
  - ring positions in the tip frame.

## 7. Uncertainty (both reported for every quantity)

- **Estimator variants** e:
  - the four other EDI q annuli;
  - EDI 4×4;
  - blind bank COD.
- **Primary (paired, correlated):**
  - Q_e is the same linear combination computed with variant e in every case;
  - U_Q = max_e |Q_e − Q|;
  - resolved iff |Q| > 2 U_Q and sign(Q_COD) = sign(Q).
  - For F_G(S) this is exactly the inherited U_R rule.
- **Conservative (uncorrelated), G:**
  - d_k = |G_EDI − G_COD|/G_EDI per case;
  - U = Σ_{k≠∅} |a_k| (G_k/G_∅) d_k + |Σ_{k≠∅} a_k G_k/G_∅| d_∅;
  - for F_G(S) this equals the inherited R(d_S + d_∅) ≈ ±3.5 %.
- **Conservative, θ:** U = Σ_k |a_k| |θ_COD,k − θ_EDI,k|.
- **Classes:** RESOLVED_BOTH, RESOLVED_PRIMARY_ONLY, UNRESOLVED.

## 8. Readings (no pass criterion on physics)

- **Additivity:**
  - ADDITIVE_WITHIN_PRIMARY if no I_ij or I_123 is resolved under the primary rule;
  - otherwise NONADDITIVE_PRIMARY, with the resolved terms listed;
  - the conservative verdict is reported alongside.
- **Ranking:** rings are ordered by f_i only where the 1-ring differences are resolved; otherwise they are ties.
- **Hypotheses:** H1–H3 of `G2_M4B_RING_ATTRIBUTION_DESIGN_UA.md` can be confirmed, refuted or left unresolved. Null outcomes are admissible.

## 9. Integrity

- **Token:** `G2M4BRUN|<policy SHA>|src=<source-set SHA>|mesh=<S2 SHA>|cases=16|solves=15`. Each case record carries its own case token.
- **Dry runs** write nothing.
- **Run requirements:**
  - a clean tree;
  - R2023a with the PDE Toolbox;
  - ≥ 5 GiB free RAM (cannot be lowered);
  - one MATLAB process.
- **Records** are immutable (SHA manifests). Reuse happens only after full re-verification, with no FEM on reuse.
- **Fault suite (policy list):**
  - dry run;
  - tampered mesh;
  - owner swap;
  - centre order;
  - off-band E;
  - broken midside;
  - q reaching a ring;
  - KII sign reversal;
  - bad tokens;
  - policy and source drift;
  - forged record;
  - interrupt and resume;
  - bit-identical replay;
  - low RAM;
  - case outside the 16.

## 10. Word

- The canonical v0.3 is verified by SHA (`49daba7e…`) and archived unchanged.
- A new **v0.4 candidate** contains:
  - the reviewed M4.A Appendix E;
  - a new M4.B section;
  - G2-REV entries;
  - all text and figures in Ukrainian.
- Every page is rendered through Word and inspected.
- Results are marked «очікує наукової перевірки».

## 11. Stop

**REVIEW_STOP_B** after one consolidated package.

The following are not authorized:
- M4.C;
- trajectories;
- a third increment;
- 3³ designs;
- interface approach;
- CZM;
- toughness and arrest claims.

Two or three candidates for future matrix-only paths may be proposed, as a proposal only.
