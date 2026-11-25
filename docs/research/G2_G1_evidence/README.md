# G1 field-study evidence (WP2, no boundary-value problem)

Read-only post-processing of SAVED elastic fields: M4.B frozen S2 (mesh `9269be43…`), R1 S2alt (mesh `0627dd3a…`) and the LP1 homogeneous path H S0–S4 (A0-reproduced). Stresses, strains and strain-energy density are reconstructed from the saved displacements with the solver's T6 kinematics and per-element plane-stress D. Fidelity: element energies agree with the saved values to ≤ 1.9e-13 (relative). The Betti identity reproduces the saved compliance changes of all 12 single-ring cases to ≤ 1.9e-10.

| File | Content |
|---|---|
| `G1_FIELD_EVIDENCE.json` | Output of `scripts/g2/m5/g1/g1_field_analysis.m` (SHA-256 of the code used: `851b1ca0…`): provenance, ring environments, hole-edge fits, corridor statistics, trajectories, single-ring effects with the Betti check, homogeneous-path energies, first-order tests, influence map statistics and profiles |
| `G1_1…G1_5_*_UA.png/.pdf` | Ukrainian figures from `scripts/g2/m5/g1/g1_figures.m` (code SHA-256 `b1c78f3c…`) |
| `run_g1.m/.log`, `run_fig.m/.log` | The exact runner scripts and console logs |
| `SANITIZATION.json` | Original and sanitized hashes; local paths replaced by `<repo>`, `<worktree>`, `<scratch>`; MATLAB startup path warnings removed |

Inputs were read from the execution clone (`<repo>`) without modification. The M4.B and R1 run folders there hold the MAT files only, so their SHA-256 values were checked against the committed manifests in `matlab/g2/evidence/m4b_20261121/campaign/` and `matlab/g2/evidence/m4b_r1_20261121/campaign/`. The intermediate `G1_FIGDATA.mat` (3.4 MB) is not committed; rerunning the analysis regenerates it.
