# G2-LP1-SR1 independent check outputs (Issue #56)

These outputs are read-only and come from no FEM solve, mesh build or written record. They were produced by `scripts/g2/sr1/`.

| File | Content |
|---|---|
| `LP1_records_reduced.json` | Path-free reduction of the 20 saved LP1 states: STATE, verified SOLUTION K fields, PHASE audit summary and the saved ring/hole polygons. Source: the hash-verified raw archive `5b333b03…c533`, via `sr1_extract_records.m`. |
| `LP1_mesh_quality.json` | Independent T3 quality of the 20 saved meshes (`sr1_mesh_quality.m`) |
| `SR1_ARCHIVE_CHECK.json` | Whole-archive and per-member SHA check (`sr1_verify_archive.py`) |
| `SR1_CHECK_RESULTS.json` | Results of the 21 independent checks, S4 classes, the cross-check against frozen-S2 M4.B/R1 and the pure-geometry LP2 feasibility block |
| `SR1_comparisons.csv` | Per-state F_G, paired COD F_G, primary U (EDI-only and with COD), conservative U, F_θ, heading difference, offset, separation |
| `SR1_offset_uncertainty.csv` | Propagated U_d (primary, conservative, paired-COD diagnostic) and the first-kink transport share |
| `SR1_compliance_energy_check.csv` | (P²/2t)·ΔC/Δa vs. EDI G per step, and compliance-based F_G |
| `SR1_clearances.csv` | Independent clearances to rings (nominal circles and saved polygons), holes, plate edges and earlier segments |
| `SR1_frozenS2_crosscheck.csv` | LP1 own-path S2 vs. accepted frozen-S2 direct effects |
| `SR1_feasibility_constant_turn.csv` | Hypothetical constant-turn family from the H S4 tip (geometry only, not a forecast) |

Reproduce with `python -I scripts/g2/sr1/sr1_independent_check.py`. The full command sequence is in `../G2_LP1_SR1_VERIFICATION_LOG.md` §5.
