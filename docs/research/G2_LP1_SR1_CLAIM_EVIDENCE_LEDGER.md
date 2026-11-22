# G2-LP1-SR1 — claim–evidence ledger

[Issue #56](https://github.com/mfs9697/NewMetacomp/issues/56). This branch starts at the PR #55 head, `70bf6f4baf9f4963380120964f6aaec04e65a349` (tree `5ea0ddbe054105e0c93651f113c5579896473110`).

This review is read-only. It ran no FEM solve, created no mesh, set no `Run=true`, wrote no GO record and changed no original state.

## Status vocabulary

| Status | Meaning |
|---|---|
| **VERIFIED** | Recomputed or checked by SR1 from bytes or arrays it opened itself: the 182 hash-verified raw records, Git blobs or committed tables. Independent code, no reuse of the project's checkers. |
| **VERIFIED (saved field)** | SR1 read the value from the hash-verified saved record and checked it for internal consistency. SR1 did not recompute the underlying FEM quantity, which would need a new solve. |
| **REPORTED_ONLY** | Supported by PR #55 reports, logs or checksums that SR1 could not re-execute. |
| **BLOCKED** | The required verification could not run in SR1. The exact gate is named. |
| **INCONCLUSIVE** | Evidence exists but does not settle the claim under the preregistered rules. |

**Raw-evidence accessibility.** The 182-file raw archive `NewMetacomp_G2_LP1_Raw_Records_20261122.zip` was found **locally** on the investigator's machine (52,837,630 bytes). Its SHA-256 is `5b333b03…c533`, which equals the committed value, and 182/182 members match `RAW_RECORDS_SHA256.json` (`SR1_ARCHIVE_CHECK.json`).

**SR1 verification is therefore not limited to summaries or CSV.** The STATE, REVIEW, SOLUTION, PHASE and MESH arrays of all 20 states were opened with a plain MATLAB `load`. The archive is still **not published remotely**; reviewers without the local archive can reproduce the SR1 numbers from the committed path-free extract `G2_LP1_SR1_independent_check/LP1_records_reduced.json`.

## A. Provenance and integrity

| # | Claim (source) | Artifact and hash | SR1 audit method | Status |
|---|---|---|---|---|
| A1 | The raw archive is the complete 182-file campaign (PR #55, `FINAL_PRESERVATION_CHECK.json`). | Archive `5b333b03…c533`; ledger `RAW_RECORDS_SHA256.json` | `sr1_verify_archive.py`: whole-file SHA plus per-member SHA, set equality, no duplicates | **VERIFIED** 182/182 |
| A2 | All 20 states were computed with source set `2e575696…ab00`, policy v2 `074d7edc…5091` and source commit `3dadf0d…` (`G2_LP1_RUNLOG.md`). | STATE/SOLUTION fields in every record; `RUN.mat` token | Read every record. The token equals `G2LP1\|policy=074d7edc…\|source=2e575696…\|LP0=b4240d7e…\|cases=H,stiff13,soft2,soft1\|maxState=4`. | **VERIFIED** (check P1, P2) |
| A3 | Policy v2 and the source lock are exactly the pinned bytes. | Git blobs: policy v2 `074d7edc…`, v1 `1cf5a76d…`, lock `6e19e222…`, LP0 evidence `b4240d7e…` | `git show HEAD:…` hashed | **VERIFIED**. An `autocrlf=true` working tree gives different (CRLF) hashes; see the verification log. |
| A4 | The hash chain holds: each state links its parent STATE and its own MESH/PHASE/SOLUTION/REVIEW. | Record fields vs. ledger | For S1–S4, `parentSHA256` equals the parent STATE ledger hash. The mesh/phase/solution/review SHAs equal the ledger. The CSV `stateSHA256` equals the ledger. REVIEW fields equal STATE fields. | **VERIFIED** 20/20 (P2) |
| A5 | Masks and ratios are exactly H [0 0 0]/1, stiff13 [1 0 1]/2, soft2 [0 1 0]/0.5, soft1 [1 0 0]/0.5. | STATE and PHASE records | Field comparison | **VERIFIED** (P3) |
| A6 | Local `3dadf0d` and remote `60358bb` have identical trees, and so do local `f9dd767` and remote `70bf6f4`. | Codex checkout (read-only) vs. this repository | `rev-parse <c>^{tree}`: `1cfe8f2d…` = `1cfe8f2d…`; `5ea0ddbe…` = `5ea0ddbe…` | **VERIFIED** |
| A7 | The 689 historical source/evidence files and 654 accepted historical MAT inputs keep their locked hashes. | `G2_LP0_SOURCE_LOCK_v1.json` | A fresh LF clone of `70bf6f4` was made with `restore_lp1_evidence.py`. Legacy files were checked in that clone; the MATs come from the investigator's worktrees (`_wt_wp3`, `NewMetacomp`), and their hashes match the lock. | **VERIFIED** 689 + 654 + 182 |
| A8 | No earlier module, policy, result or Word file was changed by PRs #54/#55. | Git trees | `git diff --name-status 6699c54..70bf6f4` contains only additions (status `A`); no `M` or `D`. | **VERIFIED** |
| A9 | The 182 campaign files stayed byte-identical after a zero-solve replay (`REPLAY.json`). | `REPLAY.json` | SR1 did not replay; the current guard forbids it without a GO. The present bytes equal the ledger (A1). | **REPORTED_ONLY** (replay); **VERIFIED** (present bytes) |
| A10 | The computation chronology relative to the 13:00 UTC scientific review. | NTFS mtimes in the Codex checkout; zip member times; commit dates | `RUN.mat` mtime is 13:17:27 +02:00 (11:17:27 UTC); the last S4 file is 13:26:32 +02:00 (11:26:32 UTC). The local enablement commit `3dadf0d` is 13:16:39 +02:00. The review comment is 13:00:00 UTC; the GO-guard commit `2b682b8` is 13:02:23 UTC. | **VERIFIED**: all 20 solves ran about 1 h 33 min **before** the HOLD review. This is chronology only; see the authorization row C3. |

## B. Numerical content of the 20 states (independent recomputation)

All checks are produced by `scripts/g2/sr1/sr1_independent_check.py` (Python standard library only). Results are in `G2_LP1_SR1_independent_check/SR1_CHECK_RESULTS.json`; the outcome is **21/21 checks pass**.

| # | Claim | SR1 audit | Result | Status |
|---|---|---|---|---|
| B1 | Signed K and units: K in N·mm⁻³ᐟ² at 1 N; the CSV gives MPa·√m per kN. | Factor ×1000/√1000; STATE K equals SOLUTION K | Maximum relative error 2e-16 (round-off). K per kN = 1000 × K(1 N); G at 1 kN = 10⁶ × G(1 N). | **VERIFIED** (N0, N1) |
| B2 | Plane stress G = (K_I² + K_II²)/E_m, with E_m = 3268.115 MPa (q support in matrix). | Recomputed against the record and the CSV | Maximum relative error < 1e-12. J/G − 1 ≤ 2.25e-5 (gate 0.005). | **VERIFIED** (N2, N3) |
| B3 | MTS angle and frame: K_I sin θ + K_II(3 cos θ − 1) = 0; K_II > 0 gives θ < 0 (clockwise). | Own closed-form root | \|Δθ\| ≤ 2.8e-13°; stationarity residual 4e-17. | **VERIFIED** (N4) |
| B4 | Geometry: common S0, exact 4-mm segments, s = 25.4 + 4k, prefix extension, tangent and left normal. | Own geometry on the saved polylines; MESH `crackPolyline` equals the state polyline | Maximum segment error < 1e-9 mm; heading(S_{k+1}) − heading(S_k) = MTS(S_k) to < 1e-9°. | **VERIFIED** (N5, N6) |
| B5 | Mesh quality: minimum angle ≥ 20°, neighbour longest-edge ratio ≤ 1.8, no inverted T3. | Own T3 metrics from the saved X3/T3 | Minimum angle 30.12685° in all states. Ratio 1.59183, except H S3 1.72951, H S4 1.59403 and stiff13 S4 1.60503. No inverted element; T3 counts equal the CSV. | **VERIFIED** (N7). The smallest margin is H S3 (4% from the 1.8 limit). |
| B6 | Relative G and signed lateral offset at matched arclength, with offset d = (x_M − x_H)·n_H and n_H the left normal of H (pointing away from the ring column, toward −x). | Recomputed | Reproduces the CSV to 1e-9. | **VERIFIED** (N8) |
| B7 | S4 values: F_G = −7.173170 % (stiff13), −2.931815 % (soft2), +6.328936 % (soft1); d = −0.190902, −0.085163, +0.305671 mm. | Recomputed | Identical. | **VERIFIED** |
| B8 | COD/EDI agreement is within the 0.03·K_ref gate. | From the saved K_COD and K_EDI | Maximum 0.00886 (vector norm). The COD bias in K_I is −0.877 % to −0.879 % in **all** 20 states, i.e. common-mode. The spread across the five EDI annuli is ≤ 1.6e-6 relative. | **VERIFIED** |
| B9 | Energy, reactions, opening and phase gates passed in every state. | Saved SOLUTION/PHASE fields | Strain energy = external work (≤ 1e-11 relative); compliance = 2U/P²; reactions sum to P/t; whole-crack opening ≥ −1e-9 mm. The signed K_II EDI/COD signs agree. Phase/owner/activation audits pass, with 38/38 at S0 and 34/34 at S1–S4. Active area = number of active rings × 1012.1525 mm². | **VERIFIED (saved field)** (N12) |
| B10 | Global energy consistency, an independent estimator. | (P²/2t)·ΔC/Δa from successive point-load compliances vs. the mean EDI G | On the 12 smooth steps, 11/12 agree within 1 % (median 0.37 %). H S1→S2 is +2.3 %, consistent with the known point-load sensitivity of nodal compliance (R1 REV-002). | **CORROBORATING_DIAGNOSTIC** (N11); not a gate |
| B11 | H S1/S2 reproduces the historical chain; S2 equals the accepted M4.B/R1 frozen-S2 homogeneous G. | Record vs. `r1_cases_both_families.csv` | ΔG/G = 8.0e-8 at S2. The S1 coordinate error of 4.41e-6 mm is the documented six-digit historical seed. | **VERIFIED** (X1); S1 tolerances **REPORTED_ONLY** from `regressH` |
| B12 | Clearances to all rings, holes, earlier segments and plate edges. | Own distances to the nominal circles **and** the saved 76-gon ring polygons; segment–segment distances | Reproduce the CSV and record metrics to 1e-9. The smallest margin in all 20 states is the guide margin 20.82 mm (stiff13 S4). The nearest ring is ring 1 throughout. | **VERIFIED** (N13) |

## C. Authorization and guarded-code status

| # | Claim | Evidence | Status |
|---|---|---|---|
| C1 | The current guarded prephysical batch passed. | `PREPHYSICAL_RESULT.json` (`FAILED`, `HOLD_MEMORY`, 4.958122 GiB) at `b276b71`. SR1 checked that the 28 source-relevant blobs (`g2_lp0*`, `g2_lp1*`, `check_g2_lp*`, policies, lock, LP0 evidence, batch script) are **identical** at `b276b71` and `70bf6f4`. | **REJECT**: it did not pass. Four dry cases and the no-GO-before-write probe were **not executed**. |
| C2 | The amended pure-contract suite passed 25/25. | `CURRENT_CONTRACT.json`; `current_guarded_contract.log` | **REPORTED_ONLY**; the count is consistent (the unprinted `positive_links` plus 24 printed names). SR1 found two test-design limits: (i) `reject()` accepts *any* error, without checking the identifier; (ii) because no GO file exists, `scientific_go_missing_or_wrong_token` exercises only the *missing-file* branch. A present-but-mismatched GO is never tested. This suite does not clear C1. |
| C3 | The 20 states are scientist-authorized. | Issue #52 authorized LP1 "only after LP0 code, source and integrity gates pass". LP0 evidence is labelled `LP0_GEOMETRY_QUALIFIED_REVIEW_REQUIRED`, and v2 set `physicalEnabled=true` without a scientist decision. The review of 13:00 UTC (after the computation, A10) required a separate SHA-bound GO, and none exists. | **NOT ESTABLISHED.** No HOLD in force was breached (A10), but scientist authorization of the physical stage was never given. SR1 creates no retrospective GO. The disposition belongs to the scientist. |
| C4 | The current controller cannot declare campaign completion from one case. | `g2_lp1_run.m` at `70bf6f4` | **VERIFIED** (code reading). A single case returns `CASE_S4_COMPLETE_AWAIT_CAMPAIGN_REVIEW` or `BOUNDED_PREFIX_COMPLETE`. The historical records' `REVIEW_STOP_LP1` strings come from the earlier source. |
| C5 | An unreviewed partial chain cannot be silently resumed. | Same | **VERIFIED** (code reading). A state folder without `REVIEW.mat` raises `HOLD_RECORD_INTEGRITY`, and any `HOLD.mat` blocks reuse of the chain. Note: `resource()` runs after `mkdir(sd)`, so a memory dip during a run leaves a permanent HOLD for that chain. This is by design, and the guard is not lowered. |
| C6 | The stop taxonomy preserves the specific reasons. | `g2_lp0_clearance.m`; HOLD record | **VERIFIED with caveat.** All reasons are kept in `geometryReasons`, but the primary code is `reasons{1}` in a fixed order (EXTERNAL > SELF_INTERSECTION > INTERFACE > Q > GUIDE). The kink limit (miter denominator ≤ 1.8, i.e. a turn > 36.87°) is reported as `HOLD_CRACK_SELF_INTERSECTION`. On a smooth approach to a ring, `HOLD_TIP_GUIDE` (15 mm) always fires long before `HOLD_INTERFACE_APPROACH` (1.52 mm). |
| C7 | Prephysical tests could be re-run in SR1. | SR1 built a clean LF clone at `70bf6f4` with the required branch name and all 654 + 182 inputs restored by hash. The free RAM then measured was 7.5 GiB before launch and 6.96 GiB inside MATLAB. | **BLOCKED**: SR1's execution environment denied permission to launch the batch. It was not attempted another way. The remaining gate is unchanged: run `Invoke-G2LP1-PrephysicalBatch.ps1` once on a clean `70bf6f4` checkout with ≥ 5 GiB free RAM. |

## D. Scientific interpretation (SR1 adjudication; numbers are VERIFIED, interpretation is SR1's)

| # | Claim | Evidence | SR1 decision |
|---|---|---|---|
| D1 | stiff13 shields, F_G(S4) = −7.17 %, while shifting toward the ring column (d = −0.191 mm). | F_G/U_cons = 2.21; \|d\|/(2U_d,cons) = 2.20; paired COD F_G differs by −3.6e-6 | **Resolved under both rules.** It is conditional evidence about prescribed 4-mm MTS states; it is not a physical shielding claim. |
| D2 | soft1 amplifies, F_G(S4) = +6.33 %, while shifting away (d = +0.306 mm). | F_G/U_cons = 1.70; \|d\|/(2U_d,cons) = 3.65 | **Resolved under both rules**, with the same scope as D1. |
| D3 | soft2 reduces G by 2.93 %. | Primary: resolved (\|F_G\| > 2U_primary, COD sign agrees). Conservative: \|F_G\|/U_cons = **0.863**, unresolved. Paired COD F_G = −2.931895 % (Δ = −7.9e-7). R1 cross-family drift −2.1e-5. Compliance-based F_G over the last two steps −3.55 % / −3.07 %. | **INCONCLUSIVE under the preregistered conservative criterion.** It must stay so labelled. SR1 notes that every *available* numerical indicator is 3–4 orders below \|F_G\|, and that U_cons is dominated by the common-mode COD bias (B8), which cancels in a paired ratio. That observation is post hoc and cannot reclassify the result. |
| D4 | soft2 shifts toward the column (d = −0.085 mm). | \|d\|/(2U_d,cons) = **0.984**; the paired-COD propagated U_d is 0.0004 mm | **INCONCLUSIVE** (cautious criterion missed by 1.6 %), for the same structural reason as D3. |
| D5 | Shielding and deflection away from the rings are different objectives. | Across the three architectures, sign(F_G) = sign(d): both shielding cases move ringward and the amplifying case moves away. | **Accepted as descriptive** for this set of three unequal-area architectures. No architecture shields *and* deflects away. Three points do not establish a general correlation. |
| D6 | The path differences are almost entirely a first-kink effect. | 4n·Δθ(S0) gives 97 % (stiff13), 80 % (soft2) and 99 % (soft1) of d(S4). After S0, \|Δθ_local\| ≤ 0.09°. In stiff13 and soft1 the later local angles counter-steer (opposite sign to S0), with growing magnitude. | **New SR1 finding (VERIFIED arithmetic).** Steering acts through the S0 heading difference set where K_II/K_I ≈ 0.11, consistent with M3. Linear growth of d beyond S4 must **not** be assumed. |
| D7 | The own-path effect at S2 opposes the frozen-S2 direct effect (M4.B). | Path contribution +0.130 / +0.051 / −0.190 pp against direct −5.478 / −3.628 / +4.430 % | **VERIFIED consistency** with M3 R_path (X2). The frozen-S2 F_θ (−0.81°, −0.37°, +1.31°) is not comparable to the own-path local Δθ (≤ 0.04° at S2): on its own path, the effect is carried by the heading. |
| D8 | soft2's magnitude trend. | F_G for soft2 is −4.26, −3.88, −3.58, −3.26 and −2.93 % at S0–S4 (monotone decrease in \|F_G\|). stiff13 and soft1 grow monotonically. | Persistence of soft2 shielding beyond S4 is **not established**; the trend points the other way. |
| D9 | Robust bypass, interface approach or interception, optimal architecture, arrest, onset or stability. | — | **REJECT as unsupported.** No interface or boundary event occurred (all margins > 20 mm). Ring areas are unequal (2024 vs. 1012 mm²). The conditional 4-mm MTS advance has no toughness criterion. |
| D10 | The uncertainty columns are certified error bounds. | — | **REJECT.** They are estimator-disagreement diagnostics. The 1e-5 primary floor (M3) is **smaller** than the observed R1 cross-family drift (2.1–3.1e-5) for these exact architectures. There is no refinement study of the evolving paths, and the shared p010 tip core means R1 is not an independent near-tip discretization test. |

## E. Concise decision matrix (for the scientist; SR1 does not decide)

| Item | Accept as retrospective scientific evidence | Request prospective reproducibility qualification | Reject unsupported |
|---|---|---|---|
| Numerical integrity of the 20 states (A1–A8, B1–B12) | ✔ numerically valid, VERIFIED | — | — |
| Compliance with the authorization process (C3) | — | ✔ the states predate the HOLD but lack a scientist GO. A cheap prospective reproduction under the current guard (≈ 9 min of compute for 20 states) would close the process gap. | — |
| stiff13 and soft1 conditional effects (D1, D2) | ✔ conditional, bounded pilot | ✔ refinement-based uncertainty before LP2 use | — |
| soft2 effects (D3, D4) | ✔ only as INCONCLUSIVE | ✔ preregistered paired-estimator + refinement test | — |
| Current guarded prephysical batch (C1) | — | ✔ complete the four dry cases and the no-GO probe | ✔ the claim that it passed |
| 25/25 contract suite (C2) | ✔ as pure-contract evidence only | ✔ identifier-checked negatives; mismatched-GO fixture | — |
| Bypass, interception, arrest, optimization, certified bounds (D9, D10) | — | — | ✔ |

Terminal status: **`REVIEW_STOP_SR1`**.
