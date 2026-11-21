# G2-M2 bonded-band shielding and steering along three frozen crack states: results (Issue #36)

**Verdict: GO.** All three frozen states S0, S1 and S2, plus the alternative S2 mesh, passed every preregistered gate.

All numbers come from genuine MATLAB R2023a runs:
- Accepted run D: `outputs/g2_material_evolution_v1/run_20261121_132226_301` at HEAD `9be3a05`.
- Run E is a bit-identical replay at `48c8864`.

Preregistration (`569db12`) and policy `G2_M2_POLICY_v1.json` (SHA-256 `1782EEBC…D834C`) were committed before any new solve.

**What this is.** Each state is a separate same-mesh comparison on an existing homogeneous-reference crack shape, under the idealized 1 N BVP with illustrative moduli. It measures the direct phase effect and a local direction forecast.

**What it is not.** It is not a crack growing through a metacomposite, not the G2 hole-versus-no-hole decomposition, and not a statement about onset, arrest, toughness or durability.

## 1. Stages

| Stage | S0 (s = 25.4 mm) | S1 (29.4 mm) | S2 (33.4 mm) | S2alt (33.4 mm) |
|---|---|---|---|---|
| Source + ledger | PASS (WP2 ledger; issue hash lacks its final `dc`) | PASS (State 1 record `cb05bd61…`) | PASS (ROOT, REVIEW, State) | built in run, hash `0627dd3a…` |
| Original auditor | 38/38 + 24/24 | 34/34 | 34/34 | 34/34; 35,125 T3, min angle 30.127°, ratio 1.592 |
| Adapter | 7/7 (adds polyline and tangent) | 7/7 (none needed) | 7/7 | 7/7 |
| Phase map / verifier / negatives | PASS / PASS / 9 of 9 | PASS / PASS / 9 of 9 | PASS / PASS / 9 of 9 | PASS / PASS / 9 of 9 |
| Homogeneous regression | WP2 EDI, J, COD: 0 difference; adapter bank COD = WP2 geometric COD exactly | State 1 record: 0 difference | REVIEW: 0 difference | (no record) gates PASS |
| H1 = M0 identity | bitwise | bitwise | bitwise | bitwise |
| Msoft / Mstiff gates | PASS / PASS | PASS / PASS | PASS / PASS | PASS / PASS |
| Equals PR #35 run C | — | — | arrays and ratio table exactly | — |

**Global stage.** The 22 PR #35 qualified modules are byte-identical to `75a4bce`, and the PR #35 benchmark record `8419ed11…` is pinned. Under the preregistered rule, the coated-hole benchmark was therefore not rerun.

**Failed runs (preserved, `G2_M2_RUNLOG.md`).** None of them produced a contrast result that was used.
- **Run A:** the PR #35 q-crossing control has a fixed 45 mm radius, chosen at S2, and that radius does not reach a band at S0. I added a state-aware wrapper; the PR #35 module itself was not changed.
- **Run B:** my wrapper's expectation omitted the preregistered 1 mm q clearance, so it held at S1.
- **Run C:** the S2alt join received the 10-decimal policy polyline, which fails K1's exact 4 mm test. The run now uses the saved polyline, with the same mesh options; no mesh had existed.

A geometry-only S2alt feasibility build and a no-contrast smoke test, both made before the formal runs, are disclosed in `evidence/m2_20261121/`.

## 2. Geometry comparability

| | S0 | S1 | S2 | S2alt |
|---|---|---|---|---|
| Chords per circle | 76 | 76 | 76 | 112 |
| Band area per hole (mm²) | 1012.152529 | 1012.152529 | 1012.152529 | 1012.852964 |
| Band volume fraction | 0.02952 | 0.02952 | 0.02952 | 0.02954 |
| Tip to nearest band node (mm) | 48.46 | 45.27 | 42.14 | 42.14 |
| q clearance beyond 2.6 mm (mm) | 45.86 | 42.67 | 39.54 | 39.54 |
| Global terminal tangent | 90.000° | 77.404° | 76.454° | 76.454° |

The three states are **geometry-equivalent** under the preregistered rule: equal chord counts and identical band polygons. The cross-state trend is therefore not confounded by different band discretizations. S0 does use a different (WP2 straight-crack) mesh family away from the bands.

## 3. Results

K is in MPa√m per kN (EDI 6×6 on the 0.4–2.6 mm annulus; blind bank COD). G is at P = 1 N. θ is the MTS forecast in **each state's own terminal frame**; negative θ turns toward the hole column.

