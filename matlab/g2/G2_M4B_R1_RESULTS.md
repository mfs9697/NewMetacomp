# G2-M4.B-R1 results: ring placement on the matched frozen S2alt (Issue #50)

**Status:** focused package complete. **REVIEW_STOP_R1**; nothing below is self-approved.

- **Policy:** `G2_M4B_R1_POLICY_v1.json` (SHA-256 `51578049…`), with `G2_M4B_R1_PREREGISTRATION.md`, committed before any R1 solve.
- **Records:** run log `G2_M4B_R1_RUNLOG.md`; evidence `evidence/m4b_r1_20261121/`.

**What this tests.** The same frozen S2 crack is used, with an independently regenerated exterior and 112-chord ring polygons (+0.0692 % ring area).
- It is **not** element-size convergence.
- It is **not** near-tip sensitivity: the p010 core, collar and q support are shared.

Everything is a direct linear-elastic effect at fixed geometry, with P = 1 N and illustrative moduli. There are no trajectories, no interaction re-test, and no claim of onset or arrest.

## 1. Matched geometry and gates

| Item | Result |
|---|---|
| S2alt mesh | PR #38 run D, `0627dd3a…3080`, 35,125 T3, 71,207 nodes, 3×112 chords |
| Match with original S2 | crack polyline, tip tangent and tip coordinates **bitwise equal**; core/collar/q 2788/128/2443 equal; no HOLD_MATCHED_S2ALT |
| B0 / B1 | PASS: audit 34/34; legacy phase map = saved PHASE_MAP_S2alt; legacy verifier + 8 negatives; oracle = annulusOf; 10/10 activations; 10/10 mutations rejected |
| B2 anchors | `none`, soft {1,2,3} and stiff {1,2,3} **bitwise equal** to the accepted M2 S2alt records; legacy routine PASS and equal |
| B3 targets | 7/7 pass every inherited SIF gate and partial-activation gate |
| Faults | **43/43** |

**What the matched-geometry rule rejected:**
- the M4.A alternative S2 (fails on polyline, tangent and tip);
- a 1e−12 mm polyline perturbation;
- a one-ulp tangent perturbation.

## 2. Cross-family comparison (preregistered classes, threshold 0.10 relative)

| Target | F_G orig → S2alt | Class | F_θ orig → S2alt (°) | Class |
|---|---|---|---|---|
| soft {1} | +4.4298 → +4.4328 % | STABLE | +1.31063 → +1.31120 | STABLE |
| soft {2} | −3.6278 → −3.6300 % | STABLE | −0.37144 → −0.37167 | STABLE |
| soft {3} | +2.3310 → +2.3327 % | STABLE | −0.35338 → −0.35362 | STABLE |
| stiff {1} | −3.6517 → −3.6538 % | STABLE | −1.11001 → −1.11037 | STABLE |
| stiff {2} | +3.0352 → +3.0367 % | STABLE | +0.30612 → +0.30627 | STABLE |
| stiff {3} | −1.8248 → −1.8258 % | STABLE | +0.28832 → +0.28849 | STABLE |
| **stiff {1,3}** | **−5.4780 → −5.4810 %** | **STABLE** | −0.80591 → −0.80608 | STABLE |
| anchor soft {1,2,3} | +2.1813 → +2.1828 % | STABLE | +0.69431 → +0.69450 | STABLE |
| anchor stiff {1,2,3} | −2.9313 → −2.9333 % | STABLE | −0.45161 → −0.45161 | STABLE |

**Drift size.** Relative cross-family drift is at most 0.08 % of each effect. It equals at most 0.0014 (F_G) and 0.040 (F_θ) of the conservative uncertainty.

**Rankings (equal active area):**
- soft: f_1 > f_3 > f_2 in both families (F_G and F_θ);
- stiff: f_2 > f_3 > f_1.

All four rankings are RANKING_STABLE, and all twelve equal-area differences d_ij are STABLE.

**Stiff {1,3}:**
- It has the lowest F_G among the stiff cases evaluated on S2alt; this is **unequal-area context only**.
- No other two-ring set was computed on S2alt, so no equal-area two-ring statement is made.

**Verdict (preregistered): R1_PLACEMENT_STABLE** (12/12 single-ring classes STABLE, 4/4 rankings stable).

## 3. Three questions, side by side (see figure g2)

1. **Primary U** (estimator agreement on one mesh): about 1e−6 for F_G and about 2e−3° for F_θ.
2. **Conservative U:** about 3.4–3.7 % (F_G) and 0.02–0.03° (F_θ).
3. **Cross-family drift:** about 1–3e−5 (F_G) and 2–8e−4° (F_θ).

**For F_G, the drift exceeds the primary U by roughly 10–100×.**
- The primary rule therefore does **not** bound mesh-family effects on G.
- Both quantities remain 3 orders of magnitude below |F_G|.

**For F_θ, the drift is below the primary U.**

## 4. Other observations (not mechanisms)

- **Point-load compliance.** Homogeneous compliance differs by about 2 % between families (2.2180e−4 vs 2.2617e−4 mm/N) in every case. That is expected from the mesh-dependent displacement under a 2D point load. K and G agree to about 1e−5, and within-family compliance ratios are unaffected.
- **K_II.** The cross-family K_II drift is at most 0.23 % (soft {1}, where K_II is smallest). K_I drift is at most 2e−5.
- **Equivalent-stress maps** (S2alt, figure g4):
  - an active soft ring lowers σ_eq inside itself by about 29 % (median);
  - stiff rings {1,3} raise it by 26 % and 22 %;
  - the median change in the matrix stays within 0.5 %;
  - the field change extends over the loaded ligament.

  This describes the fields only; no mechanism is separated.

## 5. Limitations

- The near-tip core is shared, so R1 tests exterior and ring-polygon family sensitivity only.
- There is one alternative family.
- The interactions I_ij and I_123 and the other two-ring sets were not re-tested.
- The conservative rule still leaves f_3 (both contrasts) and stiff f_2 unresolved for G, in both families.

## 6. Greyscale figures and Word

**Figures:** 8 greyscale PNGs with CSV data and `FIGURE_NOTES.json` (sources, scales, global/local limits, readability aids) in `evidence/m4b_r1_20261121/report/`.

**Word proposal package:** `reports/G2/proposals/Metakompozyt_G2_M4B_R1_proponovani_dopovnennia_UA.docx`. It contains:
- the R1 section;
- the greyscale figures with captions;
- the figure note;
- the G2-REV-M4B review decisions as insertion-ready text for the next consolidated edition.

The v0.4 candidate and v0.3 are not modified.
