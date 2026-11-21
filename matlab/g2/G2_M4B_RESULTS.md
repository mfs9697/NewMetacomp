# G2-M4.B results: frozen-S2 ring attribution and nonadditivity (Issue #47)

**Status:** numerical package complete. **REVIEW_STOP_B**, awaiting the researcher/ChatGPT scientific review. Nothing below is self-approved.

- **Policy and preregistration:** `G2_M4B_POLICY_v2.json` (SHA-256 `758f4394…b37b`), `G2_M4B_PREREGISTRATION.md`, both committed before any solve.
- **Run log:** `G2_M4B_RUNLOG.md`.
- **Evidence:** `evidence/m4b_20261121/`.
- **Word:** v0.4 candidate in `reports/G2/`.

**Scope.** All numbers are a **direct linear-elastic material effect at a fixed crack**:
- the frozen homogeneous S2 crack (s = 33.4 mm);
- the original 76-chord rings and the unchanged mesh (SHA `9269be43…`);
- P = 1 N, illustrative moduli, perfect bonding.

There are no new trajectories, no R_path/R_total and no onset/arrest/toughness claims. "Resolved" means **numerically robust within the preregistered estimator criteria**, not a physically established effect.

## 1. Gates

| Gate | Result |
|---|---|
| B0 inventory | PASS: policy, legacy-module pins to PR #46, mesh/review/baseline SHAs and ledger rows, R2023a + PDE Toolbox, RAM, clean tree |
| B1 activation | PASS: auditor 34/34; legacy phase map, verifier and 8 legacy negatives PASS; **independent owner oracle = `annulusOf` element by element**; 15/15 activations PASS; **10/10 new negatives rejected by the intended check** |
| B2 baselines | **33/33 bitwise:** `none` = CASE_S2_H1; `c0p5_111` = CASE_S2_Msoft; `c2p0_111` = CASE_S2_Mstiff (u, EDI, 4×4, COD, J, compliance, CMOD, reactions, energies); legacy `g2_material_sif_on_mesh` PASS and equal |
| B3 cases | 12/12 subset cases pass all inherited SIF gates and the partial-activation gates |
| Faults | **38/38**, including interrupt/resume without FEM and a bit-identical replay |

**Gate margins.**
- Active-interface balance ≤ 3.8e−12 (gate 1e−8).
- Energy identity ≤ 1.0e−11 (gate 1e−9).
- Residual ≤ 1.6e−12.
- MTS root check ≤ 8e−16 rad.

**Ring geometry.** All three rings have identical polygon area (1012.1525286 mm²) but different element counts (4088 / 4102 / 4088).

## 2. Ring positions in the S2 tip frame

The tip is at (103.409, 33.192) mm; the tangent is at 76.45°.

| Ring | Centre (mm) | Distance (mm) | Bearing from t (°) | Nearest ring node (mm) |
|---|---|---|---|---|
| 1 | (152.4, 69.85) | 61.19 | −39.6 | 42.14 |
| 2 | (152.4, 120.65) | 100.24 | −15.7 | 81.20 |
| 3 | (152.4, 171.45) | 146.68 | −6.0 | 127.63 |

All centres lie on the −n side of the tip frame. A positive F_θ is a counter-clockwise turn, towards +n, i.e. away from the ring side.

## 3. The 16 logical cases (EDI 6×6 primary; full precision in `cases_16_logical.csv`)

K is given per kN in MPa·√m.