| State | Case | K_I | K_II | ψ | θ_MTS | G (J/m²) | R_mat (EDI / COD / J) | U_R → primary | U_cons → conservative | Δθ (U) |
|---|---|---|---|---|---|---|---|---|---|---|
| S0 | H1 | 0.166436 | +0.018827 | 6.454° | −12.596° | 8.5846e−6 | 1 | — | — | — |
| S0 | soft | 0.166039 | +0.017766 | 6.107° | −11.949° | 8.5323e−6 | **0.99391** / 0.99392 / 0.99390 | 9.4e−6 → yes | 0.035 → no | +0.647° (0.002), yes |
| S0 | stiff | 0.165606 | +0.019403 | 6.683° | −13.020° | 8.5070e−6 | **0.99096** / 0.99095 / 0.99097 | 6.8e−6 → yes | 0.035 → no | −0.425° (0.001), yes |
| S1 | H1 | 0.182585 | +0.001514 | 0.475° | −0.950° | 1.0201e−5 | 1 | — | — | — |
| S1 | soft | 0.183156 | +0.000331 | 0.104° | −0.207° | 1.0265e−5 | **1.00620** / 1.00619 / 1.00619 | 4.7e−6 → yes | 0.035 → no | +0.743° (0.003), yes |
| S1 | stiff | 0.180914 | +0.002278 | 0.721° | −1.442° | 1.0017e−5 | **0.98187** / 0.98187 / 0.98188 | 2.6e−6 → yes | 0.034 → no | −0.493° (0.002), yes |
| S2 | H1 | 0.195982 | +0.003150 | 0.921° | −1.841° | 1.1756e−5 | 1 | — | — | — |
| S2 | soft | 0.198124 | +0.001983 | 0.573° | −1.146° | 1.2012e−5 | **1.02181** / 1.02181 / 1.02181 | 1.3e−6 → yes | 0.036 → no | +0.694° (0.003), yes |
| S2 | stiff | 0.193075 | +0.003866 | 1.147° | −2.292° | 1.1411e−5 | **0.97069** / 0.97069 / 0.97069 | 5e−8 → yes | 0.034 → no | −0.452° (0.002), yes |
| S2alt | soft | 0.198126 | +0.001981 | 0.573° | −1.146° | 1.2012e−5 | 1.02183 | 1.3e−6 → yes | 0.036 → no | +0.695° |
| S2alt | stiff | 0.193074 | +0.003865 | 1.147° | −2.292° | 1.1411e−5 | 0.97067 | 5e−8 → yes | 0.034 → no | −0.452° |

**Supporting values:**
- All K_II signs are resolved, and the COD signs agree.
- The bracketed MTS roots agree with `g2_mts_direction` to ≤ 2.6e−16 rad.
- Compliance ratio, soft / stiff: 1.01457 / 0.98947 (S0), 1.01450 / 0.98946 (S1), 1.01450 / 0.98940 (S2).
- CMOD ratio, soft / stiff: 0.9850 / 1.0035, 0.9909 / 0.9991, 0.9972 / 0.9945.
- The COD–EDI offset is 0.87–0.88 % of |K| in every case.

**Ratio robustness (S2 versus S2alt).**

| Contrast | δR, S2 (76-gon, Hmax 6) | δR, S2alt (112-gon, Hmax 5) | Relative change | Class |
|---|---|---|---|---|
| Soft | +0.021813 | +0.021828 | 0.067 % | **ROBUST** |
| Stiff | −0.029313 | −0.029333 | 0.068 % | **ROBUST** |

- Δθ changes by ≤ 2e−4° between the two meshes.
- The homogeneous K differs between them by 5e−6 (K_I) and 3.6e−4 (K_II) relative.
- Load-point compliance differs by 2 %. That is expected for a point load and is why only ratios are compared.

## 4. Interpretation (cautious)

1. **Stiff bands shield at all three states, and the shielding grows as the crack lengthens.** R_stiff is 0.9910, 0.9819 and 0.9707: −0.9 %, −1.8 % and −2.9 %. It is resolved under the primary rule at each state, and not resolved under the conservative bound at any state.
2. **Soft bands change sign.** R_soft is 0.9939 at S0 (−0.61 %, mild shielding), 1.0062 at S1 (+0.62 %) and 1.0218 at S2 (+2.2 %). Every value is resolved under the primary rule, with |δR| at least about 650 × U_R. Under the preregistered criterion this is a **shielding-to-amplification transition between S0 and S1, under the primary rule**. Under the conservative bound (±3.5 %) none of the soft values is resolved, so the conservative verdict sees no resolved effect. Both verdicts are given as preregistered.
3. **The tip effect is not a consequence of global stiffness.** The structural compliance change is practically constant along the path: soft +1.45 %, stiff −1.05 %. The tip G change, in contrast, moves from −0.6 % to +2.2 % (soft) and from −0.9 % to −2.9 % (stiff). So the tip effect depends on where the crack sits relative to the bands, not on how stiff the structure is overall.
4. **Steering is persistent and almost constant, and it is decoupled from the driving-force change for soft bands.**
   - Soft bands always reduce the clockwise turn toward the hole column: Δθ = +0.65°, +0.74°, +0.69°.
   - Stiff bands always increase it: −0.42°, −0.49°, −0.45°.
   - All of these are resolved, with U ≤ 0.003°.
   - The near-constant Δθ comes from a nearly constant additive change in K_II per kN: soft −0.00106, −0.00118, −0.00117; stiff +0.00058, +0.00076, +0.00072.
   - The large relative K_II changes at S1 (soft ×0.22, stiff ×1.50) only reflect how small the baseline K_II is there. They are not evidence of stronger directional control.
   - For stiff bands, shielding (R < 1) comes with an increased turn toward the holes. For soft bands, the steering sign stays the same while R − 1 changes sign. **Steering and driving-force changes therefore do not follow a single rule.**
