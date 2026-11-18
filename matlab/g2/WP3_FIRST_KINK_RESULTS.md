# WP3: first MTS kink in Cornell #1 (Issue #24) — results

**Executed on:** 2026-11-18, MATLAB R2023a (PDE Toolbox 3.10), investigator workstation. The 5 GiB free-RAM guard was checked before every MATLAB process; one MATLAB process ran at a time.

**Branch:** `research/g2-wp3-first-kink-20261118`, created from PR #23 head `513044cc2c5e2db68fc6630c3fe356769abd5e83`.

**Order of work (Git-verifiable):**
1. `WP3_PREREGISTRATION.md` committed at `d559dd6` (18:22:54), before any WP3 MATLAB code existed.
2. WP3.0 run (18:24).
3. WP3.1 kinked mesher, auditor and controls written, then run (18:35–18:41).
4. Code and evidence committed together afterwards.

The WP3.1 runs used the working tree that was then committed unchanged. Replay from committed code is part of WP3.3 (R1).

**Scope.** This file covers WP3.0 and WP3.1 only. WP3.2 (kinked-tip SIF) and WP3.3 (one-step restart) are reported in the stacked PR.

**Nature of the result.**
- This is a **numerical geometry trial** for the declared idealized BVP: a provisional 4 mm increment in the MTS direction of the WP2 idealized SIFs.
- It is **not** a propagation event and **not** a fracture-onset prediction. K_Ic, G_c, the experimental load, the contact conditions and the experimental path are unknown.

## Stage verdicts

| Stage | Verdict | Evidence (`matlab/g2/evidence/wp3_20261118/`) |
|---|---|---|
| WP3.0 analytic MTS tests A1–A9 and manifest | **GO** | `g2_wp3_mts_run_20261118_182426_677` |
| WP3.1 kinked mesh, family A, −12.5957° | **GO**: join 13/13, independent kink-aware audit 34/34 | `g2_wp3_kinked_mesh_run_20261118_183545_651_famA`, `g2_wp3_kinked_audit_run_20261118_183925_775` |
| WP3.1 negative controls N1–N9 (10 corruptions) | **all detected**; baseline passes | `g2_wp3_auditor_controls_run_20261118_183957_058` |
| WP3.1 mirrored geometry-only control, +12.5957° | join 13/13, audit 34/34 (no sign dependence) | `g2_wp3_kinked_mesh_run_20261118_184040_732_famA_mirror`, `g2_wp3_kinked_audit_run_20261118_184125_271` |

No attempt failed in WP3.0–3.1, and no gate, threshold, Δa or θ was changed.

## WP3.0 analytic MTS

θ = 2 atan2(−2K_II, K_I + √(K_I² + 8K_II²)), in the frame t (growth direction) and n = R(+90°)t, with the upper face on +n (WP2 convention). The result is `g2_mts_direction.m`.

| ID | Result | Criterion |
|---|---|---|
| A1 pure I | θ = 0 exactly | 0 |
| A2 pure II | ∓70.52877936550931° (exact ∓2 atan(1/√2)); status `DOCUMENTED_PURE_MODE_II`, not admissible for a step | 1e−9° |
| A3 antisymmetry, 2,001 ratios | max abs(θ(K_II) + θ(−K_II)) = 0; sign rule holds | 1e−12 rad |
| A4 stationarity residual | ≤ 1.09e−15 (grid); 0 (Cornell) | 1e−12 |
| A5 tensile global maximum, 43 ratios, 2·10⁶-point grid | arg-max error ≤ 1.55e−6 rad (grid step 3.14e−6); σ_θθ″ ≤ −0.75 < 0 | grid step |
| A6 small K_II | relative error ≤ 2.3e−12 | 1e−6 |
| A7 scale invariance | 4.4e−16 rad | 1e−14 |
| A8 HOLD regimes (zero K, K_I < 0, non-finite) | correct HOLD status; θ empty; no NaN | — |
| A9 Cornell state 0 | θ = **−12.5956937016°**, cos θ = 0.9759331546, t1 = (0.2180698918, 0.9759331546), tip1 = **(102.4722795671, 29.3037326185) mm**; errors ≤ 4.6e−9 | 1e−6° / 1e−8 |

The inherited upstream guard `MinKinkTangentDot = 0.98` would **reject** this kink (cos θ = 0.97593 ≤ 0.98, bound 11.478341°). This is recorded in the manifest. It was not lowered, and it was not applied as a WP3 gate (preregistration §3).

## Why the 0.98 guard was replaced, and the gates used instead

Upstream documents the guard as an "inherited mesh limit, not a physical criterion". No failure mechanism is recorded for it. WP3 gates each mechanism a kink can break, with thresholds made of construction constants (preregistration §3):

| Gate | Mechanism | Value (−12.60°) | Threshold |
|---|---|---|---|
| K2 | non-singular miter, 1 + t·t′ | 1.97593 (miter factor 1.00607) | > 1.8 |
| K3 | collar entry on the last segment | 4 mm > 3.3 mm | — |
| K4 | rim band clear of the earlier crack: distance(tip1, segment 1) − r_o − w | 0.680 mm | ≥ rim chord 0.32385 mm |
| K5 | core and q clear of the earlier crack | 4.000 mm | > 3 mm |
| K6 | segments to hole walls | 57.97 mm | > 3 mm |
| K7 | segments to 3R guide faces | 45.27 mm | > w + 1.5 mm |
| K8 | collar inside the material (walls / guides / plate) | 54.67 / 41.97 / 26.00 mm | > 0 |
| K9 | 15 mm tip guide (plate / nearest guide) | 14.30 / 30.27 mm | > 0 |
| K1, K10 | polyline identity; no self-intersection; inside the plate | pass | — |

