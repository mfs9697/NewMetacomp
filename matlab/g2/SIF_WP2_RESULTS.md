# WP2: idealized elastic BVP and independently cross-checked signed SIF (Issue #20)

**Executed on:** 2026-11-18, MATLAB R2023a (PDE Toolbox 3.10), investigator workstation. The 5 GiB free-RAM guard was applied before every run.

**Branch:** `research/g2-wp2-sif-20261118`, stacked on PR #22 (WP0/WP1).

**Order of work (Git-verifiable):**
1. Preregistration `31cbc7e` (16:43:54): criteria fixed before any WP2 code or number.
2. Code and Amendment 1 `359d6f4` (17:00:38): committed after the S/M and B1 runs and the discarded family-A mesh, **before any Cornell SIF was computed**.
3. Cornell run (17:00:47).
4. S/M and B1 re-run on the committed code: identical results.

**All numbers are for the declared idealized unit-load model** (`WP2_PREREGISTRATION.md` §1). The Cornell 1990 load magnitude, support and contact details, E, ν, plane state and toughness are not documented, and nothing here reproduces the experiment.

## Methods

- **FE solver:** `g2_t6_elasticity.m`. Straight-sided quadratic T6 elements, plane stress or strain, 3-point stiffness rule, sparse direct solve.
- **EDI** (`g2_sif_interaction.m`): domain interaction integral with FE-nodal q and Williams auxiliary fields; J from the same domain.
- **COD** (`g2_sif_cod.m`): displacement jumps of the crack-face T6 twin nodes, linear extrapolation of K(r) over 0.1–1.5 mm. It shares no algebra with EDI (no auxiliary field, no q, no stress).
- **Frame:** t = (0, 1), n = (−1, 0). The upper face (θ = +π) is the left face.

## Results against the preregistered criteria

| ID | Test | Result | Criterion | Verdict |
|---|---|---|---|---|
| S1 | patch test on the protected block | stress error 4.8e−12, displacement 1.2e−14, rigid-mode energy 2.3e−18 | 1e−9 / 1e−12 | PASS |
| S2 | Williams fields: Hooke vs stress; finite differences vs gradient | 7.5e−16; 2.2e−10 | 1e−6 | PASS |
| M1 | manufactured Williams fields, 6 cases (I, II, mixed (0.6, −0.8), each ± T) | EDI 0.04–0.12 % K_ref; COD 0.76–1.31 %; K_II sign correct in all | 1.0 % / 3.0 % | PASS |
| M2 | path independence, 5 annuli (manufactured; Cornell) | ≤ 2.6e−6; ≤ 2.2e−6 | 0.5 % | PASS |
| M3 | J vs (K_I² + K_II²)/E′ (manufactured; Cornell) | ≤ 2.7e−6; ≤ 1.6e−5 | 0.5 % | PASS |
| M4 | quadrature 4×4 vs 6×6 | ≤ 3.8e−13 | 0.1 % | PASS |
| B1 | edge crack, pure bending, holeless beam W = 203.2 mm (18,721 T3) vs Tada–Paris–Irwin | EDI +0.34 %; COD −0.54 %; abs(K_II)/K_I = 1.4e−7 | 1.0 % / 3.0 % / 0.5 % | PASS |
| C1 | Cornell: equilibrium | residual ≤ 1.3e−12; statics ≤ 1.6e−12; reactions 0.5/0.5 of the load, as statics requires | 1e−8 | PASS |
| C2 | Cornell: EDI vs COD | 0.89 % K_ref | 3.0 % | PASS |
| C3 | Cornell: plane stress ν 0.35 / plane strain ν 0.35 / plane stress ν 0.30 | K changes ≤ 1.1e−5 K_ref | 0.5 % | PASS |
| C4 | Cornell: family A vs refined family B | 2.0e−5 K_ref | 1.0 % | PASS |

**WP2 decision: GO for WP3 development.** This is not a permit for a physical propagation claim, which still needs a load and a toughness.