5. **The baseline matters.** G_H1 rises 37 % from S0 to S2 (8.58e−9 → 1.18e−8 N/mm at 1 N). That growth is the reference-crack geometry, not the material. The material effects are the multiplicative R(s) on top of it.
6. **The S2 ratio is robust to band and exterior discretization.** A 112-gon interface with a finer exterior changes δR by 0.07 % of itself. That is far below the effects, so the S2 ratio is refinement-stable for this one check. The S0 and S1 ratios were not re-meshed (not authorized without an amendment). Their stability is supported, not proven, by the S2 check and by the identical band polygons.

## 5. Limitations

- One mesh per state, plus a single alternative mesh at S2. S0 is a different mesh family (WP2), although its band polygons are identical.
- The conservative uncorrelated bound resolves nothing. The primary rule resolves everything. The disagreement is preregistered and reported, not settled here.
- Plane stress, illustrative moduli, ν equal in both phases, idealized point-load pin/roller BVP.
- The crack shapes are homogeneous-reference shapes. A material-specific trajectory might differ, but that has not been computed.
- The only mechanism shown is bonded elastic contrast around voids. Not shown: debonding, auxetic or resonant behaviour, toughness, onset, or a Cornell experimental path.

## 6. Bounded proposal (needs separate authorization)

Given the persistent, resolved steering difference (about ±0.5–0.7° per state) and the sign-changing soft-band effect, a justified next step would be one short, separately preregistered, **independently evolved** material-specific trajectory pair (soft and stiff, 2–3 steps from S0), compared with the homogeneous path. It would use the PR #32 controller under a new versioned policy, with the same gates and the S2alt-style ratio check at one step. Interfacial CZM, physical calibration and State 3 of the homogeneous chain stay out of scope.

## 7. Reproduce (PowerShell, repository root)

```powershell
# inputs: the S0 mesh and WP2 record copied byte-identically into outputs/ (wp2 ledger), the S1 seed, the PR #32 chain, the P0 MAT
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_m2_evolution.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_m2_evolution.ps1 -Batch run_g2_m2_report_batch -RunDir .\outputs\g2_material_evolution_v1\run_<time>
```

## 8. Files and hashes

**New code.** PR #35 code is reused unchanged:
- `g2_m2_state_adapter.m`, `check_g2_m2_phase_controls.m`
- `g2_material_case_summary.m`, `g2_material_ratio_table.m` (verbatim copies of PR #35 local functions, plus steering fields)
- `run_g2_m2_evolution_batch.m`, `run_g2_m2_report_batch.m`, `run_g2_m2_evolution.ps1`

**Run D records (SHA-256):**

| Record | SHA-256 |
|---|---|
| `PHASE_MAP_S0.mat` | `9e61153f…8390` |
| `PHASE_MAP_S1.mat` | `1abd486f…5ff9` |
| `PHASE_MAP_S2.mat` | `bfd58ada…7a44` |
| `PHASE_MAP_S2alt.mat` | `eb2f0076…7a06` |
| `CASE_S0_Msoft.mat` / `CASE_S0_Mstiff.mat` | `cd506779…2b45` / `052bcee4…5d79` |
| `CASE_S1_Msoft.mat` / `CASE_S1_Mstiff.mat` | `da5b04c6…db11` / `a2af08a0…416f` |
| `CASE_S2_Msoft.mat` / `CASE_S2_Mstiff.mat` | `20ea1f17…0f46` / `452365f9…5eec` |
| `S2ALT_KINKED_GEOMETRY_ONLY_candidate.mat` | `0627dd3a…3080` |
| `LEDGER.json` | `59873b2c…fa95` |

The full 165-file list is in `evidence/m2_20261121/SHA256SUMS_original_outputs.txt`.

**Figures:** `evidence/m2_20261121/report/m2_R_vs_s.png`, `m2_steering_mixity_G_compliance.png`, `m2_K_by_state.png`, `m2_geometry_tips_bands.png`, and `m2_results.csv`.