The mesh then had to pass the **unchanged** quality gates: minimum angle ≥ 20°, ratio ≤ 1.8 and positive Jacobians. No claim is made beyond this one kink and its mirror image; a general angular envelope is not qualified.

## WP3.1 kinked protected mesh (family A)

**Construction.**
- **Polyline:** (101.6, 0) → (101.6, 25.4) → (102.4722795671, 29.3037326185) mm.
- **Kernel:** the unchanged vendor kernel (15/15 local gates), rotated by −12.5956937016°, plus the analytic 0.3 mm collar in the new frame.
- **Exterior:** a new native PDE exterior. It has:
  - a 20 µm mitred channel;
  - the 64-chord rim cavity;
  - the three true holes and the three 3R guide faces;
  - the 15 mm / 1.5 mm tip guide centred at tip1;
  - support and load vertices at (25.4, 0), (482.6, 0) and (254, 203.2);
  - controls Hmax 6, Hmin 0.12, Hgrad 1.12 and lip Hedge 0.45.
- **Lip pairing:** each lip has 3 CAD edges (the tip-guide circle splits segment 1). Pairing gives 53 + 1 interior nodes per side and segment, a station mismatch of 7.6e−4 mm (tolerance 0.15) and a maximum lip spacing of 0.490 mm.

| Quantity | Family A (−12.60°) | Mirror (+12.60°) | WP2 straight family A |
|---|---|---|---|
| T3 elements / T6 nodes | 28,421 / 57,737 | 28,459 / 57,813 | 28,151 / 57,179 |
| min T3 angle | 30.1268° | 30.1268° | — |
| max neighbour ratio | 1.59183 (inside the rotated kernel) | 1.59183 | — |
| min T6 Jacobian | 1.50e−3 mm² | 1.50e−3 mm² | — |
| boundary loops / Euler | 4 / −2 | 4 / −2 | 4 / −2 |
| crack edges per bank / bank T6 nodes | 84 / 169 | 84 / 169 | — |
| rotated kernel versus P0 local coordinates | 2.7e−14 mm | 2.9e−14 mm | — |
| q-active parents / support radius / distance to the kink | 2,443 / 2.769 mm / 1.234 mm | same | 2,443 |
| material area versus analytic | +1.1e−6 relative | same | — |

The minimum angle and the maximum ratio of the whole mesh both occur in the rotated p010 kernel. The new exterior, including the kink vertex, is better on both measures.

**Independent kink-aware audit** (`g2_kinked_mesh_auditor.m`, 34 gates, separate process). It reads only:
- the saved arrays;
- the saved polyline;
- the JSON;
- the P0 evidence MAT, SHA-256 `15201996…7C58`.

It does not call the mesher, the join or the vendor builders. Both meshes pass 34/34. The saved family-A MAT has SHA-256 `CB5451D4…305F`.

**Straight-crack checkers, for information only (not a verdict).**
- The unchanged 38-gate checker gives 33/38 on the kinked mesh. The five failures are its straight-crack classifications: the crack on x = 101.6, the tip at (101.6, 25.4), bank coverage, mouth/tip and twins.
- The 24-gate protected-tip checker gives 9/24; every tip-centred gate is evaluated at the old tip.

This confirms that their earlier PASS verdicts cannot certify a kinked mesh.

**Negative controls.** Every corruption was rejected, with its expected gate group among the failures:

| ID | Corruption | Detected by |
|---|---|---|
| N1 | kink vertex moved 0.05 mm | G3, G5, G10 (+G4, G6, G8) |
| N2 | upper kink node moved 0.01 mm (bad miter) | G5 (+G1, G3, G4) |
| N3 | banks welded on the final segment | G5 (+G1, G4, G6, G8) |
| N4 | one r = 3.3 seam node moved 1e−6 mm radially | G7 (+G1, G6) |
| N5 | hole 2 centre shifted 0.5 mm in the JSON | G3 |
| N6 | one inverted exterior element | G2 |
| N7 | q zeroed on 10 active nodes | G9 |
| N8a | segment 2 ends inside hole 1 | G10 (+ many) |
| N8b | 100° fold | G10 (+ many) |
| N9 | straight WP2 family-A mesh with the kinked polyline | G5, G6, G8, G9 |

## Not established here

- No SIF on the kinked mesh (WP3.2) and no restart (WP3.3) in this PR.
- Tip-size convergence is not run, because the frozen p010 scale is fixed.
- The angular envelope beyond ±12.60° is not qualified.
- No physical onset, toughness or experimental path.

## Reproduce (from the repository root)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\matlab\g2\run_g2_wp3_first_kink.ps1 `
  -P0RunDir <outputs\g2_p010_isolated\run_*> -StraightMeshRunDir <WP2 family-A outputs\g2_protected_mesh\run_*>
```

The individual MATLAB calls (path: `matlab/g2` and `matlab/g2/vendor_p010_a14d8872` first, after `restoredefaultpath`) are:
- `run_g2_wp3_mts_tests_batch`
- `run_g2_wp3_kinked_mesh_batch('<manifest.mat>','famA',false,'BottomVertices_mm',[25.4 482.6],'TopVertices_mm',254,'TipGuideRadius_mm',15,'TipGuideHface_mm',1.5)`
- `run_g2_wp3_kinked_audit_batch('<mesh dir>','<P0 dir>')`
- `check_g2_kinked_auditor_controls('<mesh dir>','<P0 dir>','<straight mesh dir>')`
- the mirror: as above with `'famA_mirror',true`

MAT files stay in the gitignored `outputs/`. Their SHA-256 values are in `evidence/wp3_20261118/SHA256SUMS_original_outputs.txt`. Committed logs and JSON have local paths replaced by `<repo>`.
