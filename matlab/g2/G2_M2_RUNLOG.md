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

## Run B: `run_20261121_132003_358`, HEAD `3ebc971`, HOLD at S1 (my wrapper's expectation)

**S0: complete PASS** (kept in the run folder):
- auditors 38/38 and 24/24;
- adapter;
- phase map, verifier and negatives; tip-to-band distance 48.46 mm, so N7 at 45 mm was correctly not rejected, and N7s was rejected;
- WP2 regressions with zero difference;
- bitwise identity;
- Msoft and Mstiff pass every gate.

**Stopped at:** S1 negatives. The nearest band node is 45.27 mm from the tip. The PR #35 N7 domain (45 mm) does not reach a band, but the verifier also enforces the preregistered q clearance of at least 1 mm (45.27 − 45 = 0.27 mm < 1 mm). It therefore correctly rejected the domain. My wrapper expected no rejection because it compared 45 mm with the distance and left out the clearance term.

**Fix:** the expectation becomes "rejected iff 45 mm + `minQClearance_mm` > tip-to-band distance". No verifier, tolerance or policy change. S0 is recomputed in the retry; the formal run is deterministic.

## Run C: `run_20261121_132104_197`, HEAD `a9d3298`, S0–S2 PASS, HOLD at S2alt (harness input)

**S0, S1 and S2 PASS** (kept):
- original auditors and adapters;
- phase stages and negatives (tip-to-band distances 48.46 / 45.27 / 42.14 mm);
- historic regressions with zero difference;
- bitwise H1 = M0;
- Msoft and Mstiff pass every gate;
- S2 equals PR #35 run C exactly (arrays and ratio table).

**Stopped at:** the S2alt join, `HOLD_KINKED_P010_BLOCK / HOLD_KINK_ADMISSIBILITY K1_polylineIdentity`. No alternative mesh was produced.

**Cause.** The batch passed the policy's 10-decimal polyline to `g2_kinked_join`. K1 requires every appended segment to be exactly 4 mm, and the rounded coordinates miss that within K1's tolerance. The preregistered build means "the S2 polyline". The geometry-only feasibility build used the saved full-precision `crackPolyline` from the S2 mesh, and it passed.

**Fix.** The batch now uses the saved S2 `crackPolyline`, after asserting it equals the preregistered polyline to 1e−9 mm. Mesh options are unchanged (GuideHface 1.0, Hmax 5, everything else as for S2).

**On the one-attempt rule.** This is not a second mesh attempt in the sense of the preregistration. No mesh existed, no gate on a mesh failed, and no mesh parameter is changed. The rule against tuning after a mesh HOLD still applies to the retry.
