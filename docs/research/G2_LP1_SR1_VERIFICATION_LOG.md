# G2-LP1-SR1 — verification log (22 November 2026)

[Issue #56](https://github.com/mfs9697/NewMetacomp/issues/56). This log records every SR1 verification action in order, including blocked ones.

**Constraints observed throughout:** no FEM solve, no mesh generation, no `Run=true`, no GO record, no change to any original state, policy, pin, historical module or Word document, no merge. Local paths are written as `<repo>` (the SR1 worktree), `<clean>` (a fresh LF clone) and `<codex>` (the isolated checkout that computed LP1).

## 1. Source trees and pins

| Item | Value |
|---|---|
| SR1 branch | `research/g2-lp1-sr1-adjudication-20261122`, created at `70bf6f4baf9f4963380120964f6aaec04e65a349` (PR #55 head) |
| PR #55 head tree | `5ea0ddbe054105e0c93651f113c5579896473110`, identical to local `<codex>` `f9dd767` |
| Computation source | local `3dadf0d43aba0c5b2b3e8c69b90c2d42e89866f8`, tree `1cfe8f2d…`, identical to remote `60358bb…`; source set `2e575696…ab00` |
| Batch source (HOLD_MEMORY run) | `<codex>` `b276b71…`. Its 28 source-relevant blobs (`g2_lp0*`, `g2_lp1*`, `check_g2_lp*`, policies, lock, LP0 evidence, batch script) are identical to `70bf6f4`. |
| Policy v2 / v1 / source lock / LP0 evidence (Git blob SHA-256) | `074d7edc…5091` / `1cf5a76d…af43` / `6e19e222…6b82` / `b4240d7e…33f5`, all equal to the pins |
| Working-tree caveat | `core.autocrlf=true` on this machine turns pinned JSON into CRLF on checkout (policy v2 on disk `50b2ee2a…`). All SR1 hashing uses Git blobs or the `<clean>` clone made with `core.autocrlf=false`. |

## 2. Ordered actions

| # | UTC (file mtimes where available, otherwise ≈) | Action | Result |
|---|---|---|---|
| 1 | 15:26 | Read Issue #56, Issue #52 and its comment, PR #54 and the two assignment documents, the PR #55 body, review comment 7079495852 and the follow-up comments, `G2_LP1_RESULTS/RUNLOG/REPRODUCE/CONCURRENT_REVIEW_RECONCILIATION.md`, `FINAL_PRESERVATION_CHECK.json`, `CURRENT_CONTRACT.json`, `PREPHYSICAL_RESULT.json`, the batch console log, `SCIENTIFIC_REVIEW_UA.md`, CSV/JSON tables, `g2_lp0_clearance.m`, `check_g2_lp0_clearance.m`, `check_g2_lp1_contract.m`, `g2_lp1_run.m`, `g2_lp1_scientific_gate.m`, `g2_lp1_context.m`, `g2_lp0_preflight.m`, `g2_lp1_forecast.m`, `g2_lp1_validate_links.m` | Read before any file change |
| 2 | 15:26 | Created the SR1 worktree at `70bf6f4` | clean |
| 3 | 15:28 | Located the raw archive locally (`<codex>/../outputs/`). Hashed it and verified each member against `RAW_RECORDS_SHA256.json`. | **PASS**: 52,837,630 bytes, SHA `5b333b03…c533`, 182/182 members, no extra or missing member |
| 4 | 15:29 | Compared Git blobs with the working tree for the pinned JSON | pins equal; CRLF effect identified (§1) |
| 5 | 15:30 | `git clone --no-hardlinks -c core.autocrlf=false` of the local repository into `<clean>`, checked out `70bf6f4` as a local branch named `research/g2-lp0-lp1-implementation-20261122`. The first attempt, in the session scratch directory, failed with *Filename too long* (Windows MAX_PATH) and was deleted. | clean tree, LF bytes |
| 6 | 15:31 | `python -I scripts/g2/restore_lp1_evidence.py --historical-root <wt_wp3> --historical-root <NewMetacomp> --raw-archive <zip> --restore`, then a read-only rerun | **PASS**: 689 legacy, 654 historical MAT, 182 campaign files; 836 restored into `<clean>/outputs`, then 0 restored and all matched. `<clean>` status stayed clean. |
| 7 | 15:32–15:33 | Read-only MATLAB field probe (`load` only) | Attempts 1–2 failed in the probe script (a PowerShell `ErrorActionPreference` setting and a relative path). Attempt 3 succeeded; nothing was written to records. |
| 8 | ≈15:34 (after the first extraction, #9) | **SR1-C attempt.** Free RAM was 7.5 GiB before launch and 6.96 GiB inside MATLAB. I prepared a single run of the unchanged `Invoke-G2LP1-PrephysicalBatch.ps1 -MatlabExe <R2023a>` on `<clean>`. | **BLOCKED before launch**: SR1's execution environment denied permission for the command. No MATLAB was started by it, and no output folder or file was created. Per Issue #56 it was not retried or worked around. **Remaining gate unchanged:** run the batch once, on a clean `70bf6f4` checkout, with ≥ 5 GiB free and one engine. It must cover the four dry cases plus the no-GO-before-write probe. |
| 9 | 15:33:51; committed re-run 15:53:12 | Read-only extraction of all 20 states (scratch extractor, later re-run with the committed `scripts/g2/sr1/sr1_extract_records.m`) | **PASS**: 20 states. Free RAM inside MATLAB was 6.96 and 5.93 GiB, ≥ 5 GiB guard kept. |
| 10 | 15:34:41; committed re-run 15:53:13 | Independent mesh quality (`scripts/g2/sr1/sr1_mesh_quality.m`) | **PASS** (results in ledger B5) |
| 11 | ≈15:40 | `python -I scripts/g2/sr1/sr1_independent_check.py --reduce <full extract>`, first run | 19/21. **Two failures in SR1's own check definitions**, both corrected and documented: (a) N12 expected 34 audit gates at S0, but S0 is the straight crack audited by the 38-gate T6 auditor (38/38 recorded); (b) N11 used a hard 1 % limit on point-load-compliance finite differences. H S1→S2 gives +2.3 %, so N11 was reclassified as a corroborating diagnostic: 11/12 steps within 1 %. |
| 12 | ≈15:42 | Second run, after the definition fixes | **21/21** |
| 13 | ≈15:46 | Chronology: NTFS mtimes (`ls --time-style=full-iso`) of `<codex>` campaign outputs; zip member DOS times; `git log` dates in `<codex>` and here | RUN.mat at 11:17:27 UTC, last S4 file at 11:26:32 UTC. Review at 13:00:00 UTC; GO guard at 13:02:23 UTC. |
| 14 | ≈15:49 | Tree-identity checks (`rev-parse <c>^{tree}`) and the blob comparison between `b276b71` and `70bf6f4` | ledger A6, C1 |
| 15 | ≈15:54 | Re-ran the committed MATLAB extractors; rebuilt the reduced extract and re-ran the checks | **21/21**. The reduced JSON contains no local path; the scan for `Users` returned 0. |
| 16 | ≈15:52 | `python -I scripts/g2/sr1/sr1_verify_archive.py <zip>` | **PASS** (`SR1_ARCHIVE_CHECK.json`) |

## 3. Independent checks (`SR1_CHECK_RESULTS.json`)

| ID | Check | Result |
|---|---|---|
| P0–P3 | Policy blob; RUN token; per-state pins, ledger hashes and parent chain; masks and ratios | PASS |
| N0–N6 | STATE=SOLUTION K; unit conversion; G from K; J/G; MTS root; geometry; heading recurrence | PASS |
| N7 | T3 quality, counts, mesh polyline | PASS (worst ratio 1.7295, H S3) |
| N8–N10 | F_G, offsets, separations, paired primary U, conservative U, U_d propagation, S4 classes | PASS: CSV reproduced; soft2 conservative unresolved |
| N11 | Compliance finite-difference energy diagnostic | 11/12 within 1 % (median 0.37 %, maximum 2.3 %) |
| N12 | Saved SOLUTION/PHASE gates and identities | PASS (saved fields) |
| N13 | Clearances to rings (nominal circles and saved polygons), holes, plate, earlier segments | PASS |
| X1–X2 | H S2 vs. accepted frozen S2; own-path vs. direct effect | PASS |
| F1 | Pure-geometry feasibility block | computed |

## 4. Not performed (and why)

- **Current prephysical batch (four dry cases, no-GO probe):** BLOCKED by SR1 tool permission (action 8). The existing HOLD_MEMORY result stands.
- **Zero-solve replay of the 20 states:** not attempted. The current controller requires a GO even for replay, and older code may not be used to evade the HOLD.
- **Any FEM, mesh, refinement or S5/LP2 computation:** outside the SR1 scope.
- **Remote publication of the raw archive:** not attempted. The archive remains local only.

## 5. Commands to reproduce SR1 (no FEM)

```powershell
# hash-verify the archive and ledger
python -I scripts/g2/sr1/sr1_verify_archive.py <archive.zip>
# restore inputs into a clean core.autocrlf=false clone of 70bf6f4 (helper from PR #55)
python -I scripts/g2/restore_lp1_evidence.py --historical-root <worktree> --raw-archive <archive.zip> --restore
# read-only extraction (MATLAB R2023a, >= 5 GiB free, one engine)
matlab -batch "addpath('scripts/g2/sr1'); sr1_extract_records('<clean>/outputs/g2_lp1_matrix_paths_v1/run_20261122_lp1_v1','<new>/records_full.json'); sr1_mesh_quality('<clean>/outputs/g2_lp1_matrix_paths_v1/run_20261122_lp1_v1','<new>/mesh_quality.json')"
# independent checks: from the committed reduced extract, or rebuild it first with --reduce
python -I scripts/g2/sr1/sr1_independent_check.py [--reduce <new>/records_full.json --meshq <new>/mesh_quality.json]
```

Terminal status: `REVIEW_STOP_SR1`.
