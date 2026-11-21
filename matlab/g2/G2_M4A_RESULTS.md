# G2-M4.A results: independent full-path robustness on an alternative mesh family (Issue #44)

**Status:** numerical package complete, awaiting the researcher/ChatGPT scientific review (REVIEW_STOP_A). **G2-M4.B was not started.**

- **Preregistration:** `G2_M4_PREREGISTRATION.md`, `G2_M4_POLICY_v1.json` (SHA-256 `2548f373…9618e`).
- **Run log:** `G2_M4_RUNLOG.md`.
- **Evidence:** `evidence/m4_20261121/`.
- **Ukrainian Word proposal:** `reports/G2/proposals/Metakompozyt_G2_M4A_proponovani_dopovnennia_UA.docx`.

All values are numerical paths conditional on assumed 4-mm advance, under the idealized 1 N BVP. The moduli are illustrative and the bonding is perfect. No onset, arrest, toughness, debonding or CZM is claimed.

## What was independent and what was not

**Regenerated in the alternative family (famB_m4alt):**
- the S0 mesh: the exact WP2 routine with `GuideHface 1.0`, `Hmax 5`;
- every step mesh: 34,879–35,121 T3;
- the band interfaces: 3×112 chords against 3×76;
- every phase map;
- every two-phase solve;
- the parent K at S0, from the chain's own full-precision K.

**Shared by policy:** the frozen p010 core (2,788 T3), the collar (128 T3), the 15-mm tip guide, the q support (2,443 elements), the physical geometry and the BVP.

The test therefore covers exterior and band discretization, including the band polygon area. It does **not** cover near-tip discretization.

## Results (s = 33.4 mm; full tables in `evidence/m4_20261121/analysis/`)

| | Original (76) | Alternative (112) | Class |
|---|---|---|---|
| soft R_direct / R_path / R_total | 1.021813 / 0.998826 / 1.020614 | 1.021828 / 0.998826 / 1.020628 | ROBUST / ROBUST / ROBUST |
| stiff R_direct / R_path / R_total | 0.970687 / 1.000813 / 0.971476 | 0.970667 / 1.000813 / 0.971457 | ROBUST / ROBUST / ROBUST |
| soft lateral offset δ (mm) | +0.090500 | +0.090536 | STABLE (Δ +3.5e−5, 0.04 %) |
| stiff lateral offset δ (mm) | −0.060224 | −0.060227 | STABLE (Δ −3.4e−6, 0.006 %) |

At s = 29.4 mm all classes are also STABLE or ROBUST. **Preregistered verdict: FULL_PATH_ROBUST.**

**Cross-family drift:**
- tip drift 1.2e−4 mm for the homogeneous path, 1.55e−4 for soft and 1.17e−4 for stiff;
- K_I changes ≤ 1.2e−5 relative; K_II changes ≤ 3.8e−4 relative;
- the step-1 turn shifts by ≈ +0.001° for all three paths, because the S0 K_II is 7.6e−5 lower.

**Band polygon area and R_direct.**
- The 112-gon band is 0.0692 % larger than the 76-gon.
- The cross-family change in R_direct is 0.07–0.10 % of the effect |R − 1|, in the direction of more active area.
- The area-proportional estimate |R − 1|·ΔA/A is 1.51e−5 (soft) and 2.03e−5 (stiff). The observed changes are +1.47e−5 and −2.00e−5.

This is consistent with a geometric origin, but it is only a heuristic. Area and discretization change together, and this package does not separate them.

**Uncertainty.**
- **Primary rule:** every R_direct and R_total is resolved in both families, and R_path is resolved at 29.4 and 33.4 mm.
- **Conservative rule (≈ ±3.5 %):** no ratio is resolved in either family. The lateral offsets **are** resolved under the conservative rule (e.g. soft 0.0905 > 2 × 0.018 mm).

**Identity and controls.**
- The M0 identity is bitwise at all three alternative states.
- The soft and stiff S0 solves are bitwise equal to the homogeneous chain's Msoft and Mstiff S0 solves.
- R_total = R_direct·R_path holds to ≤ 1e−12.
- The original family recomputed from PR #38 and PR #41 equals the M3 analysis ledger exactly (maximum deviation 0).
- Faults: 24/24, including a forged S0ALT carrying the famA mesh, a review forged with the PR #41 mesh, a ROOT seeded with the original K, and a bit-identical replay of the homogeneous chain (4 solves per state).

## Limitations

- The near-tip core is shared.
- One alternative family.
- Two steps.
- The band-area effect is not separated from discretization.
- The canonical Word v0.2/v0.3 is absent: HOLD_WORD_INPUT, so a separate DOCX proposal was produced.
