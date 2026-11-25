# Erratum — signed circle term in the forced-pair diagnostic (appended; historical evidence unchanged)

**Affected record:** `LP2A2_SUPPLEMENT.json` (SHA-256 unchanged), produced at `7481509` by `g2_lp2a2_forced_pair_audit` as it stood at `8374b10`. Per review https://github.com/mfs9697/NewMetacomp/pull/71#pullrequestreview-6058599118, item 1.

**Error.** The field `predictedDx_mm` was computed as `+2·w·b/√(R²−b²)`. The crossings lie behind the tip, where x = a − √(R² − (η−b)²). The correct signed first-order prediction of the circle part Δx = x_U − x_L is therefore

  Δx ≈ **−2·w·b/√(R² − b²)**.

The stored field has the opposite sign. Its magnitude agrees with the measured circle part to within 1.7·10⁻⁹ mm over all 113 forced pairs (`LP2A2_RECONCILIATION.json`: `maxAbsPredictedMinusAbsCircleDx_mm`).

**Corrected implementation.** `g2_lp2a2_forced_pair_audit` at `52d94ef` and later: `predictedDx_mm = -2*w*b/sqrt(Rg^2-b^2)` and corrected documentation. The supplement was not re-run, and its stored values (`circleDx_mm`, `stationMismatch_mm`, `parametrisationPart_mm`, all residuals) are not affected. Only the sign of the diagnostic prediction field is wrong.

**What the forced-pair evidence does and does not show:**

| Quantity | Meaning | Value (113 pairs) |
|---|---|---|
| Station mismatch **before** collapse, \|Δs\| = \|s_U − s_L\| | different centre-line stations of the two analytic guide-circle crossings (circle part + mitred-offset parametrisation part) | ≤ 2.28·10⁻³ mm |
| Native coordinate distance before collapse | the two banks are 2w apart | ≤ 0.04005 mm |
| Coordinate residual **after** collapse | both nodes are moved to the same point on the centre line at the mean station | 0 |
| Neighbouring T6 midside pairs after collapse | | residual 0 |
| Node identities / DOFs | | distinct in every pair |

A non-zero station residual before collapse coexists with a zero coordinate residual after collapse; the pair is not "exact" before collapse.

**Scope of the claim.** The pairing audits establish geometric pairing on the meshes actually generated and audited (113 + the independent set). They do **not** give a universal guarantee that every future polyline will pair: the generator is checked per mesh and refuses (`HOLD_LIP_SEED_NOT_HONOURED`, P1–P10) otherwise. Passing the geometric audits also does not make a mesh physically eligible. Physical use additionally requires:
- SIF equivalence (WP5, rung 1 only);
- a separate authorization;
- the restricted regime.

The previously accepted results are unchanged.
