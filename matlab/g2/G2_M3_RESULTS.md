# G2-M3 independently evolved soft and stiff crack paths: results (Issue #39)

**Verdict: GO.** Two material-specific numerical paths were computed, each two 4 mm increments from the WP2 straight crack and each in its own chain. Every mesh, phase, FEM and SIF gate passed.

**Supporting checks:**
- the direct / path / total decomposition is complete for both materials;
- the preregistered alternative-mesh check classifies R_path as ROBUST for both;
- the fault, restart and replay suite passes 20/20.

All numbers come from genuine MATLAB R2023a runs. Preregistration (`eead928`) and amendment A1 (`6c929fc`, code `923b6b8`) were committed before any increment. Policy `G2_M3_TRAJECTORY_POLICY_v1.json`, SHA-256 `CF3023B5…6DA9A8`.

**What these paths are.** Numerical paths **conditional on assumed 4 mm advances**, under the idealized 1 N pin/roller BVP with illustrative moduli and perfectly bonded bands. They make no onset, arrest, toughness or experimental claim, and no third increment was taken.

## 1. Stages

| Stage | Soft (E_r/E_m = 0.5) | Stiff (2) |
|---|---|---|
| ROOT: PR #38 S0 record, hash vs M2 ledger; S0 solve recomputed | bitwise equal | bitwise equal |
| H-REC control (recurrence reproduces Γ_H, read-only) | S1 and S2 exact (0 mm) | same |
| M1 (s = 29.4 mm) | K1–K10; 28,431 T3; 34/34; 3×76 chords; all SIF gates; REVIEW, then STATE | K1–K10; 28,417 T3; 34/34; 3×76; all gates |
| M2 (s = 33.4 mm) | 28,605 T3; 34/34; 3×76; all gates; STEP_CAP | 28,629 T3; 34/34; 3×76; all gates; STEP_CAP |
| Chain re-verification (analysis, dry) | forecasts, hashes, mesh content, 34/34, phase re-map: PASS | PASS |
| Alternative M2 mesh (112 chords, Hmax 5) | 35,117 T3, 34/34, all gates: **ROBUST** | 35,109 T3, 34/34: **ROBUST** |

**Faults and restarts: 20/20.**
- Refused with the right reason: a dry run writes nothing; a step-3 request; a wrong-material token; a switched material on a chain; a forged review pointing at the other material's mesh; phase labels inconsistent with the polygons; policy drift; source drift; a changed parent K; a wrong parent hash; swapped banks; a bad segment; tampered state bytes; a dirty source; a chain containing a HOLD; a partial step.
- Handled safely: a complete chain is reused without FEM; an interrupted review is promoted without FEM and equals the accepted state; a state is reused after an interrupt.
- A full replay of the stiff chain is **bit-identical** in mesh, phase, u, EDI and COD.
- The accepted chains were byte-unchanged afterwards.

**Mesh comparability.** All four new meshes are geometry-equivalent: 3×76 chords, band area 1012.152529 mm² (equal to S2). Tip-to-band distances are soft 45.30 / 42.20 mm and stiff 45.26 / 42.10 mm.

## 2. Paths

| s (mm) | Homogeneous Γ_H tip | Soft Γ_soft tip | Stiff Γ_stiff tip |
|---|---|---|---|
| 25.4 | (101.6, 25.4) | same | same |
| 29.4 | (102.4722795671, 29.3037326185) | (102.4281543212, 29.3133311156) | (102.5011858237, 29.2971610322) |
| 33.4 | (103.4091509165, 33.1924691839) | (103.3208725513, 33.2124405218) | (103.4677612981, 33.1786210478) |

| s | Soft offset from Γ_H (lateral, + = left) | Stiff offset | U_sep / U_cons | Resolved (primary / conservative) |
|---|---|---|---|---|
| 29.4 | **+0.04516 mm** | **−0.02964 mm** | 1.6e−4 and 9.7e−5 / 8.2e−3 and 8.4e−3 | yes / yes (both) |
| 33.4 | **+0.09050 mm** | **−0.06022 mm** | 3.4e−4 and 2.1e−4 / 1.8e−2 and 1.8e−2 | yes / yes (both) |

