# G2-M2 shielding and steering along three frozen crack states: preregistration (Issue #36)

**Status:** committed before any new two-phase solve. The machine-readable contract is `G2_M2_POLICY_v1.json` (same commit). PR #35 (`75a4bce`), its policy, its modules and its accepted outputs are unchanged and are reused.

## 1. Question

Bonded bands (6.35 < r < 19.05 mm) of E_r/E_m = 0.5 or 2 surround the three holes. How does their direct effect on the tip driving force, and on the local MTS direction, depend on the position of a fixed homogeneous-reference crack?

The three crack positions are s = 25.4 mm (S0), 29.4 mm (S1) and 33.4 mm (S2).

Each state is a separate **same-mesh** comparison: H1, M0 (ratio 1), Msoft (0.5) and Mstiff (2), all on that state's saved mesh with the same 1 N BVP. This is **not** a simulation of a crack growing through a metacomposite. The crack shapes are homogeneous-reference shapes, and nothing is propagated. It is also not the G2 hole-versus-no-hole `R_direct·R_path` decomposition.

## 2. Source audit (read-only, done before this document)

| State | Mesh (under `outputs/`) | SHA-256 | Ledger | Fields |
|---|---|---|---|---|
| S0 | `g2_protected_mesh/run_20261118_165922_343_famA/GEOMETRY_ONLY_candidate.mat` | `05d5c3fc…657dc` (the issue text drops the final `dc`; the ledger value is used) | wp2 ledger, line 11 | X3/T3/X6/T6, `upperBankT6`/`lowerBankT6` (151 each, tip shared), `physicalTipNode`, `extraVertexNodes` (pin, roller, load), `nodalQ`, `qActiveT6Rows` (2443); **no** `crackPolyline` or `tipTangent` |
| S1 | `g2_wp3_state/run_20261118_185808_963/step1_a/KINKED_GEOMETRY_ONLY_candidate.mat` | `ecd6a7b8…32461` | wp3 ledger, line 55 | full kinked schema, banks 169 |
| S2 | `g2_trajectory_chain_v1_attempt2/STEP_002/KINKED_GEOMETRY_ONLY_candidate.mat` | `9269be43…5c412` | wp34 ledger, line 10 | full kinked schema, banks 185 |

**S0 copy.** The S0 mesh and the WP2 record `familyA_primary_fields.mat` (`cc183126…f577`) live in the WP2 worktree. They were byte-copied into this worktree's `outputs/`, and both match the committed wp2 ledger.

**Interfaces.** Read-only inspection (`evidence/m2_20261121/preaudit/M2_inspect.log`) shows the same picture in all three meshes:
- each circle r = 19.05 mm carries **76 T3 vertices** (within 2.1e−14 mm), and the next vertex is 1.30–1.31 mm off;
- every hole rim has 152 vertices;
- S0 has 150 coincident crack-line pairs plus the single tip node.

**Schema adapter (S0 only).** It sets `crackPolyline = [101.6 0; X3(physicalTipNode)]` and `tipTangent = (0, 1)`, and leaves everything else as saved. It is tested in three ways:
1. the tip equals (101.6, 25.4), and the banks lie on the polyline, coincide in pairs and share only the tip;
2. the upper bank belongs to elements on the +n = (−1, 0) side, which is the WP2 convention;
3. bank COD (`g2_sif_cod_banks`) equals the WP2 geometric COD (`g2_sif_cod`) on the same displacement field to 1e−10.

S1 and S2 need no adapter.

**Robustness mesh, geometry-only feasibility (disclosed; no FEM, nothing saved).** The candidate is GuideHface 1.0 with Hmax 5: 35,125 T3, kink audit 34/34, min angle 30.127°, max ratio 1.592, and **112** chords per circle. It is preregistered as `S2alt` (§5).

## 3. Per-state procedure (S0, then S1, then S2)

1. **Source.**
   - Hashes are checked against the ledgers.
   - Records: the S1 State record `cb05bd61…`; the S2 ROOT, REVIEW and State records.
   - The tree must be clean and committed.
2. **Original auditor**, unchanged:
   - S0: `g2_independent_t6_checker` 38/38 plus `g2_protected_tip_checker` 24/24;
   - S1 and S2: `g2_kinked_mesh_auditor` 34/34, with 3 and 4 vertices respectively.
