# G2-M4 preregistration (Issue #44): M4.0 and M4.A

**Date:** 21.11.2026. **Policy:** `G2_M4_POLICY_v1.json`. Its SHA-256 is bound into every run token and record.

**Branch:** `research/g2-m4-alt-mesh-family-20261121`, stacked on the brief head `bbb7c25`. The brief head contains PR #43 (`9eb5c88`) and PR #41 (`92636e5`).

This file and the policy were committed **before any G2-M4 physical solve**. The only earlier G2-M4 computation was the mesh-only M4.0 feasibility batch (no FEM), described below.

**Stage M4.B (ring factorial) is NOT AUTHORIZED.** It needs explicit researcher authorization after the M4.A review, and a new policy version committed before any ring-subset solve.

## 1. Question and hypotheses

G2-M3 (PR #41) found two things on the original mesh family:

- soft and stiff paths that separate from the homogeneous path (+0.0905 mm and −0.0602 mm at s = 33.4 mm);
- a path term `R_path` that opposes the direct material effect.

The only robustness check was one alternative mesh at the *final* geometry. M4.A asks whether the **whole two-step history** is reproduced on an independently generated mesh family.

- **H1:** on the alternative family, the soft and stiff paths deviate from the alternative homogeneous path with the same sign, and with a magnitude stable within the preregistered tolerances (section 5).
- **H2:** `R_direct` and `R_path` keep their signs. Their deviations from 1 agree within the inherited M3 robustness rule.
- **Null / falsification:** a sign change in the lateral separation, or in `R_path − 1` or `R_direct − 1`, at s = 29.4 or 33.4 mm falsifies full-path robustness for that material. So does a failure of the STABLE separation criterion. Each failure is reported and not explained away.

## 2. M4.0 source lock and feasibility (done, mesh only)

Batch `run_g2_m4_feasibility_batch.m` ran at commit `b84dea3` and wrote `outputs/g2_m4_feasibility/run_20261121_172817_429`.

**Run 1** (`a06fc5b`) was a false HOLD. My ledger lookup compared a lower-cased ledger with a mixed-case path. No mesh was built. The fix is in commit `b84dea3`.

| Check | Result |
|---|---|
| F0: 34 source, policy and PR #41 chain files hashed; the six PR #41 ROOT/STATE records found in the M3 SHA ledger | PASS |
| F1: the exact WP2 famA call `g2_join_protected_mesh('ExteriorOptions',{BottomVertices,TopVertices,TipGuide 15/1.5})`, rebuilt in memory, reproduces the **saved** famA S0 arrays | **bitwise** |
| F2: the same routine with the S2alt exterior options (`GuideHface_mm` 1.0, `Hmax_mm` 5): join 13/13, independent 38/38, protected-tip 24/24, S0 adapter, phase map + verifier + state-aware negatives | **FEASIBLE** |

**Alternative S0 (F2):**
- 34,641 T3 against 28,151 for famA;
- 3 × 112 interface chords against 3 × 76;
- band polygon area +0.0692 % relative to famA;
- 1,555 of 16,262 exterior nodes coincide with famA nodes (fixed boundary vertices and the tip guide).

**Independence disclosure.** By policy, both families share the frozen p010 kernel (2,788 core T3), the analytic collar (128 T3), the 15-mm tip guide (Hface 1.5), the crack, the holes, the band radii and the BVP anchors. These elements carry the qualified q support and seams. Everything else is regenerated: the exterior, the band interface polygons and the plate.

M4.A therefore measures the sensitivity of the **full path** to exterior and band discretization, including the band polygon area. It does **not** measure near-tip discretization sensitivity. That would require a different p010 kernel, which is outside the qualified gates.

## 3. M4.A procedure

1. **S0ALT.** Build the alternative S0 once with the exact WP2 routine (`g2_m4a_s0alt`, token `G2M4AS0|<policy SHA>|family=famB_m4alt`).
   - Save the arrays.
   - Re-audit the **saved** arrays: join 13/13, 38/38, 24/24, adapter, phase stage.
   - Write `S0ALT.mat` with the mesh SHA and the phase labels.
2. **Three chains** (`g2_m4a_trajectory_run`, token `G2M4ARUN|<policy SHA>|<material>|family=famB_m4alt|maxState=2`) under `outputs/g2_m4_alt_family_v1/chain_<material>_alt_v1`. The materials are `homogeneous` (ratio 1), `soft` (0.5) and `stiff` (2).
3. **ROOT.**
   - Verify the S0ALT record and mesh. When the ROOT is created, re-run the audits and the phase re-map.
   - Solve the chain's **own** S0 on the alternative mesh. For the homogeneous chain this means H1 from `g2_t6_elasticity` + `g2_trajectory_sif_on_mesh`, the M0 identity (inherited `identityM0` tolerances), and Msoft and Mstiff on the same mesh. For soft and stiff it is `g2_material_sif_on_mesh`.
   - The parent K is that solve's full-precision `KI_perkN`, `KII_perkN`. No original-family K is used, and no K is rounded.
4. **Steps k = 1, 2.**
   - Advance one increment with the G2-M3 recurrence.
   - Check K1–K10.
   - Build the mesh with `g2_kinked_join` and the alternative exterior options.
   - Run the 34/34 audit on the saved arrays.
   - Build a new phase map with its verifier and negatives.
   - Solve again; for the homogeneous chain this is H1 + M0 + Msoft + Mstiff on Γ_H^a.
   - Write the records in order: PHASE_MAP, SOLUTION(s), REVIEW, STATE.
   - Reuse re-verifies everything without FEM.
5. **HOLD and scope.** Any gate failure writes HOLD and stops. A HOLD chain is never reused, and there are no automatic retries. There is no third step.

## 4. Observables (both families, equal arclength s = 25.4 / 29.4 / 33.4 mm)

- **Path quantities:** tip coordinates, global heading, and local MTS turn.
- **SIFs:** signed K_I and K_II from EDI 6×6 (five annuli), 4×4, COD and J.
- **Ratios:** G, `R_direct`, `R_path` and `R_total`. Each family uses only its own G values.
- **Original family:** recomputed from the PR #38 records and PR #41 chains exactly as in the M3 analysis. It must equal the M3 analysis ledger to 1e−12 relative; this is a regression check.
- **Identity checks:**
  - `R_total = R_direct · R_path` to 1e−12;
  - `R_path(25.4) = 1` exactly;
  - the soft and stiff S0 solves are bitwise equal to the homogeneous chain's S0 Msoft and Mstiff solves.
- **Cross-family drift:**
  - each path: `tip^a − tip^o`, its signed lateral component in the original H frame, the heading difference, and relative K and G changes;
  - reference drift `d_H = |tip_H^a − tip_H^o|`.
  - The original homogeneous S1 tip carries the 4.41e−6 mm A1 offset (six-digit seed); it is printed next to every original-H comparison.
- **Band polygon accounting:** chord counts and polygon areas for every mesh. Cross-family ratio changes are **not** attributed to FEM discretization alone. An indicative magnitude |R^o − 1|·|A^a/A^o − 1| is reported as a heuristic only.

## 5. Preregistered resolution and robustness criteria

**Within each family** (inherited, unchanged):
- primary ratio rule U = max(contour spread, 4×4, COD, U_mesh for cross-mesh ratios), resolved iff |R − 1| > 2U and the COD sign agrees;
- conservative rule R(δG_a + δG_b);
- path separation with U_sep(29.4) = 4 U_Δθ0 and U_sep(33.4) = 8 U_Δθ0 + 4 U_Δθ1, plus its conservative variant.
- U_mesh is the PR #38 value (|G_H1(S2alt)/G_H1(S2) − 1| ≈ 9.98e−6), not re-estimated.

**Lateral separation across families.** Let δ^f be the signed lateral offset of Γ_M^f from Γ_H^f, and Δ = δ^a − δ^o.

| Class | Conditions |
|---|---|
| STABLE | sign(δ^a) = sign(δ^o), **and** \|Δ\| ≤ 0.25\|δ^o\| (relative), **and** \|Δ\| ≤ 0.010 mm (absolute), **and** \|δ^a\| > 2·max(d_H, U_sep^a) |
| MARGINAL | same sign and \|δ^a\| > 2U_sep^a, but another STABLE condition fails |
| NONROBUST | sign change, or \|δ^a\| ≤ 2U_sep^a |

**Ratios across families** (inherited M3 rule) for `R_direct`, `R_path` and `R_total`:
- ROBUST: same sign of R − 1 and |R^a − R^o| ≤ 0.25|R^o − 1| + 2U_mesh;
- SENSITIVE: same sign, larger difference;
- NOT_ROBUST: sign change.

**Overall verdict:**
- **FULL_PATH_ROBUST**: all separations STABLE and all `R_path` and `R_direct` ROBUST at 29.4 and 33.4 mm;
- **PARTIAL**: signs all agree, but some MARGINAL or SENSITIVE;
- **NOT_ROBUST**: otherwise;
- **HOLD_FULL_PATH_ROBUSTNESS**: any chain fails a gate.

The conservative (≈ ±3.5 %) verdicts are reported for both families, and no claim rests on them.

## 6. Faults, restarts, replay

The fault list in the policy runs on disposable copies under `outputs/g2_m4_alt_family_v1/faults_run_*`:
- dry no-write;
- wrong tokens;
- location and name refusals;
- a forged S0ALT record carrying the famA mesh;
- a forged review re-pointed to the PR #41 mesh of the same material and step;
- a ROOT parent K replaced by the original-family K;
- inconsistent phase labels;
- policy and source drift;
- a step-3 request;
- a partial step;
- a HOLD chain;
- tampered state bytes;
- a dirty source;
- interrupts after review and after state;
- deterministic replay of one complete chain.

The accepted PR #41 chains and the new alternative chains are hashed before and after the suite.

## 7. Review stop and Word report

After M4.A, I deliver **one consolidated scientific review packet** and stop. M4.B does not start.

The canonical Ukrainian Word report v0.2/v0.3 is **not present locally**. Only v0.1 is present: SHA-256 `85ef072b…bc3`, verified both on the brief branch and in Downloads. This is logged as **HOLD_WORD_INPUT** for the canonical revision. The proposed Ukrainian additions are delivered as a separate native `.docx` proposal; the canonical file is not recreated.

## 8. Not claimed

The following are not claimed: physical crack onset, growth, arrest, toughness, debonding, CZM, interface penetration or deflection, experimental Cornell agreement, a third step, or any ring attribution. All moduli are illustrative and the bonding is perfect.