- The soft and stiff tips are 0.0748 mm apart at 29.4 mm and 0.1507 mm apart at 33.4 mm. The full polylines separate no more than their tips do.
- The homogeneous S1 tip carries a 4.5e−6 mm offset from its six-digit seed (amendment A1), about 1e−4 of these separations.
- Path separation was not re-meshed. It is a **single-mesh-family numerical observation**, resolved against the preregistered estimator-based U_sep.

## 3. Direct, path and total effects on G (same load, same arclength)

| Material | s | R_direct = G_M[Γ_H]/G_H[Γ_H] | **R_path = G_M[Γ_M]/G_M[Γ_H]** | R_total = G_M[Γ_M]/G_H[Γ_H] | Path share of δR_direct |
|---|---|---|---|---|---|
| soft | 25.4 | 0.993907 | 1 (identical) | 0.993907 | — |
| soft | 29.4 | 1.006199 | **0.999511** | 1.005706 | −7.9 % |
| soft | 33.4 | 1.021813 | **0.998826** | 1.020614 | −5.4 % |
| stiff | 25.4 | 0.990960 | 1 | 0.990960 | — |
| stiff | 29.4 | 0.981870 | **1.000396** | 0.982259 | −2.2 % |
| stiff | 33.4 | 0.970687 | **1.000813** | 0.971476 | −2.8 % |

**Supporting values:**
- R_path from COD agrees: 0.999513 / 0.998826 for soft, 1.000395 / 1.000813 for stiff.
- R_total = R_direct · R_path holds to ≤ 2.2e−16 relative.
- G_M[Γ_M] at 1 N (N/mm): soft 1.0259e−8 / 1.1998e−8; stiff 1.0020e−8 / 1.1420e−8.

**Uncertainty:**
- **Primary:** U = 1.0e−5 for every cross-mesh ratio. That is the preregistered mesh floor U_mesh = |G_H1(S2alt)/G_H1(S2) − 1| = 9.98e−6, which dominates the estimator spread.
- **R_path is resolved under the primary rule** at both increments for both materials (|δR_path| = 4–12 × 10⁻⁴ > 2U).
- **Conservative bound:** none of R_direct, R_path or R_total is resolved under it (about ±3.5 %). Both verdicts are reported.

**Robustness on the alternative M2 mesh** (all gates PASS). R_path,alt = G_M,alt[Γ_M2] / G_M,S2alt[Γ_H]:
- soft: 0.998826 against 0.998826 (δ differs by 1.2e−7);
- stiff: 1.000813 against 1.000813;
- both **ROBUST**.

## 4. Steering