3. **Adapter** (S0) and its tests.
4. **Phase map and checks.** The PR #35 mapper, the separate verifier and the 8 negatives, with the same tolerances. Also recorded: chord counts, band areas, volume fraction, tip-to-band distance and q clearance.
5. **Regressions.**
   - S0: the WP2 computation reproduces `familyA_primary_fields` to 1e−12.
   - S1 and S2: `g2_trajectory_sif_on_mesh` reproduces the State 1 record and the S2 REVIEW to 1e−12.
6. **Identity.** H1 (`g2_t6_elasticity` + `g2_trajectory_sif_on_mesh`) against M0 (the phase pipeline at ratio 1), with the PR #35 identity limits.
7. **Contrast.** Msoft and Mstiff with every PR #35 SIF, q-phase, energy and interface gate.
8. **S2 only.** The four case arrays and the ratio table must equal PR #35 run C exactly.

**Benchmark pin.** The coated-hole benchmark is **not rerun**, provided every PR #35 qualified module is byte-identical to `75a4bce` (git blob check) and the run C `BENCHMARK.mat` hash matches. Any difference forces a rerun.

## 4. Quantities (per state and case)

| Quantity | Definition |
|---|---|
| Signed K | K_I, K_II in raw MPa√mm (EDI and COD), per kN = raw·√1000 |
| G at 1 N | (K_raw,I² + K_raw,II²)/E_m in N/mm (×1000 for J/m²) |
| R_mat(s) | G_M/G_H1 on the same mesh; δR = R − 1 |
| Mixity | ψ = atan2(K_II, K_I) |
| θ_MTS(s) | In the **state's own last-segment frame**, with Δθ = θ_M − θ_H1. The global terminal tangent angle is listed separately, and angles from different states are never compared in a common frame. |
| Compliance and CMOD | C = \|u_y(load)\|/P; CMOD = normal opening of the mouth twin pair at s = 0 |
| G_H1(s) | Reported separately; its change between states is a geometry effect, not a material one |

**Uncertainty.** Both PR #35 rules are applied unchanged and both verdicts are reported:
- **Primary:** U_R = max(contour spread, 4×4, COD); resolved iff |δR| > 2·U_R and the COD sign agrees.
- **Conservative:** R·(δG_M + δG_H1).
- **K_II sign:** resolved component-wise.
- **Δθ:** resolved iff |Δθ| > 2·max(COD, 4×4, contour spread of Δθ).
- **MTS root check:** the MTS root is checked by bracketed `fzero` to 1e−10 rad.

## 5. Targeted ratio-robustness check (S2 only)

`S2alt` is built by `g2_kinked_join` with the S2 polyline and the original exterior options, plus `GuideHface_mm 1.0` and `Hmax_mm 5`. The crack, kernel, collar, rim, hole edges and tip guide are unchanged; the band interface becomes a finer 112-gon and the exterior is finer.

**Gates:** join pass; independent 34/34; T3 ≤ 40,000; 20° / 1.8; full phase checks; identity; all SIF gates.

**One attempt only, with no tuning afterwards.** For each contrast:
- **ROBUST:** same sign, and |δR_alt − δR_orig| ≤ 0.10·|δR_orig|;
- **SENSITIVE:** same sign, larger difference;
- **NOT ROBUST:** opposite sign;
- **HOLD:** any gate fails, in which case there is no refinement-qualified statement.

Band-area differences between the 76-gon and the 112-gon are reported. No second mesh is made for S0 or S1 without a prospective amendment.

## 6. Cross-state comparability and interpretation rules

- **Geometry-equivalent** iff the chord counts are equal and each band polygon area is within 1e−4 relative of S2. Otherwise the cross-state trend is labelled **geometry-confounded**.
- **No PASS criterion on any trend.** Persistence, growth, decay or sign change is described, not required.
- **Transition.** A "shielding-to-amplification transition" is named only if δR changes sign between states with both signs resolved under the primary rule. The conservative verdict is shown next to it.
- **Wording.** No arrest, onset, toughness or durability language. Δθ is a frozen-tip forecast. A small K_II percentage change is not called directional control unless Δθ is resolved.

## 7. Stop rules

- Any SOURCE, AUDIT, ADAPTER, PHASE, BENCHMARK_PIN, REGRESSION, IDENTITY, SIF, QPHASE, INTERFACE or RAM failure in a state is a HOLD.
- A HOLD stops that state and every later stage. Earlier PASS states are kept, and failed evidence is preserved.
- No retry without a committed investigation, and no tolerance change.
- Outputs go to a new `outputs/g2_material_evolution_v1/run_<time>/`, with a SHA-256 ledger.
