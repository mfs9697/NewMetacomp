# G2-LP1-A0 — execution protocol for a later, separately authorized run (operational, English)

[Issue #60](https://github.com/mfs9697/NewMetacomp/issues/60). This protocol describes **how** A0 would be executed **after** a genuine investigator GO. It is not a runnable batch: no script is supplied. Every physical step is refused by the production gate (`G2LP1:HOLD_UNAUTHORIZED_STATE`) until a valid GO is committed. The governing scientific document is `G2_LP1_A0_PREREGISTRATION_UA.md`.

## 0. Preconditions (all must hold; otherwise stop with HOLD)

| # | Precondition | Evidence |
|---|---|---|
| P1 | Signed GitHub decision `GO_A0` by the investigator, naming this preregistration, the pins and the run name | GitHub comment URL |
| P2 | GO JSON committed at `matlab/g2/G2_LP1_SCIENTIFIC_GO_v1.json` by/for the investigator, on top of a commit whose source set is `6f7fb3ea…` | `a0_pin_check.py` (all checks pass except G1) |
| P3 | Fresh clone, `core.autocrlf=false`, checked out at the GO commit; inputs restored by hash (689 / 654 / 182); clean tree | `restore_lp1_evidence.py` (read-only re-check) |
| P4 | Historical archive backed up out-of-tree **and off-device**, SHA `5b333b03…` | hash listing |
| P5 | MATLAB R2023a + PDE; **no** other MATLAB process; Windows free RAM ≈ 7 GiB (admission threshold unchanged at 5 GiB inside MATLAB) | process list, RAM log |
| P6 | Run folder `outputs/g2_lp1_matrix_paths_v1/run_a0_lp1_repro_v1` does not exist | `a0_pin_check.py` K3 |

## 1. Ordered physical steps (one MATLAB session; each call is a `g2_lp1_run` with `Run=true`, the full token, and `RunName='run_a0_lp1_repro_v1'`)

1. `Case='H'`, `MaxStateIndex=2`. The H S1/S2 regression runs inside the controller.
2. `Case='stiff13'`, `MaxStateIndex=2`; then `soft2`; then `soft1`. The controller refuses these until H S2 is accepted.
3. For each of H, stiff13, soft2, soft1: `MaxStateIndex=4`. S0–S2 are reused after re-audit, without FEM. The controller refuses S3 until all four S2 records exist.

Expected totals: **20 solves and 16 new kinked meshes**, plus 4 S0 meshes built from the accepted S0 geometry, exactly as in LP1. Record the console and the `memory()` reading before every call.

## 2. Stop rules (preregistered; no silent restart)

- **Any HOLD:** stop the whole sequence and post the HOLD record and log for review. This covers geometry, K extraction, phase, mesh quality, record integrity, H regression and source.
- **Pre-admission `HOLD_MEMORY`.** The record is written as `PREADMISSION_HOLD_MEMORY_S<k>_*.mat` beside the chain, and no state folder exists. At most **one** resumption is allowed, and only after a written review note. The resumption repeats the *same* call.
- **`HOLD_MEMORY` after a state folder exists.** The chain is blocked. A0 is `A0_HOLD_INCOMPLETE` and goes to review only.
- **No other call.** Never edit, delete or rename any record or folder. Never use a different run name. Never induce a failure for testing.

## 3. Post-run, read-only

1. Re-invoke step 3 for each case once (`MaxStateIndex=4`). The expected output is `computed=0`, `reused=5`, `promoted=0`. This is the controller-level reuse/replay check; it involves no FEM.
2. Run `a0_compare_records(<historical run>, <A0 run>, <new json>)` and report the tier per state and the verdict.
3. Run the SR1-style independent recomputation on the A0 run, by pointing the reduction and check at the new run. Also verify:
   - the archive and the 654 inputs are unchanged;
   - the historical run's 182 hashes are unchanged.
4. Hash every A0 output into a SHA-256 manifest. Sanitize logs for commit.
5. **Remove the GO file in a follow-up commit**, which restores the HOLD, unless the investigator decides otherwise.

## 4. Review checklist (for the investigator)

- [ ] Every one of the 20 states has a tier, and the verdict matches the preregistered rule.
- [ ] Provenance: the new source set is `6f7fb3ea…`, the RUN token is the A0 token, the parent chain and file-hash links are self-consistent, and the historical records are untouched.
- [ ] The S4 classifications are unchanged. soft2 stays inconclusive under the conservative criterion.
- [ ] Branches not exercised in VG1, read from the actual log only:
  - the pre-admission memory catch (if it occurred);
  - the reuse `isequaln` path (step 3.1).
- [ ] Zero S5 states; no folder other than `run_a0_lp1_repro_v1`; no refinement.
- [ ] The GO has been removed or retained by explicit decision.
- [ ] Any tier C/D or HOLD is analysed before any A1 preregistration.
