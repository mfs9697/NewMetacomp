# G2 material contrast on frozen State 2: results (Issue #33)

**Verdict: GO.** The two-phase solver is qualified, M0 is bitwise identical to H1, and Msoft and Mstiff pass every inherited and added gate.

All numbers come from genuine MATLAB R2023a runs (PDE Toolbox 3.10):
- Accepted run C: `outputs/g2_material_contrast_v1/run_20261119_003430_660` at HEAD `e50e92f`.
- Run E is a bit-identical replay at `08eacf7`.

The model is idealized and illustrative: plane stress, 1 N pin/roller point load, assumed moduli. **Nothing here is a fracture-onset, toughness, durability, arrest or experimental claim**, and no crack was advanced.

## 1. Stages

| Stage | Verdict | Key evidence |
|---|---|---|
| Checkpoint integrity (PR #32 controller, dry) | PASS | `DRY_PREFLIGHT_STEP_CAP`, States verified through 2, re-audit 34/34, chain unchanged (8 files) |
| S0 source | PASS | Chain, mesh, both policies, Cornell JSON and P0 hashes match; clean committed tree; saved mesh re-audited 34/34 (min angle 30.127°, ratio 1.592, q 2,443) |
| S1 phase map | PASS | See §2 |
| S2 benchmark | PASS 14/14 | See §3; SIF-level q-phase negative rejected |
| S3 identity H1 vs M0 | PASS | Stiffness, u, every K, energy, reactions, compliance and MTS differ by exactly 0 (bitwise) |
| S4 Msoft / Mstiff | PASS / PASS | All 14 SIF and interface gates in each case |
| S5 ratios | PASS | See §4 |
| Replay (run E) | identical | Phase map, all four cases (u, EDI, COD, compliance, CMOD), benchmark and ratio table are bit-identical |

**Failed or refused runs, kept as they are** (`G2_MATERIAL_CONTRAST_RUNLOG.md`):
- **Run A:** harness HOLD on the release string, `'2023a'` versus `'R2023a'`.
- **Run B:** harness crash; my edit commented out a statement.
- **Run D:** dirty-source guard refused a replay launched with untracked evidence files.

None of them computed anything. Development smoke runs made before the formal run are disclosed in `evidence/material_20261119/development_smoke/`.

## 2. Phase topology on the saved State 2 mesh (unchanged)

The three CAD guide circles of `g2_kinked_exterior_mesh` left **conforming polygonal interfaces**:
- **Vertices:** 76 saved T3 vertices per circle within 2.2e−14 mm of r = 19.05 mm. The nearest other vertex is 1.30 mm away.
- **Chords:** each of the 228 chords is a two-owner T3 edge whose midside T6 node is shared, so the bond is perfect with no duplicated DOF.
- **No other mixed edges:** exactly 228 edges join a matrix element to a band element.
- **Two independent classifiers agree element by element:** a flood fill blocked at the chords, and point-in-polygon of all six T6 nodes.
- **Counts:** 16,347 matrix and 12,278 band T6 elements (4,088 / 4,095 / 4,095 per band). The bands are connected, the matrix is connected, and no node lies inside a void.
- **Areas:** each band is 1012.153 mm², equal to the 76-gon area minus the 152-gon hole area to 3e−16. That is 0.125 % below the nominal annulus. The plate area minus the hole polygons matches to 1.4e−16.
- **Coincident nodes:** all 184 coincident pairs are registered crack-bank twins.
- **Tip guide:** every element within the 15 mm tip guide is matrix.
- **q support:** for all five annuli it lies in the matrix. The nearest band node is 42.14 mm from the tip, giving 39.54 mm clearance beyond the largest q radius (2.6 mm).

**Negative controls, all rejected (8/8):**
- swapped labels;
- a band element relabelled matrix, and a matrix element relabelled band;
- a detached interface;
- one interface vertex moved 0.01 mm off the circle (nonconforming);
- a filled void;
- a q domain of radius 45 mm;
- a band label inside the tip guide.

Detail is in `evidence/material_20261119/run_C_GO/material_contrast_console.log`.

## 3. Two-phase FEM qualification (coated hole, exact solution)

**Setup:**
- Concentric void a = 6.35 mm, bonded band to b = 19.05 mm, matrix to c = 57.15 mm.
- Remote uniaxial 1 MPa. The exact field is Lamé plus Michell cos 2θ, and it self-checks to 6.1e−10.

**Finest level** (Hmax 0.6 mm, 66,694 T6):

| E_r/E_m | max nodal u error | strain-energy error | interface traction moments (worst side) | order, finest pair |
|---|---|---|---|---|
| 0.5 | 4.02e−4 | 5.7e−5 | 1.49e−3 | 2.33 |
| 2 | 2.55e−4 | 1.4e−5 | 1.21e−3 | 2.32 |
| 10 | 9.6e−5 | 2.8e−5 | 2.24e−3 | 2.30 |
| *gate* | ≤ 5e−3 | ≤ 5e−3 | ≤ 2e−2 | ≥ 1.0 |

**Other benchmark checks:**
- All three error measures decrease monotonically with refinement.
- Residual ≤ 4.6e−15 and interface nodal force balance ≤ 2.1e−13.
- Ratio 1 equals the homogeneous solver exactly.
- The stiffness equals an independent element-loop, 6-point-rule assembly to 5.0e−15.

**Negative controls fail as required:**
- Swapped phases give e_u 0.239 and e_U 0.73.
- A half-detached interface gives e_u 0.335, a 8.6e−3 mm displacement jump, and a mapper HOLD.

**Where the residual error comes from (development diagnostic, disclosed).** The remaining benchmark error sits at the midsides of the polygonal traction-free hole. Imposing the exact hole displacement removes most of it.

## 4. Results on the frozen State 2 crack

Units:
- K is in MPa√m per kN, which is K_raw·√1000 from the 1 N solve. Physical K at 1 N is the per-kN value divided by 1000.
- G_1N = (K_raw,I² + K_raw,II²)/E_m is converted to J/m².
- EDI is the 6×6 rule on the 0.4–2.6 mm annulus, with matrix E and ν. COD is the blind bank fit on the final segment.

| Quantity | H1 | M0 (ratio 1) | Msoft (0.5) | Mstiff (2) |
|---|---|---|---|---|
| K_I EDI | 0.195982362 | 0.195982362 | 0.198124002 | 0.193074852 |
| K_II EDI | +0.003149970 | +0.003149970 | +0.001982502 | +0.003865893 |
| K_I / K_II COD | 0.194259931 / +0.003101658 | identical | 0.196382450 / +0.001949053 | 0.191378118 / +0.003808677 |
| COD−EDI (fraction of \|K\|) | 0.8788 % | 0.8788 % | 0.8790 % | 0.8786 % |
| G at 1 N (J/m²) | 1.175571e−5 | 1.175571e−5 | 1.201214e−5 | 1.141112e−5 |
| **R_mat (EDI / COD / J)** | 1 | 1 / 1 / 1 | **1.021813 / 1.021812 / 1.021806** | **0.970687 / 0.970687 / 0.970692** |
| U_R (primary) → resolved? | — | 0 | 1.3e−6 → **yes** | 5.0e−8 → **yes** |
| U_R,cons (uncorrelated) → resolved? | — | 0.035 | 0.036 → no | 0.034 → no |
| K_I / K_I,H1 | 1 | 1 | 1.01093 | 0.98516 |
| K_II / K_II,H1 (sign resolved) | 1 (yes) | 1 (yes) | 0.629 (yes) | 1.227 (yes) |
| Mixity ψ = atan(K_II/K_I) | 0.921° | 0.921° | 0.573° | 1.147° |
| θ_MTS forecast (not executed) | −1.8407° | −1.8407° | −1.1464° | −2.2923° |
| Δθ_MTS vs H1 (U) | — | 0 | +0.694° (0.003°) | −0.452° (0.002°) |
| Load-point compliance (mm/N) | 2.218017e−4 | same | 2.250175e−4 (+1.45 %) | 2.194495e−4 (−1.06 %) |
| CMOD ratio | 1 | 1 | 0.9972 | 0.9945 |
| Share of strain energy in the bands | — | 1.83 % | 2.28 % | 1.25 % |
| Interface balance / annulus resultant | — | 1.9e−12 / 3.9e−13 | 1.7e−12 / 4.5e−13 | 2.6e−12 / 9.9e−13 |
| Chord traction mismatch, band vs matrix side (L2) | — | ≤ 0.03 % | ≤ 0.88 % | ≤ 0.39 % |

**Gate values in every case:**
- residual ≤ 1.6e−12, statics ≤ 2.7e−13;
- contour spread 1.64e−6, quadrature drift 3.7e−13;
- J identity ≤ 2.0e−5;
- whole-crack opening ≥ 0.

## 5. Interpretation (cautious)

1. **Sign and size.** At the identical crack, voids, mesh and load, a stiffer bonded band lowers the tip energy-release rate and a softer band raises it, in a smooth, monotone way. R_mat is 0.9707 at E_r/E_m = 2 (−2.9 %) and 1.0218 at 0.5 (+2.2 %). In the vocabulary of the G2 protocol, the phase-only `R_direct` is mild screening for stiff bands and mild amplification for soft bands. The effect is a few per cent, with the bands 42 mm from the tip.
2. **The change is almost all Mode I.** R_mat equals (K_I/K_I,H1)² to within 1e−4 because K_II is tiny: |K_II/K_I| ≤ 0.02. K_II changes a lot relative to its own size (−37 % / +23 %) but stays small. Both of its signs are resolved, and the mixity stays between 0.57° and 1.15°.
3. **Direction (forecast only).** The MTS forecast turns the tip clockwise, towards the hole column at x = 152.4 mm, by 1.84° in H1. That turn is 2.29° with stiff bands and 1.15° with soft bands. This does not predict a new trajectory; no step was taken.
4. **Structure.** The load-point compliance changes the same way as G, by +1.45 % (soft) and −1.06 % (stiff). CMOD falls slightly in both cases, so it does not follow G. No single global stiffness measure stands in for the tip quantity.
5. **Uncertainty.** Both preregistered rules give an answer, and they disagree:
   - **Primary rule.** It takes the spread of R itself across the five EDI annuli, the 4×4 rule and the blind COD estimator. Under it the effect is resolved by orders of magnitude (U_R ≤ 1.3e−6).
   - **Conservative rule.** It treats the 0.879 % COD–EDI K offset as independent in each case. Under it the effect is not resolved (U ≈ 3.5 %).
   - **Which one the data support.** The offset is the same in all four cases to 4e−6 relative (0.8786–0.8790 %). The conservative rule also assigns ±3.5 % to M0, which is bitwise identical to H1. So the conservative rule overstates the uncertainty of a same-mesh ratio. It is still reported as preregistered.
   - **What neither rule covers.** Neither rule measures how R_mat depends on mesh refinement. That is not studied here (out of scope). So protocol rule 5 (stability under independent refinement) is **not yet met**. The result is a resolved same-mesh effect, not a refinement-qualified screening claim.
6. **Null result?** Not on this mesh. R_mat differs from 1 by 2–3 %, far beyond the primary U_R, and the effect is antisymmetric in log(E_r/E_m) to first order. The magnitude is modest, and it is bounded by the geometry: bands at about 42 mm from the tip, three bands, a 12.7 mm outer-to-hole ratio.

## 6. Limitations

- One frozen crack state and one mesh; R_mat has not been checked under refinement.
- The interfaces are the inscribed 76-gons of the saved mesh, 0.125 % less band area than nominal.
- Plane stress; illustrative moduli (E_r/E_m = 0.5, 2) and ν = 0.35 in both phases; not measured cement, polymer or Cornell values.
- Idealized pin/roller point load. Compliance at a point load depends on the mesh; only same-mesh ratios are meaningful.
- The only mechanism shown is perfectly bonded two-phase elastic contrast around voids. Not tested: auxetics, resonance, debonding, CZM, toughness, onset, or an observed Cornell path.
- The MTS change is a forecast at a frozen tip, not a trajectory. Hole-versus-no-hole (H0), other path states, band thickness or contrast maps, and evolving trajectories need separate authorization.

## 7. Reproduce (PowerShell, repository root, this branch)

```powershell
# requires outputs\g2_trajectory_chain_v1_attempt2 (PR #32) and the P0 MAT in outputs\g2_p010_isolated\run_20261118_163657_790
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_material_contrast.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_material_contrast.ps1 `
  -Batch run_g2_material_report_batch -RunDir .\outputs\g2_material_contrast_v1\run_<time>
```

The launcher refuses to start if free RAM is below 5 GiB, if MATLAB is already running, if the Cornell JSON SHA differs, or if the run would use the HOLD-1 chain. MATLAB itself refuses a dirty tree or any hash mismatch.

## 8. Files and hashes

**Code.** All of these are new; nothing pre-existing was changed:
- `G2_MATERIAL_POLICY_v1.json` (SHA-256 `E60156F6…6A971`)
- `G2_MATERIAL_CONTRAST_PREREGISTRATION.md`
- `g2_t6_elasticity_phase.m`, `g2_material_phase_map.m`, `g2_material_phase_verify.m`
- `g2_coated_hole_exact.m`, `g2_t6_point_stress.m`, `g2_material_sif_on_mesh.m`
- `check_g2_material_benchmark.m`, `check_g2_material_phase_controls.m`
- `run_g2_material_contrast_batch.m`, `run_g2_material_report_batch.m`, `run_g2_material_contrast.ps1`

**Accepted run C records (SHA-256):**

| Record | SHA-256 |
|---|---|
| `PHASE_MAP.mat` | `43f2c374…4309d` |
| `BENCHMARK.mat` | `8419ed11…8056e` |
| `CASE_H1.mat` | `3d6abbc2…325e4` |
| `CASE_M0.mat` | `e5a29bfc…2eaf` |
| `CASE_Msoft.mat` | `a68bd934…f67dd` |
| `CASE_Mstiff.mat` | `ed66fbeb…b333` |
| `LEDGER.json` | `db42974c…056e` |

The full list (59 files, including the failed runs) is in `evidence/material_20261119/SHA256SUMS_original_outputs.txt`.

**Evidence.** `evidence/material_20261119/` holds sanitized logs, ledgers, manifests and figures:
- `report/material_phase_map.png`
- `material_annulus_zoom.png`
- `material_ratios.png`
- `material_EDI_vs_COD.png`
- `material_interface_tractions.png`
- `material_benchmark_convergence.png`
- `material_results.csv`

The committed copies are sanitized (`<repo>`, LF line endings), so their bytes differ from the originals listed in the hash ledger.