| c | S | K_I | K_II | F_G | F_θ (°) | Compliance (mm/N) |
|---|---|---|---|---|---|---|
| — | none | 0.195982 | +0.003150 | 0 | 0 | 2.21802e−4 |
| 0.5 | {1} | 0.200300 | +0.000927 | **+4.430 %** | **+1.311** | 2.22707e−4 |
| 0.5 | {2} | 0.192384 | +0.003717 | **−3.628 %** | −0.371 | 2.22624e−4 |
| 0.5 | {3} | 0.198243 | +0.003799 | +2.331 % | −0.353 | 2.23077e−4 |
| 0.5 | {1,2} | 0.196312 | +0.001340 | +0.316 % | +1.058 | 2.23608e−4 |
| 0.5 | {1,3} | 0.202506 | +0.001515 | **+6.747 %** | +0.984 | 2.24010e−4 |
| 0.5 | {2,3} | 0.194309 | +0.004427 | −1.675 % | −0.767 | 2.23999e−4 |
| 0.5 | {1,2,3} | 0.198124 | +0.001983 | +2.181 % | +0.694 | 2.25017e−4 |
| 2 | {1} | 0.192332 | +0.004960 | **−3.652 %** | **−1.110** | 2.21039e−4 |
| 2 | {2} | 0.198942 | +0.002665 | +3.035 % | +0.306 | 2.21110e−4 |
| 2 | {3} | 0.194193 | +0.002632 | −1.825 % | +0.288 | 2.20788e−4 |
| 2 | {1,2} | 0.195069 | +0.004387 | −0.906 % | −0.734 | 2.20393e−4 |
| 2 | {1,3} | 0.190513 | +0.004406 | **−5.478 %** | −0.806 | 2.20043e−4 |
| 2 | {2,3} | 0.196954 | +0.002178 | +0.980 % | +0.574 | 2.20151e−4 |
| 2 | {1,2,3} | 0.193075 | +0.003866 | −2.931 % | −0.452 | 2.19450e−4 |

In every case K_I > 0, K_II > 0 and the K_II sign agrees between EDI and COD.

## 4. Decomposition (both rules; `decomposition.csv`)

| Term | F_G soft | F_G stiff | F_θ soft (°) | F_θ stiff (°) |
|---|---|---|---|---|
| f_1 | +4.430 % (B) | −3.652 % (B) | +1.311 (B) | −1.110 (B) |
| f_2 | −3.628 % (B) | +3.035 % (P) | −0.371 (B) | +0.306 (B) |
| f_3 | +2.331 % (P) | −1.825 % (P) | −0.353 (B) | +0.288 (B) |
| I_12 | −0.486 % (P) | −0.289 % (P) | +0.119 (B) | +0.070 (B) |
| I_13 | −0.014 % (P) | −0.001 % (P) | +0.026 (P) | +0.016 (P) |
| I_23 | −0.378 % (P) | −0.230 % (P) | −0.042 (P) | −0.021 (P) |
| I_123 | −0.073 % (P) | +0.031 % (P) | +0.005 (P) | −0.001 (P) |
| Shapley φ_1 / φ_2 / φ_3 | +4.16 / −4.08 / +2.11 % | −3.79 / +2.79 / −1.93 % | +1.385 / −0.331 / −0.360 | −1.067 / +0.330 / +0.285 |

Key: B = resolved by both rules; P = resolved by the primary rule only.

**Identities.**
- Reconstruction F_123 = Σf + ΣI + I_123: ≤ 2.2e−16 (F_G), ≤ 4.4e−16° (F_θ).
- Shapley sum ≤ 2.2e−16.

**Uncertainty sizes.**
- Primary U ≤ 1.7e−6 (F_G) and ≤ 0.008° (F_θ).
- Conservative U ≈ 3.4–3.7 % for one case, ≈ 7 % for a pair interaction, ≈ 14 % for I_123 (G); 0.02–0.09° for θ.

**Readings (preregistered rules).**
- **F_G:** NONADDITIVE_PRIMARY (all four interaction terms resolved under the primary rule), but ADDITIVE_WITHIN_CONSERVATIVE (none resolved under the conservative rule).
- **F_θ:** NONADDITIVE_PRIMARY; I_12 is also resolved under the conservative rule (NONADDITIVE_CONSERVATIVE).
- **H1 (unequal ring influence):** SUPPORTED_PRIMARY for both observables.
  - For F_G, f_1 − f_2 (+8.06 %) and f_2 − f_3 (−5.96 %) are resolved by both rules.
  - For F_θ, f_1 − f_2 and f_1 − f_3 (+1.68° / +1.66°) are resolved by both rules.
