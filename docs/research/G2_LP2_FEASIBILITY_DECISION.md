# G2-LP2 — feasibility decision brief (prospective; nothing here is authorized)

[Issue #56](https://github.com/mfs9697/NewMetacomp/issues/56), work package SR1-D. Every number in this brief comes from **existing geometry, policy v2 and the 20 saved LP1 states**. There is **no new K, MTS angle, mesh or FEM**, and this brief is not a runnable prompt.

All quantities come from `G2_LP1_SR1_independent_check/SR1_CHECK_RESULTS.json` (`feasibility` block) and `SR1_feasibility_constant_turn.csv`.

## 1. Research question and two meanings of "termination"

The research question is: **under what configurations can the crack traverse the matrix without encountering an interface?** Answering it requires keeping two kinds of termination separate.

- **Numerical termination (model scope).** The current toolchain must stop because a qualified numerical device no longer fits. These devices are the 15-mm protected tip guide, the q support, segment clearance, the kink limit, mesh quality, the T3 budget and the plate margins. A numerical HOLD says nothing about the physical crack.
- **Physical event (nominal geometry).** Either the conditional path meets a nominal ring interface (r = 19.05 mm), a hole, or the free top edge (y = 203.2 mm). Even such an event is *geometric*: without toughness, interface properties or loading-system compliance there is no onset, arrest, penetration, debonding or stability statement.

## 2. Geometry that controls feasibility (derived from policy v2)

| Quantity | Value | Source |
|---|---|---|
| Ring centres; outer radius; hole radius | (152.4; 69.85 / 120.65 / 171.45) mm; 19.05 mm; 6.35 mm | policy v2 |
| Gap between rings; ring 3 to top edge | 12.7 mm; 12.7 mm | derived |
| Tip-guide exclusion around each centre (19.05 + 15) | **34.05 mm** | `tipGuideRadius_mm` |
| q exclusion (19.05 + 2.6 + 1) | 22.65 mm | `qAnnuli_mm`, `minQClearance_mm` |
| Segment exclusion (19.05 + 1.52) | 20.57 mm | `minSegmentRingClearance_mm` |
| Admissible tip box | 15 < x < 493 mm, 15 < y < **188.2** mm | guide vs. plate |
| Guide envelope of ring 3 reaches | y = 205.5 mm (> 188.2) | derived |
| Envelope waist half-width between rings | 22.68 mm | derived |
| Leftmost point of the guide envelope | x = 118.35 mm | derived |

**Consequence 1.** The three 34.05-mm discs overlap, because 50.8 < 2 × 34.05. Together with the top band y ≥ 188.2 they form **one connected forbidden column** from y = 35.8 mm to the top boundary. The admissible region is split into a left part, which contains the crack, and a right part. The inter-ring gaps (12.7 mm) and the ring-3/top gap (12.7 mm) are narrower than the 30-mm guide diameter, so with the current guide **a tip can never pass between rings or above ring 3**.

**Consequence 2.** The current toolchain **cannot reach the physical upper edge**: every tip must satisfy y < 188.2 mm, which leaves at least 15 mm of ligament unmodelled. Whether a *physical* crack reaches the edge is a different question: it is not decidable from LP1 and would need a qualified near-edge model (option C).

## 3. Where the four S4 paths point (geometry only)

All 16 recorded local MTS angles at S1–S4 are negative, between −0.91° and −1.88°. Negative means a clockwise turn, toward +x and the ring column. The table extends the **S4 tangent as a straight line**. This is a geometric construction, not a forecast.

| Path | S4 heading (deg) | Tangent line: clearance to ring 1 / 2 / 3 interface (mm) | First numerical HOLD on the tangent line | First nominal event on the tangent line |
|---|---:|---|---|---|
| H | 72.887 | 17.11 / **2.16** / −12.79 | ring-2 guide envelope at s ≈ 104.8 mm | ring 3 interface at s ≈ 162.0 mm |
| stiff13 | 72.226 | 16.43 / **0.93** / −14.58 | s ≈ 104.1 mm | s ≈ 161.5 mm |
| soft2 | 72.520 | 16.75 / **1.50** / −13.76 | s ≈ 104.4 mm | s ≈ 161.7 mm |
| soft1 | 73.956 | 18.18 / **4.14** / −9.90 | s ≈ 106.1 mm | s ≈ 163.1 mm |

The minimum straight heading from the S4 tip that reaches the respective target without an event is:

| Path | Reach the top guide line y = 188.2 without entering any 34.05-mm envelope | Reach the top edge without touching a nominal interface |
|---|---:|---:|
| H | ≥ 84.6° (+11.7° vs. S4) | ≥ 78.2° (+5.3°) |
| stiff13 | ≥ 84.6° (+12.4°) | ≥ 78.3° (+6.1°) |
| soft2 | ≥ 84.6° (+12.1°) | ≥ 78.3° (+5.8°) |
| soft1 | ≥ 84.4° (+10.4°) | ≥ 78.1° (+4.1°) |

**A family of constant per-step turns from the H S4 tip** (4-mm steps, a hypothetical construction):

| Turn per step | Numerical event (current devices) | Nominal physical event |
|---:|---|---|
| −3° … −1° | guide envelope after 7–9 steps (s ≈ 69–77 mm) | nominal interface after 13–20 steps (s ≈ 93–121 mm) |
| −0.5° | guide envelope, 11 steps (s ≈ 85 mm) | interface, 20 steps |
| 0° | guide envelope, 16 steps (s ≈ 105 mm) | interface, 31 steps (s ≈ 165 mm) |
| +0.5° | guide envelope, 18 steps (s ≈ 113 mm) | top edge, 42 steps (s ≈ 209 mm) |
| +1.0° / +1.5° | top guide limit y = 188.2 at 38 / 40 steps (s ≈ 193 / 201 mm) | top edge (s ≈ 209 / 225 mm) |
| ≥ +2° | the path curls back to the left plate guide | — |

**Interpretation, labelled as hypothesis.** A matrix-only traversal toward the top edge would require the conditional path to *reverse* its observed turning sense: a sustained anticlockwise turn of at least about +0.5° to +1° per 4 mm, or a heading increase of 4–12° relative to S4. Ring architecture changes the S4 heading by only −0.66°, −0.37° and +1.07° (stiff13, soft2, soft1). Within the tested contrasts (E_r/E_m = 0.5 or 2, one or two rings), the architecture is therefore **unlikely by itself** to switch the conditional path from "meets the ring column" to "traverses the matrix". The class is set mainly by the global geometry: crack offset x₀ = 101.6 mm, hole-column position, load span.

This is not a prediction. Local MTS angles can change sign as the tip approaches the free hole surfaces or the rings. The counter-steering seen in stiff13 and soft1 (D6 in the ledger) shows that later turning is not constant. Configurations that do traverse the matrix would require a new, preregistered *geometry* study (crack offset or hole-column position), which is outside the present authorization.

## 4. Constraints that bind a long path with the current toolchain

| Constraint | Status in LP1 | Relevance to LP2 |
|---|---|---|
| 15-mm tip guide (34.05 mm to the ring centre) | minimum margin 20.82 mm at S4 | **binding first** for any path toward the column; terminal code `HOLD_TIP_GUIDE` about 15 mm before the interface |
| q support, 2.6 mm + 1-mm buffer | margin ≥ 32.2 mm | never binding before the guide |
| Segment clearance 1.52 mm | > 35 mm | only binding if the guide is reduced |
| Non-adjacent crack clearance 0.16 mm; collar rim | 4 mm; rim margin > 4 mm | binding only for strongly curling paths |
| Kink limit (miter denominator ≤ 1.8 ⇔ turn > 36.87°), coded as `HOLD_CRACK_SELF_INTERSECTION` | maximum turn 13.26° (stiff13 S0) | possible near free surfaces; the label is misleading (proposal P3) |
| Mesh quality (≥ 20°, ratio ≤ 1.8) | minimum angle 30.13°; worst ratio **1.7295** (H S3) | a non-trivial risk over 15–40 further remeshes; monitor per state |
| T3 budget 40,000 | 29,005–29,063 at S4; growth 187–212 T3 per step | about 52–59 further steps available. Reaching y = 188.2 needs about 37 steps (s ≥ 188.7 mm), so the budget is **not binding** for option A. |
| Top guide limit y < 188.2 | 147 mm away | hard numerical end, 15 mm before the free edge |
| Fixed 4-mm step (`adaptiveStep=false`); last segment ≥ 3.3 mm | as preregistered | no approach closer than one step plus the guide; B and C need a new adaptive-step policy |
| Point-load compliance sensitivity | 11/12 smooth steps agree with EDI G within 1 % | not a convergence measure (R1 REV-002) |
| Memory guard ≥ 5 GiB, one engine | prephysical batch HOLD_MEMORY at 4.958 GiB | an operational risk to schedule around; never lowered |

## 5. Three prospective terminal problems (none authorized)

### LP2-A — matrix-confined path to the first justified numerical HOLD

- **Objective.** Continue the four own paths with the *unchanged* LP1 devices, beyond S4, until the first preregistered HOLD. This establishes the real conditional curvature trend and whether paths head into the column (expected code `HOLD_TIP_GUIDE`) or toward the top guide limit.
- **New capability needed.** None. A new policy (v3) with a raised state cap is needed (e.g. ≤ 25 states or s ≤ 141.4 mm), together with the per-step gates unchanged and a genuine SHA-bound GO.
- **Prospective gates.**
  1. Complete the current prephysical batch (four dry cases plus the no-GO probe).
  2. *A0:* prospectively reproduce LP1 S0–S4 under the current guarded controller. The expectation is identity to the archived numbers within the pinned H tolerances, because the physics modules are unchanged.
  3. *A1:* run a preregistered refinement study (p010 core and exterior) at S2 and S4 for H and soft2, to replace estimator agreement by a discretization estimate.
  4. *A2:* extend with per-step monitoring of the mesh-quality margin. The HOLD semantics stay numerical.
- **Expected terminal.** If the observed turning sense persists, `HOLD_TIP_GUIDE` at the ring-2 envelope at s ≈ 70–115 mm. Otherwise, the top guide limit.
- **Compute.** About 27 s per state (LP1: 20 states in 9 min 5 s).

### LP2-B — interface interception, stop before penetration

- **Objective.** Bring the conditional tip to a preregistered distance d_stop from a ring interface (for example a few q radii) and record K_I, K_II, G and θ during the approach. It does **not** predict penetration, deflection along the interface, or debonding.
- **New qualification needed.**
  1. A tip guide radius that adapts to the interface distance, with independent mesh qualification where the guide and interface chords coexist.
  2. q domains confined to the matrix (q_out + buffer < d), with homogeneous-J validity checks.
  3. Near-interface K benchmarks: a crack approaching a circular inclusion or bimaterial interface, against literature solutions selected and verified before use, plus a refinement study.
  4. An adaptive step (step ≤ α·d) with a preregistered α.
  5. A new stop code such as `HOLD_INTERFACE_PROXIMITY_REACHED`, explicitly *not* arrest.
- **Decision gate.** Open B only if A ends at a guide HOLD near a ring.

### LP2-C — separately developed near-free-edge termination

- **Objective.** Model the last ≥ 15 mm to the top edge in order to establish *geometric* sectioning of the conditional path.
- **New qualification needed.**
  1. Reduced or truncated tip guide and q domains near a straight free edge.
  2. Short-ligament K benchmarks, for example deep-crack bend or strip solutions from handbooks, selected before use.
  3. A watch for K_I → 0 and crack-face contact: the top fibres are in bending compression, and the existing `KIpositive` and `minWholeCrackNormalOpening` gates would then stop the run. A contact-aware model would be a separate development.
  4. A preregistered ligament-based termination criterion.
- **Limits.** "Full sectioning" in a physical sense still needs a toughness and stability analysis (load versus displacement control), which is outside the scope. Open C only if A reaches the top guide limit.

## 6. Recommendation (for the scientist's decision)

1. **Do not start LP2 propagation yet.** First close the open qualification items: the prephysical batch (C1), the prospective A0 reproduction under a genuine GO (C3), and the A1 refinement study. These are inexpensive and resolve the two open questions of SR1: authorization-process compliance and the soft2 conservative ambiguity.
2. If A0 and A1 pass, **LP2-A** is the scientifically informative next stage. It answers whether the conditional paths turn into the ring column, using qualified devices only.
3. Develop **B** or **C** as separate, prospectively qualified mesher and fracture-model issues, chosen by A's terminal.
4. The question "under what configurations does the crack traverse without an interface?" is, on present evidence, controlled by global geometry more than by ring contrast. A parametric study of crack offset or hole-column position would be a separate, new research design.

`REVIEW_STOP_SR1`. No adaptive-step policy, geometry threshold, crossing capability or LP2 prompt is authorized or provided here.