## Cornell idealized SIF (P = 1 kN on t = 12.7 mm, plane stress)

| Family | T3 / T6 nodes | K_I (MPa·√m per kN) | K_II (MPa·√m per kN) | K_II/K_I |
|---|---|---|---|---|
| A (Hmax 6, guides 1.5, tip guide 15/1.5) | 28,151 / 57,179 | 0.166436 | 0.018827 | 0.1131 |
| B (Hmax 4, guides 1.0, tip guide 15/1.0, lip Hedge 0.30) | 40,714 / 82,464 | 0.166439 | 0.018825 | 0.1131 |

- **Linearity:** K scales linearly with P.
- **Material independence:** K is independent of E, ν and the plane state for this statically determinate, traction-free-hole BVP, as C3 confirms. G = (K_I² + K_II²)/E′ is not.
- **Sign of K_II:** positive in the stated convention; the left (upper) face slides in +t relative to the right face.

## Findings recorded

1. **Amendment 1.** The first family-A mesh, with point-load and support vertices but no tip guide, failed one join gate: ratio 1.8307 > 1.8 on one edge 12 mm above the rim. The gate was not relaxed and the mesh was discarded (evidence `DISCARDED_famA_no_tip_guide_*`). A nonphysical 15 mm tip guide face controls the grading, and both families then passed join 13/13, 38/38 and 24/24.
2. **Family B exceeds the 40k T3 resource budget.** At 40,714 T3 it is a disclosed deviation for the refinement study only; family A (28,151) is within the budget.
3. **COD reads about 0.9 % below EDI.** The apparent K(r) of the non-singular T6 elements falls for r < 0.3 mm (`cornell_cod_extrapolation.png`), and the preregistered window starts at 0.1 mm. The window was not changed. Quarter-point elements are not used because the frozen kernel must stay unchanged.

## Not established

- No experimental load, CMOD, compliance or toughness, so no fracture-onset statement.
- No crack growth (WP3).
- **Evidence files:** MAT files stay in the gitignored `outputs/`. SHA-256 values are in `evidence/wp2_20261118/SHA256SUMS_original_outputs.txt`; committed logs and JSON have local paths replaced by `<repo>`.

## Reproduce (from the repository root, MATLAB R2023a)

```powershell
$m='C:\Program Files\Polyspace\R2023a\bin\matlab.exe'
& $m -batch "restoredefaultpath;addpath('matlab/g2','-begin');run_g2_wp2_verification_batch"
& $m -batch "restoredefaultpath;addpath('matlab/g2','-begin');run_g2_p010_isolated_batch"
& $m -batch "restoredefaultpath;addpath('matlab/g2','-begin');run_g2_wp2_benchmark_batch('<p0 run dir>')"
$v="'BottomVertices_mm',[25.4 482.6],'TopVertices_mm',254,'TipGuideRadius_mm',15"
& $m -batch "restoredefaultpath;addpath('matlab/g2','-begin');run_g2_protected_mesh_batch('famA',$v,'TipGuideHface_mm',1.5)"
& $m -batch "restoredefaultpath;addpath('matlab/g2','-begin');run_g2_protected_mesh_batch('famB',$v,'TipGuideHface_mm',1.0,'Hmax_mm',4,'GuideHface_mm',1.0,'Hedge_mm',0.30,'MaxT3Elements',80000)"
& $m -batch "restoredefaultpath;addpath('matlab/g2','-begin');run_g2_protected_audit_batch('<famA dir>','<p0 run dir>')"
& $m -batch "restoredefaultpath;addpath('matlab/g2','-begin');run_g2_protected_audit_batch('<famB dir>','<p0 run dir>')"
& $m -batch "restoredefaultpath;addpath('matlab/g2','-begin');run_g2_wp2_cornell_sif_batch('<famA dir>','<famB dir>')"
```

Check free RAM (≥ 5 GiB) before each call, as the launchers do.