- **H2:**
  - By the preregistered magnitude-order rule it is REFUTED: |f_1| > |f_2| > |f_3| for both observables.
  - The **sign patterns differ**:
    - for G, the ring 2 sign is opposite to rings 1 and 3;
    - for θ, the ring 1 sign is opposite to rings 2 and 3.
  - The θ difference f_2 − f_3 (0.018°) is resolved by the primary rule only.
- **H3 (interactions):** NONADDITIVE under the primary rule for both observables. For G, interactions are unresolved under the conservative rule.

## 5. Equal-active-area comparisons

**One ring (1012.15 mm² each), soft:** ring 1 +4.43 %, ring 2 −3.63 %, ring 3 +2.33 %. The same amount of soft material changes G by between −3.6 % and +4.4 % depending only on placement. Stiff mirrors this: −3.65 / +3.04 / −1.83 %.

**Two rings (2024.31 mm² each), soft:** {1,2} +0.32 %, {1,3} +6.75 %, {2,3} −1.68 %.
- D_12_13 and D_13_23 are resolved by both rules.
- D_12_23 is resolved by the primary rule only.

**Stiff two-ring sets:** −0.91 / −5.48 / +0.98 %. The largest G reduction of all 15 configurations is stiff {1,3} (−5.48 %, resolved by both rules).

## 6. Observations offered for review (not established mechanisms)

1. **The accepted full-band effect is a small net of cancelling single-ring effects.**
   - Soft: F_123 = +2.18 % = (+4.43 − 3.63 + 2.33) % + interactions (−0.95 %).
   - The M2/M3 "soft rings increase G by ~2 %" therefore hides placement effects about twice as large and of opposite sign.
2. **Steering is dominated by ring 1 (the nearest).** f_θ,1 is 3.5–3.9 times |f_θ,2| and |f_θ,3|, and of opposite sign. Rings 2 and 3 steer almost equally (difference 0.018°).
3. **G is not dominated by proximity alone.** Ring 3 (147 mm away) changes G by +2.3 % (soft). Sign alternates 1 / 2 / 3.
   - The energy-density maps (figure 5) show redistribution over the whole loaded ligament, consistent with a global load-path (bending) contribution.
   - This is a reading of the fields, not a separated mechanism.
4. **Interactions are 1–2 orders smaller than main effects.**
   - For G, |I_ij| ≤ 0.49 %. They are unresolved under the conservative rule.
   - The sizes of **I_13 (soft −1.4e−4, stiff −1.4e−5) and I_123 (±3–7e−4)** compare with the M4.A cross-family drift of R_direct (≈ 1.5–2e−5). This comparison is a post-hoc informational check, not a preregistered rule.
   - Stiff I_13 is at the discretization-drift scale and should not be interpreted, even though the primary estimator rule marks it resolved.
5. **What the primary rule measures.** It quantifies agreement between estimators (EDI contours, 4×4, COD) on one mesh. It is not a discretization-error bound. The M4.A family test bounds discretization effects only for the full-band case.

## 7. Candidate architectures for a future, separately authorized matrix-only trajectory study (proposal only)

These are not run and not authorized. Selection is for the second scientific review. Each candidate would stop before any interface contact or the outer boundary.

- **C1 – stiff {1,3}.** Largest G reduction (−5.48 %, both rules) with steering towards the ring side (−0.81°). Tests whether a shielding arrangement also draws the path towards ring 1.
- **C2 – soft {2}.** G reduction (−3.63 %, both rules) with weak steering (−0.37°). Shielding with nearly unchanged direction; the matrix-only bypass case.
- **C3 – soft {1}.** Strongest steering away from the rings (+1.31°) with G amplification (+4.43 %). A contrast case for avoidance.

## 8. Limitations

- One frozen crack (S2), one mesh, two contrasts, perfect bonding, linear elasticity, P = 1 N.
- The near-tip core is shared with every earlier stage.
- Mesh refinement of subset effects was not studied. The M4.A family check covered only the full-band case.
- The conservative rule (≈ ±3.5 %) leaves f_3 (both contrasts), f_2 (stiff) and all G interactions unresolved.
