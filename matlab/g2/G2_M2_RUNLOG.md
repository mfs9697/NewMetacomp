# G2-M2 run log and HOLD investigations (Issue #36)

Every formal run writes a new `outputs/g2_material_evolution_v1/run_<time>/`. Failed runs are kept unchanged.

## Run A: `run_20261121_131852_300`, HEAD `3748a73`, HOLD at S0 (negative-control design)

**Passed before the stop:**
- G global: PR #35 modules pinned; benchmark record pinned, so no rerun.
- S0 source and ledger checks.
- S0 original auditors: 38/38 and 24/24.
- S0 adapter: 7/7.
- S0 phase map: 15,909 matrix and 12,242 band elements, 3×76 chords.
- S0 verifier: PASS.

**Stopped at:** S0 phase negatives. Case N7 (a q domain of fixed radius 45 mm) was not rejected. No regression, identity or contrast solve was run for any state.

**Cause.** N7 in `check_g2_material_phase_controls.m` (PR #35) uses a fixed 45 mm radius, chosen at State 2, where the nearest band node is 42.14 mm from the tip. At S0 the tip is at (101.6, 25.4), and the nearest band node is about 48.45 mm away (hole-1 centre distance 67.5 mm minus 19.05 mm). A 45 mm domain therefore does not reach a band. The verifier correctly reported its support as matrix-only. The control assumed S2 geometry; the phase map is not at fault.

**Fix.** A new `check_g2_m2_phase_controls.m` wraps the PR #35 module, which is run unchanged and stays byte-pinned:
- all other PR #35 cases must still be rejected;
- the PR #35 N7 verdict must match geometry: rejected iff 45 mm exceeds the tip-to-band distance;
- a new N7s with radius equal to the tip-to-band distance plus 1 mm must be rejected.

No tolerance, gate, policy value or numerical code changed. The batch now calls the wrapper, and the wrapper is added to the source-hash list.

**Retry:** a new folder, after this note is committed.