| | θ at S0 (frame t = (0, 1)) | θ at the M1 tip (own frame) | θ forecast at the M2 tip (own frame) | Global terminal tangent at 33.4 mm |
|---|---|---|---|---|
| H | −12.5958° | −0.9498° (at S1) | −1.8407° (at S2) | 76.454° |
| soft on Γ_H (PR #38) | −11.9489° | −0.2072° | −1.1464° | — |
| **soft own path** | −11.9489° | **−0.9470°** | **−1.9106°** | 77.104° |
| stiff on Γ_H (PR #38) | −13.0203° | −1.4424° | −2.2923° | — |
| **stiff own path** | −13.0203° | **−0.9633°** | **−1.7865°** | 76.016° |

Own-path Δθ against H, with the primary U:
- **soft:** +0.6469° (0.0022), **+0.0028° (0.0004)**, **−0.0699° (0.0008)**;
- **stiff:** −0.4246° (0.0014), **−0.0134° (0.0003)**, **+0.0542° (0.0006)**.

All are resolved under the primary rule. On the alternative mesh, the M2 forecast changes by ≤ 0.0009°.

## 5. Interpretation (cautious)

1. **The material steers the first increment only.** At S0 the bands turn the tip by +0.65° (soft) or −0.42° (stiff). After that increment, the local MTS turn on each material's own path returns almost exactly to the homogeneous value: Δθ = +0.003° and −0.013° at M1. On the frozen path it would have been +0.74° and −0.49°.

   The reason is that K_II on the own path (soft +0.001513, stiff +0.001521) almost equals the homogeneous K_II (+0.001514). The kink the material selected cancels its own K_II offset. At M2 the forecast slightly **counter-steers** back toward Γ_H (−0.07° soft, +0.05° stiff).

   **Consequence:** the paths run nearly parallel to Γ_H with a persistent heading offset (+0.65° soft, −0.44° stiff), so the lateral offset grows roughly linearly (0.045 → 0.091 mm soft, 0.030 → 0.060 mm stiff).
2. **The path term opposes the direct effect for both materials.**
   - Soft bands amplify G on the frozen path (R_direct > 1 at s ≥ 29.4 mm), but their own path lowers G slightly (R_path < 1).
   - Stiff bands shield on the frozen path (R_direct < 1), but their own path raises G slightly (R_path > 1).
   - The path term removes 5–8 % of the direct soft amplification and 2–3 % of the direct stiff shielding.
   - So the sign and order of the material effect are set by the direct term: R_total stays above 1 for soft at s ≥ 29.4 mm and below 1 for stiff. Path feedback moderates it.
3. **The soft sign change survives on the own path.** R_total(soft) is 0.99391 at 25.4 mm, then 1.00571 and 1.02061: shielding before the first increment, amplification after. As before, it is resolved under the primary rule only.
4. **The path term is small but robust.** |δR_path| is 4–12 × 10⁻⁴, 40–120 times the mesh floor. It is identical to six digits on an independent 112-gon / Hmax 5 mesh at M2, and the COD estimator agrees. Path separation was not re-meshed.

## 6. Limitations

- Two increments only. The paths are conditional on assumed advance under an idealized point-load BVP, with illustrative moduli and perfect bonding.
- One alternative mesh per material at M2; no alternative full path.
- The conservative bound resolves no ratio.
- The comparison H path (WP3/WP3.4) used a six-digit seed at S0 (offset 4.5e−6 mm), which is negligible here.
- Not addressed: the hole-versus-no-hole decomposition, longer paths, interface debonding/CZM, and physical onset or toughness.

## 7. Reproduce (PowerShell, repository root)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_m3_trajectory.ps1 -Material soft          # dry, writes nothing
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_m3_trajectory.ps1 -Material soft -Run     # token bound to policy SHA
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_m3_trajectory.ps1 -Material stiff -Run
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_m3_trajectory.ps1 -Mode analysis
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_m3_trajectory.ps1 -Mode faults
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_m3_trajectory.ps1 -Mode report -RunDir .\outputs\g2_material_trajectories_v1\analysis_run_<time>
```

The inputs are the PR #38 run `run_20261121_132226_301`, the copied WP2 S0 mesh, the homogeneous chains and the P0 MAT. A new run needs a new chain folder; existing chains are only reused after re-verification.

## 8. Files and hashes

**New code:** `g2_m3_trajectory_run.m`, `g2_material_phase_stage.m`, `run_g2_m3_analysis_batch.m`, `run_g2_m3_faults_batch.m`, `run_g2_m3_report_batch.m`, `run_g2_m3_trajectory.ps1`. PR #35–#38 modules are reused unchanged.

**Chain records (SHA-256):**

| Record | Soft | Stiff |
|---|---|---|
| ROOT | `4d902643…cc8c` | `059c072c…6c00` |
| STATE step 1 | `242d05ba…463b` | `ae75cd27…590b` |
| STATE step 2 | `25e64310…02a6` | `b88a46ea…93c7` |
| Mesh step 1 | `2c7c29e4…6c6c` | `d649d2e9…29b` |
| Mesh step 2 | `af7a9a3a…3c00` | `1232f152…9c20` |

The analysis ledger is `analysis_run_20261121_142837_725/LEDGER.json`. The full 430-file list is in `evidence/m3_20261121/SHA256SUMS_original_outputs.txt`.

**Figures:** `evidence/m3_20261121/report/m3_paths_offsets.png`, `m3_ratios.png`, `m3_G_theta.png`, `m3_phase_snapshot.png`, and `analysis/m3_decomposition.csv`.
